FROM golang:alpine AS builder

RUN apk update
RUN apk add --no-cache git
WORKDIR /app/

RUN go get github.com/pin/tftp
RUN go get github.com/go-git/go-git
RUN go get github.com/sparrc/go-ping
RUN go get github.com/docker/docker/client
RUN go get github.com/tidwall/sjson
RUN go get github.com/shirou/gopsutil

#RUN go get github.com/miekg/dns
#RUN go get github.com/sparrc/go-ping
COPY JumpStarterStatus.go JumpStarterStatus.go
COPY main.go main.go
COPY ping.go ping.go
COPY git.go git.go
COPY servers.go servers.go
COPY remote.go remote.go
COPY container.go container.go
COPY stat/status.go status.go
#RUN go get -d -v
RUN CGO_ENABLED=0 go build -o /main



FROM golang:alpine AS statBuilder
RUN apk update
RUN apk add --no-cache git
WORKDIR /app/
RUN go get golang.org/x/sys/unix
RUN go get github.com/docker/docker/client
RUN go get github.com/shirou/gopsutil/cpu
COPY JumpStarterStatus.go JumpStarterStatus.go
COPY stat/status.go status.go
COPY stat/stat.go stat.go
RUN CGO_ENABLED=0 go build -o /stat


FROM alpine AS tftp 
RUN apk add --no-cache wget
RUN apk add --no-cache syslinux
WORKDIR /files/
RUN wget https://github.com/talos-systems/talos/releases/download/v0.7.1/initramfs-amd64.xz
RUN wget https://github.com/talos-systems/talos/releases/download/v0.7.1/vmlinuz-amd64

FROM alpine
RUN apk add --no-cache docker-compose
WORKDIR /files/
COPY --from=tftp /files/initramfs-amd64.xz .
COPY --from=tftp /files/vmlinuz-amd64 .
COPY init.yaml .
COPY pxe-config.ign /
COPY bootstrap/ .
COPY jumpstarter.png .
RUN apk add --no-cache vim
COPY --from=statBuilder /stat ./stat
WORKDIR /tftp/
COPY --from=tftp /usr/share/syslinux/lpxelinux.0 .
COPY --from=tftp /usr/share/syslinux/ldlinux.c32 .
WORKDIR /tftp/pxelinux.cfg/
WORKDIR /tftp/
ENV SSH_KNOWN_HOSTS=/root/.ssh/known_hosts
COPY --from=builder /main /tftp/main
ENTRYPOINT ["/tftp/main"]
