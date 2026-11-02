/*
 * Latest view counts for the catalog and the resource pages.
 *
 * The daily traffic workflow keeps a fresh resource-stats.json on the automation/traffic-stats-staging
 * branch. Publishing it to master needs a pull request that GitHub Actions cannot open here, so the
 * copy on the site is only as fresh as the last merged weekly PR. This script reads the staging copy
 * straight from raw.githubusercontent.com, which serves it to any site and caches it for five minutes.
 *
 * Only the view counts are taken from it. The local file stays the source for everything else
 * (upvotes, discussion links), and it is the fallback when the staging copy cannot be read, is
 * older than the local file, or was rendered by a different counting method (sources.views).
 * Exposes window.FastTrackLiveStats = { url, fetch, pick }. It never throws and never blocks a page.
 */
(function () {
  'use strict';

  var LIVE_STATS_URL = 'https://raw.githubusercontent.com/microsoft/FastTrack/automation/traffic-stats-staging/resource-stats.json';
  var TIMEOUT_MS = 5000;

  // Resolves with the parsed staging file, or null on any failure or timeout.
  function fetchLive() {
    return new Promise(function (resolve) {
      try {
        if (!window.fetch) { resolve(null); return; }
        var controller = window.AbortController ? new AbortController() : null;
        var timer = setTimeout(function () {
          if (controller) controller.abort();
          resolve(null);
        }, TIMEOUT_MS);
        var options = { credentials: 'omit', referrerPolicy: 'no-referrer' };
        if (controller) options.signal = controller.signal;
        window.fetch(LIVE_STATS_URL, options)
          .then(function (response) {
            if (!response.ok) throw new Error('HTTP ' + response.status);
            return response.json();
          })
          .then(function (doc) { clearTimeout(timer); resolve(doc); })
          .catch(function () { clearTimeout(timer); resolve(null); });
      } catch (error) {
        resolve(null);
      }
    });
  }

  // Returns { slug: views } when the staging copy can replace the local view counts, else null.
  function pick(local, live) {
    try {
      if (!local || !live || !live.resources || typeof live.resources !== 'object') return null;
      if (!local.sources || !live.sources || !local.sources.views || local.sources.views !== live.sources.views) return null;
      var localTime = Date.parse(local.generatedAt);
      var liveTime = Date.parse(live.generatedAt);
      if (!(liveTime >= localTime)) return null;

      var views = {};
      var found = false;
      Object.keys(live.resources).forEach(function (slug) {
        var entry = live.resources[slug];
        var count = entry ? Number(entry.views) : NaN;
        if (isFinite(count) && count >= 0) {
          views[slug] = Math.round(count);
          found = true;
        }
      });
      return found ? views : null;
    } catch (error) {
      return null;
    }
  }

  window.FastTrackLiveStats = { url: LIVE_STATS_URL, fetch: fetchLive, pick: pick };
})();
