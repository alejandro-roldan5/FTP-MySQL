# FTP-MySQL
No funciona. Las instancias se crean correctamente, se puede acceder por SSH a ellas con la clave PEM y demás, pero una vez dentro intento revisar si los servicios están corriendo y no existen. Te dejo mis archivos de configuración ya que no consigo encontrar el error:

**APARECE ESTO CADA VEZ QUE COMPRUEBO**
 ```python
    [ec2-user@ip-172-31-81-134 ~]$ systemctl status vsftpd
    Unit vsftpd.service could not be found.

 ```
