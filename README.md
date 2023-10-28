# Mail server with spam filtering
This is docker image for self hosting an IMAP mail server pulling emails from external IMAP or POP3 mail server. Multiple local and remote accounts are supported as are spam and rule based filtering. It is possible in example to pull emails from one account at remote server and write them to multiple local IMAP accounts and/or folders based on given rules. 

Please notice that this image does NOT have a SMTP server so container cannot receive emails or send emails out, only pulling is possible. This is by design and won't change as self hosting a SMTP server is too hairy business nowadays. You need external IMAP or POP3 and SMTP from your ISP or from service provider you choose.

Goals of this image is to allow:
  - Better spam filtering than your own service provider does
  - Easier backups as you now can backup your mails like you backup yor other docker containers
  - Better handling of mail aliases, mail forwards etc. as you can use rules to  
