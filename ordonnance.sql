
/* Date de renouvellement de la prescription*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162549,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(c.nxtVisitYy,c.nxtVisitMm,c.nxtVisitDd),1,e.date_created,UUID()
FROM itech.encounter c, encounter e
WHERE e.uuid = c.encGuid and c.encounterType in (5,18) and formatDate(c.nxtVisitYy,c.nxtVisitMm,c.nxtVisitDd) is not null;

update itech.prescriptionOtherFields set arvStartDateDd='01' where arvStartDateDd like '%un%';
update itech.prescriptionOtherFields set arvStartDateMm='01' where arvStartDateMm like '%un%';
update itech.prescriptionOtherFields set arvStartDateYy='01' where arvStartDateYy like '%un%';

 /* Date d'initiation ARV in ordonance form*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159599,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(pr.arvStartDateYy,pr.arvStartDateMm,pr.arvStartDateDd),1,e.date_created,UUID()
FROM itech.encounter c, encounter e,itech.prescriptionOtherFields pr
WHERE e.uuid = c.encGuid and c.encounterType in (5,18) and pr.patientID=c.patientID and pr.arvStartDateYy>0 and
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
case when FindNumericValue(v.numDaysDesc)>0 then FindNumericValue(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=90 and FindNumericValue(v.numDaysDesc)>0;
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
v.drugID=90 and (v.dispensed=1 or formatDate(v.dispDateYy,v.dispDateMm,v.dispDateDd) is not null );

		 
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
case when FindNumericValue(v.dispAltNumPills)>0 then FindNumericValue(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=90 and FindNumericValue(v.dispAltNumPills)>0;

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
case when FindNumericValue(v.numDaysDesc)>0 then FindNumericValue(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=89 and FindNumericValue(v.numDaysDesc)>0;
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
v.drugID=89 and (v.dispensed=1 or formatDate(v.dispDateYy,v.dispDateMm,v.dispDateDd) is not null );

		 
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
case when FindNumericValue(v.dispAltNumPills)>0 then FindNumericValue(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=89 and FindNumericValue(v.dispAltNumPills)>0;

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
case when FindNumericValue(v.numDaysDesc)>0 then FindNumericValue(v.numDaysDesc) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=91 and FindNumericValue(v.numDaysDesc)>0;
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
v.drugID=91 and (v.dispensed=1 or formatDate(v.dispDateYy,v.dispDateMm,v.dispDateDd) is not null );

		 
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
case when FindNumericValue(v.dispAltNumPills)>0 then FindNumericValue(v.dispAltNumPills) else null end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,  itech.prescriptions v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=91 and FindNumericValue(v.dispAltNumPills)>0;

/* End of migration group 2*/


select 2 as test2;
select 7 as Ordonance;
   SET SQL_SAFE_UPDATES = 0;
   update migration_log set endtime=now() where prcodedure = 'ordonance';


END;