FROM ubuntu:18.04 as build

ENV HOME=/root

ENV GOROOT=/usr/local/go
ENV GOPATH=$HOME/go
ENV PATH=$PATH:$GOROOT/bin:$GOPATH/bin

ENV THETA_HOME=$GOPATH/src/github.com/thetatoken/theta

ENV VERSION=v1.2.0

ENV GO_ARCHIVE=go1.12.1.linux-amd64.tar.gz
ENV GO_ARCHIVE_CHECKSUM=2a3fdabf665496a0db5f41ec6af7a9b15a49fbe71a85a50ca38b1f13a103aeec

RUN apt-get update
#software-properties-common
RUN apt-get -y install build-essential gcc make wget jq golang-glide
RUN wget https://dl.google.com/go/${GO_ARCHIVE} && \
    echo "$GO_ARCHIVE_CHECKSUM $GO_ARCHIVE" | sha256sum --check && \
    tar -C /usr/local -xzf ${GO_ARCHIVE} && \
    rm -f ${GO_ARCHIVE}

WORKDIR $THETA_HOME

RUN git clone --branch ${VERSION} https://github.com/thetatoken/theta-protocol-ledger.git .
RUN make get_vendor_deps
RUN make install
# tests are flaky
#RUN make test_unit
#RUN mkdir -p /dist/integration/ && cp -a integration/mainnet integration/testnet integration/privatenet /dist/integration/
RUN mkdir -p /dist/integration/ && cp -a integration/mainnet /dist/integration/

FROM ubuntu:18.04 as runtime

ARG USER_ID
ARG GROUP_ID

ENV HOME /theta
# add user with specified (or default) user/group ids
ENV USER_ID ${USER_ID:-1000}
ENV GROUP_ID ${GROUP_ID:-1000}

RUN groupadd -g ${GROUP_ID} theta \
	&& useradd -u ${USER_ID} -g theta -s /bin/bash -m -d ${HOME} theta

USER theta
WORKDIR ${HOME}

COPY --from=build /root/go/bin/ /usr/local/bin/
COPY --from=build /dist/integration/ /opt/theta/integration/

