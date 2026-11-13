// User-safe copy for a failed generated-connector call (`IOperationResult.error`,
// or that error rethrown inside a query). A connector blocked by a DLP / ACP
// policy is named as such so the user knows to ask an administrator; every
// other failure stays generic. The upstream message is never echoed: a policy
// block's body carries tenant and environment ids.
import { CONNECTOR_POLICY_STATUS } from "./connector-policy-monitor";

const CONNECTOR_POLICY_MARKER =
  "data loss prevention (dlp) or advanced connector policies";

function field(error: object, key: "status" | "message" | "cause"): unknown {
  return key in error ? (error as Record<string, unknown>)[key] : undefined;
}

export function isConnectorPolicyBlock(error: unknown, depth = 0): boolean {
  if (!error || typeof error !== "object" || depth > 3) return false;
  if (field(error, "status") === CONNECTOR_POLICY_STATUS) return true;
  const message = field(error, "message");
  if (
    typeof message === "string" &&
    message.toLowerCase().includes(CONNECTOR_POLICY_MARKER)
  ) {
    return true;
  }
  return isConnectorPolicyBlock(field(error, "cause"), depth + 1);
}

export function connectorErrorMessage(error: unknown, connector: string): string {
  if (isConnectorPolicyBlock(error)) {
    return `${connector} is blocked by your organization's data policy for this environment. Ask an administrator to allow the ${connector} connector, then reload the app.`;
  }
  return `Couldn't load data from ${connector}. Try again.`;
}
