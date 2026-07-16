# systemd サービス障害切り分け runbook

## 型（順番厳守）
1. 現象を確定（何がどう壊れ、再現するか）
2. 状態を確定: `systemctl is-active <svc>` → active / failed / activating / inactive
3. 観測→仮説→検証（推測でconfigを触る前に必ずログを読む）
4. 直したら再現手順で確認

## 最初の分岐（探す範囲が半分になる）
- appログ(Traceback等)が出ている → コード / 設定値 / 権限 / 依存 を疑う
- appログが無く `status=NNN/NAME` → unitのディレクティブ(User/WorkingDirectory/ExecStart)を疑う
  - systemdはprogram実行前にお膳立て(User切替・chdir等)をする。そこで失敗するとappは走らずログも出ない。

## 診断コマンド
- 状態: `systemctl status <svc> --no-pager -l`
- 詳細: `systemctl show <svc> -p Result,ExecMainStatus,NRestarts`
- ログ(現在のインシデントに絞る): `journalctl -u <svc> --since "-3min" --no-pager`
- ポートの握り主: `sudo ss -tlnp | grep :<port>`
- 半自動: `./troubleshoot.sh <svc>`

## 症状 → 原因 → 対処
| 症状 | root cause | 対処 |
|---|---|---|
| PermissionError [Errno 13] | userがファイルに書けない | chown戻す → reset-failed → start |
| ValueErrorでcrash-loop | config値が不正 | config直してから reset-failed → start |
| Address already in use [Errno 98] | ポート使用中 | ss -tlnpで握り主確認。正当なら割込側を別ポートへ |
| status=200/CHDIR | WorkingDirに入れない | dir作成 or unit修正 → daemon-reload |
| status=217/USER | User=が存在しない | user作成 or unit修正 → daemon-reload |
| repeated too quickly | StartLimit発火(既定10秒5回) | 原因直してから reset-failed |

## exit status code（お膳立て失敗）
| code | 意味 |
|---|---|
| 203/EXEC | binary実行不可(無い/実行ビット無し/shebang不正) |
| 200/CHDIR | WorkingDirに入れない |
| 217/USER | User=が存在しない |
| 216/GROUP | Group=が存在しない |
| 226/NAMESPACE | サンドボックス構築失敗 |

`man systemd.exec` の Process Exit Codes 参照

## 鉄則
- 症状(failed/repeated too quickly)と本体(最初のError行)を分ける。原因は症状の数行〜数十行"上"。
- root causeを消してから症状(reset-failed)を消す。
- unit変更後は daemon-reload。drop-inは .d/*.conf。
- 使用中のポート/プロセスをいきなりkillしない。

## 障害⑥ ディスク枯渇（ENOSPC / inode）
現象: `No space left on device`
- バイト枯渇: `df -h`(Use% 100%) → `du -h --max-depth=1 <path> | sort -rh` で犯人特定 → 削除/logrotate
- inode枯渇: `df -h`は余裕なのに書けない → `df -i`(IUse% 100%) → 小ファイル大量生成 → 犯人dir特定して削除
- 罠: 巨大ログをrmしても空かない → プロセスが握ってる。`lsof | grep deleted` → 該当サービスrestart
- 根治: logrotate、Use%閾値の監視アラート

## 障害⑦ メモリ枯渇 / OOM killer
現象: プロセスが突然消える
- 確認: `dmesg | grep -iE 'oom|out of memory|killed'`（journalctl -k が空でもdmesgに出る）
- 読む: `Killed process PID (name) ... anon-rss:XXX`（rss=実物理使用がキー）
- 注意: 殺された者≠原因。`ps aux --sort=-rss | head` で食ってた犯人を別途追う
- 予兆監視: `free -h` / `ps aux --sort=-rss`
- 防御: unitに `MemoryMax=`、重要サービスは `OOMScoreAdjust=-1000`
- 教訓: ログは経路と窓を疑う（-k空でもdmesgで確認）

## 集計ツール
- `log_report.sh <access-log>`（総数/ステータス内訳/上位パス/上位IP/5xx件数）

## 監視スタック（Prometheus + node_exporter + Grafana）
- 収集: node_exporter(:9100 hostのCPU/mem/disk) / healthapp(:8080/metrics 自作) → Prometheus(:9090)がscrape・保存
- 可視化: Grafana(:3000)がPrometheusをデータソースに描画
- 主要PromQL:
  - ディスク%: 100*(1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"})
  - メモリ%: 100*(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)
  - CPU%: 100*(1 - avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])))
  - counterはrate()で勢いに変換、gaugeはそのまま
- 対象死活: up==0 でサービス/ホスト停止を検知（最重要）
- アラート: alert.rules.yml に expr/for/severity/annotations。Inactive→Pending(for待機)→Firing。配信はAlertmanager(別部品)
- 検証: promtool check config / promtool check rules（nginx -t / sshd -t と同じ、反映前に検証）
- 公開の鉄則: ufwは送信元を絞る、認証無しツールは最小公開 or nginx前段で保護
