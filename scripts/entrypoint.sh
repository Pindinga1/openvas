#!/bin/bash

# Init Redis
echo "Iniciando Redis..."
sudo -u gvm redis-server /etc/redis/redis-openvas.conf --daemonize yes

# Wait redis 
until sudo -u gvm redis-cli -s /run/redis-openvas/redis.sock ping > /dev/null 2>&1; do
    echo "Esperando a que Redis esté listo..."
    sleep 1
done
echo "Redis está listo."

# Init PostgreSQL
echo "Iniciando PostgreSQL..."
sudo service postgresql start

# Esperar a que PostgreSQL esté listo
until pg_isready -h localhost -p 5432 > /dev/null 2>&1; do
    echo "Esperando a que PostgreSQL esté listo..."
    sleep 1
done
echo "PostgreSQL está listo."

# Iniciar OSPD-OPENVAS
echo "Iniciando OSPD-OPENVAS..."
sudo -u gvm /usr/local/bin/ospd-openvas --foreground --unix-socket /run/ospd/ospd-openvas.sock --pid-file /run/ospd/ospd-openvas.pid --log-file /var/log/gvm/ospd-openvas.log --lock-file-dir /var/lib/openvas --socket-mode 0o770 --notus-feed-dir /var/lib/notus/advisories &

# Esperar a que OSPD-OPENVAS esté listo
until [ -S /run/ospd/ospd-openvas.sock ] && pgrep -f ospd-openvas > /dev/null; do
    echo "Esperando a que OSPD-OPENVAS esté listo..."
    sleep 1
done
echo "OSPD-OPENVAS está listo."

# Iniciar GVMD
echo "Iniciando GVMD..."
/usr/local/sbin/gvmd --foreground --osp-vt-update=/run/ospd/ospd-openvas.sock --listen-group=gvm &

# Esperar a que GVMD esté listo
until pgrep -f gvmd > /dev/null; do
    echo "Esperando a que GVMD esté listo..."
    sleep 1
done
echo "GVMD está corriendo."

if [ ! -z "${OPENVAS_PASSWORD}" ]; then
    echo "Usando clave definida por el usuario..."
    /usr/local/sbin/gvmd --user=admin --new-password=${OPENVAS_PASSWORD}
else
    echo "Clave no definida por usuario, se usa por default."
    sleep 2
fi

# Iniciar GSAD
echo "Iniciando GSAD..."
/usr/local/sbin/gsad --foreground --listen=0.0.0.0 --port=9392 --http-only &

# Esperar a que GSAD esté listo
until curl -s --output /dev/null --silent --head http://127.0.0.1:9392; do
    echo "Esperando a que GSAD esté listo..."
    sleep 1
done
echo "GSAD está listo."

# Iniciar OPENVASD
echo "Iniciando OPENVASD..."
/usr/local/bin/openvasd --mode service_notus --products /var/lib/notus/products --advisories /var/lib/notus/advisories --listening 0.0.0.0:3000 &

# Esperar a que OPENVASD esté listo
until curl -s --output /dev/null --silent --head http://127.0.0.1:3000; do
    echo "Esperando a que OPENVASD esté listo..."
    sleep 1
done
echo "OPENVASD está listo."

# Verificar que los servicios están corriendo
echo "Verificando servicios..."
ps aux | grep -E "ospd-openvas|gvmd|gsad|openvasd|redis-server|postgres" | grep -v grep

# Mantener el contenedor activo
tail -f /var/log/gvm/ospd-openvas.log