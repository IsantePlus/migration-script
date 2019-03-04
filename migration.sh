#!/bin/bash
# Counting the number of lines in a list of files
# for loop over arguments
cd /home/itech/migration

createProcedure cleanOpenmrs.sql
echo "procedure cleanOpenmrs created" > /home/itech/migration/migrationLog.txt

createProcedure patientDemographics.sql
echo "procedure patientDemographics created"  >> /home/itech/migration/migrationLog.txt

createProcedure encounter_Migration.sql
echo "procedure encounter_Migration created" >> /home/itech/migration/migrationLog.txt

createProcedure ordonanceMigration.sql
echo "procedure ordonanceMigration created" >> /home/itech/migration/migrationLog.txt

createProcedure labs_migration.sql
echo "procedure labs_migration created" >> /home/itech/migration/migrationLog.txt

createProcedure labs_migration_for_old_form.sql
echo "procedure labs_migration_for_old_form. created" >> /home/itech/migration/migrationLog.txt

createProcedure adulte_visit_Migration.sql
echo "procedure adulte_visit_Migration created" >> /home/itech/migration/migrationLog.txt

createProcedure pediatric_visit_Migration.sql
echo "procedure pediatric_visit_Migration created" >> /home/itech/migration/migrationLog.txt

createProcedure discontinuation_migration.sql
echo "procedure discontinuation_migration created" >> /home/itech/migration/migrationLog.txt

createProcedure adherence_migration.sql
echo "procedure adherence_migration created" >> /home/itech/migration/migrationLog.txt

createProcedure ssp_migration_adult.sql
echo "procedure ssp_migration_adult created" >> /home/itech/migration/migrationLog.txt

createProcedure ssp_migration_pediatric.sql
echo "procedure ssp_migration_pediatric created"  >> /home/itech/migration/migrationLog.txt

createProcedure travail_et_accouchement_migration.sql
echo "procedure travail_et_accouchement_migration created"  >> /home/itech/migration/migrationLog.txt

createProcedure obgynMigration.sql
echo "procedure obgynMigration created"  >> /home/itech/migration/migrationLog.txt 

createProcedure migrationIsante.sql
echo "procedure migrationIsante created"  >> /home/itech/migration/migrationLog.txt 

echo "Lunch migration process"  >> /home/itech/migration/migrationLog.txt 
mysql -u root -pwahbahphoeth-D openmrs -e 'call migrationIsante();'  >> /home/itech/migration/migrationLog.txt

mysql -u root -pwahbahphoeth-D openmrs -e 'select * from migration_log;'  >> /home/itech/migration/migrationLog.txt

echo "Ending migration process" 

function createProcedure() {
  echo create procedure  $1
  if [ -f /home/itech/migration/$1]
    then
        mysql -u root -pwahbahphoeth-D openmrs < $1
  else
     echo procedure file $1 does not exist
  fi
}

