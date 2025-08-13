# syntax=docker/dockerfile:1.4

FROM debian:stable-slim
ENV DEBIAN_FRONTEND=noninteractive

# 基本工具 + latexmk + TeX Live full
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates make perl bash grep sed \
    latexmk texlive-full ghostscript \
    # 常用中文字型：思源 & Arphic（解 C70/bkai、C70/bsmi）
    fonts-noto-cjk \
    fonts-arphic-bkai00mp fonts-arphic-bsmi00lp \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /work

# 建立全域 latexmkrc，啟用 recorder 與集中輸出
RUN <<'RC'
cat > /etc/latexmkrc <<'EOF'
$pdf_mode = 1;          # 預設做 pdf
$recorder = 1;          # 產生 .fls 以追蹤相依
$aux_dir = "build";     # 中介輸出集中
$out_dir = "build";     # 最終輸出集中
$bibtex_use = 2;        # 自動跑 biber/bibtex

# 保險：每種引擎都加 recorder
$pdflatex = "pdflatex -interaction=nonstopmode -file-line-error -recorder %O %S";
$xelatex  = "xelatex  -interaction=nonstopmode -file-line-error -recorder %O %S";
$lualatex = "lualatex -interaction=nonstopmode -file-line-error -recorder %O %S";
EOF
RC

# 允許用環境變數覆寫主檔與引擎
ENV TEX_MAIN="*.tex" \
    TEX_ENGINE="auto" \
    TEX_WATCH=1

# 內嵌 texbuild 腳本
RUN bash -lc 'printf "%s\n" \
"#!/usr/bin/env bash" \
"set -euo pipefail" \
"shopt -s nullglob" \
"" \
": \"\${TEX_MAIN:=*.tex}\"" \
": \"\${TEX_ENGINE:=auto}\"" \
": \"\${TEX_WATCH:=0}\"" \
"" \
"files=( \$TEX_MAIN )" \
"if [ \${#files[@]} -eq 0 ]; then" \
"  echo \"[texbuild] No .tex found\"; exit 1" \
"fi" \
"main=\"\${files[0]}\"" \
"echo \"[texbuild] main: \$main\"" \
"" \
"engine=\"\$TEX_ENGINE\"" \
"if [ \"\$engine\" = \"auto\" ]; then" \
"  if grep -Rqi '\\\\usepackage\\[[^]]*pdftex[^]]*\\]{hyperref}' .; then engine=\"pdf\"; fi" \
"  if [ \"\$engine\" = \"auto\" ] && grep -qi '\\\\usepackage{CJKutf8}' \"\$main\"; then engine=\"pdf\"; fi" \
"  if [ \"\$engine\" = \"auto\" ]; then engine=\"xelatex\"; fi" \
"fi" \
"echo \"[texbuild] engine: \$engine\"" \
"" \
"args=( -synctex=1 -halt-on-error -interaction=nonstopmode )" \
"# 如果第一次編譯（沒有 .fdb_latexmk），加上 -gg 建立相依" \
"if [ ! -f \"build/\${main%.tex}.fdb_latexmk\" ]; then" \
"  echo \"[texbuild] First compile: enabling -gg\"" \
"  args+=( -gg )" \
"fi" \
"" \
"# 若啟用 TEX_WATCH，加入 -pvc" \
"if [ \"\$TEX_WATCH\" != \"0\" ]; then args+=( -pvc ); fi" \
"" \
"if [ \"\$engine\" = \"pdf\" ]; then" \
"  latexmk -pdf \"\${args[@]}\" \"\$main\"" \
"elif [ \"\$engine\" = \"xelatex\" ]; then" \
"  latexmk -xelatex \"\${args[@]}\" \"\$main\"" \
"else" \
"  echo \"[texbuild] Unknown TEX_ENGINE: \$engine\"; exit 2" \
"fi" \
> /usr/local/bin/texbuild && perl -pi -e \"s/\\r$//\" /usr/local/bin/texbuild && chmod +x /usr/local/bin/texbuild'

# 預設：自動判斷引擎
CMD ["bash", "-lc", "texbuild"]
