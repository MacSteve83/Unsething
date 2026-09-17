#!/bin/zsh
set -euo pipefail

DOMAIN="${1:-com.unsething.viewer}"
TMP_IN="$(mktemp /tmp/unsething-prefs-in.XXXXXX.plist)"
TMP_OUT="$(mktemp /tmp/unsething-prefs-out.XXXXXX.plist)"

cleanup() {
    rm -f "$TMP_IN" "$TMP_OUT"
}
trap cleanup EXIT

echo "Riparo le preferenze DICOM per $DOMAIN..."

if ! defaults export "$DOMAIN" "$TMP_IN" >/dev/null 2>&1; then
    PREF="$HOME/Library/Preferences/$DOMAIN.plist"
    if [[ -f "$PREF" ]]; then
        cp "$PREF" "$TMP_IN"
    else
        echo "Preferenze non trovate per $DOMAIN."
        echo "Apri Unsething una volta, chiudilo, poi rilancia questo script."
        exit 1
    fi
fi

python3 - "$TMP_IN" "$TMP_OUT" <<'PY'
import plistlib
import sys

source, dest = sys.argv[1], sys.argv[2]

with open(source, "rb") as f:
    prefs = plistlib.load(f)

changed = 0

def is_loopback(value):
    if not isinstance(value, str):
        return False
    clean = value.strip().lower()
    return clean.startswith("127.") or clean in {"localhost", "::1"} or clean.startswith("[::1]")

def usable(value):
    return isinstance(value, str) and value.strip() and not is_loopback(value)

def copy_localized_key(node, localized, canonical):
    global changed
    if not isinstance(node, dict) or localized not in node:
        return
    local_value = node.get(localized)
    current = node.get(canonical)
    if canonical == "Address":
        if usable(local_value) and (not isinstance(current, str) or not current.strip() or is_loopback(current)):
            node[canonical] = local_value
            changed += 1
    elif canonical not in node:
        node[canonical] = local_value
        changed += 1

def normalize_server(node):
    global changed
    if not isinstance(node, dict):
        return

    copy_localized_key(node, "Indirizzo", "Address")
    copy_localized_key(node, "Descrizione", "Description")
    copy_localized_key(node, "Porta", "Port")
    copy_localized_key(node, "Invia", "Send")
    copy_localized_key(node, "Attivo", "Activated")

    nested = node.get("server")
    if isinstance(nested, dict):
        normalize_server(nested)
        address = nested.get("Address") or node.get("Address")
        port = nested.get("Port") or node.get("Port")
    else:
        address = node.get("Address")
        port = node.get("Port")

    if isinstance(address, str) and str(port or "").strip() and "AddressAndPort" in node:
        wanted = f"{address}:{port}"
        if node.get("AddressAndPort") != wanted:
            node["AddressAndPort"] = wanted
            changed += 1

def normalize_array(key):
    value = prefs.get(key)
    if not isinstance(value, list):
        return
    for item in value:
        normalize_server(item)

for key in ("SERVERS", "OSIRIXSERVERS", "SavedQueryArray", "SavedQueryArrayAuto"):
    normalize_array(key)

with open(dest, "wb") as f:
    plistlib.dump(prefs, f, sort_keys=False)

PY

CHANGED="$(python3 - "$TMP_IN" "$TMP_OUT" <<'PY'
import plistlib, sys
with open(sys.argv[1], "rb") as f:
    before = plistlib.load(f)
with open(sys.argv[2], "rb") as f:
    after = plistlib.load(f)
print("1" if before != after else "0")
PY
)"

if [[ "$CHANGED" == "1" ]]; then
    defaults import "$DOMAIN" "$TMP_OUT"
    killall cfprefsd >/dev/null 2>&1 || true
    echo "Preferenze DICOM riparate. Ora chiudi e riapri Unsething."
else
    echo "Nessuna preferenza da correggere."
fi
