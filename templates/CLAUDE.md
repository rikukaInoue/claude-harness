# Project: __PROJECT_NAME__

## Build & Test

- `npm run build` - ビルド
- `npm run test` - テスト全体
- `npm run lint` - Lint

## Critical Rules

- テストを書いてからコードを書く（TDD）
- 既存ファイルの変更前にテストが通ることを確認する
- .env ファイルは絶対に読み書きしない
- rm -rf は使わない
- git push --force は使わない
- any 型を使わない

## Task Execution Protocol

1. 各ステップ完了後にテストを実行して確認する
2. コンパクションが起きたら、まず CLAUDE.md と現在のタスク計画を再読する
3. 不明点がある場合は推測せず停止する
4. 大きな変更は小さなコミット単位に分割する

## Long Session Rules

- 作業を急いで終わらせようとしないこと。品質が最優先
- 不確かな場合はテストを書いて検証する
