import { Outlet, useLocation } from "react-router-dom";
import { motion } from "motion/react";
import { Gauge } from "lucide-react";
import { Toaster } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";

export function AppShell() {
  const { pathname } = useLocation();
  return (
    <TooltipProvider>
      <div className="flex min-h-screen flex-col">
        <a href="#work" className="sr-only focus:not-sr-only focus:fixed focus:left-3 focus:top-3 focus:z-50 focus:rounded-md focus:bg-background focus:px-3 focus:py-2 focus:ring-2 focus:ring-ring">
          Skip to environments
        </a>
        <header className="sticky top-0 z-40 border-b bg-primary text-primary-foreground">
          <div className="mx-auto flex h-12 max-w-[1400px] items-center gap-2 px-4 sm:px-6">
            <Gauge className="size-5" aria-hidden="true" />
            <span className="font-semibold">Tenant Pool Draw Control</span>
            <span className="ml-3 hidden text-sm opacity-90 sm:inline">Copilot Credits · capacity overages</span>
          </div>
        </header>
        <main className="flex flex-1 flex-col">
          <motion.div key={pathname} initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.15, ease: "easeOut" }} className="flex-1">
            <Outlet />
          </motion.div>
        </main>
        <Toaster />
      </div>
    </TooltipProvider>
  );
}

export default AppShell;
