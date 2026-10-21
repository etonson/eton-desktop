# eton-desktop

把 GNOME 桌面調成深色＋毛玻璃風格的個人設定工具。所有設定都寫在版控裡的 profile，可以重複套用，也能還原成套用前的狀態。

適用環境：Ubuntu GNOME（Shell 46–51）、Wayland，以一般使用者身分執行，不需要 sudo。

## 架構

```
config/
  sources.json   外部素材的來源：Tela 圖示（固定 commit）、Blur my Shell（固定版本與 sha256）
  profile.json   要寫入的 GSettings 值：{ schema: { key: GVariant 文字 } }
scripts/
  install.sh     下載並驗證 sources.json 裡的素材，安裝到 ~/.local/share，最後呼叫 settings.py apply
  settings.py    讀 profile.json、驗證、寫入 GSettings、備份與還原
tests/
  test_settings.py  驗證 profile.json 與目前安裝的 schema 相符
```

流程：

1. `install.sh` 下載 Tela 圖示主題和 Blur my Shell 擴充套件，比對 commit／sha256／metadata 後安裝（只裝在使用者目錄）。
2. `settings.py apply` 先用 schema 驗證 profile 裡**每一個**值（key 存在、型別正確、在允許範圍、未被鎖定），全部通過才開始寫入。
3. 第一次寫入某個 key 前，會把原本的值存到 `~/.local/state/eton-desktop/previous-settings.json`。之後重複套用只會補記新加入的 key，不會覆蓋最初的原始值，所以 `restore` 永遠回到第一次套用之前的狀態。

## 使用方法

```sh
./scripts/install.sh            # 第一次安裝：下載素材＋套用 profile
./scripts/install.sh --check    # 只檢查環境

./scripts/settings.py apply --dry-run   # 預覽會寫入哪些值
./scripts/settings.py apply             # 套用 profile.json
./scripts/settings.py status            # 顯示目前值與備份位置
./scripts/settings.py restore           # 還原成第一次套用前的設定

# 修改 profile.json 裡的單一值（只改檔案，要再 apply 才會生效）
./scripts/settings.py set org.gnome.shell.extensions.blur-my-shell.applications opacity 200
./scripts/settings.py apply
```

`set` 的值是 GVariant 文字格式：數字直接寫（`200`、`0.75`），字串要加單引號（`"'prefer-dark'"`），字串陣列寫成 `"['a', 'b']"`。

也可以直接編輯 `config/profile.json`，改完再跑 `apply`。大部分變更會立刻生效；已經開著的視窗沒變化的話，關掉再重開即可。

## 參數說明

### 桌面外觀（`org.gnome.desktop.interface`）

| key | 目前值 | 說明 |
|---|---|---|
| `color-scheme` | `'prefer-dark'` | 深色模式 |
| `icon-theme` | `'Tela-dark'` | 圖示主題 |

### Shell 元件模糊（Blur my Shell）

`panel`（頂欄）、`dash-to-dock`（Dock）、`overview`（概覽）、`popup`（彈出選單）這幾組都設 `blur = true`，搭配 `style-* = 2`（Blur my Shell 內建的深色樣式）。頂欄另外設 `force-light-text = true`，讓文字維持淺色。

### 應用程式視窗毛玻璃（`org.gnome.shell.extensions.blur-my-shell.applications`）

| key | 目前值 | 說明 |
|---|---|---|
| `blur` | `true` | 開啟視窗模糊 |
| `enable-all` | `false` | 只模糊白名單裡的 App |
| `whitelist` | 終端機、Nautilus、Chrome、Firefox | 視窗 WM_CLASS，不分大小寫，可用 `*` 萬用字元 |
| `opacity` | `190` | 視窗不透明度，0–255；越低越通透 |
| `dynamic-opacity` | `true` | 視窗操作中時自動變得比較不透明 |
| `sigma` | `40` | 模糊程度；越高越柔和，但 GPU 負擔較大 |
| `brightness` | `0.75` | 背景亮度，0–1；越低越暗，淺色文字越清楚 |

這組值會套用到白名單裡的所有 App，無法個別設定。

要找某個 App 的 WM_CLASS，可以看它 `.desktop` 檔裡的 `StartupWMClass`，或用 Blur my Shell 設定中白名單旁的「挑選視窗」按鈕。

Blur my Shell 的 schema 沒有宣告數值範圍，所以 `opacity`、`sigma`、`brightness` 只會檢查型別，不會檢查範圍。請自己保持在上表的合理區間。

## 測試

```sh
python3 -m unittest discover tests
```

測試會讀取目前安裝的 schema，驗證 `profile.json` 的每個值，以及 `set` 的行為。沒有安裝 Blur my Shell 的機器上，相關測試會自動略過。
