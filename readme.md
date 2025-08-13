# Latex on docker

```
以下指令主要適用於Powershell
```
## 1. 建置
```
docker compose build
```
- 根據 Dockerfile 建立名為 latex-docker:latest 的 image。
- 使用 docker-compose.yml 中的 tex 服務。

## 2. 強制重建（不使用快取）
```
docker compose build --no-cache
```
- 若套件版本異動或 Image 異常時，建議用此方式重建，確保完全重新安裝。

## 3. 執行

### 3.1 清除中間檔（aux, log, out...）
```powershell
docker compose run --rm -v "${PWD}:/work" tex `
  bash -lc "latexmk -C"
```
- 相當於 latexmk -C，刪除中間產物，乾淨編譯用。
- 適用於切換引擎或重編錯誤後清理狀態。

### 3.2 編譯 計畫(XeLaTeX)
```powershell
docker run --rm -e TEX_MAIN=proposal.tex -e TEX_ENGINE=xelatex -v "${PWD}:/work" latex-docker
```
- 使用 docker run 單獨呼叫已建好之 latex-docker image。
- 指定主檔為 proposal.tex，手動設引擎為 xelatex。

### 3.3 編輯 Thesis
```powershell
$FILE="thesis.tex"
docker compose run --rm -v "${PWD}:/work" tex `
  bash -lc "latexmk -pdf -g -f -synctex=1 -halt-on-error -interaction=nonstopmode $FILE"
```

## 建議的資料結構
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