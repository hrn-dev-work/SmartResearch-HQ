#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Starting infrastructure (PostgreSQL + Redis)..."
docker compose -f "$ROOT/docker-compose.yml" up -d postgres redis

echo "Backend: cd backend && python -m venv .venv && source .venv/bin/activate"
echo "  pip install -r requirements.txt"
echo "  uvicorn app.main:app --reload --port 8000"

echo "Frontend: cd frontend && npm install && npm run dev"
