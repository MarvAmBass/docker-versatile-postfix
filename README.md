# Versatile Postfix Mail Server
_maintained by MarvAmBass_

View in Docker Registry [marvambass/versatile-postfix](https://registry.hub.docker.com/u/marvambass/versatile-postfix/)

## Running the Mailserver

This Dockerfile is build to be as versatile as possible.
Therefore the startup script takes care of all the important things.

You can easily create a new Mailserver for a domain with several users.

Keep in mind, this is a smtp server only.
To read recievied mails you should link a folder inside the conatiner.
Otherwise all mails will get lost after you delete your container.

To create a new postfix server for your domain you should use the following commands:

	docker run -p 25:25 -v /maildirs:/var/mail \
		-v /dkim:/etc/postfix/dkim/ \
		marvambass/versatile-postfix \
		yourdomain.com \
		user1:password \
		user2:password \
		userN:password

this creates a new smtp server which listens on port _25_, stores mail beneath _/mailsdirs_.

The _/dkim_ directory has to contain a DKIM-Key _(see above)_ with the name __dkim.key__

It has serveral user accounts like _user1_ with password "_password_" and 
a mail address _user1@yourdomain.com_

## DKIM

This Server uses DKIM by default. So we need our DKIM Keys.
To generate those keys you'll need the opendkim tools

	apt-get install opendkim-tools

This generates a new certificate, in testmode (like most of the used certs) for @example.com

	opendkim-genkey -t -s mail -d example.com

Just put the file _mail.private_ as _dkim.key_ inside the dkim directory you'll later link into the container using _-v_.

The _mail.txt_ should be imported into the DNS System

## Testing SMTP

	$ mailx -r "sender@yourdomain.tld" -s "Test Mail Subject" recipient@domain.tld < /etc/hosts

## Testing the SMTP Auth:

	$ echo -ne '\0user\0password' | openssl enc -base64
	AHVzZXIAcGFzc3dvcmQ=

	$ telnet 127.0.0.1 25
	Trying 192.168.4.55...
	Connected to mail.yourserver.tld.
	Escape character is '^]'.
	220 mail.yourserver.tld ESMTP
	ehlo test
	250-mail.yourserver.tld
	250-PIPELINING
	250-SIZE 10240000
	250-VRFY
	250-ETRN
	250-STARTTLS
	250-AUTH LOGIN PLAIN
	250 8BITMIME
	auth plain AHVzZXIAcGFzc3dvcmQ=
	235 Authentication successful
	quit
	221 Bye
	Connection closed by foreign host.

## Building the Dockerfile yourself

Just use the following command to build and publish your Docker Container.

  docker build -t username/versatile-postfix .
  docker push username/versatile-postfix
