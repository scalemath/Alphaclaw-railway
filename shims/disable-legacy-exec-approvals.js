#!/usr/bin/env node
/**
 * Stop alphaclaw seeding a legacy exec-approvals.json.
 *
 * alphaclaw writes ~/.openclaw/exec-approvals.json on every boot with its managed defaults
 * (security: full, ask: off). OpenClaw 2.0 moved exec approvals into SQLite and its migration
 * gate refuses ALL runtime access while that file exists — assertNoPendingLegacyExecApprovals
 * throws on mere existence, not on content:
 *
 *   if (sourceBefore || claim || sourceAfter) throw new ExecApprovalsMigrationRequiredError(...)
 *
 * So the wrapper recreates the file at startup and the gateway then refuses every message with
 * ExecApprovalsMigrationRequiredError. `openclaw doctor --fix` cannot break the loop: it tells
 * you to delete the file, and the next boot writes it again.
 *
 * Nothing is lost by not writing it. The content was only alphaclaw's own defaults, and 2.0
 * owns approvals in SQLite now. Neutralise the writer rather than the whole module, so the
 * readers and the /api/nodes/exec-approvals routes keep working.
 */
const fs = require('fs');

const target =
  '/app/node_modules/@chrysb/alphaclaw/lib/server/exec-defaults-config.js';

if (!fs.existsSync(target)) {
  console.error(`[patch] ${target} not found — alphaclaw layout changed; refusing to guess.`);
  process.exit(1);
}

const src = fs.readFileSync(target, 'utf8');
const needle =
  '  fsModule.mkdirSync(path.dirname(filePath), { recursive: true });\n' +
  '  fsModule.writeFileSync(filePath, JSON.stringify(file, null, spacing) + "\\n", "utf8");\n';

if (!src.includes(needle)) {
  console.error('[patch] writeExecApprovalsConfig body not recognised — refusing to guess.');
  process.exit(1);
}

const patched = src.replace(
  needle,
  '  // Patched at build time: OpenClaw 2.0 refuses to run while a legacy\n' +
  '  // exec-approvals.json exists. See shims/disable-legacy-exec-approvals.js\n',
);

fs.writeFileSync(target, patched);
console.log('[patch] alphaclaw no longer writes a legacy exec-approvals.json');
