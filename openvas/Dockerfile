# Usamos debian12 como base, según la documentación
FROM debian:12 AS build
#PASO 0:
ENV DEBIAN_FRONTEND=noninteractive

# Paso 2: Ruta donde quedará todo el software ya compilado
ENV INSTALL_PREFIX=/usr/local
ENV PATH=$PATH:$INSTALL_PREFIX/sbin

# Paso 3: Ruta donde quedarán todos los archivos de compilación y instalación
ENV SOURCE_DIR=/tmp/source
RUN mkdir -p $SOURCE_DIR

#Paso 4: Directorio donde se compilaran los binarios
ENV BUILD_DIR=/tmp/build
RUN mkdir -p $BUILD_DIR

# Paso 5: directorio de instalación temporal antes de mover todo al destino final
ENV INSTALL_DIR=/tmp/install
RUN mkdir -p $INSTALL_DIR

RUN apt-get update && apt-get install -y tzdata \
    && echo "America/New_York" > /etc/timezone \ 
    && dpkg-reconfigure -f noninteractive tzdata

# Paso 7: Instalamos dependencias específicas para cada componente
RUN apt-get update &&  apt-get install -y \
    # Dependencias para gvm-libs
    sudo \
    libcjson-dev \
    wget \
    build-essential \
    gnupg \
    cmake \
    curl \
    libcurl4-gnutls-dev \
    libgcrypt-dev \
    libglib2.0-dev \
    libgnutls28-dev \
    libgpgme-dev \
    libhiredis-dev \
    libnet1-dev \
    libpaho-mqtt-dev \
    libpcap-dev \
    libssh-dev \
    libxml2-dev \
    uuid-dev \
    # Dependencias para gvmd
    libbsd-dev \
    libical-dev \
    libpq-dev \
    postgresql-server-dev-all \
    rsync \
    xsltproc \
    # Dependencias para pg-gvm (ya incluidas en gvmd, no duplicamos) \
    # Dependencias para gsad
    libbrotli-dev \
    libmicrohttpd-dev \
    # Dependencias para openvas-smb
    gcc-mingw-w64 \
    libpopt-dev \
    libunistring-dev \
    heimdal-multidev \
    perl-base \
    # Dependencias para openvas-scanner
    bison \
    libksba-dev \
    nmap \
    libjson-glib-dev \
    krb5-multidev \
    # Dependencias para ospd-openvas
    python3 \
    python3-pip \
    python3-setuptools \
    python3-packaging \
    python3-wrapt \
    python3-cffi \
    python3-psutil \
    python3-lxml \
    python3-defusedxml \
    python3-paramiko \
    python3-redis \
    python3-gnupg \
    python3-paho-mqtt \
    # Dependencias para openvasd
    pkg-config \
    libssl-dev \
    # Dependencias para greenbone-feed-sync (solo python3 y pip, ya incluidas) \
    # Dependencias para gvm-tools (mayoría ya incluidas en ospd-openvas, añadimos las específicas)
    python3-venv \
    && apt-get clean

#UPDATE CARGO
RUN apt-get update && apt-get install -y curl build-essential \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && . $HOME/.cargo/env \
    && rustup update

#Paso 8 GVM LIBS
ENV GVM_LIBS_VERSION=22.18.0
RUN curl -f -L https://github.com/greenbone/gvm-libs/archive/refs/tags/v$GVM_LIBS_VERSION.tar.gz -o $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION.tar.gz \
    && mkdir -p $BUILD_DIR/gvm-libs \
    && tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION.tar.gz \
    && cmake \
	  -S $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION \
	  -B $BUILD_DIR/gvm-libs \
	  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
	  -DCMAKE_BUILD_TYPE=Release \
	  -DSYSCONFDIR=/etc \
	  -DLOCALSTATEDIR=/var \
	&& cmake --build $BUILD_DIR/gvm-libs -j$(nproc) \
	&& mkdir -p $INSTALL_DIR/gvm-libs && cd $BUILD_DIR/gvm-libs \
	&& make DESTDIR=$INSTALL_DIR/gvm-libs install \
	&& cp -rv $INSTALL_DIR/gvm-libs/* /

RUN ldconfig

#Paso 9 GVMD
ENV GVMD_VERSION=25.1.1
RUN curl -f -L https://github.com/greenbone/gvmd/archive/refs/tags/v$GVMD_VERSION.tar.gz -o $SOURCE_DIR/gvmd-$GVMD_VERSION.tar.gz \
    && tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/gvmd-$GVMD_VERSION.tar.gz \
    && mkdir -p $BUILD_DIR/gvmd \
	&& cmake \
	  -S $SOURCE_DIR/gvmd-$GVMD_VERSION \
	  -B $BUILD_DIR/gvmd \
	  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
	  -DCMAKE_BUILD_TYPE=Release \
	  -DLOCALSTATEDIR=/var \
	  -DSYSCONFDIR=/etc \
	  -DGVM_DATA_DIR=/var \
	  -DGVM_LOG_DIR=/var/log/gvm \
	  -DGVMD_RUN_DIR=/run/gvmd \
	  -DOPENVAS_DEFAULT_SOCKET=/run/ospd/ospd-openvas.sock \
	  -DGVM_FEED_LOCK_PATH=/var/lib/gvm/feed-update.lock \
	  -DLOGROTATE_DIR=/etc/logrotate.d \
	&& cmake --build $BUILD_DIR/gvmd -j$(nproc) \
	&& mkdir -p $INSTALL_DIR/gvmd && cd $BUILD_DIR/gvmd \
	&& make DESTDIR=$INSTALL_DIR/gvmd install \
    && cp -rv $INSTALL_DIR/gvmd/* /


#Paso 10 PG-GVM
ENV PG_GVM_VERSION=22.6.7
RUN curl -f -L https://github.com/greenbone/pg-gvm/archive/refs/tags/v$PG_GVM_VERSION.tar.gz -o $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION.tar.gz \
    && tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION.tar.gz \
    && mkdir -p $BUILD_DIR/pg-gvm \
    && cmake \
	  -S $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION \
	  -B $BUILD_DIR/pg-gvm \
	  -DCMAKE_BUILD_TYPE=Release \
	&& cmake --build $BUILD_DIR/pg-gvm -j$(nproc) \
	&& mkdir -p $INSTALL_DIR/pg-gvm && cd $BUILD_DIR/pg-gvm \
	&& make DESTDIR=$INSTALL_DIR/pg-gvm install \
	&& cp -rv $INSTALL_DIR/pg-gvm/* /

#Paso 11 GSA
ENV GSA_VERSION=24.3.0
RUN curl -f -L https://github.com/greenbone/gsa/releases/download/v$GSA_VERSION/gsa-dist-$GSA_VERSION.tar.gz -o $SOURCE_DIR/gsa-$GSA_VERSION.tar.gz \
    && mkdir -p $SOURCE_DIR/gsa-$GSA_VERSION \
    && tar -C $SOURCE_DIR/gsa-$GSA_VERSION -xvzf $SOURCE_DIR/gsa-$GSA_VERSION.tar.gz \
    && mkdir -p $INSTALL_PREFIX/share/gvm/gsad/web/ \
    && cp -rv $SOURCE_DIR/gsa-$GSA_VERSION/* $INSTALL_PREFIX/share/gvm/gsad/web/

#PASO 12 GSAD
ENV GSAD_VERSION=24.2.2
RUN curl -f -L https://github.com/greenbone/gsad/archive/refs/tags/v$GSAD_VERSION.tar.gz -o $SOURCE_DIR/gsad-$GSAD_VERSION.tar.gz \
    && tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/gsad-$GSAD_VERSION.tar.gz \
    && mkdir -p $BUILD_DIR/gsad \
    && cmake \
	  -S $SOURCE_DIR/gsad-$GSAD_VERSION \
	  -B $BUILD_DIR/gsad \
	  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
	  -DCMAKE_BUILD_TYPE=Release \
	  -DSYSCONFDIR=/etc \
	  -DLOCALSTATEDIR=/var \
	  -DGVMD_RUN_DIR=/run/gvmd \
	  -DGSAD_RUN_DIR=/run/gsad \
	  -DGVM_LOG_DIR=/var/log/gvm \
	  -DLOGROTATE_DIR=/etc/logrotate.d \
	&& cmake --build $BUILD_DIR/gsad -j$(nproc) \
	&& mkdir -p $INSTALL_DIR/gsad && cd $BUILD_DIR/gsad \
	&& make DESTDIR=$INSTALL_DIR/gsad install \
	&& cp -rv $INSTALL_DIR/gsad/* / 

#PASO 13 OPENVAS-SMB
ENV OPENVAS_SMB_VERSION=22.5.3
RUN curl -f -L https://github.com/greenbone/openvas-smb/archive/refs/tags/v$OPENVAS_SMB_VERSION.tar.gz -o $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION.tar.gz \
    && tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION.tar.gz \
    && mkdir -p $BUILD_DIR/openvas-smb \
    && cmake \
	  -S $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION \
	  -B $BUILD_DIR/openvas-smb \
	  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
	  -DCMAKE_BUILD_TYPE=Release \
	&& cmake --build $BUILD_DIR/openvas-smb -j$(nproc) \
	&& mkdir -p $INSTALL_DIR/openvas-smb && cd $BUILD_DIR/openvas-smb \
	&& make DESTDIR=$INSTALL_DIR/openvas-smb install \
	&& cp -rv $INSTALL_DIR/openvas-smb/* /

#PASO 14 OPENVAS-SCANNER
ENV OPENVAS_SCANNER_VERSION=23.15.3
RUN curl -f -L https://github.com/greenbone/openvas-scanner/archive/refs/tags/v$OPENVAS_SCANNER_VERSION.tar.gz -o $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION.tar.gz \
    && tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION.tar.gz \
    && mkdir -p $BUILD_DIR/openvas-scanner \
    && cmake \
	  -S $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION \
	  -B $BUILD_DIR/openvas-scanner \
	  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
	  -DCMAKE_BUILD_TYPE=Release \
	  -DSYSCONFDIR=/etc \
	  -DLOCALSTATEDIR=/var \
	  -DOPENVAS_FEED_LOCK_PATH=/var/lib/openvas/feed-update.lock \
	  -DOPENVAS_RUN_DIR=/run/ospd \
	&& cmake --build $BUILD_DIR/openvas-scanner -j$(nproc) \
	&& mkdir -p $INSTALL_DIR/openvas-scanner && cd $BUILD_DIR/openvas-scanner \
	&& make DESTDIR=$INSTALL_DIR/openvas-scanner install \
	&& cp -rv $INSTALL_DIR/openvas-scanner/* / \
	&& printf "table_driven_lsc = yes\n" | sudo tee /etc/openvas/openvas.conf \
	&& printf "openvasd_server = http://127.0.0.1:3000\n" | sudo tee -a /etc/openvas/openvas.conf


# PASO 15 OSPD-OPENVAS
ENV OSPD_OPENVAS_VERSION=22.7.1
RUN curl -f -L https://github.com/greenbone/ospd-openvas/archive/refs/tags/v$OSPD_OPENVAS_VERSION.tar.gz -o $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION.tar.gz \
    && tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION.tar.gz \
    && cd $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION \
    && mkdir -p $INSTALL_DIR/ospd-openvas \
    && python3 -m pip install --root=$INSTALL_DIR/ospd-openvas --no-warn-script-location . \
    && cp -rv $INSTALL_DIR/ospd-openvas/* /


#PASO 16 OPENVASD
ENV OPENVAS_DAEMON=23.15.3
RUN curl -f -L https://github.com/greenbone/openvas-scanner/archive/refs/tags/v$OPENVAS_DAEMON.tar.gz -o $SOURCE_DIR/openvas-scanner-$OPENVAS_DAEMON.tar.gz \
    && tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/openvas-scanner-$OPENVAS_DAEMON.tar.gz \
    && mkdir -p $INSTALL_DIR/openvasd/usr/local/bin \
    && cd $SOURCE_DIR/openvas-scanner-$OPENVAS_DAEMON/rust/src/openvasd \
    && /root/.cargo/bin/cargo build --release \
    && cd $SOURCE_DIR/openvas-scanner-$OPENVAS_DAEMON/rust/src/scannerctl \
    && /root/.cargo/bin/cargo build --release \
    && sudo cp -v ../../target/release/openvasd $INSTALL_DIR/openvasd/usr/local/bin/ \
    && sudo cp -v ../../target/release/scannerctl $INSTALL_DIR/openvasd/usr/local/bin/ \
    && cp -rv $INSTALL_DIR/openvasd/* /


# PASO 17 GREENBONE SYNC FEED
RUN mkdir -p $INSTALL_DIR/greenbone-feed-sync \
    && python3 -m pip install --root=$INSTALL_DIR/greenbone-feed-sync --no-warn-script-location greenbone-feed-sync \
    && cp -rv $INSTALL_DIR/greenbone-feed-sync/* /


# PASO 18 GVM-TOOLS
RUN mkdir -p $INSTALL_DIR/gvm-tools \
    && python3 -m pip install --root=$INSTALL_DIR/gvm-tools --no-warn-script-location gvm-tools \
    && cp -rv $INSTALL_DIR/gvm-tools/* /

RUN useradd -r -M -U -G sudo -s /bin/bash gvm \
    && echo "gvm ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/gvm \
    && usermod -aG gvm gvm \
    && usermod -aG sudo gvm

# PASO 19 REDIS-SERVER
RUN sudo apt-get update && sudo apt-get install -y redis-server \
    && curl -f -L https://github.com/greenbone/openvas-scanner/archive/refs/tags/v$OPENVAS_SCANNER_VERSION.tar.gz -o $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION.tar.gz \
    && tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION.tar.gz \
    && sudo cp $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION/config/redis-openvas.conf /etc/redis/redis-openvas.conf \
    && sudo chown redis:redis /etc/redis/redis-openvas.conf \
    && echo "db_address = /run/redis-openvas/redis.sock" | sudo tee -a /etc/openvas/openvas.conf \
    && sudo usermod -aG redis gvm \
    && sudo mkdir -p /run/redis-openvas \
    && sudo chown redis:redis /run/redis-openvas

# Etapa 2: Imagen mínima con solo el binario y sus dependencias
FROM debian:12
ENV INSTALL_DIR=/tmp/install
ENV INSTALL_PREFIX=/usr/local
ENV PATH=$PATH:$INSTALL_PREFIX/sbin
ENV SOURCE_DIR=/tmp/source
ENV GVM_LIBS_VERSION=22.18.0
ENV GVMD_VERSION=25.1.1
ENV PG_GVM_VERSION=22.6.7
ENV GSA_VERSION=24.3.0
ENV OPENVAS_SMB_VERSION=22.5.3
ENV OPENVAS_SCANNER_VERSION=23.15.3
ENV OSPD_OPENVAS_VERSION=22.7.1
ENV OPENVAS_DAEMON=23.15.3
# Librerias
RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    #dependencias gvmd
    libcjson-dev \
    libgpgme-dev \
    libpq-dev \
    libglib2.0 \
    libical-dev \
    libpaho-mqtt-dev \
    libssh-dev \
    libhiredis-dev \
    xsltproc \
    #dependencias gsad
    libmicrohttpd-dev \
    #dependencias openvas-smb
    libpopt-dev \
    heimdal-dev \
    #dependencias openvas-scanner
    libcurl4-gnutls-dev \
    libpcap-dev \
    libnet1-dev \
    nmap \
    #dependencias openvas-ospd
    python3-psutil \
    python3-defusedxml \
    python3-lxml \
    python3-gnupg \
    python3-paho-mqtt \
    #dependencias de openvasd
    #ninguna
    #dependencias de greenbone-feed-sync
    rsync\
    #dependencias de gvm-tools
    python3-paramiko\
    redis-server \
    && apt-get clean

# Copiar el binario desde la etapa de compilación
COPY --from=build $INSTALL_DIR/gvm-libs/ /
COPY --from=build $INSTALL_DIR/gvmd/ /
COPY --from=build $INSTALL_DIR/pg-gvm/ /
COPY --from=build $SOURCE_DIR/gsa-$GSA_VERSION/ $INSTALL_PREFIX/share/gvm/gsad/web/
COPY --from=build $INSTALL_DIR/gsad/ /
COPY --from=build $INSTALL_DIR/openvas-smb/ /
COPY --from=build $INSTALL_DIR/openvas-scanner/ /
COPY --from=build /etc/openvas/ /etc/openvas/
COPY --from=build $INSTALL_DIR/ospd-openvas/ /
COPY --from=build $INSTALL_DIR/openvasd/ /
COPY --from=build $INSTALL_DIR/greenbone-feed-sync/ /
COPY --from=build $INSTALL_DIR/gvm-tools/ /
COPY --from=build /etc/redis/redis-openvas.conf /etc/redis/

RUN useradd -r -M -U -G sudo -s /bin/bash gvm \
    && echo "gvm ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/gvm \
    && usermod -aG gvm gvm \
    && usermod -aG sudo gvm \
    && sudo chown redis:redis /etc/redis/redis-openvas.conf \
    && sudo usermod -aG redis gvm \
    && sudo mkdir -p /run/redis-openvas \
    && sudo chown redis:redis /run/redis-openvas \
    && echo "%gvm ALL = NOPASSWD: /usr/local/sbin/openvas" | tee /etc/sudoers.d/gvm \
    && chmod 0440 /etc/sudoers.d/gvm

    # AJUSTE DE PERMISOS
RUN sudo mkdir -p /var/lib/notus \
  && mkdir -p /run/gvmd \
  && chown -R gvm:gvm /var/lib/gvm \
  && chown -R gvm:gvm /var/lib/openvas \
  && chown -R gvm:gvm /var/lib/openvas \
  && chown -R gvm:gvm /var/lib/notus \
  && chown -R gvm:gvm /var/log/gvm \
  && chown -R gvm:gvm /run/gvmd \
  && chown -R root:root /usr/local/share/gvm/gsad/web \
  && chmod -R g+srw /var/lib/gvm \
  && chmod -R g+srw /var/lib/openvas \
  && chmod -R g+srw /var/log/gvm \
  && chown gvm:gvm /usr/local/sbin/gvmd \
  && mkdir -p /run/ospd \
  && chown gvm:gvm /run/ospd \
  && chmod -R 777 /run/redis-openvas \
  && chmod 6750 /usr/local/sbin/gvmd

# Feed Validation: Configuración del llavero GPG para validar feeds
RUN curl -f -L https://www.greenbone.net/GBCommunitySigningKey.asc -o /tmp/GBCommunitySigningKey.asc \
    && export GNUPGHOME=/tmp/openvas-gnupg \
    && mkdir -p $GNUPGHOME \
    && gpg --import /tmp/GBCommunitySigningKey.asc \
    && echo "8AE4BE429B60A59B311C2E739823FAA60ED1E580:6:" | gpg --import-ownertrust \
    && export OPENVAS_GNUPG_HOME=/etc/openvas/gnupg \
    && mkdir -p $OPENVAS_GNUPG_HOME \
    && cp -r /tmp/openvas-gnupg/* $OPENVAS_GNUPG_HOME/ \
    && chown -R gvm:gvm $OPENVAS_GNUPG_HOME
# Persistimos la variable para que esté disponible en tiempo de ejecución
ENV OPENVAS_GNUPG_HOME=/etc/openvas/gnupg

### Setting up PostgreSQL
RUN apt-get update && apt-get install -y postgresql \
    && mkdir -p /var/run/postgresql /var/log/postgresql \
    && chown postgres:postgres /var/run/postgresql /var/log/postgresql \
    && service postgresql start \
    && su - postgres -c "createuser -DRS gvm" \
    && su - postgres -c "createdb -O gvm gvmd" \
    && su - postgres -c "psql gvmd -c \"create role dba with superuser noinherit; grant dba to gvm;\""

### Setting up an Admin User
RUN  service postgresql start \
    && /usr/local/sbin/gvmd --create-user=admin --password='5JzThxe537M'

### Setting the Feed Import Owner
RUN service postgresql start \
    && /usr/local/sbin/gvmd --modify-setting 78eceaec-3385-11ea-b237-28d24461215b --value `/usr/local/sbin/gvmd --get-users --verbose | grep admin | awk '{print $2}'`

RUN ldconfig