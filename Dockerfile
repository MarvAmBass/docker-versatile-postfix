FROM ubuntu:14.04
MAINTAINER MarvAmBass

## Install Postfix.

# pre config
RUN echo mail > /etc/hostname; \
    echo "postfix postfix/main_mailer_type string Internet site" > preseed.txt; \
    echo "postfix postfix/mailname string mail.example.com" >> preseed.txt

# load pre config for apt
RUN debconf-set-selections preseed.txt

# install
RUN apt-get -q -y update \
 && apt-get -q -y install postfix \
                          opendkim \
                          mailutils \
                          opendkim-tools \
                          sasl2-bin \
                          \
 && apt-get -q -y clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
 
## Configure Postfix

RUN postconf -e smtpd_banner="\$myhostname ESMTP"; \
    postconf -e mail_spool_directory="/var/spool/mail/"; \
    postconf -e mailbox_command=""

## Configure Sasl2

# config
RUN sed -i 's/^START=.*/START=yes/g' /etc/default/saslauthd; \
    sed -i 's/^MECHANISMS=.*/MECHANISMS="shadow"/g' /etc/default/saslauthd

RUN echo "pwcheck_method: saslauthd" > /etc/postfix/sasl/smtpd.conf; \
    echo "mech_list: PLAIN LOGIN" >> /etc/postfix/sasl/smtpd.conf; \
    echo "saslauthd_path: /var/run/saslauthd/mux" >> /etc/postfix/sasl/smtpd.conf

# postfix settings
RUN postconf -e smtpd_sasl_auth_enable="yes"; \
    postconf -e smtp_tls_security_level="may"; \
    postconf -e smtpd_recipient_restrictions="permit_mynetworks permit_sasl_authenticated reject_unauth_destination"; \
    postconf -e smtpd_helo_restrictions="permit_sasl_authenticated, permit_mynetworks, reject_invalid_hostname, reject_unauth_pipelining, reject_non_fqdn_hostname"

# add user postfix to sasl group
RUN adduser postfix sasl

# chroot saslauthd fix
RUN sed -i 's/^OPTIONS=/#OPTIONS=/g' /etc/default/saslauthd; \
    echo 'OPTIONS="-c -m /var/spool/postfix/var/run/saslauthd"' >> /etc/default/saslauthd

# dkim settings
RUN mkdir -p /etc/postfix/dkim \
 && echo "LogWhy yes" >> /etc/opendkim.conf \
 && echo "Include /etc/opendkim/custom.conf" >> /etc/opendkim.conf \
 && mkdir -p /etc/opendkim/ \
 \
 && sed -i 's/^SOCKET=/#SOCKET=/g' /etc/default/opendkim \
 && echo 'SOCKET="inet:8891@localhost"' >> /etc/default/opendkim

## FINISHED

# Postfix Ports
EXPOSE 25

# Add startup script
ADD startup.sh /opt/startup.sh
RUN chmod a+x /opt/startup.sh

ENV DKIM_SELECTOR=mail

# Docker startup
ENTRYPOINT ["/opt/startup.sh"]
CMD ["-h"]
