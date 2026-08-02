# CHEATSHEET: ディスク逼迫

## 症状から引く
| 症状 | 一発目 | 判定 | 対処 |
|---|---|---|---|
| 書けない / No space left | `df -h` → `df -i` | Use% 100% = バイト枯渇 | du で掘る（下記） |
| 書けないが df に空きあり | `df -i` | IUse% 100% = inode枯渇 | 小ファイル大量の場所を特定して削除 |
| df は満杯だが du が合わない | `sudo lsof +L1` | 削除済み+fd保持 | 該当PIDを再起動 / kill |
| /var が太い | `du -h --max-depth=1 /var \| sort -rh` | journal? log? docker? | 下記の各対処 |
| journal が数GB | `journalctl --disk-usage` | 上限未設定 | vacuum → journald.conf |
| ログが回ってない | `cat /var/lib/logrotate/status` | 最終日時が古い | `logrotate -d` で検証 → `-f` で強制 |

## 掘る（太い枝を辿る）
sudo du -h --max-depth=1 / | sort -rh | head
sudo du -h --max-depth=1 /var | sort -rh | head
# 出た太い枝を次の引数にして繰り返す

## 巨大ログの正しい消し方
truncate -s 0 /path/to/big.log   # ◯ プロセス無停止・即座に容量が戻る
rm /path/to/big.log              # × fd保持で容量戻らず、出力先も失う

## journal を縮める
journalctl --disk-usage
sudo journalctl --vacuum-time=7d
sudo journalctl --vacuum-size=200M
# 恒久: /etc/systemd/journald.conf に SystemMaxUse=500M → restart systemd-journald

## logrotate 検証
sudo logrotate -d /etc/logrotate.conf     # dry run（反映前検証。nginx -t と同じ型）
sudo cat /var/lib/logrotate/status        # 最終ローテート日時
sudo logrotate -f /etc/logrotate.d/<name> # 強制実行

## 落とし穴
- df -h と df -i は必ずセット。片方だけ見ると片方の枯渇を見逃す
- sort は -rh（-h なしだと 1G < 9M と誤ソート）
- rm しても容量が戻らないことがある（lsof +L1）

## 実測メモ（loopback演習 2026-07-26）
- ENOSPC: fallocate 80M → dd 50M が TODO(エラー文)
- df/du 食い違い: rm 後 df = TODO / du = TODO / lsof +L1 の犯人 = TODO
- kill 後: df = TODO（戻った）
