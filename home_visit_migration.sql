DELIMITER $$ 
DROP PROCEDURE IF EXISTS homeVisitMigration$$
CREATE PROCEDURE homeVisitMigration()
BEGIN
	 /*Delete all inserted discontinuations data if the script fail*/
 DECLARE done INT DEFAULT FALSE;	 
DECLARE oCreateDate,OEncounter_datetime datetime;
DECLARE oPatientID,oConcept_id,oEncounter_id,oLocation_id,oContactDuringVisit,oCreator,oIllnessDescription,oServiceDelivery INT;
DECLARE oIllnessDescriptionOther,oServiceDeliveryOther varchar(100);
	 
DECLARE observation CURSOR  for 
SELECT DISTINCT c.patient_id,160288 as concept_id,c.encounter_id,c.encounter_datetime,c.location_id,ac.contactDuringVisit,1,e.createDate
		from encounter c, itech.encounter e, itech.homeCareVisits ac
		WHERE c.uuid = e.encGuid 
		AND e.siteCode = ac.siteCode
		AND e.patientID = ac.patientID
		AND concat(e.visitDateYy,"-",e.visitDateMm,"-",e.visitDateDd)=concat(ac.visitDateYy,"-",ac.visitDateMm,"-",ac.visitDateDd)
		AND ac.contactDuringVisit>0;	 

DECLARE maladie CURSOR  for 
SELECT DISTINCT c.patient_id,c.encounter_id,c.encounter_datetime,c.location_id,ac.illnessDescription,illnessDescriptionOther,1,e.createDate
from encounter c, itech.encounter e, itech.homeCareVisits ac
WHERE c.uuid = e.encGuid 
AND e.siteCode = ac.siteCode
AND e.patientID = ac.patientID
AND concat(e.visitDateYy,"-",e.visitDateMm,"-",e.visitDateDd) =concat(ac.visitDateYy,"-",ac.visitDateMm,"-",ac.visitDateDd)
AND ac.illnessDescription>0;		
		

DECLARE serviceDelivery CURSOR  for 
SELECT DISTINCT c.patient_id,c.encounter_id,c.encounter_datetime,c.location_id,ac.serviceDelivery,serviceDeliveryOther,1,e.createDate
from encounter c, itech.encounter e, itech.homeCareVisits ac
WHERE c.uuid = e.encGuid 
AND e.siteCode = ac.siteCode
AND e.patientID = ac.patientID
AND concat(e.visitDateYy,"-",e.visitDateMm,"-",e.visitDateDd) =concat(ac.visitDateYy,"-",ac.visitDateMm,"-",ac.visitDateDd)
AND ac.serviceDelivery>0;	

		
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE; 

SET SQL_SAFE_UPDATES = 0;
SET FOREIGN_KEY_CHECKS=0;
	 
	 DELETE FROM obs WHERE encounter_id IN
	 (
		SELECT en.encounter_id FROM encounter en, encounter_type ent
		WHERE en.encounter_type=ent.encounter_type_id
		AND ent.uuid='1dd1e63a-1543-4885-b807-e49c6d18cffd'
	 );
	  SET SQL_SAFE_UPDATES = 1;
	  SET FOREIGN_KEY_CHECKS=1;
	/*BUT DE LA VISITE */ 
        /*Start migration but de la visite*/	
	    INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,comments,creator,date_created,uuid)
		SELECT DISTINCT c.patient_id,160288,c.encounter_id,c.encounter_datetime,c.location_id,
		case when ac.reasonVisit=1 then (select concept_id from concept where uuid='e2739712-ed4b-4a8d-b8e7-f6ef8cf780e5')
		     when ac.reasonVisit=2 then 164370
			 when ac.reasonVisit=4 then (select concept_id from concept where uuid='ef958f97-f811-49af-a0e1-c22546eca30d')
			 when ac.reasonVisit=8 then 162192
			 when ac.reasonVisit=16 then 5622
		end as value_coded,reasonVisitOther,1,e.createDate, UUID()
		from encounter c, itech.encounter e, itech.homeCareVisits ac
		WHERE c.uuid = e.encGuid 
		AND e.siteCode = ac.siteCode
		AND e.patientID = ac.patientID
		AND concat(e.visitDateYy,"-",e.visitDateMm,"-",e.visitDateDd)=concat(ac.visitDateYy,"-",ac.visitDateMm,"-",ac.visitDateDd)
		AND ac.reasonVisit in (1,2,4,8,16);
		
		select 1 as homeVisit;
		/*SUIVI DES SOINS*/
		/* Observation faite lors de la visite à domicile */		
OPEN observation;

  observation_loop: LOOP
  FETCH observation INTO oPatientID,oConcept_id,oEncounter_id,OEncounter_datetime,oLocation_id,oContactDuringVisit,oCreator,oCreateDate;
    IF done THEN
      LEAVE observation_loop;
    END IF;
	
    select 6 as homeVisit;
    /* migration of Patient présent */
	if(oContactDuringVisit=1||oContactDuringVisit=5||oContactDuringVisit=9) then 
	 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
	values (oPatientID,1899,oEncounter_id,OEncounter_datetime,oLocation_id,1065,oCreator,oCreateDate,uuid());
	end if;
    /* migration of Patient absent */
	if(oContactDuringVisit=2||oContactDuringVisit=6||oContactDuringVisit=10) then 
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
	values (oPatientID,1899,oEncounter_id,OEncounter_datetime,oLocation_id,1066,oCreator,oCreateDate,uuid());
	end if;
	
    /* migration of Accompagnateur présent */
	if(oContactDuringVisit=4||oContactDuringVisit=5||oContactDuringVisit=6) then 
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
	values (oPatientID,160112,oEncounter_id,OEncounter_datetime,oLocation_id,163748,oCreator,oCreateDate,uuid());
	end if;
	/* migration Accompagnateur absent */
	if(oContactDuringVisit=8||oContactDuringVisit=10||oContactDuringVisit=9) then 
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
	values (oPatientID,160112,oEncounter_id,OEncounter_datetime,oLocation_id,163747,oCreator,oCreateDate,uuid());
	end if;

  END LOOP;
  
  CLOSE observation;
		
/* Support de l'accompagnateur au cours du mois précédent */		
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
		SELECT DISTINCT c.patient_id,(select concept_id from concept where uuid='65581878-a659-4e15-bd6a-699d535b7c7f') ,c.encounter_id,c.encounter_datetime,c.location_id,
		case when ac.freqSupportBuddy=1 then 1464
		     when ac.freqSupportBuddy=2 then (select concept_id from concept where uuid='33994c72-47ae-4ec4-9cfd-6a80de5457da')
			 when ac.freqSupportBuddy=4 then 1099
			 when ac.freqSupportBuddy=8 then (select concept_id from concept where uuid='af9b2b1b-f829-4c6c-81ed-a70f3c017c53')
			 when ac.freqSupportBuddy=16 then 1098
			 when ac.freqSupportBuddy=32 then 1107
		end,1,e.createDate, UUID()
		from encounter c, itech.encounter e, itech.homeCareVisits ac
		WHERE c.uuid = e.encGuid 
		AND e.siteCode = ac.siteCode
		AND e.patientID = ac.patientID
		AND concat(e.visitDateYy,"-",e.visitDateMm,"-",e.visitDateDd) =concat(ac.visitDateYy,"-",ac.visitDateMm,"-",ac.visitDateDd)
		AND ac.freqSupportBuddy in (1,2,4,8,16,32);
		
		select 8 as homeVisit;
		
		
/* Est-ce que le patient a manqué une visite ? */		
        INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
		SELECT DISTINCT c.patient_id,(select concept_id from concept where uuid='19ec4c07-484d-4f0a-adb5-2b79245b3605') ,c.encounter_id,c.encounter_datetime,c.location_id,
		case when ac.missedAppointment=1 then 1065
		     when ac.missedAppointment=2 then 1065
		end,1,e.createDate, UUID() from encounter c, itech.encounter e, itech.homeCareVisits ac
		WHERE c.uuid = e.encGuid AND e.siteCode = ac.siteCode
		AND e.patientID = ac.patientID
		AND concat(e.visitDateYy,"-",e.visitDateMm,"-",e.visitDateDd) =concat(ac.visitDateYy,"-",ac.visitDateMm,"-",ac.visitDateDd)
		AND ac.missedAppointment in (1,2);		
/* Date de la visite manquée */		
        INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
		SELECT DISTINCT c.patient_id,(select concept_id from concept where uuid='e45337bf-6953-4c9d-9604-a3d74523aca9') ,c.encounter_id,c.encounter_datetime,c.location_id,
		formatDate(ac.missedDateYy,ac.missedDateMm,ac.missedDateDd),1,e.createDate, UUID()
		from encounter c, itech.encounter e, itech.homeCareVisits ac
		WHERE c.uuid = e.encGuid 
		AND e.siteCode = ac.siteCode
		AND e.patientID = ac.patientID
		AND concat(e.visitDateYy,"-",e.visitDateMm,"-",e.visitDateDd) =concat(ac.visitDateYy,"-",ac.visitDateMm,"-",ac.visitDateDd)
		AND ac.missedDateYy>1 and missedDateMm>0;
/* Raison de la manque de visite */	
        INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,comments,creator,date_created,uuid)
		SELECT DISTINCT c.patient_id,(select concept_id from concept where uuid='f8162b87-e660-41d4-86c9-392a45bdbf7d') ,c.encounter_id,c.encounter_datetime,c.location_id,
		case when ac.reasonMissed=1 then 1737
		     when ac.reasonMissed=2 then (select concept_id from concept where uuid='b4c726da-e0c6-4109-96e6-5ca4d5c2f04e')
			 when ac.reasonMissed=4 then (select concept_id from concept where uuid='18cfea41-c788-4096-9652-5c6b53eb549b')
			 when ac.reasonMissed=8 then (select concept_id from concept where uuid='1b1a2739-6ae0-43f9-b765-9e2e20968532')
			 when ac.reasonMissed=16 then (select concept_id from concept where uuid='d0378433-debc-4a5d-b989-6c32aede2bb6')
			 when ac.reasonMissed=32 then 164377
			 when ac.reasonMissed=64 then 162192
			 when ac.reasonMissed=128 then 160589
			 when ac.reasonMissed=256 then 5622
		end,reasonMissedText,1,e.createDate, UUID()
		from encounter c, itech.encounter e, itech.homeCareVisits ac
		WHERE c.uuid = e.encGuid 
		AND e.siteCode = ac.siteCode
		AND e.patientID = ac.patientID
		AND concat(e.visitDateYy,"-",e.visitDateMm,"-",e.visitDateDd) =concat(ac.visitDateYy,"-",ac.visitDateMm,"-",ac.visitDateDd)
		AND ac.reasonMissed in (1,2,4,8,16,32,64,128,256);		

/* DESCRIPTION DE LA MALADIE DONT LE PATIENT SOUFFRE ACTUELLEMENT */ 
OPEN maladie;

  maladie_loop: LOOP
  FETCH maladie INTO oPatientID,oEncounter_id,OEncounter_datetime,oLocation_id,oIllnessDescription,oIllnessDescriptionOther,oCreator,oCreateDate;
    IF done THEN
      LEAVE maladie_loop;
    END IF;
	 
    select 10 as homeVisit;
    /* Douleur abdominale */
      /*Migration for obsgroup*/
	if(substr(reverse(bin(oIllnessDescription)),1,1)=1) then 
	 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	values (oPatientID,(select concept_id from concept where uuid='280f7e9e-73de-4fa1-899e-3e4db50915db'),oEncounter_id,OEncounter_datetime,oLocation_id,oCreator,oCreateDate,uuid());
	
    delete from itech.obs_concept_group where 1;
    INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
    SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
    FROM openmrs.obs,openmrs.concept c
    WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='280f7e9e-73de-4fa1-899e-3e4db50915db' 
    GROUP BY openmrs.obs.person_id,encounter_id;
	
	/*migration of the concept  Douleur abdominale*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,obs_group_id,creator,date_created,uuid)
	values (oPatientID,1728,oEncounter_id,OEncounter_datetime,oLocation_id,151,
	(select distinct obs_id from itech.obs_concept_group where person_id=oPatientID and encounter_id=oEncounter_id),oCreator,oCreateDate,uuid());
	
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,obs_group_id,creator,date_created,uuid)
	values (oPatientID,1729,oEncounter_id,OEncounter_datetime,oLocation_id,1065,
	(select distinct obs_id from itech.obs_concept_group where person_id=oPatientID and encounter_id=oEncounter_id),oCreator,oCreateDate,uuid());
	
	end if;
   /* End of Douleur abdominale */
   
   select 11 as homeVisit;
    /* Diarrhée */
      /*Migration for obsgroup*/
	if(substr(reverse(bin(oIllnessDescription)),2,1)=1) then 
	 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	values (oPatientID,(select concept_id from concept where uuid='cc8df5ed-7f7a-4c39-ae6c-d292c46c3034'),oEncounter_id,OEncounter_datetime,oLocation_id,oCreator,oCreateDate,uuid());
	
    delete from itech.obs_concept_group where 1;
    INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
    SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
    FROM openmrs.obs,openmrs.concept c
    WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='cc8df5ed-7f7a-4c39-ae6c-d292c46c3034' 
    GROUP BY openmrs.obs.person_id,encounter_id;
	
	/*migration of the concept  Diarrhée*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,obs_group_id,creator,date_created,uuid)
	values (oPatientID,1728,oEncounter_id,OEncounter_datetime,oLocation_id,142412,
	(select distinct obs_id from itech.obs_concept_group where person_id=oPatientID and encounter_id=oEncounter_id),oCreator,oCreateDate,uuid());
	
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,obs_group_id,creator,date_created,uuid)
	values (oPatientID,1729,oEncounter_id,OEncounter_datetime,oLocation_id,1065,
	(select distinct obs_id from itech.obs_concept_group where person_id=oPatientID and encounter_id=oEncounter_id),oCreator,oCreateDate,uuid());
	
	end if;
   /* End of Diarrhée */
   
   select 12 as homeVisit;
    /* Maux de tête */
      /*Migration for obsgroup*/
	if(substr(reverse(bin(oIllnessDescription)),3,1)=1) then 
	 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	values (oPatientID,(select concept_id from concept where uuid='7ff8201b-93b9-4aa3-b86c-ab9c567a1f35'),oEncounter_id,OEncounter_datetime,oLocation_id,oCreator,oCreateDate,uuid());
	
    delete from itech.obs_concept_group where 1;
    INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
    SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
    FROM openmrs.obs,openmrs.concept c
    WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='7ff8201b-93b9-4aa3-b86c-ab9c567a1f35' 
    GROUP BY openmrs.obs.person_id,encounter_id;
	
	/*migration of the concept  Maux de tête*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,obs_group_id,creator,date_created,uuid)
	values (oPatientID,1728,oEncounter_id,OEncounter_datetime,oLocation_id,139084,
	(select distinct obs_id from itech.obs_concept_group where person_id=oPatientID and encounter_id=oEncounter_id),oCreator,oCreateDate,uuid());
	
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,obs_group_id,creator,date_created,uuid)
	values (oPatientID,1729,oEncounter_id,OEncounter_datetime,oLocation_id,1065,
	(select distinct obs_id from itech.obs_concept_group where person_id=oPatientID and encounter_id=oEncounter_id),oCreator,oCreateDate,uuid());
	
	end if;
   /* End of Maux de tête */
   
   
      select 13 as homeVisit;
    /* Fièvre */
      /*Migration for obsgroup*/
	if(substr(reverse(bin(oIllnessDescription)),4,1)=1) then 
	 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	values (oPatientID,(select concept_id from concept where uuid='271a5ab5-131d-45c9-9415-b0dcedb418c7'),oEncounter_id,OEncounter_datetime,oLocation_id,oCreator,oCreateDate,uuid());
	
    delete from itech.obs_concept_group where 1;
    INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
    SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
    FROM openmrs.obs,openmrs.concept c
    WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='271a5ab5-131d-45c9-9415-b0dcedb418c7' 
    GROUP BY openmrs.obs.person_id,encounter_id;
	
	/*migration of the concept  Fièvre */
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,obs_group_id,creator,date_created,uuid)
	values (oPatientID,1728,oEncounter_id,OEncounter_datetime,oLocation_id,140238,
	(select distinct obs_id from itech.obs_concept_group where person_id=oPatientID and encounter_id=oEncounter_id),oCreator,oCreateDate,uuid());
	
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,obs_group_id,creator,date_created,uuid)
	values (oPatientID,1729,oEncounter_id,OEncounter_datetime,oLocation_id,1065,
	(select distinct obs_id from itech.obs_concept_group where person_id=oPatientID and encounter_id=oEncounter_id),oCreator,oCreateDate,uuid());
	
	end if;
   /* End of Fièvre */
   
   
        select 14 as homeVisit;
    /* Nausée */
      /*Migration for obsgroup*/
	if(substr(reverse(bin(oIllnessDescription)),5,1)=1) then 
	 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	values (oPatientID,(select concept_id from concept where uuid='244851ca-731c-4ee1-8557-4c75cb38fe9b'),oEncounter_id,OEncounter_datetime,oLocation_id,oCreator,oCreateDate,uuid());
	
    delete from itech.obs_concept_group where 1;
    INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
    SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
    FROM openmrs.obs,openmrs.concept c
    WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='244851ca-731c-4ee1-8557-4c75cb38fe9b' 
    GROUP BY openmrs.obs.person_id,encounter_id;
	
	/*migration of the concept  Nausée */
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,obs_group_id,creator,date_created,uuid)
	values (oPatientID,1728,oEncounter_id,OEncounter_datetime,oLocation_id,5978,
	(select distinct obs_id from itech.obs_concept_group where person_id=oPatientID and encounter_id=oEncounter_id),oCreator,oCreateDate,uuid());
	
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,obs_group_id,creator,date_created,uuid)
	values (oPatientID,1729,oEncounter_id,OEncounter_datetime,oLocation_id,1065,
	(select distinct obs_id from itech.obs_concept_group where person_id=oPatientID and encounter_id=oEncounter_id),oCreator,oCreateDate,uuid());
	
	end if;
   /* End of Nausée */

    select 15 as homeVisit;
    /* Autres */
      /*Migration for obsgroup*/
	if(substr(reverse(bin(oIllnessDescription)),6,1)=1) then 
	 INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	values (oPatientID,(select concept_id from concept where uuid='0671685b-ced1-459f-b31d-fa851985d117'),oEncounter_id,OEncounter_datetime,oLocation_id,oCreator,oCreateDate,uuid());
	
    delete from itech.obs_concept_group where 1;
    INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
    SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
    FROM openmrs.obs,openmrs.concept c
    WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='0671685b-ced1-459f-b31d-fa851985d117' 
    GROUP BY openmrs.obs.person_id,encounter_id;
	
	/*migration of the concept  Autres */
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,obs_group_id,comments,creator,date_created,uuid)
	values (oPatientID,1728,oEncounter_id,OEncounter_datetime,oLocation_id,5622,
	(select distinct obs_id from itech.obs_concept_group where person_id=oPatientID and encounter_id=oEncounter_id),oIllnessDescriptionOther,oCreator,oCreateDate,uuid());
	
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,obs_group_id,creator,date_created,uuid)
	values (oPatientID,1729,oEncounter_id,OEncounter_datetime,oLocation_id,1065,
	(select distinct obs_id from itech.obs_concept_group where person_id=oPatientID and encounter_id=oEncounter_id),oCreator,oCreateDate,uuid());
	
	end if;
   /* End of Autres */ 
   
  END LOOP;
  
  CLOSE maladie;

	

/* SERVICES RENDUS */ 

OPEN serviceDelivery;

  serviceDelivery_loop: LOOP
  FETCH serviceDelivery INTO oPatientID,oEncounter_id,OEncounter_datetime,oLocation_id,oServiceDelivery,oServiceDeliveryOther,oCreator,oCreateDate;
    IF done THEN
      LEAVE serviceDelivery_loop;
    END IF;
	 
    select 16 as homeVisit;
    /* Counseling/Support psychosocial pour patient ou famille */
	if(substr(reverse(bin(oServiceDelivery)),1,1)=1) then 
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
	values (oPatientID,163560,oEncounter_id,OEncounter_datetime,oLocation_id,5490,oCreator,oCreateDate,uuid());	
	end if;

	 /* Aide alimentaire */
	if(substr(reverse(bin(oServiceDelivery)),2,1)=1) then 
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
	values (oPatientID,163560,oEncounter_id,OEncounter_datetime,oLocation_id,161648,oCreator,oCreateDate,uuid());	
	end if;

	 /* Kit pour les soins à domicile */
	if(substr(reverse(bin(oServiceDelivery)),3,1)=1) then 
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
	values (oPatientID,163560,oEncounter_id,OEncounter_datetime,oLocation_id,(select concept_id from concept where uuid='eb2104d6-bb87-4283-a024-d9a115e57a27'),oCreator,oCreateDate,uuid());	
	end if;	

	 /* Livraisons des Médicaments */
	if(substr(reverse(bin(oServiceDelivery)),4,1)=1) then 
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
	values (oPatientID,163560,oEncounter_id,OEncounter_datetime,oLocation_id,(select concept_id from concept where uuid='6e2a8a88-e49d-4382-8125-e7afc8d420b8'),oCreator,oCreateDate,uuid());	
	end if;		
	
	 /* Conseils santé */
	if(substr(reverse(bin(oServiceDelivery)),5,1)=1) then 
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
	values (oPatientID,163560,oEncounter_id,OEncounter_datetime,oLocation_id,1379,oCreator,oCreateDate,uuid());	
	end if;	

	 /* Autres */
	if(substr(reverse(bin(oServiceDelivery)),6,1)=1) then 
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
	values (oPatientID,163560,oEncounter_id,OEncounter_datetime,oLocation_id,5622,oCreator,oCreateDate,uuid());	
	end if;		
   
   
  END LOOP;
  
  CLOSE serviceDelivery;



/* PLAN DE SUIVI */
/* Prochaine visite médicale à la établissement recommandée dans */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT c.patient_id,(select concept_id from concept where uuid='7f142c0a-5f24-472b-955d-f839e36f5e24') ,c.encounter_id,c.encounter_datetime,c.location_id,
FindNumericValue(nextClinicVisitDays) ,1,e.createDate, UUID()
from encounter c, itech.encounter e, itech.homeCareVisits ac
WHERE c.uuid = e.encGuid 
AND e.siteCode = ac.siteCode
AND e.patientID = ac.patientID 
AND concat(e.visitDateYy,"-",e.visitDateMm,"-",e.visitDateDd) =concat(ac.visitDateYy,"-",ac.visitDateMm,"-",ac.visitDateDd)
AND FindNumericValue(ac.nextClinicVisitDays)>0;

/* Date de la prochaine visite à la établissement */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT c.patient_id,5096 ,c.encounter_id,c.encounter_datetime,c.location_id,
formatDate(ac.nextClinicVisitYy,ac.nextClinicVisitMm,ac.nextClinicVisitDd) ,1,e.createDate, UUID()
from encounter c, itech.encounter e, itech.homeCareVisits ac
WHERE c.uuid = e.encGuid 
AND e.siteCode = ac.siteCode
AND e.patientID = ac.patientID 
AND concat(e.visitDateYy,"-",e.visitDateMm,"-",e.visitDateDd) =concat(ac.visitDateYy,"-",ac.visitDateMm,"-",ac.visitDateDd)
AND ac.nextClinicVisitYy>1 and ac.nextClinicVisitMm>0;

/* Prochaine visite à domicile recommandée dans */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT c.patient_id,(select concept_id from concept where uuid='4abbc619-d0ba-4233-89aa-d94647327b4c') ,c.encounter_id,c.encounter_datetime,c.location_id,
FindNumericValue(nextHomeVisitDays) ,1,e.createDate, UUID()
from encounter c, itech.encounter e, itech.homeCareVisits ac
WHERE c.uuid = e.encGuid 
AND e.siteCode = ac.siteCode
AND e.patientID = ac.patientID 
AND concat(e.visitDateYy,"-",e.visitDateMm,"-",e.visitDateDd) =concat(ac.visitDateYy,"-",ac.visitDateMm,"-",ac.visitDateDd)
AND FindNumericValue(ac.nextHomeVisitDays)>0;

/* Date de la prochaine visite à domicile */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT c.patient_id,(select concept_id from concept where uuid='545a2c88-2f37-4228-97ef-3895b480062d') ,c.encounter_id,c.encounter_datetime,c.location_id,
formatDate(ac.nextHomeVisitYy,ac.nextHomeVisitMm,ac.nextHomeVisitDd) ,1,e.createDate, UUID()
from encounter c, itech.encounter e, itech.homeCareVisits ac
WHERE c.uuid = e.encGuid 
AND e.siteCode = ac.siteCode
AND e.patientID = ac.patientID 
AND concat(e.visitDateYy,"-",e.visitDateMm,"-",e.visitDateDd) =concat(ac.visitDateYy,"-",ac.visitDateMm,"-",ac.visitDateDd)
AND ac.nextHomeVisitYy>1 and ac.nextHomeVisitMm>0;



		/*End migration for Raison donnée pour avoir manqué une dose, cocher le ou les cas ci-dessous*/
END$$
	DELIMITER ;