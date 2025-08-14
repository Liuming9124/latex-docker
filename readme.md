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


* **自動偵測引擎**：`pdfLaTeX` 或 `XeLaTeX`（根據專案內容判斷）
* **相依檔案追蹤**：`\input{}`、圖片、`.bib` 變更會觸發重新編譯
* **初次編譯自動加 `-gg`**（建立依賴快取）
* **集中輸出**：中介檔與 PDF 會放在 `build/` 資料夾
* **預裝常用中文字型**：思源宋黑、標楷體（自動嘗試替換缺字問題）
* **可選 watch 模式**（`TEX_WATCH=1` 啟用，預設關閉，可即時監看檔案變更，自動重新編譯）


---

## 專案結構建議

```plaintext
├── docker-compose.yml
├── Dockerfile
├── proposal.tex
├── sec-01-intro.tex
├── proposal.bib
├── figures/
│   └── fig1.png
````

---

## 快速使用

### 1. 使用本地 `Dockerfile` 建置

```powershell
docker compose build
# 或強制不使用快取
docker compose build --no-cache
```

---

### 2. 使用已發佈映像（預設單次編譯）

```powershell
docker run --rm `
    -v "${PWD}:/work" `
    -e TEX_MAIN="proposal.tex" `
    liuming9124/latex-docker
```

### 2.1 Watch編譯
```powershell
docker run --rm `
  -v "$PWD:/work" `
  -e TEX_MAIN="proposal.tex" `
  -e TEX_WATCH=1 `
  liuming9124/latex-docker
```

### 2.2 加入windows字型 (Watch 編譯)
```powershell
docker run --rm `
   -v "${PWD}:/work" `
   -v "C:/Windows/Fonts/consola.ttf:/usr/share/fonts/truetype/consolas/consola.ttf:ro" `
   -v "C:/Windows/Fonts/consolab.ttf:/usr/share/fonts/truetype/consolas/consolab.ttf:ro" `
   -v "C:/Windows/Fonts/consolai.ttf:/usr/share/fonts/truetype/consolas/consolai.ttf:ro" `
   -v "C:/Windows/Fonts/consolaz.ttf:/usr/share/fonts/truetype/consolas/consolaz.ttf:ro" `
   -e TEX_MAIN=proposal.tex `
   -e TEX_ENGINE=xe `
   -e TEX_WATCH=1 `
   latex-docker
```


### 3. 清除中間檔案（build/、aux、log）

```powershell
docker run --rm -v "${PWD}:/work" liuming9124/latex-docker bash -lc "latexmk -C"
```

---

## 使用 docker-compose

`docker-compose.yml` 範例：

```yaml
services:
  tex:
    image: liuming9124/latex-docker
    volumes:
      - .:/work
    environment:
      TEX_MAIN: "*.tex"
      TEX_ENGINE: auto
      TEX_WATCH: 0
```

執行：

```sh
# 預設為單次編譯模式
docker compose run --rm tex

# Watch編譯
docker compose run --rm tex bash -lc "TEX_WATCH=1 latexmk"
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


## 環境變數

| 變數名稱         | 說明                           | 預設值     |
| ------------ | ---------------------------- | ------- |
| `TEX_MAIN`   | 主 `.tex` 檔名（支援萬用字元）          | `*.tex` |
| `TEX_ENGINE` | 編譯引擎：`auto`、`pdf`、`xe`、`lua` | `auto`  |
| `TEX_WATCH`  | 1=持續監看模式，0=單次編譯              | `0`     |

---

## 推薦用途

* 學位論文與學術文章撰寫
* 研究計畫書編譯
* 雲端 LaTeX 編譯與 CI/CD 流程整合

---
