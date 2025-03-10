# openvascpnbase
DockerFile BASE para construir un OPENVAS funcional
## CONSTRUIR IMAGEN

Traemos Repo:
``` bash
git clone https://github.com/Pindinga1/openvas.git
```

Ingresamos a la carpeta:
``` bash
cd openvascpnbase
```

Construimos imágen:
``` bash
sudo docker-compose up -d  
```
Esperamos unos momentos hasta que la interfáz web esté lista en http://tu-ip:9392/, las credenciales por defecto son:  
User  
``` bash
admin
```  
Password  (Puedes especificar otra clave en el archivo compose.yml):  
``` bash
5JzThxe537M
```  
**Esperamos unos 5 minutos y lanzamos el comando para sincronizar los feeds:**
``` bash
sudo docker exec -d -u gvm openvas greenbone-feed-sync
```  
**Dependiendo de los recursos de la máquina o de la conexión de red, puede tardarse hasta una hora la sincronización completa***