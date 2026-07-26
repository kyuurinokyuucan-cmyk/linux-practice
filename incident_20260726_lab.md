# 【最終報告】ラボ演習インシデント（2026-07-26）

■発生時刻: 2026-07-26 18:25:54 JST（systemctl status の状態遷移時刻）
■復旧時刻: 2026-07-26 18:4x JST
■影響: 停止中、192.168.11.200:80 への接続は Connection refused。
        HTTP 提供は全面不可。labtest は稼働継続、failed unit 0件。
        停止時間中の実アクセス有無は調査中。

■時系列:
  18:25:54 JST  nginx.service 停止（systemctl status の状態遷移時刻）
  ??:??         検知：目視確認により発覚（systemctl is-active nginx → inactive）
                ※アラート等による自動検知ではない
  ??:??         一次切り分け：
                - systemctl is-active nginx labtest → inactive / active
                - ss -tlnp | grep :80 → 出力なし（LISTEN 消失）
                → 単一サービスの停止と判断（層⑥＝アプリケーション層）
                ※client からの ping / curl は未実施（外部視点の記録なし）
  ??:??         原因特定：上記2コマンドが決め手。
                systemctl / ss の2系統から同一結論に到達
                ※systemctl status / journalctl は復旧前に未取得
  ??:??         対処実施：nginx.service を起動
  ??:??         復旧確認：is-active → active
                ※:80 の LISTEN 復帰確認、client からの curl 確認は未実施

■原因:
  直接原因: nginx.service に対する明示的な停止操作。
            異常終了ではない（failed unit 0件）。
  根本原因: 障害訓練スクリプト ~/lab/break.sh の実行により、
            fault 1（systemctl stop nginx）が選択された。
            → 演習環境における意図的な注入であり、
              システム側の欠陥・設定ミスに起因するものではない。

■対処: nginx.service の起動により HTTP 提供を復旧。

■恒久対策:
  1. 死活監視の自動化（今回の最大の課題）
     外部視点で :80 を定期的に叩き、失敗時に通知する仕組みを入れる。
  2. サービス停止の追跡性確保
     誰がいつ停止したかを後から辿れる状態にする。
  3. 切り分け記録の即時保存
     判断の根拠となった出力を、復旧前にファイルへ残す運用にする。

■残課題:
  - 停止時間中に実アクセスがあったかが不明（access.log 未確認のまま復旧）
  - 検知に要した時間が計測できていない（時刻の記録漏れ）
  - Restart= による自動復旧が今回のケースに有効かの検証
