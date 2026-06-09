// Claude Code session namer
//
// Gives each Claude Code session a short, stable, human-readable name derived
// from the user's first real prompt in the session transcript. Results are
// cached by session_id so every statusline tick is O(1) after the first call.
//
// Exports: getSessionName({ sessionId, transcriptPath }) -> string | null

const fs = require('fs');
const path = require('path');

const HOME = process.env.HOME || process.env.USERPROFILE;
const CACHE_PATH = path.join(HOME, '.claude', '.session-names.json');
const MAX_CACHE_ENTRIES = 200;
const MAX_NAME_CHARS = 40;
const NAME_WORD_COUNT = 4;

// Words to drop when deriving a name. Articles, prepositions, pronouns, common
// auxiliary/generic verbs, and filler words that rarely describe a task.
const STOPWORDS = new Set([
  // articles / determiners
  'a', 'an', 'the', 'this', 'that', 'these', 'those', 'some', 'any', 'each',
  'every', 'all', 'both', 'few', 'more', 'most', 'other', 'such', 'no', 'nor',
  'not', 'only', 'own', 'same', 'than', 'too', 'very', 'another', 'one', 'two',
  // pronouns
  'i', 'me', 'my', 'mine', 'myself', 'we', 'us', 'our', 'ours', 'ourselves',
  'you', 'your', 'yours', 'yourself', 'yourselves', 'he', 'him', 'his',
  'himself', 'she', 'her', 'hers', 'herself', 'it', 'its', 'itself', 'they',
  'them', 'their', 'theirs', 'themselves', 'what', 'which', 'who', 'whom',
  'whose',
  // auxiliaries / modals
  'am', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has',
  'had', 'having', 'do', 'does', 'did', 'doing', 'will', 'would', 'shall',
  'should', 'can', 'could', 'may', 'might', 'must', 'ought',
  // prepositions / conjunctions
  'and', 'or', 'but', 'if', 'then', 'else', 'so', 'as', 'of', 'at', 'by',
  'for', 'with', 'about', 'against', 'between', 'into', 'through', 'during',
  'before', 'after', 'above', 'below', 'to', 'from', 'in', 'on', 'off', 'out',
  'over', 'under', 'again', 'further', 'once', 'here', 'there', 'when',
  'where', 'why', 'how', 'because', 'until', 'while', 'since', 'without',
  'within', 'upon', 'via',
  // generic verbs that don't convey subject
  'make', 'makes', 'made', 'making', 'get', 'gets', 'got', 'getting', 'use',
  'uses', 'used', 'using', 'go', 'goes', 'went', 'going', 'take', 'takes',
  'took', 'taking', 'want', 'wants', 'wanted', 'need', 'needs', 'needed',
  'try', 'tries', 'tried', 'trying', 'help', 'helps', 'helped', 'helping',
  'let', 'lets', 'letting', 'see', 'sees', 'saw', 'seeing', 'look', 'looks',
  'looked', 'looking', 'think', 'thinks', 'thought', 'thinking', 'know',
  'knows', 'knew', 'knowing', 'work', 'works', 'worked', 'working',
  'start', 'starts', 'started', 'starting', 'begin', 'begins', 'began',
  'beginning', 'please', 'just', 'now', 'then', 'really', 'also', 'very',
  'much', 'many', 'lots', 'like', 'ok', 'okay', 'yes', 'yeah', 'sure',
  'actually', 'basically', 'maybe', 'kind', 'sort', 'thing', 'things',
  'stuff', 'way', 'ways', 'time', 'times',
  // generic nouns/adjectives that rarely describe the subject
  'new', 'old', 'small', 'big', 'good', 'bad', 'nice', 'better', 'best',
  'worst', 'more', 'less', 'first', 'last', 'next', 'previous', 'current',
  'main', 'item', 'items', 'part', 'parts', 'bit', 'bits', 'line', 'lines',
]);

// --- cache i/o --------------------------------------------------------------

function loadCache() {
  try {
    return JSON.parse(fs.readFileSync(CACHE_PATH, 'utf8'));
  } catch {
    return {};
  }
}

function saveCache(cache) {
  try {
    const entries = Object.entries(cache);
    if (entries.length > MAX_CACHE_ENTRIES) {
      entries.sort((a, b) => (b[1].lastAccess || 0) - (a[1].lastAccess || 0));
      cache = Object.fromEntries(entries.slice(0, MAX_CACHE_ENTRIES));
    }
    fs.writeFileSync(CACHE_PATH, JSON.stringify(cache, null, 2));
  } catch {}
}

// --- transcript parsing -----------------------------------------------------

// Pull text out of a user message whose `content` field may be a string or an
// array of structured content blocks (text, tool_result, image, ...).
function extractText(content) {
  if (!content) return '';
  if (typeof content === 'string') return content;
  if (!Array.isArray(content)) return '';
  let out = '';
  for (const block of content) {
    if (!block || typeof block !== 'object') continue;
    if (block.type === 'text' && typeof block.text === 'string') {
      out += block.text + ' ';
    }
  }
  return out;
}

// Strip XML-ish wrapper tags Claude Code injects around command output,
// caveats, and system reminders. We only want the raw user prose.
function stripWrappers(text) {
  if (!text) return '';
  return text
    .replace(/<command-name>[\s\S]*?<\/command-name>/g, ' ')
    .replace(/<command-message>[\s\S]*?<\/command-message>/g, ' ')
    .replace(/<command-args>[\s\S]*?<\/command-args>/g, ' ')
    .replace(/<local-command-stdout>[\s\S]*?<\/local-command-stdout>/g, ' ')
    .replace(/<local-command-stderr>[\s\S]*?<\/local-command-stderr>/g, ' ')
    .replace(/<local-command-caveat>[\s\S]*?<\/local-command-caveat>/g, ' ')
    .replace(/<system-reminder>[\s\S]*?<\/system-reminder>/g, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

// Read the first real user prompt out of a JSONL transcript. A "real" prompt
// is a user-role message that carries a promptId field and is not marked meta.
function firstUserPrompt(transcriptPath) {
  if (!transcriptPath) return '';
  let raw;
  try {
    raw = fs.readFileSync(transcriptPath, 'utf8');
  } catch {
    return '';
  }
  const lines = raw.split('\n');
  for (const line of lines) {
    if (!line) continue;
    let entry;
    try {
      entry = JSON.parse(line);
    } catch {
      continue;
    }
    if (entry.type !== 'user') continue;
    if (entry.isMeta) continue;
    if (!entry.promptId) continue;
    const text = stripWrappers(extractText(entry.message && entry.message.content));
    if (text.length >= 3) return text;
  }
  return '';
}

// --- name generation --------------------------------------------------------

function generateName(text) {
  if (!text) return null;
  const tokens = text
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, ' ')
    .split(/\s+/)
    .filter(Boolean);

  const keep = [];
  const seen = new Set();
  for (const tok of tokens) {
    if (tok.length < 3) continue;
    if (STOPWORDS.has(tok)) continue;
    if (seen.has(tok)) continue;
    seen.add(tok);
    keep.push(tok);
    if (keep.length >= NAME_WORD_COUNT) break;
  }

  // Fallback: if stopword filtering left us with nothing, take raw leading
  // tokens so we still produce *something* rather than "unnamed".
  if (keep.length === 0) {
    for (const tok of tokens) {
      if (tok.length < 2) continue;
      if (seen.has(tok)) continue;
      seen.add(tok);
      keep.push(tok);
      if (keep.length >= NAME_WORD_COUNT) break;
    }
  }
  if (keep.length === 0) return null;

  const titleCased = keep
    .map(w => w[0].toUpperCase() + w.slice(1))
    .join(' ');

  return titleCased.length > MAX_NAME_CHARS
    ? titleCased.slice(0, MAX_NAME_CHARS - 1).trimEnd() + '…'
    : titleCased;
}

// --- public api -------------------------------------------------------------

function getSessionName({ sessionId, transcriptPath }) {
  if (!sessionId) return null;

  const cache = loadCache();
  const cached = cache[sessionId];
  const now = Date.now();

  // Settled name → return immediately.
  if (cached && cached.name && cached.settled) {
    cached.lastAccess = now;
    saveCache(cache);
    return cached.name;
  }

  // Otherwise, try to derive (or re-derive) a name from the transcript. We
  // re-derive until the first real user prompt appears because the statusline
  // may fire before the user has actually typed anything.
  const text = firstUserPrompt(transcriptPath);
  const name = generateName(text);

  if (!name) {
    // No prompt yet. Remember that we tried so we don't burn the cache, but
    // don't settle.
    cache[sessionId] = {
      name: cached && cached.name ? cached.name : null,
      settled: false,
      lastAccess: now,
      created: (cached && cached.created) || now,
    };
    saveCache(cache);
    return cache[sessionId].name;
  }

  cache[sessionId] = {
    name,
    settled: true,
    lastAccess: now,
    created: (cached && cached.created) || now,
  };
  saveCache(cache);
  return name;
}

module.exports = { getSessionName, generateName, firstUserPrompt };
