nano attack_mapping.md# MITRE ATT&CK mapping (homelab observations)
## ATT&CKの構造
Tactic(なぜ) / Technique(どうやって) / Sub-technique(細かい手口)

## 今日の観測 → ATT&CK
2026-07-24T23:18:14.929005+00:00 mimir sshd-session[226440]: Connection closed by 172.18.0.2 port xxxxx
2026-07-24T23:19:14.937035+00:00 mimir sshd-session[226465]: Connection closed by 172.18.0.2 port xxxxx

## 環境のMitigation状況
mimir: 鍵認証のみ・パスワード認証無効 → T1110.001は原理的に成立しない
→ 「アラートが出ない」の理由が"安全"なのか"収集漏れ"なのかを区別する重要性

## auth_report.sh の検知gap
Technique               	自作スクリプトで検知できるか	        足 りないもの

T1110.001 (総当たり)	        ○ 回数閾値で検知	                時間窓がない（1年で10回も検知される）
T1110.003 (Password Spraying)	✗ 	                             1ユーザーへの集中でなく多ユーザーに1回ずつなので回数閾値をすり抜ける
T1078 (正規アカウント悪用)	△ Acceptedは拾えるが正常と区別不能	通常と異なる時刻/IP/地域のベースライン比較
T1021.004 (SSH横移動)    	✗	                               mimir単体のログしか見ていない。3台横断が必要

## 次に埋めるべきgap
- 時間窓の導入（N分以内にM回）
- Password Sprayingの検知（ユーザー横断で1回ずつ）
- 3台横断のログ集約 ← SIEMが必要になる理由
