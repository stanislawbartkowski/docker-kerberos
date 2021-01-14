#!/bin/bash

: ${REALM:=EXAMPLE.COM}
: ${DOMAIN_REALM:=example.com}
: ${KERB_MASTER_KEY:=topsecret}
: ${KERB_ADMIN_USER:=admin}
: ${KERB_ADMIN_PASS:=admin}
: ${KERB_ADMIN_PORT:=749}
: ${KERB_KDC_PORT:=88}
: ${KERB_MAX_RENEWABLE:=7d}

KADMINCONF=/var/kerberos/krb5kdc/kadm5.ac
KDCKONF=/var/kerberos/krb5kdc/kdc.conf
#KDCKONF=kdc.conf



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
   renew_lifetime = ${KERB_MAX_RENEWABLE}
   forwardable = true
[realms]
   $REALM = {
      kdc = $KDC_ADDRESS:$KERB_KDC_PORT
      admin_server = $KDC_ADDRESS:$KERB_ADMIN_PORT
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
  kadmin.local -q "modprinc -maxrenewlife ${KERB_MAX_RENEWABLE} krbtgt/$REALM"

  touch $KADMINCONF
  echo "*/admin@$REALM *" > $KADMINCONF
}

replacekdcport() {
   sed "s/88/$KERB_KDC_PORT/g" $KDCKONF >$TMP
   cp $TMP $KDCKONF
}

configadcadmin() {
   sed "s/}/kadmin_port = ${KERB_ADMIN_PORT} \n max_renewable_life = ${KERB_MAX_RENEWABLE} \n }/g" $KDCKONF >$TMP
   cp $TMP $KDCKONF
}

init_kerberos() {
   mkdir -p /var/log/kerberos
   create_db   
   create_config
   replacekdcport
   configadcadmin
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


TMP=$(mktemp)
main 
rm -r $TMP

