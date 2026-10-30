/*
 * Informational privacy and cookie notice shared by the FastTrack catalog, the static
 * resource pages (r/**), and the Agents cost calculator.
 *
 * It records no choice and makes no consent call. It only describes what these pages store
 * in the browser and which services they contact, and opens from any element that carries a
 * data-privacy-notice attribute. It injects its own styles, reads the page's existing CSS
 * variables, and makes no network requests. If anything fails it does nothing, and the
 * triggers stay hidden.
 *
 * Triggers are <button type="button" data-privacy-notice aria-haspopup="dialog" hidden>Privacy notice</button>
 * and are revealed by this script, so a blocked or failed script leaves no dead button.
 */
(function () {
  'use strict';
  try {
    if (window.__ftPrivacyNotice) return;
    window.__ftPrivacyNotice = true;

    var PRIVACY_URL = 'https://privacy.microsoft.com/en-us/privacystatement';
    var overlay = null;
    var dialog = null;
    var lastTrigger = null;

    var CSS = [
      ':where([data-privacy-notice]){background:none;border:0;padding:0;margin:0;font:inherit;color:inherit;text-decoration:underline;text-underline-offset:2px;cursor:pointer}',
      'html.ft-pn-open{overflow:hidden}',
      '.ft-pn-overlay{position:fixed;inset:0;z-index:2147483000;display:flex;align-items:center;justify-content:center;padding:12px;background:rgba(10,10,20,.6)}',
      '.ft-pn-overlay[hidden]{display:none}',
      '.ft-pn-modal{display:flex;flex-direction:column;width:min(600px,100%);max-height:calc(100vh - 24px);max-height:calc(100dvh - 24px);box-sizing:border-box;',
      'background:var(--surface,var(--card,#fff));color:var(--text,#171717);border:1px solid var(--border,#e4e4e7);border-radius:14px;',
      'box-shadow:0 24px 48px rgba(0,0,0,.35);font-family:var(--font-sans,"Segoe UI",system-ui,-apple-system,sans-serif);font-size:15px;line-height:1.55;text-align:left}',
      '.ft-pn-modal:focus{outline:none}',
      '.ft-pn-modal *{box-sizing:border-box}',
      '.ft-pn-modal :focus-visible{outline:2px solid var(--accent,var(--link,#4f46e5));outline-offset:2px;border-radius:4px}',
      '.ft-pn-head{display:flex;align-items:flex-start;justify-content:space-between;gap:12px;padding:18px 20px 12px;border-bottom:1px solid var(--border,#e4e4e7)}',
      '.ft-pn-head h2{margin:0;font-size:1.2rem;line-height:1.3;font-weight:700;color:var(--text,#171717)}',
      '.ft-pn-x{flex:0 0 auto;width:36px;height:36px;min-height:36px;display:inline-flex;align-items:center;justify-content:center;padding:0;margin:-4px -6px 0 0;',
      'font:inherit;font-size:22px;line-height:1;color:var(--text-muted,var(--muted,#52525b));background:transparent;border:1px solid transparent;border-radius:8px;cursor:pointer}',
      '.ft-pn-x:hover{background:var(--surface-hover,var(--input,#f4f4f5));border-color:var(--border,#e4e4e7);color:var(--text,#171717)}',
      '.ft-pn-body{flex:1 1 auto;min-height:0;overflow-y:auto;padding:4px 20px 12px;-webkit-overflow-scrolling:touch}',
      '.ft-pn-body p{margin:.6rem 0;color:var(--text-muted,var(--muted,#52525b))}',
      '.ft-pn-body p.ft-pn-lead{color:var(--text,#171717)}',
      '.ft-pn-body section{padding:14px 0;border-bottom:1px solid var(--border,#e4e4e7)}',
      '.ft-pn-body section:last-child{border-bottom:0}',
      '.ft-pn-body h3{margin:0 0 4px;font-size:1rem;line-height:1.4;font-weight:700;color:var(--text,#171717)}',
      '.ft-pn-body ul{margin:.5rem 0;padding-left:1.25rem;color:var(--text-muted,var(--muted,#52525b))}',
      '.ft-pn-body li{margin:.3rem 0}',
      '.ft-pn-body strong{color:var(--text,#171717);font-weight:600}',
      '.ft-pn-body code{font-family:var(--font-mono,ui-monospace,Consolas,monospace);font-size:.85em;padding:.05rem .35rem;border-radius:4px;',
      'background:var(--surface-hover,var(--input,#f4f4f5));border:1px solid var(--border,#e4e4e7);color:var(--text,#171717)}',
      '.ft-pn-body a,.ft-pn-foot a{color:var(--link,var(--accent,#4f46e5));text-decoration:underline;text-underline-offset:2px}',
      '.ft-pn-meta{margin:.6rem 0 0;font-family:var(--font-mono,ui-monospace,Consolas,monospace);font-size:.75rem;color:var(--text-muted,var(--muted,#52525b));overflow-wrap:anywhere}',
      '.ft-pn-foot{display:flex;flex-wrap:wrap;align-items:center;justify-content:space-between;gap:10px 16px;padding:12px 20px 16px;border-top:1px solid var(--border,#e4e4e7);font-size:.875rem}',
      '.ft-pn-btn{font:inherit;font-weight:600;font-size:.9375rem;min-height:40px;padding:.45rem 1.2rem;color:var(--text,#171717);',
      'background:var(--surface-hover,var(--input,#f4f4f5));border:1px solid var(--border-strong,var(--border,#d4d4d8));border-radius:8px;cursor:pointer}',
      '.ft-pn-btn:hover{border-color:var(--accent,var(--link,#4f46e5))}',
      '@media (max-width:480px){.ft-pn-head{padding:14px 16px 10px}.ft-pn-body{padding:2px 16px 8px}.ft-pn-foot{padding:10px 16px 14px}}'
    ].join('');

    var CONTENT = [
      '<div class="ft-pn-head">',
      '<h2 id="ft-pn-title">Privacy &amp; cookie notice</h2>',
      '<button type="button" class="ft-pn-x" data-ft-pn-close aria-label="Close privacy notice">&times;</button>',
      '</div>',
      '<div class="ft-pn-body">',
      '<p id="ft-pn-intro" class="ft-pn-lead">This notice describes what this FastTrack site stores in your browser and which other services your browser contacts. It is for information only. The site has no on-page setting to change these items.</p>',

      '<section aria-labelledby="ft-pn-h-analytics">',
      '<h3 id="ft-pn-h-analytics">Product analytics (Microsoft Clarity)</h3>',
      '<p>The catalog, the resource pages, and the Agents cost calculator use Microsoft Clarity to understand how the site is used and to count resource views and downloads. Clarity gathers:</p>',
      '<ul>',
      '<li>Which pages you view</li>',
      '<li>Where you click and how far you scroll, which Clarity can present as session replays and heatmaps</li>',
      '<li>How long you stay on a page</li>',
      '<li>Your approximate country and your device and browser type</li>',
      '<li>Which resource you open, preview, or download. These events feed the view and download counts shown in the catalog.</li>',
      '</ul>',
      '<p>Clarity sets two first-party cookies, <code>_clck</code> and <code>_clsk</code>, and sends data to clarity.ms. To avoid it, you can block cookies or clarity.ms in your browser or with a content blocker.</p>',
      '<div class="ft-pn-meta">Cookies: _clck, _clsk &middot; clarity.ms &middot; <a href="' + PRIVACY_URL + '" target="_blank" rel="noopener">Microsoft Privacy Statement</a></div>',
      '</section>',

      '<section aria-labelledby="ft-pn-h-storage">',
      '<h3 id="ft-pn-h-storage">Saved in your browser</h3>',
      '<p>To remember your choices between visits, pages use your browser&rsquo;s local storage. These values stay on your device, and the site&rsquo;s own code does not send them anywhere.</p>',
      '<ul>',
      '<li><code>theme</code>: your light or dark theme on the catalog and resource pages</li>',
      '<li><code>ft-density</code>: your layout density in the catalog</li>',
      '</ul>',
      '<p>Some tools save their own settings the same way. The Agent 365 Enablement Checklist keeps your plan in local storage, and the Agent 365 Technical Advisory viewer keeps its theme choice.</p>',
      '</section>',

      '<section aria-labelledby="ft-pn-h-third">',
      '<h3 id="ft-pn-h-third">Content from other services</h3>',
      '<ul>',
      '<li><strong>Google Fonts.</strong> The catalog and resource pages load fonts from fonts.googleapis.com and fonts.gstatic.com.</li>',
      '<li><strong>giscus and GitHub.</strong> A resource&rsquo;s detail view in the catalog loads comments and reactions from giscus.app, which uses GitHub Discussions in the microsoft/FastTrack repository. You sign in with GitHub to react or comment.</li>',
      '<li><strong>Links to other sites</strong>, such as Microsoft Learn and GitHub, follow those sites&rsquo; own privacy statements.</li>',
      '</ul>',
      '</section>',

      '<section aria-labelledby="ft-pn-h-offline">',
      '<h3 id="ft-pn-h-offline">Downloadable and offline tools</h3>',
      '<p>The Agent 365 Enablement Checklist and the Agent 365 Customer Implementation Guide are single HTML files. When you open them directly or download them, they load nothing from other sites and contain no analytics. The checklist stores your plan only in your browser&rsquo;s local storage. The Agent 365 Technical Advisory viewer likewise loads nothing from other sites and contains no analytics.</p>',
      '<p>When any of these open inside the catalog&rsquo;s viewer, the analytics described above still apply to the catalog page.</p>',
      '</section>',
      '</div>',
      '<div class="ft-pn-foot">',
      '<a href="' + PRIVACY_URL + '" target="_blank" rel="noopener">Microsoft Privacy Statement</a>',
      '<button type="button" class="ft-pn-btn" data-ft-pn-close>Close</button>',
      '</div>'
    ].join('');

    function injectStyles() {
      if (document.getElementById('ft-pn-styles')) return;
      var style = document.createElement('style');
      style.id = 'ft-pn-styles';
      style.textContent = CSS;
      document.head.appendChild(style);
    }

    function build() {
      if (overlay) return;
      injectStyles();
      overlay = document.createElement('div');
      overlay.className = 'ft-pn-overlay';
      overlay.hidden = true;
      dialog = document.createElement('div');
      dialog.className = 'ft-pn-modal';
      dialog.setAttribute('role', 'dialog');
      dialog.setAttribute('aria-modal', 'true');
      dialog.setAttribute('aria-labelledby', 'ft-pn-title');
      dialog.setAttribute('aria-describedby', 'ft-pn-intro');
      dialog.tabIndex = -1;
      dialog.innerHTML = CONTENT;
      overlay.appendChild(dialog);
      overlay.addEventListener('click', function (event) {
        if (event.target === overlay) close();
      });
      var closers = dialog.querySelectorAll('[data-ft-pn-close]');
      for (var i = 0; i < closers.length; i++) closers[i].addEventListener('click', close);
      document.body.appendChild(overlay);
    }

    function focusable() {
      var nodes = dialog.querySelectorAll('a[href], button:not([disabled]), [tabindex]:not([tabindex="-1"])');
      return Array.prototype.slice.call(nodes);
    }

    function onKeydown(event) {
      if (!overlay || overlay.hidden) return;
      if (event.key === 'Escape' || event.key === 'Esc') {
        event.preventDefault();
        event.stopPropagation();
        close();
        return;
      }
      if (event.key !== 'Tab') return;
      var items = focusable();
      if (!items.length) {
        event.preventDefault();
        dialog.focus();
        return;
      }
      var first = items[0];
      var last = items[items.length - 1];
      var active = document.activeElement;
      if (!dialog.contains(active)) {
        event.preventDefault();
        first.focus();
      } else if (event.shiftKey && (active === first || active === dialog)) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && active === last) {
        event.preventDefault();
        first.focus();
      }
    }

    function onFocusIn(event) {
      if (overlay && !overlay.hidden && !dialog.contains(event.target)) dialog.focus();
    }

    function open(trigger) {
      build();
      if (!overlay.hidden) return;
      lastTrigger = trigger || document.activeElement;
      overlay.hidden = false;
      document.documentElement.classList.add('ft-pn-open');
      document.addEventListener('keydown', onKeydown, true);
      document.addEventListener('focusin', onFocusIn, true);
      var body = dialog.querySelector('.ft-pn-body');
      if (body) body.scrollTop = 0;
      dialog.focus();
    }

    function close() {
      if (!overlay || overlay.hidden) return;
      overlay.hidden = true;
      document.documentElement.classList.remove('ft-pn-open');
      document.removeEventListener('keydown', onKeydown, true);
      document.removeEventListener('focusin', onFocusIn, true);
      var target = lastTrigger;
      lastTrigger = null;
      if (target && document.documentElement.contains(target) && typeof target.focus === 'function') target.focus();
    }

    document.addEventListener('click', function (event) {
      var node = event.target;
      var trigger = node && node.closest ? node.closest('[data-privacy-notice]') : null;
      if (!trigger) return;
      event.preventDefault();
      open(trigger);
    });

    function reveal() {
      injectStyles();
      var triggers = document.querySelectorAll('[data-privacy-notice]');
      for (var i = 0; i < triggers.length; i++) triggers[i].hidden = false;
    }

    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', reveal);
    else reveal();
  } catch (error) {
    /* The notice is optional; fail silently. */
  }
})();
