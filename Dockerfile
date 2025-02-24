 # Start from Apline linux
FROM alpine:3.18

# Expose ports for imap, imaps and rspamd
EXPOSE 143
EXPOSE 993
EXPOSE 11334

# Add packages
RUN apk add --no-cache supervisor inetutils-syslogd dovecot redis rspamd rspamd-client fetchmail
RUN apk add --no-cache fdm --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community
RUN apk add --no-cache nmap inetutils-telnet nano

# Copy application files to /app
COPY ./app /app

# Run init script
CMD ["sh", "/app/init.sh"]
