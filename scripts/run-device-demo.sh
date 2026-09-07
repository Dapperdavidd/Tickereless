#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
device_ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)

if [ -z "$device_ip" ]; then
  device_ip=$(ifconfig 2>/dev/null | awk '/inet 192\.168\.|inet 10\.|inet 172\.(1[6-9]|2[0-9]|3[01])\./ { print $2; exit }')
fi

if [ -z "$device_ip" ]; then
  echo "Could not detect this Mac's Wi-Fi address. Connect the Mac and phone to the same network."
  exit 1
fi

echo "Starting Tickerless for a phone at http://${device_ip}:8080"
cd "$project_root"

if ! pg_isready -h 127.0.0.1 -p 5432 >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1 && brew services list | grep -q '^postgresql@16'; then
    brew services restart postgresql@16
  else
    docker compose up -d postgres
  fi
fi

api_pid=""
if ! curl --silent --fail --max-time 1 http://127.0.0.1:8080/health >/dev/null 2>&1; then
  echo "Starting the Tickerless API..."
  TICKERLESS_API_HOST=0.0.0.0 cargo run -p tickerless-api --bin tickerless-api &
  api_pid=$!
fi

cleanup() {
  if [ -n "$api_pid" ]; then
    kill "$api_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

attempt=0
until curl --silent --fail --max-time 1 http://127.0.0.1:8080/ready >/dev/null 2>&1; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 60 ]; then
    echo "The API did not become ready. Check the error above."
    exit 1
  fi
  sleep 1
done

echo "API ready. Launching the mobile app..."
cd "$project_root/apps/mobile"
flutter run --dart-define="TICKERLESS_API_URL=http://${device_ip}:8080" "$@"
