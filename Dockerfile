ARG BUILDPLATFORM=$BUILDPLATFORM
ARG GO_VERSION=1.24.1
FROM --platform=$BUILDPLATFORM golang:$GO_VERSION AS psiphon_builder
WORKDIR /go
LABEL stage=builder
ARG BUILDOS
ARG BUILDARCH
ARG TARGETS
ARG PSIPHON_VERSION
ENV DIR=/go/src/github.com/Psiphon-Labs/psiphon-tunnel-core
ENV GO111MODULE=off
ENV CGO_ENABLED=0
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN <<__SCRIPT__
TARGET_PALTFORMS=${TARGETS:-"$BUILDOS/$BUILDARCH"}
TARGET_PALTFORMS=${TARGET_PALTFORMS//,/ }
mkdir -p ${DIR}
curl -sL https://github.com/Psiphon-Labs/psiphon-tunnel-core/archive/refs/tags/v${PSIPHON_VERSION}.tar.gz | tar xz -C ${DIR} --strip-components=1
for PLATFORM in $TARGET_PALTFORMS
do
	OS=${PLATFORM%%/*}                                                                     
	ARCH=${PLATFORM#*/}                                                                    
	ARCH=${ARCH%/*}                                                                        
	VERSION=${PLATFORM##*/}                                                                
	TARGETVARIANT=${VERSION/$ARCH/}                                                        
	VERSION=${TARGETVER/v/}                                                                
	GOOS=${OS} GOARCH=${ARCH} go install -a -tags netgo -ldflags '-w -extldflags "-static"' github.com/Psiphon-Labs/psiphon-tunnel-core/ConsoleClient
	BINARY=$(find /go/bin/* -name "ConsoleClient*")
	mv ${BINARY} /go/psiphon_${OS}_${ARCH}_${TARGETVARIANT}
done
__SCRIPT__

FROM swarupsengupta2007/alpine-s6:3.16.0
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
COPY base/ /
COPY psiphon.config ${DEF_DEFAULTS}
COPY --from=psiphon_builder /go/psiphon_${TARGETOS}_${TARGETARCH}_${TARGETVARIANT} ${DEF_APP}/psiphon
EXPOSE 8080 1080
HEALTHCHECK --interval=30s --timeout=5s --start-period=2m --retries=3 CMD netstat -ltn|grep 1080 || exit 1
VOLUME /config
