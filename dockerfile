# latex-docker (合併穩定版，單一 Dockerfile 內嵌腳本)
# 同一映像支援：
# - proposal：pdfLaTeX + CJKutf8
# - thesis：XeLaTeX + xeCJK
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

# 允許用環境變數覆寫主檔與引擎
ENV TEX_MAIN="*.tex" \
    TEX_ENGINE="auto"

# 以 printf 產生 /usr/local/bin/texbuild（避免 heredoc 與 CRLF 問題）
RUN bash -lc 'printf "%s\n" \
"#!/usr/bin/env bash" \
"set -euo pipefail" \
"shopt -s nullglob" \
"" \
": \"\${TEX_MAIN:=*.tex}\"" \
": \"\${TEX_ENGINE:=auto}\"" \
"" \
"files=( \$TEX_MAIN )" \
"if [ \${#files[@]} -eq 0 ]; then" \
"  echo \"[texbuild] No .tex found\"" \
"  exit 1" \
"fi" \
"main=\"\${files[0]}\"" \
"echo \"[texbuild] main: \$main\"" \
"" \
"engine=\"\$TEX_ENGINE\"" \
"if [ \"\$engine\" = \"auto\" ]; then" \
"  # 若任何 .tex 有 [pdftex] hyperref 或主檔含 CJKutf8，優先用 pdfLaTeX" \
"  if grep -Rqi '\\\\usepackage\\[[^]]*pdftex[^]]*\\]{hyperref}' .; then" \
"    engine=\"pdf\"" \
"  fi" \
"  if [ \"\$engine\" = \"auto\" ] && grep -qi '\\\\usepackage{CJKutf8}' \"\$main\"; then" \
"    engine=\"pdf\"" \
"  fi" \
"  # 其他則用 XeLaTeX" \
"  if [ \"\$engine\" = \"auto\" ]; then" \
"    engine=\"xelatex\"" \
"  fi" \
"fi" \
"echo \"[texbuild] engine: \$engine\"" \
"" \
"if [ \"\$engine\" = \"pdf\" ]; then" \
"  latexmk -pdf -synctex=1 -halt-on-error -interaction=nonstopmode \"\$main\"" \
"elif [ \"\$engine\" = \"xelatex\" ]; then" \
"  latexmk -xelatex -synctex=1 -halt-on-error -interaction=nonstopmode \"\$main\"" \
"else" \
"  echo \"[texbuild] Unknown TEX_ENGINE: \$engine\"" \
"  exit 2" \
"fi" \
> /usr/local/bin/texbuild && perl -pi -e \"s/\\r$//\" /usr/local/bin/texbuild && chmod +x /usr/local/bin/texbuild'

# 預設：自動判斷引擎
CMD ["bash", "-lc", "texbuild"]
