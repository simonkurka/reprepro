FROM ubuntu:focal

VOLUME /data

ENV TZ="Europe/Berlin"
RUN DEBIAN_FRONTEND="noninteractive" apt update && DEBIAN_FRONTEND="noninteractive" apt install -y reprepro gpg-agent dpkg-sig && rm -rf /var/lib/apt/lists/*

ENV PASS=""
ENV VERIFY="true"
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

