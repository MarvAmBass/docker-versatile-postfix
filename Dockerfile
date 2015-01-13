FROM ubuntu:14.04
MAINTAINER MarvAmBass

## Install Postfix.

# pre config
RUN echo mail > /etc/hostname
RUN echo "postfix postfix/main_mailer_type string Internet site" > preseed.txt
RUN echo "postfix postfix/mailname string mail.example.com" >> preseed.txt

# load pre config for apt
RUN debconf-set-selections preseed.txt

# install
RUN apt-get update && apt-get install -y \
    postfix \
    opendkim \
    mailutils \
    opendkim-tools \
    sasl2-bin

## Configure Postfix

RUN postconf -e smtpd_banner="\$myhostname ESMTP"
RUN postconf -e mail_spool_directory="/var/spool/mail/"
RUN postconf -e mailbox_command=""

## Configure Sasl2

# config
RUN sed -i 's/^START=.*/START=yes/g' /etc/default/saslauthd
RUN sed -i 's/^MECHANISMS=.*/MECHANISMS="shadow"/g' /etc/default/saslauthd

RUN echo "pwcheck_method: saslauthd" > /etc/postfix/sasl/smtpd.conf
RUN echo "mech_list: PLAIN LOGIN" >> /etc/postfix/sasl/smtpd.conf
RUN echo "saslauthd_path: /var/run/saslauthd/mux" >> /etc/postfix/sasl/smtpd.conf

# postfix settings
RUN postconf -e smtpd_sasl_auth_enable="yes"
RUN postconf -e smtpd_recipient_restrictions="permit_mynetworks permit_sasl_authenticated reject_unauth_destination"
RUN postconf -e smtpd_helo_restrictions="permit_sasl_authenticated, permit_mynetworks, reject_invalid_hostname, reject_unauth_pipelining, reject_non_fqdn_hostname"

# add user postfix to sasl group
RUN adduser postfix sasl

# chroot saslauthd fix
RUN sed -i 's/^OPTIONS=/#OPTIONS=/g' /etc/default/saslauthd
RUN echo 'OPTIONS="-c -m /var/spool/postfix/var/run/saslauthd"' >> /etc/default/saslauthd

# dkim settings
RUN mkdir -p /etc/postfix/dkim
RUN mkdir -p /var/spool/postfix/var/run/opendkim/ && chown opendkim.opendkim /var/spool/postfix/var/run/opendkim/

RUN adduser postfix opendkim

RUN echo "KeyFile                 /etc/postfix/dkim/dkim.key" >> /etc/opendkim.conf
RUN echo "Selector                mail" >> /etc/opendkim.conf
RUN echo "SOCKET                  local:/var/spool/postfix/var/run/opendkim/opendkim.sock" >> /etc/opendkim.conf

RUN sed -i 's/^SOCKET=/#SOCKET=/g' /etc/default/opendkim
RUN echo 'SOCKET="local:/var/spool/postfix/var/run/opendkim/opendkim.sock"' >> /etc/default/opendkim

RUN postconf -e milter_default_action="accept"
RUN postconf -e milter_protocol="2"
RUN postconf -e smtpd_milters="unix:/var/spool/postfix/var/run/opendkim/opendkim.sock"
RUN postconf -e non_smtpd_milters="unix:/var/spool/postfix/var/run/opendkim/opendkim.sock"

## FINISHED

# Postfix Ports
EXPOSE 25

# Add startup script
ADD startup.sh /opt/startup.sh
RUN chmod a+x /opt/startup.sh

# Docker startup
ENTRYPOINT ["/opt/startup.sh"]
CMD ["-h"]
