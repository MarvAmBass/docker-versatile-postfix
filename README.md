# Versatile Postfix Mail Server (marvambass/versatile-postfix)
_maintained by MarvAmBass_

[FAQ - All you need to know about the marvambass Containers](https://marvin.im/docker-faq-all-you-need-to-know-about-the-marvambass-containers/)


## What is it

This Dockerfile (available as `marvambass/versatile-postfix`) gives you a completly versatile postfix
mailserver.

It signs outgoing mails with DKIM by default. You can create one Domain with different users with their passwords. For multiple Domains you need to use multiple containers or create your own fork of this project.

This is not a POP3 or IMAP server, you will get incomming E-Mails in the __Maildir__ format. Read it with less or link a IMAP Server to the volume.

View in Docker Registry [marvambass/versatile-postfix](https://registry.hub.docker.com/u/marvambass/versatile-postfix/)

View in GitHub [MarvAmBass/docker-versatile-postfix](https://github.com/MarvAmBass/docker-versatile-postfix/)


## Environment variables and defaults

* `ALIASES`
 * optional, no default, example usage: `postmaster:root;john:root;j.doe:root`
* `DISABLE_DKIM`
 * default: not set - if set to any value the DKIM Signing will be deactivated
* `DKIM_CANONICALIZATION`
 * default: `simple` - can be either `relaxed` or `simple`


## Running the Mailserver

This Dockerfile is build to be as versatile as possible.
Therefore the startup script takes care of all the important things.

You can easily create a new Mailserver for a domain with several users.

Keep in mind, this is a smtp server only.
To read recievied mails you should link a folder inside the conatiner.
Otherwise all mails will get lost after you delete your container.

To create a new postfix server for your domain you should use the following commands:

```
$ docker run -p 25:25 -v /maildirs:/var/mail \
    -v /dkim:/etc/postfix/dkim/ \
    -e 'ALIASES=postmaster:root;hostmaster:root;webmaster:root' \
    marvambass/versatile-postfix \
    yourdomain.com \
    user:password \
    user1:password \
    user2:password \
    userN:password
```

this creates a new smtp server which listens on port _25_, stores mail beneath _/mailsdirs_.

The `/dkim` directory has to contain a DKIM-Key _(see above)_ with the name `dkim.key`

It has serveral user accounts like `user1` with password "`password`" and a mail address `user1@yourdomain.com`


## DKIM

This Server uses DKIM by default. So we need our DKIM Keys.
If you don't have a DKIM Key, the Server will generate it on the first start.
Just be sure, that you make the directory `/etc/postfix/dkim/` available and
install the logged public key to your DNS System


### More about DKIM
To generate those keys you'll need the opendkim tools

```
$ apt-get install opendkim-tools
```

This generates a new certificate for @example.com with selector (_-s_) _mail_. If you want to Test DKIM first, add _-t_ argument which stands for test-mode.

```
$ opendkim-genkey -s mail -d example.com
```

Just put the file _mail.private_ as _dkim.key_ inside the dkim directory you'll later link into the container using _-v_.

The `mail.txt` should be imported into the DNS System. Add a new _TXT-Record_ for _mail_.\_domainkey [selector.\_domainkey]. And add as value the String starting "`v=DKIM1;...`" from the `mail.txt` file.

Thats all you need for DKIM


## Testing SMTP Mail recivieing

```
$ mailx -r "sender@example.com" -s "Test Mail Subject" user1@yourdomain.com < /etc/hosts
```


## Testing the SMTP Auth and SMTP sending via telnet:

```
$ echo -ne '\0user\0password' | openssl enc -base64
AHVzZXIAcGFzc3dvcmQ=

$ telnet 127.0.0.1 25
Trying 192.168.4.55...
Connected to yourdomain.com.
Escape character is '^]'.
220 yourdomain.com ESMTP
ehlo test
250-yourdomain.com
250-PIPELINING
250-SIZE 10240000
250-VRFY
250-ETRN
250-STARTTLS
250-AUTH LOGIN PLAIN
250 8BITMIME
auth plain AHVzZXIAcGFzc3dvcmQ=
235 Authentication successful
mail from: user@yourdomain.com
250 2.1.0 Ok
rcpt to: mail@example.com
250 2.1.5 Ok
data
354 End data with <CR><LF>.<CR><LF>
Hi there
this is just a basic test message
.
250 2.0.0 Ok: queued as 2E7FB27F
quit
221 Bye
Connection closed by foreign host.
```


## Links

* [DKIM Keycheck](http://dkimcore.org/c/keycheck)
* [DKIM more Infos and signature check](http://www.elandsys.com/resources/mail/dkim/opendkim.html)
