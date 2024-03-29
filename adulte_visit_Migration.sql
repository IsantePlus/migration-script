drop procedure if exists adult_visit_migration;
DELIMITER $$ 

CREATE PROCEDURE adult_visit_migration()
BEGIN
  DECLARE done INT DEFAULT FALSE;

  DECLARE vvisit_type_id INT;
  DECLARE obs_datetime_,vobs_datetime,vdate_created,vencounter_datetime datetime;
  DECLARE vobs_id,vperson_id,vconcept_id,vencounter_id,vlocation_id INT;
  DECLARE vreferHosp,vreferVctCenter,vreferPmtctProg,vreferOutpatStd,vreferCommunityBasedProg,vfirstCareOtherFacText varchar(100);
 

DECLARE source_reference CURSOR  for 
SELECT DISTINCT e.patient_id,159936,e.encounter_id,e.encounter_datetime,e.location_id,
referHosp,referVctCenter,referPmtctProg,referOutpatStd,referCommunityBasedProg,firstCareOtherFacText,e.date_created
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and e.encounter_datetime = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
(referHosp=1 or referVctCenter=1 or referPmtctProg=1 or referOutpatStd=1 or referCommunityBasedProg=1 or firstCareOtherFacText=1);
  
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE; 

SET FOREIGN_KEY_CHECKS=0;

/* SIGNES VITAUX MENU */
/*DATA Migration for vitals Temp*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT c.patient_id,5088,c.encounter_id,c.encounter_datetime,c.location_id,
CASE WHEN v.vitalTempUnits=2 THEN ROUND((substring_index(replace(v.vitalTemp,',','.'),'.',2)+0-32)/1.8000,2) 
ELSE ROUND(substring_index(replace(v.vitalTemp,',','.'),'.',2)+0,2) END,1,c.date_created,UUID()
from encounter c, itech.encounter e, itech.vitals v 
WHERE c.uuid = e.encGuid and 
e.patientID = v.patientID and 
e.sitecode = v.sitecode and 
concat(e.visitDateYy,'-',e.visitDateMm,'-',e.visitDateDd) = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) and 
e.seqNum = v.seqNum AND 
(substring_index(replace(v.vitalTemp,',','.'),'.',2)+0 > 0 AND vitalTempUnits IS NOT NULL);

select 4 as vital1;
/*DATA Migration for vitals TA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5085,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.vitalBPUnits=1 THEN substring_index(replace(digits(v.vitalBp1)+0,',','.'),'.',2)*10
WHEN v.vitalBPUnits=2 THEN substring_index(replace(digits(v.vitalBp1)+0,',','.'),'.',2) END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and
v.seqNum=c.seqNum and c.sitecode = v.sitecode and
date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
substring_index(replace(v.vitalBp1,',','.'),'.',2) REGEXP '^[0-9\.]+$' and v.vitalBp1 IS NOT NULL AND v.vitalBp1 <> '';

select 5 as vital10;

INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5086,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.vitalBPUnits=1 THEN substring_index(replace(digits(v.vitalBp2),',','.'),'.',2)*10
WHEN v.vitalBPUnits=2 THEN substring_index(replace(digits(v.vitalBp2),',','.'),'.',2) END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and
c.sitecode = v.sitecode and v.seqNum=c.seqNum and
date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
substring_index(replace(v.vitalBp2,',','.'),'.',2) REGEXP '^[0-9\.]+$' and v.vitalBp2 IS NOT NULL AND v.vitalBp2 <> '';

select 5 as vital10;
/*DATA Migration for vitals POULS*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5087,e.encounter_id,e.encounter_datetime,e.location_id,digits(v.vitalHr),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and 
c.patientID = v.patientID and 
c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and 
date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd)
AND v.vitalHr<>'';
select 5 as vital11;

/*DATA Migration for vitals FR*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5242,e.encounter_id,e.encounter_datetime,e.location_id,digits(v.vitalRr),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and 
c.patientID = v.patientID and 
c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and 
date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd)
AND v.vitalRr<>'';

select 5 as vital12;
/*DATA Migration for vitals TAILLE*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5090,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN digits(v.vitalHeightCm)>0 and digits(vitalHeight)>0 THEN digits(v.vitalHeightCm)+digits(vitalHeight)*100
WHEN digits(vitalHeight)>0  and digits(v.vitalHeightCm)=0 THEN digits(v.vitalHeight)*100
WHEN digits(v.vitalHeightCm)>0 and digits(vitalHeight)=0  THEN digits(v.vitalHeightCm)
ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and 
c.patientID = v.patientID and 
c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
(digits(v.vitalHeight)>0 OR digits(v.vitalHeightCm)>0);
select 5 as vital13;

/*DATA Migration for vitals POIDS*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5089,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.vitalWeightUnits=1 THEN digits(v.vitalWeight)
WHEN v.vitalWeightUnits=2  THEN digits(v.vitalWeight)/2.2046
ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and 
c.patientID = v.patientID and 
c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
digits(v.vitalWeight)>0 and v.vitalWeightUnits in (1,2);

/*END OF SIGNES VITAUX MENU*/

select 5 as vital2;
/*STARTING SOURCE DE RÉFÉRENCE MENU*/ 
OPEN source_reference;

source_reference_loop: LOOP
  FETCH source_reference INTO vperson_id,vconcept_id,vencounter_id,vencounter_datetime,vlocation_id, vreferHosp,
	                          vreferVctCenter,vreferPmtctProg,vreferOutpatStd,vreferCommunityBasedProg,vfirstCareOtherFacText,vdate_created;
    IF done THEN
      LEAVE source_reference_loop;
    END IF;
	
select 6 as source;
	/*MIGRATION FOR Hôpital (patient a été hospitalisé antérieurement)*/
	if(vreferHosp=1) then 
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
	values (vperson_id,vconcept_id,vencounter_id,vencounter_datetime,vlocation_id,5485,1,vdate_created,uuid());
	end if;
select 7 as source1;	
	/*MIGRATION FOR Centres CDV intégrés*/
	if(vreferVctCenter=1) then 
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
	values (vperson_id,vconcept_id,vencounter_id,vencounter_datetime,vlocation_id,159940,1,vdate_created,uuid());
	end if;

	
	/*MIGRATION FOR Programme PTME*/
	if(vreferPmtctProg=1) then 
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
	values (vperson_id,vconcept_id,vencounter_id,vencounter_datetime,vlocation_id,159937,1,vdate_created,uuid());
	end if;
	
	/*MIGRATION FOR Clinique Externe*/
	if(vreferOutpatStd=1) then 
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
	values (vperson_id,vconcept_id,vencounter_id,vencounter_datetime,vlocation_id,160542,1,vdate_created,uuid());
	end if;
	
    /*MIGRATION FOR Programmes communautaires*/
	if(vreferCommunityBasedProg=1) then 
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
	values (vperson_id,vconcept_id,vencounter_id,vencounter_datetime,vlocation_id,159938,1,vdate_created,uuid());
	end if;
		
	/*MIGRATION FOR Transfert d'un autre établissement de santé*/
	if(vfirstCareOtherFacText<>'') then 
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,comments,creator,date_created,uuid)
	values (vperson_id,vconcept_id,vencounter_id,vencounter_datetime,vlocation_id,5622,vfirstCareOtherFacText,1,vdate_created,uuid());
	end if;
		
	/*END OF SOURCE DE RÉFÉRENCE MENU*/

  END LOOP;
  
  CLOSE source_reference;
  
 /* Date des premiers soins dans cet établissement */ 
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='d9885523-a923-474b-88df-f3294d422c3c'),e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(FindNumericValue(v.firstCareOtherYy),FindNumericValue(v.firstCareOtherMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.firstCareOtherYy)>0 AND FindNumericValue(v.firstCareOtherMm)>0; 
  
/* Transfert avec dossier médical */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='30735143-5968-4bee-8bb9-8a07f3c5b57b'),e.encounter_id,e.encounter_datetime,e.location_id,
case when medRecord=1 then 1065
     when medRecord=2 then 1066
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
medRecord in (1,2); 

/* Transfert sous ARV */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='84ea41d3-fc79-418b-ae8c-6a8cf27de66e'),e.encounter_id,e.encounter_datetime,e.location_id,
case when transferOnArv=1 then 1065
     when transferOnArv=2 then 1066
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
transferOnArv in (1,2); 
  
  select 7 as source_reference;
  	
	/*STARTING TEST ANTICORPS VIH MENU*/
	   /*Migration for Date du premier test (anticorps) VIH positif*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160082,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(FindNumericValue(v.firstTestYy),FindNumericValue(v.firstTestMm),FindNumericValue(v.firstTestDd)),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.firstTestYy)>0 AND FindNumericValue(v.firstTestMm)>0;
		
select 8 as anticorps;
		
		/*Migration for Établissement où le test a été réalisé*/
		 /*Cet établissement */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159936,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.firstTestThisFac=1 THEN 163266
		ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.firstTestThisFac=1;
		
		/*Autre */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,comments,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159936,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.firstTestOtherFac=1 THEN 164407
		ELSE NULL
	END,v.firstTestOtherFacText,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.firstTestOtherFac=1;	

/* Date du test de répétition dans cet établissement */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='b8bdec55-6b04-4750-958c-e09eed84a2f8') ,e.encounter_id,e.encounter_datetime,e.location_id,
	formatDate(FindNumericValue(v.repeatTestYy),FindNumericValue(v.repeatTestMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.repeatTestYy)>1;	

/* Résultats reçus par le patient ? */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,164848 ,e.encounter_id,e.encounter_datetime,e.location_id,
	case when ifnull(FindNumericValue(v.firstTestResultsReceived),0)=1 then 1065
	     when ifnull(FindNumericValue(v.firstTestResultsReceived),0)=2 then 1066
    end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
ifnull(v.firstTestResultsReceived,0) in (1,2);

	
	/*END OF TEST ANTICORPS VIH MENU*/
 
 select 9 as etablissement;
 
 	/*STARTING ÉTAT DE FONCTIONNEMENT MENU*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162753,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.functionalStatus=1 THEN 159468
	 WHEN v.functionalStatus=2 THEN 160026
	 WHEN v.functionalStatus=4 THEN 162752
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.functionalStatus>0;
	/*END OF ÉTAT DE FONCTIONNEMENT MENU*/
 
 
 /*PLANNING FAMILIAL*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,965,e.encounter_id,e.encounter_datetime,e.location_id,
 v.famPlan,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.famPlan in (1,2);

 /*Methop PF Preservatif*/
  INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,374,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.famPlanMethodCondom=1 THEN 190
     ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.famPlanMethodCondom=1;

 /*Methop PF DMPA*/
  INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,374,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.famPlanMethodDmpa=1 THEN 5279
     ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.famPlanMethodDmpa=1;
 
  /*Methop PF Pillules*/
  INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,374,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.famPlanMethodOcPills=1 THEN 780
     ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.famPlanMethodOcPills=1;

  /*Methop PF Ligature des trompes*/
  INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,374,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.famPlanMethodTubalLig=1 THEN 1472
     ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.famPlanMethodTubalLig=1;

  /*Methop PF Autres preciser */
  INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,comments,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,374,e.encounter_id,e.encounter_datetime,e.location_id,v.famPlanOtherText
,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.famPlanOtherText<>'';
 
 
 /*STARTING ANTECEDENTS OBSTETRIQUES ET GROSSESSE MENU*/
		/*GRAVIDA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5624,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN FindNumericValue(v.gravida)>0 THEN FindNumericValue(v.gravida)
     ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
 FindNumericValue(v.gravida)>0;
		
		
		/*PARA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1053,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN FindNumericValue(v.para)>0 THEN FindNumericValue(v.para)
     ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
 FindNumericValue(v.para)>0;
		
		/*Aborta*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1823,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN FindNumericValue(v.aborta)>0 THEN FindNumericValue(v.aborta)
     ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.aborta)>0;
		
		/*Enfants vivants*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1825,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN FindNumericValue(v.children)>0 THEN FindNumericValue(v.children)
     ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
 FindNumericValue(v.children)>0;
		
		/*Grossesse actuelle*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5272,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.pregnant=1 THEN 1065
	 WHEN v.pregnant=2 THEN 1066
	 WHEN v.pregnant=4 THEN 1067
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
 v.pregnant<>'';

 select 9 as pregnant; 
		/*Migration for Date du dernier Pap Test*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163267,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(FindNumericValue(v.papTestYy),FindNumericValue(v.papTestMm),FindNumericValue(v.papTestDd)),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
 FindNumericValue(v.papTestYy)>0;	
		
		/* Migration for Date des dernières règles*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1427,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(FindNumericValue(v.pregnantLmpYy),FindNumericValue(v.pregnantLmpMm),FindNumericValue(v.pregnantLmpDd)),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
 FindNumericValue(v.pregnantLmpYy)>0;	
	
	select 9 as pregnantLmpDd; 
	
	

/*Migration of Dépistage du cancer du Col */	
	/*Migration for obsgroup*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160714,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id in (146602,70485,163589,70029);	

select 9 as depistage1;  

delete from itech.obs_concept_group where 1;
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=160714 
GROUP BY openmrs.obs.person_id,encounter_id;

select 9 as depistage2; 
		
/*migration for the Dépistage du cancer du Col*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1651,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.value_numeric=1 then 151185	 ELSE NULL END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs o ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id=o.encounter_id  and  o.value_numeric=1 and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = o.location_id and o.concept_id=146602 ;

select 9 as depistage3; 

/*migration for the Dépistage du cancer du Col*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160721,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.value_numeric=1 then 1065 when o.value_numeric=2 then 1066 ELSE NULL END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs o ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.encounter_id=o.encounter_id  and  o.value_numeric in (1,2) and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = o.location_id and o.concept_id=146602;	

select 9 as depistage4; 

/* Date du dernier dépistage du cancer du Col */	
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,165429,e.encounter_id,e.encounter_datetime,e.location_id,o.value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs o
WHERE e.uuid = c.encGuid and c.encounter_id=o.encounter_id  and 
c.sitecode = o.location_id and o.concept_id=70485 and o.value_datetime is not null;
select 9 as depistage5; 

/* Méthode utilisée du cancer du Col */	
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163589,e.encounter_id,e.encounter_datetime,e.location_id,
case when o.value_numeric=1 then 885
     when o.value_numeric=2 then 162816
	 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs o
WHERE e.uuid = c.encGuid and c.encounter_id=o.encounter_id  and  o.value_numeric in (1,2) and 
c.sitecode = o.location_id and o.concept_id=163589;

select 9 as depistage6; 

/* Résultat du cancer du Col */	
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160704,e.encounter_id,e.encounter_datetime,e.location_id,
case when o.value_numeric=1 then 1115
     when o.value_numeric=2 then 1116
	 when o.value_numeric=4 then 1067
	 else null end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs o
WHERE e.uuid = c.encGuid and 
c.encounter_id=o.encounter_id  and  
o.value_numeric in (1,2,4) and 
c.sitecode = o.location_id and o.concept_id=70029;
	
	/*END OF ANTECEDENTS OBSTETRIQUES ET GROSSESSE MENU*/
 
 select 9 as obstetric;
 
  /*STARTING MIGRATION FOR MODE PROBABLE DE TRANSMISSION DU VIH MENU*/
		/*Rapports sexuels avec un homme*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='c2b3c5cb-f1e6-4d3d-ad18-5ecf71b26dc2'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=1 and v.riskAnswer in (1,2);

select 9 as sexualHomme;

delete from itech.obs_concept_group where 1;
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='c2b3c5cb-f1e6-4d3d-ad18-5ecf71b26dc2'
GROUP BY openmrs.obs.person_id,encounter_id;
		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1061,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN v.riskID=1 AND v.riskAnswer=1 THEN 163290
	 WHEN v.riskID=1 AND v.riskAnswer=2 THEN 1066
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=1 and v.riskAnswer in (1,2);
		
		/*Rapports sexuels avec une femme*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='0906f171-72d4-4727-8ede-97a47c2e25ee'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=3 and v.riskAnswer in (1,2);


delete from itech.obs_concept_group where 1;
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='0906f171-72d4-4727-8ede-97a47c2e25ee'
GROUP BY openmrs.obs.person_id,encounter_id;
		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1061,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN v.riskID=3 AND v.riskAnswer=1 THEN 163291
	 WHEN v.riskID=3 AND v.riskAnswer=2 THEN 1066
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=3 and v.riskAnswer in (1,2);		
		
		/*personne qui s'injecte de la drogue */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='d526575e-5fa1-45c6-b8ed-73a2cba0fba0'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=5 and v.riskAnswer in (1,2);


delete from itech.obs_concept_group where 1;
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='d526575e-5fa1-45c6-b8ed-73a2cba0fba0'
GROUP BY openmrs.obs.person_id,encounter_id;
		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1061,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN v.riskID=5 AND v.riskAnswer=1 THEN 105
	 WHEN v.riskID=5 AND v.riskAnswer=2 THEN 1066
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=5 and v.riskAnswer in (1,2);	


		/*Injection de drogues correct */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='f6a51d0c-eb19-4875-8c37-85e39f0def00'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=9 and v.riskAnswer in (1,2);


delete from itech.obs_concept_group where 1;
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='f6a51d0c-eb19-4875-8c37-85e39f0def00'
GROUP BY openmrs.obs.person_id,encounter_id;
		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1061,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN v.riskID=9 AND v.riskAnswer=1 THEN 105
	 WHEN v.riskID=9 AND v.riskAnswer=2 THEN 1066
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=9 and v.riskAnswer in (1,2);


	
		/*Bénéficier de sang/dérivé sanguin*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='92259610-b7b8-4723-b879-6e33fdd4b817'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=15 and v.riskAnswer in (1,2);


delete from itech.obs_concept_group where 1;
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='92259610-b7b8-4723-b879-6e33fdd4b817'
GROUP BY openmrs.obs.person_id,encounter_id;
		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1061,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN v.riskID=15 AND v.riskAnswer=1 THEN 1063
	 WHEN v.riskID=15 AND v.riskAnswer=2 THEN 1066
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=15 and v.riskAnswer in (1,2);		



		/*Bénéficier de sang/dérivé sanguin rapport hetero*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='df47e128-268f-4238-9b13-f829c01ae7d8'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=31 and v.riskAnswer in (1,2);


delete from itech.obs_concept_group where 1;
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='df47e128-268f-4238-9b13-f829c01ae7d8'
GROUP BY openmrs.obs.person_id,encounter_id;
		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1061,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN v.riskID=31 AND v.riskAnswer=1 THEN 1063
	 WHEN v.riskID=31 AND v.riskAnswer=2 THEN 1066
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=31 and v.riskAnswer in (1,2);	



		
		/*Migration FOR Transmission mère a enfant*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='92259610-b7b8-4723-b879-6e33fdd4b817'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=14 and v.riskAnswer in (1,2,4);


delete from itech.obs_concept_group where 1;
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='92259610-b7b8-4723-b879-6e33fdd4b817'
GROUP BY openmrs.obs.person_id,encounter_id;
		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1061,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN v.riskID=14 AND v.riskAnswer=1 THEN 163273
	 WHEN v.riskID=14 AND v.riskAnswer=2 THEN 1066
	 WHEN v.riskID=14 AND v.riskAnswer=4 THEN 1067
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=14 and v.riskAnswer in (1,2,4);		
		
		/*MIGRATION FOR - homme bisexuel */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='9d6ee2a2-8547-4fa9-a2d8-301d009ca3a5'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=6 and v.riskAnswer in (1,2,4);


delete from itech.obs_concept_group where 1;
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='9d6ee2a2-8547-4fa9-a2d8-301d009ca3a5'
GROUP BY openmrs.obs.person_id,encounter_id;
		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1061,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN v.riskID=6 AND v.riskAnswer=1 THEN 163275
	 WHEN v.riskID=6 AND v.riskAnswer=2 THEN 1066
	 WHEN v.riskID=6 AND v.riskAnswer=4 THEN 1067
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=6 and v.riskAnswer in (1,2,4);		
		/*MIGRATION FOR Rapports hétérosexuelles avec :
		  - personne SIDA/VIH+
		*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='844017f9-8d6a-4b9a-8347-637284b43893'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=19 and v.riskAnswer in (1,2,4);


delete from itech.obs_concept_group where 1;
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='844017f9-8d6a-4b9a-8347-637284b43893'
GROUP BY openmrs.obs.person_id,encounter_id;
		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1061,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN v.riskID=19 AND v.riskAnswer=1 THEN 163289
	 WHEN v.riskID=19 AND v.riskAnswer=2 THEN 1066
	 WHEN v.riskID=19 AND v.riskAnswer=4 THEN 1067
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=19 and v.riskAnswer in (1,2,4);		
		
	
select 3 as sid;
		/*FOR THE DATE*//*Bénéficier de sang/dérivé sanguin*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163268,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.riskYy),FindNumericValue(v.riskMm),FindNumericValue(v.riskDd)),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=19 and v.riskAnswer=1 and FindNumericValue(v.riskYy)>0;

select 9 as riskAnswer; 		
/*MIGRATION FOR Accident d'exposition au sang*/
	/*Migration for obsgroup*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163288,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=12 and v.riskAnswer=1;

delete from itech.obs_concept_group where 1;
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=160741 
GROUP BY openmrs.obs.person_id,encounter_id;


		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160581,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN v.riskID=12 AND v.riskAnswer=1 THEN 163274
     WHEN v.riskID=12 AND v.riskAnswer=2 THEN 1066
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=12 and v.riskAnswer=1;
		/*migration for the date*/
		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162601,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.riskYy),FindNumericValue(v.riskMm),FindNumericValue(v.riskDd)),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.riskID=12 and v.riskAnswer=1 and FindNumericValue(v.riskYy)>0;		
	
	/*END OF MIGRATION FOR MODE PROBABLE DE TRANSMISSION DU VIH MENU*/
 select 9 as riskAnswer1; 

/*MIGRATION FOR AUTRES FACTEURS DE RISQUE MENU*/
	/*Migration for Histoire ou présence de syphilis*/
	/*Migration for obsgroup*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163292,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND v.riskID=32
AND (v.riskAnswer=1 OR v.riskAnswer=2 OR v.riskAnswer=4);
		
delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163292 
GROUP BY openmrs.obs.person_id,encounter_id;		
		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163276,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN v.riskID=32 AND v.riskAnswer=1 THEN 1065
	 WHEN v.riskID=32 AND v.riskAnswer=2 THEN 1066
	 WHEN v.riskID=32 AND v.riskAnswer=4 THEN 1067
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND v.riskID=32
AND (v.riskAnswer=1 OR v.riskAnswer=2 OR v.riskAnswer=4);

		/*Histoire ou présence d'autre IST*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,156660,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN v.riskID=11 AND v.riskAnswer=1 THEN 1065
	 WHEN v.riskID=11 AND v.riskAnswer=2 THEN 1066
	 WHEN v.riskID=11 AND v.riskAnswer=4 THEN 1067
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND v.riskID=11
AND (v.riskAnswer=1 OR v.riskAnswer=2 OR v.riskAnswer=4);
		
		/*migration for Victime d'agression sexuelle*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,123160,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN v.riskID=13 AND v.riskAnswer=1 THEN 1065
	 WHEN v.riskID=13 AND v.riskAnswer=2 THEN 1066
	 WHEN v.riskID=13 AND v.riskAnswer=4 THEN 1067
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND v.riskID=13
AND (v.riskAnswer=1 OR v.riskAnswer=2 OR v.riskAnswer=4);
	

/* Histoire ou présence de TB */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='a3e61f72-6066-4af6-94e5-958458c04418'),e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN v.riskID=36 AND v.riskAnswer=1 THEN 1065
	 WHEN v.riskID=36 AND v.riskAnswer=2 THEN 1066
	 WHEN v.riskID=36 AND v.riskAnswer=4 THEN 1067
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND v.riskID=36
AND (v.riskAnswer=1 OR v.riskAnswer=2 OR v.riskAnswer=4);
	
		/*Migration for Rapports sexuels :
			- ≥ 2 personnes dans les 3 dernières mois
		*/
		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5567,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.riskID=33 AND v.riskAnswer=1 THEN 1
     WHEN v.riskID=33 AND v.riskAnswer=2 THEN 2
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) 
AND v.riskID=33 AND v.riskAnswer=1;		
/* sans preservatif */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159218,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.riskID=4 AND v.riskAnswer=1 THEN 1065
     WHEN v.riskID=4 AND v.riskAnswer=2 THEN 1066
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) 
AND v.riskID=4 AND v.riskAnswer=1;			
		
		/*- par voie anale*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163278,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.riskID=7 AND v.riskAnswer=1 THEN 1065
     WHEN v.riskID=7 AND v.riskAnswer=2 THEN 1066
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) 
AND v.riskID=7 AND (v.riskAnswer=1 or v.riskAnswer=2);	
		
		/*- avec travailleur/euse de sexe*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160581,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.riskID=20 AND (v.riskAnswer=1 or v.riskAnswer=2 ) THEN 160580
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) 
AND v.riskID=20 AND (v.riskAnswer=1 or v.riskAnswer=2);			

INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160580,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.riskID=20 AND v.riskAnswer=1 THEN 1065
     WHEN v.riskID=20 AND v.riskAnswer=2 THEN 1066
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) 
AND v.riskID=20 AND (v.riskAnswer=1 or v.riskAnswer=2);	
		
		/* - L'échange de sexe pour argent/choses*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160581,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.riskID=34 AND (v.riskAnswer=1 or v.riskAnswer=2 ) THEN 160579
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) 
AND v.riskID=34 AND (v.riskAnswer=1 or v.riskAnswer=2);			

INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160579,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.riskID=34 AND v.riskAnswer=1 THEN 1065
     WHEN v.riskID=34 AND v.riskAnswer=2 THEN 1066
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessments v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) 
AND v.riskID=34 AND (v.riskAnswer=1 or v.riskAnswer=2);			

	/*END OF MIGRATION FOR AUTRES FACTEURS DE RISQUE MENU*/ 
 
 /*RAPPORTS SEXUELS DANS LES TROIS (3) DERNIERS MOIS*/
 
 	/*Migration for obsgroup*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163279,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessment v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) 
AND (v.lastQuarterSex in (1,2) OR v.lastQuarterSexWithoutCondom in (1,2));
		
delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163279 
GROUP BY openmrs.obs.person_id,encounter_id;	
 
 /* rapport sexuel */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160109,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN v.lastQuarterSex=1  THEN 1065
     WHEN v.lastQuarterSex=2 THEN 1066
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessment v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) 
AND v.lastQuarterSex in (1,2);		

/* si oui */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1357,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN v.lastQuarterSexWithoutCondom=1  THEN 1358
     WHEN v.lastQuarterSexWithoutCondom=2 THEN 1090
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessment v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) 
AND v.lastQuarterSexWithoutCondom in (1,2);	
 
 /* end group*/
 
 
 /* Statut sérologique du conjoint(e) */
 	/*Migration for obsgroup*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163279,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessment v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) 
AND ( v.lastQuarterSeroStatPart in (1,2,4));
		
delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs
WHERE openmrs.obs.concept_id=163279 
GROUP BY openmrs.obs.person_id,encounter_id;	
 
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1436,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN v.lastQuarterSeroStatPart=1  THEN 703
     WHEN v.lastQuarterSeroStatPart=2 THEN 664
	 WHEN v.lastQuarterSeroStatPart=4 THEN 1067
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.riskAssessment v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) 
AND v.lastQuarterSeroStatPart in (1,2,4);	


/*ACTIVITE SEXUELS */
/*Rapport sexuel */
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160109,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.sexInt=1  THEN 1065
     WHEN v.sexInt=2 THEN 1066
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) 
AND v.sexInt in (1,2);	

/*Rapports sexuels sans préservatif*/
 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160581,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.sexIntWOcondom=1  THEN 159218
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) 
AND v.sexIntWOcondom in (1,2);	
 
 select 10 as testColumn;
 
 
 
 
/* END OF RAPPORTS SEXUELS DANS LES TROIS (3) DERNIERS MOIS*/
 
 
 
 
 	/*STARTING MIGRATION FOR COMPTE CD4 MENU*/
		/*Compte CD4 le plus bas*/		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159375,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN FindNumericValue(v.lowestCd4Cnt)>0 THEN FindNumericValue(lowestCd4Cnt)
		ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.lowestCd4Cnt)>0;	
 select 10 as testColumn1;

		/* DATE */		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159376,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(FindNumericValue(v.lowestCd4CntYy),FindNumericValue(v.lowestCd4CntMm),FindNumericValue(v.lowestCd4CntDd)),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.lowestCd4Cnt<>'' AND FindNumericValue(v.lowestCd4CntYy)>0;

 select 10 as testColumn2;
		/*Non effectué/Inconnu*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1941,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.lowestCd4CntNotDone=1 THEN 1066 ELSE NULL END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.lowestCd4CntNotDone=1;
 select 10 as testColumn3;
		/*MIGRATION for Virémie*/
	
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163280,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN FindNumericValue(v.firstViralLoad)>0 THEN FindNumericValue(lowestCd4Cnt)
		ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.firstViralLoad)>0
AND FindNumericValue(lowestCd4Cnt) > 0;	
 select 10 as testColumn4;
		/* DATE */		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163281,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(FindNumericValue(v.firstViralLoadYy),FindNumericValue(v.firstViralLoadMm),FindNumericValue(v.firstViralLoadDd)),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.firstViralLoad<>'' AND FindNumericValue(v.firstViralLoadYy)>0;

		/*Non effectué/Inconnu*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163310,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.firstViralLoadNotDone=1 THEN 1118 ELSE NULL END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.firstViralLoadNotDone=1;

 select 10 as testColumn3;
		
	/*END OF MIGRATION FOR COMPTE CD4 MENU*/
 
  select 11 as testColumn;
 
 	/*MIGRATION FOR STATUT TB MENU*/
			INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1659,e.encounter_id,e.encounter_datetime,e.location_id,
	CASE WHEN v.asymptomaticTb=1 AND (v.completeTreat=0 OR v.completeTreat='') AND (v.currentTreat=0 OR v.currentTreat='') THEN 1660
		WHEN v.completeTreat=1 AND (v.asymptomaticTb=0 OR v.asymptomaticTb='') AND (v.currentTreat=0 OR v.currentTreat='') THEN 1663
		WHEN v.currentTreat=1 AND (v.asymptomaticTb=0 OR v.asymptomaticTb='') AND (v.completeTreat=0 OR v.completeTreat='') THEN 1662
		ELSE NULL
	END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.tbStatus  v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
(v.asymptomaticTb=1 OR v.completeTreat=1 OR v.currentTreat=1);
	
		/*Migration for Date complété */		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159431,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(FindNumericValue(v.completeTreatYy),FindNumericValue(v.completeTreatMm),FindNumericValue(v.completeTreatDd)),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.tbStatus v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.completeTreat=1 AND FindNumericValue(v.completeTreatYy)>0;


/* Numero Dossier TB*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='e5803d79-0f64-4904-a7b3-971003c1ba36'),e.encounter_id,e.encounter_datetime,e.location_id,
left(v.currentTreatNo,50),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.tbStatus v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
ifnull(v.currentTreatNo,'')<>'';

		/*Migration for Etablissement 1 */		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162724 as conscept_id,e.encounter_id,e.encounter_datetime,e.location_id,
completeTreatFac as value_text,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.tbStatus v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
ifnull(v.completeTreatFac,'')<>'';

		/*Migration for Etablissement 2 */		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,
(select concept_id from concept where uuid='4a580214-39ae-4986-a25c-fd05e102fb86') as conscept_id,e.encounter_id,e.encounter_datetime,e.location_id,
currentTreatFac as value_text,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.tbStatus v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
ifnull(v.currentTreatFac,'')<>'';
		/*On Going with james*/
	/*END OF MIGRATION FOR STATUT TB MENU */
	
	
	 select 12 as testColumn;
	
	
	/*MIGRATION FOR VACCINS MENU*/
	/*MIGRATION FOR Hépatite B*/
	/*concept group */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='120157b7-a596-4623-8f7d-960fd686fb67'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals  v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
(v.vaccHepB=1);

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='120157b7-a596-4623-8f7d-960fd686fb67' 
GROUP BY openmrs.obs.person_id,encounter_id;
	

		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN v.vaccHepB=1 THEN 782
     WHEN v.vaccHepB=2 THEN 1066
     WHEN v.vaccHepB=4 THEN 1067
	 ELSE NULL END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals  v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) 
AND v.vaccHepB in (1,2,4);
		
/*migration for MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.vaccHepBYy),FindNumericValue(v.vaccHepBMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals  v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.vaccHepB=1 AND FindNumericValue(v.vaccHepBYy)>0;

/*migration for Nombre de dose */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN digits(v.vaccHepB)=1 AND digits(v.hepBdoses)>=0 THEN digits(v.hepBdoses) ELSE NULL END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals  v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.vaccHepB=1 AND digits(v.hepBdoses)>0 and v.hepBdoses<>'';

select 1 as hepatie;
		/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
		/*MIGRATION FOR Tétanos*/ 
		
	/*concept group */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='f9e79221-424c-44e9-a23d-3b507d326c32'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals  v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
(v.vaccTetanus=1);

select 108 as vaccin;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='f9e79221-424c-44e9-a23d-3b507d326c32' 
GROUP BY openmrs.obs.person_id,encounter_id;
		
select 109 as vaccin;		
/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,984,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN v.vaccTetanus=1 THEN 1685
     WHEN v.vaccTetanus=2 THEN 1066
     WHEN v.vaccTetanus=4 THEN 1067
	 ELSE NULL END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals  v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.vaccTetanus in (1,2,4);

	select 110 as vaccin;	
/*migration for MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1410,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.vaccTetanusYy,v.vaccTetanusMm,'XX'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals  v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.vaccTetanus=1 AND FindNumericValue(v.vaccTetanusYy)>0;

select 111 as vaccin;
/*migration for Nombre de dose */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1418,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN v.vaccTetanus=1 AND FindNumericValue(v.tetDoses)>=0 THEN FindNumericValue(v.tetDoses) ELSE NULL END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals  v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.vaccTetanus=1 AND FindNumericValue(v.tetDoses)>0 and v.tetDoses<>'';		
		/*On going*/
		/*Autre preciser*/
	/*END OF MIGRATION FOR VACCINS MENU*/
	
select 2 as vaccin;

/*MIGRATION FOR SYMPTÔMES MENU*/
	  /*migration for Douleur abdominale*/
	  /*concept group */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='280f7e9e-73de-4fa1-899e-3e4db50915db'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7000 and o.value_boolean=1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='280f7e9e-73de-4fa1-899e-3e4db50915db'
GROUP BY openmrs.obs.person_id,encounter_id;
	
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1728,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7000 AND o.value_boolean=1 THEN 151
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7000 and o.value_boolean=1 and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;		

		/*Migration for YES */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1729,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7000 AND o.value_boolean=1 THEN 1065
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7000 and o.value_boolean=1 and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;
		/*=========================================================================================================*/
		/*migration for Anorexie/Perte d'appétit*/
	  /*concept group */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='8d118f23-1934-4ae3-9a0c-2045dd67c849'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7001 and o.value_boolean=1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='8d118f23-1934-4ae3-9a0c-2045dd67c849' 
GROUP BY openmrs.obs.person_id,encounter_id;
	
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1728,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7001 AND o.value_boolean=1 THEN 6031
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7001 and o.value_boolean=1 and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;		

		/*Migration for YES */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1729,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7001 AND o.value_boolean=1 THEN 1065
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7001 and o.value_boolean=1 and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;	
		/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
		/*migration for Toux*/
	  /*concept group */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='78b69c38-8119-4634-8def-4b75e079243f'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7004 and o.value_boolean=1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='78b69c38-8119-4634-8def-4b75e079243f' 
GROUP BY openmrs.obs.person_id,encounter_id;
	
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1728,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7004 AND o.value_boolean=1 THEN 143264
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7004 and o.value_boolean=1 and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

		/*Migration for YES */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1729,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7004 AND o.value_boolean=1 THEN 1065
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7004 and o.value_boolean=1  and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id; 
		/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
		/*Migration for Toux/Expectoration (sauf hémoptysie)*/		
		 /*concept group */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='64e7b85c-355e-4c40-a11e-2893934bb38b'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7008 and o.value_boolean=1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='64e7b85c-355e-4c40-a11e-2893934bb38b' 
GROUP BY openmrs.obs.person_id,encounter_id;
	
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1728,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7008 AND o.value_boolean=1 THEN 5957
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7008 and o.value_boolean=1 and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id; 	

		/*Migration for YES */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1729,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7008 AND o.value_boolean=1 THEN 1065
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7008 and o.value_boolean=1 and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;		 
		/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
		/*Migration for Dyspnée*/
		 /*concept group */
		 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='81db35ed-27a7-4e26-a54a-1ddff821ca5e'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7007 and o.value_boolean=1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='81db35ed-27a7-4e26-a54a-1ddff821ca5e'
GROUP BY openmrs.obs.person_id,encounter_id;

		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1728,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7007 AND o.value_boolean=1 THEN 122496
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7007 and o.value_boolean=1  and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

		/*Migration for YES */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1729,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7007 AND o.value_boolean=1 THEN 1065
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7007 and o.value_boolean=1 and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;			 

	/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
		/*Migration for Céphalée*/
	 /*concept group */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='7ff8201b-93b9-4aa3-b86c-ab9c567a1f35'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7011 and o.value_boolean=1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='7ff8201b-93b9-4aa3-b86c-ab9c567a1f35' 
GROUP BY openmrs.obs.person_id,encounter_id;

		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1728,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7011 AND o.value_boolean=1 THEN 139084
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7011 and o.value_boolean=1  and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;	

		/*Migration for YES */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1729,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7011 AND o.value_boolean=1 THEN 1065
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7011 and o.value_boolean=1  and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;	 

		/*=============================================================================================================*/
		/*Migration for Hémoptysie*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='3d584639-8c55-45de-b202-f7405af953df'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7012 and o.value_boolean=1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='3d584639-8c55-45de-b202-f7405af953df' 
GROUP BY openmrs.obs.person_id,encounter_id;
	
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1728,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7012 AND o.value_boolean=1 THEN 138905
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7012 and o.value_boolean=1  and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;		

		/*Migration for YES */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1729,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7012 AND o.value_boolean=1 THEN 1065
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7012 and o.value_boolean=1  and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;			
		/*=================================================================================================================*/
		/*Migration for Nausée*/
		/*Concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='244851ca-731c-4ee1-8557-4c75cb38fe9b'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7013 and o.value_boolean=1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='244851ca-731c-4ee1-8557-4c75cb38fe9b' 
GROUP BY openmrs.obs.person_id,encounter_id;
	
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1728,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7013 AND o.value_boolean=1 THEN 5978
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7013 and o.value_boolean=1  and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;		

		/*Migration for YES */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1729,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7013 AND o.value_boolean=1 THEN 1065
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7013 and o.value_boolean=1  and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;
		/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
		/*Migration for Sueurs nocturnes*/
		/*Concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='3777f798-60fd-4f8c-acb6-c9bf879c8913'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7014 and o.value_boolean=1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='3777f798-60fd-4f8c-acb6-c9bf879c8913' 
GROUP BY openmrs.obs.person_id,encounter_id;
	
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1728,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7014 AND o.value_boolean=1 THEN 133027
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7014 and o.value_boolean=1  and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;	

		/*Migration for YES */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1729,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7014 AND o.value_boolean=1 THEN 1065
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7014 and o.value_boolean=1  and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;
		/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
		/*Migration for Perte de sensibilité*/
		/*Concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='bfa2b9d6-75d1-407e-b4a9-1df36e639429'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7015 and o.value_boolean=1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='bfa2b9d6-75d1-407e-b4a9-1df36e639429' 
GROUP BY openmrs.obs.person_id,encounter_id;
	
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1728,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7015 AND o.value_boolean=1 THEN 141635
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7015 and o.value_boolean=1  and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;		

		/*Migration for YES */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1729,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7015 AND o.value_boolean=1 THEN 1065
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7015 and o.value_boolean=1  and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;	
		/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
		/*Migration for Odynophagie/dysphagie*/
		/*Concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='b41e4d9d-b0f7-455c-851f-dc9c05fc519a'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7016 and o.value_boolean=1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='b41e4d9d-b0f7-455c-851f-dc9c05fc519a' 
GROUP BY openmrs.obs.person_id,encounter_id;

		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1728,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7016 AND o.value_boolean=1 THEN 118789
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7016 and o.value_boolean=1  and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;	

		/*Migration for YES */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1729,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7016 AND o.value_boolean=1 THEN 1065
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7024 and o.value_boolean=1  and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;		
		/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
		/*Migration for Eruption cutanée*/
		/*Concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='9c67aa65-9411-4ac7-b56f-b7f2ffe36192'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7024 and o.value_boolean=1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='9c67aa65-9411-4ac7-b56f-b7f2ffe36192' 
GROUP BY openmrs.obs.person_id,encounter_id;
	
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1728,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7024 AND o.value_boolean=1 THEN 512
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7024 and o.value_boolean=1 and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;	

		/*Migration for YES */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1729,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7024 AND o.value_boolean=1 THEN 1065
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7024 and o.value_boolean=1 and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;	
		/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
		/*Migration for Vomissement*/
		/*Concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='89803a57-4a1b-475d-9a7a-fbcd9f74c0c9'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7025 and o.value_boolean=1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='89803a57-4a1b-475d-9a7a-fbcd9f74c0c9'
GROUP BY openmrs.obs.person_id,encounter_id;
	
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1728,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7025 AND o.value_boolean=1 THEN 122983
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7025 and o.value_boolean=1 and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;	

		/*Migration for YES */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1729,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7025 AND o.value_boolean=1 THEN 1065
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7025 and o.value_boolean=1 and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;	

		/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
		/*Migration for Prurigo*/
		/*Concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='696e5e96-c3ca-4b01-a792-583dfcd4af2a'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7042 and o.value_boolean=1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='696e5e96-c3ca-4b01-a792-583dfcd4af2a' 
GROUP BY openmrs.obs.person_id,encounter_id;
	
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1728,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7042 AND o.value_boolean=1 THEN 128319
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7042 and o.value_boolean=1 and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;		

		/*Migration for YES */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1729,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7042 AND o.value_boolean=1 THEN 1065
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7042 and o.value_boolean=1 and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;			

		/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
		/*Migration for Autres, préciser :*/
		/*Concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='0671685b-ced1-459f-b31d-fa851985d117'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7044 and value_text<>'';

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='0671685b-ced1-459f-b31d-fa851985d117' 
GROUP BY openmrs.obs.person_id,encounter_id;
	
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,comments,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1728,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7044 THEN 5622
	 ELSE NULL
END,o.value_text,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7044 and value_text<>'' and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;		

		/*Migration for YES */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1729,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
CASE WHEN o.concept_id=7044 AND o.value_boolean=1 THEN 1065
	 ELSE NULL
END,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=7044 and value_text<>'' and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id;			
	/*END OF MIGRATION FOR SYMPTÔMES MENU*/

select 2 as symptome;	
 
 /*MIGRATION FOR EXAMEN CLINIQUE*/
		/* Migration for Général*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1119,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.physicalGeneral=1 THEN 159438
	 WHEN v.physicalGeneral=2 THEN 163293
	 WHEN v.physicalGeneral=4 THEN 1118
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd)
AND (v.physicalGeneral=1 OR v.physicalGeneral=2 OR v.physicalGeneral=4);	

		/*Migration for Peau*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1120,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.physicalSkin=1 THEN 1115
	 WHEN v.physicalSkin=2 THEN 1116
	 WHEN v.physicalSkin=4 THEN 1118
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd)
AND (v.physicalSkin=1 OR v.physicalSkin=2 OR v.physicalSkin=4);	

		/*Migration for Bouche/Orale*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163308,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.physicalOral=1 THEN 1115
	 WHEN v.physicalOral=2 THEN 1116
	 WHEN v.physicalOral=4 THEN 1118
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd)
AND (v.physicalOral=1 OR v.physicalOral=2 OR v.physicalOral=4);	
		/*Migration for Oreilles*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163337,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.physicalEarsNose=1 THEN 1115
	 WHEN v.physicalEarsNose=2 THEN 1116
	 WHEN v.physicalEarsNose=4 THEN 1118
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd)
AND (v.physicalEarsNose=1 OR v.physicalEarsNose=2 OR v.physicalEarsNose=4);	

		/*Migration for Nez*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163336,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.physicalEarsNose=1 THEN 1115
	 WHEN v.physicalEarsNose=2 THEN 1116
	 WHEN v.physicalEarsNose=4 THEN 1118
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd)
AND (v.physicalEarsNose=1 OR v.physicalEarsNose=2 OR v.physicalEarsNose=4);

		/*Migration for Yeux*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163309,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.physicalEyes=1 THEN 1115
	 WHEN v.physicalEyes=2 THEN 1116
	 WHEN v.physicalEyes=4 THEN 1118
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd)
AND (v.physicalEyes=1 OR v.physicalEyes=2 OR v.physicalEyes=4);	
		/*Migration for Ganglions lymphatiques*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1121,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.physicalLymph=1 THEN 1115
	 WHEN v.physicalLymph=2 THEN 1116
	 WHEN v.physicalLymph=4 THEN 1118
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd)
AND (v.physicalLymph=1 OR v.physicalLymph=2 OR v.physicalLymph=4);			
		
		/*Migration for Poumons*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1123,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.physicalLungs=1 THEN 1115
	 WHEN v.physicalLungs=2 THEN 1116
	 WHEN v.physicalLungs=4 THEN 1118
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd)
AND (v.physicalLungs=1 OR v.physicalLungs=2 OR v.physicalLungs=4);			

		/*Migration for Cardio-vasculaire*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1124,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.physicalCardio=1 THEN 1115
	 WHEN v.physicalCardio=2 THEN 1116
	 WHEN v.physicalCardio=4 THEN 1118
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd)
AND (v.physicalCardio=1 OR v.physicalCardio=2 OR v.physicalCardio=4);	
		
		/*Migration for Abdomen*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1125,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.physicalAbdomen=1 THEN 1115
	 WHEN v.physicalAbdomen=2 THEN 1116
	 WHEN v.physicalAbdomen=4 THEN 1118
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd)
AND (v.physicalAbdomen=1 OR v.physicalAbdomen=2 OR v.physicalAbdomen=4);	

		/*Migration for Urogénital*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1126,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.physicalUro=1 THEN 1115
	 WHEN v.physicalUro=2 THEN 1116
	 WHEN v.physicalUro=4 THEN 1118
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd)
AND (v.physicalUro=1 OR v.physicalUro=2 OR v.physicalUro=4);	

		/*Migration for Musculo-squeletal*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1128,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.physicalMusculo=1 THEN 1115
	 WHEN v.physicalMusculo=2 THEN 1116
	 WHEN v.physicalMusculo=4 THEN 1118
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd)
AND (v.physicalMusculo=1 OR v.physicalMusculo=2 OR v.physicalMusculo=4);	

		/*Migration for Neurologique*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1129,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.physicalNeuro=1 THEN 1115
	 WHEN v.physicalNeuro=2 THEN 1116
	 WHEN v.physicalNeuro=4 THEN 1118
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd)
AND (v.physicalNeuro=1 OR v.physicalNeuro=2 OR v.physicalNeuro=4);
		
		/*Migration for Description des conclusions anormales*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1391,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.clinicalExam<>'' THEN v.clinicalExam ELSE NULL END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND v.clinicalExam<>'';
		
	/*END OF MIGRATION FOR EXAMEN CLINIQUE*/
 
 select 3 as examen;
  
  /*MIGRATION FOR ÉVALUATION TB*/
		/*Migration for Présence de cicatrice BCG*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160265,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.presenceBCG=1 THEN 1065 ELSE NULL END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.tbStatus  v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.presenceBCG=1;		

		
		/*migration for Prophylaxie à I'INH*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1110,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.propINH=1 THEN 1679 ELSE NULL END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.tbStatus  v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.propINH=1;	


		/*Migration for Suspicion de TB selon les symptômes*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1659,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.suspicionTBwSymptoms=1 THEN 142177 ELSE NULL END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.tbStatus  v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.suspicionTBwSymptoms=1;		

		/*Date d'arrêt de I'INH*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163284,e.encounter_id,e.encounter_datetime,e.location_id,
formatDate(v.arretINHYy,v.arretINHMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.tbStatus  v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
FindNumericValue(v.arretINHYy)>0;			

		/* Migration for Aucun signe ou sympôtme indicatif de TB */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1659,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.noTBsymptoms=1 THEN 1660 ELSE NULL END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.tbStatus  v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.noTBsymptoms=1;		

select 4 as tbEvaluation;		
	/*END OF MIGRATION FOR ÉVALUATION TB aeyaitahlu*/
  
  /*MIGRATION FOR ANTÉCEDENTS MÉDICAUX ET DIAGNOSTICS ACTUELS*/
  
 /*Aucun diagnostic fait ou reporté aujourd'hui*/ 
  INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1284,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.noDiagnosis=1 THEN 133010
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd)
AND v.noDiagnosis=1;
  
	  /*Migration for Lymphadénopathie chronique persistante*/
	  INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
		SELECT DISTINCT e.patient_id,
		CASE WHEN v.conditionActive=1 THEN 6042
		     WHEN v.conditionActive=2 THEN 6097
             else null END,e.encounter_id,
			 ifnull(formatDate(v.conditionYy,v.conditionMm,'01'),e.encounter_datetime),1,
			 case when v.conditionID=435 then 5328
			      when v.conditionID=406 then 298
				  when v.conditionID=403 then 127794
				  when v.conditionID=402 then 512
				  when v.conditionID=407 then 111721
				  when v.conditionID=192 then 117543
				  when v.conditionID=297 then 902
				  when v.conditionID=196 then 5334
				  when v.conditionID=396 then 298
				  when v.conditionID=408 then 5333
				  when v.conditionID=202 then 5337
				  when v.conditionID=205 then 121255
				  when v.conditionID in (409,21,208) then 42
				  when v.conditionID=715 then 159355
				  when v.conditionID=410 then 5030
				  when v.conditionID=218 then 116023
				  when v.conditionID=411 then 5035
				  when v.conditionID=230 then 142963
				  when v.conditionID=233 then 120330
				  when v.conditionID=257 then 5033
				  when v.conditionID=412 then 1460
				  when v.conditionID=433 then 5334
				  when v.conditionID=428 then case when v.conditionActive=1 then 130864
				                                   when v.conditionActive=2 then 132827
												   end 
				  when v.conditionID=303 then case when v.conditionActive=1 then 1226
				                                   when v.conditionActive=2 then 121629
												   end 
				  when v.conditionID=306 then 129079
				  when v.conditionID=429 then 116030
				  when v.conditionID=430 then 119816
				  when v.conditionID=315 then case when v.conditionActive=1 then 142474
				                                   when v.conditionActive=2 then 142473
												   end
				  when v.conditionID=320 then 111759
				  when v.conditionID=323 then case when v.conditionActive=1 then 149743
				                                   when v.conditionActive=2 then 145347
												   end
				  when v.conditionID=20 then 111873
												   
				  when v.conditionID=326 then 117441
				  when v.conditionID=329 then 117339
				  when v.conditionID=332 then 135761
				  when v.conditionID=716 then 116128
				  when v.conditionID=335 then 160148
				  when v.conditionID=416 then 145443
				  when v.conditionID=434 then 5034
				  when v.conditionID=414 then 136458
				  when v.conditionID=415 then 139739
				  when v.conditionID=416 then 118510
				  when v.conditionID=417 then 110516
				  when v.conditionID=418 then 156804
				  when v.conditionID=419 then 135886
				  when v.conditionID=251 then 5040
				  when v.conditionID=287 then 990
				  when v.conditionID=242 then 5038
				  when v.conditionID=290 then 141488
				  when v.conditionID=420 then 507
				  when v.conditionID=421 then 5041
				  when v.conditionID=422 then 115195
				  when v.conditionID in (423,41,405) then case when v.conditionActive=1 then 118890
				                                           when v.conditionActive=2 then 5042
												      end
				  when v.conditionID=424 then case when v.conditionActive=1 then 5043
				                                   when v.conditionActive=2 then 5044
												   end		
				  when v.conditionID=425 then case when v.conditionActive=1 then 114100
				                                   when v.conditionActive=2 then 123742
												   end		
                  when v.conditionID=426 then 5340	
                  when v.conditionID=427 then 123098	
                  when v.conditionID=272 then 882
                  when v.conditionID=248 then 5046	
                  when v.conditionID=717 then 160155
				  when v.conditionID=344 then 118983
				  when v.conditionID=350 then 112493
				  when v.conditionID=353 then 117295
				  when v.conditionID=431 then 119537
				  when v.conditionID=383 then 113517
				  when v.conditionID=386 then 121131
				  when v.conditionID=368 then 159449
				  when v.conditionID=371 then 73650
			END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.conditions v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.conditionID in (435,406,403,402,407,192,297,196,396,408,202,205,409,715,410,218,411,230,233,257,412,433,428,303,306,429,430,315,320,323,326,329,332,716,335,416,434,414,415,416,417,418,419,251,287,242,290,420,421,422,423,424,425,426,427,272,248,717,344,350,353,431,383,386,368,371,21,41,405,208,20)
AND (v.conditionActive=1 OR v.conditionActive=2);

	/*END OF MIGRATION FOR ANTÉCEDENTS MÉDICAUX ET DIAGNOSTICS ACTUELS*/
select 12 as arvTraitement;
	
	/*MIGRATION FOR ARV : TRAITEMENTS PRÉCÉDENTS MENU*/
	/*Migration for Est-ce que le patient a déjà utilisé des ARV ?*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160533,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.arvEver=1 or v.pedArvEver=1 THEN 1
     WHEN v.arvEver=2 or v.pedArvEver=2 THEN 2
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.arvEnrollment v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
(v.arvEver in (1,2) or v.pedArvEver in (1,2));


/* for pediatric  medicament connu*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163715,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.pedArvKnown=1 THEN 1 
     WHEN v.pedArvKnown=2 THEN 2 END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.arvEnrollment v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
(pedArvKnown=1);


	/*(-) INTIs*/
	/*Migration for Abacavir (ABC)*/
	/*Concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='f604049d-9959-49cb-812a-7dcf453b2d73'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=1;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='f604049d-9959-49cb-812a-7dcf453b2d73' 
GROUP BY openmrs.obs.person_id,encounter_id;

 /* 16819 */
		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,70056,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=1;
		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,138405,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v ,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=1;		
		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v ,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=1 AND FindNumericValue(v.startYy)>0;			

		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 	,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=1 AND FindNumericValue(v.stopYy)>0;			

		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og  	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=1 and v.isContinued=1;
		/*Arrêt : raison*/
		/*Migration for Tox,Intol,Ech,Inconnu,Fin PTME*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,6098,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,		
		case when v.toxicity=1 then 102
		     when v.intolerance=1 then 987
			 when v.failure=1 then 843
			 when v.discUnknown=1 then 1067
			 when v.finPTME=1 then 1253
		end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v ,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=1 and (v.toxicity=1 or v.intolerance=1 or v.failure=1 or v.discUnknown=1 or v.finPTME=1);

select 12 as abacavir;

	/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
	/*Migration for Combivir (AZT+3TC)*/
		/*Concept group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='4898493b-c3ba-42e0-b893-7e9ac50a5de0'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=8;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='4898493b-c3ba-42e0-b893-7e9ac50a5de0' 
GROUP BY openmrs.obs.person_id,encounter_id;

set vobs_id=last_insert_id();
		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,630,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=8;
		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,138405,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=8;		
		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=8 AND FindNumericValue(v.startYy)>0;			

		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 	,itech.obs_concept_group og	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=8 AND FindNumericValue(v.stopYy)>0;			

		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v ,itech.obs_concept_group og	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=8 and v.isContinued=1;
		/*Arrêt : raison*/
		/*Migration for Tox,Intol,Ech,Inconnu,Fin PTME*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,6098,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,		
		case when v.toxicity=1 then 102
		     when v.intolerance=1 then 987
			 when v.failure=1 then 843
			 when v.discUnknown=1 then 1067
			 when v.finPTME=1 then 1253
		end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v ,itech.obs_concept_group og	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=8 and (v.toxicity=1 or v.intolerance=1 or v.failure=1 or v.discUnknown=1 or v.finPTME=1);		

select 12 as combivir;	
	/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
	/*Migration for Didanosine (ddI) */
	/*Concept group*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='95ac7b3a-0bda-49d3-8562-ee77bc8fd733'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=10;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='95ac7b3a-0bda-49d3-8562-ee77bc8fd733' 
GROUP BY openmrs.obs.person_id,encounter_id;

set vobs_id=last_insert_id();
		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,74807,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=10;
		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,138405,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=10;		
		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=10 AND FindNumericValue(v.startYy)>0;			

		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 		
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=10 AND FindNumericValue(v.stopYy)>0;			

		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and e.encounter_datetime = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=10 and v.isContinued=1;
		/*Arrêt : raison*/
		/*Migration for Tox,Intol,Ech,Inconnu,Fin PTME*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,6098,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,		
		case when v.toxicity=1 then 102
		     when v.intolerance=1 then 987
			 when v.failure=1 then 843
			 when v.discUnknown=1 then 1067
			 when v.finPTME=1 then 1253
		end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=10 and (v.toxicity=1 or v.intolerance=1 or v.failure=1 or v.discUnknown=1 or v.finPTME=1);
 
	/*======================================================================================================================*/
	/*Migration for Emtricitabine (FTC)*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='3e8dea76-369d-45bf-970e-2005496587a5'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=12;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='3e8dea76-369d-45bf-970e-2005496587a5' 
GROUP BY openmrs.obs.person_id,encounter_id;

set vobs_id=last_insert_id();
		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,75628,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=12;
		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,138405,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=12;		
		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=12 AND FindNumericValue(v.startYy)>0;			

		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 		
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=12 AND FindNumericValue(v.stopYy)>0;			

		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=12 and v.isContinued=1;
		/*Arrêt : raison*/
		/*Migration for Tox,Intol,Ech,Inconnu,Fin PTME*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,6098,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,		
		case when v.toxicity=1 then 102
		     when v.intolerance=1 then 987
			 when v.failure=1 then 843
			 when v.discUnknown=1 then 1067
			 when v.finPTME=1 then 1253
		end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=12 and (v.toxicity=1 or v.intolerance=1 or v.failure=1 or v.discUnknown=1 or v.finPTME=1);

select 12 as didanosine;
	/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/	
	/*Migration for Lamivudine (3TC)*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='eb704fe8-7cf0-4e36-b86b-a69bc8ed5a4a'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=20;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='eb704fe8-7cf0-4e36-b86b-a69bc8ed5a4a' 
GROUP BY openmrs.obs.person_id,encounter_id;

set vobs_id=last_insert_id();
		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,78643,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=20;
		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,138405,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=20;		
		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=20 AND FindNumericValue(v.startYy)>0;			

		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 		
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=20 AND FindNumericValue(v.stopYy)>0;			

		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v ,itech.obs_concept_group og	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=20 and v.isContinued=1;
		/*Arrêt : raison*/
		/*Migration for Tox,Intol,Ech,Inconnu,Fin PTME*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,6098,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,		
		case when v.toxicity=1 then 102
		     when v.intolerance=1 then 987
			 when v.failure=1 then 843
			 when v.discUnknown=1 then 1067
			 when v.finPTME=1 then 1253
		end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v ,itech.obs_concept_group og	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=20 and (v.toxicity=1 or v.intolerance=1 or v.failure=1 or v.discUnknown=1 or v.finPTME=1);	

select 12 as lamividune;
		/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
		/*Migration for Stavudine (d4T)*/
		/*Migration for the group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='544b0301-f89e-4ae6-b48f-9780b2ea4bed'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=29;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='544b0301-f89e-4ae6-b48f-9780b2ea4bed' 
GROUP BY openmrs.obs.person_id,encounter_id;
		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,84309,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=29;
		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,138405,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=29;		
		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=29 AND FindNumericValue(v.startYy)>0;			

		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 		
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=29 AND FindNumericValue(v.stopYy)>0;			

		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=29 and v.isContinued=1;
		/*Arrêt : raison*/
		/*Migration for Tox,Intol,Ech,Inconnu,Fin PTME*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,6098,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,		
		case when v.toxicity=1 then 102
		     when v.intolerance=1 then 987
			 when v.failure=1 then 843
			 when v.discUnknown=1 then 1067
			 when v.finPTME=1 then 1253
		end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=29 and (v.toxicity=1 or v.intolerance=1 or v.failure=1 or v.discUnknown=1 or v.finPTME=1);			
		
select 12 as stavidune;
		
		/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
		/*Migration for Tenofovir (TNF)*/
		/*Migration for the group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='7ae7e7f7-db75-4533-bce3-caf77a75355e'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=31;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='7ae7e7f7-db75-4533-bce3-caf77a75355e' 
GROUP BY openmrs.obs.person_id,encounter_id;

		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,84795,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=31;
		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,138405,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=31;		
		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=31 AND FindNumericValue(v.startYy)>0;			

		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 		
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=31 AND FindNumericValue(v.stopYy)>0;			

		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=31 and v.isContinued=1;
		/*Arrêt : raison*/
		/*Migration for Tox,Intol,Ech,Inconnu,Fin PTME*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,6098,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,		
		case when v.toxicity=1 then 102
		     when v.intolerance=1 then 987
			 when v.failure=1 then 843
			 when v.discUnknown=1 then 1067
			 when v.finPTME=1 then 1253
		end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=31 and (v.toxicity=1 or v.intolerance=1 or v.failure=1 or v.discUnknown=1 or v.finPTME=1);	

select 12 as tenofovir;
		/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
		/*Migration for Trizivir (ABC+AZT+3TC)*/
		/*Migration for the group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='60299c6d-de85-45d9-adbd-9d67906c658d'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=33;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='60299c6d-de85-45d9-adbd-9d67906c658d' 
GROUP BY openmrs.obs.person_id,encounter_id;

		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,817,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=33;
		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,vobs_id,138405,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=33;		
		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'01')D,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=33 AND FindNumericValue(v.startYy)>0;			

		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 		
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=33 AND FindNumericValue(v.stopYy)>0;			

		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=33 and v.isContinued=1;
		/*Arrêt : raison*/
		/*Migration for Tox,Intol,Ech,Inconnu,Fin PTME*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,6098,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,		
		case when v.toxicity=1 then 102
		     when v.intolerance=1 then 987
			 when v.failure=1 then 843
			 when v.discUnknown=1 then 1067
			 when v.finPTME=1 then 1253
		end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=33 and (v.toxicity=1 or v.intolerance=1 or v.failure=1 or v.discUnknown=1 or v.finPTME=1);		

		/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
		/*Migration for Zidovudine (AZT)*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='32bc1f59-e316-4c4f-84eb-dc0906f8e2fa'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=34;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='32bc1f59-e316-4c4f-84eb-dc0906f8e2fa' 
GROUP BY openmrs.obs.person_id,encounter_id;

set vobs_id=last_insert_id();
		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,86663,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=34;
		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,138405,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=34;		
		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=34 AND FindNumericValue(v.startYy)>0;			

		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 		
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=34 AND FindNumericValue(v.stopYy)>0;			

		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=34 and v.isContinued=1;
		/*Arrêt : raison*/
		/*Migration for Tox,Intol,Ech,Inconnu,Fin PTME*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,6098,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,		
		case when v.toxicity=1 then 102
		     when v.intolerance=1 then 987
			 when v.failure=1 then 843
			 when v.discUnknown=1 then 1067
			 when v.finPTME=1 then 1253
		end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=34 and (v.toxicity=1 or v.intolerance=1 or v.failure=1 or v.discUnknown=1 or v.finPTME=1);	

		/*Migration for Efavirenz (EFV)*/
		/*Migration for the group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='5b14f87d-3b64-418c-bfcf-90a8d0ae0e02'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=11;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='5b14f87d-3b64-418c-bfcf-90a8d0ae0e02' 
GROUP BY openmrs.obs.person_id,encounter_id;

set vobs_id=last_insert_id();
		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,75523,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=11;
		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,138405,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=11;		
		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=11 AND FindNumericValue(v.startYy)>0;			

		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 		
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=11 AND FindNumericValue(v.stopYy)>0;			

		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=11 and v.isContinued=1;
		/*Arrêt : raison*/
		/*Migration for Tox,Intol,Ech,Inconnu,Fin PTME*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,6098,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,		
		case when v.toxicity=1 then 102
		     when v.intolerance=1 then 987
			 when v.failure=1 then 843
			 when v.discUnknown=1 then 1067
			 when v.finPTME=1 then 1253
		end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=11 and (v.toxicity=1 or v.intolerance=1 or v.failure=1 or v.discUnknown=1 or v.finPTME=1);	


		/*=========================================================================================================================*/
		/*Migration for Nevirapine (NVP)*/
			/*Migration for the group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='dbd8e7e9-6b7a-4b70-8c8f-a80f8e64b710'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=23;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='dbd8e7e9-6b7a-4b70-8c8f-a80f8e64b710' 
GROUP BY openmrs.obs.person_id,encounter_id;

set vobs_id=last_insert_id();
		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,80586,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=23;
		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,138405,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=23;		
		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=23 AND FindNumericValue(v.startYy)>0;			

		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 		
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=23 AND FindNumericValue(v.stopYy)>0;			

		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=23 and v.isContinued=1;
		/*Arrêt : raison*/
		/*Migration for Tox,Intol,Ech,Inconnu,Fin PTME*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,6098,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,		
		case when v.toxicity=1 then 102
		     when v.intolerance=1 then 987
			 when v.failure=1 then 843
			 when v.discUnknown=1 then 1067
			 when v.finPTME=1 then 1253
		end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=23 and (v.toxicity=1 or v.intolerance=1 or v.failure=1 or v.discUnknown=1 or v.finPTME=1);	

		/*Migration for Atazanavir (ATZN)*/
		/*Migration for the group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='d1c8a581-4512-4874-8960-cb3306f06f11'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=5;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='d1c8a581-4512-4874-8960-cb3306f06f11' 
GROUP BY openmrs.obs.person_id,encounter_id;

set vobs_id=last_insert_id();
		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,71647,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=5;
		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,138405,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=5;		
		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=5 AND FindNumericValue(v.startYy)>0;			

		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 		
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=5 AND FindNumericValue(v.stopYy)>0;			

		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=5 and v.isContinued=1;
		/*Arrêt : raison*/
		/*Migration for Tox,Intol,Ech,Inconnu,Fin PTME*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,6098,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,		
		case when v.toxicity=1 then 102
		     when v.intolerance=1 then 987
			 when v.failure=1 then 843
			 when v.discUnknown=1 then 1067
			 when v.finPTME=1 then 1253
		end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=5 and (v.toxicity=1 or v.intolerance=1 or v.failure=1 or v.discUnknown=1 or v.finPTME=1);	

		/*+++++++++++++++++++++++++++++++++++++++++++++++*/
		/*Migration for Atazanavir+BostRTV*/
		/*Migration for the group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='71cfae87-3d31-40d8-8a06-aeed72c799d0'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=6;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='71cfae87-3d31-40d8-8a06-aeed72c799d0' 
GROUP BY openmrs.obs.person_id,encounter_id;

set vobs_id=last_insert_id();
		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,159809,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=6;
		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,138405,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=6;		
		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=6 AND FindNumericValue(v.startYy)>0;			

		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 		
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=6 AND FindNumericValue(v.stopYy)>0;			

		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=6 and v.isContinued=1;
		/*Arrêt : raison*/
		/*Migration for Tox,Intol,Ech,Inconnu,Fin PTME*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,6098,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,		
		case when v.toxicity=1 then 102
		     when v.intolerance=1 then 987
			 when v.failure=1 then 843
			 when v.discUnknown=1 then 1067
			 when v.finPTME=1 then 1253
		end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=6 and (v.toxicity=1 or v.intolerance=1 or v.failure=1 or v.discUnknown=1 or v.finPTME=1);	

		/*--------------------------------------------------------------------------------------------------------*/
		/*Migration for Indinavir (IDV)*/
		/*Migration for the group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='7f5144db-0182-4775-a0e5-78f71aa9d6e1'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=16;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='7f5144db-0182-4775-a0e5-78f71aa9d6e1' 
GROUP BY openmrs.obs.person_id,encounter_id;

set vobs_id=last_insert_id();
		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,77995,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=16;
		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,138405,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=16;		
		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=16 AND FindNumericValue(v.startYy)>0;			

		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 		
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=16 AND FindNumericValue(v.stopYy)>0;			

		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=16 and v.isContinued=1;
		/*Arrêt : raison*/
		/*Migration for Tox,Intol,Ech,Inconnu,Fin PTME*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,6098,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,		
		case when v.toxicity=1 then 102
		     when v.intolerance=1 then 987
			 when v.failure=1 then 843
			 when v.discUnknown=1 then 1067
			 when v.finPTME=1 then 1253
		end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=16 and (v.toxicity=1 or v.intolerance=1 or v.failure=1 or v.discUnknown=1 or v.finPTME=1);	

		/*---------------------------------------------------------------------------------------------------------------------------*/
		/*Migration for Lopinavir+BostRTV (Kaletra)*/
		/*Migration for the group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='e017cfcf-a763-4e85-845a-e0aa6573c829'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=21;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='e017cfcf-a763-4e85-845a-e0aa6573c829' 
GROUP BY openmrs.obs.person_id,encounter_id;

set vobs_id=last_insert_id();
		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,794,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=21;
		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,138405,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=21;		
		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=21 AND FindNumericValue(v.startYy)>0;			

		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 		
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=21 AND FindNumericValue(v.stopYy)>0;			

		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=21 and v.isContinued=1;
		/*Arrêt : raison*/
		/*Migration for Tox,Intol,Ech,Inconnu,Fin PTME*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,6098,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,		
		case when v.toxicity=1 then 102
		     when v.intolerance=1 then 987
			 when v.failure=1 then 843
			 when v.discUnknown=1 then 1067
			 when v.finPTME=1 then 1253
		end ,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=21 and (v.toxicity=1 or v.intolerance=1 or v.failure=1 or v.discUnknown=1 or v.finPTME=1);
		
		/*Autre a Verifier +++++++++++++++++++++++==========================++++++++++++++++++++++++++++++++++==*/
	/*END OF MIGRATION FOR ARV : TRAITEMENTS PRÉCÉDENTS MENU*/
	/*MIGRATION FOR REMARQUES MENU*/
	
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,161011,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.drugComments<>'' THEN v.drugComments
	 ELSE NULL
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugComments<>'';

	/*END OF MIGRATION FOR REMARQUES MENU*/
	
	

	/*MIGRATION FOR ARV ET GROSSESSE (SEXE F) MENU*/
	/*Migration for Est-ce que la patiente a pris un médicament ARV exclusivement afin de prévenir la transmission mère-enfant ?*/	
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,966,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.ARVexcl=1 THEN 1107 END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.arvAndPregnancy v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.ARVexcl=1;
/*Migration for Zidovudine,Nevirapine (NVP),Inconnu,Autre :*/	
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,comments,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,966,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.zidovudineARVpreg=1 THEN 86663
	 WHEN v.nevirapineARVpreg=1 THEN 80586
	 WHEN v.unknownARVpreg=1 THEN 1067
	 WHEN v.otherARVpreg=1 THEN 5424
END,
CASE WHEN v.otherARVpreg=1 AND v.otherTextARVpreg<>'' THEN v.otherTextARVpreg ELSE NULL END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.arvAndPregnancy v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
(v.zidovudineARVpreg=1 OR v.nevirapineARVpreg=1 OR v.unknownARVpreg=1 OR v.otherARVpreg=1);
	/*END OF ARV ET GROSSESSE (SEXE F) MENU*/	

select 6 as grossesse;
	
/*MIGRATION FOR AUTRES TRAITEMENTS PRÉCÉDENTS MENU */
		/*Migration for Ethambutol*/
		/*Migration for the group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='439f0405-b70b-49a9-8c32-66b39b3186bd'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=13;	

select 100 as test;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='439f0405-b70b-49a9-8c32-66b39b3186bd' 
GROUP BY openmrs.obs.person_id,encounter_id;	

set vobs_id=last_insert_id();
		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,75948,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=13;

select 101 as test;
		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,5622,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and e.encounter_datetime = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=13;		

select 102 as test;		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=13 AND FindNumericValue(v.startYy)>0;			
select 104 as test;
		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v ,itech.obs_concept_group og		
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=13 AND FindNumericValue(v.stopYy)>0;			
select 105 as test;
		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=13 and v.isContinued=1;

select 106 as test;		
		/*Migration for Isoniazide (INH)*/
		/*Migration for the group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='fee8bd39-2a95-47f9-b1f5-3f9e9b3ee959'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=18;		

select 107 as test;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='fee8bd39-2a95-47f9-b1f5-3f9e9b3ee959' 
GROUP BY openmrs.obs.person_id,encounter_id;

set vobs_id=last_insert_id();
		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,78280,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=18;

select 108 as test;
		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,5622,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=18;
		
select 109 as test;		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=18 AND FindNumericValue(v.startYy)>0;			

select 110 as test;
		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 		
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=18 AND FindNumericValue(v.stopYy)>0;			

select 111 as test;
		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=18 and v.isContinued=1;	
	
select 112 as test;
		/*Migration for Pyrazinamide*/
		/*Migration for the group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ee73ed0f-8fd5-4a3e-be10-c12cef9672e8'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=24;		

select 113 as test;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='ee73ed0f-8fd5-4a3e-be10-c12cef9672e8' 
GROUP BY openmrs.obs.person_id,encounter_id;

set vobs_id=last_insert_id();
		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,82900,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and e.encounter_datetime = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=24;

select 114 as test;

		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,5622,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=24;		

select 115 as test;
		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'XX'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=24 AND FindNumericValue(v.startYy)>0;			

select 116 as test;

		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 		
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=24 AND FindNumericValue(v.stopYy)>0;			

select 118 as test;

		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=24 and v.isContinued=1;

select 119 as test;
		/*Migration for Rifampicine*/
		/*Migration for Streptomycine*/
		/*Migration for Acyclovir*/
		/*Migration for the group*/
		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='137fc1c1-84b9-4cbc-97a3-124835f29866'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=2;		

select 120 as test;

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='137fc1c1-84b9-4cbc-97a3-124835f29866' 
GROUP BY openmrs.obs.person_id,encounter_id;

		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,70245,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=2;

select 121 as test;

		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,5622,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=2;		

select 122 as test;
		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'XX'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=2 AND FindNumericValue(v.startYy)>0;			

select 1221 as test;

		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 		
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=2 AND FindNumericValue(v.stopYy)>0;			

select 123 as test;

		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=2 and v.isContinued=1;		

select 124 as test;

		/*Migration for Cotrimoxazole (TMS)*/
		/*Migration for the group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ace97bb2-35d8-4195-ad08-edfee78f1ec2'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=9;	

select 125 as test;	

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='ace97bb2-35d8-4195-ad08-edfee78f1ec2' 
GROUP BY openmrs.obs.person_id,encounter_id;

set vobs_id=last_insert_id();
		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,105281,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=9;

select 126 as test;
		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,5622,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=9;		

select 127 as test;
		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=9 AND FindNumericValue(v.startYy)>0;			

select 128 as test;

		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 		
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=9 AND FindNumericValue(v.stopYy)>0;			

select 129 as test;

		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=9 and v.isContinued=1;			

select 130 as test;
		/*Migration for Fluconazole*/
		/*Migration for the group*/
		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='1c4f7da3-2d64-4c58-aad5-16d7eafa53a0'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=14;		

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='1c4f7da3-2d64-4c58-aad5-16d7eafa53a0' 
GROUP BY openmrs.obs.person_id,encounter_id;

set vobs_id=last_insert_id();

select 131 as test;		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,76488,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=14;

select 132 as test;

		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,5622,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=14;		

select 133 as test;
		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'XX'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=14 AND FindNumericValue(v.startYy)>0;			

select 134 as test;

		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 		
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=14 AND FindNumericValue(v.stopYy)>0;			

select 136 as test;

		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=14 and v.isContinued=1;			

select 137 as test;
		
		/*Migration for Ketaconazole*/
			/*Migration for the group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='1152e548-2161-43ab-94fa-76bf3d327b3a'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=19;

select 138 as test;		

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='1152e548-2161-43ab-94fa-76bf3d327b3a' 
GROUP BY openmrs.obs.person_id,encounter_id;

set vobs_id=last_insert_id();
		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,78476,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=19;

select 140 as test;

		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,5622,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=19;		

select 141 as test;
		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=19 AND FindNumericValue(v.startYy)>0;			


select 142 as test;

		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 		
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=19 AND FindNumericValue(v.stopYy)>0;			

select 143 as test;

		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=19 and v.isContinued=1;			
			
select 144 as test;

		/*Migration for Traitement traditionnelle*/
		/*Migration for the group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='0e545872-74fe-4a54-8e9f-6ee86262f28f'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=35;		

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='0e545872-74fe-4a54-8e9f-6ee86262f28f' 
GROUP BY openmrs.obs.person_id,encounter_id;

set vobs_id=last_insert_id();
		
		/*migration for the concept*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1282,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,5841,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=35;

select 146 as test;

		/*==================================================*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160742,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,5622,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=35;		

select 147 as test;
		
		/*Migration for Début MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.startYy,v.startMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=35 AND FindNumericValue(v.startYy)>0;			

select 148 as test;

		/*Migration for Arrêt MM/AA*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.stopYy),FindNumericValue(v.stopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 		
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=35 AND FindNumericValue(v.stopYy)>0;			

select 149 as test;

		/*Migration for Utilisation courante*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159367,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,1065,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.drugs v,itech.obs_concept_group og 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.drugID=35 and v.isContinued=1;

select 150 as test;

/*Migration for Commentaire*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,163323,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.treatmentComments<>'' THEN v.treatmentComments ELSE NULL END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.treatmentComments<>'';

select 150 as test;

		/*Migration for Autres, préciser :*/
		/*Migration for the group*/
/* other drugs can be multiple in the table */
	/*END OF AUTRES TRAITEMENTS PRÉCÉDENTS MENU*/	
	
	
/*MIGRATION FOR ÉLIGIBILITÉ MÉDICALE AUX ARV MENU*/
		/*Stade OMS actuel*/
		/*Migration for Stade I (Asymptomatique) AND Stade II (Symptomatique) AND Stade III (Symptomatique) AND Stade IV (SIDA)*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5356,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.currentHivStage=1 THEN 1204
	 WHEN v.currentHivStage=2 THEN 1205
	 WHEN v.currentHivStage=4 THEN 1206
	 WHEN v.currentHivStage=8 THEN 1207
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.medicalEligARVs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
(v.currentHivStage=1 OR v.currentHivStage=2 OR v.currentHivStage=4 OR v.currentHivStage=8);

select 151 as test;

		/*Migration for Éligibilité médicale aux ARV*/
		/*Migration for Oui - préciser la raison AND Non - pas d'éligibilité médicale aujourd'hui AND À déterminer*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162703,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.medElig=1 THEN 1065
	 WHEN v.medElig=4 THEN 1066
	 WHEN v.medElig=8 THEN 1067
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.medicalEligARVs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
(v.medElig=1 OR v.medElig=4 OR v.medElig=8);

select 152 as test;
		/*Raison d'éligibilité médicale aux ARV*/
		/*Migration for CD4 inférieur au seuil (500) */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162225,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.cd4LT200=1 THEN 5497 
     WHEN v.WHOIII=1 THEN 163326
	 WHEN v.WHOIV=1 THEN 1207
	 WHEN v.PMTCT=1 THEN 160538
	 WHEN v.medEligHAART=1 THEN 163327
	 WHEN v.formerARVtherapy=1 THEN 1087
	 WHEN v.PEP=1 THEN 1691
	 WHEN v.coinfectionTbHiv=1 THEN 163324
	 WHEN v.coinfectionHbvHiv=1 THEN 163325
	 WHEN v.coupleSerodiscordant=1 THEN 6096
	 WHEN v.pregnantWomen=1 THEN 1434
	 WHEN v.breastfeedingWomen=1 THEN 5632
	 WHEN v.patientGt50ans=1 THEN 163328
	 WHEN v.nephropathieVih=1 THEN 153701
	 WHEN v.protocoleTestTraitement=1 THEN 163329
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.medicalEligARVs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.medElig=1	AND (v.cd4LT200=1 or v.WHOIII=1 or v.WHOIV=1 or v.PMTCT=1 or v.medEligHAART=1 or v.formerARVtherapy=1 or 
                 v.PEP=1 or v.coinfectionTbHiv=1 or v.coinfectionHbvHiv=1 or v.coupleSerodiscordant=1 or v.pregnantWomen=1 or 
                 v.breastfeedingWomen=1 or v.patientGt50ans=1 or v.nephropathieVih=1 or v.protocoleTestTraitement=1);	

select 153 as test;

INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162225,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.WHOIII=1 THEN 163326 else null END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.medicalEligARVs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.medElig=1	AND (v.WHOIII=1);

select 154 as test;					 
				 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162225,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.WHOIV=1 THEN 1207 else null END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.medicalEligARVs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.medElig=1	AND (v.WHOIV=1);	

select 155 as test;

INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162225,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.PMTCT=1 THEN 160538 else null END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.medicalEligARVs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.medElig=1	AND (v.PMTCT=1);

select 156 as test;

INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162225,e.encounter_id,e.encounter_datetime,e.location_id,
CASE  WHEN v.medEligHAART=1 THEN 163327 else null END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.medicalEligARVs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.medElig=1	AND (v.medEligHAART=1);	

select 157 as test;

INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162225,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.formerARVtherapy=1 THEN 1087 else null END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.medicalEligARVs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.medElig=1	AND (v.formerARVtherapy=1);	

select 158 as test;

INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162225,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.PEP=1 THEN 1691 else null END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.medicalEligARVs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.medElig=1	AND (v.PEP=1);		

select 159 as test;

INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162225,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.coinfectionTbHiv=1 THEN 163324 else null END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.medicalEligARVs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.medElig=1	AND (v.coinfectionTbHiv=1);	


select 160 as test;


INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162225,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.coinfectionHbvHiv=1 THEN 163325 else null END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.medicalEligARVs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.medElig=1	AND (v.coinfectionHbvHiv=1);

select 161 as test;


INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162225,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.coupleSerodiscordant=1 THEN 6096 else null END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.medicalEligARVs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.medElig=1	AND (v.coupleSerodiscordant=1);	

select 162 as test;


INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162225,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.pregnantWomen=1 THEN 1434 else null END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.medicalEligARVs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.medElig=1	AND (v.pregnantWomen=1);

select 163 as test;

INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162225,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.breastfeedingWomen=1 THEN 5632 else null END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.medicalEligARVs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.medElig=1	AND (v.breastfeedingWomen=1);

select 164 as test;

INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162225,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.patientGt50ans=1 THEN 163328 else null END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.medicalEligARVs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.medElig=1	AND (v.patientGt50ans=1);	

select 165 as test;

INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162225,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.nephropathieVih=1 THEN 153701 else null END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.medicalEligARVs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.medElig=1	AND (v.nephropathieVih=1);

select 166 as test;

INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162225,e.encounter_id,e.encounter_datetime,e.location_id,
CASE WHEN v.protocoleTestTraitement=1 THEN 163329 END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.medicalEligARVs v 	
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')  = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.medElig=1	AND (v.protocoleTestTraitement=1);					
	/*END OF ÉLIGIBILITÉ MÉDICALE AUX ARV MENU*/

	/*END OF MIGRATION FOR Date de prochaine visite*/

	
 select 167 as test; 
  
  
  
  /* migration for suivi visit*/
  
/*MIGRATION FOR ÉTAT GENERAL MENU*/
/* MIGRATION OF Inchangé,uelque peu amélioré,Aggravé,Nette amélioration*/			
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,
case when v.genStat=1 then 162676
	 when v.genStat=4 then 1898
	 when v.genStat=8 then 162676
	 when v.genStat=16 then 162676
else null
END,e.encounter_id,e.encounter_datetime,e.location_id,
case when v.genStat=1 then 162679
	 when v.genStat=4 then 1065
	 when v.genStat=8 then 162678
	 when v.genStat=16 then 162677
else null
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.genStat in (1,4,8,16);



select 168 as test;	
/*Hospitalisé depuis la dernière visite*/	
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,976,e.encounter_id,e.encounter_datetime,e.location_id,
case when v.hospitalized=1 then 1
	 when v.hospitalized=2 then 2
else null
END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.hospitalized in (1,2);

select 169 as test;

/* Si oui, expliquer */			
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,162879,e.encounter_id,e.encounter_datetime,e.location_id,
case when v.hospitalizedText<>'' then v.hospitalizedText else null END,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.hospitalizedText<>'';

select 170 as test;
/* END of MIGRATION FOR ÉTAT GENERAL MENU*/		
  
  
/* Migration of alergies */

/* Aucune */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160643,e.encounter_id,e.encounter_datetime,e.location_id,1107,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.noneTreatments=1;

select 171 as test;

/* oui, non,Aucune for pediatrique */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160643,e.encounter_id,e.encounter_datetime,e.location_id,
case when v.pedMedAllerg=1 then 1065
     when v.pedMedAllerg=2 then 1066
	 when v.pedMedAllerg=4 then 1107
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedMedAllerg in (1,2,4);

select 172 as test;

/* Aliment for pediatrique */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,comments,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160643,e.encounter_id,e.encounter_datetime,e.location_id,
case when v.pedFoodAllerg=1 then 139994
end,v.pedFoodAllergText,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedFoodAllerg=1;

select 173 as test;
/* Autres for pediatrique */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,comments,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160643,e.encounter_id,e.encounter_datetime,e.location_id,
case when v.pedOtherAllerg=1 then 5622
end,v.aMedOther,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedOtherAllerg=1;

select 174 as test;

/* Médicaments, préciser:*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160643,e.encounter_id,e.encounter_datetime,e.location_id,
case when v.pedMedAllergMeds=1 then 141760
end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.vitals v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d')= concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.pedMedAllergMeds=1;

select 175 as test;

/* Alergie I group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='c5e4b458-41cf-4d17-aa7a-6dfc00482198'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=1;

select 176 as test;

delete from itech.obs_concept_group where 1;
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='c5e4b458-41cf-4d17-aa7a-6dfc00482198'
GROUP BY openmrs.obs.person_id,encounter_id;
		
/* Name of the Alergie I */		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160632,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,v.allergyName,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=1;

select 177 as test;

/* Start date of the Alergie I */		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.allergyStartYy,v.allergyStartMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=1 and FindNumericValue(v.allergyStartYy)>1 and FindNumericValue(v.allergyStartMM)>0;	

select 177 as test;

/* Stop date of the Alergie I */		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(FindNumericValue(v.allergyStopYy),FindNumericValue(v.allergyStopMm),'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=1 and FindNumericValue(v.allergyStopYy)>1 and FindNumericValue(v.allergyStopMM)>0; 
 
 select 179 as test;
/*erup of the Alergie I */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160646,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.rash=1 then 512 end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v  ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=1 and v.rash=1;

 select 180 as test;
/*erupF of the Alergie I */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160646,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.rashF=1 then 156083 end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v  ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=1 and v.rashF=1;

select 181 as test;

/*ABC of the Alergie I */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160646,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.ABC=1 then 137781 end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=1 and v.ABC=1;

select 182 as test;
/*pap of the Alergie I */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160646,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.hives=1 then 130908 end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=1 and v.hives=1;

select 184 as test;
/*sj of the Alergie I */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160646,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.SJ=1 then 125886 end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=1 and v.SJ=1;

select 185 as test;
/*anaph of the Alergie I */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160646,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.anaph=1 then 148888 end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=1 and v.anaph=1;

select 186 as test;
/*other of the Alergie I */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160646,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.allergyOther=1 then 5622 end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og  
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=1 and v.allergyOther=1;

select 187 as test;
/* *******************  end of alergie I */
/* Alergi II group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='09f30ecb-b6e8-4e44-9adc-e27bdf07b081') as concept_id,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=2;

select 188 as test;
delete from itech.obs_concept_group where 1;
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='09f30ecb-b6e8-4e44-9adc-e27bdf07b081'
GROUP BY openmrs.obs.person_id,encounter_id;
		
/* Name of the Alergie I */		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160632,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,v.allergyName,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v  ,itech.obs_concept_group og 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=2;

select 189 as test;

/* Start date of the Alergie I */		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.allergyStartYy,v.allergyStartMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=2 and FindNumericValue(v.allergyStartYy)>1 and FindNumericValue(v.allergyStartMM)>0;	

select 190 as test;

/* Stop date of the Alergie I */		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.allergyStopYy,v.allergyStopMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=2 and FindNumericValue(v.allergyStopYy)>1 and FindNumericValue(v.allergyStopMM)>0; 
 
 select 191 as test;
/*erup of the Alergie I */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160646,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.rash=1 then 512 end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=2 and v.rash=1;

select 192 as test;
/*erupF of the Alergie I */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160646,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.rashF=1 then 156083 end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=2 and v.rashF=1;

select 193 as test;
/*ABC of the Alergie I */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160646,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.ABC=1 then 137781 end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=2 and v.ABC=1;

select 194 as test;
/*pap of the Alergie I */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160646,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.hives=1 then 130908 end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=2 and v.hives=1;

select 195 as test;
/*sj of the Alergie I */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160646,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.SJ=1 then 125886 end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=2 and v.SJ=1;

select 196 as test;
/*anaph of the Alergie I */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160646,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.anaph=1 then 148888 end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=2 and v.anaph=1;

select 197 as test;
/*other of the Alergie I */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160646,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.allergyOther=1 then 5622 end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=2 and v.allergyOther=1;

/* *******************  end of alergie II */
select 198 as test;

/* Alergi III group*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='6639a971-43ca-4baf-89b6-194ab3597ebd'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v 
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=3;


delete from itech.obs_concept_group where 1;
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='6639a971-43ca-4baf-89b6-194ab3597ebd'
GROUP BY openmrs.obs.person_id,encounter_id;
		
/* Name of the Alergie I */		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_text,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160632,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,v.allergyName,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=3;

select 199 as test;
/* Start date of the Alergie I */		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1190,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.allergyStartYy,v.allergyStartMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=3 and FindNumericValue(v.allergyStartYy)>1 and FindNumericValue(v.allergyStartMM)>0;	

select 200 as test;
/* Stop date of the Alergie I */		
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1191,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
formatDate(v.allergyStopYy,v.allergyStopMm,'01'),1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=3 and v.allergyStopYy>1 and v.allergyStopMM>0; 

select 201 as test; 
/*erup of the Alergie I */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160646,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.rash=1 then 512 end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=3 and v.rash=1;

select 202 as test;
/*erupF of the Alergie I */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160646,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.rashF=1 then 156083 end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=3 and v.rashF=1;

select 203 as test;
/*ABC of the Alergie I */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160646,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.ABC=1 then 137781 end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=3 and v.ABC=1;

select 204 as test;
/*pap of the Alergie I */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160646,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.hives=1 then 130908 end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=3 and v.hives=1;

select 205 as test;
/*sj of the Alergie I */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160646,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.SJ=1 then 125886 end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=3 and v.SJ=1;

select 206 as test;
/*anaph of the Alergie I */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160646,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.anaph=1 then 148888 end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and 
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=3 and v.anaph=1;

select 207 as test;
/*other of the Alergie I */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,160646,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when v.allergyOther=1 then 5622 end,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.allergies v  ,itech.obs_concept_group og
WHERE e.uuid = c.encGuid and c.patientID = v.patientID and c.seqNum = v.seqNum and 
og.person_id=e.patient_id and e.encounter_id=og.encounter_id and
c.sitecode = v.sitecode and date_format(date(e.encounter_datetime),'%y-%m-%d') = concat(v.visitDateYy,'-',v.visitDateMm,'-',v.visitDateDd) AND 
v.allergySlot=3 and v.allergyOther=1;

/* *******************  end of alergie III */
 select 208 as test; 
END;
