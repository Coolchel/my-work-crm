# Backend configuration

## Environment variables

Create a local `.env` file in `backend/` based on `.env.example`.

Variables:
- `DJANGO_DEBUG`: `True` for local development, `False` for production.
- `DJANGO_SECRET_KEY`: required in production, should be a long random secret.
- `DJANGO_ALLOWED_HOSTS`: comma-separated hostnames/IPs allowed by Django.
- `DJANGO_CORS_ALLOW_ALL_ORIGINS`: keep `True` for local dev convenience.
- `DJANGO_CORS_ALLOWED_ORIGINS`: comma-separated full origins for production CORS whitelist.

## Behavior

- Local dev defaults are convenient:
  - `DJANGO_DEBUG=True`
  - fallback dev secret key if `DJANGO_SECRET_KEY` is not set
  - `DJANGO_ALLOWED_HOSTS` defaults to `localhost,127.0.0.1`
  - CORS allow-all enabled by default
- Production is strict (`DJANGO_DEBUG=False`):
  - `DJANGO_SECRET_KEY` must be set
  - `DJANGO_ALLOWED_HOSTS` must be configured
  - CORS should use `DJANGO_CORS_ALLOWED_ORIGINS` whitelist

## Run tests

From `backend/`:

```bash
python manage.py test core
```
