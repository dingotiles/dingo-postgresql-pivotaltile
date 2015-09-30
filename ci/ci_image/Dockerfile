FROM concourse/concourse-ci
# https://github.com/concourse/concourse/blob/master/ci/dockerfiles/concourse-ci/Dockerfile

RUN apt-get update && apt-get install zip curl wget bzr -y

ADD https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 /usr/bin/jq
RUN chmod 775 /usr/bin/jq

ADD https://github.com/geofffranks/spruce/releases/download/v0.9.0/spruce_0.9.0_linux_amd64.tar.gz /tmp/
RUN cd /tmp/ && tar xfz spruce*.tar.gz && mv spruce_0.9.0_linux_amd64/spruce /usr/bin/spruce && chmod 755 /usr/bin/spruce

# Install Go
RUN \
  mkdir -p /goroot && \
  curl https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz | tar xvzf - -C /goroot --strip-components=1

# Set environment variables.
ENV GOROOT /goroot
ENV GOPATH /gopath
ENV PATH $GOROOT/bin:$GOPATH/bin:$PATH
