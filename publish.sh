#!/usr/bin/env bash
set -euo pipefail

CSV_FILE="recetas.csv"
AUTH_TOKEN="${AUTH_TOKEN:-}"

if [[ -z "$AUTH_TOKEN" ]]; then
  echo "Error: La variable de entorno AUTH_TOKEN no está definida." >&2
  exit 1
fi

if [[ ! -f "$CSV_FILE" ]]; then
  echo "Error: El archivo $CSV_FILE no existe." >&2
  exit 1
fi

mapfile -t lines < <(grep -v '^[[:space:]]*$' "$CSV_FILE")
total_lines=${#lines[@]}

if [[ $total_lines -eq 0 ]]; then
  echo "Error: El archivo CSV está vacío." >&2
  exit 1
fi

if [[ -n "${SRANDOM:-}" ]]; then
  random_index=$(( SRANDOM % total_lines ))
else
  random_index=$(( RANDOM % total_lines ))
fi

selected_line="${lines[$random_index]}"

IFS=',' read -r -a fields <<< "$selected_line"

payload="Mañana toca ${fields[0]:-}

Recuerda comprar:"

for i in {1..4}; do
  if [[ -n "${fields[$i]:-}" ]]; then
    payload+=$'\n'"- ${fields[$i]}"
  fi
done

payload+=$"\n\n(toot generado por un boot en pruebas. #LoQueTocaToca )"

json_escaped_text="${payload//\"/\\\"}"
json_escaped_text="${json_escaped_text//$'\n'/\\n}"
json_payload="{\"status\": \"${json_escaped_text}\"}"

curl -s -X POST "$INSTANCE/api/v1/statuses" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d "$json_payload"
