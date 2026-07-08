# linux-practice

インフラエンジニア転職に向けたLinux学習の実践記録。
VM (Ubuntu) 上で作成した運用スクリプト群。

## スクリプト一覧

- health.sh — システム状態の確認
- monitor.sh — ディスク/メモリを閾値監視し、[WARN]/[OK]をログ記録
- disk_check.sh — ディスク使用率の定期記録（cron用）
- heartbeat.sh — systemdサービス化の練習用常駐スクリプト
- deploy.sh — ノートPCからVMへスクリプトを配布・実行するデプロイスクリプト

## 学んだこと

- systemd unitファイルの自作（Restart=alwaysによる自動復旧）
- cronとsystemdの使い分け（定期単発 vs 常駐）
- ログ設計（grepで抽出できる[WARN]タグ）
