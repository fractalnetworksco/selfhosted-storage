FROM alpine

# install openssh and borgbackup
RUN apk add openssh-server borgbackup 
RUN ssh-keygen -A; adduser --disabled-password borg; 
RUN mkdir /home/borg/.ssh; chown borg:borg /home/borg/.ssh; chmod 700 /home/borg/.ssh;

COPY authorized_keys /home/borg/.ssh/authorized_keys

RUN chown borg:borg /home/borg/.ssh/authorized_keys; chmod 600 /home/borg/.ssh/authorized_keys;

# Configure SSH server
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
  && echo "AllowUsers borg" >> /etc/ssh/sshd_config

# Allow login with ssh key only, set impossible password
# https://arlimus.github.io/articles/usepam/
RUN sed -i 's/borg:!:/borg:*:/' /etc/shadow

# entrypoint
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

