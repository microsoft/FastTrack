type DiagnosticBindingScope = "table" | "action";

export function diagnosticHttpStatus(value: unknown): number | undefined {
  if (typeof value !== "number" || !Number.isInteger(value)) return undefined;
  return value >= 100 && value <= 599 ? value : undefined;
}

export function logConnectorFailure(operation: string, bindingScope: DiagnosticBindingScope, error: unknown): void {
  const fields = typeof error === "object" && error !== null ? (error as Record<string, unknown>) : {};
  console.error("connector operation failed", {
    operation,
    bindingScope,
    status: diagnosticHttpStatus(fields.status),
  });
}
