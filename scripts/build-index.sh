#!/usr/bin/env bash
# Generates index.html: a browsable listing of every file in the repo.
# Excludes git/CI plumbing and the generated index itself.
set -euo pipefail
export LC_ALL=C

OUT="index.html"
NOW="$(date -u '+%Y-%m-%d %H:%M UTC')"

# Collect tracked-worthy files (skip .git, .github, scripts, index.html, dotfiles).
FILES=()
while IFS= read -r line; do
  FILES+=("$line")
done < <(
  find . -type f \
    -not -path './.git/*' \
    -not -path './.github/*' \
    -not -path './scripts/*' \
    -not -name '.*' \
    -not -name 'index.html' \
    | sed 's|^\./||' \
    | sort
)

rows=""
for f in "${FILES[@]}"; do
  bytes=$(wc -c < "$f" | tr -d ' ')
  if   [ "$bytes" -ge 1048576 ]; then size="$(awk "BEGIN{printf \"%.1f MB\", $bytes/1048576}")"
  elif [ "$bytes" -ge 1024 ];    then size="$(awk "BEGIN{printf \"%.1f KB\", $bytes/1024}")"
  else size="${bytes} B"; fi
  ext="${f##*.}"; [ "$ext" = "$f" ] && ext="—"
  # URL-encode spaces for the href.
  href="${f// /%20}"
  rows+="      <li><a href=\"./${href}\"><span class=\"name\">${f}</span><span class=\"ext\">${ext}</span><span class=\"size\">${size}</span></a></li>\n"
done

count="${#FILES[@]}"
[ "$count" = "1" ] && noun="file" || noun="files"

cat > "$OUT" <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>randomdocs</title>
<style>
  :root { color-scheme: dark; }
  * { box-sizing: border-box; }
  body {
    margin: 0; padding: 48px 20px; min-height: 100vh;
    font: 16px/1.5 ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
    background: #0b0f17; color: #e6edf3;
    display: flex; justify-content: center;
  }
  .wrap { width: 100%; max-width: 760px; }
  header { margin-bottom: 28px; }
  .eyebrow { text-transform: uppercase; letter-spacing: .12em; font-size: 12px; color: #6b7689; }
  h1 { margin: 6px 0 4px; font-size: 28px; }
  .sub { color: #8b95a7; font-size: 14px; }
  ul { list-style: none; margin: 0; padding: 0; border: 1px solid #1c2433; border-radius: 12px; overflow: hidden; }
  li + li { border-top: 1px solid #1c2433; }
  a {
    display: grid; grid-template-columns: 1fr auto auto; gap: 16px; align-items: center;
    padding: 14px 18px; text-decoration: none; color: #e6edf3; transition: background .12s;
  }
  a:hover { background: #131a26; }
  .name { font-weight: 600; word-break: break-all; }
  .ext { font-size: 12px; color: #7d8aa3; text-transform: uppercase; letter-spacing: .04em; }
  .size { font-size: 13px; color: #6b7689; font-variant-numeric: tabular-nums; min-width: 72px; text-align: right; }
  .empty { padding: 40px; text-align: center; color: #6b7689; border: 1px dashed #1c2433; border-radius: 12px; }
  footer { margin-top: 24px; font-size: 12px; color: #5a6478; }
</style>
</head>
<body>
  <div class="wrap">
    <header>
      <div class="eyebrow">Index</div>
      <h1>randomdocs</h1>
      <div class="sub">${count} ${noun}</div>
    </header>
HTML

if [ "$count" -eq 0 ]; then
  printf '    <div class="empty">No files yet.</div>\n' >> "$OUT"
else
  printf '    <ul>\n' >> "$OUT"
  printf "%b" "$rows" >> "$OUT"
  printf '    </ul>\n' >> "$OUT"
fi

cat >> "$OUT" <<HTML
    <footer>Auto-generated ${NOW}</footer>
  </div>
</body>
</html>
HTML

echo "Wrote $OUT with $count $noun."
