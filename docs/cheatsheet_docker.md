# CHEATSHEET: コンテナ障害

## ホスト → コンテナ 対応表
| やること | ホスト | コンテナ |
|---|---|---|
| 状態 | systemctl status | docker ps -a |
| ログ | journalctl -u | docker logs |
| 起動停止 | systemctl start/stop | docker start/stop |
| 中に入る | (SSH) | docker exec -it <n> bash |
| プロセス | ps aux | docker top <n> |
| リソース | top / free | docker stats |
| 設定 | systemctl cat | docker inspect <n> |
| ポート | ss -tlnp | docker port <n> |

## STATUS の読み方（docker ps -a）
| STATUS | 意味 | 次の一手 |
|---|---|---|
| Up | 正常 | — |
| Exited (0) | 正常終了 | 設計通りか確認 |
| Exited (1) | アプリのエラー | docker logs |
| Exited (137) | OOM kill (128+9) | メモリ制限 / docker stats |
| Exited (143) | SIGTERM (128+15) | 正常停止 |
| Restarting | 起動失敗ループ | docker logs --since 10m |
| Created | 未起動 | docker start |

## 症状から引く
| 症状 | 一発目 | 判定 |
|---|---|---|
| curl が refused | docker ps -a | Exited なら落ちている |
| コンテナは Up だが繋がらない | docker port + docker exec で ss | ポートマッピング違い |
| 起動してすぐ落ちる | docker logs --tail 50 | アプリのエラー |
| 再起動ループ | docker logs --since 10m | 窓を絞らないと同じ行の山 |
| ディスク満杯 | docker system df | イメージ/キャッシュの肥大 |
| メモリで殺される | Exited (137) | メモリ制限 or ホストのOOM |

## 落とし穴
- `docker ps` は起動中のみ。落ちたものは `-a` が必須
- `-p` は ufw を迂回する → `127.0.0.1:8080:80` でローカルバインド
- コンテナを消すとデータも消える → volume / bind mount で永続化
- ディスクの犯人は Docker のことが多い → `docker system df` → `prune`
- exit code は 128+シグナル番号（137=SIGKILL, 143=SIGTERM）
