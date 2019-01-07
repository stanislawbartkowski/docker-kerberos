# docker-kerberos

https://github.com/sequenceiq/docker-kerberos

I was using this dockerized Kerberos image but I decided to prepare my own version based on Ubuntu. The Ubuntu has smaller footprint, 650 MB Centos against 230 MB Ubuntu version (160MB + 70MB). The sequenceid/kerberos is also using the old version of Centos (6.6).

# Image creation

> git clone https://github.com/stanislawbartkowski/docker-kerberos.git
> cd docker-kerberos/
> docker build -t ubuntu-kerberos .

# Running

## Quick start 

> docker run -d --name kerberos -p 749:749 -p 88:88 ubuntu-kerberos

```bash
$ docker ps

CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS                                      NAMES
24afe18eb548        ubuntu-kerberos     "/main.sh"          4 seconds ago       Up 2 seconds        0.0.0.0:88->88/tcp, 0.0.0.0:749->749/tcp   kerberos

```
The container can be customized by a number of environment variables

| Variable | Description | Default
|----|-----|-----|
| REALM | The Kerberos realm | EXAMPLE.COM
| DOMAIN.REALM | The DNS domain for realm | example.com
| KERB_MASTER_KEY | Master key for KDC | topsecret |
| KERB_ADMIN_USER | Administrator account name  | admin
| KERB_ADMIN_PASS | Administrator password | admin

Example, custom realm name

 > docker run -d  -name  -p 749:749 -p 88:88  -e REALM=HADOOP.COM.REALM kerberos ubuntu-kerberos




