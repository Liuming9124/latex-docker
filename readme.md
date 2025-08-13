# LaTeX on Docker

> 通用型 XeLaTeX / pdfLaTeX 編譯環境  
> 支援中文與論文格式，自動判斷編譯引擎，適合跨平台開發與 CI 使用

---

## 專案連結

- Docker Hub: [`liuming9124/latex-docker`](https://hub.docker.com/r/liuming9124/latex-docker)
- GitHub: [`Liuming9124/latex-docker`](https://github.com/Liuming9124/latex-docker)

---

## 支援編譯引擎

本映像支援以下 LaTeX 引擎：

- `pdfLaTeX`：預設處理大多數含中文的論文格式（如 `CJKutf8` 或 `[pdftex]hyperref`）
- `XeLaTeX`：適合自訂字體、直排與現代中文字排版（如使用 `xeCJK`, `fontspec`）

若未指定 `TEX_ENGINE`，會自動依 `.tex` 檔內容進行判斷。

---

## 使用方式（PowerShell 指令）

### 1. 建置 Docker Image（若使用本地 `dockerfile`）

```powershell
docker compose build
```

### 2. 強制重建（不使用快取）

```powershell
docker compose build --no-cache
```

---

## 編譯與清除指令

### 使用已發佈的公開Image（建議）

#### 清除中間檔（aux, log 等）

```powershell
docker run --rm -v "${PWD}:/work" liuming9124/latex-docker bash -lc "latexmk -C"
```

#### 編譯 Proposal（自動判斷引擎，預設為 pdfLaTeX）

```powershell
docker run --rm -e TEX_MAIN=proposal.tex -v "${PWD}:/work" liuming9124/latex-docker
```

#### 編譯 Thesis（預設為 pdfLaTeX）

```powershell
docker run --rm -e TEX_MAIN=thesis.tex -e TEX_ENGINE=pdf -v "${PWD}:/work" liuming9124/latex-docker
```

---

### 使用 docker compose（需本地有 `docker-compose.yml`）

#### 清除中間檔

```powershell
docker compose run --rm -v "${PWD}:/work" tex bash -lc "latexmk -C"
```

#### 編譯 Thesis（固定 pdfLaTeX）

```powershell
$FILE = "thesis.tex"
docker compose run --rm -v "${PWD}:/work" tex `
  bash -lc "latexmk -pdf -g -f -synctex=1 -halt-on-error -interaction=nonstopmode $FILE"
```

---

## 建議的專案結構

```plaintext
├── docker-compose.yml
├── Dockerfile
├── proposal.tex
├── thesis.tex
├── settings/
│   └── thesis.sty
└── figures/
    └── ...
```

---

## 特點與支援

* 自動判斷 pdfLaTeX 或 XeLaTeX（也可手動指定）
* 預裝中文字型（Noto 思源、Arphic 中華電信）
* latexmk 編譯與快取清除流程已整合
* 適合跨平台編譯與 CI/CD 自動化部署

---
