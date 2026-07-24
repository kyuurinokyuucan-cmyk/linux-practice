# MITRE ATT&CK mapping (homelab observations)

## ATT&CKの構造
Tactic(なぜ) / Technique(どうやって) / Sub-technique(細かい手口)

## 今日の観測 → ATT&CK
（上の6行の表を埋めたもの。実際に撮ったログを1行ずつ添える）

## 環境のMitigation状況
mimir: 鍵認証のみ・パスワード認証無効 → T1110.001は原理的に成立しない
→ 「アラートが出ない」の理由が"安全"なのか"収集漏れ"なのかを区別する重要性

## auth_report.sh の検知gap
（3列の表）

## 次に埋めるべきgap
- 時間窓の導入（N分以内にM回）
- Password Sprayingの検知（ユーザー横断で1回ずつ）
- 3台横断のログ集約 ← SIEMが必要になる理由
