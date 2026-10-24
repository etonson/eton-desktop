# 相容性與驗收

- 本機 Blur my Shell v76 metadata 包含 GNOME 50。`eton-desktop` 的實測紀錄指出此版本搭配 Ubuntu Dock 時，開啟 Dock 模糊會導致應用程式格狀清單空白，因此保持 Dock 模糊關閉。
- WezTerm 版本支援 `window_background_opacity`。本機測試顯示 `Everforest Dark (Medium)` 不是內建配色名稱；Lua 色值片段不依賴名稱解析。
- Wayland 支援透明視窗，但透明不等於背景模糊。GNOME Shell 擴充套件是否會模糊 WezTerm 窗後內容，仍須在實際桌面檢查。
- GNOME Shell、GTK4/libadwaita、Firefox、IntelliJ、Java 工具鏈和 Podman 均未被此專案修改。
- 對 IntelliJ 只建議可選的配色試用；必須人工檢查程式碼與警示對比度後才決定是否採用。

## 實測清單

| 項目 | 狀態 |
| --- | --- |
| 版本、擴充套件 metadata、WezTerm 路徑與字型 | 已查 |
| Bash 語法、ShellCheck、隔離設定的備份／套用／重複執行／回復 | 已通過 |
| 實際設定備份、套用、雜湊驗證、WezTerm 設定解析 | 已通過，2026-10-25 |
| 實際桌布備份、套用、GNOME 值與圖片雜湊 | 已通過，2026-10-25 |
| 桌布完整套用與回復 | 隔離 DConf 工作階段已通過；實際設定的回復預覽已通過 |
| WezTerm Wayland 透明與可讀性 | 需人工目視 |
| 桌布在實際螢幕、頂欄與 Dock 下的裁切 | 需人工目視 |
| 登出登入、Dock、Overview、Firefox、IntelliJ | 需人工目視 |
| WezTerm rollback | 實際設定的 dry-run 已通過；完整回復已在隔離設定測試 |

參考：[WezTerm 透明度](https://wezterm.org/config/lua/config/window_background_opacity.html)、[Blur my Shell](https://extensions.gnome.org/extension/3193/blur-my-shell/)。
