import {
  accessSync,
  chmodSync,
  constants,
  copyFileSync,
  cpSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  realpathSync,
  rmSync,
  symlinkSync,
  unlinkSync,
  writeFileSync,
} from 'node:fs';
import { tmpdir } from 'node:os';
import { delimiter, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const ROOT = fileURLToPath(new URL('../..', import.meta.url));
const FIXTURES = join(ROOT, 'tests', 'fixtures', 'baseline');
const ADAPTER = join(FIXTURES, 'bin', 'stateful-adapter');
const COMMANDS = [
  'pin',
  'track-latest',
  'unpin',
  'prepare',
  'probe',
  'install',
  'update',
  'uninstall',
];
const PASSTHROUGH_VARIABLES = [
  'SUPERPOWERS_REF',
  'SUPERPOWERS_UPSTREAM_URL',
  'SUPERPOWERS_CODEX',
  'SUPERPOWERS_CACHE_DIR',
  'SUPERPOWERS_CONFIG_DIR',
  'SUPERPOWERS_PLUGIN_ROOT',
  'SUPERPOWERS_MANIFEST_TEMPLATE',
  'SUPERPOWERS_VALIDATOR',
  'SUPERPOWERS_INSTALLED_SEARCH_ROOT',
  'SUPERPOWERS_INSTALL_REFRESH_MODE',
];

function hostExecutable(name) {
  if (name === 'node') return realpathSync(process.execPath);
  for (const directory of (process.env.PATH || '').split(delimiter)) {
    if (!directory) continue;
    const candidate = join(directory, name);
    try {
      accessSync(candidate, constants.X_OK);
      return realpathSync(candidate);
    } catch {
      // Keep looking through the host PATH used only during sandbox setup.
    }
  }
  throw new Error(`required host command not found: ${name}`);
}

function linkHostTool(bin, name) {
  symlinkSync(hostExecutable(name), join(bin, name));
}

function copyRuntimePackage(pkg) {
  mkdirSync(pkg, { recursive: true });
  cpSync(join(ROOT, 'bin'), join(pkg, 'bin'), { recursive: true });
  cpSync(join(ROOT, 'scripts'), join(pkg, 'scripts'), { recursive: true });
  cpSync(join(ROOT, 'config'), join(pkg, 'config'), { recursive: true });
  copyFileSync(join(ROOT, 'package.json'), join(pkg, 'package.json'));

  const manifestDirectory = join(pkg, 'plugins', 'superpowers', '.codex-plugin');
  mkdirSync(manifestDirectory, { recursive: true });
  copyFileSync(
    join(
      ROOT,
      'plugins',
      'superpowers',
      '.codex-plugin',
      'plugin.template.json',
    ),
    join(manifestDirectory, 'plugin.template.json'),
  );
}

function dispatchStub(command) {
  return `#!/bin/sh
set -eu

python3 - ${JSON.stringify(command)} "$@" <<'PY'
import json
import os
import sys

command, *arguments = sys.argv[1:]
log_path = os.environ["SPW_BASELINE_DISPATCH_LOG"]
passthrough = ${JSON.stringify(PASSTHROUGH_VARIABLES)}
record = {
    "command": command,
    "argv": arguments,
    "passthrough": {name: os.environ.get(name) for name in passthrough},
    "superpowers_env": {
        name: value
        for name, value in os.environ.items()
        if name.startswith("SUPERPOWERS_")
    },
    "xdg_env": {
        name: value
        for name, value in os.environ.items()
        if name.startswith("XDG_")
    },
    "npm_env": {
        name: value
        for name, value in os.environ.items()
        if name.upper().startswith("NPM_CONFIG_")
    },
    "codex_env": {
        name: value
        for name, value in os.environ.items()
        if name.startswith("CODEX_")
    },
}
with open(log_path, "a", encoding="utf-8") as handle:
    json.dump(record, handle, allow_nan=False, separators=(",", ":"))
    handle.write("\\n")
raise SystemExit(int(os.environ.get("SPW_BASELINE_DELEGATE_EXIT", "0")))
PY
`;
}

function installDispatchStubs(sandbox) {
  for (const command of COMMANDS) {
    const script = join(sandbox.pkg, 'scripts', command);
    writeFileSync(script, dispatchStub(command), 'utf8');
    chmodSync(script, 0o755);
  }
}

function writeNoopTool(sandbox, name = 'codex') {
  const tool = join(sandbox.bin, name);
  writeFileSync(tool, '#!/bin/sh\nexit 0\n', 'utf8');
  chmodSync(tool, 0o755);
  return tool;
}

function createSandbox({ stubScripts = false } = {}) {
  const root = realpathSync(mkdtempSync(join(tmpdir(), 'spw-baseline-')));
  const sandbox = {
    root,
    pkg: join(root, 'pkg'),
    bin: join(root, 'bin'),
    home: join(root, 'home'),
    tmp: join(root, 'tmp'),
    config: join(root, 'config'),
    cache: join(root, 'cache'),
    plugin: join(root, 'plugin'),
    codex: join(root, 'codex'),
    work: join(root, 'work'),
    adapter: ADAPTER,
    adapterState: join(root, 'adapter-state'),
    adapterLog: join(root, 'adapter.log'),
    dispatchLog: join(root, 'dispatch.log'),
  };

  for (const directory of [
    sandbox.bin,
    sandbox.home,
    sandbox.tmp,
    sandbox.config,
    sandbox.cache,
    sandbox.codex,
    sandbox.work,
    sandbox.adapterState,
  ]) {
    mkdirSync(directory, { recursive: true });
  }
  copyRuntimePackage(sandbox.pkg);
  for (const tool of ['node', 'sh', 'git', 'python3']) {
    linkHostTool(sandbox.bin, tool);
  }
  if (stubScripts) installDispatchStubs(sandbox);
  return sandbox;
}

function baseEnvironment(sandbox, overrides = {}) {
  return {
    PATH: sandbox.bin,
    HOME: sandbox.home,
    TMPDIR: sandbox.tmp,
    SUPERPOWERS_CONFIG_DIR: sandbox.config,
    SUPERPOWERS_CACHE_DIR: sandbox.cache,
    SUPERPOWERS_PLUGIN_ROOT: sandbox.plugin,
    SUPERPOWERS_MANIFEST_TEMPLATE: join(
      sandbox.pkg,
      'plugins/superpowers/.codex-plugin/plugin.template.json',
    ),
    SUPERPOWERS_INSTALLED_SEARCH_ROOT: sandbox.codex,
    ...overrides,
  };
}

function runCli(sandbox, args = [], overrides = {}, options = {}) {
  if (
    Object.hasOwn(overrides, 'SPW_ADAPTER')
    && !Object.hasOwn(overrides, 'SUPERPOWERS_CODEX')
    && !existsSync(join(sandbox.bin, 'codex'))
  ) {
    writeNoopTool(sandbox);
  }
  return spawnSync(
    join(sandbox.bin, 'node'),
    [join(sandbox.pkg, 'bin', 'superpowers-manager.js'), ...args],
    {
      cwd: options.cwd || sandbox.work,
      env: baseEnvironment(sandbox, overrides),
      encoding: 'utf8',
      maxBuffer: 16 * 1024 * 1024,
    },
  );
}

function runScenario(sandbox, command, destination, overrides = {}) {
  return spawnSync(
    join(sandbox.bin, 'sh'),
    [
      join(ROOT, 'tests', 'builders', 'baseline-scenario.sh'),
      command,
      destination,
    ],
    {
      cwd: sandbox.work,
      env: baseEnvironment(sandbox, overrides),
      encoding: 'utf8',
      maxBuffer: 16 * 1024 * 1024,
    },
  );
}

function readDispatchLog(sandbox) {
  if (!existsSync(sandbox.dispatchLog)) return [];
  const text = readFileSync(sandbox.dispatchLog, 'utf8');
  return text
    .split('\n')
    .filter(Boolean)
    .map((line) => JSON.parse(line));
}

function clearDispatchLog(sandbox) {
  writeFileSync(sandbox.dispatchLog, '', 'utf8');
}

function removeTool(sandbox, name) {
  const tool = join(sandbox.bin, name);
  if (existsSync(tool)) unlinkSync(tool);
}

function writeAdapterState(sandbox, state) {
  const stateFile = join(sandbox.adapterState, 'state.json');
  writeFileSync(stateFile, `${JSON.stringify(state)}\n`, {
    encoding: 'utf8',
    mode: 0o600,
  });
  return stateFile;
}

function destroySandbox(sandbox) {
  rmSync(sandbox.root, { recursive: true, force: true });
}

function fixturePath(...parts) {
  return join(FIXTURES, ...parts);
}

export {
  COMMANDS,
  PASSTHROUGH_VARIABLES,
  ROOT,
  baseEnvironment,
  clearDispatchLog,
  createSandbox,
  destroySandbox,
  fixturePath,
  installDispatchStubs,
  readDispatchLog,
  removeTool,
  runCli,
  runScenario,
  writeAdapterState,
  writeNoopTool,
};
