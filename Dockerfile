ARG BUILDPLATFORM=$BUILDPLATFORM
ARG GO_VERSION=1.24.1
FROM --platform=$BUILDPLATFORM golang:$GO_VERSION AS psiphon_builder
WORKDIR /go
LABEL stage=builder
ARG TARGETS
ARG PSIPHON_VERSION
ADD build.sh latest_version.sh /go/
RUN <<__SCRIPT__
ARGS=""
if [ -n "${TARGETS}" ]; then
	ARGS="${ARGS} --targets ${TARGETS}"
fi
if [ -n "${PSIPHON_VERSION}" ]; then
	ARGS="${ARGS} --version ${PSIPHON_VERSION}"
fi
/go/build.sh ${ARGS}
__SCRIPT__

FROM alpine:3.23.2
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
RUN --mount=type=bind,from=psiphon_builder,source=/go/dist,target=/tmp/psiphon \
    --mount=type=bind,source=./assets,target=/tmp/assets \
	<<__SCRIPT__
    apk add --no-cache tini
	cp /tmp/assets/start-psiphon /usr/local/bin/start-psiphon
	cp /tmp/assets/healthcheck /usr/local/bin/healthcheck
	mkdir -p /etc/psiphon
	cp /tmp/assets/psiphon.config /etc/psiphon/psiphon.config
	if [ -z "${TARGETVARIANT}" ]; then
		cp /tmp/psiphon/psiphon_${TARGETOS}_${TARGETARCH} /usr/local/bin/psiphon
	else
		cp /tmp/psiphon/psiphon_${TARGETOS}_${TARGETARCH}_${TARGETVARIANT} /usr/local/bin/psiphon
	fi
	chmod +x /usr/local/bin/start-psiphon 
	chmod +x /usr/local/bin/healthcheck
	chmod +x /usr/local/bin/psiphon
__SCRIPT__
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/start-psiphon"]
HEALTHCHECK --interval=30s --timeout=5s --start-period=2m --retries=3 CMD healthcheck
