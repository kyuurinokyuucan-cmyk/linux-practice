# SIEM / EDR を自分の言葉で（2026-08-08）

## 1. 手作業 → SIEMの機能

| 自分がやった手作業 | それは何をしていたか（自分の言葉） | SIEMの機能 | クエリで言うと |
|---|---|---|---|
| `zcat -f /var/log/auth.log*` |ファイルを表示する |収集 | |
| `grep "Failed password"` |Failed passwordがあるディレクトリを探す |検索 | |
| `awk '{print $(NF-3)}'` |最後から3列目を表示 |正規化 | |
| `sort \| uniq -c \| sort -rn` |カウントと順番を整理する |集約 | |
| 同一IPが触ったユニークユーザー数を数える |不正IPを検知する |集約 | |
| `journalctl --since` で時間窓を切る |いつからのアクセスかを見る |検索 | |
| auth.log と別ログを時刻で突き合わせる |横断を見る |相関 | |
| 閾値を超えたIPを目で拾う |原因を調査するため |アラート | |
| これを3台分やる → 100台分を想像する |効率化を意識する |収集 | |

## 2. EDRは何を見ているか

Q1. SIEMに届くログは、誰が書いているか。書かなかった場合どうなるか。　自動検知がログ書いてる？存在しない
Q2. auth.log にも journald にも残らないホスト内の挙動を3つ挙げる。　　メモリ上だけでコードを実行　プロセスの親子関係　
Q3. EDRができる「Response（対処）」を3つ挙げる。SIEMにできるか。　　　
Q4. Microsoft Sentinel と Microsoft Defender for Endpoint は競合か補完か。
    データの流れを矢印で書く。　　　　　　　　　　　　　　　　　　　　　sentilel→endpoint
Q5. Splunk はSIEM側かEDR側か。理由を1行。                               siem?ログ収集だから


## 3. 自宅ラボ3台の話としてのSIEM

- mimir / yggdrasil / ratatoskr のログは今どこにあるか
- 攻撃者が mimir に入り ssh で yggdrasil へ横移動したとき、　　
  1台のログだけでは何が見えないか（T1021.004）
- 3台のログを1台に集めるだけでは足りないもの
- 「アラート0件」を安心と読める条件／最危険と読むべき条件
