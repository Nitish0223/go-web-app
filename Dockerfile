
# Build stage
FROM golang:1.22.5 AS base

WORKDIR /app

COPY go.mod .
RUN go mod download

COPY . .

# Build one self-contained binary. distroless has no C libraries, so cgo is turned off.
RUN CGO_ENABLED=0 go build -o main .

# Final stage
FROM gcr.io/distroless/static-debian12

WORKDIR /app

COPY --from=base /app/main .
COPY --from=base /app/static ./static

EXPOSE 8080

CMD ["./main"]
