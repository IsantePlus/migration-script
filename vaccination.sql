drop procedure if exists vaccination;
DELIMITER $$ 

CREATE PROCEDURE vaccination()
BEGIN
  DECLARE done INT DEFAULT FALSE;
 
SET FOREIGN_KEY_CHECKS=0;


/* Imunization */
/* hepatiteB  */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
c.sitecode = v.sitecode and 
v.immunizationID =2 and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,782,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =2 and c.encounterType=35;

/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,
formatDate(immunizationYy,immunizationMm,immunizationDd),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =2 and c.encounterType=35;

/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,digits(v.immunizationSlot),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and
v.immunizationID =2 and c.encounterType=35;

select 1 as vacc;
/* Polio (OPV/IPV) */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
c.sitecode = v.sitecode and 
v.immunizationID =3 and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,783,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =3 and c.encounterType=35;

/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =3 and c.encounterType=35;

/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,digits(v.immunizationSlot),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =3 and c.encounterType=35;
 
select 2 as vacc; 
  
/* DiTePer */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.immunizations v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
c.sitecode = v.sitecode and 
v.immunizationID =4 and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,781,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =4 and c.encounterType=35;

/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =4 and c.encounterType=35;

/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,digits(v.immunizationSlot),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =4 and c.encounterType=35;  
  
 select 3 as vacc; 
 
/* HIB */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.immunizations v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
c.sitecode = v.sitecode and 
v.immunizationID =5 and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,5261,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =5 and c.encounterType=35;

/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =5 and c.encounterType=35;

/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,digits(v.immunizationSlot),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =5 and c.encounterType=35;  

select 4 as vacc; 
  /* 00850 */ 
/* Pentavalent */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.immunizations v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
c.sitecode = v.sitecode and 
v.immunizationID =20 and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,1423,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =20 and c.encounterType=35;

/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =20 and c.encounterType=35;

/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,digits(v.immunizationSlot),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =20 and c.encounterType=35;  
 
 select 5 as vacc; 
  
/* Pneumocoque	 */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.immunizations v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
c.sitecode = v.sitecode and 
v.immunizationID =14 and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,82215,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =14 and c.encounterType=35;

/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =14 and c.encounterType=35;

/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,digits(v.immunizationSlot),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =14 and c.encounterType=35; 
 
 select 6 as vacc;  
  
/* Rotavirus */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.immunizations v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
c.sitecode = v.sitecode and 
v.immunizationID =13 and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,83531,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =13 and c.encounterType=35;

/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =13 and c.encounterType=35;

/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,digits(v.immunizationSlot),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =13 and c.encounterType=35; 
 
 
select 7 as vacc;    
  
/* ROR */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.immunizations v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
c.sitecode = v.sitecode and 
v.immunizationID =6 and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,159701,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =6 and c.encounterType=35;

/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =6 and c.encounterType=35;

/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,digits(v.immunizationSlot),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =6 and c.encounterType=35; 


select 8 as vacc;    
  
/* RR	 */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.immunizations v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
c.sitecode = v.sitecode and 
v.immunizationID =21 and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,162586,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =21 and c.encounterType=35;

/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =21 and c.encounterType=35;

/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,digits(v.immunizationSlot),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =21 and c.encounterType=35; 
 
 
select 9 as vacc; 
    
  
/* DT	 */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.immunizations v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
c.sitecode = v.sitecode and 
v.immunizationID =8 and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,17,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =8 and c.encounterType=35;

/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =8 and c.encounterType=35;

/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,digits(v.immunizationSlot),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =8 and c.encounterType=35; 
 
 
 select 10 as vacc;
 
  
/* Varicelle	 */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.immunizations v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
c.sitecode = v.sitecode and 
v.immunizationID =15 and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,73193,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =15 and c.encounterType=35;

/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =15 and c.encounterType=35;

/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,digits(v.immunizationSlot),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =15 and c.encounterType=35; 
 
 
 select 11 as vacc;
  
/* Typhimvi	 */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.immunizations v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
c.sitecode = v.sitecode and 
v.immunizationID =16 and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,86208,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =16 and c.encounterType=35;

/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =16 and c.encounterType=35;

/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,digits(v.immunizationSlot),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =16 and c.encounterType=35; 
 
 
select 12 as vacc; 
   
/* Meningo AC	 */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.immunizations v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
c.sitecode = v.sitecode and 
v.immunizationID =17 and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,105030,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =17 and c.encounterType=35;

/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =17 and c.encounterType=35;

/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,digits(v.immunizationSlot),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =17 and c.encounterType=35; 
 
 
 
 select 13 as vacc; 
   
/* Hépatite A */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.immunizations v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
c.sitecode = v.sitecode and 
v.immunizationID =18 and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,77424,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =18 and c.encounterType=35;

/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =18 and c.encounterType=35;

/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,digits(v.immunizationSlot),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =18 and c.encounterType=35; 
 
select 14 as vacc; 
    
/* Cholera */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.immunizations v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
c.sitecode = v.sitecode and 
v.immunizationID =19 and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,73354,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =19 and c.encounterType=35;

/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =19 and c.encounterType=35;

/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,digits(v.immunizationSlot),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =19 and c.encounterType=35; 
 
select 15 as vacc; 
  
    
/* BCG */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.immunizations v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
c.sitecode = v.sitecode and 
v.immunizationID =1 and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,886,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =1 and c.encounterType=35;

/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =1 and c.encounterType=35;

/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,
ifnull(formatDate(immunizationYy,immunizationMm,immunizationDd),e.encounter_datetime),e.location_id,og.obs_id,digits(v.immunizationSlot),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.immunizations v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and  
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and 
v.immunizationID =1 and c.encounterType=35; 
 


select 16 as vacc;


/* Imunization soins de sante primaire*/
/* hepatiteB  */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,date(c.visitDate),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and  
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70693,70694,70695,70696,70697) and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,782,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70693,70694,70695,70696,70697) and c.encounterType=35;


/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,v.value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70693,70694,70695,70696,70697) and c.encounterType=35;


/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,
case when v.concept_id=70693 then 1
     when v.concept_id=70694 then 2
	 when v.concept_id=70695 then 3
	 when v.concept_id=70696 then 4
	 when v.concept_id=70697 then 5 
	 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70693,70694,70695,70696,70697) and c.encounterType=35;

select 17 as vacc;

/* Polio (OPV/IPV) */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,date(c.visitDate),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and  
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70667,70668,70669,70670,70671) and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,783,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70667,70668,70669,70670,70671) and c.encounterType=35;


/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,v.value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70667,70668,70669,70670,70671) and c.encounterType=35;


/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,
case when v.concept_id=70667 then 1
     when v.concept_id=70668 then 2
	 when v.concept_id=70669 then 3
	 when v.concept_id=70670 then 4
	 when v.concept_id=70671 then 5 
	 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70667,70668,70669,70670,70671) and c.encounterType=35;

select 18 as vacc;
/* DiTePer */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,date(c.visitDate),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and  
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70673,70674,70675,70676,70677) and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,781,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70673,70674,70675,70676,70677) and c.encounterType=35;


/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,v.value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70673,70674,70675,70676,70677) and c.encounterType=35;


/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,
case when v.concept_id=70673 then 1
     when v.concept_id=70674 then 2
	 when v.concept_id=70675 then 3
	 when v.concept_id=70676 then 4
	 when v.concept_id=70677 then 5 
	 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70673,70674,70675,70676,70677) and c.encounterType=35;

select 19 as vacc;
/* HIB */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,date(c.visitDate),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and  
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71248,71249,71250,71251,71252) and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,5261,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71248,71249,71250,71251,71252) and c.encounterType=35;


/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,v.value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71248,71249,71250,71251,71252) and c.encounterType=35;


/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,
case when v.concept_id=71248 then 1
     when v.concept_id=71249 then 2
	 when v.concept_id=71250 then 3
	 when v.concept_id=71251 then 4
	 when v.concept_id=71252 then 5 
	 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71248,71249,71250,71251,71252) and c.encounterType=35;

 select 20 as vacc;
  /* 00850 */ 
/* Pentavalent */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,date(c.visitDate),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and  
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71412,71413,71414,71415,71416) and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,1423,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71412,71413,71414,71415,71416) and c.encounterType=35;


/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,v.value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71412,71413,71414,71415,71416) and c.encounterType=35;


/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,
case when v.concept_id=71412 then 1
     when v.concept_id=71413 then 2
	 when v.concept_id=71414 then 3
	 when v.concept_id=71415 then 4
	 when v.concept_id=71416 then 5 
	 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71412,71413,71414,71415,71416) and c.encounterType=35;
  
 select 21 as vacc;  
/* Pneumocoque	 */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,date(c.visitDate),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and  
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71616,71617,71618) and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,82215,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71616,71617,71618) and c.encounterType=35;


/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,v.value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71616,71617,71618) and c.encounterType=35;


/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,
case when v.concept_id=71616 then 1
     when v.concept_id=71617 then 2
	 when v.concept_id=71618 then 3 
	 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71616,71617,71618) and c.encounterType=35;
   
  select 22 as vacc; 
/* Rotavirus */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,date(c.visitDate),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and  
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71610,71611) and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,83531,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71610,71611) and c.encounterType=35;


/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,v.value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71610,71611) and c.encounterType=35;


/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,
case when v.concept_id=71610 then 1
     when v.concept_id=71611 then 2 
	 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71610,71611) and c.encounterType=35;
    
  select 23 as vacc; 
/* ROR */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,date(c.visitDate),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and  
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71635,71636,71637,71638) and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,159701,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71635,71636,71637,71638) and c.encounterType=35;


/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,v.value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71635,71636,71637,71638) and c.encounterType=35;


/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,
case when v.concept_id=71635 then 1
     when v.concept_id=71636 then 2 
	 when v.concept_id=71637 then 3
	 when v.concept_id=71638 then 4
	 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71635,71636,71637,71638) and c.encounterType=35;
 
 select 24 as vacc; 
/* RR	 */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,date(c.visitDate),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and  
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70683,70684,70685,70686,70687) and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,162586,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70683,70684,70685,70686,70687) and c.encounterType=35;


/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,v.value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70683,70684,70685,70686,70687) and c.encounterType=35;


/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,
case when v.concept_id=70683 then 1
     when v.concept_id=70684 then 2 
	 when v.concept_id=70685 then 3
	 when v.concept_id=70686 then 4
	 when v.concept_id=70687 then 4
	 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70683,70684,70685,70686,70687) and c.encounterType=35;
 
   
  select 25 as vacc; 
/* DT	 */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,date(c.visitDate),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and  
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70688,70689,70690,70691,70692) and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,17,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70688,70689,70690,70691,70692) and c.encounterType=35;


/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,v.value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70688,70689,70690,70691,70692) and c.encounterType=35;


/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,
case when v.concept_id=70688 then 1
     when v.concept_id=70689 then 2 
	 when v.concept_id=70690 then 3
	 when v.concept_id=70691 then 4
	 when v.concept_id=70692 then 4
	 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70688,70689,70690,70691,70692) and c.encounterType=35;

 select 26 as vacc;
  
/* Varicelle	 */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,date(c.visitDate),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and  
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71612,71613) and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,73193,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71612,71613) and c.encounterType=35;


/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,v.value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71612,71613) and c.encounterType=35;


/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,
case when v.concept_id=71612 then 1
     when v.concept_id=71613 then 2
	 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71612,71613) and c.encounterType=35;

 select 27 as vacc; 
  
/* Typhimvi	 */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,date(c.visitDate),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and  
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71614,71615) and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,86208,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71614,71615) and c.encounterType=35;


/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,v.value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71614,71615) and c.encounterType=35;


/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,
case when v.concept_id=71614 then 1
     when v.concept_id=71615 then 2
	 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71614,71615) and c.encounterType=35;

 select 28 as vacc;   
/* Meningo AC	 */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,date(c.visitDate),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and  
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71621,71622) and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,105030,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71621,71622) and c.encounterType=35;


/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,v.value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71621,71622) and c.encounterType=35;


/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,
case when v.concept_id=71621 then 1
     when v.concept_id=71622 then 2
	 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71621,71622) and c.encounterType=35;

  
  select 29 as vacc;  
/* Hépatite A */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,date(c.visitDate),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and  
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71619,71620) and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,77424,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71619,71620) and c.encounterType=35;


/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,v.value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71619,71620) and c.encounterType=35;


/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,
case when v.concept_id=71621 then 1
     when v.concept_id=71622 then 2
	 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71619,71620) and c.encounterType=35;

  select 30 as vacc;   
/* Cholera */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,date(c.visitDate),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and  
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71623,71624) and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,73354,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71623,71624) and c.encounterType=35;


/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,v.value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71623,71624) and c.encounterType=35;


/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,
case when v.concept_id=71623 then 1
     when v.concept_id=71624 then 2
	 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (71623,71624) and c.encounterType=35;

  select 31 as vacc; 
    
/* BCG */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1421,e.encounter_id,date(c.visitDate),e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and  
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70666) and c.encounterType=35;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1421 
GROUP BY openmrs.obs.person_id,encounter_id;

/* concept of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,886,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70666) and c.encounterType=35;


/* Date of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,v.value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70666) and c.encounterType=35;


/* Dose of imunization*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,date(c.visitDate),e.location_id,og.obs_id,
case when v.concept_id=70666 then 1
	 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id = v.encounter_id and 
e.encounter_id=og.encounter_id and 
c.sitecode = v.location_id and date_format(date(e.encounter_datetime),'%y-%m-%d') = date_format(date(c.visitDate),'%y-%m-%d') AND 
v.concept_id in (70666) and c.encounterType=35;

 select 32 as vacc;
END;
