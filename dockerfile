# syntax=docker/dockerfile:1.4
FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8

SHELL ["/bin/bash", "-c"]

# 1) APT sources：加入 contrib/non-free
RUN set -eux; \
  if [ -f /etc/apt/sources.list ]; then \
    sed -i 's/ main/ main contrib non-free non-free-firmware/g' /etc/apt/sources.list; \
  elif [ -f /etc/apt/sources.list.d/debian.sources ]; then \
    sed -i -E 's/^Components: .*/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources; \
  else \
    echo "Types: deb" > /etc/apt/sources.list.d/debian.sources; \
    echo "URIs: http://deb.debian.org/debian" >> /etc/apt/sources.list.d/debian.sources; \
    echo "Suites: stable stable-updates" >> /etc/apt/sources.list.d/debian.sources; \
    echo "Components: main contrib non-free non-free-firmware" >> /etc/apt/sources.list.d/debian.sources; \
    echo "Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg" >> /etc/apt/sources.list.d/debian.sources; \
    echo "" >> /etc/apt/sources.list.d/debian.sources; \
    echo "Types: deb" >> /etc/apt/sources.list.d/debian.sources; \
    echo "URIs: http://security.debian.org/debian-security" >> /etc/apt/sources.list.d/debian.sources; \
    echo "Suites: stable-security" >> /etc/apt/sources.list.d/debian.sources; \
    echo "Components: main contrib non-free non-free-firmware" >> /etc/apt/sources.list.d/debian.sources; \
    echo "Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg" >> /etc/apt/sources.list.d/debian.sources; \
  fi

# 2) 安裝 TeX Live + 字型
RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    ca-certificates make perl bash grep sed \
    latexmk texlive-full ghostscript \
    fontconfig fonts-texgyre fonts-dejavu \
    fonts-noto-cjk fonts-noto-cjk-extra \
    fonts-arphic-uming fonts-arphic-ukai \
    fonts-arphic-bkai00mp fonts-arphic-bsmi00lp \
    cabextract xfonts-utils; \
  echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections; \
  apt-get install -y --no-install-recommends ttf-mscorefonts-installer || true

# 3) 字型替代：Consolas → DejaVu Sans Mono（若未掛入 Windows 字型時）
RUN mkdir -p /etc/fonts/conf.d && cat > /etc/fonts/conf.d/60-override-substitutions.conf <<'XML'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="pattern">
    <test name="family" compare="eq"><string>Consolas</string></test>
    <edit name="family" mode="assign" binding="strong"><string>DejaVu Sans Mono</string></edit>
  </match>
</fontconfig>
XML

# 4) Fandol → Noto Serif CJK TC 的符號連結（避免缺字）
RUN set -eux; \
  fandol_dir="$(fc-list | grep -i 'FandolSong' | head -n1 | xargs dirname || true)"; \
  if [ -n "$fandol_dir" ] && [ -d "$fandol_dir" ]; then \
    noto_path="$(fc-list | grep -i 'NotoSerifCJKtc-Regular.otf' | head -n1 || true)"; \
    noto_bold_path="$(fc-list | grep -i 'NotoSerifCJKtc-Bold.otf' | head -n1 || true)"; \
    if [ -n "$noto_path" ] && [ -n "$noto_bold_path" ]; then \
      rm -f "$fandol_dir"/FandolSong-Regular.otf "$fandol_dir"/FandolSong-Bold.otf || true; \
      ln -s "$noto_path"      "$fandol_dir/FandolSong-Regular.otf"; \
      ln -s "$noto_bold_path" "$fandol_dir/FandolSong-Bold.otf"; \
    fi; \
  fi

# 5) 覆蓋 ctex 預設字型（改用 Noto CJK TC）
RUN mkdir -p /usr/local/texlive/texmf-local/tex/latex/ctex/fontset && \
    printf "%s\n" \
      "\\ProvidesFile{ctex-fontset-default.def}" \
      "\\setCJKmainfont{Noto Serif CJK TC}" \
      "\\setCJKsansfont{Noto Sans CJK TC}" \
      "\\setCJKmonofont{Noto Sans Mono CJK TC}" \
      > /usr/local/texlive/texmf-local/tex/latex/ctex/fontset/ctex-fontset-default.def && \
    mktexlsr && fc-cache -f

# 6) 全域 latexmkrc（集中輸出 build、recorder、bib 自動）
RUN <<'RC'
cat > /etc/latexmkrc <<'EOF'
$pdf_mode = 1;          # 預設 PDF
$recorder = 1;          # 產生 .fls 追蹤相依
$aux_dir = "build";     # 中介輸出集中到 build
$out_dir = "build";     # 最終輸出集中到 build
$bibtex_use = 2;        # 自動跑 biber/bibtex

# 保險：所有引擎都啟用 -recorder
$pdflatex = "pdflatex -interaction=nonstopmode -file-line-error -recorder %O %S";
$xelatex  = "xelatex  -interaction=nonstopmode -file-line-error -recorder %O %S";
$lualatex = "lualatex -interaction=nonstopmode -file-line-error -recorder %O %S";
EOF
RC

# 7) texbuild 腳本
#    - 支援 TEX_MAIN 萬用字元（取第一個匹配）
#    - 自動判斷引擎（優先 ctex→xe；有 CJKutf8 或 [pdftex]hyperref→pdf；否則 xe）
#    - 第一次編譯自動加 -gg
#    - TEX_WATCH=1 啟用 -pvc
RUN bash -lc 'printf "%s\n" \
"#!/usr/bin/env bash" \
"set -euo pipefail" \
"shopt -s nullglob" \
"" \
": \"\${TEX_MAIN:=*.tex}\"" \
": \"\${TEX_ENGINE:=auto}\"" \
": \"\${TEX_WATCH:=0}\"" \
"" \
"# 展開萬用字元，取第一個檔案作為 main" \
"files=( \$TEX_MAIN )" \
"if [ \${#files[@]} -eq 0 ]; then" \
"  echo \"[texbuild] ERROR: No tex matched: \$TEX_MAIN\"; exit 2" \
"fi" \
"main=\"\${files[0]}\"" \
"if [ ! -f \"\$main\" ]; then" \
"  echo \"[texbuild] ERROR: File not found: \$main\"; exit 2" \
"fi" \
"" \
"pick_engine() {" \
"  # 只要專案中有 ctex 類別/套件，強制 xe" \
"  if grep -RqiE \"\\\\\\documentclass.*{ctex}|\\\\\\usepackage.*{ctex}\" .; then echo xe; return; fi" \
"  # 有 CJKutf8 或 hyperref 的 [pdftex] 設定 → pdfLaTeX" \
"  if grep -RqiE \"\\\\\\usepackage{CJKutf8}|\\\\\\[.*pdftex.*\\\\\\]{hyperref}\" .; then echo pdf; return; fi" \
"  # 否則預設 xe" \
"  echo xe" \
"}" \
"" \
"engine=\"\$TEX_ENGINE\"" \
"if [ \"\$engine\" = \"auto\" ]; then" \
"  engine=\"\$(pick_engine)\"" \
"fi" \
"" \
"case \"\$engine\" in" \
"  pdf) latexmk_engine=\"-pdf\" ;;" \
"  xe)  latexmk_engine=\"-xelatex\" ;;" \
"  lua) latexmk_engine=\"-lualatex\" ;;" \
"  *) echo \"[texbuild] ERROR: TEX_ENGINE must be pdf|xe|lua|auto\"; exit 2 ;;" \
"esac" \
"" \
"echo \"[texbuild] main:   \$main\"" \
"echo \"[texbuild] engine: \$engine\"" \
"" \
"args=( -synctex=1 -halt-on-error -interaction=nonstopmode )" \
"# 第一次編譯（沒有 fdb_latexmk）→ -gg" \
"fdb=\"build/\${main%.tex}.fdb_latexmk\"" \
"if [ ! -f \"\$fdb\" ]; then" \
"  echo \"[texbuild] First compile: enabling -gg\"" \
"  args+=( -gg )" \
"fi" \
"" \
"# watch 模式" \
"if [ \"\${TEX_WATCH:-0}\" = \"1\" ]; then args+=( -pvc ); fi" \
"" \
"latexmk \"\${latexmk_engine}\" \"\${args[@]}\" \"\$main\"" \
> /usr/local/bin/texbuild && chmod +x /usr/local/bin/texbuild'

# 8) 清理
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/texbuild"]
