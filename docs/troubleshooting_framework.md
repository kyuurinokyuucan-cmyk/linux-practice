# Troubleshooting Framework（汎用・障害切り分け）

どの案件でも初日から使う、障害切り分けの型。

## 5ステップ
1. 現象を確定：誰が/いつ/何をしたら/何が起きる/再現するか
2. 層で切る：物理 → L3到達 → 経路 → 名前解決 → ポート → アプリ（下から上へ）
3. 観測してから触る：config をいじる前に状態とログを見る
4. 仮説→検証：1回に1つだけ変える
5. 再現・確認：直った証拠を取る

## 層の地図
| 層 | 確認 | コマンド |
|---|---|---|
| 物理/リンク | NIC が up か | ip link show |
| L3到達 | 相手に届くか | ping |
| 経路 | どこで止まるか | tracepath |
| 名前解決 | 名前→IP できるか | getent hosts / dig |
| ポート | 開いてて届くか | ss -tlnp / nc -zv |
| アプリ | 応答するか | curl -v / systemctl status / journalctl |

## エラーメッセージ → 層
| エラー | 意味 | 層 |
|---|---|---|
| Name or service not known | 名前→IP に変換できてない | DNS |
| Connection refused | 届いたが待ち受けなし（RST） | ポート/サービス |
| Connection timed out / No route to host | そもそも届かない（無音） | 到達/経路 |
| Permission denied (publickey) | 到達もポートもOK、認証で失敗 | アプリ（SSH認証） |

**キモ**：refused（届いたが拒否）と timed out（届かない）で分岐。正常系との差分で範囲を絞る。

## 実例：nginx 停止を層で切った記録（2026-07-25）
- 現象：sudo でnginxをstop
- 各層の観測（ping / curl の結果）：pingは通るがcurlでfailed to connect
- 原因確定（ss / systemctl status の結果）：Active: inactive (dead),80ポートが使われていない
- 復旧確認：Active: active (running), rin@mimir:~$ ss -tlnp | grep :80
LISTEN 0      511                        0.0.0.0:80         0.0.0.0:*
LISTEN 0      511                           [::]:80            [::]:*
