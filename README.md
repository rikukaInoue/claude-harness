# claude-harness

Claude Code の長時間自律稼働を安全に実現するための共有ハーネス。

## 構成

```
claude-harness/
├── hooks/
│   ├── protect-bash.sh       # 危険コマンド防止 (PreToolUse)
│   ├── file-guard.sh         # 機密ファイル保護 (PreToolUse)
│   └── post-compact.sh       # コンパクション後コンテキスト再注入 (PostToolUse)
├── templates/
│   ├── settings.json         # プロジェクト用 permissions + hooks テンプレート
│   ├── CLAUDE.md             # ベースルール テンプレート
│   └── context-essentials.txt # compact 後再注入用テンプレート
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
| git 読み取り系 | allow |
| テスト・lint 実行 | allow |
| `rm -rf`, `sudo`, `curl`, `wget` | deny |
| `git push --force`, `git reset --hard` | deny |
| `.env`, `.pem`, `.key` への書き込み | deny |

プロジェクトに応じて `allow` のパスやコマンドを調整すること。
