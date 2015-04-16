FROM perl:5.20.1
MAINTAINER Arthur Axel fREW Schmidt <frioux@gmail.com>

ADD . /opt/harbinger
WORKDIR /opt/harbinger

EXPOSE 8001

ENV PERL5LIB lib:local/lib/perl5

CMD ["perl", "-Ilocal/lib/perl5", "-Ilib", "bin/harbinger-server"]
