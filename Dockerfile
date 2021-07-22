FROM ubuntu:focal

VOLUME /data

RUN apt update && apt install -y reprepro gpg-agent && rm -rf /var/lib/apt/lists/*

ENV PASS=""
ENV ORIGIN="aktin"
ENV LABEL="aktin"
ENV SUITE="stable"
ENV RELEASE="focal"
ENV ARCHITECTURES="amd64 i386"
ENV COMPONENTS="main"
ENV DESCRIPTION="Apt repository for AKTIN"
ENV KEYTYPE="default"
ENV KEYLENGTH="4096"
ENV SUBKEYTYPE="default"
ENV SUBKEYLENGTH="4096"
ENV NAME="AKTIN Repository"
ENV EMAIL="it-support@aktin.org"
ENV EXPIRE="1y"

RUN gpg -qk
ADD ./*.template /usr/share/aktin-reprepro/
ADD ./gpg.conf /root/.gnupg/
ADD ./gpg-agent.conf /root/.gnupg/
ADD ./run.sh /

CMD ["/run.sh"]

