FROM python:3.12-slim

# Create non-root user
RUN addgroup --system closet && adduser --system --ingroup closet closet

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

USER closet

ENV PORT=8080

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port $PORT"]
