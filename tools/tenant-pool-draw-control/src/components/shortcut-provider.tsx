import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type FocusEvent,
  type PointerEvent,
  type ReactNode,
} from "react";

// The app's one keyboard-shortcut surface. Raw keydown listeners and JSX onKey*
// handlers are lint-banned outside this file and src/components/ui/**.
export const APP_SHORTCUTS = {
  commandPalette: "mod+k",
  focusSearch: "/",
  shortcutHelp: "mod+/",
  nextItem: "j",
  previousItem: "k",
  openItem: "enter",
  newItem: "n",
  saveAndClose: "mod+enter",
} as const;

// Combos the browser or OS owns (the page never sees them) or that users expect to keep
// (find, save, print, reload, zoom, devtools). useAppShortcut rejects every one of them,
// scoped or not; `mod` here also covers explicit `ctrl+`/`meta+` spellings.
export const RESERVED_BROWSER_SHORTCUTS = [
  ...["n", "t", "w", "q", "h", "m", "l", "r", "p", "s", "f", "g", "o", "u", "d", "j", "e"].map((key) => `mod+${key}`),
  ...["n", "t", "w", "r", "g", "i", "j", "c", "b", "o", "delete", "tab"].map((key) => `mod+shift+${key}`),
  ...["tab", "pageup", "pagedown", "[", "]", ",", "left", "right", "+", "=", "-", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "f5"].map((key) => `mod+${key}`),
  // macOS Chrome/Edge keep these Cmd+Option combos (devtools, side panel, bookmarks, source, downloads).
  ...["n", "i", "j", "c", "b", "u", "l"].map((key) => `mod+alt+${key}`),
  ...["left", "right", "home", "d", "e", "f", "f4"].map((key) => `alt+${key}`),
  "shift+f5",
  ...["f1", "f3", "f5", "f6", "f7", "f11", "f12"],
] as const;

export interface ShortcutScope {
  readonly name: string;
  readonly kind: "local";
  readonly token: symbol;
  readonly bindings: {
    onFocusCapture: (event: FocusEvent<HTMLElement>) => void;
    onPointerDownCapture: (event: PointerEvent<HTMLElement>) => void;
  };
  readonly containsActiveElement: boolean;
}

export interface ModalShortcutScope {
  readonly name: string;
  readonly kind: "modal";
  readonly token: symbol;
  readonly depth: number;
}

export interface AppShortcutOptions {
  allowRepeat?: boolean;
  description?: string;
  enabled?: boolean;
  enableOnContentEditable?: boolean;
  enableOnFormTags?: boolean;
  preventDefault?: boolean;
  scope?: ShortcutScope | ModalShortcutScope;
}

interface ParsedBinding {
  alt: boolean;
  ctrl: boolean;
  meta: boolean;
  shift: boolean;
  key: string;
}

interface Registration {
  bindings: ParsedBinding[];
  callback: (event: KeyboardEvent) => void;
  options: AppShortcutOptions;
  order: number;
}

interface ShortcutContextValue {
  register: (registration: Registration) => () => void;
  activeLocal: symbol | null;
  setActiveLocal: (token: symbol | null, element: HTMLElement | null) => void;
  releaseLocal: (token: symbol) => void;
  pushModal: (token: symbol, depth: number) => () => void;
  markModalEvent: (event: Event, token: symbol) => void;
}

const ShortcutContext = createContext<ShortcutContextValue | null>(null);
const ModalScopeContext = createContext<ModalShortcutScope | null>(null);

const KEY_ALIASES: Record<string, string> = {
  del: "delete",
  down: "arrowdown",
  esc: "escape",
  left: "arrowleft",
  return: "enter",
  right: "arrowright",
  space: " ",
  spacebar: " ",
  up: "arrowup",
};
const MODIFIERS = new Set(["alt", "ctrl", "control", "meta", "cmd", "mod", "shift"]);
const FUNCTION_KEY = /^f([1-9]|1[0-9]|2[0-4])$/;
const DOM_MODAL_SELECTOR = '[aria-modal="true"], [role="dialog"][data-state="open"], [role="alertdialog"][data-state="open"]';
// Radix popovers render role="dialog" inside a popper wrapper; they are not modal.
const POPPER_WRAPPER_SELECTOR = "[data-radix-popper-content-wrapper]";
// Text-editing combos stay with the focused field unless a scope claims them.
const TEXT_EDIT_KEYS = new Set(["a", "c", "v", "x", "y", "z"]);

function isMac(): boolean {
  return typeof navigator !== "undefined" && /mac|iphone|ipad/i.test(navigator.platform || navigator.userAgent);
}

export function parseBinding(binding: string): ParsedBinding {
  const raw = binding.toLowerCase().trim();
  const parts = raw === "+" ? ["+"] : raw.endsWith("++") ? [...raw.slice(0, -2).split("+").filter(Boolean), "+"] : raw.split("+");
  const parsed: ParsedBinding = { alt: false, ctrl: false, meta: false, shift: false, key: "" };
  for (const part of parts) {
    if (MODIFIERS.has(part)) {
      if (part === "alt") parsed.alt = true;
      else if (part === "shift") parsed.shift = true;
      else if (part === "ctrl" || part === "control") parsed.ctrl = true;
      else if (part === "meta" || part === "cmd") parsed.meta = true;
      else if (isMac()) parsed.meta = true;
      else parsed.ctrl = true;
    } else if (part && !parsed.key) {
      parsed.key = KEY_ALIASES[part] ?? part;
    } else {
      throw new Error(`Invalid shortcut "${binding}": exactly one non-modifier key is required.`);
    }
  }
  if (!parsed.key) throw new Error(`Invalid shortcut "${binding}": exactly one non-modifier key is required.`);
  // Shift turns a digit into a symbol ("!" on US layouts), so event.key never equals the digit;
  // with alt held the event.code fallback still matches it.
  if (parsed.shift && !parsed.alt && /^[0-9]$/.test(parsed.key)) {
    throw new Error(`Invalid shortcut "${binding}": shift+<digit> never matches; use alt or a letter instead.`);
  }
  // Shift+"/" reports event.key "?", so a shift+<symbol> binding can never fire.
  if (parsed.shift && isSymbolKey(parsed.key)) {
    throw new Error(`Invalid shortcut "${binding}": shift+<symbol> never matches; bind the character it produces (e.g. "?") instead.`);
  }
  return parsed;
}

// Punctuation keys already encode shift in event.key, so matches() ignores shift on
// them and the signature does too. Letters in any script, digits and space are not
// punctuation: shift+é and shift+space are distinct bindings.
function isSymbolKey(key: string): boolean {
  return key.length === 1 && !/[\p{L}\p{N}\s]/u.test(key);
}


function signature(binding: ParsedBinding): string {
  const shift = binding.shift && !isSymbolKey(binding.key);
  return `${binding.ctrl || binding.meta ? "mod+" : ""}${binding.alt ? "alt+" : ""}${shift ? "shift+" : ""}${binding.key}`;
}

const RESERVED_SIGNATURES = new Set(RESERVED_BROWSER_SHORTCUTS.map((binding) => signature(parseBinding(binding))));

export function isReservedShortcut(binding: string): boolean {
  return RESERVED_SIGNATURES.has(signature(parseBinding(binding)));
}

const SYMBOL_CODES: Record<string, string> = {
  Backquote: "`",
  Backslash: "\\",
  BracketLeft: "[",
  BracketRight: "]",
  Comma: ",",
  Equal: "=",
  Minus: "-",
  Period: ".",
  Quote: "'",
  Semicolon: ";",
  Slash: "/",
  Space: " ",
};

// macOS Option turns letters, digits and symbols into other characters (Option+F is "ƒ",
// Option+/ is "÷"), so an alt binding falls back to the physical key. A letter or digit is
// kept (AZERTY Alt+A stays "a"); a digit key always reads as its digit so alt+shift+<digit>
// matches; any other key still reporting printable ASCII is kept, so Alt+Shift+/ stays "?".
function eventKey(event: KeyboardEvent): string {
  const key = event.key.toLowerCase();
  if (!event.altKey || /^[a-z0-9]$/.test(key)) return key;
  const code = event.code ?? "";
  const digit = /^Digit([0-9])$/.exec(code);
  if (digit) return digit[1];
  if (/^[\x20-\x7e]$/.test(key)) return key;
  const letter = /^Key([A-Z])$/.exec(code);
  if (letter) return letter[1].toLowerCase();
  return SYMBOL_CODES[code] ?? key;
}

function matches(binding: ParsedBinding, event: KeyboardEvent): boolean {
  const key = eventKey(event);
  return (
    key === binding.key &&
    event.altKey === binding.alt &&
    event.ctrlKey === binding.ctrl &&
    event.metaKey === binding.meta &&
    (isSymbolKey(key) || event.shiftKey === binding.shift)
  );
}

const TEXT_ROLES = new Set(["textbox", "combobox", "searchbox"]);
// Native controls only: an ARIA-role element has no built-in activation, so Enter and
// Space reach the scope's shortcut (Radix items handle their own keys and preventDefault).
const INTERACTIVE_SELECTOR = "button, a[href], summary";

function isFormTarget(target: EventTarget | null): boolean {
  return (
    target instanceof HTMLElement &&
    (["INPUT", "TEXTAREA", "SELECT"].includes(target.tagName) || TEXT_ROLES.has(target.getAttribute("role") ?? ""))
  );
}

// Enter and Space already activate a focused native button, link or summary; a shortcut
// on those keys must not run on top of that activation.
function isActivationOnInteractive(event: KeyboardEvent, scopeRoot: HTMLElement | undefined): boolean {
  if (event.ctrlKey || event.metaKey || event.altKey) return false;
  if (event.key !== "Enter" && event.key !== " ") return false;
  const target = event.target;
  return target instanceof HTMLElement && target !== scopeRoot && target.matches(INTERACTIVE_SELECTOR);
}

function isEditableTarget(target: EventTarget | null): boolean {
  return target instanceof HTMLElement && target.isContentEditable;
}

export function AppShortcutProvider({ children }: { children: ReactNode }) {
  const registrations = useRef(new Set<Registration>());
  const modalStack = useRef<{ token: symbol; depth: number; seq: number }[]>([]);
  const modalSeq = useRef(0);
  // Boundaries a keydown passed through in the React tree (portals included).
  const modalEvents = useRef(new WeakMap<Event, Set<symbol>>());
  const activeLocalRef = useRef<{ token: symbol; element: HTMLElement } | null>(null);
  const [activeLocal, setActiveLocalState] = useState<symbol | null>(null);

  const setActiveLocal = useCallback((token: symbol | null, element: HTMLElement | null) => {
    activeLocalRef.current = token && element ? { token, element } : null;
    setActiveLocalState(token);
  }, []);

  // A scope's unmount clears activation only if that scope still owns it.
  const releaseLocal = useCallback((token: symbol) => {
    if (activeLocalRef.current?.token !== token) return;
    activeLocalRef.current = null;
    setActiveLocalState(null);
  }, []);

  const register = useCallback((registration: Registration) => {
    registrations.current.add(registration);
    return () => void registrations.current.delete(registration);
  }, []);

  // Child effects run before parent effects, so push order is not nesting order:
  // the top modal is the deepest boundary, then the most recently activated.
  const pushModal = useCallback((token: symbol, depth: number) => {
    modalStack.current.push({ token, depth, seq: ++modalSeq.current });
    return () => {
      modalStack.current = modalStack.current.filter((entry) => entry.token !== token);
    };
  }, []);

  const markModalEvent = useCallback((event: Event, token: symbol) => {
    const tokens = modalEvents.current.get(event) ?? new Set<symbol>();
    tokens.add(token);
    modalEvents.current.set(event, tokens);
  }, []);

  useEffect(() => {
    const clearIfOutside = (event: Event) => {
      const current = activeLocalRef.current;
      if (current && !(event.target instanceof Node && current.element.contains(event.target))) {
        setActiveLocal(null, null);
      }
    };

    const onKeyDown = (event: KeyboardEvent) => {
      // Autofill and synthetic events can dispatch keydown without a key.
      if (event.defaultPrevented || typeof event.key !== "string") return;
      const topModal = modalStack.current.reduce<{ token: symbol; depth: number; seq: number } | undefined>(
        (top, entry) => (!top || entry.depth > top.depth || (entry.depth === top.depth && entry.seq > top.seq) ? entry : top),
        undefined,
      )?.token;
      const domModal =
        Array.from(document.querySelectorAll(DOM_MODAL_SELECTOR))
          .filter((element) => !element.closest(POPPER_WRAPPER_SELECTOR))
          .at(-1) ?? null;
      // A Radix popover opened from inside the dialog is portaled out of it but belongs to it;
      // it is portaled after the dialog, so a popper that precedes the dialog is a background one.
      const insideDomModal = (node: Node | null) => {
        if (!domModal || !node) return false;
        if (domModal.contains(node)) return true;
        const element = node.nodeType === Node.ELEMENT_NODE ? (node as Element) : node.parentElement;
        const popper = element?.closest(POPPER_WRAPPER_SELECTOR) ?? null;
        return !!(popper && domModal.compareDocumentPosition(popper) & Node.DOCUMENT_POSITION_FOLLOWING);
      };
      // A region removed without a focusin/pointerdown elsewhere would otherwise stay active.
      if (activeLocalRef.current && !activeLocalRef.current.element.isConnected) setActiveLocal(null, null);
      const local = activeLocalRef.current;
      const localInsideDomModal = insideDomModal(local?.element ?? null);
      const targetInsideDomModal = insideDomModal(event.target instanceof Node ? event.target : null);
      // With a DOM dialog open, a boundary owns the key only if it travelled through that
      // boundary; an unrelated dialog on top of it does not.
      const throughTopModal = !!(topModal && modalEvents.current.get(event)?.has(topModal));
      const activationOnInteractive = isActivationOnInteractive(event, local?.element);

      let best: { registration: Registration; rank: number } | null = null;
      for (const registration of registrations.current) {
        const { options } = registration;
        if (options.enabled === false) continue;
        if (event.repeat && !options.allowRepeat) continue;
        if (isFormTarget(event.target) && !options.enableOnFormTags) continue;
        if (isEditableTarget(event.target) && !options.enableOnContentEditable) continue;
        if (!registration.bindings.some((binding) => matches(binding, event))) continue;
        if (activationOnInteractive) continue;

        const scope = options.scope;
        let rank: number;
        if (scope?.kind === "modal") {
          if (scope.token !== topModal || (domModal && !(targetInsideDomModal && throughTopModal))) continue;
          rank = 3;
        } else if (scope?.kind === "local") {
          if (topModal || (domModal && !localInsideDomModal)) continue;
          if (scope.token !== local?.token) continue;
          rank = 2;
        } else {
          if (topModal || domModal) continue;
          rank = 1;
        }
        if (!best || rank > best.rank || (rank === best.rank && registration.order > best.registration.order)) {
          best = { registration, rank };
        }
      }
      if (!best) return;
      const modified = event.ctrlKey || event.metaKey || event.altKey;
      if (best.registration.options.preventDefault ?? (modified || best.registration.options.scope !== undefined)) {
        event.preventDefault();
      }
      best.registration.callback(event);
    };

    document.addEventListener("keydown", onKeyDown);
    document.addEventListener("focusin", clearIfOutside, true);
    document.addEventListener("pointerdown", clearIfOutside, true);
    return () => {
      document.removeEventListener("keydown", onKeyDown);
      document.removeEventListener("focusin", clearIfOutside, true);
      document.removeEventListener("pointerdown", clearIfOutside, true);
    };
  }, [setActiveLocal]);

  const value = useMemo(
    () => ({ register, activeLocal, setActiveLocal, releaseLocal, pushModal, markModalEvent }),
    [register, activeLocal, setActiveLocal, releaseLocal, pushModal, markModalEvent],
  );
  return <ShortcutContext.Provider value={value}>{children}</ShortcutContext.Provider>;
}

function useShortcutContext(hook: string): ShortcutContextValue {
  const context = useContext(ShortcutContext);
  if (!context) throw new Error(`${hook} must be used within AppShortcutProvider.`);
  return context;
}

// Spread `scope.bindings` onto the region; its shortcuts fire only while focus or
// the last pointer-down is inside it.
export function useShortcutScope(name: string): ShortcutScope {
  const { activeLocal, setActiveLocal, releaseLocal } = useShortcutContext("useShortcutScope");
  const token = useRef(Symbol(name)).current;
  useEffect(() => () => releaseLocal(token), [releaseLocal, token]);
  const activate = useCallback(
    (event: { currentTarget: HTMLElement }) => setActiveLocal(token, event.currentTarget),
    [setActiveLocal, token],
  );
  return useMemo<ShortcutScope>(
    () => ({
      name,
      kind: "local",
      token,
      bindings: { onFocusCapture: activate, onPointerDownCapture: activate },
      containsActiveElement: activeLocal === token,
    }),
    [name, token, activate, activeLocal],
  );
}

// Wrap custom (non-Radix) modals. While active, only this boundary's modal-scoped
// shortcuts fire; Radix dialogs are detected from the DOM without a wrapper. The
// display:contents wrapper only observes keydowns routed through this subtree.
export function ModalShortcutBoundary({ active, children, name }: { active: boolean; children: ReactNode; name: string }) {
  const { pushModal, markModalEvent } = useShortcutContext("ModalShortcutBoundary");
  const parent = useContext(ModalScopeContext);
  const depth = (parent?.depth ?? 0) + 1;
  const token = useRef(Symbol(name)).current;
  useEffect(() => (active ? pushModal(token, depth) : undefined), [active, pushModal, token, depth]);
  const scope = useMemo<ModalShortcutScope>(() => ({ name, kind: "modal", token, depth }), [name, token, depth]);
  return (
    <ModalScopeContext.Provider value={scope}>
      <div style={{ display: "contents" }} onKeyDownCapture={(event) => markModalEvent(event.nativeEvent, token)}>
        {children}
      </div>
    </ModalScopeContext.Provider>
  );
}

export function useModalShortcutScope(): ModalShortcutScope {
  const scope = useContext(ModalScopeContext);
  if (!scope) throw new Error("useModalShortcutScope must be used within ModalShortcutBoundary.");
  return scope;
}

let registrationOrder = 0;

export function useAppShortcut(
  keys: string | readonly string[],
  callback: (event: KeyboardEvent) => void,
  options: AppShortcutOptions = {},
): void {
  const { register } = useShortcutContext("useAppShortcut");
  const keyList = typeof keys === "string" ? [keys] : keys;
  const keySignature = keyList.join("\u0000");
  const scoped = Boolean(options.scope);
  const bindings = useMemo(() => {
    // Dev and tests fail loudly; a published app drops the binding instead of crashing the page.
    const reject = (message: string) => {
      if (!import.meta.env?.PROD) throw new Error(message);
      console.error(message);
    };
    const raw: string[] = [];
    const parsed: ParsedBinding[] = [];
    for (const key of keySignature.split("\u0000")) {
      try {
        parsed.push(parseBinding(key));
        raw.push(key);
      } catch (error) {
        reject(error instanceof Error ? error.message : String(error));
      }
    }
    const reserved = raw.filter((_, index) => RESERVED_SIGNATURES.has(signature(parsed[index])));
    if (reserved.length > 0) {
      reject(
        `Shortcut "${reserved.join('", "')}" is reserved by the browser (find, save, print, new tab, reload, zoom, devtools...). Use a plain key scoped with useShortcutScope instead.`,
      );
    }
    let allowed = parsed.filter((binding) => !RESERVED_SIGNATURES.has(signature(binding)));
    if (!scoped) {
      const modified = allowed.filter((binding) => binding.alt || binding.ctrl || binding.meta || FUNCTION_KEY.test(binding.key));
      if (modified.length !== allowed.length) {
        reject(
          `Unscoped app shortcuts require a modifier or function key. Use useShortcutScope for plain keys (got "${raw.join('", "')}").`,
        );
      }
      allowed = modified;
      const textEdit = allowed.filter((binding) => (binding.ctrl || binding.meta) && !binding.alt && TEXT_EDIT_KEYS.has(binding.key));
      if (textEdit.length > 0) {
        reject(
          `Unscoped shortcuts may not take select-all, copy, paste, cut or undo (got "${raw.join('", "')}"). Scope them with useShortcutScope.`,
        );
        allowed = allowed.filter((binding) => !textEdit.includes(binding));
      }
    }
    return allowed.length === parsed.length ? parsed : allowed;
  }, [keySignature, scoped]);
  const callbackRef = useRef(callback);
  callbackRef.current = callback;
  const optionsRef = useRef(options);
  optionsRef.current = options;

  useEffect(() => {
    const registration: Registration = {
      bindings,
      callback: (event) => callbackRef.current(event),
      get options() {
        return optionsRef.current;
      },
      order: ++registrationOrder,
    };
    return register(registration);
  }, [bindings, register]);
}
