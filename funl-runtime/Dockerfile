# ---- Build stage ----
  FROM golang:1.25-alpine AS builder
  WORKDIR /src
  
  COPY go.mod ./
  RUN go mod tidy || true
  COPY . .
  
  # Build a static binary
  ENV CGO_ENABLED=0 GOOS=linux
  RUN go build -ldflags="-s -w" -o /server ./cmd/server
  
  # ---- Runtime stage ----
  FROM scratch
  WORKDIR /
  # TLS certs for outbound HTTPS if needed
  COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
  COPY --from=builder /server /server
  EXPOSE 8080
  ENTRYPOINT ["/server"]
  