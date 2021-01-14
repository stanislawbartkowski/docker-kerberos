FROM centos:7
LABEL maintainer=<stanislawbartkowski@gmail.com>

RUN yum install -y krb5-kdc krb5-server krb5-workstation

# EXPOSE 88 749

ADD ./main.sh /main.sh

ENTRYPOINT ["/main.sh"]
