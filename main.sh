#!/bin/bash

: ${REALM:=EXAMPLE.COM}
: ${DOMAIN_REALM:=example.com}
: ${KERB_MASTER_KEY:=topsecret}
: ${KERB_ADMIN_USER:=admin}
: ${KERB_ADMIN_PASS:=admin}

create_config() {
: ${KDC_ADDRESS:=$(hostname -f)}

 cat>/etc/krb5.conf<<EOF
[logging]
   default = FILE:/var/log/kerberos/krb5libs.log
   kdc = FILE:/var/log/kerberos/krb5kdc.log
   admin_server = FILE:/var/log/kerberos/kadmind.log
[libdefaults]
   default_realm = $REALM
   dns_lookup_realm = false
   dns_lookup_kdc = false
   ticket_lifetime = 24h
   renew_lifetime = 7d
   forwardable = true
[realms]
   $REALM = {
      kdc = $KDC_ADDRESS
      admin_server = $KDC_ADDRESS
    }
[domain_realm]
  .$DOMAIN_REALM = $REALM
   $DOMAIN_REALM = $REALM
EOF
}

create_db() {
  /usr/sbin/kdb5_util -P $KERB_MASTER_KEY -r $REALM create -s
}

create_admin_user() {
  kadmin.local -q "addprinc -pw $KERB_ADMIN_PASS $KERB_ADMIN_USER/admin"
  echo "*/admin@$REALM *" > /etc/krb5kdc/kadm5.acl
}


init_kerberos() {
   mkdir -p /var/log/kerberos
   create_config
   create_db   
   create_admin_user
}

start_kdc() {
  /usr/sbin/krb5kdc &
  /usr/sbin/kadmind &
}

main() {
 [[ -d /var/log/kerberos ]] || init_kerberos 
 start_kdc
 sleep infinity
}

main 

