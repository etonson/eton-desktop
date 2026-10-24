# 備份與回復

備份根目錄：`${XDG_DATA_HOME:-$HOME/.local/share}/forest-retreat/backups/`。

`backup.sh` 在首次套用前保存 WezTerm 原始檔、目標路徑、SHA256，及當時 GNOME 介面與桌布值。`wallpaper.sh backup` 在**桌布套用前**另存當下的 URI、圖片檔、`picture-options` 與各鍵是否有使用者值。若桌布曾在兩次備份間改變，以後者作為桌布回復點。GTK、圖示與 Blur my Shell 仍由 `eton-desktop` 管理，本方案不更動它們。

`apply.sh` 先列出預計變更及完整 diff，只接受與備份相同的原始 WezTerm 設定。`wallpaper.sh apply` 也會列出三個 GNOME 鍵與目標圖片路徑，只接受與桌布備份相同的原始值。再次執行且內容已一致時不寫入。`rollback.sh --dry-run` 預檢兩部分；實際回復前，若目前內容不同於本次套用結果，會提示衝突並停止。新圖片僅在由本方案建立且雜湊未變時移除。

```bash
./scripts/rollback.sh --dry-run
./scripts/rollback.sh
```

回復保留備份供查核。若套用後自行修改了 WezTerm 或桌布設定，先人工比對變更，再選擇合併或另外保存；腳本不會自動丟棄後續修改。若改了 symlink 指向，或原桌布檔案內容變了，腳本也會停止。備份與原設定中的個人路徑、Shell 設定應只保存在自己的帳號中。
