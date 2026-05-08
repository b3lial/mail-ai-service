FROM python:3.12-slim

ARG VERSION=dev
LABEL version="${VERSION}"
LABEL description="Mail AI Service – automated email sorting via LLM agent"

WORKDIR /app

# Install dependencies for both services in one layer
COPY mail-proxy/requirements.txt /tmp/requirements-proxy.txt
COPY mail-agent/requirements.txt  /tmp/requirements-agent.txt
RUN pip install --no-cache-dir \
        -r /tmp/requirements-proxy.txt \
        -r /tmp/requirements-agent.txt

# Copy application code
COPY mail-proxy/ /app/mail-proxy/
COPY mail-agent/ /app/mail-agent/

# Record build version
RUN mkdir -p /etc/mail-ai-service && echo "${VERSION}" > /etc/mail-ai-service/version

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Default paths for mounted config files
ENV MAIL_PROXY_CONFIG=/etc/mail-proxy/config.yaml
ENV MAIL_AGENT_CONFIG=/etc/mail-agent/config.yaml

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
