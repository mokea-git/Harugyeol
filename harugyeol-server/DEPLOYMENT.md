# HRG-BK Docker Deployment

## GitHub Actions

- `CI` runs `npm ci` and `npm run build` on every branch push and pull request.
- `Deploy` runs on `main` pushes and manual dispatches.
- Deployment expects a self-hosted runner on the production server with Docker and Docker Compose v2 installed.

## Server Setup

Create the runtime directory and environment file on the server:

```bash
sudo mkdir -p /opt/hrg-bk
sudo chown -R "$USER":"$USER" /opt/hrg-bk
cp .env.example /opt/hrg-bk/.env
```

Fill `/opt/hrg-bk/.env` with production values:

```bash
PORT=3000
HOST=0.0.0.0
APP_AUTH_CALLBACK_URL=io.supabase.harugyeol://login-callback
POSTGRES_URL=postgresql://user:password@host:5432/harugyeol
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJ...
ANTHROPIC_API_KEY=sk-ant-...
RESEND_API_KEY=re_...
RESEND_FROM=support@mokea.cloud
```

If you use a different deployment path, set the repository variable `DEPLOY_PATH`.

## Runtime

The deploy workflow syncs the repository into `DEPLOY_PATH`, keeps the server-side `.env` file intact, builds the Docker image, and starts the service with:

```bash
docker compose up -d --remove-orphans
```

The API is exposed on `PORT` from `.env` and uses `/health` as the container health check.
