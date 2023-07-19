FROM nginx
COPY nginx.conf /etc/nginx/nginx.conf

RUN apt install gunicorn
RUN apt install php5-fpm

ENTRYPOINT php5 fpm nginx
EXPOSE 443
