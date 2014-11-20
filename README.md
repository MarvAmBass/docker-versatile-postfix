# Versatile Postfix Mail Server
_maintained by MarvAmBass_

View in Docker Registry [marvambass/versatile-postfix](https://registry.hub.docker.com/u/marvambass/versatile-postfix/)

## Environment variables and defaults

* ALIASES
 * optional, no default, example usage: "postmaster:root;john:root;j.doe:root"

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
		-e 'ALIASES=postmaster:root;hostmaster:root;webmaster:root' \
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
If you don't have a DKIM Key, the Server will generate it on the first start.
Just be sure, that you make the directory ___/etc/postfix/dkim/___ available and
install the logged public key to your DNS System

### More about DKIM
To generate those keys you'll need the opendkim tools

	apt-get install opendkim-tools

This generates a new certificate for @example.com with selector (_-s_) _mail_. If you want to Test DKIM first, add _-t_ argument which stands for test-mode.

	opendkim-genkey -s mail -d example.com

Just put the file _mail.private_ as _dkim.key_ inside the dkim directory you'll later link into the container using _-v_.

The _mail.txt_ should be imported into the DNS System. Add a new _TXT-Record_ for _mail_.\_domainkey [selector.\_domainkey]. And add as value the String starting "_v=DKIM1;..._" from the _mail.txt_ file.

Thats all you need for DKIM

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
