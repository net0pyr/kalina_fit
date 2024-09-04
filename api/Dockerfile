FROM golang:1.23.0-alpine AS build_dir

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go build -o main .

FROM alpine:latest

WORKDIR /app

COPY --from=build_dir /app/main .

EXPOSE 8080

CMD ["./main"]

