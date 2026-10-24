# 環境盤點

盤點日期：2026-10-25。資料來自唯讀檢查；沙箱中的 dconf 讀取會有唯讀警告。

| 項目 | 結果 |
| --- | --- |
| 系統 | Ubuntu 26.04.1 LTS |
| GNOME Shell | 50.1，Wayland 工作階段 |
| GTK | `Yaru-prussiangreen-dark`，`prefer-dark` |
| Icon | `Tela-dark`；未找到 Papirus Dark |
| Blur my Shell | 本機 v76，metadata 宣告支援 Shell 46–51，GNOME 啟用清單中有該 UUID |
| WezTerm | `20240203-110809-5046fc22` |
| WezTerm 設定 | `${XDG_CONFIG_HOME:-$HOME/.config}/wezterm/wezterm.lua`，目前經由 symlink 指向 dotfiles；不得以覆寫 symlink 的方式修改 |
| WezTerm 字型 | `JetBrainsMono Nerd Font` 14pt，已安裝 |
| GNOME 介面字型 | `Ubuntu Sans 11` |
| IntelliJ IDEA | 2026.2.3 |
| 桌布 | 現有本機 1536×1024 PNG，明暗模式相同；畫面是高亮藍色水面與金色蓮花，和低飽和霧林方向不一致 |

內建螢幕已連接，可列出 2560×1600、1920×1200 等模式；沙箱無法讀取當下 GNOME 使用的解析度。歷史 `monitors.xml` 也記錄了外接 2560×1440 螢幕，不能當作目前連線狀態。

`eton-desktop/config/profile.json` 已管理 GNOME 深色模式、Tela 圖示、Blur my Shell 的 Panel、Overview、Popup 和應用程式效果。Dock 模糊刻意關閉，原因見該專案 README；Forest Retreat 不建立第二份互相競爭的 GNOME profile。

2026-10-25 桌布套用前重新讀取實際 GNOME 工作階段，發現當時 URI 已改為 `~/snap/firefox/common/Firefox_wallpaper.png`，圖像為 1316×877 黑白霧湖，`picture-options` 為 `centered`。初次盤點的蓮花圖已不是套用前桌布；`wallpaper.sh backup` 已以黑白霧湖為回復點，並另存圖片內容。現已套用 Rowan Heuvel 霧湖松林原圖及 `zoom`。
