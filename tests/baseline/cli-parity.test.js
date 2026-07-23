import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';

import {
  COMMANDS,
  PASSTHROUGH_VARIABLES,
  clearDispatchLog,
  createSandbox,
  destroySandbox,
  readDispatchLog,
  removeTool,
  runCli,
  writeNoopTool,
} from './support.js';

const USAGE = `usage: superpowers-manager [command] [args...]

Selection commands (save intent only; they do not prepare or install it):
  pin REF       save an exact upstream release tag or commit
  track-latest  save selection of the latest stable upstream release
  unpin         remove the saved selection and return to the packaged fallback

Apply and lifecycle commands:
  prepare    fetch the pinned upstream ref and generate the plugin tree
  probe      report upstream/generated/installed status (accepts --porcelain)
  install    register this package root as a Codex marketplace and install the plugin
  update     probe, then prepare/install only if needed (default when no subcommand)
  uninstall  remove the manager plugin and marketplace from Codex

Environment overrides (passed through to the scripts): SUPERPOWERS_REF,
SUPERPOWERS_UPSTREAM_URL, SUPERPOWERS_CODEX, SUPERPOWERS_CACHE_DIR,
SUPERPOWERS_CONFIG_DIR, XDG_CONFIG_HOME,
SUPERPOWERS_PLUGIN_ROOT, SUPERPOWERS_MANIFEST_TEMPLATE,
SUPERPOWERS_VALIDATOR,
SUPERPOWERS_INSTALLED_SEARCH_ROOT, SUPERPOWERS_INSTALL_REFRESH_MODE

Selection state uses SUPERPOWERS_CONFIG_DIR when set; otherwise it uses
$XDG_CONFIG_HOME/superpowers-manager, then $HOME/.config/superpowers-manager.
`;

function withSandbox(options, callback) {
  const sandbox = createSandbox(options);
  try {
    return callback(sandbox);
  } finally {
    destroySandbox(sandbox);
  }
}

function dispatchEnvironment(sandbox, overrides = {}) {
  return {
    SPW_ADAPTER: sandbox.adapter,
    SPW_BASELINE_DISPATCH_LOG: sandbox.dispatchLog,
    ...overrides,
  };
}

function assertCleanResult(result, status = 0) {
  assert.equal(result.error, undefined);
  assert.equal(result.signal, null);
  assert.equal(result.status, status);
}

function assertOnlyDispatch(sandbox, command, argv) {
  assert.deepEqual(
    readDispatchLog(sandbox).map(({ command: name, argv: args }) => ({
      command: name,
      argv: args,
    })),
    [{ command, argv }],
  );
}

test('CLI-MODE-HELP-01 help modes', () => {
  withSandbox({ stubScripts: true }, (sandbox) => {
    for (const mode of ['--help', '-h']) {
      const result = runCli(sandbox, [mode]);
      assertCleanResult(result);
      assert.equal(result.stdout, USAGE);
      assert.equal(result.stderr, '');
    }
  });
});

test('CLI-MODE-VERSION-01 version mode', () => {
  withSandbox({ stubScripts: true }, (sandbox) => {
    const { version } = JSON.parse(
      readFileSync(join(sandbox.pkg, 'package.json'), 'utf8'),
    );
    const result = runCli(sandbox, ['--version']);
    assertCleanResult(result);
    assert.equal(result.stdout, `${version}\n`);
    assert.equal(result.stderr, '');
  });
});

test('CLI-MODE-DEFAULT-01 no arguments dispatch update', () => {
  withSandbox({ stubScripts: true }, (sandbox) => {
    const result = runCli(sandbox, [], dispatchEnvironment(sandbox));
    assertCleanResult(result);
    assert.equal(result.stdout, '');
    assert.equal(result.stderr, '');
    assertOnlyDispatch(sandbox, 'update', []);
  });
});

test('CLI-COMMANDS-01 eight named commands dispatch', () => {
  const cases = new Map([
    ['pin', ['v6.1.1']],
    ['track-latest', []],
    ['unpin', []],
    ['prepare', ['--candidate', 'arbitrary value']],
    ['probe', ['--porcelain']],
    ['install', ['--dry-run', 'arbitrary value']],
    ['update', ['--force', 'arbitrary value']],
    ['uninstall', ['--purge', 'arbitrary value']],
  ]);
  assert.deepEqual([...cases.keys()], COMMANDS);

  withSandbox({ stubScripts: true }, (sandbox) => {
    for (const [command, argv] of cases) {
      clearDispatchLog(sandbox);
      const result = runCli(
        sandbox,
        [command, ...argv],
        dispatchEnvironment(sandbox),
      );
      assertCleanResult(result);
      assert.equal(result.stdout, '');
      assert.equal(result.stderr, '');
      assertOnlyDispatch(sandbox, command, argv);
    }
  });
});

test('CLI-USAGE-01 invalid command and stray flag fail with exit 2', () => {
  const cases = [
    { args: ['bogus'], diagnostic: 'unknown subcommand: bogus' },
    { args: ['--porcelain'], diagnostic: 'unknown subcommand: --porcelain' },
    { args: ['pin'], diagnostic: 'usage: superpowers-manager pin REF' },
    {
      args: ['pin', 'v1.2.3', 'extra'],
      diagnostic: 'usage: superpowers-manager pin REF',
    },
    {
      args: ['pin', 'main'],
      diagnostic:
        'pin REF must be an exact v-prefixed SemVer tag or full 40-hex commit',
    },
    {
      args: ['track-latest', 'extra'],
      diagnostic: 'usage: superpowers-manager track-latest',
    },
    {
      args: ['unpin', 'extra'],
      diagnostic: 'usage: superpowers-manager unpin',
    },
  ];

  withSandbox({ stubScripts: true }, (sandbox) => {
    for (const { args, diagnostic } of cases) {
      clearDispatchLog(sandbox);
      const result = runCli(
        sandbox,
        args,
        dispatchEnvironment(sandbox),
      );
      assertCleanResult(result, 2);
      assert.equal(result.stdout, '');
      assert.equal(result.stderr, `error: ${diagnostic}\n${USAGE}`);
      assert.deepEqual(readDispatchLog(sandbox), []);
    }
  });
});

test('CLI-PIN-REF-01 pin accepts exact tag or 40-hex commit only', () => {
  const accepted = [
    'v0.0.0',
    'v1.2.3',
    'v1.2.3-alpha',
    'v1.2.3-alpha.1',
    'v1.2.3-0',
    'v1.2.3-x-y.z9',
    '0123456789abcdef0123456789abcdef01234567',
    'ABCDEF0123456789ABCDEF0123456789ABCDEF01',
  ];
  const refused = [
    '1.2.3',
    'v01.2.3',
    'v1.02.3',
    'v1.2.03',
    'v1.2.3-',
    'v1.2.3-01',
    'v1.2.3+build',
    '0123456789abcdef0123456789abcdef0123456',
    'g123456789abcdef0123456789abcdef01234567',
  ];

  withSandbox({ stubScripts: true }, (sandbox) => {
    for (const ref of accepted) {
      clearDispatchLog(sandbox);
      const result = runCli(
        sandbox,
        ['pin', ref],
        dispatchEnvironment(sandbox),
      );
      assertCleanResult(result);
      assertOnlyDispatch(sandbox, 'pin', [ref]);
    }
    for (const ref of refused) {
      clearDispatchLog(sandbox);
      const result = runCli(
        sandbox,
        ['pin', ref],
        dispatchEnvironment(sandbox),
      );
      assertCleanResult(result, 2);
      assert.equal(result.stdout, '');
      assert.equal(
        result.stderr,
        'error: pin REF must be an exact v-prefixed SemVer tag or full 40-hex commit\n'
          + USAGE,
      );
      assert.deepEqual(readDispatchLog(sandbox), []);
    }
  });
});

test('CLI-PREFLIGHT-01 missing tools fail before dispatch', () => {
  const requirements = new Map([
    ['pin', ['git', 'python3', 'sh']],
    ['track-latest', ['python3', 'sh']],
    ['unpin', ['sh']],
    ['prepare', ['git', 'python3', 'sh']],
    ['probe', ['git', 'python3', 'codex', 'sh']],
    ['install', ['git', 'python3', 'codex', 'sh']],
    ['update', ['git', 'python3', 'codex', 'sh']],
    ['uninstall', ['python3', 'codex', 'sh']],
  ]);
  const argsFor = { pin: ['v1.2.3'] };

  for (const [command, tools] of requirements) {
    for (const tool of tools) {
      withSandbox({ stubScripts: true }, (sandbox) => {
        if (tools.includes('codex') && tool !== 'codex') writeNoopTool(sandbox);
        removeTool(sandbox, tool);
        const result = runCli(
          sandbox,
          [command, ...(argsFor[command] || [])],
          { SPW_BASELINE_DISPATCH_LOG: sandbox.dispatchLog },
        );
        assertCleanResult(result, 1);
        assert.equal(result.stdout, '');
        assert.match(
          result.stderr,
          new RegExp(`required command not found: ${tool}`),
        );
        assert.deepEqual(readDispatchLog(sandbox), []);
      });
    }
  }
});

test('CLI-CHILD-STATUS-01 delegated child status is preserved', () => {
  withSandbox({ stubScripts: true }, (sandbox) => {
    const result = runCli(
      sandbox,
      ['probe'],
      dispatchEnvironment(sandbox, { SPW_BASELINE_DELEGATE_EXIT: '42' }),
    );
    assertCleanResult(result, 42);
    assertOnlyDispatch(sandbox, 'probe', []);
  });
});

test('CLI-ENV-01 ten SUPERPOWERS variables pass through', () => {
  withSandbox({ stubScripts: true }, (sandbox) => {
    const customCodex = writeNoopTool(sandbox, 'custom-codex');
    const values = {
      SUPERPOWERS_REF: 'v9.8.7-rc.1',
      SUPERPOWERS_UPSTREAM_URL: join(sandbox.root, 'upstream source'),
      SUPERPOWERS_CODEX: customCodex,
      SUPERPOWERS_CACHE_DIR: join(sandbox.root, 'custom cache'),
      SUPERPOWERS_CONFIG_DIR: join(sandbox.root, 'custom config'),
      SUPERPOWERS_PLUGIN_ROOT: join(sandbox.root, 'custom plugin'),
      SUPERPOWERS_MANIFEST_TEMPLATE: join(sandbox.root, 'custom template.json'),
      SUPERPOWERS_VALIDATOR: join(sandbox.root, 'custom validator.py'),
      SUPERPOWERS_INSTALLED_SEARCH_ROOT: join(sandbox.root, 'custom codex'),
      SUPERPOWERS_INSTALL_REFRESH_MODE: 'force-refresh',
    };
    assert.deepEqual(Object.keys(values), PASSTHROUGH_VARIABLES);

    const previousLeak = process.env.SUPERPOWERS_BASELINE_LEAK;
    process.env.SUPERPOWERS_BASELINE_LEAK = 'must-not-pass';
    let result;
    try {
      result = runCli(
        sandbox,
        ['update'],
        dispatchEnvironment(sandbox, values),
      );
    } finally {
      if (previousLeak === undefined) {
        delete process.env.SUPERPOWERS_BASELINE_LEAK;
      } else {
        process.env.SUPERPOWERS_BASELINE_LEAK = previousLeak;
      }
    }

    assertCleanResult(result);
    const [record] = readDispatchLog(sandbox);
    assert.deepEqual(record.passthrough, values);
    assert.deepEqual(record.superpowers_env, values);
    assert.deepEqual(record.xdg_env, {});
    assert.deepEqual(record.npm_env, {});
    assert.deepEqual(record.codex_env, {});
  });
});
