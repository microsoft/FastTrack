import { createContext, useContext } from "react";

export interface ConfirmOptions {
  title: string;
  description?: string;
  confirmLabel?: string;
  cancelLabel?: string;
  /** Style the confirm button as a destructive action. */
  destructive?: boolean;
}

export type ConfirmFn = (options: ConfirmOptions) => Promise<boolean>;

export const ConfirmContext = createContext<ConfirmFn | null>(null);

// `window.confirm` / `alert` / `prompt` are suppressed in the sandboxed preview
// iframe — use this instead. Render <ConfirmDialogProvider> once (App.tsx does),
// then anywhere below it:
//   const confirm = useConfirm();
//   if (await confirm({ title: "Delete task?", destructive: true })) remove();
export function useConfirm(): ConfirmFn {
  const ctx = useContext(ConfirmContext);
  if (!ctx) {
    throw new Error("useConfirm must be used within <ConfirmDialogProvider>");
  }
  return ctx;
}
