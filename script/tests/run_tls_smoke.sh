#!/bin/bash
# A local, mutually authenticated DICOM TLS check using disposable credentials.
set -euo pipefail
cd "$(dirname "$0")/../.."
BUILD_DATA="${BUILD_DATA:-DerivedData}"
LIBROOT="$PWD/$BUILD_DATA/Build/Intermediates.noindex/Unsething.build/Debug"
TEST_DIR="$(mktemp -d /tmp/unsething-tls.XXXXXX)"
SERVER_PID=''
trap 'if [[ -n "$SERVER_PID" ]]; then kill "$SERVER_PID" 2>/dev/null || true; wait "$SERVER_PID" 2>/dev/null || true; fi; rm -rf "$TEST_DIR"' EXIT
"$LIBROOT/OpenSSL.build/Install/bin/openssl" req -x509 -newkey rsa:2048 -noenc -subj /CN=Unsething-Library-Test -days 1 -keyout "$TEST_DIR/key.pem" -out "$TEST_DIR/cert.pem" > "$TEST_DIR/cert.log" 2>&1
PORT=$(python3 - <<'PY'
import socket
with socket.socket() as s:
    s.bind(('127.0.0.1',0));print(s.getsockname()[1])
PY
)
"$LIBROOT/DCMTK.build/Install/bin/storescp" +tls "$TEST_DIR/key.pem" "$TEST_DIR/cert.pem" -pw +cf "$TEST_DIR/cert.pem" -rc -od "$TEST_DIR" "$PORT" > "$TEST_DIR/server.log" 2>&1 &
SERVER_PID=$!
python3 - "$PORT" <<'PY'
import socket,sys,time
for i in range(50):
    try:
        with socket.create_connection(('127.0.0.1',int(sys.argv[1])),timeout=.2): break
    except OSError: time.sleep(.1)
else: raise SystemExit('TLS test server did not start')
PY
if ! "$LIBROOT/DCMTK.build/Install/bin/echoscu" -v +tls "$TEST_DIR/key.pem" "$TEST_DIR/cert.pem" -pw +cf "$TEST_DIR/cert.pem" -rc 127.0.0.1 "$PORT"; then
    cat "$TEST_DIR/server.log"; exit 1
fi
printf 'PASS DCMTK 3.7 / OpenSSL 4 mutually authenticated DICOM TLS echo\n'
