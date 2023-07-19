FROM ubuntu/bind9:9.18-22.04_beta
MAINTAINER HammerBear hammerbear@tunnelbear.com

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y bind9

# config files
ADD ./named.conf.local /etc/bind/named.conf.local
ADD ./named.conf.options /etc/bind/named.conf.options
ADD ./tunnelbear.server /etc/bind/tunnelbear.server

# lock and load baby
ENTRYPOINT /usr/sbin/named -f -u bind
EXPOSE 53
