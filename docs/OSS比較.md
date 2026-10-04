# OSS比較とライセンス確認

2026-10-04 時点で、各プロジェクトの公開 GitHub README とリポジトリ内の LICENSE 表示を確認しました。採用したのは設計上の着想だけで、コード・文章・テンプレートのコピーはしていません。

| プロジェクト | 確認した設計 | 表示ライセンス | 今回の採用判断 |
|---|---|---|---|
| [Orka](https://github.com/Dusttoo/orka) | config-driven、独立レビュー、merge gate、Claude/Codexプラグイン | MIT | 設定とゲートの分離を参考 |
| [superharness](https://github.com/backmeupplz/superharness) | worker の隔離、stall検知、cleanup | MIT | worker lifecycle の考え方を参考 |
| [repo-harness](https://github.com/Ancienttwo/repo-harness) | file-backed な plan / handoff / review evidence | MIT | `.orca-handoff` の永続化を参考 |
| [claude-codex-coordination](https://github.com/sun9huni/claude-codex-coordination) | Claude と Codex の共有ファイル運用 | 公開ページで要再確認 | コード・文章は取り込まない |
| [Harness](https://github.com/majiayu000/harness) | fleet、policy、observability | 公開ページで要再確認 | 将来調査。依存しない |
| [claude-codex](https://github.com/Z-M-Huang/claude-codex) | 要件整理からreviewまでの一連のUX | 公開ページで要再確認 | UXの比較のみ。依存しない |

ライセンスが確認できない参照先のコードは使用していません。将来コードを取り込む場合は、対象コミット、著作権表示、NOTICE要否、互換性を個別に確認します。

