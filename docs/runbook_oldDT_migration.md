# 旧DT Ubuntu Server化 手順書

## 目的
旧デスクトップ(i5-12400F/32GB)を、VirtualBox上のVMから、
物理マシン直インストールのUbuntu Serverへ移行する。

## 前提・準備
## 前提・準備
- [ ] 旧DTのWindowsから退避すべきデータを外付け/ノートにコピー済み
- [ ] コピーしたデータを別マシンで開けるか検証済み（復元テストの思想）
- [ ] 学習スクリプトはGitHubにpush済み（linux-practiceリポジトリ）
- [ ] Ubuntu ServerのISOをダウンロード、USBインストーラ作成済み
- [ ] 新DTが安定稼働中（＝作業中も稼働マシンが1台残る状態）
- [ ] 部屋のLAN差込口のネットワーク帯を確認済み（ip aで192.168.11.x帯か）

## 手順

### 1. Ubuntu Serverインストール
（USBから起動→インストール）

### 2. ネットワーク確認
（IPアドレスの確認方法。ip a）

### 3. SSH接続の確立
（ノートのWSL2から入れるようにする。

ssh-copy-id で旧DTの新IPに公開鍵を登録→WSL2の ~/.ssh/config に Host oldsv として HostName（新IP）/User を追記。これで ssh oldsv で入れる）

### 4. SSH要塞化
（パスワード認証とroot loginをどうする？変更前後にやる安全確認
/etc/ssh/sshd_config をバックアップ(cp .bak)→ PasswordAuthentication no / PermitRootLogin no(#を
外す)→ sudo sshd -t で構文チェック→ systemctl restart ssh→ 別端末で鍵接続とパスワード拒否を検証。）

### 5. ufw設定
（順番が命。何を先にやる？）先に sudo ufw allow 22（作業経路の確保が絶対先）→ その後 sudo ufw enable→ ufw status verbose で確認。リモートで順序を
逆にすると締め出し。

### 6. Docker導入
（インストールとsudoなし化sudo apt install docker.io -y → sudo usermod -aG docker $USER → 入り直して docker ps で確認。）

### 7. 監視の再構築
（monitor.sh配置、systemd timer登録）git clone でlinux-practiceを取得→ monitor.sh を ~/bin/ に配置(shebang #!/bin/bash と chmod +x を忘れずに。
Exec format errorの教訓)→ monitor.service(Type=oneshot)とmonitor.timer(OnCalendar=*:0/5)を /etc/systemd/system/ に作成
→ daemon-reload → enable --now monitor.timer → list-timers で確認。

## ロールバック
- 旧DTのWindowsは復元しない前提（データ退避済み・検証済みが条件）
- ただし移行が完了するまで、以下を保険として維持:
  - 新DTが稼働中（作業マシンが常に1台残る）
  - VMのUbuntu環境は、旧DT構築が完全に終わるまで削除しない
  - GitHubのlinux-practiceが全スクリプトの復元元
- SSH設定で締め出した場合:
  - 物理コンソール（旧DTに直接モニタ・キーボード接続）から復旧
  - sshd_config.bak を戻す
- ufwで締め出した場合:
  - 物理コンソールから sudo ufw disable

## 完了条件
- [ ] ノートのWSL2から ssh oldsv で鍵認証ログインできる
- [ ] パスワード認証が拒否される（ssh -o PubkeyAuthentication=no で確認）
- [ ] ufw status が SSH(22)のみ ALLOW、他は拒否
- [ ] docker ps が sudoなしで実行できる
- [ ] systemctl list-timers に monitor.timer が表示される
- [ ] 5分後、monitor.log に新しい行が記録される
- [ ] journalctl -u monitor.service に実行履歴が残る
