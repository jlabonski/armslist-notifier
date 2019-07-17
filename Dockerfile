FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y --no-install-recommends libxml2-utils curl && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /aln
COPY *.sh /

WORKDIR /aln

ENTRYPOINT [ "/armslist-notifier.sh" ]
