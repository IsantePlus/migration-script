/*migration data for the old iSante lab form*/

DELIMITER $$
DROP PROCEDURE IF EXISTS labsMigrationOldData$$
CREATE PROCEDURE labsMigrationOldData()
BEGIN
 /*Delete all inserted labs data if the script fail
 SET SQL_SAFE_UPDATES = 0;
 SET FOREIGN_KEY_CHECKS=0;
 DELETE FROM obs WHERE encounter_id IN
 (
	SELECT en.encounter_id FROM encounter en, encounter_type ent
	WHERE en.encounter_type=ent.encounter_type_id
	AND ent.uuid='f037e97b-471e-4898-a07c-b8e169e0ddc4'
 );
  SET SQL_SAFE_UPDATES = 1;
SET FOREIGN_KEY_CHECKS=1;
*/

/*Start migration for labs data*/
	/*start migration for Tests rapides*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	1040,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID=100;
   /*Answer*/
   INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1040,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,
	CASE WHEN (
				(l.result like lower("NEG%"))
				OR (l.result2 like lower("NEG%"))
				OR (l.result3 like lower("NEG%"))
				OR (l.result4 like lower("NEG%"))
			  ) THEN 664
		WHEN (
				(l.result like lower("POS%"))
				OR (l.result2 like lower("POS%"))
				OR (l.result3 like lower("POS%"))
				OR (l.result4 like lower("POS%"))
			  ) THEN 703 
		WHEN (
				(l.result = '4')
				OR (l.result2 = '4')
				OR (l.result3 = '4')
				OR (l.result4 = '4')
			  ) THEN 1138
		END,
	l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID=100
	AND ((l.result like lower("POS%") OR l.result like lower("NEG%") OR l.result = '4')
		OR (l.result2 like lower("POS%") OR l.result2 like lower("NEG%") OR l.result2 = '4')
		OR (l.result3 like lower("POS%") OR l.result3 like lower("NEG%") OR l.result3 = '4')
		OR (l.result4 like lower("POS%") OR l.result4 like lower("NEG%") OR l.result4 = '4')
	);
	/*end migration for Tests rapides*/
	/*Start migration for test ELISA*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	1042,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 101;
   /*Answer*/
   INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1042,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,
	CASE WHEN (
				(l.result like lower("NEG%"))
				OR (l.result2 like lower("NEG%"))
				OR (l.result3 like lower("NEG%"))
				OR (l.result4 like lower("NEG%"))
			  ) THEN 664
		WHEN (
				(l.result like lower("POS%"))
				OR (l.result2 like lower("POS%"))
				OR (l.result3 like lower("POS%"))
				OR (l.result4 like lower("POS%"))
			  ) THEN 703 
		WHEN (
				(l.result = '4')
				OR (l.result2 = '4')
				OR (l.result3 = '4')
				OR (l.result4 = '4')
			  ) THEN 1138
		END,
	l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 101
	AND (
		(l.result like lower("POS%") OR l.result like lower("NEG%") OR l.result = '4')
		OR (l.result2 like lower("POS%") OR l.result2 like lower("NEG%") OR l.result2 = '4')
		OR (l.result3 like lower("POS%") OR l.result3 like lower("NEG%") OR l.result3 = '4')
		OR (l.result4 like lower("POS%") OR l.result4 like lower("NEG%") OR l.result4 = '4')
	);
	/*End migration for Test ELISA*/
	/*Start migration for CD4*/
	/*Create table obs_concept_group for the obs_group_id*/
	create table if not exists itech.obs_concept_group (obs_id int,person_id int,concept_id int,encounter_id int);
		/*Start migration for CD4 Compte Absolu*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	 5497,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID	= 176;
	/*Insert obs_group for CD4 Compte Absolu */
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	SELECT DISTINCT e.patient_id,657,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
	FROM itech.encounter c, encounter e, itech.labs l 
	WHERE e.uuid = c.encGuid and c.patientID = l.patientID and c.seqNum = l.seqNum and 
	c.sitecode = l.sitecode and DATE(e.encounter_datetime) = DATE_FORMAT(concat(l.visitDateYy,'-',l.visitDateMm,'-',l.visitDateDd),"%Y-%m-%d") AND 
	l.labID = 176 and l.result is not null;
	/*Finding the last obs_group_id inserted */
	TRUNCATE TABLE itech.obs_concept_group;
	INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
	SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
	FROM openmrs.obs
	WHERE openmrs.obs.concept_id=657 
	GROUP BY openmrs.obs.person_id,encounter_id;

	/*Finding the last obs_group_id inserted */
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,5497,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,cg.obs_id,digits(l.result) as resultat,l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l, itech.obs_concept_group cg 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND c.encounter_id=cg.encounter_id
	AND c.patient_id=cg.person_id
	AND l.labID = 176
	AND (l.result <> "" AND digits(l.result) > 0);
	/*END of CD4 Compte Absolu*/
	/*Starting insert for CD4 Compte en %*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
		creator,date_created,uuid)
		SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
		730,1,e.createDate,
		UUID()
		from encounter c, itech.encounter e, itech.labs l 
		WHERE c.uuid = e.encGuid and 
		e.patientID = l.patientID and e.siteCode = l.siteCode 
		and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
		concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
		and e.seqNum = l.seqNum
		AND l.labID = 176
		AND (l.result2 <> "" AND digits(l.result2) > 0);
		/*add obsgroup*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
		SELECT DISTINCT e.patient_id,657,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
		FROM itech.encounter c, encounter e, itech.labs l 
		WHERE e.uuid = c.encGuid and c.patientID = l.patientID and c.seqNum = l.seqNum and 
		c.sitecode = l.sitecode and DATE(e.encounter_datetime) = DATE_FORMAT(concat(l.visitDateYy,'-',l.visitDateMm,'-',l.visitDateDd),"%Y-%m-%d") AND 
		l.labID = 176 AND (l.result2 <> "" AND digits(l.result2) > 0);
		/*Finding the last obs_group_id inserted */
	TRUNCATE TABLE itech.obs_concept_group;
	INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
	SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
	FROM openmrs.obs
	WHERE openmrs.obs.concept_id=657 
	GROUP BY openmrs.obs.person_id,encounter_id;
	   /*concept*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,730,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,cg.obs_id,digits(l.result2) as resultat,l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l, itech.obs_concept_group cg
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND c.encounter_id = cg.encounter_id
	AND c.patient_id = cg.person_id
	AND l.labID = 176
	AND (l.result2 <> "" AND digits(l.result2) > 0);
	/*Ending insert for CD4 Compte en %*/
	/*End migration for CD4*/
	
	/*Start migration for Lymphocytes*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	1338,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 105
	and (l.result2 <> "" AND digits(l.result2) >= 0);
	 /*Migration for obsgroup*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	SELECT DISTINCT e.patient_id,163700,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
	FROM itech.encounter c, encounter e, itech.labs l 
	WHERE e.uuid = c.encGuid and c.patientID = l.patientID and c.seqNum = l.seqNum and 
	c.sitecode = l.sitecode and DATE(e.encounter_datetime) = DATE_FORMAT(concat(l.visitDateYy,'-',l.visitDateMm,'-',l.visitDateDd),"%Y-%m-%d") AND 
	l.labID = 105 and (l.result2 <> "" AND digits(l.result2) >= 0);
	/*Finding the last obs_group_id inserted */
	TRUNCATE TABLE itech.obs_concept_group;
	INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
	SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
	FROM openmrs.obs
	WHERE openmrs.obs.concept_id=163700 
	GROUP BY openmrs.obs.person_id,encounter_id;
   /*Answer*/
    INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1338,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,cg.obs_id,digits(l.result2) as resultat,l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l, itech.obs_concept_group cg 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND c.encounter_id = cg.encounter_id
	AND c.patient_id = cg.person_id
	AND l.labID = 105
	AND (l.result <> "" AND digits(l.result) >= 0);
	/*End migration for Lymphocytes*/
	
	/*Starting migration for Monocytes*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
		creator,date_created,uuid)
		SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
		1339,1,e.createDate,
		UUID()
		from encounter c, itech.encounter e, itech.labs l 
		WHERE c.uuid = e.encGuid and 
		e.patientID = l.patientID and e.siteCode = l.siteCode 
		and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
		concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
		and e.seqNum = l.seqNum
		AND l.labID = 106
		AND (l.result2 <> "" AND digits(l.result2) >= 0);
		
		/*concept*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,comments,
		creator,date_created,uuid)
		SELECT DISTINCT c.patient_id,1339,c.encounter_id,
		ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,digits(l.result2),l.resultRemarks,1,e.createDate, UUID()
		from encounter c, itech.encounter e, itech.labs l 
		WHERE c.uuid = e.encGuid and 
		e.patientID = l.patientID and e.siteCode = l.siteCode 
		and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
		concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
		and e.seqNum = l.seqNum
		AND l.labID = 106
		AND (l.result2 <> "" AND digits(l.result2) >= 0);
	/*Ending migration for Monocytes*/
	/*Start migration for Hématocrites*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	1015,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 175
	AND (l.result <> "" AND digits(l.result) >= 0);
	 /*Migration for obsgroup*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	SELECT DISTINCT e.patient_id,163700,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
	FROM itech.encounter c, encounter e, itech.labs l 
	WHERE e.uuid = c.encGuid and c.patientID = l.patientID and c.seqNum = l.seqNum and 
	c.sitecode = l.sitecode and DATE(e.encounter_datetime) = DATE_FORMAT(concat(l.visitDateYy,'-',l.visitDateMm,'-',l.visitDateDd),"%Y-%m-%d") AND 
	l.labID = 175 and (l.result <> "" AND digits(l.result) >= 0);
	/*Finding the last obs_group_id inserted */
	TRUNCATE TABLE itech.obs_concept_group;
	INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
	SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
	FROM openmrs.obs
	WHERE openmrs.obs.concept_id=163700 
	GROUP BY openmrs.obs.person_id,encounter_id;
   /*Answer*/
    INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1015,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,cg.obs_id,digits(l.result) as resultat,l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l, itech.obs_concept_group cg 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND c.encounter_id=cg.encounter_id
	AND c.patient_id=cg.person_id
	AND l.labID = 175
	AND (l.result <> "" AND digits(l.result) >= 0);
	
	/*End migration for Hématocrites*/
	/*Start migration for Hémoglobine*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	21,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 177;
	 /*Migration for obsgroup*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	SELECT DISTINCT e.patient_id,163700,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
	FROM itech.encounter c, encounter e, itech.labs l 
	WHERE e.uuid = c.encGuid and c.patientID = l.patientID and c.seqNum = l.seqNum and 
	c.sitecode = l.sitecode and DATE(e.encounter_datetime) = DATE_FORMAT(concat(l.visitDateYy,'-',l.visitDateMm,'-',l.visitDateDd),"%Y-%m-%d") AND 
	l.labID = 177 and (l.result <> "" AND digits(l.result) >= 0);
	/*Finding the last obs_group_id inserted */
	TRUNCATE TABLE itech.obs_concept_group;
	INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
	SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
	FROM openmrs.obs
	WHERE openmrs.obs.concept_id=163700 
	GROUP BY openmrs.obs.person_id,encounter_id;
   /*Answer*/
    INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,21,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,cg.obs_id,digits(l.result) as resultat,l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l, itech.obs_concept_group cg 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND c.encounter_id = cg.encounter_id
	AND c.patient_id = cg.person_id
	AND l.labID = 177
	AND (l.result <> "" AND digits(l.result) >= 0);
	/*End migration for Hémoglobine*/
	
	/*Starting migration for Vitesse de Sedimentation*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
		creator,date_created,uuid)
		SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
		855,1,e.createDate,UUID()
		from encounter c, itech.encounter e, itech.labs l 
		WHERE c.uuid = e.encGuid and 
		e.patientID = l.patientID and e.siteCode = l.siteCode 
		and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
		concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
		and e.seqNum = l.seqNum
		AND l.labID = 147;
		
		
		/*concept*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,comments,
		creator,date_created,uuid)
		SELECT DISTINCT c.patient_id,855,c.encounter_id,
		ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,digits(l.result),l.resultRemarks,1,e.createDate, UUID()
		from encounter c, itech.encounter e, itech.labs l 
		WHERE c.uuid = e.encGuid and 
		e.patientID = l.patientID and e.siteCode = l.siteCode 
		and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
		concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
		and e.seqNum = l.seqNum
		AND l.labID = 147
		AND (l.result <> "" AND digits(l.result) >= 0);
	/*Ending migration for Vitesse de Sedimentation*/
	/*Starting migration for Groupe Sanguin - Rhesus (Have concept group)*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	160232,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 151;
	 /*Migration for obsgroup*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	SELECT DISTINCT e.patient_id,161473,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
	FROM itech.encounter c, encounter e, itech.labs l 
	WHERE e.uuid = c.encGuid and c.patientID = l.patientID and c.seqNum = l.seqNum and 
	c.sitecode = l.sitecode and DATE(e.encounter_datetime) = DATE_FORMAT(concat(l.visitDateYy,'-',l.visitDateMm,'-',l.visitDateDd),"%Y-%m-%d") AND 
	l.labID = 151 and l.result2 IN(1,2);
	/*Finding the last obs_group_id inserted */
	TRUNCATE TABLE itech.obs_concept_group;
	INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
	SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
	FROM openmrs.obs
	WHERE openmrs.obs.concept_id=161473 
	GROUP BY openmrs.obs.person_id,encounter_id;
   /*Answer*/
    INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,160232,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,cg.obs_id,
	CASE WHEN (digits(l.result2) = 1) THEN 703
	WHEN(digits(l.result2) = 2) THEN 664
	ELSE null
	END,l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l, itech.obs_concept_group cg 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND c.encounter_id = cg.encounter_id
	AND c.patient_id = cg.person_id
	AND l.labID = 151
	AND (digits(l.result2) IN(1,2));
	/*Ending migration for Groupe Sanguin - Rhesus*/
	
	/*Start Migration for HCO3 (have concept group)*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	163596,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 180;
	 /*Migration for obsgroup*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	SELECT DISTINCT e.patient_id,163602,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
	FROM itech.encounter c, encounter e, itech.labs l 
	WHERE e.uuid = c.encGuid and c.patientID = l.patientID and c.seqNum = l.seqNum and 
	c.sitecode = l.sitecode and DATE(e.encounter_datetime) = DATE_FORMAT(concat(l.visitDateYy,'-',l.visitDateMm,'-',l.visitDateDd),"%Y-%m-%d") AND 
	l.labID = 180 and (l.result <> "" AND l.result is not null AND digits(l.result) >= 0);
	/*Finding the last obs_group_id inserted */
	TRUNCATE TABLE itech.obs_concept_group;
	INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
	SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
	FROM openmrs.obs
	WHERE openmrs.obs.concept_id=163602
	GROUP BY openmrs.obs.person_id,encounter_id;
   /*Answer*/
    INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,163596,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,cg.obs_id,digits(l.result) as resultat,l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l, itech.obs_concept_group cg 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND c.encounter_id = cg.encounter_id
	AND c.patient_id = cg.person_id
	AND l.labID = 180
	AND (l.result <> "" AND l.result is not null AND digits(l.result) >= 0);
		
	/*End migration for HCO3*/
	
	/*Starting migration for Créatinine (have concept group)*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	790,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 155;
	 /*Migration for obsgroup*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	SELECT DISTINCT e.patient_id,161488,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
	FROM itech.encounter c, encounter e, itech.labs l 
	WHERE e.uuid = c.encGuid and c.patientID = l.patientID and c.seqNum = l.seqNum and 
	c.sitecode = l.sitecode and DATE(e.encounter_datetime) = DATE_FORMAT(concat(l.visitDateYy,'-',l.visitDateMm,'-',l.visitDateDd),"%Y-%m-%d") AND 
	l.labID = 155 and (l.result <> "" AND l.result is not null AND digits(l.result) >= 0)
	AND digits(l.result2) = 1;
	/*Finding the last obs_group_id inserted */
	TRUNCATE TABLE itech.obs_concept_group;
	INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
	SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
	FROM openmrs.obs
	WHERE openmrs.obs.concept_id=161488
	GROUP BY openmrs.obs.person_id,encounter_id;
   /*Answer*/
    INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,790,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,cg.obs_id,digits(l.result) as resultat,l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l, itech.obs_concept_group cg 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND c.encounter_id = cg.encounter_id
	AND c.patient_id = cg.person_id
	AND l.labID = 155
	AND (l.result <> "" AND l.result2 is not null AND digits(l.result) >= 0)
	AND digits(l.result2) = 1;
	/*END migration for Créatinine*/
	/*Start Migration for SGOT (AST) (have concept group)*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	653,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 158;
	 /*Migration for obsgroup*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	SELECT DISTINCT e.patient_id,953,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
	FROM itech.encounter c, encounter e, itech.labs l 
	WHERE e.uuid = c.encGuid and c.patientID = l.patientID and c.seqNum = l.seqNum and 
	c.sitecode = l.sitecode and DATE(e.encounter_datetime) = DATE_FORMAT(concat(l.visitDateYy,'-',l.visitDateMm,'-',l.visitDateDd),"%Y-%m-%d") AND 
	l.labID = 158 and (l.result <> "" AND l.result is not null AND digits(l.result) >= 0)
	AND digits(l.result2) = 1;
	/*Finding the last obs_group_id inserted */
	TRUNCATE TABLE itech.obs_concept_group;
	INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
	SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
	FROM openmrs.obs
	WHERE openmrs.obs.concept_id = 953
	GROUP BY openmrs.obs.person_id,encounter_id;
   /*Answer*/
    INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,653,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,cg.obs_id,
	CASE WHEN digits(l.result2) = 1 THEN digits(l.result)
	WHEN digits(l.result2) = 2 THEN (digits(l.result) * 1000)
	END,
	l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l, itech.obs_concept_group cg 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND c.encounter_id = cg.encounter_id
	AND c.patient_id = cg.person_id
	AND l.labID = 158
	AND (l.result <> "" AND l.result is not null AND digits(l.result) >= 0)
	AND digits(l.result2) = 1;
	/*End migration for SGOT (AST)*/
	
	/*Start migration for SGPT (ALT) (have concept group)*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	654,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 159;
	 /*Migration for obsgroup*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	SELECT DISTINCT e.patient_id,953,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
	FROM itech.encounter c, encounter e, itech.labs l 
	WHERE e.uuid = c.encGuid and c.patientID = l.patientID and c.seqNum = l.seqNum and 
	c.sitecode = l.sitecode and DATE(e.encounter_datetime) = DATE_FORMAT(concat(l.visitDateYy,'-',l.visitDateMm,'-',l.visitDateDd),"%Y-%m-%d") AND 
	l.labID = 159 and (l.result <> "" AND l.result is not null AND digits(l.result) >= 0)
	AND digits(l.result2) = 1;
	/*Finding the last obs_group_id inserted */
	TRUNCATE TABLE itech.obs_concept_group;
	INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
	SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
	FROM openmrs.obs
	WHERE openmrs.obs.concept_id = 953
	GROUP BY openmrs.obs.person_id,encounter_id;
   /*Answer*/
    INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,654,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,cg.obs_id,
	CASE WHEN digits(l.result2) = 1 THEN digits(l.result)
	WHEN digits(l.result2) = 2 THEN (digits(l.result) * 1000)
	END,l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l, itech.obs_concept_group cg 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND c.encounter_id = cg.encounter_id
	AND c.patient_id = cg.person_id
	AND l.labID = 159
	AND (l.result <> "" AND l.result is not null AND digits(l.result) >= 0)
	AND digits(l.result2) = 1;
	/*End migration for SGPT (ALT)*/
	
	/*Starting migration for Bilirubine totale(have concept group)*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	655,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID  = 160;
	 /*Migration for obsgroup*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	SELECT DISTINCT e.patient_id,953,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
	FROM itech.encounter c, encounter e, itech.labs l 
	WHERE e.uuid = c.encGuid and c.patientID = l.patientID and c.seqNum = l.seqNum and 
	c.sitecode = l.sitecode and DATE(e.encounter_datetime) = DATE_FORMAT(concat(l.visitDateYy,'-',l.visitDateMm,'-',l.visitDateDd),"%Y-%m-%d") AND 
	l.labID = 160 and (l.result <> "" AND l.result is not null AND digits(l.result) >= 0);
	/*Finding the last obs_group_id inserted */
	TRUNCATE TABLE itech.obs_concept_group;
	INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
	SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
	FROM openmrs.obs
	WHERE openmrs.obs.concept_id=953
	GROUP BY openmrs.obs.person_id,encounter_id;
   /*Answer*/
    INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,655,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,cg.obs_id,digits(l.result),l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l, itech.obs_concept_group cg 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND c.encounter_id = cg.encounter_id
	AND c.patient_id = cg.person_id
	AND l.labID = 160
	AND (l.result <> "" AND l.result is not null AND digits(l.result) >= 0);
	/*End migration for Bilirubine totale*/
	/*Starting migration for Amylase*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
		creator,date_created,uuid)
		SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
		1299,1,e.createDate,UUID()
		from encounter c, itech.encounter e, itech.labs l 
		WHERE c.uuid = e.encGuid and 
		e.patientID = l.patientID and e.siteCode = l.siteCode 
		and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
		concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
		and e.seqNum = l.seqNum
		AND l.labID = 161;
		
		
		/*concept*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,comments,
		creator,date_created,uuid)
		SELECT DISTINCT c.patient_id,1299,c.encounter_id,
		ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,digits(l.result),l.resultRemarks,1,e.createDate, UUID()
		from encounter c, itech.encounter e, itech.labs l 
		WHERE c.uuid = e.encGuid and 
		e.patientID = l.patientID and e.siteCode = l.siteCode 
		and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
		concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
		and e.seqNum = l.seqNum
		AND l.labID = 161
		AND (l.result <> "" AND l.result is not null AND digits(l.result) >= 0);
	/*End migration for Amylase*/
	/*Starting migration forLipase */
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
		creator,date_created,uuid)
		SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
		1013,1,e.createDate,
		UUID()
		from encounter c, itech.encounter e, itech.labs l 
		WHERE c.uuid = e.encGuid and 
		e.patientID = l.patientID and e.siteCode = l.siteCode 
		and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
		concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
		and e.seqNum = l.seqNum
		AND l.labID = 162;
		
		/*concept*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,comments,
		creator,date_created,uuid)
		SELECT DISTINCT c.patient_id,
		1013,c.encounter_id,
		ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,digits(l.result),l.resultRemarks,1,e.createDate, UUID()
		from encounter c, itech.encounter e, itech.labs l 
		WHERE c.uuid = e.encGuid and 
		e.patientID = l.patientID and e.siteCode = l.siteCode 
		and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
		concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
		and e.seqNum = l.seqNum
		AND l.labID = 162
		AND(l.result <> "" AND l.result is not null AND digits(l.result) >=0);
	/*End migration for Lipase*/
	
	/*Starting migration for Cholestérol total(have concept group)*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	1006,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 163;
	 /*Migration for obsgroup*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	SELECT DISTINCT e.patient_id,1010,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
	FROM itech.encounter c, encounter e, itech.labs l 
	WHERE e.uuid = c.encGuid and c.patientID = l.patientID and c.seqNum = l.seqNum and 
	c.sitecode = l.sitecode and DATE(e.encounter_datetime) = DATE_FORMAT(concat(l.visitDateYy,'-',l.visitDateMm,'-',l.visitDateDd),"%Y-%m-%d") AND 
	l.labID = 163 and (l.result <> "" AND l.result is not null AND digits(l.result) >= 0);
	/*Finding the last obs_group_id inserted */
	TRUNCATE TABLE itech.obs_concept_group;
	INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
	SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
	FROM openmrs.obs
	WHERE openmrs.obs.concept_id=1010
	GROUP BY openmrs.obs.person_id,encounter_id;
   /*Answer*/
    INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1006,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,cg.obs_id,digits(l.result) as resultat,l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l, itech.obs_concept_group cg 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND c.encounter_id=cg.encounter_id
	AND c.patient_id=cg.person_id
	AND l.labID = 163
	AND (l.result <> "" AND l.result is not null AND digits(l.result) >= 0);
	/*End migration for Cholestérol total*/
	/*Start migration for LDL (have oncept group)*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	1008,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 126;
	 /*Migration for obsgroup*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	SELECT DISTINCT e.patient_id,1010,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
	FROM itech.encounter c, encounter e, itech.labs l 
	WHERE e.uuid = c.encGuid and c.patientID = l.patientID and c.seqNum = l.seqNum and 
	c.sitecode = l.sitecode and DATE(e.encounter_datetime) = DATE_FORMAT(concat(l.visitDateYy,'-',l.visitDateMm,'-',l.visitDateDd),"%Y-%m-%d") AND 
	l.labID = 126 and (l.result <> "" AND l.result is not null AND digits(l.result) >= 0);
	/*Finding the last obs_group_id inserted */
	TRUNCATE TABLE itech.obs_concept_group;
	INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
	SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
	FROM openmrs.obs
	WHERE openmrs.obs.concept_id=1010
	GROUP BY openmrs.obs.person_id,encounter_id;
   /*Answer*/
    INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1008,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,cg.obs_id,digits(l.result) as resultat,l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l, itech.obs_concept_group cg 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND c.encounter_id=cg.encounter_id
	AND c.patient_id=cg.person_id
	AND l.labID = 126
	AND (l.result <> "" AND l.result is not null AND digits(l.result) >= 0);
	/*End migration for LDL*/
	/*Start Migration for HDL (have concept group)*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	1007,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 127;
	 /*Migration for obsgroup*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	SELECT DISTINCT e.patient_id,1010,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
	FROM itech.encounter c, encounter e, itech.labs l 
	WHERE e.uuid = c.encGuid and c.patientID = l.patientID and c.seqNum = l.seqNum and 
	c.sitecode = l.sitecode and DATE(e.encounter_datetime) = DATE_FORMAT(concat(l.visitDateYy,'-',l.visitDateMm,'-',l.visitDateDd),"%Y-%m-%d") AND 
	l.labID = 127 and (l.result <> "" AND l.result is not null AND digits(l.result) >= 0);
	/*Finding the last obs_group_id inserted */
	TRUNCATE TABLE itech.obs_concept_group;
	INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
	SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
	FROM openmrs.obs
	WHERE openmrs.obs.concept_id=1010
	GROUP BY openmrs.obs.person_id,encounter_id;
   /*Answer*/
    INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1007,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,cg.obs_id,digits(l.result) as resultat,l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l, itech.obs_concept_group cg 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND c.encounter_id=cg.encounter_id
	AND c.patient_id=cg.person_id
	AND l.labID = 127
	AND (l.result <> "" AND l.result is not null AND digits(l.result) >= 0);
	/*END Migration for HDL */
	
	/*Start Migration for Malaria Test Rapide*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	1643,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 132;
   /*Answer*/
   INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1643,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,
	CASE WHEN (digits(l.result) = 1) THEN 703
		 WHEN (digits(l.result) = 2) THEN 664
		END,
	l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 132
	AND (digits(l.result) IN(1,2));
	/*End migration for Malaria Test Rapide*/
	
	/*Starting migration for Sickling Test*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
		creator,date_created,uuid)
		SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
		160225,1,e.createDate,
		UUID()
		from encounter c, itech.encounter e, itech.labs l 
		WHERE c.uuid = e.encGuid and 
		e.patientID = l.patientID and e.siteCode = l.siteCode 
		and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
		concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
		and e.seqNum = l.seqNum
		AND l.labID = 142;
		
		/*concept*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,comments,
		creator,date_created,uuid)
		SELECT DISTINCT c.patient_id,160225,c.encounter_id,
		ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,
		 CASE WHEN (digits(l.result) = 2) THEN 664
			  WHEN (digits(l.result) = 1) THEN 703
		END,l.resultRemarks,1,e.createDate, UUID()
		from encounter c, itech.encounter e, itech.labs l 
		WHERE c.uuid = e.encGuid and 
		e.patientID = l.patientID and e.siteCode = l.siteCode 
		and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
		concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
		and e.seqNum = l.seqNum
		AND l.labID = 142
		AND (l.result <> "" AND l.result is not null AND digits(l.result) IN(1,2));
	/*Ending migration for Sickling Test*/
	
	/*Start migration for Syphilis RPR*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	1619,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 168;
   /*Answer*/
   INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1619,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,
	CASE WHEN (digits(l.result) = 2) THEN 664
		WHEN (digits(l.result) = 1) THEN 703
		END,
	l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 168
	AND digits(l.result) IN(1,2);
	/*End migration for Syphilis RPR*/
	/*Start migration for Test de Grossesse*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	45,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 134;
   /*Answer*/
   INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,45,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,
	CASE WHEN (l.result like lower("NEG%")) THEN 664
		WHEN (l.result  like lower("POS%")) THEN 703
		WHEN (l.result = '4') THEN 1138
		END,
	l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 134
	AND (
	     l.result like lower("POS%") or 
		 l.result like lower("Neg%") or 
		 l.result ='4'
		 );
		/*End migration for Test de Grossesse*/
	
	/*Start migration for Phosphatase Alcaline*/
			INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
		creator,date_created,uuid)
		SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
		785,1,e.createDate,UUID()
		from encounter c, itech.encounter e, itech.labs l 
		WHERE c.uuid = e.encGuid and 
		e.patientID = l.patientID and e.siteCode = l.siteCode 
		and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
		concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
		and e.seqNum = l.seqNum
		AND l.labID = 188;
		
		
		/*concept*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,comments,
		creator,date_created,uuid)
		SELECT DISTINCT c.patient_id,785,c.encounter_id,
		ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,digits(l.result),l.resultRemarks,1,e.createDate, UUID()
		from encounter c, itech.encounter e, itech.labs l 
		WHERE c.uuid = e.encGuid and 
		e.patientID = l.patientID and e.siteCode = l.siteCode 
		and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
		concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
		and e.seqNum = l.seqNum
		AND l.labID = 188
		AND (l.result <> "" AND digits(l.result) >= 0);
	/*End migration for Phosphatase Alcaline*/
	
	/*Start migration for PPD Qualitatif*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	163630,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 172;
	
	/*Migration for obsgroup*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	SELECT DISTINCT e.patient_id,163631,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
	FROM itech.encounter c, encounter e, itech.labs l
	WHERE e.uuid = c.encGuid and c.patientID = l.patientID and c.seqNum = l.seqNum
	and c.sitecode = l.sitecode and DATE(e.encounter_datetime) = DATE_FORMAT(concat(l.visitDateYy,'-',l.visitDateMm,'-',l.visitDateDd),"%Y-%m-%d") AND 
	l.labID = 172
	AND digits(l.result) IN(1,2);
	/*Finding the last obs_group_id inserted */
	TRUNCATE TABLE itech.obs_concept_group;
	INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
	SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
	FROM openmrs.obs
	WHERE openmrs.obs.concept_id=163631
	GROUP BY openmrs.obs.person_id,encounter_id;
   /*Answer*/
   INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,163630,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,cg.obs_id,
	CASE WHEN (digits(l.result) = 1) THEN 1228
		 WHEN (digits(l.result) = 2) THEN 1229
		END,
	l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l, itech.obs_concept_group cg
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND c.encounter_id=cg.encounter_id
	AND c.patient_id=cg.person_id
	AND l.labID = 172
	AND digits(l.result) IN(1,2);
		/*End migration for PPD Qualitatif*/
		
    /*Starting Migration for Groupe Sanguin - ABO (Have concept group)*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	300,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 151;
	 /*Migration for obsgroup*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	SELECT DISTINCT e.patient_id,161473,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
	FROM itech.encounter c, encounter e, itech.labs l 
	WHERE e.uuid = c.encGuid and c.patientID = l.patientID and c.seqNum = l.seqNum and 
	c.sitecode = l.sitecode and DATE(e.encounter_datetime) = DATE_FORMAT(concat(l.visitDateYy,'-',l.visitDateMm,'-',l.visitDateDd),"%Y-%m-%d") AND 
	l.labID = 151
	AND digits(l.result) IN(1,2,4,8)
	AND digits(l.result2) IN(1,2);
	/*Finding the last obs_group_id inserted */
	TRUNCATE TABLE itech.obs_concept_group;
	INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
	SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
	FROM openmrs.obs
	WHERE openmrs.obs.concept_id=161473 
	GROUP BY openmrs.obs.person_id,encounter_id;
   /*Answer*/
    INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,300,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,cg.obs_id,
		CASE WHEN (digits(l.result) = 8 AND digits(l.result2) = 1) THEN 690
			WHEN (digits(l.result) = 8 AND digits(l.result2) = 2) THEN 692
	        WHEN (digits(l.result) = 1 AND digits(l.result2) = 1) THEN 694
			WHEN (digits(l.result) = 1 AND digits(l.result2) = 2) THEN 696
			WHEN (digits(l.result) = 2 AND digits(l.result2) = 1) THEN 699
			WHEN (digits(l.result) = 2 AND digits(l.result2) = 2) THEN 701
			WHEN (digits(l.result) = 4 AND digits(l.result2) = 1) THEN 1230
			WHEN (digits(l.result) = 4 AND digits(l.result2) = 2) THEN 1231
	END,l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l, itech.obs_concept_group cg 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND c.encounter_id = cg.encounter_id
	AND c.patient_id = cg.person_id
	AND l.labID = 151
	AND digits(l.result) IN(1,2,4,8)
	AND digits(l.result2) IN(1,2);
	/*Ending migration for Groupe Sanguin - ABO*/
	
	/*Migration for the concept question of CCMH*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	1017,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 187
	and (l.result <> "" AND l.result is not null AND digits(l.result) >= 0);
	 /*Migration for obsgroup of CCMH*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	SELECT DISTINCT e.patient_id,163700,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
	FROM itech.encounter c, encounter e, itech.labs l 
	WHERE e.uuid = c.encGuid and c.patientID = l.patientID and c.seqNum = l.seqNum and 
	c.sitecode = l.sitecode and DATE(e.encounter_datetime) = DATE_FORMAT(concat(l.visitDateYy,'-',l.visitDateMm,'-',l.visitDateDd),"%Y-%m-%d") AND 
	l.labID = 187 and (l.result <> "" AND l.result is not null AND digits(l.result) >= 0);
	/*Finding the last obs_group_id inserted */
	TRUNCATE TABLE itech.obs_concept_group;
	INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
	SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
	FROM openmrs.obs
	WHERE openmrs.obs.concept_id=163700 
	GROUP BY openmrs.obs.person_id,encounter_id;
   /*Answer*/
    INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1017,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,cg.obs_id,digits(l.result) as resultat,l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l, itech.obs_concept_group cg 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND c.encounter_id = cg.encounter_id
	AND c.patient_id = cg.person_id
	AND l.labID = 187
	AND (l.result <> "" AND l.result is not null AND digits(l.result) >= 0);
	/*END CCMH TEST*/
	
	/*Starting migration for VGM (have concept group)*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	851,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 190;
	 /*Migration for obsgroup*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	SELECT DISTINCT e.patient_id,163700,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
	FROM itech.encounter c, encounter e, itech.labs l 
	WHERE e.uuid = c.encGuid and c.patientID = l.patientID and c.seqNum = l.seqNum and 
	c.sitecode = l.sitecode and DATE(e.encounter_datetime) = DATE_FORMAT(concat(l.visitDateYy,'-',l.visitDateMm,'-',l.visitDateDd),"%Y-%m-%d") AND 
	l.labID = 190 and (l.result <> "" AND l.result is not null AND digits(l.result) >= 0);
	/*Finding the last obs_group_id inserted */
	TRUNCATE TABLE itech.obs_concept_group;
	INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
	SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
	FROM openmrs.obs
	WHERE openmrs.obs.concept_id=163700
	GROUP BY openmrs.obs.person_id,encounter_id;
   /*Answer*/
    INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,851,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,cg.obs_id,digits(l.result) as resultat,l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l, itech.obs_concept_group cg 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND c.encounter_id = cg.encounter_id
	AND c.patient_id = cg.person_id
	AND l.labID = 190
	AND (l.result <> "" AND l.result is not null AND digits(l.result) >= 0);
	
	/*Ending migration for VGM*/
	/*Start migration for Sodium (have concept group)*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	1132,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 152;
	 /*Migration for obsgroup*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	SELECT DISTINCT e.patient_id,5473,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
	FROM itech.encounter c, encounter e, itech.labs l 
	WHERE e.uuid = c.encGuid and c.patientID = l.patientID and c.seqNum = l.seqNum and 
	c.sitecode = l.sitecode and DATE(e.encounter_datetime) = DATE_FORMAT(concat(l.visitDateYy,'-',l.visitDateMm,'-',l.visitDateDd),"%Y-%m-%d") AND 
	l.labID = 152 and (l.result <> "" AND l.result is not null AND digits(l.result) >= 0)
	AND digits(l.result2) = 1;
	/*Finding the last obs_group_id inserted */
	TRUNCATE TABLE itech.obs_concept_group;
	INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
	SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
	FROM openmrs.obs
	WHERE openmrs.obs.concept_id = 5473
	GROUP BY openmrs.obs.person_id,encounter_id;
   /*Answer*/
    INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1132,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,cg.obs_id,digits(l.result) as resultat,l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l, itech.obs_concept_group cg 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND c.encounter_id = cg.encounter_id
	AND c.patient_id = cg.person_id
	AND l.labID = 152
	AND (l.result <> "" AND l.result is not null AND digits(l.result) >= 0)
	AND digits(l.result2) = 1;
	/*End migration for Sodium*/
	/*Start migration for Potassium (have concept group)*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	1133,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 153
	AND (l.result <> "" AND l.result is not null AND digits(l.result) >= 0)
	AND digits(l.result2) = 1;
	 /*Migration for obsgroup*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	SELECT DISTINCT e.patient_id,5473,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
	FROM itech.encounter c, encounter e, itech.labs l 
	WHERE e.uuid = c.encGuid and c.patientID = l.patientID and c.seqNum = l.seqNum and 
	c.sitecode = l.sitecode and DATE(e.encounter_datetime) = DATE_FORMAT(concat(l.visitDateYy,'-',l.visitDateMm,'-',l.visitDateDd),"%Y-%m-%d") AND 
	l.labID = 153 and (l.result <> "" AND l.result is not null AND digits(l.result) >= 0)
	AND digits(l.result2) = 1;
	/*Finding the last obs_group_id inserted */
	TRUNCATE TABLE itech.obs_concept_group;
	INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
	SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
	FROM openmrs.obs
	WHERE openmrs.obs.concept_id=5473
	GROUP BY openmrs.obs.person_id,encounter_id;
   /*Answer*/
    INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1133,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,cg.obs_id,digits(l.result) as resultat,l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l, itech.obs_concept_group cg 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND c.encounter_id = cg.encounter_id
	AND c.patient_id = cg.person_id
	AND l.labID = 153
	AND (l.result <> "" AND l.result is not null AND digits(l.result) >= 0)
	AND digits(l.result2) = 1;
	/*End migration for Potassium*/
	/*Starting migration Chlore (have concept group)*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	1134,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 154
	AND (l.result <> "" AND l.result is not null AND digits(l.result) >= 0)
	AND digits(l.result2) = 1;
	 /*Migration for obsgroup*/
	INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
	SELECT DISTINCT e.patient_id,159645,e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
	FROM itech.encounter c, encounter e, itech.labs l 
	WHERE e.uuid = c.encGuid and c.patientID = l.patientID and c.seqNum = l.seqNum and 
	c.sitecode = l.sitecode and DATE(e.encounter_datetime) = DATE_FORMAT(concat(l.visitDateYy,'-',l.visitDateMm,'-',l.visitDateDd),"%Y-%m-%d") AND 
	l.labID = 154 and (l.result <> "" AND l.result is not null AND digits(l.result) >= 0)
	AND digits(l.result2) = 1;
	/*Finding the last obs_group_id inserted */
	TRUNCATE TABLE itech.obs_concept_group;
	INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
	SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
	FROM openmrs.obs
	WHERE openmrs.obs.concept_id=159645
	GROUP BY openmrs.obs.person_id,encounter_id;
   /*Answer*/
    INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1134,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,cg.obs_id,digits(l.result) as resultat,l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l, itech.obs_concept_group cg 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND c.encounter_id = cg.encounter_id
	AND c.patient_id = cg.person_id
	AND l.labID = 154
	AND (l.result <> "" AND l.result is not null AND digits(l.result) >= 0)
	AND l.result2 = 1;
	/*End migration Chlore*/
		/*Start migration for CRP*/
		INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,1271,c.encounter_id,e.createDate,c.location_id,
	161500,1,e.createDate,
	UUID()
	from encounter c, itech.encounter e, itech.labs l 
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 183
	AND (l.result <> "" AND l.result is not null AND digits(l.result) >= 0);
   /*Answer*/
    INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_numeric,comments,
	creator,date_created,uuid)
	SELECT DISTINCT c.patient_id,161500,c.encounter_id,
	ifnull(formatDate(l.resultDateYy,l.resultDateMm,l.resultDateDd),e.createDate) as obs_datetime,c.location_id,digits(l.result) as resultat,l.resultRemarks,1,e.createDate, UUID()
	from encounter c, itech.encounter e, itech.labs l
	WHERE c.uuid = e.encGuid and 
	e.patientID = l.patientID and e.siteCode = l.siteCode 
	and concat(e.visitdateYy,'-',e.visitDateMm,'-',e.visitDateDd) = 
	concat(l.visitdateYy,'-',l.visitDateMm,'-',l.visitDateDd) 
	and e.seqNum = l.seqNum
	AND l.labID = 183
	AND (l.result <> "" AND l.result is not null AND digits(l.result) >= 0);
		/*End migration for CRP*/
	
/*Ending migration for labs data*/
	
 END$$
DELIMITER ;