FROM python:3

# RUN apt-get update
# RUN apt-get install python3.6
# RUN apt-get install pip

RUN pip install Jinja2
# RUN apt-get install -y nginx
# RUN apt-get install -y  gunicorn
# RUN apt-get install -y  php5-fpm

ARG NAME

WORKDIR /workdir

COPY ${NAME}/config.py /workdir
COPY repos/opscode/playbooks/roles/jdauphant.nginx/templates/nginx.conf.j2 /workdir

RUN mkdir -p /etc/nginx
RUN python /workdir/config.py nginx.conf.j2 /etc/nginx/nginx.conf

# ENTRYPOINT php5 fpm nginx
EXPOSE 443
