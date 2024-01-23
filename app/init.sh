#!/bin/sh
#
# (Re-)initializes container on start based on config. Notice that we may seem
# to do unnecessary or stupid things here e.g. copying files back and forth and
# chmod and chown them, but purpose is to setup everything properly in case of
# bind mounts without need to adjust access rights on source files.
#
# We also copy files to /etc on every start which may seem odd but we want to
# support custom config being added without container rebuild.
#
# In hindsight, not sure if this is totally stupid so let me know...
#
DOVECOTUSER=dovecot
FETCHMAILUSER=vmail
MAILUSER=vmail

addUser()
{
  CONFDIR=$1
  USER=`basename $1`
  SAFEUSER=`echo -n $USER | tr -c '[:alnum:]' '_'`

  if [ -f $CONFDIR/fetchmailrc ]
  then
    echo Configure supervisor for $USER
    echo "[program:fetchmail_$SAFEUSER]" > /etc/supervisor/conf.d/$USER.conf
    echo "command=/usr/bin/fetchmail --daemon 600 --nodetach --syslog" >> /etc/supervisor/conf.d/$USER.conf
    echo "user=$FETCHMAILUSER" >> /etc/supervisor/conf.d/$USER.conf
    echo "environment=FETCHMAILHOME=\"/run/fetchmail/$USER\",HOME=\"/run/fetchmail/$USER\",USER=\"$MAILUSER\"" >> /etc/supervisor/conf.d/$USER.conf
    echo "stdout_logfile=/dev/stdout" >> /etc/supervisor/conf.d/$USER.conf
    echo "stderr_logfile=/dev/stderr" >> /etc/supervisor/conf.d/$USER.conf
    echo "stdout_logfile_maxbytes=0" >> /etc/supervisor/conf.d/$USER.conf
    echo "stderr_logfile_maxbytes=0" >> /etc/supervisor/conf.d/$USER.conf
    ls -l /etc/supervisor/conf.d/$USER.conf
  fi

  if [ -f $CONFDIR/passwd ]
  then
    echo Configure dovecot for $USER
    PASS=`cat $CONFDIR/passwd | xargs`
    echo $USER:$PASS:::::: >> /etc/dovecot/passwd
    chmod 0600 /etc/dovecot/passwd
    chown $DOVECOTUSER:$DOVECOTUSER /etc/dovecot/passwd
    ls -l /etc/dovecot/passwd
  fi

  if [ -f $CONFDIR/fetchmailrc ]
  then
    echo Configure fetchmail for $USER
    mkdir -p /run/fetchmail/$USER
    cp $CONFDIR/fetchmailrc /run/fetchmail/$USER/fetchmailrc
    chmod 0600 /run/fetchmail/$USER/fetchmailrc
    chown -R $FETCHMAILUSER:$FETCHMAILUSER /run/fetchmail/$USER
    ls -ld /run/fetchmail/$USER
    ls -l /run/fetchmail/$USER/fetchmailrc
  fi

  if [ -f $CONFDIR/fdm.conf ]
  then
    echo Configure fdm for $USER
    mkdir -p /run/fetchmail/$USER
    cp $CONFDIR/fdm.conf /run/fetchmail/$USER/fdm.conf
    chmod 0600 /run/fetchmail/$USER/fdm.conf
    chown -R $FETCHMAILUSER:$FETCHMAILUSER /run/fetchmail/$USER
    ls -ld /run/fetchmail/$USER
    ls -l /run/fetchmail/$USER/fdm.conf
  fi

}

# Apply app config
cp -dRv /app/etc /

# Apply custom config
if [ -d /config/etc ]; then cp -dRv /config/etc /; fi

# Setup dovecot
if ! grep -q "$MAILUSER"; then
  adduser -D -s /sbin/nologin "$MAILUSER"
fi
chmod 2750 /home/$MAILUSER
chown $MAILUSER:$MAILUSER /home/$MAILUSER
echo -n > /etc/dovecot/passwd

# Setup redis
if ! grep -q "include /etc/redis.conf.d/" /etc/redis.conf; then
  echo -e "\ninclude /etc/redis.conf.d/*.conf" >> /etc/redis.conf
fi
chown redis:redis /var/lib/redis

# Setup rspamd
if [ ! -z $RSPAMD_PASSWORD ]; then
  RSPAMD_PASSWORD_ENC=`rspamadm pw -p $RSPAMD_PASSWORD`
fi
if [ ! -z $RSPAMD_PASSWORD_ENC ]; then
  echo "password = \"$RSPAMD_PASSWORD_ENC\"" >> /etc/rspamd/local.d/worker-controller.inc
fi
mkdir -p /run/rspamd
chmod 0750 /var/lib/rspamd
chown rspamd:rspamd /run/rspamd /var/lib/rspamd
addgroup rspamd redis

# Setup users
for d in /config/users/*/; do addUser $d; done

# Exec supervisor
exec supervisord -c /etc/supervisor/supervisord.conf
