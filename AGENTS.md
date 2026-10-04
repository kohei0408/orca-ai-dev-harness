# AGENTS.md

このリポジトリは、Windows PowerShell と Orca 向けの再利用可能なハーネステンプレートです。

## Verification

- `pwsh .\tests\Test-OrcaHarness.ps1`
- `Get-ChildItem -Recurse -File | Select-String -Pattern 'api[_-]?key|secret|token'` で秘密情報の混入を確認

## Boundaries

- 参照OSSからコード・文章をコピーしない。
- `ai-picture-app` のファイルをこのリポジトリから変更しない。
- 認証情報、ユーザーの実データ、実運用のデプロイ先をコミットしない。
- READMEの導入コマンドと実際のスクリプトの挙動を一致させる。

## Release

- 変更時はテストを実行する。
- GitHub公開前に remote とアカウントを確認する。
- push後にGitHub上のREADMEと最新コミットを確認する。

