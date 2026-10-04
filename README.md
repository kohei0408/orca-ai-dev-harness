# Orca AI Development Harness

Windows PowerShell と Orca を前提に、Claude の Front Desk、Technical Coordinator、Human Gate、Codex 実装、Claude レビュー、最大2回の修正、コミット・プッシュ・デプロイ確認を、別のプロダクトへ持ち運ぶための小さなテンプレートです。

このリポジトリはアプリケーション本体ではありません。プロジェクト固有の知識は対象プロジェクトの `AGENTS.md` に残し、ハーネス共通の運用ルールだけを `.orca/` と `scripts/` に分離します。

## できること

- `.orca-handoff/` に plan、hash、レビュー、ゲート結果を保存
- Front Desk → Coordinator → Human Gate → Implement → Review → Fix の状態を追跡
- plan の SHA-256 が変わったら実装を止める
- レビュー修正は `0..2` 回に制限
- plan にないファイル変更を out-of-scope として隔離
- commit / push / deploy は明示的な安全ガードを通す
- worker の作業ディレクトリと一時 handoff を安全に掃除

## 5分導入（PowerShell）

対象プロジェクトのルートで実行します。

```powershell
$harness = 'https://github.com/kohei0408/orca-ai-dev-harness.git'
$temp = Join-Path $env:TEMP 'orca-ai-dev-harness'
if (Test-Path $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
git clone $harness $temp
& (Join-Path $temp 'scripts\Install-OrcaHarness.ps1') -TargetPath (Get-Location).Path
Remove-Item -LiteralPath $temp -Recurse -Force
```

インストールは `.orca/`、`scripts/Orca-Harness.ps1`、`AGENTS.md` の雛形を追加します。既存ファイルは上書きせず、差分がある場合は `.new` として保存します。

## 日常の流れ

```powershell
pwsh .\scripts\Orca-Harness.ps1 init -TaskId TASK-001 -RequestFile .\request.md
pwsh .\scripts\Orca-Harness.ps1 status -TaskId TASK-001
pwsh .\scripts\Orca-Harness.ps1 gate -TaskId TASK-001 -Decision approve
pwsh .\scripts\Orca-Harness.ps1 review -TaskId TASK-001 -Verdict changes_requested
pwsh .\scripts\Orca-Harness.ps1 fix -TaskId TASK-001
pwsh .\scripts\Orca-Harness.ps1 scope -TaskId TASK-001
pwsh .\scripts\Orca-Harness.ps1 safe-commit -TaskId TASK-001 -Message 'feat: implement TASK-001'
pwsh .\scripts\Orca-Harness.ps1 safe-push -TaskId TASK-001
pwsh .\scripts\Orca-Harness.ps1 deploy-check -TaskId TASK-001
```

`safe-commit` と `safe-push` は、ゲート承認済み・レビュー済み・scope が clean の場合だけ動きます。デプロイは環境固有なので、`deploy-check` は設定と承認の確認までを担当し、実際のデプロイコマンドは勝手に実行しません。

## Orcaでの使い方

1. `.orca/front-desk.md` を読む Claude を窓口にする。
2. Front Desk は要件を `request.md` に整理し、Technical Coordinator に渡す。
3. Coordinator は `plan.md` と `acceptance.md` を作成し、`init` で hash を固定する。
4. Human Gate で `gate -Decision approve` を実行するまで Codex は実装を開始しない。
5. Codex は対象プロジェクトの `AGENTS.md` と plan だけを根拠に実装する。
6. 別の Claude が `.orca/coordinator.md` のレビュー手順で判定する。
7. `changes_requested` のときだけ `fix` を実行する。3回目は fail-closed。

## プロジェクト固有設定

`AGENTS.md` には技術スタック、テスト、デプロイ先、変更禁止領域だけを書きます。会社情報や秘密情報、APIキーは書きません。テンプレートの詳細は [docs/導入手順.md](docs/導入手順.md) を参照してください。

## 開発者向け検証

```powershell
pwsh .\tests\Test-OrcaHarness.ps1
```

## ライセンスと参考調査

このプロジェクト自身は MIT です。参考にした公開プロジェクトとライセンスの確認結果は [docs/OSS比較.md](docs/OSS比較.md) に記録しています。参照先のコード・文章・テンプレートはコピーしていません。

