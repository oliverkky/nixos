#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
TEST_TMPDIRS=()

make_test_tmpdir() {
    local -n destination=$1

    destination=$(mktemp -d)
    TEST_TMPDIRS+=("$destination")
}

cleanup_test_tmpdirs() {
    local directory

    for directory in "${TEST_TMPDIRS[@]}"; do
        [[ -d $directory ]] && rm -rf -- "$directory"
    done
}
trap cleanup_test_tmpdirs EXIT

fail() {
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}

pass() {
    printf 'ok - %s\n' "$1"
}

assert_equal() {
    local description=$1
    local expected=$2
    local actual=$3

    [[ $actual == "$expected" ]] || {
        printf 'expected: %s\nactual:   %s\n' "$expected" "$actual" >&2
        fail "$description"
    }
    pass "$description"
}

assert_contains() {
    local description=$1
    local haystack=$2
    local needle=$3

    [[ $haystack == *"$needle"* ]] || {
        printf 'expected output to contain: %s\nactual output:\n%s\n' "$needle" "$haystack" >&2
        fail "$description"
    }
    pass "$description"
}

assert_file_contains() {
    local description=$1
    local file=$2
    local needle=$3

    [[ -f $file ]] || fail "$description (missing $file)"
    assert_contains "$description" "$(<"$file")" "$needle"
}

make_logging_stub() {
    local directory=$1
    local name=$2

    ln -s "$ROOT/test/lib/log-command" "$directory/$name"
}

make_stub() {
    local directory=$1
    local name=$2

    {
        printf '#!%s\n' "$(command -v bash)"
        cat
    } > "$directory/$name"
    chmod +x "$directory/$name"
}
