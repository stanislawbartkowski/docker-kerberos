FROM ubuntu
MAINTAINER sb

RUN apt-get update 
RUN apt-get upgrade -y
RUN export DEBIAN_FRONTEND=noninteractive ; apt-get install krb5-kdc krb5-admin-server -y

EXPOSE 88 749

ADD ./main.sh /main.sh

ENTRYPOINT ["/main.sh"]
