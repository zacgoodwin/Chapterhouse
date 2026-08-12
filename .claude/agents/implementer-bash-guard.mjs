// PreToolUse guard for the ticket-implementer agent: exact-shape allowlist,
// not a program allowlist. Ticket bodies are public, untrusted input —
// deploys, gh mutations, and network clients stay in the parent session.
// Hook-level fence: the OS-level boundary (writable guard, credential
// stripping) is tracked in #100. Exit 2 = block, message on stderr.
import { readFileSync } from 'node:fs';

// Argument-free-form utilities (read-only or filesystem-local). No `find`
// (-exec), no `npx`/`cd` (fence hops), no interpreters here.
const SIMPLE = new Set(['ls', 'cat', 'echo', 'mkdir', 'grep', 'rg', 'head', 'tail', 'wc', 'diff', 'pwd']);

// Local-only git verbs. Nothing that reaches the network, reconfigures git,
// or defines aliases.
const GIT_OK = new Set(['status', 'add', 'commit', 'diff', 'log', 'show', 'restore', 'checkout',
  'switch', 'branch', 'stash', 'rev-parse', 'mv', 'rm', 'grep', 'blame', 'describe']);

const WORKFLOW_PATH = /(^|[\\/])scripts[\\/](ship|lib|triage)([\\/]|$)/;
const EVAL_FLAG = /^(-[a-z]*[ep]|--eval|--print)/;

// Normalize a word for path checks: strip quotes and leading ./ .\ chains.
const norm = (w) => w.replace(/^['"]|['"]$/g, '').replace(/^(\.[\\/])+/, '');

// Returns null when allowed, else the reason. Pure — gate-tested.
export function denyReason(command) {
  if (typeof command !== 'string' || !command.trim()) return 'empty command';
  if (/\$\(|`|<\(|>\(/.test(command)) return 'command/process substitution is blocked';
  const segments = command.split(/(?:&&|\|\||[;|&\n])+/).map((s) => s.trim()).filter(Boolean);
  for (const seg of segments) {
    let words = seg.replace(/^([A-Za-z_][A-Za-z0-9_]*=\S+\s+)+/, '').split(/\s+/); // skip VAR=x prefixes
    if (words[0] === 'rtk') words = words.slice(1); // rtk proxies its first argument
    const program = words[0] ?? '';
    const args = words.slice(1);
    const normed = words.map(norm);

    // Workflow scripts are never runnable here, whatever the spelling
    // (./scripts/..., absolute paths, cd tricks are out since cd is denied).
    if (normed.some((w) => WORKFLOW_PATH.test(w))) return 'implementers may not touch workflow scripts';

    if (SIMPLE.has(program)) continue;

    if (program === 'git') {
      if (words.some((w) => w === '-c' || w === '-C' || w.startsWith('--config') || w.startsWith('--git-dir') || w.startsWith('--work-tree') || w.startsWith('--exec-path'))) {
        return 'git -c/-C/--config/--git-dir flags are blocked';
      }
      const sub = args.find((w) => !w.startsWith('-'));
      if (!GIT_OK.has(sub)) return `'git ${sub ?? ''}' is not on the local-git allowlist — pushing and remotes are the parent's job`;
      continue;
    }

    if (program === 'node' || program === 'ruby') {
      if (words.some((w) => EVAL_FLAG.test(w))) return 'inline interpreter eval is blocked';
      continue; // repo files + tests; workflow scripts already excluded above
    }

    if (program === 'npm' || program === 'yarn') {
      const sub = args[0] ?? '';
      // test/run only: exec/x/dlx/install would run arbitrary or lifecycle
      // code fetched from the network. Dependency changes are the parent's.
      if (!['test', 'run', 't', '--version', '-v'].includes(sub)) {
        return `'${program} ${sub}' is blocked — only ${program} test / ${program} run <script>`;
      }
      continue;
    }

    if (program === 'bundle') {
      // bundle exec <runner> where the runner itself is an allowed shape.
      if (args[0] !== 'exec') return `'bundle ${args[0] ?? ''}' is blocked — only bundle exec`;
      const runner = args[1] ?? '';
      if (!['rspec', 'rubocop', 'rails', 'rake', 'ruby'].includes(runner)) return `'bundle exec ${runner}' is not allowlisted`;
      if (words.includes('runner')) return "'rails runner' is inline eval — blocked";
      if (runner === 'ruby' && words.some((w) => EVAL_FLAG.test(w))) return 'inline interpreter eval is blocked';
      continue;
    }

    if (program === 'bin/rails' || program === 'rails' || program === 'rake' || program === 'rspec'
      || program === 'bin/rspec' || program === 'bin/rubocop' || program === 'rubocop') {
      if (words.includes('runner')) return "'rails runner' is inline eval — blocked";
      if (words.includes('dbconsole') || words.includes('console')) return 'rails console is blocked';
      continue;
    }

    if (program === 'st') continue; // stax: local branch management

    return `'${program}' is not on the implementer allowlist`;
  }
  return null;
}

if (process.argv[1] && import.meta.url.endsWith(process.argv[1].replace(/\\/g, '/').split('/').pop())) {
  const input = JSON.parse(readFileSync(0, 'utf8'));
  const reason = denyReason(input?.tool_input?.command ?? '');
  if (reason) {
    console.error(`Blocked: ${reason}. Deploys and GitHub mutations happen in the parent ticket-ship session.`);
    process.exit(2);
  }
}
