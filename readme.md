# LaTeX on Docker

> 通用型 XeLaTeX / pdfLaTeX 編譯環境  
> 自動偵測引擎、自動追蹤子檔案，支援中文與學術論文格式  
> 適合跨平台開發與 CI 使用

---

## 專案連結

- Docker Hub: [`liuming9124/latex-docker`](https://hub.docker.com/r/liuming9124/latex-docker)
- GitHub: [`Liuming9124/latex-docker`](https://github.com/Liuming9124/latex-docker)

---

## 功能與特色

自動偵測：
- 引擎：`pdfLaTeX` 或 `XeLaTeX`
- 相依檔案（`\input{}`、圖片、bib）異動會自動觸發重新編譯

- 初次編譯自動使用 `latexmk -gg` 建立依賴快取

- 預設啟用：
  - 集中輸出至 `build/`（含中介檔、PDF）
  -   預裝常見中文字型（思源宋黑、標楷體）

- 支援 watch 模式（預設啟用）

---

## 專案結構建議

```plaintext
.
├── docker-compose.yml
├── Dockerfile
├── proposal.tex
├── sec-cm03.tex
├── proposal.bib
├── figures/
│   └── ...
````

---

## 快速使用

### 建置（使用本地 `Dockerfile`）

```powershell
docker compose build
# 或強制不使用快取
docker compose build --no-cache
```

---

### 使用已發佈的映像

#### 一次編譯並自動選擇引擎

```powershell
docker run --rm -v "${PWD}:/work" -e TEX_MAIN="proposal.tex" liuming9124/latex-docker
```

#### 清除中介檔案（build/、aux、log）

```powershell
docker run --rm -v "${PWD}:/work" liuming9124/latex-docker bash -lc "latexmk -C"
```

---

### 使用 docker compose（需有 `docker-compose.yml`）

#### 自動 watch 編譯（建議方式）

```powershell
docker compose run --rm tex
```

#### 清除中介檔

```powershell
docker compose run --rm tex bash -lc "latexmk -C"
```

---

## Watch 編譯行為說明

| 狀況        | 動作              |
| --------- | --------------- |
| 第一次編譯     | 自動啟用 `-gg` 建立依賴 |
| 修改子檔案     | 自動重新編譯          |
| 修改圖、bib 等 | 自動偵測異動重新編譯      |
| 不需重新建構依賴  | 不會執行 `-gg`，節省時間 |

---

## 自訂參數（可於 docker-compose.yml 或 CLI 設定）

| 環境變數         | 說明                             | 預設值     |
| ------------ | ------------------------------ | ------- |
| `TEX_MAIN`   | 主 `.tex` 檔案名稱（支援 `*.tex`）      | `*.tex` |
| `TEX_ENGINE` | 編譯引擎（`auto`, `pdf`, `xelatex`） | `auto`  |
| `TEX_WATCH`  | 是否啟用 watch 模式（1=開, 0=關）        | `1`     |

---

## 推薦用途

* 學位論文編寫（含圖片與子檔）
* NSC/TW研究計畫書撰寫
* 雲端 LaTeX 編譯與持續整合 CI
