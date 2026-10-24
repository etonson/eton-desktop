# 設計決策

Forest Retreat 以安靜、低飽和、易讀為主。現有 Yaru 深綠變體與 Tela-dark 比改成通用 Yaru Dark 更接近松針灰綠，也少一次套件與設定變更。

## 配色比較

| 方案 | 長時間閱讀 | 與桌面一致性 | 維護與相容性 |
| --- | --- | --- | --- |
| Everforest Dark Medium | 溫暖前景與中等對比，需在實際 log 測試 | 最高 | 本機沒有同名內建 scheme；使用獨立 Lua 色值片段 |
| Gruvbox Material | 柔和、暖色 | 偏木質秋色 | 本機沒有同名內建 scheme，需要自備色值 |
| Catppuccin Mocha | 對比與辨識度良好 | 紫藍調較突出 | 本機已有內建 scheme，維護較少 |

WezTerm 片段的 Dark Medium 色值取自 [Everforest 作者公開的終端機方案](https://gist.github.com/sainnhe/6432f83181c4520ea87b5211fed27950)；`config/wezterm.lua` 只提供 `config.colors` 區塊。`0.96` 透明度由套用腳本單獨調整，可與原有 `0.95` 比較。選取色、游標及 ANSI 色皆跟隨同一色盤，原本字型、快捷鍵和 zsh 設定保留。

桌布目標比例以實際螢幕為準，優先 16:10，兼顧可能的 16:9 外接螢幕。找霧林、湖泊、遠山及柔和自然光，中央留白，避開上方 Panel 與側邊 Dock 的高對比細節。任何下載與套用須先確認圖片、來源、授權與預覽。

使用者確認 [Rowan Heuvel 的霧湖松林](https://unsplash.com/photos/misty-lake-surrounded-by-pine-trees-and-hills-9X9KkyF_7oc)。照片頁面標示依 [Unsplash License](https://unsplash.com/license) 免費使用；原圖 3840×2560，已取得並核對雜湊。會以 GNOME `zoom` 模式配合 16:10 或 16:9 螢幕，最後仍需目視確認構圖與 Dock 位置。來源細節見 [SOURCE.md](../assets/SOURCE.md)。
