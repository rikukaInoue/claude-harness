# claude-harness

Claude Code の長時間自律稼働を安全に実現するための共有ハーネス。

## 構成

```
claude-harness/
├── hooks/
│   ├── protect-bash.sh       # 危険コマンド防止 (PreToolUse)
│   ├── file-guard.sh         # 機密ファイル保護 (PreToolUse)
│   ├── post-compact.sh       # コンパクション後コンテキスト再注入 (PostToolUse)
│   └── post-edit-feedback.sh # ファイル編集後の自動テスト (PostToolUse)
├── templates/
│   ├── settings.json         # プロジェクト用 permissions + hooks テンプレート
│   ├── CLAUDE.md             # ベースルール テンプレート
│   ├── context-essentials.txt # compact 後再注入用テンプレート
│   └── test-command.sh       # テストコマンド テンプレート
└── setup.sh                  # プロジェクトへの展開スクリプト
```

## セットアップ

### 1. このリポジトリを clone

```bash
git clone git@github.com:rikukaInoue/claude-harness.git ~/gh/claude-harness
```

### 2. プロジェクトに展開

```bash
~/gh/claude-harness/setup.sh /path/to/your-project
```

これで以下が生成される:

- `your-project/.claude/settings.json` — permissions + hooks 設定
- `your-project/CLAUDE.md` — ベースルール
- `your-project/.claude/context-essentials.txt` — compact 後再注入テンプレート

既存ファイルがある場合はスキップされる。

### 3. プロジェクトに合わせてカスタマイズ

- `CLAUDE.md` にプロジェクト固有のビルドコマンドやルールを追記
- `.claude/settings.json` の `permissions.allow` に必要なコマンドを追加
- `.claude/context-essentials.txt` を作業開始時に更新

## Hooks の動作

### protect-bash.sh (PreToolUse → Bash)

以下のパターンを含むコマンドをブロック:

- `rm -rf /`, `rm -rf ~`, `rm -rf .`
- `DROP TABLE`, `DROP DATABASE`, `TRUNCATE TABLE`
- `terraform destroy`
- `git push --force`, `git push -f`
- `git reset --hard`, `git clean -fd`
- `sudo rm`, `sudo shutdown`, `sudo reboot`
- `mkfs.`, `> /dev/sd`, `dd if=`

`exit 2` で返すため、`bypassPermissions` モードでも強制ブロックが効く。

### file-guard.sh (PreToolUse → Edit|Write)

以下のパターンにマッチするファイルへの書き込みをブロック:

- `.env`, `.pem`, `.key`, `.p12`, `.pfx`
- `id_rsa`, `id_ed25519`
- `credentials`, `secrets/`, `.secret`
- `token.json`, `service-account`

### post-edit-feedback.sh (PostToolUse → Edit|Write)

ファイル編集後に自動でテストを実行し、結果を Claude にフィードバックする。

1. プロジェクトの `.claude/test-command.sh` があればそれを実行
2. なければスキップ（何も起きない）
3. テスト成功時は `PASSED` + 末尾5行を表示
4. テスト失敗時は `FAILED` + 末尾30行 + 修正を促すメッセージを表示

プロジェクトごとに `.claude/test-command.sh` を書くだけで、言語やフレームワークを問わず動作する。

```bash
# .claude/test-command.sh の例
# Node.js
npm test

# Go
go test ./...

# Rust
cargo test
```

### post-edit-diffsize.sh (PostToolUse → Edit|Write)

未コミットの変更量を監視し、閾値を超えたらコミットを促す。

- デフォルト閾値: **100行**（insertion + deletion の合計）
- 環境変数 `CLAUDE_HARNESS_DIFF_THRESHOLD` で変更可能
- git リポジトリでなければスキップ
- 閾値未満なら何も出力しない

### post-compact.sh (PostToolUse → compact)

コンパクション発生時に:

1. プロジェクトの `.claude/context-essentials.txt` があればその内容を注入
2. なければ汎用の再読み込みリマインダーを注入

## permissions 設計

テンプレートのデフォルト:

| カテゴリ | 設定 |
|---------|------|
| ファイル読み取り・検索 | allow |
| `src/**` への書き込み | allow |
| git 読み取り系 + add/commit/push（force 以外）/ブランチ作成 | allow |
| `gh pr` / `gh issue` / `gh run` / `gh api` | allow |
| `docker compose` / `docker logs` / `docker exec` / `docker ps` | allow |
| `mise run`, `go test/build/vet`, npm/pnpm の test・lint, `rtk` | allow |
| `curl` は **localhost / 127.0.0.1 宛のみ** allow（外向きは通常の確認） | allow |
| `rm -rf`, `sudo`, `wget`, force push, `git reset --hard` | deny |
| `git push --force`, `git reset --hard` | deny |
| `.env`, `.pem`, `.key` への書き込み | deny |

プロジェクトに応じて `allow` のパスやコマンドを調整すること。

allow の設計方針: **自律稼働で1日に何十回も出る操作**（PR 運用・compose 実測・
テスト実行）を通し、**課金・削除・外向きの操作**は通常の確認に残す。
`curl` を一律 deny にしない理由は、ローカル実測（healthz 叩き等）が
ワークフローの中心にあるため。外向き `curl` は allow に入れず確認に倒す。

なお `git push --force` などは deny と protect-bash.sh の**二重**で守っている。
deny は settings を消せば外れるが、hook の exit 2 は bypassPermissions でも効く。
