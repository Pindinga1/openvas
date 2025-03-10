# OPENVAS
Contenedor de Docker OPENVAS
## INSTRUCCIONES

Traemos Repo:
``` bash
git clone https://github.com/Pindinga1/openvas.git
```

Ingresamos a la carpeta:
``` bash
cd openvas/compose/
```

Iniciamos el Contenedor:
``` bash
sudo docker-compose up -d  
```
Esperamos unos momentos hasta que la interfaz web esté lista en http://tu-ip:9392/, las credenciales por defecto son:  
User  
``` bash
admin
```  
Password  (Puedes especificar otra clave en el archivo compose.yml):  
``` bash
5JzThxe537M
```  
**Una vez que el acceso web esté disponible, lanzamos el siguiente comando para sincronizar Feeds:**  
``` bash
sudo docker exec -d -u gvm openvas greenbone-feed-sync
```  
**Dependiendo de los recursos de la máquina o de la conexión de red, el proceso de sincronización de Feeds puede tardar hasta 1 hora**