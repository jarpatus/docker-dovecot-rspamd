# Mail server with spam filtering
This is docker image for self hosting an IMAP mail server pulling emails from external IMAP or POP3 mail server. Multiple local and remote mailboxes are supported as are spam and rule based filtering. It is possible in example to pull messages from one mailbox at remote server and write them to multiple local mailboxes and/or folders. 

Please notice that this image does NOT have a SMTP server so container cannot receive or send out emails, only pulling is possible. This is by design and won't change as self hosting a SMTP server is too hairy business nowadays. You need external IMAP or POP3 and SMTP from your ISP or from service provider you choose.

Goals of this image is to allow:
  - Better spam filtering than your own service provider can offer
  - Better handling of email aliases, forwards etc. as you can use rules to sort messages to multiple local mailboxes
  - Easier backups as you now can backup your emails like you backup yor other docker containers
  - Taking back control of your own emails

# Software
Following software packages are used for this image:
* Dovecot for IMAP and LDA
* fetchmail for remote-mail retrieval
* Rspamd for spam filtering  
* fdm for rule based filtering 

# Installation
Use Docker Compose, example docker-compose.yml:
```
services:
  dovecot:
    image: codedure/dovecot
    container_name: dovecot
    environment:
      RSPAMD_PASSWORD: 'password'
    volumes:
      - ./config:/config
      - ./data/dovecot:/home/vmail
      - ./data/redis:/var/lib/redis
      - ./data/rspamd:/var/lib/rspamd
    ports:
      # - 143:143
      - 993:993
      # - 11334:11334
    restart: unless-stopped
```

## Environment variables
* RSPAMD_PASSWORD - Password for rpsamd controller

## Ports
* 143 - IMAP, while STARTTLS is supported so is unencrypted connections so exposing this port is strongly advised against 
* 993 - IMAPS, encrypted, please use this
* 11334 - Rspamd controller and Web UI, at minimum set RSPAMD_PASSWORD environment variable

## Mounts
You should use volumes or bind mounts for all following folders:
* /config - Container is configured and can be customized by putting config to this folder
* /home/vmail - Contains mailboxes which you probably do want to backup as well 
* /var/lib/redis - Redis databases 
* /var/lib/rspamd - Rspamd static runtime data 

# FAQ
* Why fetchmail instead of just fdm doing fetch? Fdm does not support daemon mode nor IDLE.
* Why use Dovecot's delivery when fdm could do delivery by itself? Updates Dovecot's mailbox indexes during delivery. 

