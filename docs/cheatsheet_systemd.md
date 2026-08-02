# CHEATSHEET: systemd / サービス障害

## 症状から引く
| 症状 | 一発目 | 判定 | 対処 |
|---|---|---|---|
| 設定を直したのに効かない | `systemctl cat <u>` | 直したファイルが表示に無い / drop-inが上書き | 実効値を `systemctl show -p` で確認 → 正しい層を直す |
| Unit is masked | `systemctl status <u>` | masked | `systemctl unmask <u>` |
| 依存先を止めたら一緒に落ちた | `systemctl list-dependencies --reverse <u>` | Requires/BindsTo の伝播 | 弱くするなら Wants= |
| 起動しない・依存先が上がらない | `systemctl list-dependencies <u>` | 上流の failed | 上流を先に直す |
| 動いてないがエラーも無い | `journalctl -u <u>` | `Condition check ... skipped` | Condition* を見直す |
| active (activating) のまま | `systemctl show -p TimeoutStartUSec <u>` | Type=notify で通知なし / timeout待ち | Type= を simple に / アプリ側の通知実装 |
| 落ちて再起動を繰り返す | `journalctl -u <u> --since "5 min ago"` | StartLimit (repeated too quickly) | 最初のError行を見る → 直す → `reset-failed` |
| 何が失敗中か分からない | `systemctl list-units --failed` | 一覧 | 上から潰す |
| 起動が遅い | `systemd-analyze blame` / `critical-chain` | 律速unitの特定 | 依存/タイムアウト見直し |

## 依存関係の強弱（1文字で挙動が変わる）
| | 意味 | 依存先が落ちたら |
|---|---|---|
| After= | 順序のみ（依存ではない） | 何も起きない |
| Wants= | 弱い依存 | 自分は生き残る |
| Requires= | 強い依存 | 停止が伝播して自分も止まる |
| BindsTo= | 最強 | 予期せぬ停止でも確実に伝播 |
| PartOf= | 片方向 | stop/restart のみ伝播（startは伝播せず） |

## mask vs disable
- disable = 自動起動しない（手動ならstartできる）
- mask    = /dev/null へリンクで完全封鎖（startも拒否）→ unmask で解除

## 実効設定を見る3手
systemctl cat <u>                    # 本体+drop-in の連結（どのファイル由来か分かる）
systemd-delta                        # システム全体の上書き一覧
systemctl show -p <Key> <u>          # マージ後の実効値（ファイルを読むより確実）

## drop-in で ExecStart を差し替える定型
[Service]
ExecStart=            # ← 空代入でリセット（無いと2つになって起動エラー）
ExecStart=/new/path

## 落とし穴
- After= は順序、Requires= が依存。混同が事故の元
- 止める前に `list-dependencies --reverse` で連鎖する下流を確認する
- root領域にheredocは `sudo tee <file> > /dev/null`（`sudo cat >` は権限で失敗）
- 「動いてない」≠「失敗してる」（Condition skip は成功扱い）

## 実測メモ（dep-base/dep-child 演習 2026-07-26）
- Requires: child を start → base も active / base を stop → child は stop
- Wants に変更後: base を stop → child は active
- drop-in 後の `show -p ExecStart`: sleep 30
