import { useCallback, useRef, useState, type ReactNode } from "react";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import {
  ConfirmContext,
  type ConfirmFn,
  type ConfirmOptions,
} from "@/hooks/use-confirm";
import { cn } from "@/lib/utils";

interface PendingConfirm extends ConfirmOptions {
  resolve: (value: boolean) => void;
}

// Provides the Promise-based confirm() used by `useConfirm` (hooks/use-confirm).
// Rendered once at the app root (App.tsx). Replaces the sandbox-suppressed
// window.confirm with a shadcn AlertDialog.
export function ConfirmDialogProvider({ children }: { children: ReactNode }) {
  const [pending, setPending] = useState<PendingConfirm | null>(null);
  const openRef = useRef(false);

  const confirm = useCallback<ConfirmFn>(
    (options) => {
      // Guard against a second confirm() while one is already open — otherwise
      // the first promise's resolver would be orphaned and that await hangs.
      if (openRef.current) return Promise.resolve(false);
      openRef.current = true;
      return new Promise<boolean>((resolve) =>
        setPending({ ...options, resolve }),
      );
    },
    [],
  );

  const settle = (value: boolean) => {
    openRef.current = false;
    pending?.resolve(value);
    setPending(null);
  };

  return (
    <ConfirmContext.Provider value={confirm}>
      {children}
      <AlertDialog
        open={pending !== null}
        onOpenChange={(open) => {
          if (!open) settle(false);
        }}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>{pending?.title}</AlertDialogTitle>
            {pending?.description && (
              <AlertDialogDescription>
                {pending.description}
              </AlertDialogDescription>
            )}
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => settle(false)}>
              {pending?.cancelLabel ?? "Cancel"}
            </AlertDialogCancel>
            <AlertDialogAction
              onClick={() => settle(true)}
              className={cn(
                pending?.destructive &&
                  "bg-destructive text-destructive-foreground hover:bg-destructive/90",
              )}
            >
              {pending?.confirmLabel ?? "Confirm"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </ConfirmContext.Provider>
  );
}
