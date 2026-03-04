#!/usr/bin/env node
/**
 * update-message-center.js
 *
 * Fetches real Microsoft 365 Message Center posts from the merill/mc
 * open-source archive (https://github.com/merill/mc) and updates the
 * messageCenterPosts array in index.html.
 *
 * The merill/mc repo scrapes the M365 Service Communications API daily
 * and publishes the results as JSON. We filter for Copilot/agent-relevant
 * posts within a 60-day lookback / 60-day lookahead window, then assign
 * agentAudience targeting based on affected services and tags.
 *
 * Run manually:  node scripts/update-message-center.js
 * Automated via: .github/workflows/update-message-center.yml (every Monday)
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

const INDEX_PATH = path.resolve(__dirname, '..', 'index.html');
const MC_DATA_URL =
  'https://raw.githubusercontent.com/merill/mc/main/%40data/messages.json';

// ── helpers ──────────────────────────────────────────────────────────────────

function iso(d) {
  return d.toISOString().slice(0, 10);
}

function addDays(d, n) {
  const r = new Date(d);
  r.setDate(r.getDate() + n);
  return r;
}

function fetchJson(url) {
  return new Promise((resolve, reject) => {
    https
      .get(url, { headers: { 'User-Agent': 'FastTrack-MC-Updater/1.0' } }, (res) => {
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          return fetchJson(res.headers.location).then(resolve, reject);
        }
        if (res.statusCode !== 200) {
          return reject(new Error(`HTTP ${res.statusCode} from ${url}`));
        }
        const chunks = [];
        res.on('data', (d) => chunks.push(d));
        res.on('end', () => {
          try {
            resolve(JSON.parse(Buffer.concat(chunks).toString()));
          } catch (e) {
            reject(e);
          }
        });
      })
      .on('error', reject);
  });
}

// ── category mapping ─────────────────────────────────────────────────────────
// merill/mc uses camelCase categories; we map to display names.

const categoryMap = {
  planForChange: 'Plan for Change',
  stayInformed: 'Stay Informed',
  preventOrFixIssues: 'Prevent or Fix Issues',
  actionRequired: 'Action Required',
};

// ── severity mapping ─────────────────────────────────────────────────────────

const severityMap = {
  high: 'high',
  normal: 'medium',
  low: 'low',
};

// ── agent audience heuristic ─────────────────────────────────────────────────
// Assign agentAudience based on affected services and keywords in the title.
// A post can target multiple agent types. Posts that don't match any specific
// agent get 'all'.

function inferAgentAudience(post) {
  const services = Array.isArray(post.Services) ? post.Services : [];
  const serviceSet = new Set(
    services
      .map((s) => (s || '').toLowerCase().trim())
      .filter(Boolean)
  );
  const titleLower = (post.Title || '').toLowerCase();
  const bodyLower = (post.summary || '').toLowerCase();
  const text = `${titleLower} ${bodyLower}`;

  // Score each agent from service-name and keyword signals; only strong scores
  // become targeted audiences.
  const scores = {
    researcherAnalyst: 0,
    lite: 0,
    full: 0,
    sharepoint: 0,
    declarative: 0,
    toolkit: 0,
  };
  const add = (agent, points) => {
    scores[agent] += points;
  };
  const hasService = (name) => serviceSet.has(name.toLowerCase());

  // Exclusion: Dynamics-only updates are not agent-specific unless explicitly
  // about Copilot agents.
  const mentionsAgentConcept = /(copilot|agent|copilot studio|declarative|custom engine|mcp|a2a)/.test(text);
  if (
    serviceSet.size > 0 &&
    [...serviceSet].every((s) => s.includes('dynamics 365')) &&
    !mentionsAgentConcept
  ) {
    return ['all'];
  }

  // Exclusion: generic Microsoft 365 suite/app tags are too broad alone.
  const genericSuiteServices = new Set(['microsoft 365 suite', 'microsoft 365 apps']);
  if (
    serviceSet.size > 0 &&
    [...serviceSet].every((s) => genericSuiteServices.has(s)) &&
    !mentionsAgentConcept
  ) {
    return ['all'];
  }

  // A) Precise service-name mapping (exact matches).
  if (hasService('Microsoft 365 Copilot')) {
    add('researcherAnalyst', 3);
    add('lite', 3);
    add('full', 3);
    add('sharepoint', 3);
    add('declarative', 3);
    add('toolkit', 3);
  }
  if (hasService('Microsoft 365 Copilot Chat')) {
    add('researcherAnalyst', 4);
    add('declarative', 3);
  }
  if (hasService('SharePoint Online')) {
    add('sharepoint', 4);
    add('declarative', 3);
  }
  if (hasService('Microsoft Teams')) {
    add('declarative', 3);
    add('toolkit', 3);
  }
  if (hasService('Power Apps') || hasService('Power Automate')) {
    add('lite', 3);
    add('full', 4);
  }
  if (hasService('Copilot Studio')) {
    add('lite', 4);
    add('full', 4);
    add('declarative', 3);
  }
  if (hasService('Microsoft Purview')) {
    add('full', 3);
    add('declarative', 3);
    add('toolkit', 3);
  }
  if (hasService('Microsoft Entra')) {
    add('full', 3);
    add('declarative', 3);
  }
  if (hasService('Exchange Online') || hasService('Outlook')) {
    add('researcherAnalyst', 4);
  }
  if (hasService('Power BI')) add('full', 4);
  if (hasService('Microsoft Intune')) add('full', 4);

  // B) Keyword refinement (title + summary).
  if (/\bdeclarative agent(s)?\b/.test(text)) {
    add('declarative', 4);
    add('toolkit', 3);
  }
  if (/\bcustom agent(s)?\b|\bcustom engine\b/.test(text)) {
    add('toolkit', 4);
    add('full', 3);
  }
  if (/\bcopilot studio\b/.test(text)) {
    add('lite', 3);
    add('full', 3);
  }
  if (/\bplugin(s)?\b|\bgraph connector(s)?\b|\bcopilot connector(s)?\b|\bmanifest(s)?\b/.test(text)) {
    add('toolkit', 3);
    add('declarative', 2);
  }
  if (/\borchestrat/.test(text)) {
    add('declarative', 3);
    add('full', 3);
  }
  if (/\bagent store\b|\bmarketplace\b/.test(text)) {
    add('declarative', 3);
    add('toolkit', 3);
    add('full', 2);
  }
  if (/\bmcp\b|model context protocol/.test(text)) add('toolkit', 4);
  if (/\ba2a\b|agent-to-agent/.test(text)) {
    add('toolkit', 4);
    add('declarative', 3);
  }
  if ((/\bsharepoint\b/.test(text) || /\bsite(s)?\b/.test(text)) && /\bagent(s)?\b/.test(text)) {
    add('sharepoint', 4);
  }
  if (/\bsharepoint\b/.test(text)) {
    add('sharepoint', 2);
    add('declarative', 2);
  }
  if (/\bresearcher\b|\banalyst\b|\breasoning\b|\bo3\b/.test(text)) {
    add('researcherAnalyst', 4);
  }
  if (/\bcopilot chat\b|\bbusiness chat\b/.test(text)) add('researcherAnalyst', 4);
  if (/\bword\b|\boutlook\b/.test(text)) add('researcherAnalyst', 2);
  if (/\bagent\b.*\bchat\b|\bchat\b.*\bagent\b/.test(text)) {
    add('researcherAnalyst', 2);
    add('declarative', 2);
  }
  if (/\bgrounding\b/.test(text)) {
    add('declarative', 3);
    add('full', 3);
  }
  if (/\bretention\b|\bcompliance\b|\bdlp\b|\bsensitivity\b|\bpurview\b/.test(text)) {
    add('full', 3);
    add('declarative', 3);
    add('toolkit', 3);
  }
  if (/\blicense\b|\blicensing\b|\badmin center\b|\btenant\b/.test(text)) {
    add('full', 3);
    add('toolkit', 3);
  }
  if (/\bteams\b/.test(text) && /\bapp(s)?\b|\bbot(s)?\b/.test(text)) {
    add('toolkit', 3);
    add('declarative', 3);
  }
  if (/\bpower automate\b|\bflow(s)?\b/.test(text)) {
    add('full', 3);
    add('lite', 3);
  }
  if (/\bcomputer use\b|\brpa\b/.test(text)) add('full', 4);
  if (/\bdynamics 365\b/.test(text) && /\bcopilot\b|\bagent(s)?\b/.test(text)) {
    add('full', 2);
    add('toolkit', 2);
  }

  // C) Scored targeting: include only agents above threshold; fallback to 'all'
  // for low-signal posts.
  const threshold = 2;
  const matched = Object.keys(scores).filter((k) => scores[k] >= threshold);
  return matched.length ? matched : ['all'];
}

// ── transform merill/mc post to our schema ───────────────────────────────────

function transformPost(raw) {
  const summaryDetail = (raw.Details || []).find((d) => d.Name === 'Summary');
  const summary = summaryDetail
    ? summaryDetail.Value
    : (raw.Body?.Content || '').replace(/<[^>]+>/g, '').slice(0, 300);

  const category = categoryMap[raw.Category] || 'Stay Informed';
  const severity = severityMap[raw.Severity] || 'medium';

  const services = raw.Services || [];
  const tags = (raw.Tags || [])
    .map((t) =>
      t
        .toLowerCase()
        .replace(/\s+/g, '-')
    )
    .slice(0, 4);

  const datePublished = raw.StartDateTime
    ? iso(new Date(raw.StartDateTime))
    : null;
  const actionRequiredBy = raw.ActionRequiredByDateTime
    ? iso(new Date(raw.ActionRequiredByDateTime))
    : null;

  // Determine status
  const now = new Date();
  const pubDate = new Date(raw.StartDateTime);
  const daysDiff = Math.floor((now - pubDate) / (1000 * 60 * 60 * 24));
  let status;
  if (daysDiff > 30) status = 'completed';
  else if (daysDiff >= 0) status = 'active';
  else status = 'upcoming';

  return {
    id: raw.Id,
    title: raw.Title,
    category,
    severity,
    datePublished,
    actionRequiredBy,
    status,
    services,
    summary: summary.replace(/'/g, "\u2019"), // curly quote to avoid JS string issues
    tags,
    isHighImpact: raw.IsMajorChange === true || severity === 'high',
    agentAudience: inferAgentAudience({ ...raw, summary }),
  };
}

// ── filter for Copilot Agent relevance ───────────────────────────────────────
// Include posts that are about Copilot agents OR that IT admins / users
// managing agents would want to know about (licensing, governance, platform
// changes to services agents depend on). Exclude general end-user Copilot
// features (UI tweaks, chat history, etc.) and unrelated "copilot" products
// (Viva Glint Copilot, Dynamics Copilot, Windows Copilot).

function isCopilotAgentRelevant(raw) {
  const title = (raw.Title || '').toLowerCase();
  const svcStr = (raw.Services || []).join(' ').toLowerCase();
  const summaryDetail = (raw.Details || []).find((d) => d.Name === 'Summary');
  const summary = summaryDetail ? summaryDetail.Value.toLowerCase() : '';
  const combined = `${title} ${svcStr} ${summary}`;

  // ── Exclude: non-agent Copilot products ──
  // These mention "copilot" but aren't about M365 Copilot agents.
  const excludeProducts = [
    'viva glint',
    'viva learning',
    'viva engage',
    'viva insights',
    'windows copilot',
    'github copilot',
    'security copilot',
    'edge copilot',
  ];
  if (excludeProducts.some((kw) => combined.includes(kw)) &&
      !combined.includes('agent') && !combined.includes('copilot studio')) {
    return false;
  }

  // ── Strong signals: unambiguously agent-related ──
  const strongKeywords = [
    'copilot studio',
    'declarative agent',
    'custom agent',
    'custom engine agent',
    'copilot agent',
    'microsoft 365 agents',
    'm365 agents',
    'agents toolkit',
    'agents sdk',
    'agent store',
    'agent builder',
    'agent-to-agent',
    'a2a protocol',
    'model context protocol',
    'mcp server',
    'orchestrator',
    'copilot extensibility',
    'copilot plugin',
    'message extension',
    'sharepoint agent',
  ];
  if (strongKeywords.some((kw) => combined.includes(kw))) return true;

  // ── Copilot Studio service tag: auto-include ──
  if (svcStr.includes('copilot studio')) return true;

  // ── M365 Copilot service posts: include if they mention agent-adjacent
  // topics that admins/users building agents care about ──
  const hasCopilotService = svcStr.includes('microsoft 365 copilot');
  if (hasCopilotService) {
    const agentAdjacentPatterns = [
      /\bagent(s)?\b/,
      /\bplugin(s)?\b/,
      /\bgraph connector(s)?\b/,
      /\bcopilot connector(s)?\b/,
      /\bknowledge.{0,20}grounding\b/,
      /\bextensibility\b/,
      /\bdeclarative\b/,
      /\blicens(e|ing)\b/,            // licensing changes affect agent rollout
      /\badmin center\b/,             // admin controls for agents
      /\bcopilot app\b/,              // the app where agents are surfaced
      /\bretrieval\b/,                // retrieval API for agents
      /\bdata loss prevention\b|\bdlp\b/, // DLP policies affect agents
      /\bsensitivity label/,          // sensitivity labels affect agent access
      /\bretention polic/,            // retention for agent conversations
      /\bcompliance\b/,               // compliance controls for agents
      /\bpurview\b/,                  // Purview governance for agents
      /\bconditional access\b/,       // CA policies affect agent access
    ];
    if (agentAdjacentPatterns.some((rx) => rx.test(combined))) return true;
  }

  // ── SharePoint service: include if it mentions agents or Copilot ──
  if (svcStr.includes('sharepoint') && /\b(copilot|agent)\b/.test(combined)) {
    return true;
  }

  // ── Teams service: include if it mentions agents, bots, or apps ──
  if (svcStr.includes('microsoft teams') && /\b(agent|bot|app.*copilot|copilot.*app)\b/.test(combined)) {
    return true;
  }

  // ── Power Platform services: include if they mention copilot or agents ──
  if (/power (apps|automate|platform)/.test(svcStr) && /\b(copilot|agent)\b/.test(combined)) {
    return true;
  }

  // ── Governance/security services: include if they mention copilot ──
  if (/purview|entra/.test(svcStr) && /\bcopilot\b/.test(combined)) {
    return true;
  }

  return false;
}

// ── serialise a post to inline JS ────────────────────────────────────────────

function serialisePost(p) {
  const esc = (s) => s.replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\r?\n/g, ' ').replace(/\s{2,}/g, ' ');
  const arr = (a) => '[' + a.map((v) => `'${esc(v)}'`).join(', ') + ']';
  const parts = [
    `id: '${p.id}'`,
    `title: '${esc(p.title)}'`,
    `category: '${p.category}'`,
    `severity: '${p.severity}'`,
    `datePublished: '${p.datePublished}'`,
    `actionRequiredBy: ${p.actionRequiredBy ? `'${p.actionRequiredBy}'` : 'null'}`,
    `status: '${p.status}'`,
    `services: ${arr(p.services)}`,
    `summary: '${esc(p.summary)}'`,
    `tags: ${arr(p.tags)}`,
    `isHighImpact: ${p.isHighImpact}`,
    `agentAudience: ${arr(p.agentAudience)}`,
  ];
  return `          { ${parts.join(', ')} }`;
}

// ── main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('⏳ Fetching message center posts from merill/mc...');
  const rawPosts = await fetchJson(MC_DATA_URL);
  console.log(`   Fetched ${rawPosts.length} total posts from archive`);

  const today = new Date();
  const windowStart = addDays(today, -60);
  const windowEnd = addDays(today, 60);

  // Filter to 60-day window + Copilot-relevant
  const inWindow = rawPosts.filter((p) => {
    if (!p.StartDateTime) return false;
    const d = new Date(p.StartDateTime);
    return d >= windowStart && d <= windowEnd;
  });
  console.log(`   ${inWindow.length} posts within 60-day window`);

  const copilotPosts = inWindow.filter(isCopilotAgentRelevant);
  console.log(`   ${copilotPosts.length} Copilot agent-relevant posts`);

  // Sort by date descending (newest first)
  copilotPosts.sort(
    (a, b) => new Date(b.StartDateTime) - new Date(a.StartDateTime)
  );

  // Cap at 40 before transform (we'll drop 'all'-only posts after scoring)
  const candidates = copilotPosts.slice(0, 40);

  // Transform to our schema
  const allPosts = candidates.map(transformPost);

  // Drop posts that couldn't be mapped to any specific agent type — these
  // passed the relevance filter but the scoring heuristic couldn't assign
  // them to a specific agent, so they'd clutter every agent's feed.
  const posts = allPosts.filter(
    (p) => !p.agentAudience.includes('all')
  );
  console.log(`   ${allPosts.length - posts.length} posts dropped (no specific agent match)`);
  console.log(`   ${posts.length} posts with specific agent targeting`);

  // Final cap at 30
  const finalPosts = posts.slice(0, 30);

  // Verify agent audience distribution
  const agents = ['researcherAnalyst', 'lite', 'full', 'sharepoint', 'declarative', 'toolkit'];
  for (const a of agents) {
    const count = finalPosts.filter(
      (p) => p.agentAudience.includes(a)
    ).length;
    console.log(`   → ${a}: ${count} posts`);
  }

  // Read and update index.html
  const html = fs.readFileSync(INDEX_PATH, 'utf8');

  const startMarker = '        const messageCenterPosts = [';
  const endMarker = '        ];';

  const startIdx = html.indexOf(startMarker);
  if (startIdx === -1) {
    console.error('Could not find messageCenterPosts start marker in index.html');
    process.exit(1);
  }

  const searchFrom = startIdx + startMarker.length;
  const endIdx = html.indexOf(endMarker, searchFrom);
  if (endIdx === -1) {
    console.error('Could not find messageCenterPosts end marker in index.html');
    process.exit(1);
  }

  const postsJs = finalPosts.map(serialisePost).join(',\n');
  const updated =
    html.slice(0, startIdx) +
    startMarker +
    '\n' +
    postsJs +
    ',\n' +
    html.slice(endIdx);

  fs.writeFileSync(INDEX_PATH, updated, 'utf8');

  // Update the "Updated MONTH YEAR" badge
  const monthYear = today.toLocaleDateString('en-US', {
    month: 'long',
    year: 'numeric',
  });
  const updatedHtml = fs
    .readFileSync(INDEX_PATH, 'utf8')
    .replace(/Updated \w+ \d{4}/, `Updated ${monthYear}`);
  fs.writeFileSync(INDEX_PATH, updatedHtml, 'utf8');

  console.log(
    `\n✅ Updated ${finalPosts.length} real message center posts (window: ${iso(windowStart)} to ${iso(windowEnd)})`
  );
  console.log(`✅ Updated date badge to "${monthYear}"`);
  console.log(`📖 Source: https://github.com/merill/mc`);
}

main().catch((err) => {
  console.error('❌ Failed to update message center posts:', err.message);
  process.exit(1);
});

