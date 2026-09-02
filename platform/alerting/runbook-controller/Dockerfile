FROM python:3.12-alpine
RUN apk add --no-cache curl && \
    curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && mv kubectl /usr/local/bin/
WORKDIR /app
COPY app.py .
EXPOSE 8081
CMD ["python", "app.py"]
