drop function if exists IsNumeric;
CREATE FUNCTION IsNumeric (val varchar(255)) RETURNS tinyint 
 RETURN val REGEXP '^(-|\\+){0,1}([0-9]+\\.[0-9]*|[0-9]*\\.[0-9]+|[0-9]+)$';

DROP FUNCTION if exists FindNumericValue;
DELIMITER $$
 
CREATE FUNCTION FindNumericValue(val VARCHAR(255)) RETURNS VARCHAR(255)
    DETERMINISTIC
BEGIN
		DECLARE idx INT DEFAULT 0;
		IF ISNULL(val) THEN RETURN NULL; END IF;

		IF LENGTH(val) = 0 THEN RETURN ""; END IF;
 SET idx = LENGTH(val);
		WHILE idx > 0 DO
			IF IsNumeric(SUBSTRING(val,idx,1)) = 0 THEN
				SET val = REPLACE(val,SUBSTRING(val,idx,1),"");
				SET idx = LENGTH(val)+1;
			END IF;
				SET idx = idx - 1;
		END WHILE;
			RETURN val;
END
$$
DELIMITER ;

DROP FUNCTION if exists `formatDate`;
DELIMITER $$
CREATE FUNCTION `formatDate`( dateYy Varchar(10),dateMm Varchar(10),dateDd Varchar(10) ) RETURNS DATE
BEGIN
  IF (FindNumericValue(dateYy)<=0)
  THEN 
    RETURN null;
  END IF;
  
  IF(length(dateYy)<=2) 
  THEN 
   set dateYy=concat('20',FindNumericValue(dateYy));
   END IF;
  
  IF(dateMm is null or dateMm='XX' or dateMm='' or dateMm>12 or dateMm<1)
  THEN 
   set dateMm='01';
   END IF;
 
  IF(dateDd is null or dateDd='XX' or dateDd='' or dateDd>31 or dateDd<1)
  THEN 
   set dateDd='01';
   END IF;
 
 IF((dateMm='01' or dateMm='03' or dateMm='05' or dateMm='07' or dateMm='08' or dateMm='10' or dateMm='12') and dateDd>31)
 THEN 
  set dateDd='31';
  END IF;
 
  IF((dateMm='04' or dateMm='06' or dateMm='09' or dateMm='11') and dateDd>30)
 THEN 
  set dateDd='30';
  END IF;
  
 IF((dateMm='02') and dateDd>29)
 THEN 
  set dateDd='28';
  END IF;
 
  RETURN date_format(concat(dateYy,'-',dateMm,'-',dateDd),'%y-%m-%d');
END$$
DELIMITER ;

DROP FUNCTION if exists `digits`;
DELIMITER $$
CREATE FUNCTION `digits`( str CHAR(32) ) RETURNS char(32) CHARSET utf8
BEGIN
  DECLARE i, len SMALLINT DEFAULT 1;
  DECLARE ret CHAR(32) DEFAULT '';
  DECLARE c CHAR(1);
  DECLARE pos SMALLINT;
  DECLARE after_p CHAR(20);
  IF str IS NULL
  THEN 
    RETURN "";
  END IF;
  SET len = CHAR_LENGTH( str );
  l:REPEAT
    BEGIN
      SET c = MID( str, i, 1 );
      IF c BETWEEN '0' AND '9' THEN 
        SET ret=CONCAT(ret,c);
      ELSEIF c = '.' OR c = ',' THEN
		IF c = '.' THEN
			SET pos=INSTR(str, '.' );
            SET after_p=MID(str,pos,pos+2);
            SET ret=CONCAT(FindNumericValue(ret),'.',FindNumericValue(after_p));
            LEAVE l;
		ELSEIF c = ',' THEN 
			SET pos=INSTR(str, ',');
            SET after_p=MID(str,pos,pos+2);
            SET ret=CONCAT(FindNumericValue(ret),'.',FindNumericValue(after_p));
            LEAVE l;
		END IF;
      END IF;
      
      SET i = i + 1;
      
    END;
  UNTIL i > len END REPEAT;
  RETURN ret;
END$$
DELIMITER ;

drop procedure if exists migrationIsante;
DELIMITER $$ 
CREATE PROCEDURE migrationIsante()
BEGIN

  DECLARE cnt INT;

create table if not exists migration_log(id int(11) primary key auto_increment,prcodedure varchar(25),starttime datetime,endtime datetime);

 select count(*) into cnt from migration_log where prcodedure = 'encounter'  and endtime is not null;
 if(cnt=0) then 
   SET SQL_SAFE_UPDATES = 0;
/* Clean openmrs database before import */
   call cleanOpenmrs();
   select 1  as CleanOpenmrs;
/* patient registration migration */
   SET SQL_SAFE_UPDATES = 0;
   insert into migration_log(prcodedure,starttime) values('demographic',now());
   call patientDemographics();
   select 2 as Demographic;
   update migration_log set endtime=now() where prcodedure = 'demographic';
/* visit and Encounter migration*/
   SET SQL_SAFE_UPDATES = 0;
   insert into migration_log(prcodedure,starttime) values('encounter',now());
   call encounter_Migration();
   select 3 as Encounter;
   update migration_log set endtime=now() where prcodedure = 'encounter';
 end if;  

  
  select count(*) into cnt from migration_log where prcodedure = 'ordonance' and endtime is not null;
  if(cnt=0) then    
   delete from migration_log where prcodedure in ('ordonance');
   insert into migration_log(prcodedure,starttime) values('ordonance',now());
   update obs o,encounter e, encounter_type et set o.obs_group_id=null where o.encounter_id=e.encounter_id and e.encounter_type=et.encounter_type_id and et.uuid='10d73929-54b6-4d18-a647-8b7316bc1ae3'; 
   delete o from obs o, encounter e, encounter_type et where o.encounter_id=e.encounter_id and e.encounter_type=et.encounter_type_id and et.uuid='10d73929-54b6-4d18-a647-8b7316bc1ae3';
   
   SET SQL_SAFE_UPDATES = 0;
/* ordonance migration */ 
   call ordonanceMigration();
   select 7 as Ordonance;
   SET SQL_SAFE_UPDATES = 0;
   update migration_log set endtime=now() where prcodedure = 'ordonance';
 end if; 
   
  
 select count(*) into cnt from migration_log where prcodedure = 'lab' and endtime is not null;
 if(cnt=0) then    
   delete from migration_log where prcodedure in ('lab');
   insert into migration_log(prcodedure,starttime) values('lab',now());
   update obs o,encounter e, encounter_type et set o.obs_group_id=null where o.encounter_id=e.encounter_id and e.encounter_type=et.encounter_type_id and et.uuid='f037e97b-471e-4898-a07c-b8e169e0ddc4'; 
   delete o from obs o, encounter e, encounter_type et where o.encounter_id=e.encounter_id and e.encounter_type=et.encounter_type_id and et.uuid='f037e97b-471e-4898-a07c-b8e169e0ddc4';
   
   SET SQL_SAFE_UPDATES = 0;
 /* Lab migration  */
   call labsMigration();
   select 6 as Lab;
   SET SQL_SAFE_UPDATES = 0;
   call labsMigrationOldData();
   select 6 as LabOLD;
   update migration_log set endtime=now() where prcodedure = 'lab';
 end if; 
 
 
  select count(*) into cnt from migration_log where prcodedure = 'discontinuation' and endtime is not null;
  if(cnt=0) then    
   delete from migration_log where prcodedure in ('discontinuation');
   insert into migration_log(prcodedure,starttime) values('discontinuation',now()); 
   update obs o,encounter e, encounter_type et set o.obs_group_id=null where o.encounter_id=e.encounter_id and e.encounter_type=et.encounter_type_id and et.uuid='9d0113c6-f23a-4461-8428-7e9a7344f2ba'; 
   delete o from obs o, encounter e, encounter_type et where o.encounter_id=e.encounter_id and e.encounter_type=et.encounter_type_id and et.uuid='9d0113c6-f23a-4461-8428-7e9a7344f2ba';
      
/* discontinutation */   
   call discontinuationMigration();
   SET SQL_SAFE_UPDATES = 0;
   select 8 as discontinuation;
   update migration_log set endtime=now() where prcodedure = 'discontinuation';
 end if; 
 
 
 select count(*) into cnt from migration_log where prcodedure in ('sspPediatric') and endtime is not null;
 if(cnt=0) then  
 
   update obs o,encounter e, encounter_type et set o.obs_group_id=null where o.encounter_id=e.encounter_id and e.encounter_type=et.encounter_type_id 
   and et.uuid in ('12f4d7c3-e047-4455-a607-47a40fe32460','709610ff-5e39-4a47-9c27-a60e740b0944','fdb5b14f-555f-4282-b4c1-9286addf0aae','a5600919-4dde-4eb8-a45b-05c204af8284',
			   'd95b3540-a39f-4d1e-a301-8ee0e03d5eab','c45d7299-ad08-4cb5-8e5d-e0ce40532939','49592bec-dd22-4b6c-a97f-4dd2af6f2171','349ae0b4-65c1-4122-aa06-480f186c8350',
			   '33491314-c352-42d0-bd5d-a9d0bffc9bf1','17536ba6-dd7c-4f58-8014-08c7cb798ac7','204ad066-c5c2-4229-9a62-644bc5617ca2'); 
   delete o from obs o, encounter e, encounter_type et where o.encounter_id=e.encounter_id and e.encounter_type=et.encounter_type_id and 
   et.uuid in ('12f4d7c3-e047-4455-a607-47a40fe32460','709610ff-5e39-4a47-9c27-a60e740b0944','fdb5b14f-555f-4282-b4c1-9286addf0aae','a5600919-4dde-4eb8-a45b-05c204af8284',
			   'd95b3540-a39f-4d1e-a301-8ee0e03d5eab','c45d7299-ad08-4cb5-8e5d-e0ce40532939','49592bec-dd22-4b6c-a97f-4dd2af6f2171','349ae0b4-65c1-4122-aa06-480f186c8350',
			   '33491314-c352-42d0-bd5d-a9d0bffc9bf1','17536ba6-dd7c-4f58-8014-08c7cb798ac7','204ad066-c5c2-4229-9a62-644bc5617ca2');
  
/* fistVisit migration VIH form */
   SET SQL_SAFE_UPDATES = 0;
   delete from migration_log where prcodedure in ('adult visit','pediatric visit');
   insert into migration_log(prcodedure,starttime) values('adult visit',now());
   
   call adult_visit_Migration();
   select 4 as Adult;
   update migration_log set endtime=now() where prcodedure = 'adult visit';
   
   insert into migration_log(prcodedure,starttime) values('pediatric visit',now());
   SET SQL_SAFE_UPDATES = 0;
/* pediatric visit HIV migration */
   call pediatric_visit_Migration();
   update migration_log set endtime=now() where prcodedure = 'pediatric visit';
   select 5 as Pediatric;

  /*  
   delete from migration_log where prcodedure in ('accouchemnet');
   insert into migration_log(prcodedure,starttime) values('accouchemnet',now());     
travail et accouchemnet
   call travailAccMigration();
   SET SQL_SAFE_UPDATES = 0;
   select 9 as travailAcc; 
   update migration_log set endtime=now() where prcodedure = 'accouchemnet';
*/
  
   delete from migration_log where prcodedure in ('adherence');
   insert into migration_log(prcodedure,starttime) values('adherence',now());   
/* Adherence */
   call  adherenceMigration();
   SET SQL_SAFE_UPDATES = 0;
   select 10 as adherence;
   update migration_log set endtime=now() where prcodedure = 'adherence';
   
  
   delete from migration_log where prcodedure in ('homeVisit');
   insert into migration_log(prcodedure,starttime) values('homeVisit',now());   
/* homeVisit */
   call  homeVisitMigration();
   SET SQL_SAFE_UPDATES = 0;
   select 10 as homeVisit;
   update migration_log set endtime=now() where prcodedure = 'homeVisit';


  
  delete from migration_log where prcodedure in ('obgyn');
  insert into migration_log(prcodedure,starttime) values('obgyn',now());    
/* OBGYN */   
  call obgynMigration();
  SET SQL_SAFE_UPDATES = 0;
  select 11 as obgyn;
  update migration_log set endtime=now() where prcodedure = 'obgyn';
  
  delete from migration_log where prcodedure in ('sspAdult');
  insert into migration_log(prcodedure,starttime) values('sspAdult',now()); 
/* SOINS SANTE PRIMAIRE ADULTE */ 
  call sspAdultMigration();
  SET SQL_SAFE_UPDATES = 0;
  select 12 as sspAdult;
  update migration_log set endtime=now() where prcodedure = 'sspAdult';
  
  delete from migration_log where prcodedure in ('sspPediatric');
  insert into migration_log(prcodedure,starttime) values('sspPediatric',now());   
/* SOINS SANTE PRIMAIRE ADULTE */  
  call sspPediatricMigration();
  SET SQL_SAFE_UPDATES = 0;
  select 13 as sspPediatric;
  update migration_log set endtime=now() where prcodedure = 'sspPediatric'; 
 
 end if;
 
 
 /* migration for next VisitDate*/  
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5096,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(c.nxtVisitYy,c.nxtVisitMm,c.nxtVisitDd),1,e.date_created,UUID()
FROM itech.encounter c, encounter e
WHERE e.uuid = c.encGuid and formatDate(c.nxtVisitYy,c.nxtVisitMm,c.nxtVisitDd) is not null;

/*Statut de la fiche*/
/* complete/Incomplete */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163340,e.encounter_id,e.encounter_datetime,e.location_id,
    CASE WHEN encStatus=5 or encStatus=7 THEN 163339
	     WHEN encStatus=1 or encStatus=3 or encStatus=0 THEN 1267	 
		ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e
WHERE e.uuid = c.encGuid and encStatus in (0,1,3,5,7);

/* La fiche doit être passée en revue par la personne responsable de la qualité des données. */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163341,e.encounter_id,e.encounter_datetime,e.location_id,
    CASE WHEN encStatus=3 or encStatus=7 THEN 1065	 
		ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e
WHERE e.uuid = c.encGuid and encStatus in (3,7);

/*Evaluation et plan */



/*visit suivi */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159395,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.followupComments<>'' then substring(v.followupComments,1000)
ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.followupTreatment v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.followupComments<>'';

 select 13 as comments;

/* premiere visit  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159395,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.assessmentPlan<>'' then substring(v.assessmentPlan,1000)
ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.assessmentPlan<>'';

 select 14 as comments;
 
 
 /* Home visit remarque */ 
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,161011,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.homeVisitRemarks<>'' then substring(v.homeVisitRemarks,1,1000)
ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.homeCareVisits v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.homeVisitRemarks<>'';

/* counseling remarque */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163104,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.obstaclesRemarks<>'' then v.obstaclesRemarks
ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.comprehension v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.obstaclesRemarks <>'';

 /* migration for From Autor*/  
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1473,e.encounter_id,e.encounter_datetime,e.location_id,
    CASE WHEN ifnull(formAuthor,'')<>'' and  ifnull(formAuthor2,'')<>'' then concat(formAuthor,' / ',formAuthor2)
	     WHEN ifnull(formAuthor,'')<>'' and  ifnull(formAuthor2,'')='' then formAuthor
		 WHEN ifnull(formAuthor,'')='' and  ifnull(formAuthor2,'')<>'' then formAuthor2
		ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e
WHERE e.uuid = c.encGuid ;

END$$