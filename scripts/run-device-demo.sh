#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
device_ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)

if [ -z "$device_ip" ]; then
  echo "Could not detect this Mac's Wi-Fi address. Connect the Mac and phone to the same network."
  exit 1
fi

echo "Starting Tickerless for a phone at http://${device_ip}:8080"
echo "Keep the API running with TICKERLESS_API_HOST=0.0.0.0."
cd "$project_root/apps/mobile"
exec flutter run --dart-define="TICKERLESS_API_URL=http://${device_ip}:8080" "$@"
