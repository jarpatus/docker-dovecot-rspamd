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
      RSPAMD_PASSWORD: password
      RSPAMD_PASSWORD_ENC: $$2$$rxgdn8ez91f49cmq7kgj75rhmeps4awy$$mp35rment7zt4mizqxia7zg6ayxmbronhi1mrzhybudobczx3ery
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
* RSPAMD_PASSWORD - Plain text password for Rspamd controller (use encrypted instead for good measure).
* RSPAMD_PASSWORD_ENC - Ecnrypted password for Rspamd controller. Note that if both RSPAMD_PASSWORD and RSPAMD_PASSWORD_ENC are defined, RSPAMD_PASSWORD will be used.

For RSPAMD_PASSWORD_ENC seems like encrypted password can be only generated using rspamadm and annoyingly in docker-compose.yml you must replace $ with $$, so start container first without a password and run:
```
docker exec container rspamadm pw -p password | sed  's/\$/$$/g'
```


## Ports
* 143 - IMAP, while STARTTLS is supported so is unencrypted connections so exposing this port is strongly advised against 
* 993 - IMAPS, encrypted, please use this
* 11334 - Rspamd controller and Web UI, at minimum set RSPAMD_PASSWORD or RSPAMD_PASSWORD_ENC environment variable but consided if this needs to be exposed at all

## Mounts
You should use volumes or bind mounts for all following folders:
* /config - Container is configured and can be customized by putting config to this folder
* /home/vmail - Contains mailboxes which you probably do want to backup as well 
* /var/lib/redis - Redis databases 
* /var/lib/rspamd - Rspamd static runtime data

# Configuration
All configuration (except what can be configured by using environment variables) should be put under /config (see Mounts above). We do use concept of virtual "users" for which mailboxes can be created and/or mail retrieval can be set up. In trivial case you would create one virtual user with mailbox and enable mail retrieval from external server. You could create multiple such users or you could create multiple users having mailboxes but only one user would retrieve mails and use rules to distribute messages to correct mailboxes. 

Container will read /config only on start and set up users, configs etc. so in case you want to modify config, restart the container. If no configuration has been added container will start with Dovecot running, but no mailboxes will be created nor mail will be retrieved.

## Users
Virtual users can be created by creating a folder under /config/users e.g. /config/users/user@example.com. In order to create mailbox for the user, create a file passwd under user's folder. In order to enable email retrieval for the user create a file fetchmailrc and for fdm create a file fdm.conf. 

### passwd
Create passwd file i.e. /config/users/user@example.com/passwd if you want to use mailbox for the user. This will create a new virtual user to Dovecot's password database with password read from the file. Password should be in format Dovecot understand, plain text but preferrably encrypted.

To use plain text password use {PLAIN} prefix (but please use encrypted password instead just for good measure):
```
{PLAIN}password
```

To use encrypted password no prefix is needed, use openssl to generate password:

```
$ openssl passwd -6
Password:
Verifying - Password:
$6$pu01GtapWT3f.i0N$Vf9Bu.JC8YpJB4hk/nN84v1/8mf4/vdR3vjBUX4TntllRP.2KHjHtvmQcbP8QlbWwylAT/KGFWZ62YKcfHp.w.
```

### fetchmailrc
### fdm.com





# FAQ
* Why fetchmail instead of just fdm doing fetch? Fdm does not support daemon mode nor IDLE.
* Why use Dovecot's delivery when fdm could do delivery by itself? Updates Dovecot's mailbox indexes during delivery. 

