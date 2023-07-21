FROM ubuntu:jammy

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python-is-python3
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python3-pip
RUN pip install Jinja2

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y gunicorn

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 libapache2-mod-fcgid
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y php-fpm

ARG NAME
WORKDIR /workdir

COPY ${NAME}/config.py /workdir
COPY repos/opscode/playbooks/roles/jdauphant.nginx/templates/nginx.conf.j2 /workdir

RUN mkdir -p /etc/nginx
RUN python /workdir/config.py nginx.conf.j2 /etc/nginx/nginx.conf

# ENTRYPOINT php5 fpm nginx
EXPOSE 443
