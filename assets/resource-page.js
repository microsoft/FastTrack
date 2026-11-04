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
  var downloadSlug = document.documentElement.getAttribute('data-download-slug');
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
    } else if (downloadSlug) {
      // Loading this page is what counts as a download: the stats read its URL from Clarity.
      window.clarity('set', 'page', location.pathname);
      window.clarity('set', 'resource', downloadSlug);
      window.clarity('event', 'resource_download');
    }
    document.querySelectorAll('[data-event]').forEach(function (element) {
      element.addEventListener('click', function () { window.clarity('event', element.getAttribute('data-event')); });
    });
  }

  // Views come from the published stats, so the page needs no rebuild when the counts change. The row
  // stays hidden if the file cannot be read. The latest counts are taken from the staged stats when
  // they can be read in time (assets/live-stats.js). Keep VIEWS_TIP in step with the catalog (index.html).
  var VIEWS_TIP = "Catalog page views recorded by Microsoft Clarity since Jul 2026, plus views of the resource's GitHub folder from saved snapshots (Apr\u2013Jun and 14\u201327 Oct 2026). Some days were never captured, so this is a minimum.";
  var LIVE_STATS_WAIT_MS = 1500;
  var viewsRow = document.getElementById('viewsRow');
  var viewsValue = document.getElementById('viewsValue');
  if (viewsRow && viewsValue && slug && script && script.src && window.fetch) {
    var liveStats = window.FastTrackLiveStats ? window.FastTrackLiveStats.fetch() : Promise.resolve(null);
    var liveOrTimeout = Promise.race([liveStats, new Promise(function (resolve) { setTimeout(function () { resolve(null); }, LIVE_STATS_WAIT_MS); })]);
    var localStats = fetch(new URL('../resource-stats.json', script.src).href, { cache: 'no-cache' })
      .then(function (response) { if (!response.ok) throw new Error('HTTP ' + response.status); return response.json(); });
    Promise.all([localStats, liveOrTimeout])
      .then(function (results) {
        var data = results[0];
        if (!data || !data.resources || typeof data.resources !== 'object') return;
        var entry = data.resources[slug];
        var views = entry ? Number(entry.views) : 0;
        var fresh = window.FastTrackLiveStats ? window.FastTrackLiveStats.pick(data, results[1]) : null;
        if (fresh && Object.prototype.hasOwnProperty.call(fresh, slug)) views = fresh[slug];
        if (!isFinite(views) || views < 0) views = 0;
        var short = views >= 10000 ? (views / 1000).toFixed(0) + 'k' : views >= 1000 ? (views / 1000).toFixed(1) + 'k' : String(views);
        viewsValue.textContent = short;
        viewsRow.title = views.toLocaleString('en-US') + (views === 1 ? ' view. ' : ' views. ') + VIEWS_TIP;
        viewsRow.hidden = false;
      })
      .catch(function () { /* leave the row hidden */ });
  }

  // The download page saves the file by itself; its visible link covers blocked scripts.
  var autoDownload = document.querySelector('[data-autodownload]');
  if (autoDownload) {
    setTimeout(function () { autoDownload.click(); }, 600);
  }
})();
