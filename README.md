iSanté to iSantéPlus data migrationscript
=========================================
This repository contains sql queries to migrate data from an existing iSanté server to the new iSantéPlus database that is based on the OpenMRS data model.

#	Exporter la base de donnée de isante vers un fichier sql. 
mysqldump -uadmin -p itech > itech.sql 

# Importer la base de données de isante sur le serveur isanteplus 

mysql -uroot -p 
Entrer le mot de pass correctement. 

create database itech;
CREATE USER 'itechapp'@'localhost' IDENTIFIED BY 'XXXXXXXXXXX';
GRANT ALL ON itech.* TO 'itechapp'@'localhost';
FLUSH PRIVILEGES;

exit;

mysql -uroot -p itech < itech.sql 

#Cloner le repertoire migration_script sur le serveur isanteplus 
git clone https://github.com/IsantePlus/migration-script.git 
sudo chmod 777 migration-script/migration.sh

#Executer la migration 
cd migration-script 
sudo sh migration.sh 

NB- un fichier log (migration/migrationLog.txt) est généré après l’exécution de la migration
