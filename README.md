# docker-kerberos

I created my version of dockerized Kerberos adapted to *podman*. The main feature is the configurable ports. Podman is usually executed as a non-root user and complains about ports below 1000. To use podman, replace all *docker* occurences with *podman*.

# Image creation

> git clone https://github.com/stanislawbartkowski/docker-kerberos.git <br>
> cd docker-kerberos/ <br>
> docker build -t kerberos .

# Running

## Quick start 

> docker run -d --name kerberos -p 749:749 -p 88:88 -kerberos

```bash
$ docker ps

CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS                                      NAMES
24afe18eb548        ubuntu-kerberos     "/main.sh"          4 seconds ago       Up 2 seconds        0.0.0.0:88->88/tcp, 0.0.0.0:749->749/tcp   kerberos

```
The container can be customized by several environment variables

| Variable | Description | Default
|----|-----|-----|
| REALM | The Kerberos realm | EXAMPLE.COM
| DOMAIN.REALM | The DNS domain for realm | example.com
| KERB_MASTER_KEY | Master key for KDC | topsecret |
| KERB_ADMIN_USER | Administrator account name  | admin
| KERB_ADMIN_PASS | Administrator password | admin
| KERB_ADMIN_PORT | Kerberos Admin server port | 749
| KERB_KDC_PORT | Kerberos KDC port | 88
| KERB_MAX_RENEWABLE | Max renewable period for Kerberos tickets | 7d

Example, a custom realm name

 > docker run -d  --name kerberos  -p 749:749 -p 88:88  -e REALM=HADOOP.COM.REALM kerberos
 
 For podman, usually executed as a non-root user, redirect the port numbers above 1000.
 
 > podman run -d --name kerberos -p 1749:749 -p 1088:88 kerberos
 
 Port reconfiguration.<br>
 >  podman run -d --name kerberos -e KERB_ADMIN_PORT=1749 -e KERB_KDC_PORT=1088 -p 1749:1749 -p 1088:1088 kerberos<br>
 
  ## Test
 
 Customize your Kerberos client
 
 > vi vi /etc/krb5.conf
 
  ```
  ...
  default_realm = HADOOP.COM.REALM
  ...
 HADOOP.COM.REALM = {
  kdc = localhost
  admin_server = localhost
}
 ```
 
 If non-standard ports are used, include port numbers.<br>
 ```
 EXAMPLE.COM = {
     kdc = thinkde:1088
     admin_server = thinkde:1749
}

```
 
 > kadmin -p admin/admin  (password admin)<br>
 
Important: to run *kadmin* from a remote machine, the Kerberos realm (here HADOOP.COM.REALM) should be configured as a default KDC on the client */etc/krb5.conf* file. Otherwise, after entering the password, the *kadmin* utility will hang.

 > listprincs
 ```
 kadmin:  listprincs
K/M@HADOOP.COM.REALM
admin/admin@HADOOP.COM.REALM
kadmin/21528069223e@HADOOP.COM.REALM
kadmin/admin@HADOOP.COM.REALM
kadmin/changepw@HADOOP.COM.REALM
kiprop/21528069223e@HADOOP.COM.REALM
krbtgt/HADOOP.COM.REALM@HADOOP.COM.REALM
kadmin:  
 ```
 Add user guest
 > kadmin:  addprinc guest
 ```
WARNING: no policy specified for guest@HADOOP.COM.REALM; defaulting to no policy
Enter password for principal "guest@HADOOP.COM.REALM": 
```
Authorize as guest
> kinit guest
```
Password for guest@HADOOP.COM.REALM: 
```
>klist
```
Ticket cache: KEYRING:persistent:1001:1001
Default principal: guest@HADOOP.COM.REALM

Valid starting       Expires              Service principal
07.01.2019 12:21:42  08.01.2019 12:21:42  krbtgt/HADOOP.COM.REALM@HADOOP.COM.REALM
	renew until 07.01.2019 12:21:42
```
Prepare guest keytab
> kadmin -p admin/admin  (password admin)<br>
> ktadd -k guest.keytab  guest@HADOOP.COM.REALM
```
Entry for principal guest@HADOOP.COM.REALM with kvno 2, encryption type aes256-cts-hmac-sha1-96 added to keytab WRFILE:guest.keytab.
Entry for principal guest@HADOOP.COM.REALM with kvno 2, encryption type aes128-cts-hmac-sha1-96 added to keytab WRFILE:guest.keytab.
kadmin: 
```
Authorize with keytab, preferred, avoid the password being passed over network
> kinit -kt guest.keytab guest<br>
> klist
```
Ticket cache: KEYRING:persistent:1001:1001
Default principal: guest@HADOOP.COM.REALM

Valid starting       Expires              Service principal
07.01.2019 12:47:53  08.01.2019 12:47:53  krbtgt/HADOOP.COM.REALM@HADOOP.COM.REALM
	renew until 07.01.2019 12:47:53
```
# Kubernetes/OpenShift

Containerized Kerberos can be deployed to OpenShift or Kubernetes cluster. A sample *kerberos.yaml* deployment file is attached.<br>
https://github.com/stanislawbartkowski/docker-kerberos/blob/master/openshift/kerberos.yaml<br>

Important: the Kerberos container is using ephemeral storage. Every time the container is recreated or deleted, the content is erased without any possibility to recover. Do not use in a production environment.

## Make public

Make Kerberos image public, being accessible from OpenShift cluster.<br>

> podman tag keberos quay.io/stanislawbartkowski/kerberos:v1.0<br>
> podman login quay.io<br>
> podman push quay.io/stanislawbartkowski/kerberos:v1.0<br>

## anyuid ServiceAccount

Kerberos services inside the container are started as *root* user. The deployment should be managed by ServiceAccount with *anyuid* RBAC privilege. In the sample deployment, *uuid-as* service account is used.<br>

## Deploy the service

> cd openshift<br>
> oc create -f kerberos.yaml<br>

>  oc get pods<br>
```
NAME                        READY   STATUS    RESTARTS   AGE
kerberos-54649c4c5b-gn86f   1/1     Running   0          31m
```

## Expose the service 

In the sample deployment, NodeIP service port is used.
```
oc get svc
NAME          TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kerberosadm   NodePort   172.30.197.73   <none>        1749:32275/TCP   32m
kerberoskdc   NodePort   172.30.53.179   <none>        1088:31476/TCP   32m
```
OpenShift assigns random ports from range 30000-32767. Another deployment can select different ports.<br>

On gateway node where HaProxy is installed, modify */etc/haproxy/haproxy.cfg* adding appropriate entries. In this example, OpenShift Master Node are referenced and related service ports are redirected.
```
frontend kerberoskdc-tcp
        bind *:31476
        default_backend kerberoskdc-tcp
        mode tcp
        option tcplog

backend kerberoskdc-tcp
        balance source
        mode tcp
        server master0 10.16.40.242:31476 check
        server master1 10.16.40.243:31476 check
        server master2 10.16.40.249:31476 check

frontend kerberosadm-tcp
        bind *:32275
        default_backend kerberosadm-tcp
        mode tcp
        option tcplog

backend kerberosadm-tcp
        balance source
        mode tcp
        server master0 10.16.40.242:32275 check
        server master1 10.16.40.243:32275 check
        server master2 10.16.40.249:32275 check
```
Restart HAProxy.<br>

> systemctl restart haproxy<br>

Make sure that ports are redirected.<br>
<br>
>nc -zv localhost 32275<br>
```
Ncat: Version 7.50 ( https://nmap.org/ncat )
Ncat: Connected to 127.0.0.1:32275.
Ncat: 0 bytes sent, 0 bytes received in 0.01 seconds.
```
## Configure client workstation

Assuming HAProxy hostname *shrieker-inf*.

```
...
default_realm = EXAMPLE.COM
...

EXAMPLE.COM = {
      kdc = shrieker-inf:31476
      admin_server = shrieker-inf:32275
}
....

```
> kadmin -p admin/admin
```
Connection to shrieker-inf closed.
sbartkowski:Pulpit$ vi /etc/krb5.conf
sbartkowski:Pulpit$ kadmin -p admin/admin
Couldn't open log file /var/log/kadmind.log: Permission denied
Authenticating as principal admin/admin with password.
Password for admin/admin@EXAMPLE.COM: 

addprinc guest
```
> kinit guest<br>
```
Password for guest@EXAMPLE.COM: 
sbartkowski:Pulpit$ klist
Ticket cache: KCM:1001
Default principal: guest@EXAMPLE.COM

Valid starting       Expires              Service principal
14.01.2021 18:37:40  15.01.2021 18:37:40  krbtgt/EXAMPLE.COM@EXAMPLE.COM
	renew until 21.01.2021 18:37:40
```
# Expose using OpenShift routes

> oc expose service/kerberosadm<br>
```
route.route.openshift.io/kerberosadm exposed
```

> oc expose service/kerberoskdc<br>
```
route.route.openshift.io/kerberoskdc exposed
```

> oc get routes<br>
```
NAME          HOST/PORT                                      PATH   SERVICES      PORT   TERMINATION   WILDCARD
kerberosadm   kerberosadm-sb.apps.shrieker.os.fyre.ibm.com          kerberosadm   1749                 None
kerberoskdc   kerberoskdc-sb.apps.shrieker.os.fyre.ibm.com          kerberoskdc   1088                 None
```
