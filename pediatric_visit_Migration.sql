
drop procedure if exists pediatric_visit_Migration;

DELIMITER $$ 
CREATE PROCEDURE pediatric_visit_Migration()
BEGIN
  DECLARE done INT DEFAULT FALSE;
 -- DECLARE a CHAR(16);
  DECLARE vstatus boolean;
  DECLARE vvisit_type_id INT;
  DECLARE obs_datetime_,vobs_datetime,vdate_created,vencounter_datetime datetime;
  DECLARE vobs_id,vperson_id,vconcept_id,vencounter_id,vlocation_id INT;
  
DECLARE uuid_encounter CURSOR  for SELECT DISTINCT e.patientID,e.encounter_id FROM itech.encounter e;



/* L'enfant est-il au courant de son statut VIH?*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163524,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedChildAware=1 THEN 1065
	     WHEN v.pedChildAware=2 THEN 1066
		 WHEN v.pedChildAware=4 THEN 1067
		ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedChildAware in (1,2,4);


select 1 as stVih;
/* Le parent/substitut est-il au courant du statut VIH?*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163525,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedParentAware=1 THEN 1065
	     WHEN v.pedParentAware=2 THEN 1066
		 WHEN v.pedParentAware=4 THEN 1067
		ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedParentAware in (1,2,4);

select 2 as stVih;
/* ANTÉCÉDENTS MÉDICAUX DE LA MÈRE BIOLOGIQUE */
/* Le parent/substitut est-il au courant du statut VIH?*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1856,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedParentAware=1 THEN 1067
		ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedMotherHistUnk=1;

select 3 as stVih;
	  /*concept group */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160593,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.pedHistory v
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
   (FindNumericValue(pedMotherHistDobYy)>0 or 
     FindNumericValue(pedMotherHistRecentTb)>0 or 
     FindNumericValue(pedMotherHistActiveTb)>0 or 
     FindNumericValue(pedMotherHistTreatTb)>0 or 
     FindNumericValue(pedMotherHistTreatTbYy)>0);
select 5 as trt1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=160593 
GROUP BY openmrs.obs.person_id,encounter_id;

/*migration for Mere*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1560,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,970,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedMotherHistDobYy)>0;

select 5 as trt2;
/* Date de naissance de la mère*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160751,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.pedMotherHistDobYy,v.pedMotherHistDobMm,pedMotherHistDobDd),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedMotherHistDobYy)>0;

select 5 as trt3;
/* migration TB récente*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160592,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
	CASE WHEN v.pedMotherHistRecentTb>0 THEN 42
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedMotherHistRecentTb)>0;

select 5 as trt4;
/* migration TB active (avec crachats positifs)*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160592,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
	CASE WHEN v.pedMotherHistRecentTb>0 THEN 113489
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedMotherHistActiveTb)>0;
select 5 as trt5;

/* migration Si TB active, traitement TB en cours*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160592,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
	CASE WHEN v.pedMotherHistTreatTb=1 THEN 1065
	     WHEN v.pedMotherHistTreatTb=2 THEN 1066
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedMotherHistTreatTb)>0;

select 5 as trt6;
/* migration Date de début de traitment*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163526,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.pedMotherHistTreatTbYy,v.pedMotherHistTreatTbMm,v.pedMotherHistTreatTbDd),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedMotherHistTreatTbYy)>0;

select 5 as trt;

/*migration de grossesse */
	  /*concept group */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163770,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.pedHistory v
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
  (FindNumericValue(pedMotherHistGrosGrav)>0 or 
     FindNumericValue(pedMotherHistGrosPara)>0 or 
     FindNumericValue(pedMotherHistGrosAbor)>0 or 
     FindNumericValue(pedMotherHistGrosViva)>0);

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163770 
GROUP BY openmrs.obs.person_id,encounter_id;

/* gravida*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5624,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
	CASE WHEN FindNumericValue(v.pedMotherHistGrosGrav)>=0 THEN FindNumericValue(v.pedMotherHistGrosGrav)
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedMotherHistGrosGrav)>0;
/* Para*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1053,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
	CASE WHEN FindNumericValue(v.pedMotherHistGrosPara)>0 THEN FindNumericValue(v.pedMotherHistGrosPara)
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedMotherHistGrosPara)>0;
/* Aborta*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1823,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
	CASE WHEN FindNumericValue(v.pedMotherHistGrosAbor)>0 THEN FindNumericValue(v.pedMotherHistGrosAbor)
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedMotherHistGrosAbor)>0;
/* Enfant Vivant*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1825,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
	CASE WHEN FindNumericValue(v.pedMotherHistGrosViva)>0 THEN FindNumericValue(v.pedMotherHistGrosViva)
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedMotherHistGrosViva)>0;


select 1 as antecedent; 

/* END of ANTÉCÉDENTS MÉDICAUX DE LA MÈRE BIOLOGIQUE */

/* migration mort infantiles */
	  /*concept group */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163528,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.pedHistory v
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
   (digits(v.pedMotherHistGrosDeadAge1)>0 or digits(v.pedMotherHistGrosDeadCause1)>0 or digits(v.pedMotherHistGrosDeadUnk1)>0 or
     digits(v.pedMotherHistGrosDeadAge2)>0 or digits(v.pedMotherHistGrosDeadCause2)>0 or digits(v.pedMotherHistGrosDeadUnk2)>0 or
     digits(v.pedMotherHistGrosDeadAge3)>0 or digits(v.pedMotherHistGrosDeadCause3)>0 or digits(v.pedMotherHistGrosDeadUnk3)>0
     );

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163528 
GROUP BY openmrs.obs.person_id,encounter_id;
/* age du deces*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163527,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
	CASE WHEN FindNumericValue(v.pedMotherHistGrosDeadAge1)>0 THEN FindNumericValue(v.pedMotherHistGrosDeadAge1)
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedMotherHistGrosDeadAge1)>0;
/*----------------------------------------------------------------*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163527,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
	CASE WHEN FindNumericValue(v.pedMotherHistGrosDeadAge2)>0 THEN FindNumericValue(v.pedMotherHistGrosDeadAge2)
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedMotherHistGrosDeadAge2)>0;
/*----------------------------------------------------------------*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163527,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
	CASE WHEN FindNumericValue(v.pedMotherHistGrosDeadAge3)>0 THEN FindNumericValue(v.pedMotherHistGrosDeadAge3)
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedMotherHistGrosDeadAge3)>0;


select 1 as Age; 

/* cause du deces*/
/*INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159482,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
	CASE WHEN v.pedMotherHistGrosDeadCause1>0 THEN v.pedMotherHistGrosDeadCause1
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date(e.encounter_datetime) = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
(v.pedMotherHistGrosDeadCause1>0);
*/
select 1 as Cause1; 
/*----------------------------------------------------------------*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159482,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
	CASE WHEN v.pedMotherHistGrosDeadCause2<>'' THEN v.pedMotherHistGrosDeadCause2
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedMotherHistGrosDeadCause2<>'';
select 1 as Cause2; 
/*----------------------------------------------------------------*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159482,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
	CASE WHEN v.pedMotherHistGrosDeadCause3<>'' THEN v.pedMotherHistGrosDeadCause3
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
(v.pedMotherHistGrosDeadCause3)<>'';

select 1 as Cause3; 


/* Histoire d'IST pendant la grossesse?*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159482,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedMotherHistGrosIst=1 THEN 1065
	     WHEN v.pedMotherHistGrosIst=2 THEN 1066
		 WHEN v.pedMotherHistGrosIst=4 THEN 1067
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
(v.pedMotherHistGrosIst>0);
/* Si Oui, préciser le trimestre */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163772,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedMotherHistGrosIstTri=1 THEN 1721
	     WHEN v.pedMotherHistGrosIstTri=2 THEN 1722
		 WHEN v.pedMotherHistGrosIstTri=4 THEN 1723
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
(v.pedMotherHistGrosIst>0 and pedMotherHistGrosIstTri>0);

/* soins prenatal */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163773,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedMotherHistGrosPreCare=1 THEN 1065
	     WHEN v.pedMotherHistGrosPreCare=2 THEN 1066
		 WHEN v.pedMotherHistGrosPreCare=4 THEN 1067
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
(v.pedMotherHistGrosPreCare>0);

/* Si Oui, préciser lieu des soins */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163529,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedMotherHistGrosPreCareSite<>'' THEN v.pedMotherHistGrosPreCareSite
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
(v.pedMotherHistGrosPreCareSite<>'');

/* No. du dossier médical de la mère */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163530,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedMotherHistGrosPreCareNum<>'' THEN v.pedMotherHistGrosPreCareNum
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
(v.pedMotherHistGrosPreCareNum<>'');


select 1 as method; 


/* Méthode d'accouchement */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5630,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedMotherHistGrosMeth=1 THEN 1170
	     WHEN v.pedMotherHistGrosMeth=2 THEN 1171
		 WHEN v.pedMotherHistGrosMeth=4 THEN 1067
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
(v.pedMotherHistGrosMeth in (1,2,4));

/* Lieu d'accouchement */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163774,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedMotherHistGrosWhere=1 THEN 1536
	     WHEN v.pedMotherHistGrosWhere=2 THEN 1589
		 WHEN v.pedMotherHistGrosWhere=4 THEN 5622
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
(v.pedMotherHistGrosWhere in (1,2,4));

/* Precisez Lieu d'accouchement */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163531,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedMotherHistGrosWhereOther<>'' THEN v.pedMotherHistGrosWhereOther
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
(v.pedMotherHistGrosWhereOther<>'');

/* Statut VIH */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1396,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedMotherHistHivStat=1 THEN 663
	     WHEN v.pedMotherHistHivStat=2 THEN 703
		 WHEN v.pedMotherHistHivStat=4 THEN 1067
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedMotherHistHivStat in (1,2,4);


/*Mère décédée du SIDA/probablement du SIDA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5590,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedMotherHistHivStat=8 THEN 1065
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedMotherHistHivStat=8;
/*Fait partie d'un programme PTME*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163776,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedMotherHistHivPmtct=1 THEN 1065
	     WHEN v.pedMotherHistHivPmtct=2 THEN 1066
	     WHEN v.pedMotherHistHivPmtct=4 THEN 1067    
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedMotherHistHivPmtct in (1,2,4);

/*Fait partie d'un programme PTME si oui precisez */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163779,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedMotherHistHivPmtctWhere<>'' THEN v.pedMotherHistHivPmtctWhere   
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedMotherHistHivPmtctWhere<>'';

/* Prophylaxie ARV pendant la grossesse */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163780,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedMotherHistHivArvPreg=1 THEN 1065
	     WHEN v.pedMotherHistHivArvPreg=2 THEN 1066
	     WHEN v.pedMotherHistHivArvPreg=4 THEN 1067    
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedMotherHistHivArvPreg in (1,2,4);


/* Debut Prophylaxie ARV pendant la grossesse */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163781,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(v.pedMotherHistHivArvPregStartYy,v.pedMotherHistHivArvPregStartMm,v.pedMotherHistHivArvPregStartDd),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedMotherHistHivArvPreg=1 and FindNumericValue(v.pedMotherHistHivArvPregStartYy)>0;

/* Fin Prophylaxie ARV pendant la grossesse */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163782,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(v.pedMotherHistHivArvPregStopYy,v.pedMotherHistHivArvPregStopMm,v.pedMotherHistHivArvPregStopDd),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedMotherHistHivArvPreg=1 and FindNumericValue(v.pedMotherHistHivArvPregStopYy)>0;

/* Trithérapie pendant la grossesse*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163783,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedMotherHistHivHaartPreg=1 THEN 1065
	     WHEN v.pedMotherHistHivHaartPreg=2 THEN 1066
	     WHEN v.pedMotherHistHivHaartPreg=4 THEN 1067    
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedMotherHistHivHaartPreg in (1,2,4);

/* Debut Trithérapie pendant la grossesse */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163784,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(v.pedMotherHistHivHaartPregStYy,v.pedMotherHistHivHaartPregStMm,v.pedMotherHistHivHaartPregStDd),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedMotherHistHivArvPreg=1 and FindNumericValue(v.pedMotherHistHivHaartPregStYy)>0;

/* Fin Trithérapie pendant la grossesse */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163785,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(v.pedMotherHistHivHaartPregSpYy,v.pedMotherHistHivHaartPregSpMm,pedMotherHistHivHaartPregSpDd),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedMotherHistHivArvPreg=1 and FindNumericValue(v.pedMotherHistHivHaartPregSpYy)>0;

/* Prophylaxie ARV pendant l'accouchement */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159595,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedMotherHistHivArvDel=1 THEN 1065
	     WHEN v.pedMotherHistHivArvDel=2 THEN 1066
	     WHEN v.pedMotherHistHivArvDel=4 THEN 1067    
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedMotherHistHivArvDel in (1,2,4);

/* préciser régime ARV */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,comments,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163786,e.encounter_id,e.encounter_datetime,e.location_id,5622,v.pedMotherHistHivReg,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedMotherHistHivReg<>'';


select 1 as grossesse; 


/* ANTÉCÉDENTS MÉDICAUX DE LA FRATRIE */
/*Inconnus, passer à la section Prophylaxie du Nouveau Né et de l'Enfant.*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163533,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedFratHistUnk=1 THEN 1065   
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedFratHistUnk=1;

select 1 as antecedentMed;

/* statut TB*/
/* concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160593,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.pedHistory v
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
(v.pedFratHistRecentTb>0 or pedFratHistActiveTb>0 or pedFratHistTreatTb>0 or pedFratHistTreatTbYy>0);

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=160593 
GROUP BY openmrs.obs.person_id,encounter_id;
select 1 as statuttb;

/* TB récente */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160592,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
	CASE WHEN v.pedFratHistRecentTb=1 THEN 42    
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedFratHistRecentTb=1;
select 1 as tbRecent1;
/* ----------------------------------------------------------------------------------------------------------------------*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1560,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,972,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedFratHistRecentTb=1;

select 1 as tbRecent;

/* Si TB active, traitement TB en cours */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160749,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
	CASE WHEN v.pedFratHistActiveTb=1 THEN 1065   
         WHEN v.pedFratHistActiveTb=2 THEN 1066	
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedFratHistActiveTb in (1,2);

/* TB active (avec crachats positifs) */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160592,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
	CASE WHEN v.pedFratHistTreatTb=1 THEN 113489 
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedFratHistTreatTb=1;


/* Date de début de traitment */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163526,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(v.pedFratHistTreatTbYy,v.pedFratHistTreatTbMm,v.pedFratHistTreatTbDd),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedFratHistTreatTb=1 and FindNumericValue(v.pedFratHistTreatTbYy)>0;


select 1 as statut;

/* VIH /SIDA*/
/* Status du père */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1397,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedFratHistHivStat=1 THEN 664
	     WHEN v.pedFratHistHivStat=2 THEN 703
		 WHEN v.pedFratHistHivStat=4 THEN 1067
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedFratHistHivStat in (1,2,4);

/* Père décédé du SIDA/probablement du SIDA */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5591,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedFratHistHivStat=8 THEN 1065
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedFratHistHivStat=8;


/* Status des Soeurs et freres */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5587,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedFratHistHivStatFrat=1 THEN 1065
	     WHEN v.pedFratHistHivStatFrat=2 THEN 1066
		 WHEN v.pedFratHistHivStatFrat=4 THEN 1067
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedFratHistHivStatFrat in (1,2,4);

/* Soeurs et freres décédé du SIDA/probablement du SIDA */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163534,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedFratHistHivStatFrat=8 THEN 1065
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedFratHistHivStatFrat=8;


/* Nombre de cas par statut VIH (fratrie)*/
/* VIH NEGATIF */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163535,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN FindNumericValue(v.pedFratHistHivStatNumNeg)>0 THEN FindNumericValue(v.pedFratHistHivStatNumNeg)
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedFratHistHivStatNumNeg)>0;

/* VIH POSITIF */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159906,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN FindNumericValue(v.pedFratHistHivStatNumPos)>0 THEN FindNumericValue(v.pedFratHistHivStatNumPos)
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedFratHistHivStatNumPos)>0;

/* VIH INCONU */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163536,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN FindNumericValue(v.pedFratHistHivStatNumUnk)>0 THEN FindNumericValue(v.pedFratHistHivStatNumUnk)
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedFratHistHivStatNumUnk)>0;

/* Frères ou soeurs décédés du SIDA */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163537,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN FindNumericValue(v.pedFratHistHivStatNumDead)>0 THEN FindNumericValue(v.pedFratHistHivStatNumDead)
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedFratHistHivStatNumDead)>0;


select 1 as vih;

/* PROPHYLAXIE DU NOUVEAU NÉ ET DE L'ENFANT */
/*A reçu prophylaxie ARV dans les 72 heures suivant la naissance*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5665,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedInfProArv=1 THEN 1065
	     WHEN v.pedInfProArv=2 THEN 1066
		 WHEN v.pedInfProArv=4 THEN 1067
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedInfProArv in (1,2,4);
/* A reçu prophylaxie contre PCP */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163538,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedInfProPcp=1 THEN 1065
	     WHEN v.pedInfProPcp=2 THEN 1066
		 WHEN v.pedInfProPcp=4 THEN 1067
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedInfProPcp in (1,2,4);
/* A reçu prophylaxie contre MAC */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163539,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedInfProMac=1 THEN 1065
	     WHEN v.pedInfProMac=2 THEN 1066
		 WHEN v.pedInfProMac=4 THEN 1067
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.pedHistory v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedInfProMac in (1,2,4);
/*                 */















/*COMPTE CD4/VIRÉMIE*/
/* Dernier compte CD4 */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163542,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN FindNumericValue(v.pedCd4CntPerc)>0 THEN FindNumericValue(v.pedCd4CntPerc)
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedCd4CntPerc)>0;

/* Date Dernier compte CD4 */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163526,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(v.lowestCd4CntYy,v.lowestCd4CntMm,v.lowestCd4CntDd),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedCd4CntPerc>0 and FindNumericValue(v.lowestCd4CntYy)>0;

/*Non effectué,Inconn */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163544,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.lowestCd4CntNotDone=1 THEN 1066
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.lowestCd4CntNotDone)>0;

/* Virémie la plus récente*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163545,e.encounter_id,formatDate(v.firstViralLoadYy,v.firstViralLoadMm,firstViralLoadDd),e.location_id,
	CASE WHEN FindNumericValue(v.firstViralLoad)>0 THEN FindNumericValue(v.firstViralLoad)
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.firstViralLoad)>0 and FindNumericValue(v.firstViralLoadYy)>0;

/*Non effectué,Inconn */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163546,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.firstViralLoadNotDone=1 THEN 1066
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.firstViralLoadNotDone)>0;


/* ÉVALUATION GYNÉCOLOGIQUE (ADOLESCENTE EN ÂGE DE PROCRÉER) */
/*Menstruations*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160600,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedReproHealthMenses=1 THEN 1065
	     WHEN v.pedReproHealthMenses=2 THEN 1066
		 WHEN v.pedReproHealthMenses=4 THEN 1067
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedReproHealthMenses in (1,2,4);
/*Dernières règles*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1427,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(v.pregnantLmpYy,v.pregnantLmpMm,v.pregnantLmpDd),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pregnantLmpYy)>0;

/*Grossesse*/
/*
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5272,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pregnant=1 THEN 1065
	     WHEN v.pregnant=2 THEN 1066
		 WHEN v.pregnant=4 THEN 1067
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pregnant in (1,2,4);

*/
/*Si Oui, suivie en clinique prénatale?*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1622,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pregnantPrenatal=1 THEN 1065
	     WHEN v.pregnantPrenatal=2 THEN 1066
		 WHEN v.pregnantPrenatal=4 THEN 1067
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pregnantPrenatal in (1,2,4);
/*Date de première visite de suivi prénatale*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163547,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(v.pregnantPrenatalFirstYy,v.pregnantPrenatalFirstMm,v.pregnantPrenatalFirstDd),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pregnantPrenatalFirstYy)>0;

/*Date de dernière visite de suivi prénatale*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159590,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(v.pregnantPrenatalLastYy,v.pregnantPrenatalLastMm,v.pregnantPrenatalLastDd),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pregnantPrenatalLastYy)>0;

/* Pap Test */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163952,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.papTest=1 THEN 1267
	     WHEN v.papTest=2 THEN 1118
		 WHEN v.papTest=4 THEN 1067
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.papTest in (1,2,4);

/* Si Oui, résultat */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,885,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedPapTestRes=1 THEN 1115
	     WHEN v.pedPapTestRes=2 THEN 1116
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedPapTestRes in (1,2);


/* Si Oui, date du dernier test */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163267,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(v.papTestYy,v.papTestMm,v.papTestDd),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.papTestYy)>0;

/* ALIMENTATION DE L'ENFANT */
/* Allaitement exclusif */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5526,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedFeedBreast=1 THEN 163720
	     WHEN v.pedFeedBreast=2 THEN 163721
		 WHEN v.pedFeedBreast=4 THEN 1090
	     WHEN v.pedFeedBreast=8 THEN 1067
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedFeedBreast in (1,2,4,8);

/* Âge au sevrage (en mois) */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163548,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN FindNumericValue(v.pedFeedBreastAge)>0 THEN FindNumericValue(v.pedFeedBreastAge)
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedFeedBreastAge)>0;

/* Lait artificiel */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5254,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedFeedFormula=1 THEN 163720
	     WHEN v.pedFeedFormula=2 THEN 163721
		 WHEN v.pedFeedFormula=4 THEN 1090
	     WHEN v.pedFeedFormula=8 THEN 1067
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedFeedFormula in (1,2,4,8);

/* Âge au sevrage (en mois) */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163549,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN FindNumericValue(v.pedFeedFormulaAge)>0 THEN FindNumericValue(v.pedFeedFormulaAge)
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedFeedFormulaAge)>0;

/* Alimentation mixte */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,6046,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedFeedMixed=1 THEN 163720
	     WHEN v.pedFeedMixed=2 THEN 163721
		 WHEN v.pedFeedMixed=4 THEN 1090
	     WHEN v.pedFeedMixed=8 THEN 1067
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedFeedMixed in (1,2,4,8);

/* Âge au sevrage (en mois) */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163550,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN FindNumericValue(v.pedFeedMixedAge)>0 THEN FindNumericValue(v.pedFeedMixedAge)
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedFeedMixedAge)>0;


/* Autre alimentation*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163551,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedFeedOther=1 THEN 163720
	     WHEN v.pedFeedOther=2 THEN 163721
		 WHEN v.pedFeedOther=4 THEN 1090
	     WHEN v.pedFeedOther=8 THEN 1067
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedFeedOther in (1,2,4,8);

/* Âge au sevrage (en mois) */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163552,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN FindNumericValue(v.pedFeedOtherAge)>0 THEN FindNumericValue(v.pedFeedOtherAge)
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedFeedOtherAge)>0;

/* Si lait artificiel, préciser type */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163553,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedFeedMixedType<>'' THEN v.pedFeedMixedType
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedFeedMixedType<>'';

/* Si autre alimentation, préciser type */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163719,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.pedFeedOtherType<>'' THEN v.pedFeedOtherType
	     ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedFeedOtherType<>'';

/* SIGNES VITAUX ET ANTHROPOMÉTRIE À LA NAISSANCE */

/* Poids à la naissance */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5916,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.pedVitBirWtUnits=1 THEN FindNumericValue(v.pedVitBirWt)
	 WHEN v.pedVitBirWtUnits=2  THEN FindNumericValue(v.pedVitBirWt)/2.2046
	 ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedVitBirWt)>0 and v.pedVitBirWtUnits in (1,2);
/* Taille à la naissance */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163554,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN FindNumericValue(v.pedVitBirLen)>0 THEN FindNumericValue(v.pedVitBirLen)
	 ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedVitBirLen)>0;

/* Périmètre crânien (PC) à la naissance */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163555,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN FindNumericValue(v.pedVitBirPc)>0 THEN FindNumericValue(v.pedVitBirPc)
	 ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedVitBirPc)>0;
/*Âge gestationnel à la naissance*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1409,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN FindNumericValue(v.pedVitBirGest)>0 THEN FindNumericValue(v.pedVitBirGest)
	 ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedVitBirGest)>0;


/*SIGNES VITAUX ET ANTHROPOMÉTRIE ACTUELS*/

/*Périmètre crânien (PC) */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5314,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN FindNumericValue(v.pedVitCurHeadCirc)>0 THEN FindNumericValue(v.pedVitCurHeadCirc)
	 ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedVitCurHeadCirc)>0;
/* Périmètre brachial (PB) */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1343,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN FindNumericValue(v.pedVitCurBracCirc)>0 THEN FindNumericValue(v.pedVitCurBracCirc)
	 ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedVitCurBracCirc)>0;
/* Saturation en oxygène */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5092,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN FindNumericValue(v.pedVitCurOxySat)>0 THEN FindNumericValue(v.pedVitCurOxySat)
	 ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.pedVitCurOxySat)>0;

/* ÉVALUATION DU DÉVELOPPEMENT PSYCHOMOTEUR */
/* Motricité globale*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163578,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.pedPsychoMotorGross=1 THEN 160275
     WHEN v.pedPsychoMotorGross=2 THEN 160276
	 ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedPsychoMotorGross in (1,2);
/* Motricité fine	*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163579,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.pedPsychoMotorFine=1 THEN 160275
     WHEN v.pedPsychoMotorFine=2 THEN 160276
	 ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedPsychoMotorFine in (1,2);
/* Langage/Compréhension<*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163787,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.pedPsychoMotorLang=1 THEN 160275
     WHEN v.pedPsychoMotorLang=2 THEN 160276
	 ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedPsychoMotorLang in (1,2);
/*Contact Social*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163580,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.pedPsychoMotorSocial=1 THEN 160275
     WHEN v.pedPsychoMotorSocial=2 THEN 160276
	 ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedPsychoMotorSocial in (1,2);


/* STATUT VIH ACTUEL */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1401,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.pedCurrHiv=1 THEN 1405
     WHEN v.pedCurrHiv=8 THEN 163767
	 WHEN v.pedCurrHiv=2 THEN 163718 
	 WHEN v.pedCurrHiv=4 THEN 163717
	 ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedCurrHiv in (1,2,4,8);

/* ÉVALUATION TB */
/*Antécédent de TB */
/*concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1633,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.tbStatus v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.asymptomaticTb=1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1633 
GROUP BY openmrs.obs.person_id,encounter_id;

/*Antécédent de TB*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1389,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN v.asymptomaticTb=1 THEN 1065
	 ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.tbStatus v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.asymptomaticTb=1;

/*Traitement TB */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159398,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.completeTreat=1 THEN 1065
	 ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.tbStatus v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.completeTreat=1;

/* Traitement TB en cours */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159798,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.currentTreat=1 THEN 1065
	 ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.tbStatus v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.currentTreat=1;
/* Date de début Traitement tb*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159798,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(v.pedCompleteTreatStartYy,v.pedCompleteTreatStartMm,'XX'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.tbStatus v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.completeTreat=1 and FindNumericValue(v.pedCompleteTreatStartYy)>0;

/* Date de fin Traitement tb*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159798,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(v.completeTreatYy,v.completeTreatMm,'XX'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.tbStatus v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.completeTreat=1 and FindNumericValue(v.completeTreatYy)>0;

/* Prophylaxie TB à I'INH */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1110,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.propINH=1 THEN 1679
	 ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.tbStatus v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.propINH=1;

/* Date de début Prophylaxie TB à I'INH */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162320,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(FindNumericValue(v.debutINHYy),FindNumericValue(v.debutINHMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.tbStatus v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.propINH=1 and FindNumericValue(v.debutINHYy)>0;

/* Date de fin Prophylaxie TB à I'INH */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163284,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(FindNumericValue(v.arretINHYy),FindNumericValue(v.arretINHMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.tbStatus v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.propINH=1 and FindNumericValue(v.arretINHYy)>0;

/* Statut TB actuel */
/* Notion de contact TB */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1659,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.pedTbEvalRecentExp=1 THEN 124068
	 ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.tbStatus v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedTbEvalRecentExp=1;

/* Récent PPD */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163951,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.pedTbEvalRecentExp=1 THEN 1267
     WHEN v.pedTbEvalRecentExp=2 THEN 1118
	 WHEN v.pedTbEvalRecentExp=4 THEN 1067
	 ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.tbStatus v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedTbEvalPpdRecent in (1,2,4);



 
 /* Test serologique */
 /* test rapide 1*/
 /* migration group*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='28e8ffc8-1b65-484c-baa1-929f0b8901a6'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=1 and pedLabsID=1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='28e8ffc8-1b65-484c-baa1-929f0b8901a6' 
GROUP BY openmrs.obs.person_id,encounter_id;

/* nom du test*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162087,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,163722,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=1 and pedLabsID=1;
/* 	Age de depistage serologique */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163540,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.pedLabsResultAge)>0 then FindNumericValue(v.pedLabsResultAge) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=1 and pedLabsID=1;

/* 	Age Unit de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163541,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResultAgeUnits=1 then 1072
     when v.pedLabsResultAgeUnits=2 then 1074
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=1 and pedLabsID=1;

/* Resultat de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163722,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResult=1 then 703
     when v.pedLabsResult=2 then 664
	 when v.pedLabsResult=4 then 1138
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=1 and pedLabsID=1;



/* test rapide 2 */
 /* migration group*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='6e3aa01c-8a70-42b6-94fe-6ac465b620d9'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=2 and pedLabsID=1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='6e3aa01c-8a70-42b6-94fe-6ac465b620d9' 
GROUP BY openmrs.obs.person_id,encounter_id;

/* nom du test*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162087,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,163722,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=2 and pedLabsID=1;
/* 	Age de depistage serologique */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163540,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.pedLabsResultAge)>0 then FindNumericValue(v.pedLabsResultAge) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=2 and pedLabsID=1;

/* 	Age Unit de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163541,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResultAgeUnits=1 then 1072
     when v.pedLabsResultAgeUnits=2 then 1074
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=2 and pedLabsID=1;

/* Resultat de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163722,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResult=1 then 703
     when v.pedLabsResult=2 then 664
	 when v.pedLabsResult=4 then 1138
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=2 and pedLabsID=1;
 
 
 
 
 /* test rapide 3*/
 /* migration group*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='2a66236f-d84b-4cc8-a552-15b12238e7ea'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=3 and pedLabsID=1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='2a66236f-d84b-4cc8-a552-15b12238e7ea' 
GROUP BY openmrs.obs.person_id,encounter_id;

/* nom du test*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162087,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,163722,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=3 and pedLabsID=1;
/* 	Age de depistage serologique */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163540,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.pedLabsResultAge)>0 then FindNumericValue(v.pedLabsResultAge) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=3 and pedLabsID=1;

/* 	Age Unit de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163541,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResultAgeUnits=1 then 1072
     when v.pedLabsResultAgeUnits=2 then 1074
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=3 and pedLabsID=1;

/* Resultat de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163722,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResult=1 then 703
     when v.pedLabsResult=2 then 664
	 when v.pedLabsResult=4 then 1138
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=3 and pedLabsID=1;
 
 
 

 /* Elisa 1*/
 /* migration group*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='121d7ed6-c039-465d-9663-4ab631232ba9'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=1 and pedLabsID=2;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='121d7ed6-c039-465d-9663-4ab631232ba9' 
GROUP BY openmrs.obs.person_id,encounter_id;

/* nom du test*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162087,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1042,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=1 and pedLabsID=2;
/* 	Age de depistage serologique */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163540,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.pedLabsResultAge)>0 then FindNumericValue(v.pedLabsResultAge) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=1 and pedLabsID=2;

/* 	Age Unit de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163541,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResultAgeUnits=1 then 1072
     when v.pedLabsResultAgeUnits=2 then 1074
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=1 and pedLabsID=2;

/* Resultat de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1042,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResult=1 then 703
     when v.pedLabsResult=2 then 664
	 when v.pedLabsResult=4 then 1138
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=1 and pedLabsID=2;



/* Elisa 2 */
 /* migration group*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ec6e3a54-3e4b-4647-b9bd-baf0d06a98d2'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=2 and pedLabsID=2;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='ec6e3a54-3e4b-4647-b9bd-baf0d06a98d2' 
GROUP BY openmrs.obs.person_id,encounter_id;

/* nom du test*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162087,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1042,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=2 and pedLabsID=2;
/* 	Age de depistage serologique */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163540,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.pedLabsResultAge)>0 then FindNumericValue(v.pedLabsResultAge) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=2 and pedLabsID=2;

/* 	Age Unit de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163541,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResultAgeUnits=1 then 1072
     when v.pedLabsResultAgeUnits=2 then 1074
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=2 and pedLabsID=2;

/* Resultat de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1042,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResult=1 then 703
     when v.pedLabsResult=2 then 664
	 when v.pedLabsResult=4 then 1138
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=2 and pedLabsID=2;
 
 
 
 
 /* Elisa 3*/
 /* migration group*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='99f7b98e-8900-4898-9772-a88f4783babd'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=3 and pedLabsID=2;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='99f7b98e-8900-4898-9772-a88f4783babd' 
GROUP BY openmrs.obs.person_id,encounter_id;

/* nom du test*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162087,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1042,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=3 and pedLabsID=2;
/* 	Age de depistage serologique */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163540,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.pedLabsResultAge)>0 then FindNumericValue(v.pedLabsResultAge) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=3 and pedLabsID=2;

/* 	Age Unit de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163541,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResultAgeUnits=1 then 1072
     when v.pedLabsResultAgeUnits=2 then 1074
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=3 and pedLabsID=2;

/* Resultat de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1042,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResult=1 then 703
     when v.pedLabsResult=2 then 664
	 when v.pedLabsResult=4 then 1138
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=3 and pedLabsID=2; 
 
 
 
 
  /* PCR 1*/
 /* migration group*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='eaa7f684-1473-4f59-acb4-686bada87846'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=1 and pedLabsID=3;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='eaa7f684-1473-4f59-acb4-686bada87846' 
GROUP BY openmrs.obs.person_id,encounter_id;

/* nom du test*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162087,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1030,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=1 and pedLabsID=3;
/* 	Age de depistage serologique */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163540,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.pedLabsResultAge)>0 then FindNumericValue(v.pedLabsResultAge) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=1 and pedLabsID=3;

/* 	Age Unit de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163541,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResultAgeUnits=1 then 1072
     when v.pedLabsResultAgeUnits=2 then 1074
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=1 and pedLabsID=3;

/* Resultat de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1030,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResult=1 then 703
     when v.pedLabsResult=2 then 664
	 when v.pedLabsResult=4 then 1138
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=1 and pedLabsID=3 and v.pedLabsResult in (1,2,4);



/* PCR 2 */
 /* migration group*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='9a05c0d5-2c03-4c3a-a810-6bc513ae7ee7'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=2 and pedLabsID=3;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='9a05c0d5-2c03-4c3a-a810-6bc513ae7ee7' 
GROUP BY openmrs.obs.person_id,encounter_id;

/* nom du test*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162087,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1030,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=2 and pedLabsID=3;
/* 	Age de depistage serologique */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163540,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.pedLabsResultAge)>0 then FindNumericValue(v.pedLabsResultAge) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=2 and pedLabsID=3;

/* 	Age Unit de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163541,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResultAgeUnits=1 then 1072
     when v.pedLabsResultAgeUnits=2 then 1074
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=2 and pedLabsID=3;

/* Resultat de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1030,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResult=1 then 703
     when v.pedLabsResult=2 then 664
	 when v.pedLabsResult=4 then 1138
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=2 and pedLabsID=3 and v.pedLabsResult in (1,2,4);
 
 
 
 
 /* PCR 3*/
 /* migration group*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='535b63e9-0773-4f4e-94af-69ff8f412411'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=3 and pedLabsID=3;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='535b63e9-0773-4f4e-94af-69ff8f412411' 
GROUP BY openmrs.obs.person_id,encounter_id;

/* nom du test*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162087,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1030,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=3 and pedLabsID=3;
/* 	Age de depistage serologique */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163540,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.pedLabsResultAge)>0 then FindNumericValue(v.pedLabsResultAge) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=3 and pedLabsID=3;

/* 	Age Unit de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163541,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResultAgeUnits=1 then 1072
     when v.pedLabsResultAgeUnits=2 then 1074
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=3 and pedLabsID=3;

/* Resultat de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1030,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResult=1 then 703
     when v.pedLabsResult=2 then 664
	 when v.pedLabsResult=4 then 1138
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=3 and pedLabsID=3 and v.pedLabsResult in (1,2,4); 
 
 
 
 
 
 
 
 
 
  /* ANTIGEN (UP24) 1*/
 /* migration group*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='245e1289-9ad9-4da7-985a-59035b5a8838'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=1 and pedLabsID=4;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='245e1289-9ad9-4da7-985a-59035b5a8838' 
GROUP BY openmrs.obs.person_id,encounter_id;

/* nom du test*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162087,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,163342,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=1 and pedLabsID=4;
/* 	Age de depistage serologique */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163540,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.pedLabsResultAge)>0 then FindNumericValue(v.pedLabsResultAge) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=1 and pedLabsID=4;

/* 	Age Unit de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163541,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResultAgeUnits=1 then 1072
     when v.pedLabsResultAgeUnits=2 then 1074
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=1 and pedLabsID=4;

/* Resultat de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163342,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResult=1 then 703
     when v.pedLabsResult=2 then 664
	 when v.pedLabsResult=4 then 1138
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=1 and pedLabsID=4;



/* ANTIGEN (UP24) 2 */
 /* migration group*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='8814b88a-aed9-44b4-848c-24283e749a4f'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=2 and pedLabsID=4;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='8814b88a-aed9-44b4-848c-24283e749a4f' 
GROUP BY openmrs.obs.person_id,encounter_id;

/* nom du test*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162087,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,163342,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=2 and pedLabsID=4;
/* 	Age de depistage serologique */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163540,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.pedLabsResultAge)>0 then FindNumericValue(v.pedLabsResultAge) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=2 and pedLabsID=4;

/* 	Age Unit de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163541,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResultAgeUnits=1 then 1072
     when v.pedLabsResultAgeUnits=2 then 1074
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=2 and pedLabsID=4;

/* Resultat de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163342,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResult=1 then 703
     when v.pedLabsResult=2 then 664
	 when v.pedLabsResult=4 then 1138
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=2 and pedLabsID=4;
 
 
 
 
 /* Antigen (UP24) 3*/
 /* migration group*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='fcc58dd7-2232-4627-8c73-af233db677eb'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=3 and pedLabsID=4;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='fcc58dd7-2232-4627-8c73-af233db677eb' 
GROUP BY openmrs.obs.person_id,encounter_id;

/* nom du test*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162087,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,163342,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=3 and pedLabsID=4;
/* 	Age de depistage serologique */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163540,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.pedLabsResultAge)>0 then FindNumericValue(v.pedLabsResultAge) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=3 and pedLabsID=4;

/* 	Age Unit de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163541,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResultAgeUnits=1 then 1072
     when v.pedLabsResultAgeUnits=2 then 1074
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=3 and pedLabsID=4;

/* Resultat de depistage*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163342,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedLabsResult=1 then 703
     when v.pedLabsResult=2 then 664
	 when v.pedLabsResult=4 then 1138
	 else null 
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.pedLabs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedLabsSlot=3 and pedLabsID=4; 
 
END;
