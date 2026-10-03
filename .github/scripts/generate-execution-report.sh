#!/usr/bin/env bash
set -euo pipefail

report_directory="${1:-target/ci-reports}"
source_root="${2:-src/main/java}"
mobile_number="${MOBILE_NUMBER:-9876543210}"
email_id="${EMAIL_ID:-student@example.com}"

report_file="$report_directory/execution-report.html"
output_file="$report_directory/program-output.txt"
main_pattern='public[[:space:]]+static[[:space:]]+void[[:space:]]+main[[:space:]]*\('

mkdir -p "$report_directory"
SECONDS=0
run_timestamp="$(date -u +"%Y-%m-%d %H:%M:%S UTC")"

cat > "$report_file" <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>JavaLearning — Daily Execution Report</title>
  <style>
    :root {
      --bg: #0f172a;
      --panel: #1e293b;
      --panel-border: #334155;
      --text: #e2e8f0;
      --muted: #94a3b8;
      --accent: #38bdf8;
      --pass: #4ade80;
      --fail: #f87171;
      --warn: #fbbf24;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: "Segoe UI", system-ui, -apple-system, sans-serif;
      background: linear-gradient(160deg, #020617 0%, #0f172a 45%, #1e1b4b 100%);
      color: var(--text);
      min-height: 100vh;
      padding: 2rem 1.25rem 3rem;
    }
    .wrap { max-width: 1200px; margin: 0 auto; }
    header {
      background: linear-gradient(135deg, rgba(56, 189, 248, 0.15), rgba(129, 140, 248, 0.12));
      border: 1px solid var(--panel-border);
      border-radius: 16px;
      padding: 1.75rem 2rem;
      margin-bottom: 1.5rem;
      box-shadow: 0 20px 50px rgba(0, 0, 0, 0.35);
    }
    h1 { margin: 0 0 0.35rem; font-size: 1.85rem; letter-spacing: -0.02em; }
    .subtitle { color: var(--muted); margin: 0; font-size: 0.95rem; }
    .cards {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
      gap: 1rem;
      margin-bottom: 1.5rem;
    }
    .card {
      background: var(--panel);
      border: 1px solid var(--panel-border);
      border-radius: 12px;
      padding: 1rem 1.15rem;
    }
    .card .label { color: var(--muted); font-size: 0.8rem; text-transform: uppercase; letter-spacing: 0.06em; }
    .card .value { font-size: 1.75rem; font-weight: 700; margin-top: 0.35rem; }
    .card.total .value { color: var(--accent); }
    .card.pass .value { color: var(--pass); }
    .card.fail .value { color: var(--fail); }
    .card.timeout .value { color: var(--warn); }
    .table-panel {
      background: var(--panel);
      border: 1px solid var(--panel-border);
      border-radius: 16px;
      overflow: hidden;
      box-shadow: 0 12px 40px rgba(0, 0, 0, 0.25);
    }
    table { width: 100%; border-collapse: collapse; font-size: 0.88rem; }
    thead th {
      position: sticky;
      top: 0;
      background: #0b1220;
      color: var(--muted);
      text-align: left;
      padding: 0.85rem 1rem;
      border-bottom: 1px solid var(--panel-border);
      font-weight: 600;
      text-transform: uppercase;
      font-size: 0.72rem;
      letter-spacing: 0.05em;
    }
    tbody td {
      padding: 0.75rem 1rem;
      border-bottom: 1px solid rgba(51, 65, 85, 0.6);
      vertical-align: top;
    }
    tbody tr:hover { background: rgba(56, 189, 248, 0.06); }
    pre {
      margin: 0;
      white-space: pre-wrap;
      word-break: break-word;
      max-height: 8rem;
      overflow: auto;
      font-size: 0.78rem;
      color: #cbd5e1;
      background: #0b1220;
      padding: 0.5rem 0.65rem;
      border-radius: 8px;
      border: 1px solid #1e293b;
    }
    .badge {
      display: inline-block;
      padding: 0.2rem 0.55rem;
      border-radius: 999px;
      font-size: 0.72rem;
      font-weight: 700;
      letter-spacing: 0.04em;
    }
    .badge.pass { background: rgba(74, 222, 128, 0.15); color: var(--pass); }
    .badge.fail { background: rgba(248, 113, 113, 0.15); color: var(--fail); }
    .badge.timeout { background: rgba(251, 191, 36, 0.15); color: var(--warn); }
    .mono { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 0.82rem; }
    footer { margin-top: 1.25rem; color: var(--muted); font-size: 0.85rem; text-align: center; }
  </style>
</head>
<body>
  <div class="wrap">
    <header>
      <h1>JavaLearning Daily Execution Report</h1>
      <p class="subtitle">Automated run of every <code>main</code> method in the demo module</p>
    </header>
    <div class="cards" id="summary-cards">
      <div class="card total"><div class="label">Programs run</div><div class="value" id="stat-total">—</div></div>
      <div class="card pass"><div class="label">Passed</div><div class="value" id="stat-pass">—</div></div>
      <div class="card fail"><div class="label">Failed</div><div class="value" id="stat-fail">—</div></div>
      <div class="card timeout"><div class="label">Timed out</div><div class="value" id="stat-timeout">—</div></div>
    </div>
    <div class="table-panel">
      <table>
        <thead>
          <tr>
            <th>Folder</th>
            <th>Program</th>
            <th>Arguments</th>
            <th>Output</th>
            <th>Exit</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
HTML

program_count=0
passed_count=0
failed_count=0
timed_out_count=0
programs_run_with_arguments=()

html_escape() {
  printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g'
}

run_program() {
  folder="$1"
  program="$2"
  arguments="$3"

  if [ -n "$arguments" ]; then
    programs_run_with_arguments+=("$program")
  fi

  set +e
  timeout --kill-after=2s 5s java -cp target/classes "$program" $arguments > "$output_file" 2>&1
  exit_code=$?
  set -e
  output=$(head -c 20000 "$output_file")

  if [ "$exit_code" -eq 0 ]; then
    status="PASSED"
    badge_class="pass"
    passed_count=$((passed_count + 1))
  elif [ "$exit_code" -eq 124 ] || [ "$exit_code" -eq 137 ]; then
    status="TIMED OUT"
    badge_class="timeout"
    timed_out_count=$((timed_out_count + 1))
  else
    status="FAILED"
    badge_class="fail"
    failed_count=$((failed_count + 1))
  fi

  printf '<tr><td>%s</td><td class="mono">%s</td><td class="mono">%s</td><td><pre>%s</pre></td><td>%s</td><td><span class="badge %s">%s</span></td></tr>\n' \
    "$(html_escape "$folder")" "$(html_escape "$program")" "$(html_escape "$arguments")" \
    "$(html_escape "$output")" "$exit_code" "$badge_class" "$status" >> "$report_file"
  echo "[$status] $folder > $program (exit: $exit_code)"
  program_count=$((program_count + 1))
}

run_program "regularExpressions" "com.regularExpressions.checkNumber" "mobile $mobile_number"
run_program "regularExpressions" "com.regularExpressions.checkNumber" "email $email_id"

has_main_method() {
  grep -q -E "$main_pattern" "$1"
}

was_run_with_arguments() {
  for configured_program in "${programs_run_with_arguments[@]}"; do
    [ "$configured_program" = "$1" ] && return 0
  done
  return 1
}

while IFS= read -r -d '' source_file; do
  has_main_method "$source_file" || continue
  class_name=${source_file#"$source_root"/}
  class_name=${class_name%.java}
  class_name=${class_name//\//.}
  was_run_with_arguments "$class_name" && continue
  if [[ "$source_file" == *"/com/"* ]]; then
    relative_path=${source_file#*"/com/"}
    folder=${relative_path%%/*}
  elif [[ "$source_file" == *"/interview/"* ]]; then
    folder="interview"
  else
    folder="other"
  fi
  run_program "$folder" "$class_name" ""
done < <(find "$source_root" -name '*.java' -print0 | sort -z)

total_duration_seconds=$SECONDS

cat >> "$report_file" <<HTML
        </tbody>
      </table>
    </div>
    <footer>
      Generated at ${run_timestamp} · ${program_count} programs in ${total_duration_seconds}s
      (passed: ${passed_count}, failed: ${failed_count}, timed out: ${timed_out_count})
    </footer>
  </div>
  <script>
    document.getElementById('stat-total').textContent = '${program_count}';
    document.getElementById('stat-pass').textContent = '${passed_count}';
    document.getElementById('stat-fail').textContent = '${failed_count}';
    document.getElementById('stat-timeout').textContent = '${timed_out_count}';
  </script>
</body>
</html>
HTML

echo "Executed $program_count programs in $total_duration_seconds seconds."
echo "HTML report: $report_file"
