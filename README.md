# Introducción

Este repositorio alberga un *contenedor Docker* para "[Fluentd](http://www.fluentd.org/)". Lo tienes automatizado en el registry hub de Docker [luispa/base-fluentd](https://registry.hub.docker.com/u/luispa/base-fluentd/) con los fuentes en GitHub: [base-fluentd](https://github.com/LuisPalacios/base-fluentd). Lo uso en combinación con el contenedor [luispa/base-eskibana](https://registry.hub.docker.com/u/luispa/base-eskibana/), con los fuentes en GitHub: [GitHub: base-fluentd](https://github.com/LuisPalacios/base-eskibana)

La combinación de fluentd + elasticsearch + kibana permite unificar, almacenar y visualizar todos los log's de todos mis contenedores docker en mi equipo linux en un único sitio.

[Fluentd](http://www.fluentd.org/) es un recolector que unifica "logs", proyecto open source que permite aunar colecciones de datos y que sean consumidos de forma centralizada para poder entender mejor los datos. 

[Elasticsearch](http://www.elasticsearch.org/) es un motor de búsqueda (una base de datos para que nos entendamos), también es un proyecto opensource que es muy conocido por su sencillez de uso. 

[Kibana](http://www.elasticsearch.org/overview/kibana/) es un interfaz de usuario Web que permite realizar búsquedas más amigables en elasticsearch. 

Al combinar las tres herramientas (Fluentd + Elasticsearch + Kibana) conseguimos un sistema escalable, sencillo y flexible que agrega los logs en un motor de búsqueda que puede ser consumido de forma sencilla desde la web. En mi caso he decidido separar las tres herramientas en dos contenedores, uno con fluentd y el otro con elasticsearch y kibana.

Consulta este [apunte técnico sobre varios servicios en contenedores Docker](http://www.luispa.com/?p=172) para acceder a otros contenedores Docker y sus fuentes en GitHub.

## Ficheros

* **Dockerfile**: Para crear la base de servicio.
* **do.sh**: Para arrancar el contenedor creado con esta imagen.

## Instalación de la imagen

### desde Docker

Para usar esta imagen desde el registry de docker hub

    totobo ~ $ docker pull luispa/base-fluentd

### manualmente

Si prefieres crear la imagen de forma manual en tu sistema, primero debes clonarla desde Github para luego ejecutar el build

    $ git clone https://github.com/LuisPalacios/base-fluentd.git
    $ docker build -t luispa/base-fluentd ./



# Ejecución

## Arrancar manualmente

Puedes ejecutar "manulamente" el contenedor, es decir, de forma interactiva, que es muy útil para hacer pruebas. Aquí te dejo un "ejemplo":

	  docker run -t -i -e FLUENTD_PORT=24224 -p 24224:24224 --name fluentd_1 --link eskibana_1:eskibana luispa/base-fluentd /bin/bash
	 

## Arrancar con "fig"

Si por el contrario prefieres automatizarlo con el programa [fig](http://www.fig.sh/index.html) y que arranquen ambos contenedores, el de fluentd y el de elasticsearch+kibana, te recomiendo que eches un ojo al [servicio-log](https://github.com/LuisPalacios/servicio-log) que he dejado en GitHub.


# Personalización

## Variables de entorno


### Variable: FLUENTD_PORT

Puerto por el que escuchará fluentd en este contenedor. Cuando configuremos rsyslogd (o cualquier otro gestor de logs) en los contenedores remotos que quieran enviarme sus logs, tenemos que darles este puerto como el de destino. 

## Links

Cuando arranques el contenedor fluentd es necesario que le indiques mediante --link (o links: en fig.yml) cual es el contenedor donde se ejecuta elasticsearch+kibana. 

