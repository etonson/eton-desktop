# Forest Retreat — 森林靜居

Ubuntu 26.04 GNOME 50 / Wayland 的低干擾桌面配色。此專案管理本次 WezTerm 色盤、透明度與桌布；現有 `eton-desktop` 專案繼續管理 GNOME 深色模式、Tela 圖示與 Blur my Shell。

## 目前決策

- GNOME：保留 `Yaru-prussiangreen-dark`、`Tela-dark`、Ubuntu Sans 及現有 Blur my Shell 設定。
- WezTerm：保留原有字型、快捷鍵、Shell、分頁與視窗設定；只改為 Everforest Dark Medium 色盤，背景透明度由 `0.95` 改為 `0.96`。
- IntelliJ：先保持現狀。日後若試 Everforest 配色，先檢查 Java 語法、警告、搜尋結果、diff 與 log 的對比度。
- 桌布：使用者已確認 [Rowan Heuvel 的霧湖松林照片](https://unsplash.com/photos/misty-lake-surrounded-by-pine-trees-and-hills-9X9KkyF_7oc)；來源、授權與雜湊見 [SOURCE.md](assets/SOURCE.md)。

## 部署狀態（2026-10-25）

WezTerm 配色與 `0.96` 透明度、Rowan Heuvel 霧湖松林桌布都已套用；實際檔案與 GNOME 設定已驗證。仍需在桌面目視確認透明效果、閱讀舒適度、桌布裁切，以及登出登入後的狀態。

## 操作順序

所有腳本以桌面使用者執行，不使用 `sudo`。`--dry-run` 不修改設定。開始前請先閱讀 `docs/rollback.md`。

```bash
./scripts/inspect.sh
./scripts/backup.sh --dry-run
./scripts/apply.sh --dry-run
./scripts/backup.sh
./scripts/apply.sh
./scripts/verify.sh
./scripts/wallpaper.sh backup --dry-run
./scripts/wallpaper.sh backup
./scripts/wallpaper.sh apply --dry-run
./scripts/wallpaper.sh apply
./scripts/wallpaper.sh verify
./scripts/rollback.sh --dry-run
```

`apply.sh` 管理 WezTerm，`wallpaper.sh` 依序管理桌布。兩者都可重複執行；若設定在備份後改變，套用或回復會停止並報告衝突。`rollback.sh` 會預檢並回復兩部分。實際備份放在 `${XDG_DATA_HOME:-$HOME/.local/share}/forest-retreat/backups/`。

更多細節：[環境](docs/environment.md)、[設計](docs/design.md)、[相容性](docs/compatibility.md)、[回復](docs/rollback.md)。
