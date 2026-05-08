#!/bin/sh
set -e

# Start mail-proxy in the background
echo "Starting mail-proxy..."
cd /app/mail-proxy
python main.py --config "${MAIL_PROXY_CONFIG}" &
PROXY_PID=$!

# Wait for mail-proxy to accept connections (up to 30 s)
echo "Waiting for mail-proxy to become ready..."
RETRIES=30
while [ $RETRIES -gt 0 ]; do
    if python3 -c "
import socket, sys
s = socket.socket()
s.settimeout(1)
try:
    s.connect(('127.0.0.1', 8080))
    s.close()
    sys.exit(0)
except Exception:
    sys.exit(1)
" 2>/dev/null; then
        break
    fi
    if ! kill -0 $PROXY_PID 2>/dev/null; then
        echo "ERROR: mail-proxy exited unexpectedly" >&2
        exit 1
    fi
    RETRIES=$((RETRIES - 1))
    sleep 1
done

if [ $RETRIES -eq 0 ]; then
    echo "ERROR: mail-proxy did not start within 30 seconds" >&2
    kill $PROXY_PID 2>/dev/null || true
    exit 1
fi

echo "mail-proxy is ready"

# Start mail-agent in watch mode (becomes PID 1 via exec, receives Docker signals)
echo "Starting mail-agent..."
cd /app/mail-agent
exec python -m mail_agent.main --config "${MAIL_AGENT_CONFIG}" watch
