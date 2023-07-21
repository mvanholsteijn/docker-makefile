FROM ubuntu:jammy

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python-is-python3
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python3-pip
RUN pip install Jinja2

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y bind9

ARG NAME
WORKDIR /workdir

COPY ${NAME}/config.py /workdir
COPY repos/opscode/playbooks/roles/bind/templates/etc/bind/named.conf.local.j2 /workdir

RUN mkdir -p /etc/bind
RUN python /workdir/config.py named.conf.local.j2 /etc/bind/named.conf.local

# config files
# ADD etc/bind/named.conf.local /etc/bind/named.conf.local
ADD repos/opscode/playbooks/roles/bind/files/etc/bind/named.conf.options /etc/bind/named.conf.options
ADD repos/opscode/playbooks/roles/bind/files/etc/bind/tunnelbear.server /etc/bind/tunnelbear.server
ADD repos/opscode/playbooks/roles/bind/files/etc/bind/mcafee.lazerpenguin.com /etc/bind/mcafee.lazerpenguin.com

# lock and load baby
ENTRYPOINT /usr/sbin/named -f -u bind
EXPOSE 53
