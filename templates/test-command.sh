#!/bin/bash
# .claude/test-command.sh — プロジェクト固有のテストコマンド
# post-edit-feedback.sh から呼ばれる
#
# プロジェクトに合わせて書き換えること。例:
#
# Node.js:   npm test
# Go:        go test ./...
# Rust:      cargo test
# Python:    pytest
# Astro:     npm run build

npm test
