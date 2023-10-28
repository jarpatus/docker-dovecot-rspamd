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
