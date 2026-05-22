# Reverse Proxy

n8n serves plaintext HTTP on port 5678. In production, put a reverse proxy
in front to terminate TLS, route, and apply security headers.

> Authoritative reference: <https://docs.n8n.io/hosting/configuration/reverse-proxy/>

---

## Things to get right (universal)

1. **Forward the `Host` header** (or set it explicitly).
2. **Forward WebSockets** — n8n uses WS for editor live-collab and the chat
   trigger. Pass `Upgrade` and `Connection` headers.
3. **Allow large bodies** — webhooks can carry multi-MB payloads (uploads,
   detailed JSON). Default proxy limits often kick at 1 MB.
4. **Match `WEBHOOK_URL` to the proxied URL** — same domain, same path
   prefix.
5. **Set `N8N_PROTOCOL=https`** when terminating TLS at the proxy.

---

## nginx

```nginx
server {
    listen 443 ssl http2;
    server_name n8n.example.com;

    ssl_certificate     /etc/letsencrypt/live/n8n.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/n8n.example.com/privkey.pem;

    # Reasonable security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;

    # Allow large webhook bodies and editor uploads
    client_max_body_size 32m;

    # Timeouts — important for long-running webhooks
    proxy_read_timeout  3600s;
    proxy_send_timeout  3600s;

    location / {
        proxy_pass http://127.0.0.1:5678;

        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host  $host;

        # WebSockets (editor + chat)
        proxy_http_version 1.1;
        proxy_set_header Upgrade    $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

server {
    listen 80;
    server_name n8n.example.com;
    return 301 https://$server_name$request_uri;
}
```

In compose:

```yaml
services:
  n8n:
    environment:
      N8N_HOST: n8n.example.com
      N8N_PROTOCOL: https
      WEBHOOK_URL: https://n8n.example.com/
      N8N_PROXY_HOPS: 1                  # trust 1 reverse-proxy hop for X-Forwarded-*
    # NO 'ports:' — nginx connects via the Docker network or 127.0.0.1
```

---

## Traefik (v3, Docker labels)

```yaml
services:
  traefik:
    image: traefik:v3
    command:
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entryPoints.web.address=:80"
      - "--entryPoints.websecure.address=:443"
      - "--certificatesResolvers.le.acme.email=ops@example.com"
      - "--certificatesResolvers.le.acme.storage=/letsencrypt/acme.json"
      - "--certificatesResolvers.le.acme.tlschallenge=true"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - traefik_letsencrypt:/letsencrypt

  n8n:
    image: n8nio/n8n:1.78.0
    environment:
      N8N_HOST: n8n.example.com
      N8N_PROTOCOL: https
      WEBHOOK_URL: https://n8n.example.com/
      N8N_PROXY_HOPS: 1
      # ... other env
    labels:
      - "traefik.enable=true"

      - "traefik.http.routers.n8n.rule=Host(`n8n.example.com`)"
      - "traefik.http.routers.n8n.entrypoints=websecure"
      - "traefik.http.routers.n8n.tls.certresolver=le"
      - "traefik.http.services.n8n.loadbalancer.server.port=5678"

      # HTTP → HTTPS redirect
      - "traefik.http.routers.n8n-http.rule=Host(`n8n.example.com`)"
      - "traefik.http.routers.n8n-http.entrypoints=web"
      - "traefik.http.routers.n8n-http.middlewares=https-redirect"
      - "traefik.http.middlewares.https-redirect.redirectscheme.scheme=https"

      # Allow large bodies
      - "traefik.http.middlewares.n8n-bodysize.buffering.maxRequestBodyBytes=33554432"
      - "traefik.http.routers.n8n.middlewares=n8n-bodysize"

volumes:
  traefik_letsencrypt:
```

---

## Caddy (auto-TLS, simplest)

```caddy
# Caddyfile
n8n.example.com {
    reverse_proxy n8n:5678 {
        header_up Host              {host}
        header_up X-Real-IP         {remote_host}
        header_up X-Forwarded-For   {remote_host}
        header_up X-Forwarded-Proto {scheme}
    }
    request_body {
        max_size 32MB
    }
    encode gzip
}
```

In compose:

```yaml
services:
  caddy:
    image: caddy:2-alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config

  n8n:
    image: n8nio/n8n:1.78.0
    environment:
      N8N_HOST: n8n.example.com
      N8N_PROTOCOL: https
      WEBHOOK_URL: https://n8n.example.com/
      N8N_PROXY_HOPS: 1
      # ... other env

volumes:
  caddy_data:
  caddy_config:
```

Caddy handles certificate provisioning automatically via Let's Encrypt
(needs ports 80/443 reachable from the internet).

---

## Hosting at a sub-path

If you want `https://example.com/n8n/` instead of a subdomain:

```yaml
services:
  n8n:
    environment:
      N8N_HOST: example.com
      N8N_PATH: /n8n/                    # n8n knows it's at /n8n/
      WEBHOOK_URL: https://example.com/n8n/
      N8N_PROTOCOL: https
```

In nginx:

```nginx
location /n8n/ {
    proxy_pass http://127.0.0.1:5678/;   # trailing slash strips /n8n/ prefix
    # ... usual proxy headers + WS upgrade
}
```

Pitfall: the trailing `/` in `proxy_pass` matters. With it, nginx strips the
`/n8n/` prefix before forwarding (n8n sees `/` paths). Without it, n8n sees
`/n8n/...` paths and may 404.

---

## Cloudflare in front

Common pattern: Cloudflare proxies traffic to your origin (nginx/Caddy on
your VPS).

- Set Cloudflare SSL mode to **Full (strict)** — Cloudflare validates your
  origin cert.
- Cloudflare adds `CF-Connecting-IP` for the real client IP.
- Set `N8N_PROXY_HOPS=2` (Cloudflare + your local proxy = 2 hops).
- Disable Cloudflare's caching for `/webhook/*`, `/rest/*`, and any
  websocket paths.

---

## Reverse-proxy pitfalls

### 1. WebSocket connection failed in editor

Missing `Upgrade`/`Connection` headers in proxy config. Editor won't load
in some places (live updates broken).

### 2. Webhook returns 413 Payload Too Large

Body bigger than proxy's default limit. Bump `client_max_body_size`
(nginx) / `request_body max_size` (Caddy) / `buffering.maxRequestBodyBytes`
(Traefik).

### 3. Long-running webhook returns 504 Gateway Timeout

Proxy timed out before n8n responded. Bump `proxy_read_timeout` (nginx) and
consider switching the workflow to `responseMode: "onReceived"` (ack
immediately, work in background).

### 4. n8n logs show all clients with the same IP

Missing `X-Forwarded-For` header passthrough. Set as in examples.

### 5. Webhook URL in n8n UI shows wrong domain

`WEBHOOK_URL` env var wrong. Restart after fixing.

### 6. HTTPS warnings in browser

n8n cookies marked `Secure` (default). If accessed via HTTP, browsers
reject. Either fix the proxy to force HTTPS or set `N8N_SECURE_COOKIE=false`
for dev (NEVER for production).

### 7. `Host` mismatch breaks SSO redirects

OAuth/SSO callback URLs use the configured public URL. If `N8N_HOST`,
`WEBHOOK_URL`, and what the user actually hits don't agree, OAuth flows
fail. Use one canonical public URL everywhere.
