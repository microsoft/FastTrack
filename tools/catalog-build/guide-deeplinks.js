// Adds deep links to the Customer Implementation Guide: #advanced/<key> opens the Detailed view, shows
// the section or step, scrolls to it, and highlights it. <key> is a step code such as 4.04a or 12b, or a
// section number such as 04 (pp for Power Platform). The Enablement Checklist links to these addresses.
//
// The guide is a generated single file, so the change is applied as a small, repeatable patch:
//
//   node guide-deeplinks.js          apply (or refresh) the patch in place
//   node guide-deeplinks.js --check  fail if the guide is missing the patch or has drifted from it
//
// Each inserted block sits between /*cx-deeplinks:<id>:start*/ and /*cx-deeplinks:<id>:end*/ markers,
// so applying the patch again replaces a block instead of adding a second one. If the guide is
// regenerated without the patch, `npm run check` fails and points here.
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { codePattern, guideFolder } from './agent365-content.js';

export const guidePath = join(guideFolder, 'index.html');

const escapeAttribute = text => text.replace(/&/g, '&amp;').replace(/"/g, '&quot;');
const wrap = (id, body) => `/*cx-deeplinks:${id}:start*/${body}/*cx-deeplinks:${id}:end*/`;

const outerPatches = [
  {
    id: 'hash',
    find: 'function current(){ return location.hash==="#advanced"?"advanced":"simple"; }',
    body: String.raw`
  function parseHash(){ var m=/^#(simple|advanced)(?:\/(.+))?$/.exec(location.hash); return m?{view:m[1],key:m[2]||""}:{view:"simple",key:""}; }
  function current(){ return parseHash().view; }
  `
  },
  {
    id: 'select',
    find: 'try{ if(location.hash!=="#"+k){ history.replaceState(null,"","#"+k); } }catch(e){ try{location.hash=k;}catch(e2){} }',
    // Keep a deep link such as #advanced/4.04a when the view it names is already showing.
    body: String.raw`try{ var hm=/^#(simple|advanced)(?:\/|$)/.exec(location.hash); if(!hm||hm[1]!==k){ history.replaceState(null,"","#"+k); } }catch(e){ try{location.hash=k;}catch(e2){} }`
  },
  {
    id: 'wire',
    find: '  select(current(),false);\n})();</script></body></html>',
    insertAt: 0,
    body: String.raw`
  var advancedLoaded=false;
  function sendGoto(){
    var h=parseHash(); var f=frames.advanced;
    if(h.view!=="advanced"||!h.key||!f||!advancedLoaded||!f.contentWindow)return;
    window.requestAnimationFrame(function(){ try{ f.contentWindow.postMessage({type:"cx-goto",key:h.key},"*"); }catch(e){} });
  }
  if(frames.advanced){
    frames.advanced.addEventListener("load",function(){ advancedLoaded=true; sendGoto(); });
    try{ var d0=frames.advanced.contentDocument; if(d0&&d0.readyState==="complete"&&d0.body&&d0.body.children.length)advancedLoaded=true; }catch(e){}
  }
  window.addEventListener("hashchange",sendGoto);
  window.addEventListener("message",function(e){
    var d=e.data;
    if(!d||d.type!=="cx-goto-result"||!frames.advanced||e.source!==frames.advanced.contentWindow)return;
    root.setAttribute("data-deeplink",(d.found?"found:":"missing:")+d.key);
    announce(d.found?"Opened the linked step":"That step was not found in the Detailed view");
  });
  sendGoto();
`
  }
];

// Runs inside the Detailed view's own document, next to its existing tab and link handling.
const innerPatch = {
  id: 'inner',
  find: 'document.addEventListener(&quot;click&quot;,onClick,true);\n})();\n})();</script></body></html>',
  insertAt: 'document.addEventListener(&quot;click&quot;,onClick,true);\n})();\n'.length,
  body: String.raw`
(function(){
  var CODE_RE=/^(${codePattern})\s*·/;
  var index=null;
  function keyOf(code){ return code.toLowerCase().replace("·","-"); }
  function buildIndex(){
    index={};
    [].slice.call(document.querySelectorAll("h2")).forEach(function(h){
      var t=h.textContent.replace(/\s+/g," ").trim();
      var m=/^(\d{2})\./.exec(t);
      var k=m?m[1]:(/^Power Platform/i.test(t)?"pp":"");
      if(k&&!index[k])index[k]=h;
    });
    [].slice.call(document.querySelectorAll("h3,h4")).forEach(function(h){
      var m=CODE_RE.exec(h.textContent.replace(/\s+/g," ").trim());
      if(!m)return;
      var k=keyOf(m[1]);
      if(!index[k])index[k]=h;
    });
  }
  var st=document.createElement("style");
  st.textContent=".cx-deeplink-target{outline:3px solid #0078d4;outline-offset:4px;border-radius:8px}@media (forced-colors: active){.cx-deeplink-target{outline-color:Highlight}}";
  document.head.appendChild(st);
  function goToKey(key){
    if(!index)buildIndex();
    var el=index[String(key).toLowerCase()];
    if(!el)return false;
    var panel=el.closest?el.closest(".panel"):null;
    if(panel&&!panel.classList.contains("active")&&typeof activate==="function")activate(panel.id,false);
    var target=(el.closest&&el.closest(".task-head")&&el.closest(".task-card"))||el;
    [].slice.call(document.querySelectorAll(".cx-deeplink-target")).forEach(function(n){ n.classList.remove("cx-deeplink-target"); });
    var rm=false;
    try{ rm=!!(window.matchMedia&&window.matchMedia("(prefers-reduced-motion: reduce)").matches); }catch(e){}
    try{ target.scrollIntoView({behavior:rm?"auto":"smooth",block:"start"}); }catch(e){ try{ target.scrollIntoView(); }catch(e2){} }
    var had=el.hasAttribute("tabindex");
    if(!had)el.setAttribute("tabindex","-1");
    try{ el.focus({preventScroll:true}); }catch(e){}
    target.classList.add("cx-deeplink-target");
    window.setTimeout(function(){ target.classList.remove("cx-deeplink-target"); },4000);
    return true;
  }
  window.addEventListener("message",function(e){
    var d=e.data;
    if(!d||d.type!=="cx-goto"||e.source!==window.parent)return;
    var ok=goToKey(d.key);
    try{ window.parent.postMessage({type:"cx-goto-result",key:d.key,found:ok},"*"); }catch(err){}
  });
})();
`
};

function advancedRange(source) {
  const start = source.indexOf('id="cxAdvanced"');
  const open = start < 0 ? -1 : source.indexOf('srcdoc="', start);
  if (open < 0) throw new Error('The guide has no Detailed view frame (id="cxAdvanced"); the deep-link patch cannot be applied.');
  const from = open + 'srcdoc="'.length;
  return { from, to: source.indexOf('"', from) };
}

function applyPatch(text, patch, escape) {
  const body = escape ? escapeAttribute(patch.body) : patch.body;
  const wrapped = wrap(patch.id, body);
  const startMarker = `/*cx-deeplinks:${patch.id}:start*/`;
  const endMarker = `/*cx-deeplinks:${patch.id}:end*/`;
  const markerAt = text.indexOf(startMarker);
  if (markerAt >= 0) {
    const endAt = text.indexOf(endMarker, markerAt);
    if (endAt < 0) throw new Error(`The guide has a deep-link block "${patch.id}" with no end marker.`);
    return text.slice(0, markerAt) + wrapped + text.slice(endAt + endMarker.length);
  }
  const occurrences = text.split(patch.find).length - 1;
  if (occurrences !== 1) {
    throw new Error(`The guide changed shape: expected one place to add the deep-link block "${patch.id}" but found ${occurrences}. Update tools/catalog-build/guide-deeplinks.js.`);
  }
  const at = text.indexOf(patch.find);
  if (patch.insertAt === undefined) return text.slice(0, at) + wrapped + text.slice(at + patch.find.length);
  const split = at + patch.insertAt;
  return text.slice(0, split) + wrapped + text.slice(split);
}

export function patchGuide(source) {
  let next = source;
  for (const patch of outerPatches) next = applyPatch(next, patch, false);
  const { from, to } = advancedRange(next);
  const patchedFrame = applyPatch(next.slice(from, to), innerPatch, true);
  return next.slice(0, from) + patchedFrame + next.slice(to);
}

export function checkGuide(source) {
  try {
    return patchGuide(source) === source
      ? { ok: true, problem: '' }
      : { ok: false, problem: 'The guide has no deep-link support, or it is out of date. Run `npm run patch:guide` in tools/catalog-build and commit the result.' };
  } catch (error) {
    return { ok: false, problem: error.message };
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const source = readFileSync(guidePath, 'utf8');
  if (process.argv.includes('--check')) {
    const result = checkGuide(source);
    if (!result.ok) {
      console.error(result.problem);
      process.exitCode = 1;
    } else {
      console.log('The guide has current deep-link support.');
    }
  } else {
    const patched = patchGuide(source);
    if (patched === source) console.log('The guide already has current deep-link support.');
    else {
      writeFileSync(guidePath, patched);
      console.log('Added deep-link support to the guide.');
    }
  }
}
