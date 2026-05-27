# [Caddy](https://caddyserver.com/) Frontend & Backend Reverse Proxy

**Combine your separate frontend and backend services into one domain!**

This image can also run an OpenClaw Daytona preview proxy for Studio OS. The
OpenClaw listeners are intended for Railway private networking only and let
Studio OS reach a Daytona sandbox without Tailscale.

### [View the example public project here](https://railway.app/project/35d8d571-4313-4049-9699-4e7db7f02a2f) - Utilizes sleeping frontend and backend services with wake via the private network

Access the frontend from `/*` and access the backend from `/api/*` on the same domain

**Frontend - Vue 3:** https://mysite.up.railway.app/

**Backend - Go Mux:** https://mysite.up.railway.app/api/

The proxy configurations are done in the [`Caddyfile`](https://github.com/brody192/reverse-proxy/blob/main/Caddyfile) everything is commented for your ease of use!

When deploying your Reverse Proxy service it will require you to set four service variables: **FRONTEND_DOMAIN** / **FRONTEND_PORT** and **BACKEND_DOMAIN** / **BACKEND_PORT**

**Note:** You will first need to have set a fixed `PORT` variable in both the frontend and backend services before deploying this template.

These are the four template variables that you will be required to fill out during the first deployment of this service, it is highly recommended to use [reference variables](https://docs.railway.app/guides/variables#referencing-another-services-variable).

Example:

```
FRONTEND_DOMAIN = ${{Frontend.RAILWAY_PRIVATE_DOMAIN}}
FRONTEND_PORT = ${{Frontend.PORT}}

BACKEND_DOMAIN = ${{Backend.RAILWAY_PRIVATE_DOMAIN}}
BACKEND_PORT = ${{Backend.PORT}}
```

## OpenClaw Daytona preview proxy

Use this mode when Studio OS needs to connect to a no-Tailscale Daytona sandbox
through Daytona preview URLs. Caddy listens on private ports for the OpenClaw
gateway and metadata sidecar, validates the Studio OS gateway bearer token, and
injects the Daytona preview token only on the upstream request. The token is sent
as both Daytona's preview header and `DAYTONA_SANDBOX_AUTH_KEY` query parameter
because Daytona preview authentication may require either form.

The proxy exposes:

```text
http://<caddy-service>.railway.internal:18789 -> Daytona gateway preview
http://<caddy-service>.railway.internal:18790 -> Daytona metadata preview
```

The public site listener can also expose the Railway-hosted model router at a
narrow Daytona-reachable path:

```text
https://studio.vegapunk-egghead.com/openclaw-model-router/* -> daytona-openclaw.railway.internal:18791
```

The model router validates `OPENCLAW_MODEL_ROUTER_TOKEN` itself. Keep that token
out of browser code and pass it only to Studio OS API/Daytona VM env.

Required Railway variables for the Caddy proxy service:

```env
DAYTONA_GATEWAY_PREVIEW_URL=https://18789-<sandbox-id>.daytonaproxy01.net
DAYTONA_METADATA_PREVIEW_URL=https://18790-<sandbox-id>.daytonaproxy01.net
DAYTONA_PREVIEW_TOKEN=<daytona preview token>
OPENCLAW_GATEWAY_TOKEN=<same token used by Daytona and Studio OS>
OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_METADATA_PORT=18790
```

Optional model-router route variables:

```env
OPENCLAW_MODEL_ROUTER_DOMAIN=daytona-openclaw.railway.internal
OPENCLAW_MODEL_ROUTER_PORT=18791
OPENCLAW_MODEL_ROUTER_PUBLIC_HOST=<optional Railway-generated host for Daytona VM calls>
```

When `OPENCLAW_MODEL_ROUTER_PUBLIC_HOST` is set, that host only serves
`/openclaw-model-router/*`; all other paths return `404` so the alternate
Railway domain does not bypass Cloudflare Access for the Studio UI/API.

If Daytona returns different preview tokens for each port, use these instead of
the shared `DAYTONA_PREVIEW_TOKEN`:

```env
DAYTONA_GATEWAY_PREVIEW_TOKEN=<preview token for port 18789>
DAYTONA_METADATA_PREVIEW_TOKEN=<preview token for port 18790>
```

If any Daytona/OpenClaw proxy variable is set, all required OpenClaw proxy
variables must be present or the container exits during startup. This prevents a
half-configured proxy from starting.

Studio OS API should use the Railway-private Caddy service URL:

```env
CHAT_VIA_GATEWAY=true
OPENCLAW_GATEWAY_URL=http://<caddy-service>.railway.internal:18789
OPENCLAW_METADATA_URL=http://<caddy-service>.railway.internal:18790
OPENCLAW_GATEWAY_API_KEY=<same OPENCLAW_GATEWAY_TOKEN>
```

After pairing Studio OS with the Daytona sandbox, also copy the `make pair`
device values into the Studio OS API environment:

```env
OPENCLAW_DEVICE_ID=<from make pair>
OPENCLAW_DEVICE_TOKEN=<from make pair>
OPENCLAW_DEVICE_PUBLIC_KEY=<from make pair>
OPENCLAW_DEVICE_PRIVATE_SEED=<from make pair>
```

### OpenClaw security notes

- Do not expose ports `18789` or `18790` through Railway public networking or
  TCP proxy. They should only be reachable through Railway private networking.
- Keep Daytona preview tokens only in this Caddy proxy service. Do not pass them
  to Studio OS, the browser, or application logs.
- The OpenClaw private listeners intentionally do not define access logs because
  the upstream request includes the Daytona preview token as a query parameter.
- Caddy preserves the Studio OS `Authorization` header so OpenClaw gateway and
  device pairing auth still run inside Daytona.
- Caddy removes any caller-supplied `x-daytona-preview-token` before injecting
  the configured Daytona preview token.
- A separate private OpenClaw proxy service is recommended if your existing
  Caddy service is also the public web/API edge.

**Relevant Caddy documentation:**

- [The Caddyfile](https://caddyserver.com/docs/caddyfile)
- [Caddyfile Directives](https://caddyserver.com/docs/caddyfile/directives)
- [reverse_proxy](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy)

**Some prerequisites to help with common issues that could arise:**

- Both the frontend and backend need to listen on fixed ports, in my example project I have configured my frontend and backend to both listen on port `3000`
    - This can be done by [configuring your frontend and backend apps to listen on the `$PORT`](https://docs.railway.app/troubleshoot/fixing-common-errors) environment variable, then setting a `PORT` service variable to `3000`

- Since Railway's internal network is IPv6 only the frontend and backend apps will need to listen on `::` (all interfaces, both IPv4 and IPv6)

    **Start commands for some popular frameworks:**

    - **Gunicorn:** `gunicorn main:app -b [::]:${PORT:-3000}`

    - **Uvicorn:** `uvicorn main:app --host :: --port ${PORT:-3000}`

        - Uvicorn does not support dual-stack binding (IPv6 and IPv4) from the CLI, so while that start command will work to enable access from within the private network, this prevents you from accessing the app from the public domain if needed, I recommend using [Hypercorn](https://pgjones.gitlab.io/hypercorn/) instead

    - **Hypercorn:** `hypercorn main:app --bind [::]:${PORT:-3000}`

    - **Next:** `next start -H :: --port ${PORT:-3000}`

    - **Express/Nest:** `app.listen(process.env.PORT || 3000, "::");`
