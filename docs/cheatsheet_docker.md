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

## 実測メモ（実機演習 2026-08-02）
### Up なのに refused
- 仕込み: `-p 8081:8080` だがコンテナ内は80番で待機
- 決め手: `docker port` でマッピング確認 + `docker exec` で内側の待ち受け確認
- 復旧: マッピングは変更不可 → `rm -f` して正しい `-p 8081:80` で作り直す

### 起動してすぐ落ちる
- `docker ps` には出ない → `-a` 必須
- `Exited (1)` = アプリのエラー → `docker logs` に実体

### 再起動ループ
- `--restart=always` + 起動失敗 = `Restarting (1)`
- `--tail` だと同じエラーの山 → `--since` で時間の窓に切る
- 回数確認: `docker inspect -f '{{ .RestartCount }}' <n>`

### メモリ制限で殺される
- `Exited (137)` = 128 + 9 (SIGKILL)
- 確定: `docker inspect -f '{{ .State.OOMKilled }}' <n>` が true
- ホスト側の証拠: `dmesg` に cgroup OOM

## コンテナ間ネットワーク
### 名前解決の可否
| ネットワーク | コンテナ名で引けるか |
|---|---|
| 既定の bridge | **引けない** |
| ユーザー定義ネットワーク | 引ける（Docker内蔵DNS） |
| Compose が自動作成するもの | 引ける（サービス名で） |

### 症状から引く
| 症状 | 一発目 | 判定 |
|---|---|---|
| コンテナ間で名前が引けない | `docker exec <n> getent hosts <相手>` | DNS層で落ちている |
| 両方 Up なのに繋がらない | `docker inspect -f '{{ range $k,$v := .NetworkSettings.Networks }}{{ $k }} {{ end }}' <n>` | 所属ネットワーク不一致 |
| 起動直後だけ繋がらない | `docker compose ps` の healthy 有無 | depends_on は順序のみ |

### depends_on の誤解（systemd と同じ構造）
- `depends_on` 単体 = After=（起動順序のみ。準備完了は保証しない）
- `depends_on` + `condition: service_healthy` = 本当の依存（healthcheck 必須）

### 複数ネットワーク構成
共通ネットワークを1つでも共有していれば繋がる。
3層構成の型: web→front / db→back / api→front,back
