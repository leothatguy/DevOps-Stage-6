FROM python:3.6-alpine

WORKDIR /app

COPY requirements.txt .
RUN apk add --no-cache build-base && \
	pip install --upgrade pip && \
	pip install --no-cache-dir --default-timeout=100 -r requirements.txt

COPY . .

CMD ["python", "main.py"]
