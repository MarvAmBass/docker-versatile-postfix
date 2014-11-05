#!/bin/bash

function print_help {
cat <<EOF
        Generic Postfix Setup Script
===============================================

to create a new postfix server for your domain
you should use the following commands:

  docker run -p 25:25 -v /maildirs:/var/mail \
         dockerimage/postfix \
         yourdomain.com \
         user1:password \
         user2:password \
         userN:password

this creates a new smtp server which listens
on port 25, stores mail under /mailsdirs
and has serveral user accounts like
user1 with password "password" and a mail
address user1@yourdomain.com
________________________________________________
by MarvAmBass
EOF
}

if [ "-h" == "$1" ] || [ "--help" == "$1" ] || [ -z $1 ] || [ "" == "$1" ]
then
  print_help
  exit 0
fi

if [ ! -f /etc/default/saslauthd ]
then
  >&2 echo "you're not inside a valid docker container"
  exit 1;
fi

echo "setting up postfix for: $1"

# add domain
postconf -e myhostname="$1"
postconf -e mydestination="$1"
echo "$1" > /etc/mailname
echo "Domain $1" >> /etc/opendkim.conf

if [ ${#@} -gt 1 ]
then
  echo "adding users..."

  # all arguments but skip first argumenti
  i=0
  for ARG in "$@"
  do
    if [ $i -gt 0 ] && [ "$ARG" != "${ARG/://}" ]
    then
      USER=`echo "$ARG" | cut -d":" -f1`
      echo "  adding user: $USER"
      useradd -s /bin/bash $USER
      echo "$ARG" | chpasswd
      mkdir /var/spool/mail/$USER
      chown $USER:mail /var/spool/mail/$USER
    fi

    i=`expr $i + 1`
  done

fi

# starting services
service rsyslog start
service opendkim start
service saslauthd start
service postfix start

# print logs
touch /var/log/mail.log /var/log/mail.err /var/log/mail.warn
chmod a+rw /var/log/mail.*
tail -F /var/log/mail.*
