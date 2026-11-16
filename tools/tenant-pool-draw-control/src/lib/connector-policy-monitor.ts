// App-wide detection of a connector blocked by a DLP / ACP policy. The data
// SDK returns a failed call as a result rather than throwing, so whether the
// user sees anything depends on the generated page. The host's metric stream
// reports the status of every request it sends, so watching it here catches a
// block from any connector without the app's code taking part. Started from
// main.tsx; the banner reads the state through useConnectorPolicyBlock().
import { useSyncExternalStore } from "react";
import { initializeLogger, type Metric } from "@microsoft/managed-apps/telemetry";

// API Hub answers a DLP/ACP connector-policy block with this status. Defined
// here so this locked module imports nothing the app builder may edit.
export const CONNECTOR_POLICY_STATUS = 442;

// Fixed text: the request URL and the upstream body carry connection,
// tenant and environment ids, so neither is logged.
export const CONNECTOR_POLICY_LOG =
  "[connector-policy] A connector request was blocked by the organization's DLP/ACP policy (HTTP 442). The app code is not at fault; an administrator must allow the connector.";

export interface ConnectorPolicyBlock {
  blocked: boolean;
  // Connector API names (e.g. "microsoftspatialservices"), never connection ids.
  connectors: readonly string[];
  // A blocked request whose URL named no connector.
  unnamed: boolean;
}

const UNBLOCKED: ConnectorPolicyBlock = { blocked: false, connectors: [], unnamed: false };
let state = UNBLOCKED;
const listeners = new Set<() => void>();

// API Hub paths are /apim/<connector api name>/<connection id>/...; only the
// api name is kept.
export function connectorApiName(url: string): string | undefined {
  const match = /\/apim\/([a-z0-9_-]+)\//i.exec(url);
  return match ? match[1].toLowerCase() : undefined;
}

export function observeConnectorMetric(metric: Metric): void {
  if (metric.type !== "networkRequest") return;
  if (metric.data.statusCode !== CONNECTOR_POLICY_STATUS) return;
  const name = connectorApiName(metric.data.url ?? "");
  if (state.blocked && (name ? state.connectors.includes(name) : state.unnamed)) return;
  if (!state.blocked) console.error(CONNECTOR_POLICY_LOG);
  state = {
    blocked: true,
    connectors: name ? [...state.connectors, name] : state.connectors,
    unnamed: state.unnamed || !name,
  };
  for (const listener of listeners) listener();
}

let started = false;

export function startConnectorPolicyMonitor(
  initialize: typeof initializeLogger = initializeLogger,
): void {
  if (started) return;
  started = true;
  try {
    initialize({ logMetric: observeConnectorMetric });
  } catch {
    // No host channel (unit tests, a bare browser): nothing to watch.
  }
}

export function subscribeConnectorPolicyBlock(listener: () => void): () => void {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

const subscribe = subscribeConnectorPolicyBlock;

export function getConnectorPolicyBlock(): ConnectorPolicyBlock {
  return state;
}

export function isConnectorPolicyBlocked(): boolean {
  return state.blocked;
}

export function useConnectorPolicyBlock(): ConnectorPolicyBlock {
  return useSyncExternalStore(subscribe, getConnectorPolicyBlock, getConnectorPolicyBlock);
}

export function resetConnectorPolicyMonitorForTests(): void {
  state = UNBLOCKED;
  started = false;
  listeners.clear();
}