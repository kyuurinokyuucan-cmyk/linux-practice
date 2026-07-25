cat > network_map.md << 'EOF'
# Network Map — ホームラボ全体構成（2026-07-25）

## 物理構成
Internet
  └─ HGW: RX-600MI (192.168.x.x)
       └─ ルータ: WXR-6000AX12S (LAN側 192.168.xx.1 = デフォルトGW)
            ├─ yggdrasil (新DT / miku)
            ├─ mimir      (server / rin)
            └─ ratatoskr  (ThinkPad / luka)

DHCPレンジ: 192.168.xx.2 〜 .65
mimir は 192.168.xx (レンジ外の固定IP。IP衝突回避の教訓)

## 各機の諸元
| 機体 | hostname | user | IP | mask | GW | DNS |
|---|---|---|---|---|---|---|
| 新DT | yggdrasil | miku | TODO(ip a) | /24 | 192.168.11.1 | TODO(resolvectl) |
| server | mimir | rin | 192.168.11.200 | /24 | 192.168.11.1 | TODO |
| ThinkPad | ratatoskr | luka | TODO(ip a) | /24 | 192.168.11.1 | TODO |

## 経路 (tracepath 実測)
### client → mimir (192.168.11.200)
1ホップ = 同一サブネット・直接
実測:hops 1 back 1

### client → 外部 (8.8.8.8)
複数ホップ = 二重NAT (1段目 WXR .11.1 → 2段目 HGW .1.1 → ...)
実測: [LOCALHOST]                      pmtu 1500

## Tailscale (論理レイヤー)
物理LAN(192.168.11.x)とは別に、Tailscale mesh(100.x.x.x)で3台を接続。
物理サブネットを越えて、暗号化トンネルで直接繋がる論理ネットワーク。
外出先からは 100.x 経由で mimir にSSH (ssh mimir-ts)。

| 機体 | Tailscale IP |
|---|---|
| yggdrasil | 100.105.202.17  |
| mimir | 100.89.164.0 |
| ratatoskr | 100.82.125.89 |
EOF
