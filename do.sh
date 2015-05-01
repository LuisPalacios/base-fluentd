#!/bin/bash
#
# Punto de entrada para el servicio fluentd
#
# Activar el debug de este script:
# set -eux
#

##################################################################
#
# main
#
##################################################################

# Averiguar si necesito configurar Postfix por primera vez
#
CONFIG_DONE="/.config_fluentd_done"
NECESITA_PRIMER_CONFIG="si"
if [ -f ${CONFIG_DONE} ] ; then
    NECESITA_PRIMER_CONFIG="no"
fi

##################################################################
#
# PREPARAR timezone
#
##################################################################
# Workaround para el Timezone, en vez de montar el fichero en modo read-only:
# 1) En el DOCKERFILE
#    RUN mkdir -p /config/tz && mv /etc/timezone /config/tz/ && ln -s /config/tz/timezone /etc/
# 2) En el Script entrypoint:
if [ -d '/config/tz' ]; then
    dpkg-reconfigure -f noninteractive tzdata
    echo "Hora actual: `date`"
fi
# 3) Al arrancar el contenedor, montar el volumen, a contiuación un ejemplo:
#     /Apps/data/tz:/config/tz
# 4) Localizar la configuración:
#     echo "Europe/Madrid" > /Apps/data/tz/timezone

##################################################################
#
# VARIABLES AUTOMÁTICAS
#
##################################################################

## Variables para conectar con ElasticSearch
if [ -z "${ESKIBANA_PORT_9200_TCP}" ]; then
	echo >&2 "error: falta la variable ESKIBANA_PORT_9200_TCP"
	echo >&2 "  Olvidaste --link un_contenedor_eskibana:eskibana ?"
	exit 1
fi
eskibanaLink="${ESKIBANA_PORT_9200_TCP#tcp://}"
eskibanaHost=${eskibanaLink%%:*}
eskibanaPort=${eskibanaLink##*:}


##################################################################
#
# VARIABLES OBLIGATORIAS
#
##################################################################

## Puerto en el que escucha Fluentd
#
if [ -z "${FLUENTD_PORT}" ]; then
	echo >&2 "error: falta el puerto en el que escucha fluentd, variable: FLUENTD_PORT"
	exit 1
fi


##################################################################
#
# PREPARAR EL CONTAINER POR PRIMERA VEZ
#
##################################################################

# Necesito configurar por primera vez?
#
if [ ${NECESITA_PRIMER_CONFIG} = "si" ] ; then

	############
	#
	# Supervisor
	# 
	############
	cat > /etc/supervisor/conf.d/supervisord.conf <<EOF
[unix_http_server]
file=/var/run/supervisor.sock 					; path to your socket file

[inet_http_server]
port = 0.0.0.0:9001								; allow to connect from web browser to supervisord

[supervisord]
logfile=/var/log/supervisor/supervisord.log 	; supervisord log file
logfile_maxbytes=50MB 							; maximum size of logfile before rotation
logfile_backups=10 								; number of backed up logfiles
loglevel=error 									; info, debug, warn, trace
pidfile=/var/run/supervisord.pid 				; pidfile location
minfds=1024 									; number of startup file descriptors
minprocs=200 									; number of process descriptors
user=root 										; default user
childlogdir=/var/log/supervisor/ 				; where child log files will live

nodaemon=false 									; run supervisord as a daemon when debugging
;nodaemon=true 									; run supervisord interactively (production)
 
[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface
 
[supervisorctl]
serverurl=unix:///var/run/supervisor.sock		; use a unix:// URL for a unix socket 

[program:fluentd]
command = /usr/local/bin/fluentd --conf=/etc/fluent/fluent.conf

#### exec /usr/local/bin/fluentd -c /etc/fluent.conf -vv >>/var/log/fluentd.log 2>&1

EOF

	mkdir /etc/fluent
	cat > /etc/fluent/fluent.conf <<EOFLUENTD
<source>
  type syslog
  port ${FLUENTD_PORT}
  protocol_type tcp
  tag  rsyslog
</source>

<match rsyslog.**>
  type copy
  <store>
    # for debug (see /var/log/td-agent.log)
    type stdout
  </store>
  <store>
    type elasticsearch
    logstash_format true
    flush_interval 10s # for testing.
    host ${eskibanaHost}
    port ${eskibanaPort}
  </store>
</match>
EOFLUENTD


    #
    # Creo el fichero de control para que el resto de 
    # ejecuciones no realice la primera configuración
    > ${CONFIG_DONE}

fi

##################################################################
#
# EJECUCIÓN DEL COMANDO SOLICITADO
#
##################################################################
#
exec "$@"
