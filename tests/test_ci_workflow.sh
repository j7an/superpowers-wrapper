#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
wf="$root/.github/workflows/ci.yml"

[ -f "$wf" ] || { echo "missing $wf" >&2; exit 1; }

ruby - "$wf" <<'RUBY'
require "yaml"

path = ARGV.fetch(0)
workflow = YAML.load_file(path)

def expect_hash(value, path)
  raise "expected mapping at #{path}, got #{value.class}" unless value.is_a?(Hash)

  value
end

def fetch(mapping, key, path)
  raise "missing #{path}" unless mapping.key?(key)

  mapping.fetch(key)
end

def expect_equal(actual, expected, path)
  return if actual == expected

  raise "unexpected #{path}: #{actual.inspect} (expected #{expected.inspect})"
end

workflow = expect_hash(workflow, "workflow")
expect_equal(fetch(workflow, "permissions", "permissions"), {}, "permissions")

jobs = expect_hash(fetch(workflow, "jobs", "jobs"), "jobs")
expect_equal(jobs.keys, ["test"], "jobs keys")

test_job = expect_hash(fetch(jobs, "test", "jobs.test"), "jobs.test")
raise "jobs.test must not use continue-on-error" if test_job.key?("continue-on-error")
expect_equal(fetch(test_job, "runs-on", "jobs.test.runs-on"), "ubuntu-latest", "jobs.test.runs-on")
expect_equal(
  fetch(expect_hash(fetch(test_job, "permissions", "jobs.test.permissions"), "jobs.test.permissions"), "contents", "jobs.test.permissions.contents"),
  "read",
  "jobs.test.permissions.contents",
)

steps = fetch(test_job, "steps", "jobs.test.steps")
raise "expected jobs.test.steps to be an array" unless steps.is_a?(Array)
expect_equal(steps.length, 3, "jobs.test.steps length")

harden = expect_hash(steps.fetch(0), "jobs.test.steps[0]")
expect_equal(fetch(harden, "name", "jobs.test.steps[0].name"), "Harden runner", "jobs.test.steps[0].name")
expect_equal(
  fetch(harden, "uses", "jobs.test.steps[0].uses"),
  "step-security/harden-runner@9af89fc71515a100421586dfdb3dc9c984fbf411",
  "jobs.test.steps[0].uses",
)
expect_equal(
  fetch(expect_hash(fetch(harden, "with", "jobs.test.steps[0].with"), "jobs.test.steps[0].with"), "egress-policy", "jobs.test.steps[0].with.egress-policy"),
  "audit",
  "jobs.test.steps[0].with.egress-policy",
)

checkout = expect_hash(steps.fetch(1), "jobs.test.steps[1]")
expect_equal(fetch(checkout, "name", "jobs.test.steps[1].name"), "Checkout repository", "jobs.test.steps[1].name")
expect_equal(
  fetch(checkout, "uses", "jobs.test.steps[1].uses"),
  "actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0",
  "jobs.test.steps[1].uses",
)
expect_equal(
  fetch(expect_hash(fetch(checkout, "with", "jobs.test.steps[1].with"), "jobs.test.steps[1].with"), "persist-credentials", "jobs.test.steps[1].with.persist-credentials"),
  false,
  "jobs.test.steps[1].with.persist-credentials",
)

acceptance = expect_hash(steps.fetch(2), "jobs.test.steps[2]")
expect_equal(fetch(acceptance, "name", "jobs.test.steps[2].name"), "Run container acceptance suite", "jobs.test.steps[2].name")
expect_equal(fetch(acceptance, "run", "jobs.test.steps[2].run"), "sh tests/container.sh", "jobs.test.steps[2].run")
raise "jobs.test.steps[2] must not use continue-on-error" if acceptance.key?("continue-on-error")
RUBY

echo "test_ci_workflow: OK"
