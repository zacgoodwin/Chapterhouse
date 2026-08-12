// Drain ordering for ticket-ship: prompt builder for the one latent ordering
// call, plus the deterministic edge validator. The queue filter already
// excludes tickets with OPEN blockers, so in-queue edges are belt-and-braces —
// but the invariant is absolute: no ticket ever precedes its blocker.
export function orderPrompt(tickets, edges = []) {
  return `Order these tickets for serial execution (one merges before the next starts)
on zacgoodwin/Chapterhouse. Judgment criteria: security fixes first, cluster
tickets touching the same files/subsystem adjacently, small unblockers early.
Hard constraints (blocker before blocked, always): ${JSON.stringify(edges)}
(format: [blocked, blockedBy]).

Tickets:
${JSON.stringify(tickets, null, 2)}

Reply with ONLY a JSON array of ticket numbers in execution order, containing
every ticket exactly once. No prose, no fences.`;
}

// order: [numbers]; edges: [[blocked, blockedBy], ...]. Returns list of
// violations; empty = valid. Never throws — a malformed latent reply must
// surface as a violation so the snapshot-order fallback runs.
export function validateOrder(order, tickets, edges = []) {
  if (!Array.isArray(order) || !order.every(Number.isInteger)) {
    return [`order must be an array of integer ticket numbers, got ${JSON.stringify(order)}`];
  }
  const problems = [];
  const want = tickets.map((t) => t.number).sort((a, b) => a - b);
  const got = [...order].sort((a, b) => a - b);
  if (JSON.stringify(want) !== JSON.stringify(got)) {
    problems.push(`order must be a permutation of ${JSON.stringify(want)}, got ${JSON.stringify(order)}`);
    return problems;
  }
  const pos = new Map(order.map((n, i) => [n, i]));
  for (const [blocked, blockedBy] of edges) {
    if (pos.has(blocked) && pos.has(blockedBy) && pos.get(blockedBy) > pos.get(blocked)) {
      problems.push(`#${blocked} runs before its blocker #${blockedBy}`);
    }
  }
  return problems;
}
