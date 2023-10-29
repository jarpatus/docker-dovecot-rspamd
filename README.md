# Mail server with spam filtering
This is docker image for self hosting an IMAP mail server pulling emails from external IMAP or POP3 mail server. Multiple local and remote mailboxes are supported as are spam and rule based filtering. It is possible in example to pull messages from one mailbox at remote server and write them to multiple local mailboxes and/or folders. 

Please notice that this image does NOT have a SMTP server so container cannot receive or send out emails, only pulling is possible. This is by design and won't change as self hosting a SMTP server is too hairy business nowadays. You need external IMAP or POP3 and SMTP from your ISP or from service provider you choose.

Goals of this image is to allow:
  - Better spam filtering than your own service provider can offer
  - Better handling of email aliases, forwards etc. as you can use rules to sort messages to multiple local mailboxes
  - Easier backups as you now can backup your emails like you backup yor other docker containers
  - Taking back control of your own emails

# Disclaimer
As we are pulling and potentially deleting emails from remote server, loss of emails is very much possible in case of misconfiguration and/or bugs. If you value your mails please at least configure fetchmail not to delete messages from remote server (use keep keyword) and preferrably also configure remote server to keep copies of messages and still understand that you are at risk. Under no circumstances nobody else than you can be held reponsible of data loss. If you do not accept then please do not use this image.

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
      RSPAMD_PASSWORD_ENC: $$2$$rhpb4naqycoshygfpe6b48wwejiakk3w$$zhf6bbeo4djibusp9zx7aahym8sim8dx41byyizc3kspr48wdb9y 
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
* ```RSPAMD_PASSWORD``` - Plain text password for Rspamd controller (use encrypted instead for good measure).
* ```RSPAMD_PASSWORD_ENC``` - Ecnrypted password for Rspamd controller.

For ```RSPAMD_PASSWORD_ENC``` seems like encrypted password can be only generated using rspamadm and annoyingly in docker-compose.yml you must replace $ with $$, so start container first without a password and run:
```
$ docker exec container rspamadm pw -p password | sed  's/\$/$$/g'
$$2$$rhpb4naqycoshygfpe6b48wwejiakk3w$$zhf6bbeo4djibusp9zx7aahym8sim8dx41byyizc3kspr48wdb9y
```

## Ports
* ```143``` - IMAP, while STARTTLS is supported so is unencrypted connections so exposing this port is strongly advised against 
* ```993``` - IMAPS, encrypted, please use this
* ```11334``` - Rspamd controller and Web UI, at minimum set RSPAMD_PASSWORD or RSPAMD_PASSWORD_ENC environment variable but consided if this needs to be exposed at all

## Mounts
You should use volumes or bind mounts for all following folders:
* ```/config``` - Container is configured and can be customized by putting config to this folder
* ```/home/vmail``` - Contains mailboxes which you probably do want to backup as well 
* ```/var/lib/redis```- Redis databases 
* ```/var/lib/rspamd``` - Rspamd static runtime data

# Configuration
All configuration (except what can be configured by using environment variables) should be put under ```/config``` (see Mounts above). We do use concept of virtual "users" for which mailboxes can be created and/or mail retrieval can be set up. In trivial case you would create one virtual user with mailbox and enable mail retrieval from external server for the same user. You could create multiple such users or you could create multiple users having mailboxes but only one user (with or without mailbox) would retrieve mails and use rules to distribute messages to correct mailboxes. 

Container will read ```/config``` only on start and set up users, configs etc. so in case you want to modify config, restart the container. If no configuration has been added container will start with Dovecot running, but no mailboxes will be created nor mail will be retrieved.

Additionally it is possible to put files to /config/etc which will be copied over /etc on container start. This would allow customizing config of daemons even further.

## Users
Virtual users can be created by creating a folder under ```/config/users``` e.g. ```/config/users/user@example.com```. In order to create mailbox for the user, create a file passwd under user's folder. In order to enable email retrieval for the user create a file fetchmailrc and for fdm create a file fdm.conf. 

### passwd
Create passwd file i.e. ```/config/users/user@example.com/passwd``` if you want to use mailbox for the user. This will create a new virtual user to Dovecot's password database with password read from the file. Password should be in format Dovecot understand, plain text but preferrably encrypted.

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
Create fetchmail configuration file fetchmailrc i.e. ```/config/users/user@example.com/fetchmailrc``` if you want to use mail retrieval for the user. This will setup a new instance of daemonized fetchmail for the user based on conifguration file. Configure as you would normally configure fetchmailrc, but:

* Strongly consider using keep keyword (does not delete mails from external server, see Disclaimer)
* Using idle keyword is nice and will enable near instant delivery
* Use ```/usr/libexec/dovecot/deliver``` as mda as it updates Dovecot's index during delivery
* For spam detection use ```rspamc --mime | /usr/libexec/dovecot/deliver``` as mda 
* For spam detection and rule based filtering use ```rspamc --mime | /usr/bin/fdm -a stdin -f ~/fdm.conf -l -m -v fetch``` as mda and setup fdm to use ```/usr/libexec/dovecot/deliver``` 

#### Examples
Pull from IMAP server and deliver directly to mailbox user@example.com. Keep messages and use IDLE. Notice that it is possible to make delivery to another user's mailbox but that would be a bit misconfiguration unless you use this user only for mail retrieval and have another user for mailbox.  

```
poll mail.example.com protocol IMAP port 993
      user 'user@example.com' there with ssl with password 'password' folder 'INBOX' idle ssl keep
      mda "/usr/libexec/dovecot/deliver -d user@example.com"
```

Pull from IMAP server, run spam detection and deliver directly to mailbox user@example.com. Keep messages and use IDLE. Notice that this will add new spam related headers to the message, but does not actually filter anything unless you do some client side filtering. Also notice that it is possible to make delivery to another user's mailbox but that would be a bit misconfiguration unless you use this user only for mail retrieval and have another user for mailbox.

```
poll mail.example.com protocol IMAP port 993
      user 'user@example.com' there with ssl with password 'password' folder 'INBOX' idle ssl keep
      mda "rspamc --mime | /usr/libexec/dovecot/deliver -d user@example.com"
```

Pull from IMAP server, run spam detection and use fdm for rule based filtering. Keep messages and use IDLE. You also need to set up fdm by using ```fdm.conf```.

```
poll mail.example.com protocol IMAP port 993
      user 'user@example.com' there with ssl with password 'password' folder 'INBOX' idle ssl keep
      mda "rspamc --mime | /usr/bin/fdm -a stdin -f ~/fdm.conf -l -m -v fetch"
```


### fdm.conf
If you use fdm as mda in fetchmailrc, you need to set up fdm.conf. Configure as you would configure fdm, but:

* Create only stdin account, do not make fdm to actually fetch emails from anywhere.  
* Create pipe action(s) for mail delivery and use ```/usr/libexec/dovecot/deliver -d mailbox``` as command

You can create as complex configurations as you wish, deliver mails to multiple mailboxes and folders based on headers or whatever, make copies (archive) of messages, handle aliases, forwards, distribution lists etc. How cool is that? 

#### Examples
Deliver mails to two different mailboxes based on rules and make copies of messages. By default deliver messages to mailbox ```user@example.com``` but in case of ```Delivered-To: alias@example.com``` found from headers deliver to mailbox ```alias@example.com``` instead. Creates copies of messages to Received folder of choosen mailbox. 

```
account "stdin" disabled stdin
action "alias@example.com" pipe "/usr/libexec/dovecot/deliver -d alias@example.com"
action "alias@example.com:Received" pipe "/usr/libexec/dovecot/deliver -d alias@example.com -m Received"
action "user@example.com" pipe "/usr/libexec/dovecot/deliver -d user@example.com"
action "user@example.com:Received" pipe "/usr/libexec/dovecot/deliver -d user@example.com -m Received"
match "^Delivered-To: alias@example.com" in headers action { "alias@example.com" "alias@example.com:Received" }
match all action { "user@example.com" "user@example.com:Received" }
```

# SSL
By default we use self signed certificate for IMAPS thus your mail client will complain about it. On container re-creation certificates will be regenerated so your mail client will complain even more. You could create your own SSL certificates and place them to /config/etc/ssl/dovecot using names server.key and server.pem.

# Security considerations
Make sure that container configuration and data cannot be read by outsiders. If you just do ```mkdir container``` and use bind mounts, your container config and data actually could be world readable. In worst case your emails are world readable (on container start we try to chmod relevant folders and files to not be world readable but in case of bug or something something may leak, so take good care of permissions by yourself). 

Use encrypted passwords instead of plain text ones when configuring container. Even if permissions are set up properly, it's a good thing never to store plain text passwords.

Mails, config, etc. is not encrypted in container so make sure that if you back them up, you will encrypt them. 

As usual, all users in docker group can control your container and thus read your mail. 

Consider what ports you expose and especially consider what you expose to the Internet. If you want to access your mail from the Internet i.e. using mobile devices or so, consider using VPN instead of opening ports to your internal network.

# Backups 
Backup your volumes or bind mounts as usual. To backup Redis database run following command before backup to make Redis to write database to disk.
```
docker exec container redis-cli save
```

Consider your data as backed up only after you have tried to restore everything from backups...

# FAQ
* Why fetchmail instead of just fdm doing fetch? Fdm does not support daemon mode nor IDLE.
* Why use Dovecot's delivery when fdm could do delivery by itself? Updates Dovecot's mailbox indexes during delivery leading to better performance. 
* Why manual creation of conf files, why no environment variables? Realistically speaking supporting complex use cases using environment variables whould be total nightmare both for users and me...

