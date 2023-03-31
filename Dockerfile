ARG BUILDPLATFORM=$BUILDPLATFORM
FROM --platform=$BUILDPLATFORM golang:1.18 AS psiphon_builder
WORKDIR /go
LABEL stage=builder
ARG VERSION=2.0.29
ARG BUILDOS
ARG BUILDARCH
ARG TARGETS
ENV DIR=/go/src/github.com/Psiphon-Labs/psiphon-tunnel-core \
		GO111MODULE=off \
		CGO_ENABLED=0
SHELL ["/bin/bash", "-c"]
RUN TARGET_PALTFORMS=${TARGETS:-"$BUILDOS/$BUILDARCH"} &&                                                    \
    mkdir -p ${DIR}                                                                                       && \
		curl -sL https://github.com/Psiphon-Labs/psiphon-tunnel-core/archive/refs/tags/v${VERSION}.tar.gz |      \
		tar xz -C ${DIR} --strip-components=1                                                                 && \
		(IFS=','; for PLATFORM in $TARGET_PALTFORMS;                                                             \
		do                                                                                                       \
			OS=${PLATFORM%%/*}                                                                                  && \
			ARCH=${PLATFORM#*/}                                                                                 && \
			ARCH=${ARCH%/*}                                                                                     && \
			VERSION=${PLATFORM##*/}                                                                             && \
			TARGETVARIANT=${VERSION/$ARCH/}                                                                     && \
			VERSION=${TARGETVER/v/}                                                                             && \
			GOOS=${OS} GOARCH=${ARCH} go install -a -tags netgo                                                    \
			-ldflags '-w -extldflags "-static"'                                                                    \
			github.com/Psiphon-Labs/psiphon-tunnel-core/ConsoleClient                                           && \
			BINARY=$(find /go/bin/* -name "ConsoleClient*")                                                     && \
			mv ${BINARY} /go/psiphon_${OS}_${ARCH}_${TARGETVARIANT};                                               \
		done)

FROM swarupsengupta2007/alpine-s6:3.16.0
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
COPY base/ /
COPY psiphon.config ${DEF_DEFAULTS}
COPY --from=psiphon_builder /go/psiphon_${TARGETOS}_${TARGETARCH}_${TARGETVARIANT} ${DEF_APP}/psiphon
EXPOSE 8080 1080
VOLUME /config
