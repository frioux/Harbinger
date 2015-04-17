FROM perl:5.20.1
MAINTAINER Arthur Axel fREW Schmidt <frioux@gmail.com>

RUN env DEBIAN_FRONTEND=noninteractive apt-get update \
 && apt-get install --no-install-recommends -y \
    libmysqlclient-dev \
    libpq-dev \
 && apt-get autoremove -y \
 && cpanm DBD::Pg DBD::mysql \
 && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cpanm local/cache local/man

ADD . /opt/harbinger
WORKDIR /opt/harbinger

EXPOSE 8001

ENV PERL5LIB lib:local/lib/perl5

CMD ["perl", "-Ilocal/lib/perl5", "-Ilib", "bin/harbinger-server"]
