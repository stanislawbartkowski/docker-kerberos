# docker-kerberos

https://github.com/sequenceiq/docker-kerberos

I created my own version of dockerized Kerberos. 

# Image creation

> git clone https://github.com/stanislawbartkowski/docker-kerberos.git <br>
> cd docker-kerberos/ <br>
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
| 

Example, a custom realm name

 > docker run -d  --name kerberos  -p 749:749 -p 88:88  -e REALM=HADOOP.COM.REALM ubuntu-kerberos
 
 For podman, usually executed as non-root user, redirect the port numbers above 1000.
 
 > podman run -d --name kerberos -p 1749:749 -p 1088:88 kerberos
 
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
 
Important: in order to run *kadmin* from remote machine, the Kerberos realm (here HADOOP.COM.REALM) should be configured as a default KDC on the client */etc/krb5.conf* file. Otherwise, after entering the password, the *kadmin* utility will hang.
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




