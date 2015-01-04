#
# "fluentd" log-collector base by Luispa, Dec 2014
#
# -----------------------------------------------------
#
#

#
# Desde donde parto...
#
FROM debian:jessie

# Autor de este Dockerfile
#
MAINTAINER Luis Palacios <luis@luispa.com>

# Pido que el frontend de Debian no sea interactivo
ENV DEBIAN_FRONTEND noninteractive

# Actualizo el sistema operativo e instalo lo mínimo
#
RUN apt-get update && \
    apt-get -y install 	locales \
    					net-tools \
                       	vim \
                       	supervisor \
                       	wget \
                       	curl \
                       	tcpdump \
                        net-tools

# HOME
ENV HOME /root

# Preparo locales
#
RUN locale-gen es_ES.UTF-8
RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales

# Preparo el timezone para Madrid
#
RUN echo "Europe/Madrid" > /etc/timezone; dpkg-reconfigure -f noninteractive tzdata

# Instalo ruby
#		
RUN apt-get update && apt-get install -y -q build-essential \
											ruby \
											ruby-dev \
											libcurl4-openssl-dev

# Instalo fluentd
#
RUN gem install fluentd --no-ri --no-rdoc

# Instalo el plugin para enviar los datos a elasticsearch
#
RUN gem install fluent-plugin-elasticsearch --no-ri --no-rdoc

#-----------------------------------------------------------------------------------

# Ejecutar siempre al arrancar el contenedor este script
#
ADD do.sh /do.sh
RUN chmod +x /do.sh
ENTRYPOINT ["/do.sh"]

#
# Si no se especifica nada se ejecutará lo siguiente: 
#
CMD ["/usr/bin/supervisord", "-n -c /etc/supervisor/supervisord.conf"]

