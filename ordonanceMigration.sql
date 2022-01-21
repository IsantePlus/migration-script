drop procedure if exists ordonanceMigration;
DELIMITER $$ 
CREATE PROCEDURE ordonanceMigration()
BEGIN
  DECLARE done INT DEFAULT FALSE;
 -- DECLARE a CHAR(16);
  DECLARE vstatus boolean;
  DECLARE vvisit_type_id INT;
  DECLARE obs_datetime_,vobs_datetime,vdate_created,vencounter_datetime datetime;
  DECLARE vobs_id,vperson_id,vconcept_id,vencounter_id,vlocation_id INT;
  
DECLARE uuid_encounter CURSOR  for SELECT DISTINCT e.patientID,e.encounter_id FROM itech.encounter e;


 SET SQL_SAFE_UPDATES = 0;

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

/* dispensation communautaire */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1755,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN o.concept_id=71642 AND o.value_boolean=1 THEN 1065
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=71642 and o.value_boolean=1;	


select 1 as test1;


/* Abacavir(ABC) */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,70056,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=1;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=1 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=1 and v.stdDosage in (1,2);

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=1 and v.altDosageSpecify<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=1 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,70056,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=1;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
ifnull(formatDate(v.dispDateYy,v.dispDateMm,v.dispDateDd),e.encounter_datetime),e.location_id,og.obs_id,
case when v.dispensed=1 then 1 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=1 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

		 
 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=1 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=1 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=1 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 2 as test2;


/* Combivir(AZT+3TC) */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=8;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,630,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=8;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=8 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=8 and v.stdDosage in (1,2);

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=8 and v.altDosageSpecify<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=8 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=8;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,630,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=8;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
ifnull(formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)),e.encounter_datetime),e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=8 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=8 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=8 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=8 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 3 as test3;

/* Didanosine */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=10;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,74807,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=10;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=10 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=10 and v.stdDosage in (1,2);

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=10 and v.altDosageSpecify<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=10 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=10;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,74807,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=10;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
ifnull(formatDate(v.dispDateYy,v.dispDateMm,v.dispDateDd),e.encounter_datetime),e.location_id,og.obs_id,
1 ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=10 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=10 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=10 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=10 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 4 as test4;

/* Emtricitabine(FTC) */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=12;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,75628,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=12;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=12 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=12 and v.stdDosage in (1,2);

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=12 and v.altDosageSpecify<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=12 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=12;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,75628,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=12;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
ifnull(formatDate(v.dispDateYy,v.dispDateMm,v.dispDateDd),e.encounter_datetime),e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=12 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null);

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=12 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=12 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=12 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 5 as test5;

/* Lamivudine(3TC)*/
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=20;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,78643,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=20;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=20 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=20 and v.stdDosage in (1,2);

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=20 and v.altDosageSpecify<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=20 and digits(v.numDaysDesc)>0;

/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=20;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,78643,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=20;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
ifnull(formatDate(v.dispDateYy,v.dispDateMm,v.dispDateDd),e.encounter_datetime),e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=20 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=20 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=20 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=20 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 6 as test6;


/* Stavudine(d4T) */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=29;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,84309,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=29;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=29 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=29 and v.stdDosage in (1,2);

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=29 and v.altDosageSpecify<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=29 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=29;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,84309,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=29;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) 
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=29 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=29 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=29 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=29 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 7 as test7;


/* Tenofovir(TNF) */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=31;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,84795,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=31;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=31 and v.forPepPmtct in (1,2);

select 71 as test71;
 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=31 and v.stdDosage in (1,2);

select 72 as test72;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=31 and v.altDosageSpecify<>'';

select 73 as test73;
/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=31 and digits(v.numDaysDesc)>0;

select 730 as test730;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=31;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,84795,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=31;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when FindNumericValue(v.dispDateDd)>0 and FindNumericValue(dispDateMm)>0 and FindNumericValue(dispDateYy)>0 then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=31 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

select 74 as test74;
 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=31 and v.dispAltDosageSpecify<>'';

select 75 as test75;
 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=31 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

select 76 as test76;
/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=31 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 8 as test8;


/* Trizivir(ABC+AZT+3TC)*/
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=33;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,817,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=33;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=33 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=33 and v.stdDosage in (1,2);

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=33 and v.altDosageSpecify<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=33 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=33;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,817,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=33;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when FindNumericValue(v.dispDateDd)>0 and FindNumericValue(dispDateMm)>0 and FindNumericValue(dispDateYy)>0 then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=33 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=33 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=33 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=33 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 77 as test;


/* Zidovudine(AZT) */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=34;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,86663,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=34;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=34 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=34 and v.stdDosage in (1,2);

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=34 and v.altDosageSpecify<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=34 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=34;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,86663,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=34;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=34 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=34 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=34 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=34 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 78 as test;


/* Efavirenz(EFV)*/
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=11;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,75523,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=11;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=11 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=11 and v.stdDosage in (1,2);

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=11 and v.altDosageSpecify<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=11 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=11;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,75523,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=11;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=11 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=11 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=11 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=11 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 79 as test;


/* Nevirapine(NVP)*/
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=23;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,80586,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=23;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=23 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=23 and v.stdDosage in (1,2);

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=23 and v.altDosageSpecify<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=23 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=23;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,80586,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=23;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=23 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null);

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=23 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=23 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=23 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 79 as test;


/* Atazanavir(ATZN) */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=5;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,71647,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=5;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=5 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=5 and v.stdDosage in (1,2);

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=5 and v.altDosageSpecify<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=5 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=5;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,71647,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=5;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=5 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null);

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=5 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=5 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=5 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 80 as test;


/* Atazanavir+BostRTV */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=6;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,159809,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=6;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=6 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=6 and v.stdDosage in (1,2);

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=6 and v.altDosageSpecify<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=6 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=6;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,159809,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=6;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=6 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=6 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=6 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=6 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 81 as test;

/* Indinavir(IDV) */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=16;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,77995,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=16;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=16 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=16 and v.stdDosage in (1,2);

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=16 and v.altDosageSpecify<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=16 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=16;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,77995,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=16;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=16 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=16 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=16 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=16 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 82 as test;



/* Lopinavir + BostRTV(Kaletra)*/
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=21;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,794,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=21;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=21 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=21 and v.stdDosage in (1,2);

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=21 and v.altDosageSpecify<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=21 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=21;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,794,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=21;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=21 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null);

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=21 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=21 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=21 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 83 as test;



/* Darunavir */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=88;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,74258,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=88;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=88 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=88 and v.stdDosage in (1,2);

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=88 and v.altDosageSpecify<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=88 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=88;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,74258,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=88;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=88 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null);

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=88 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=88 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=88 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 84 as test;


/* Raltegravir */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=87;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,154378,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=87;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=87 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=87 and v.stdDosage in (1,2);

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=87 and v.altDosageSpecify<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=87 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=87;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,154378,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=87;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=87 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=87 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=87 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=87 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/
select 85 as test;

/*Acétaminophène*/
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=36;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,70116,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=36;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=36 and v.altDosageSpecify<>'';

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=36 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=36 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=36;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,70116,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=36;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=36 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=36 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=36 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=36 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 86 as test;

/* Aspirine */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=37;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,71617,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=37;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=37 and v.altDosageSpecify<>'';

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=37 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=37 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=37;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,71617,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=37;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=37 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=37 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=37 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=37 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 87 as test;
/* Hydroxyde d'aluminium */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=82;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,70994,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=82;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=82 and v.altDosageSpecify<>'';

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=82 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=82 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=82;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,70994,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=82;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=82 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=82 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=82 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=82 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 88 as test;

/* Enalapril */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=80;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,75633,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=80;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=80 and v.altDosageSpecify<>'';

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=80 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=80 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=80;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,75633,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=80;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=80 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=80 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=80 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=80 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 89 as test;

/* HCTZ */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=81;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,77696,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=81;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=81 and v.altDosageSpecify<>'';

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=81 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=81 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=81;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,77696,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=81;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=81 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=81 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=81 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=81 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 90 as test;


/* Amoxiciline */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=55;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,71160,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=55;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=55 and v.altDosageSpecify<>'';

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=55 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=55 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=55;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,71160,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=55;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=55 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=55 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=55 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=55 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 91 as test;


/* Ciprofloxacine */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=42;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,73449,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=42;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=42 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=42 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=42 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=42;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,73449,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=42;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=42 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=42 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=42 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=42 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 92 as test;


/* Clarithromycin */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=56;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,73498,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=56;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=56 and v.altDosageSpecify<>'';

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=56 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=56 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=56;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,73498,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=56;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=56 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=56 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=56 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=56 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 93 as test;


/* Clindamycine */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=57;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,73546,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=57;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=57 and v.altDosageSpecify<>'';

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=57 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=57 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=57;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,73546,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=57;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=57 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=57 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=57 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=57 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 94 as test;



/* Cotrimoxazole */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=9;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,105281,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=9;

 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=9 and v.forPepPmtct in (1,2);

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=9 and v.altDosageSpecify<>'';

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=9 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=9 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=9;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,105281,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=9;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=9 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=9 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=9 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=9 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 95 as test;


/* Erythromycin */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=43;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,75842,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=43;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=43 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=43 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=43 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=43;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,75842,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=43;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=43 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=43 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=43 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=43 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 96 as test;


/* Metromidazole */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=44;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,79782,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=44;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=44 and v.altDosageSpecify<>'';

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=44 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=44 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=44;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,79782,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=44;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=44 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=44 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=44 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=44 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 97 as test;


/* Doxycyline */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=79;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,75222,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=79;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=79 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=79 and v.pedPresentationDesc<>'';


/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=79 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=79;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,75222,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=79;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=79 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=79 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=79 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=79 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 98 as test;


/* PNC */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=84;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,81724,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=84;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=84 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=84 and v.pedPresentationDesc<>'';


/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=84 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=84;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,81724,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=84;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=84 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=84 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=84 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=84 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 99 as test;


/* Amphotericine B */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=58;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,71184,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=58;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=58 and v.altDosageSpecify<>'';



 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=58 and v.pedPresentationDesc<>'';


/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=58 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=58;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,71184,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=58;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=58 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=58 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=58 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=58 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 100 as test;

/* Fluconazole */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=14;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,76488,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=14;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=14 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=14 and v.pedPresentationDesc<>'';


/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=14 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=14;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,76488,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=14;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=14 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=14 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=14 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=14 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 101 as test;


/* Itraconazole */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=59;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,78338,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=59;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=59 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=59 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=59 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=59;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,78338,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=59;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=59 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=59 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=59 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=59 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/



select 102 as test;


/* Ketaconazole */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=19;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,78476,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=19;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=19 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=19 and v.pedPresentationDesc<>'';


/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=19 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=19;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,78476,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=19;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=19 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=19 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=19 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=19 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 103 as test;

/* Miconazole */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=45;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,79831,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=45;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=45 and v.altDosageSpecify<>'';



 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=45 and v.pedPresentationDesc<>'';


/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=45 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=45;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,79831,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=45;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=45 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=45 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=45 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=45 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/



select 104 as test;



/* Nystatin */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=46;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,80945,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=46;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=46 and v.altDosageSpecify<>'';



 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=46 and v.pedPresentationDesc<>'';


/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=46 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=46;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,80945,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=46;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=46 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=46 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=46 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=46 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 105 as test;


/* Chloroquine */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=60;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,73300,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=60;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=60 and v.altDosageSpecify<>'';



 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=60 and v.pedPresentationDesc<>'';


/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=60 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=60;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,73300,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=60;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=60 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=60 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=60 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=60 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 106 as test;
/* Ivermectine */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=64;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,78342,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=64;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=64 and v.altDosageSpecify<>'';



 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=64 and v.pedPresentationDesc<>'';



/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=64 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=64;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,78342,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=64;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=64 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=64 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=64 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=64 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 107 as test;


/* Primaquine */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=85;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,82521,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=85;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=85 and v.altDosageSpecify<>'';



 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=85 and v.pedPresentationDesc<>'';


/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=85 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=85;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,82521,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=85;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=85 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=85 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=85 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=85 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 108 as test;


/* Pyrimethamine */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=61;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,82919,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=61;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=61 and v.altDosageSpecify<>'';



 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=61 and v.pedPresentationDesc<>'';



/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=61 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=61;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,82919,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=61;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=61 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=61 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=61 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=61 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 109 as test;


/* Quinine */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=62;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,83023,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=62;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=62 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=62 and v.pedPresentationDesc<>'';


/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=62 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=62;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,83023,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=62;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=62 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=62 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=62 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=62 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 110 as test;

/* Sulfadiazine */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=63;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,84459,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=63;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=63 and v.altDosageSpecify<>'';



 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=63 and v.pedPresentationDesc<>'';



/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=63 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=63;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,84459,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=63;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=63 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=63 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=63 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=63 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 111 as test;

/* Ethambutol */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=13;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,75948,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=13;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=13 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=13 and v.pedPresentationDesc<>'';


/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=13 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=13;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,75948,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=13;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=13 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=13 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=13 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=13 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/



select 112 as test;



/* Isoniazide */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=18;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,78280,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=18;

 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=18 and v.forPepPmtct in (1,2);

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=18 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=18 and v.pedPresentationDesc<>'';


/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=18 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=18;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,78280,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=18;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=18 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=18 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=18 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=18 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 113 as test;

/* Pyrazinamide */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=24;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,82900,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=24;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=24 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=24 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=24 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=24;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,82900,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=24;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=24 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=24 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=24 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=24 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 115 as test;


/* Rifampicine */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=25;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,767,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=25;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=25 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=25 and v.pedPresentationDesc<>'';



/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=25 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=25;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,82900,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=25;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=25 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=25 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=25 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=25 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 116 as test;



/* Streptomycine */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=30;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,84360,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=30;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=30 and v.altDosageSpecify<>'';

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=30 and v.pedPresentationDesc<>'';


/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=30 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=30;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,84360,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=30;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=30 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=30 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=30 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=30 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 117 as test;



/* Acide Folique */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=48;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,76613,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=48;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=48 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=48 and v.pedPresentationDesc<>'';


/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=48 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=48;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,76613,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=48;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=48 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=48 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=48 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=48 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 118 as test;



/* B Complexe */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=47;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,86341,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=47;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=47 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=47 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=47 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=47;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,86341,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=47;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=47 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=47 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=47 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=47 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 119 as test;


/* Fer */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=49;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,78218,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=49;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=49 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=49 and v.pedPresentationDesc<>'';


/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=49 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=49;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,78218,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=49;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=49 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=49 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=49 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=49 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/



select 120 as test;



/* Multivitamine */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=50;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,461,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=50;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=50 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=50 and v.pedPresentationDesc<>'';



/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=50 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=50;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,461,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=50;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=50 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=50 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=50 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=50 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 121 as test;

/* Pyridoxine */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=65;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,82912,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=65;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=65 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=65 and v.pedPresentationDesc<>'';


/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=65 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=65;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,82912,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=65;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=65 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=65 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=65 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=65 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 122 as test;


/* Supplément Protéinique */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=51;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,82767,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=51;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=51 and v.altDosageSpecify<>'';

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=51 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=51 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=51;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,82767,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=51;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=51 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=51 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=51 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=51 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 123 as test;


/* Vitamine C */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=52;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,71589,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=52;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=52 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=52 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=52 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=52;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,71589,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=52;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=52 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=52 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=52 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=52 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 123 as test;


/* Acyclovir*/
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=2;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,70245,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=2;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=2 and v.altDosageSpecify<>'';

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=2 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=2 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=2;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,70245,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=2;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=2 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=2 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=2 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=2 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 125 as test;

/* Loperamide*/
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=53;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,79037,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=53;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=53 and v.altDosageSpecify<>'';

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=53 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=53 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=53;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,79037,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=53;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=53 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=53 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=53 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=53 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 126 as test;


/* Promethazine*/
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=54;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,82667,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=54;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=54 and v.altDosageSpecify<>'';

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=54 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=54 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=54;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,82667,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=54;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=54 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=54 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=54 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=54 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 127 as test;



/* Calamine*/
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=78;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,493,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=78;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=78 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=78 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=78 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=78;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,493,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=78;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=78 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=78 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=78 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=78 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 128 as test;

/* Bromhexine*/
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=77;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,72401,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=77;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=77 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=77 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=77 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=77;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,72401,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=77;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=77 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=77 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=77 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=77 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 129 as test;

/* Benzoate de benzyl */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=76;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,72075,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=76;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=76 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=76 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=76 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=76;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,72075,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=76;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=76 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=76 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=76 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=76 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 130 as test;

/* drug pediatric */

/*  Nelfinavir (NFV) */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=22;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,80487,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=22;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=22 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=22;

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=22 and v.altDosageSpecify<>'';

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=22 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=22 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=22;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,80487,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=22;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=22 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=22 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=22 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=22 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 131 as test;

/* Saquinavir (SQV) */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=27;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,83690,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=27;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=27 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=27;

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=27 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=27 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=27 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=27;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,80487,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=27;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=27 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=27 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=27 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=27 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 132 as test;

/* Ritonavir (RTV) */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=26;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,83412,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=26;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=26 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=26;

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=26 and v.altDosageSpecify<>'';

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=26 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=26 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=26;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,83412,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=26;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=26 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=26 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=26 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=26 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/



select 133 as test;




/* Diclofenac */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=72;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,74778,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=72;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=72 and v.altDosageSpecify<>'';

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=72 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=72 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=72;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,74778,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=72;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=72 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=72 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=72 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=72 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/

select 134 as test;
/* Ibuprofen */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=38;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,77897,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=38;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=38 and v.altDosageSpecify<>'';

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=38 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=38 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=38;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,77897,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=38;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=38 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=38 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=38 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=38 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 135 as test;


/* Paracétamol */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=39;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,70116,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=39;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=39 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=39 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=39 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=39;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,70116,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=39;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=39 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=39 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=39 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=39 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/



select 136 as test;



/* Amoxiciline + acide clavulanique */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=73;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,450,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=73;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=73 and v.altDosageSpecify<>'';



 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=73 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=73 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=73;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,450,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=73;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=73 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=73 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=73 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=73 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/



select 137 as test;



/* mebendazole */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=75;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,79413,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=75;
 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=75 and v.altDosageSpecify<>'';


 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.pedPresentationDesc<>'' then v.pedPresentationDesc else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=75 and v.pedPresentationDesc<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=75 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=75;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,79413,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=75;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,case when formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null then formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd))
     else e.encounter_datetime end as obs_datetime,e.location_id,og.obs_id,
case when v.dispensed=1 then 1
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=75 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=75 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=75 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=75 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


/* Date de renouvellement de la prescription*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162549,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(FindNumericValue(c.nxtVisitYy),FindNumericValue(c.nxtVisitMm),FindNumericValue(c.nxtVisitDd)),1,e.date_created,UUID()
FROM itech.encounter c, encounter e
WHERE e.uuid = c.encGuid and c.encounterType in (5,18) and formatDate(FindNumericValue(c.nxtVisitYy),FindNumericValue(c.nxtVisitMm),FindNumericValue(c.nxtVisitDd)) is not null;

update itech.prescriptionOtherFields set arvStartDateDd='01' where arvStartDateDd like '%un%';
update itech.prescriptionOtherFields set arvStartDateMm='01' where arvStartDateMm like '%un%';
update itech.prescriptionOtherFields set arvStartDateYy='01' where arvStartDateYy like '%un%';

 /* Date d'initiation ARV in ordonance form*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159599,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(FindNumericValue(pr.arvStartDateYy),FindNumericValue(pr.arvStartDateMm),FindNumericValue(pr.arvStartDateDd)),1,e.date_created,UUID()
FROM itech.encounter c, encounter e,itech.prescriptionOtherFields pr
WHERE e.uuid = c.encGuid and c.encounterType in (5,18) and pr.patientID=c.patientID and FindNumericValue(pr.arvStartDateYy)>0 and
date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(pr.visitDateYy,'-',pr.visitDateMm,'-',pr.visitDateDd);

/* Patient inscrit dans le programme ARV*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159811,e.encounter_id,e.encounter_datetime,e.location_id,
    CASE WHEN pr.startedArv=1 then 1065
	     when pr.startedArv=0 then 1066
		 else null 
    end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,itech.prescriptionOtherFields pr
WHERE e.uuid = c.encGuid and c.encounterType in (5,18) and pr.patientID=c.patientID and pr.startedArv>=0 and
date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(pr.visitDateYy,'-',pr.visitDateMm,'-',pr.visitDateDd);

/* migration for others Drugs */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163322,e.encounter_id,e.encounter_datetime,e.location_id,
    other.otherDrugs,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,
(select visitDate,patientID,seqNum,concat(ifnull(otherdrug1,''),ifnull(otherdrug2,''),ifnull(otherdrug3,''),ifnull(otherdrug4,''),ifnull(otherdrug5,'')) as otherDrugs from 
(
select formatDate(visitDateYy,visitDateMm,visitDateDd) as visitDate,patientID,seqNum,
GROUP_CONCAT(case when rxSlot=1 then concat('Drug Name:',drug,'; Dosage:',altDosageSpecify,'; Nombre de Jour:',numDaysDesc,'; Date Dispensation:',case when dispensed=1 then formatDate(dispDateYy,dispDateMm,dispDateDd) else '' end,'||') else null end SEPARATOR '||') as otherdrug1, 
GROUP_CONCAT(case when rxSlot=2 then concat('Drug Name:',drug,'; Dosage:',altDosageSpecify,'; Nombre de Jour:',numDaysDesc,'; Date Dispensation:',case when dispensed=1 then formatDate(dispDateYy,dispDateMm,dispDateDd) else '' end,'||') else null end SEPARATOR '||') as otherdrug2, 
GROUP_CONCAT(case when rxSlot=3 then concat('Drug Name:',drug,'; Dosage:',altDosageSpecify,'; Nombre de Jour:',numDaysDesc,'; Date Dispensation:',case when dispensed=1 then formatDate(dispDateYy,dispDateMm,dispDateDd) else '' end,'||') else null end SEPARATOR '||') as otherdrug3, 
GROUP_CONCAT(case when rxSlot=4 then concat('Drug Name:',drug,'; Dosage:',altDosageSpecify,'; Nombre de Jour:',numDaysDesc,'; Date Dispensation:',case when dispensed=1 then formatDate(dispDateYy,dispDateMm,dispDateDd) else '' end,'||') else null end SEPARATOR '||') as otherdrug4,
GROUP_CONCAT(case when rxSlot=5 then concat('Drug Name:',drug,'; Dosage:',altDosageSpecify,'; Nombre de Jour:',numDaysDesc,'; Date Dispensation:',case when dispensed=1 then formatDate(dispDateYy,dispDateMm,dispDateDd) else '' end,'||') else null end SEPARATOR '||')  as otherdrug5 
from itech.otherPrescriptions group by 1,2 order by 2,1
) ot where (otherdrug1 is not null
            or otherdrug2 is not null
			or otherdrug3 is not null
			or otherdrug4 is not null
			or otherdrug5 is not null)
) other
WHERE e.uuid = c.encGuid and c.encounterType in (5,18) and other.patientID=c.patientID and other.seqNum=c.seqNum and
date_format(date(e.encounter_datetime),'%y-%m-%d')  = other.visitDate and other.otherDrugs<>'';


select 138 as test;

/* Ajout de dolutogravir et etravirine */

/* ETRAVIRINE(ETV) */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=90;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,159810,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=90;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=90 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=90;

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=90 and v.altDosageSpecify<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=90 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=90;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,159810,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=90;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
ifnull(formatDate(v.dispDateYy,v.dispDateMm,v.dispDateDd),e.encounter_datetime),e.location_id,og.obs_id,
case when v.dispensed=1 then 1 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=90 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

		 
 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=90 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=90 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=90 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 2 as test2;



/* Dolutogravir(DTG) */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=89;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,165085,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=89;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=89 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=89;

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=89 and v.altDosageSpecify<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=89 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=89;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,165085,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=89;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
ifnull(formatDate(v.dispDateYy,v.dispDateMm,v.dispDateDd),e.encounter_datetime),e.location_id,og.obs_id,
case when v.dispensed=1 then 1 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=89 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

		 
 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=89 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=89 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=89 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 2 as test2;



/* Elvitegravir(ETV) */
  /* migration group 1 */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1442,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=91;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=1442 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,165093,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=91;
 /*Rx,Prophy*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.forPepPmtct=1 then 163768
     when v.forPepPmtct=2 then 138405
	 else null
end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=91 and v.forPepPmtct in (1,2);

 /* dosage */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when c.encounterType=5 and v.stdDosage=1 then d.stdDosageDescription
     when c.encounterType=18 and v.stdDosage=1 then d.pedStdDosageFr1
	 when c.encounterType=18 and v.stdDosage=2 then d.pedStdDosageFr2
	 else d.stdDosageDescription
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.drugLookup d,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and d.drugID=v.drugID and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=91;

 /* dosage alternative */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ca8bc9c3-7f97-450a-8f33-e98f776b90e1'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.altDosageSpecify<>'' then v.altDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=91 and v.altDosageSpecify<>'';

/* Durée de prise des médicaments */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.numDaysDesc)>0 then digits(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=91 and digits(v.numDaysDesc)>0;
/* end migration group 1*/

  /* migration group 2*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163711,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=91;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163711 
GROUP BY openmrs.obs.person_id,encounter_id;
 
 /* name of the drug */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,165093,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=91;
 /* MÉDICAMENT dispense A LA VISITE */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1276,e.encounter_id,
ifnull(formatDate(v.dispDateYy,v.dispDateMm,v.dispDateDd),e.encounter_datetime),e.location_id,og.obs_id,
case when v.dispensed=1 then 1 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=91 and (v.dispensed=1 or formatDate(FindNumericValue(v.dispDateYy),FindNumericValue(v.dispDateMm),FindNumericValue(v.dispDateDd)) is not null );

		 
 /* Posologie alternative  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1444,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.dispAltDosageSpecify<>'' then v.dispAltDosageSpecify else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=91 and v.dispAltDosageSpecify<>'';

 /* Nombre de jours alternatifs  */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159368,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when FindNumericValue(v.dispAltNumDaysSpecify)>0 then FindNumericValue(v.dispAltNumDaysSpecify) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=91 and FindNumericValue(v.dispAltNumDaysSpecify)>0;

/* Nombre de pillules distribuée*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1443,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when digits(v.dispAltNumPills)>0 then digits(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=91 and digits(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 2 as test2;

END;


