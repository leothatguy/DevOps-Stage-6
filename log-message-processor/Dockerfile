FROM python:3.6-slim

WORKDIR /app

COPY requirements.txt .
RUN apt-get update && apt-get install -y build-essential && \
	pip install --upgrade pip && \
	pip install --no-cache-dir --default-timeout=100 -r requirements.txt

COPY . .

CMD ["python", "main.py"]
