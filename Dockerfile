FROM golang:1.13-alpine AS build

ARG HUGO_BUILD_TAGS

ARG CGO=1
ENV CGO_ENABLED=${CGO}
ENV GOOS=linux
ENV GO111MODULE=on

RUN apk update && \
    apk add --no-cache git && \
    git clone https://github.com/gohugoio/hugo.git

RUN cd hugo && go build

# ---

FROM alpine:3.11

COPY --from=build /go/hugo/hugo /usr/bin/hugo

# libc6-compat & libstdc++ are required for extended SASS libraries
# ca-certificates are required to fetch outside resources (like Twitter oEmbeds)
RUN apk update && \
    apk add --no-cache ca-certificates libc6-compat libstdc++ git

WORKDIR /work

# Expose port for live server
EXPOSE 1313

ENTRYPOINT ["hugo"]
CMD [""]
