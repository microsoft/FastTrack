(function () {
  var script = document.currentScript;
  var slug = document.documentElement.getAttribute('data-slug');

  var toggle = document.getElementById('themeToggle');
  if (toggle) {
    toggle.addEventListener('click', function () {
      var next = document.documentElement.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', next);
      try { localStorage.setItem('theme', next); } catch (e) { /* storage unavailable */ }
    });
  }

  var copy = document.getElementById('copyLink');
  if (copy) {
    copy.addEventListener('click', function () {
      var url = copy.getAttribute('data-url');
      var done = function () {
        var label = copy.textContent;
        copy.textContent = 'Link copied';
        setTimeout(function () { copy.textContent = label; }, 1800);
      };
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(url).then(done, function () { window.prompt('Copy this link', url); });
      } else {
        window.prompt('Copy this link', url);
      }
    });
  }

  // Same Clarity project and event names as the catalog so per-resource view stats keep working.
  var clarityId = script && script.getAttribute('data-clarity');
  if (clarityId) {
    (function (c, l, a, r, i, t, y) {
      c[a] = c[a] || function () { (c[a].q = c[a].q || []).push(arguments); };
      t = l.createElement(r); t.async = 1; t.src = 'https://www.clarity.ms/tag/' + i;
      y = l.getElementsByTagName(r)[0]; y.parentNode.insertBefore(t, y);
    })(window, document, 'clarity', 'script', clarityId);
    if (slug) {
      window.clarity('set', 'page', location.pathname);
      window.clarity('set', 'resource', slug);
      window.clarity('event', 'resource_view');
    }
    document.querySelectorAll('[data-event]').forEach(function (element) {
      element.addEventListener('click', function () { window.clarity('event', element.getAttribute('data-event')); });
    });
  }
})();
