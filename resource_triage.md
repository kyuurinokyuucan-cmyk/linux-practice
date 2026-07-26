# Resource Triage（重い/固まった の切り分け）

サーバが重いとき、CPU・メモリ・I/O のどれが律速かを一発で切る型。

## Step 1: load average を読む
uptime 末尾 `load average: 1分, 5分, 15分` = CPU の順番待ち行列長。
コア数(nproc)と比べる。コア数 = ちょうど飽和 / 超 = 過負荷 / 下 = 余裕。
1分 > 15分 なら悪化中、逆なら回復中。

このマシンのコア数: 12

## Step 2: 3大パターンの見分け
| パターン | load | us (CPU) | wa (I/O) | available / swap |
|---|---|---|---|---|
| CPU張り付き | 高 | 高(90%〜) | 低 | 潤沢 / 0 |
| メモリ枯渇 | 高 | 低 | 低 | 僅少 / si-so活発 |
| I/O待ち | 高 | 低 | 高(70%〜) | 潤沢 / 0 |

読む道具: free -h の available、vmstat 1 の us/wa/si/so。
※「数値が高い=異常」ではない。コア数と各指標を突き合わせて初めて判断。

## Step 3: 犯人特定と対処
- CPU犯人: ps aux --sort=-%cpu | head
- メモリ犯人: ps aux --sort=-rss | head
- 正体確認: ps -fp <PID> (親PPID・起動時刻・フルコマンド)
- 対処: kill -15 → 効かねば -9 / 止めたくない重い奴は renice +N で優先度を下げる



