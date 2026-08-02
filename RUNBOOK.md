# RUNBOOK — 障害対応 手順書

障害を検知したら、まずこのファイルを開く。上から順に実行する。

---

## STEP 1: 全体スキャン（mimir）

uptime # load average（コア数と比較）
free -h # available を見る（used ではない）
df -h; df -i # バイトと inode は別勘定。必ずセット
systemctl list-units --failed # 失敗しているサービス
systemctl is-active nginx labtest # 主要サービスの生死


**この5行で大半の異常は見つかる。**
何も引っかからない → ネットワーク系を疑って STEP 2 へ。

### 注意
- load は「平常時と比べて」判断する。ベースラインを知らないと異常を見逃す
- 進行中の障害はスナップショット1回では見えない。時間を置いて2回見る

---

## STEP 2: 外部視点（client = yggdrasil の WSL2）

ping -c 2 192.168.11.200
curl -v -m 5 http://192.168.11.200


| 結果 | 意味 | 疑う層 |
|---|---|---|
| ping OK / curl refused | 届いたが待ち受け無し（RST） | サービス側 |
| ping OK / curl timed out | 届かない（DROP） | ファイアウォール・経路 |
| ping NG | 到達不能 | L3・経路・ホストダウン |

---

## STEP 3: 領域を絞って決め手を打つ（mimir）

### nginx が不調

systemctl status nginx --no-pager
sudo nginx -t # 設定検証（行番号付きでエラーが出る）
journalctl -u nginx -n 20 --no-pager

| 判定 | 状態 |
|---|---|
| inactive (dead) + nginx -t OK | 単純な停止 → `systemctl start nginx` |
| failed + nginx -t エラー | 設定破損 → 該当行を修正 → `nginx -t` → restart |

### systemd サービスが不調

systemctl status <unit> --no-pager
systemctl cat <unit> # 本体+drop-in の連結（どのファイル由来か分かる）
systemctl show -p ExecStart <unit> # 実効値（ファイルを読むより確実）
journalctl -u <unit> -n 30 --no-pager

| 判定 | 状態 |
|---|---|
| cat が /dev/null を指す | mask → `systemctl unmask <unit>` |
| status に 203/EXEC | 実行ファイルが無い → ExecStart のパスを確認 |
| Condition check ... skipped | 条件不成立で未実行（失敗ではない） |
| repeated too quickly | StartLimit → 原因を直して `reset-failed` |

### ディスクが不調

df -h; df -i
sudo du -h --max-depth=1 /var | sort -rh | head
sudo du -sh /mnt/testdisk # df と食い違わないか
sudo lsof +L1 | grep -v memfd | sort -k7 -rn | head

| 判定 | 状態 |
|---|---|
| Use% 100% | バイト枯渇 → du で掘って削る |
| IUse% 100%（df -h に空きあり） | inode 枯渇 → 小ファイルの山を削除 |
| df 満杯だが du が合わない | 削除済み+fd保持 → lsof +L1 で PID 特定 → kill/再起動 |

巨大ログは `rm` でなく `truncate -s 0 <file>`

### load が高い

vmstat 1 3 # us / wa / si-so でリソースを割る
free -h
ps aux --sort=-%cpu | head -5 # CPU の犯人
ps -eo pid,user,rss,%mem,comm --sort=-rss | head -5 # メモリの犯人
ps -fp <PID> # 犯人の詳細（親PPID・起動時刻・フルコマンド）

| 判定 | リソース | 犯人の探し方 |
|---|---|---|
| us 高・wa 低 | CPU | `--sort=-%cpu` |
| us 低・available 僅少・si/so 活発 | メモリ | `--sort=-rss` |
| us 低・wa 高 | I/O | ディスク・NFS を疑う |

**START 時刻を必ず見る。** 過去の残骸と今回の障害を分離できる。

対処: `kill -15 <PID>` → 効かねば `kill -9`
止めたくない重いプロセス → `renice +10 -p <PID>`

---

## STEP 4: 一次報告を書く

date "+%Y-%m-%d %H:%M:%S %Z"

【一次報告】<現象> / <発生時刻 JST>
■影響: <誰が・何ができないか>
■現状: <確認済みの事実 / 実施中の対応>
■原因: 調査中
■次報告: <HH:MM JST までに>


**一次報告に原因は要らない。速さが価値。**

### 書き方の鉄則
- 時刻には必ず TZ（`14:32 JST`）
- 影響は「誰が何をできないか」で書く
- 事実「〜を確認」/ 推測「〜と思われる」/ 未確認「〜は未確認」
- 次報告の時刻を自分から宣言する

---

## STEP 5: 復旧確認 → 最終報告

systemctl is-active <unit>
curl -I -m 5 http://192.168.11.200 # client から

【最終報告】<件名>
■発生時刻 / ■復旧時刻（影響時間: N分）
■影響: <誰が何をできなかったか>
■時系列: 検知 → 一次切り分け → 原因特定 → 対処 → 復旧確認
■原因: 直接原因 / 根本原因（分けて書く）
■対処 / ■恒久対策（いつまでに誰が） / ■残課題


---

## 原則

- **想像で設定を触る前に、状態とログで事実を確認する**
- **下の層から順に「どこまで正常か」を確定させる**
- **エラーが無いことを正常の証拠にしない**（Condition skip / アラート0件）
- **1回に1つだけ変える**
- **同じ症状でも原因は違う。決め手のコマンドで割る**

---

## 詳細リファレンス
- ディスク: [docs/cheatsheet_disk.md](docs/cheatsheet_disk.md)
- systemd: [docs/cheatsheet_systemd.md](docs/cheatsheet_systemd.md)
- 報告テンプレ: [docs/cheatsheet_report.md](docs/cheatsheet_report.md)
- リソース: [docs/resource_triage.md](docs/resource_triage.md)
- ネットワーク: [docs/network_map.md](docs/network_map.md)
- 切り分けの型: [docs/troubleshooting_framework.md](docs/troubleshooting_framework.md)

## 演習環境
`lab/break.sh`（障害注入・10種）→ 切り分け → `lab/fix.sh`（復旧・答え合わせ）
