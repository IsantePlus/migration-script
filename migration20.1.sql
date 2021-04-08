drop procedure if exists migration20_1;
DELIMITER $$ 

CREATE PROCEDURE migration20_1()
BEGIN
  DECLARE done INT DEFAULT FALSE;
 
SET FOREIGN_KEY_CHECKS=0;

/* Date début des ARV dans l’établissement de référence*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159599,e.encounter_id,e.encounter_datetime,e.location_id,
ifnull(o.value_datetime,value_text) as value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs o 
WHERE e.uuid = c.encGuid and c.encounter_id=o.encounter_id  
and ifnull(o.value_datetime,value_text) is not null
and c.sitecode = o.location_id and o.concept_id=163606 ;

select 1 as migration1;
/*DATA Migration population cle */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='b2726cc7-df4b-463c-919d-1c7a600fef87') as concept_id,
e.encounter_id,e.encounter_datetime,e.location_id,
case when o.concept_id=163593 then 160578
     when o.concept_id=163594 then 160579
	 when o.concept_id=163595 then 162277
	 when o.concept_id=163596 then 124275
	 when o.concept_id=163597 then 105
	 else null end as value_coded,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs o 
WHERE e.uuid = c.encGuid and c.encounter_id=o.encounter_id  
and o.value_boolean=1 and c.sitecode = o.location_id 
and o.concept_id in (163593,163594,163595,163596,163597);

select 2 as migration2;

/* Date du début de traitement TB */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1113,e.encounter_id,e.encounter_datetime,e.location_id,
ifnull(o.value_datetime,value_text) as value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs o 
WHERE e.uuid = c.encGuid and c.encounter_id=o.encounter_id  
and ifnull(o.value_datetime,value_text) is not null
and c.sitecode = o.location_id and o.concept_id=163607 ;

select 3 as migration3;

/*	  (163680,0,'adenopathies','adenopathies','Adénopathies',10,13,0,1,'2020-07-25'),
	  (163681,0,'douleurThoracique','douleurThoracique','Douleur thoracique',10,13,0,1,'2020-07-25'),
	  (163682,0,'fievreVesperale','fievreVesperale','Fièvre vespérale',10,13,0,1,'2020-07-25'),
	  (163683,0,'perteAppetit','perteAppetit','Perte d’appétit',10,13,0,1,'2020-07-25');
*/
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
		
 /*MIGRATION FOR GROSSESSE et ALLAITEMENT */
/*MIGRATION FOR GROSSESSE OUI NON */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1434,e.encounter_id,e.encounter_datetime,e.location_id,
case when o.value_numeric=1 then 1
     when o.value_numeric=2 then 2
	 else null end as value_coded,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs o 
WHERE e.uuid = c.encGuid and c.encounter_id=o.encounter_id  
and o.value_numeric in (1,2)
and c.sitecode = o.location_id and o.concept_id=163590 ;

select 4 as migration4;	

/*MIGRATION FOR GROSSESSE startDate */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='ef1d8d6f-3083-4479-900d-274285326424') as concept_id,e.encounter_id,e.encounter_datetime,e.location_id,
ifnull(o.value_datetime,value_text) as value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs o 
WHERE e.uuid = c.encGuid and c.encounter_id=o.encounter_id  
and ifnull(o.value_datetime,value_text) is not null
and c.sitecode = o.location_id and o.concept_id=163591 ;

select 5 as migration5;	

/*MIGRATION FOR GROSSESSE EndDate */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='33940458-bb56-4743-b791-acdbe4c5f75c') as concept_id,e.encounter_id,e.encounter_datetime,e.location_id,
ifnull(o.value_datetime,value_text) as value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs o 
WHERE e.uuid = c.encGuid and c.encounter_id=o.encounter_id  
and ifnull(o.value_datetime,value_text) is not null
and c.sitecode = o.location_id and o.concept_id=163592 ;

select 6 as migration6;	



/*MIGRATION FOR ALLAITEMENT OUI NON */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5632,e.encounter_id,e.encounter_datetime,e.location_id,
case when o.value_numeric=1 then 1065
     when o.value_numeric=2 then 1066
	 else null end as value_coded,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs o 
WHERE e.uuid = c.encGuid and c.encounter_id=o.encounter_id  
and o.value_numeric in (1,2)
and c.sitecode = o.location_id and o.concept_id=163620 ;

select 4 as migration4;	

/*MIGRATION FOR ALLAITEMENT startDate */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='7e0f24aa-4f8e-42d0-8649-282bc3c867e3') as concept_id,e.encounter_id,e.encounter_datetime,e.location_id,
ifnull(o.value_datetime,value_text) as value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs o 
WHERE e.uuid = c.encGuid and c.encounter_id=o.encounter_id  
and ifnull(o.value_datetime,value_text) is not null
and c.sitecode = o.location_id and o.concept_id=163621 ;

select 5 as migration5;	

/*MIGRATION FOR ALLAITEMENT EndDate */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='b128ef02-7d8f-43f3-8ee5-592925627813') as concept_id,e.encounter_id,e.encounter_datetime,e.location_id,
ifnull(o.value_datetime,value_text) as value_datetime,1,e.date_created,UUID()
FROM itech.encounter c, encounter e, itech.obs o 
WHERE e.uuid = c.encGuid and c.encounter_id=o.encounter_id  
and ifnull(o.value_datetime,value_text) is not null
and c.sitecode = o.location_id and o.concept_id=163622 ;




 (163624,0,'surveillanceTbDatemois0','surveillanceTbDatemois0','Date surveillance TB mois 0',8,5,0,1,'2020-07-25'),
	  (163625,0,'bacilloscopiemois0','bacilloscopiemois0','bacilloscopie mois 0',1,5,0,1,'2020-07-25'),
	  (163626,0,'geneXpertBkmois0','geneXpertBkmois0','geneXpert Bk mois 0',1,5,0,1,'2020-07-25'),
	  (163627,0,'geneXpertRifmois0','geneXpertRifmois0','geneXpert RIF mois 0',1,5,0,1,'2020-07-25'),
	  (163628,0,'culturemois0','culturemois0','Culture mois 0',1,5,0,1,'2020-07-25'),
	  (163629,0,'dstmois0','dstmois0','DST mois 0',1,5,0,1,'2020-07-25'),
	  (163630,0,'poidsmois0','poidsmois0','Poids mois 0',1,5,0,1,'2020-07-25'),		

/*MIGRATION FOR Surveillance TB */
	  /*migration for mois 1*/
	  /*concept group */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='c2c7db51-d427-4c21-9655-ae9ee604c81c'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid 
and c.encounter_id=o.encounter_id 
and o.concept_id in (163624,163625,163626,163627,163628,163629,163630);

delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='c2c7db51-d427-4c21-9655-ae9ee604c81c'
GROUP BY openmrs.obs.person_id,encounter_id;
	
/*migration of the date*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159964,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
ifnull(o.value_datetime,value_text) as value_datetime,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163624 
and ifnull(o.value_datetime,value_text) is not null 
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;		

/*migration of bacilloscopie*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,307,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 664
     when o.value_numeric=2 then 1362
	 when o.value_numeric=4 then 1363
	 when o.value_numeric=8 then 1364
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163625 
and o.value_numeric in (1,2,4,8)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

/*migration of geneXpertBk*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='4cbdc90a-e007-4a48-af54-5dd204edadd9') as concept_id,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 1301
     when o.value_numeric=2 then 1302
	 when o.value_numeric=4 then 1138
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163626 
and o.value_numeric in (1,2,4)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 7 as migration7;	

/*migration of geneXpertRif*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='4cbdc90a-e007-4a48-af54-5dd204edadd9') as concept_id,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 162204
     when o.value_numeric=2 then 162203
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163627 
and o.value_numeric in (1,2)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 8 as migration8;	

/*migration of culture*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159982,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then (select concept_id from concept where uuid='36d6616b-8c7c-4768-9f38-2be4b704fccd')
     when o.value_numeric=2 then (select concept_id from concept where uuid='f4ee3bcc-947c-4390-9190-a335c2cd5868')
	 when o.value_numeric=4 then 664
	 when o.value_numeric=8 then 160008
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163628 
and o.value_numeric in (1,2,4,8)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 9 as migration9;	

/*migration of dst*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159984,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 162204
     when o.value_numeric=2 then 162203
	 when o.value_numeric=4 then 1138
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163629 
and o.value_numeric in (1,2,4)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 10 as migration10;

/*migration of poids*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5089,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
o.value_numeric,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163630 
and o.value_numeric>0  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 11 as migration11;

/* End of group */


 /*migration for mois 2*/
	  /*concept group */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='b05762eb-b8f5-4af2-8105-cc68a6dc9d3b'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid 
and c.encounter_id=o.encounter_id 
and o.concept_id in (163631,163632,163633,163634,163635,163636,163637);
 
delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='b05762eb-b8f5-4af2-8105-cc68a6dc9d3b'
GROUP BY openmrs.obs.person_id,encounter_id;
	
/*migration of the date*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159964,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
ifnull(o.value_datetime,value_text) as value_datetime,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163631 
and ifnull(o.value_datetime,value_text) is not null 
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;		

/*migration of bacilloscopie*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,307,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 664
     when o.value_numeric=2 then 1362
	 when o.value_numeric=4 then 1363
	 when o.value_numeric=8 then 1364
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163632 
and o.value_numeric in (1,2,4,8)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

/*migration of geneXpertBk*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='4cbdc90a-e007-4a48-af54-5dd204edadd9') as concept_id,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 1301
     when o.value_numeric=2 then 1302
	 when o.value_numeric=4 then 1138
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163633 
and o.value_numeric in (1,2,4)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 7 as migration7;	

/*migration of geneXpertRif*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='4cbdc90a-e007-4a48-af54-5dd204edadd9') as concept_id,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 162204
     when o.value_numeric=2 then 162203
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163634 
and o.value_numeric in (1,2)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 8 as migration8;	

/*migration of culture*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159982,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then (select concept_id from concept where uuid='36d6616b-8c7c-4768-9f38-2be4b704fccd')
     when o.value_numeric=2 then (select concept_id from concept where uuid='f4ee3bcc-947c-4390-9190-a335c2cd5868')
	 when o.value_numeric=4 then 664
	 when o.value_numeric=8 then 160008
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163635 
and o.value_numeric in (1,2,4,8)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 9 as migration9;	

/*migration of dst*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159984,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 162204
     when o.value_numeric=2 then 162203
	 when o.value_numeric=4 then 1138
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163636 
and o.value_numeric in (1,2,4)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 10 as migration10;

/*migration of poids*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5089,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
o.value_numeric,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163637 
and o.value_numeric>0  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 11 as migration11;

/* End of group */

 /*migration for mois 3*/
	  /*concept group */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='be7a27bb-2dcd-4bff-b696-ccdbbd2d3192'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid 
and c.encounter_id=o.encounter_id 
and o.concept_id in (163638,163639,163640,163641,163642,163643,163644);
 
delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='be7a27bb-2dcd-4bff-b696-ccdbbd2d3192'
GROUP BY openmrs.obs.person_id,encounter_id;
	
/*migration of the date*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159964,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
ifnull(o.value_datetime,value_text) as value_datetime,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163638 
and ifnull(o.value_datetime,value_text) is not null 
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;		

/*migration of bacilloscopie*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,307,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 664
     when o.value_numeric=2 then 1362
	 when o.value_numeric=4 then 1363
	 when o.value_numeric=8 then 1364
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163639 
and o.value_numeric in (1,2,4,8)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

/*migration of geneXpertBk*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='4cbdc90a-e007-4a48-af54-5dd204edadd9') as concept_id,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 1301
     when o.value_numeric=2 then 1302
	 when o.value_numeric=4 then 1138
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163640 
and o.value_numeric in (1,2,4)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 7 as migration7;	

/*migration of geneXpertRif*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='4cbdc90a-e007-4a48-af54-5dd204edadd9') as concept_id,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 162204
     when o.value_numeric=2 then 162203
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163641 
and o.value_numeric in (1,2)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 8 as migration8;	

/*migration of culture*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159982,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then (select concept_id from concept where uuid='36d6616b-8c7c-4768-9f38-2be4b704fccd')
     when o.value_numeric=2 then (select concept_id from concept where uuid='f4ee3bcc-947c-4390-9190-a335c2cd5868')
	 when o.value_numeric=4 then 664
	 when o.value_numeric=8 then 160008
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163642 
and o.value_numeric in (1,2,4,8)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 9 as migration9;	

/*migration of dst*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159984,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 162204
     when o.value_numeric=2 then 162203
	 when o.value_numeric=4 then 1138
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163643 
and o.value_numeric in (1,2,4)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 10 as migration10;

/*migration of poids*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5089,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
o.value_numeric,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163644 
and o.value_numeric>0  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 11 as migration11;

/* End of group */




 /*migration for mois 4*/
	  /*concept group */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='fdd9d953-004a-4e9a-ab93-9afaa0e090fa'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid 
and c.encounter_id=o.encounter_id 
and o.concept_id in (163645,163646,163647,163648,163649,163650,163651);
 
delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='fdd9d953-004a-4e9a-ab93-9afaa0e090fa'
GROUP BY openmrs.obs.person_id,encounter_id;
	
/*migration of the date*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159964,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
ifnull(o.value_datetime,value_text) as value_datetime,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163645 
and ifnull(o.value_datetime,value_text) is not null 
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;		

/*migration of bacilloscopie*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,307,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 664
     when o.value_numeric=2 then 1362
	 when o.value_numeric=4 then 1363
	 when o.value_numeric=8 then 1364
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163646 
and o.value_numeric in (1,2,4,8)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

/*migration of geneXpertBk*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='4cbdc90a-e007-4a48-af54-5dd204edadd9') as concept_id,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 1301
     when o.value_numeric=2 then 1302
	 when o.value_numeric=4 then 1138
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163647 
and o.value_numeric in (1,2,4)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 7 as migration7;	

/*migration of geneXpertRif*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='4cbdc90a-e007-4a48-af54-5dd204edadd9') as concept_id,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 162204
     when o.value_numeric=2 then 162203
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163648 
and o.value_numeric in (1,2)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 8 as migration8;	

/*migration of culture*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159982,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then (select concept_id from concept where uuid='36d6616b-8c7c-4768-9f38-2be4b704fccd')
     when o.value_numeric=2 then (select concept_id from concept where uuid='f4ee3bcc-947c-4390-9190-a335c2cd5868')
	 when o.value_numeric=4 then 664
	 when o.value_numeric=8 then 160008
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163649 
and o.value_numeric in (1,2,4,8)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 9 as migration9;	

/*migration of dst*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159984,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 162204
     when o.value_numeric=2 then 162203
	 when o.value_numeric=4 then 1138
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163650 
and o.value_numeric in (1,2,4)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 10 as migration10;

/*migration of poids*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5089,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
o.value_numeric,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163651 
and o.value_numeric>0  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 11 as migration11;

/* End of group */



 /*migration for mois 5*/
	  /*concept group */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='dc12da69-937e-4cfc-afed-a2f07b44eff4'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid 
and c.encounter_id=o.encounter_id 
and o.concept_id in (163652,163653,163654,163655,163656,163657,163658);
 
delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='dc12da69-937e-4cfc-afed-a2f07b44eff4'
GROUP BY openmrs.obs.person_id,encounter_id;
	
/*migration of the date*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159964,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
ifnull(o.value_datetime,value_text) as value_datetime,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163652 
and ifnull(o.value_datetime,value_text) is not null 
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;		

/*migration of bacilloscopie*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,307,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 664
     when o.value_numeric=2 then 1362
	 when o.value_numeric=4 then 1363
	 when o.value_numeric=8 then 1364
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163653 
and o.value_numeric in (1,2,4,8)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

/*migration of geneXpertBk*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='4cbdc90a-e007-4a48-af54-5dd204edadd9') as concept_id,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 1301
     when o.value_numeric=2 then 1302
	 when o.value_numeric=4 then 1138
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163654 
and o.value_numeric in (1,2,4)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 7 as migration7;	

/*migration of geneXpertRif*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='4cbdc90a-e007-4a48-af54-5dd204edadd9') as concept_id,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 162204
     when o.value_numeric=2 then 162203
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163655 
and o.value_numeric in (1,2)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 8 as migration8;	

/*migration of culture*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159982,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then (select concept_id from concept where uuid='36d6616b-8c7c-4768-9f38-2be4b704fccd')
     when o.value_numeric=2 then (select concept_id from concept where uuid='f4ee3bcc-947c-4390-9190-a335c2cd5868')
	 when o.value_numeric=4 then 664
	 when o.value_numeric=8 then 160008
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163656 
and o.value_numeric in (1,2,4,8)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 9 as migration9;	

/*migration of dst*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159984,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 162204
     when o.value_numeric=2 then 162203
	 when o.value_numeric=4 then 1138
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163657 
and o.value_numeric in (1,2,4)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 10 as migration10;

/*migration of poids*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5089,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
o.value_numeric,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163658 
and o.value_numeric>0  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 11 as migration11;

/* End of group */


 /*migration for mois 6*/
	  /*concept group */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='224546bb-03da-4793-9ef6-3d42adc5b353'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid 
and c.encounter_id=o.encounter_id 
and o.concept_id in (163659,163660,163661,163662,163663,163664,163665);
 
delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='224546bb-03da-4793-9ef6-3d42adc5b353'
GROUP BY openmrs.obs.person_id,encounter_id;
	
/*migration of the date*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159964,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
ifnull(o.value_datetime,value_text) as value_datetime,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163659 
and ifnull(o.value_datetime,value_text) is not null 
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;		

/*migration of bacilloscopie*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,307,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 664
     when o.value_numeric=2 then 1362
	 when o.value_numeric=4 then 1363
	 when o.value_numeric=8 then 1364
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163660 
and o.value_numeric in (1,2,4,8)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

/*migration of geneXpertBk*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='4cbdc90a-e007-4a48-af54-5dd204edadd9') as concept_id,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 1301
     when o.value_numeric=2 then 1302
	 when o.value_numeric=4 then 1138
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163661 
and o.value_numeric in (1,2,4)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 7 as migration7;	

/*migration of geneXpertRif*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='4cbdc90a-e007-4a48-af54-5dd204edadd9') as concept_id,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 162204
     when o.value_numeric=2 then 162203
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163662 
and o.value_numeric in (1,2)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 8 as migration8;	

/*migration of culture*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159982,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then (select concept_id from concept where uuid='36d6616b-8c7c-4768-9f38-2be4b704fccd')
     when o.value_numeric=2 then (select concept_id from concept where uuid='f4ee3bcc-947c-4390-9190-a335c2cd5868')
	 when o.value_numeric=4 then 664
	 when o.value_numeric=8 then 160008
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163663 
and o.value_numeric in (1,2,4,8)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 9 as migration9;	

/*migration of dst*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159984,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 162204
     when o.value_numeric=2 then 162203
	 when o.value_numeric=4 then 1138
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163664 
and o.value_numeric in (1,2,4)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 10 as migration10;

/*migration of poids*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5089,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
o.value_numeric,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163665 
and o.value_numeric>0  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 11 as migration11;

/* End of group */


 /*migration for mois 7 */
	  /*concept group */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='67f6a83d-5aa2-4da5-950c-833dadfa8916'),e.encounter_id,e.encounter_datetime,e.location_id,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid 
and c.encounter_id=o.encounter_id 
and o.concept_id in (163666,163667,163668,163669,163670,163671,163672);
 
delete from itech.obs_concept_group where 1;		
INSERT INTO itech.obs_concept_group (obs_id,person_id,concept_id,encounter_id)
SELECT MAX(openmrs.obs.obs_id) as obs_id,openmrs.obs.person_id,openmrs.obs.concept_id,openmrs.obs.encounter_id
FROM openmrs.obs,openmrs.concept c
WHERE openmrs.obs.concept_id=c.concept_id and c.uuid='67f6a83d-5aa2-4da5-950c-833dadfa8916'
GROUP BY openmrs.obs.person_id,encounter_id;
	
/*migration of the date*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_datetime,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159964,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
ifnull(o.value_datetime,value_text) as value_datetime,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163666 
and ifnull(o.value_datetime,value_text) is not null 
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;		

/*migration of bacilloscopie*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,307,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 664
     when o.value_numeric=2 then 1362
	 when o.value_numeric=4 then 1363
	 when o.value_numeric=8 then 1364
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163667 
and o.value_numeric in (1,2,4,8)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

/*migration of geneXpertBk*/
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='4cbdc90a-e007-4a48-af54-5dd204edadd9') as concept_id,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 1301
     when o.value_numeric=2 then 1302
	 when o.value_numeric=4 then 1138
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163668 
and o.value_numeric in (1,2,4)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 7 as migration7;	

/*migration of geneXpertRif*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,(select concept_id from concept where uuid='4cbdc90a-e007-4a48-af54-5dd204edadd9') as concept_id,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 162204
     when o.value_numeric=2 then 162203
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163669 
and o.value_numeric in (1,2)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 8 as migration8;	

/*migration of culture*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159982,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then (select concept_id from concept where uuid='36d6616b-8c7c-4768-9f38-2be4b704fccd')
     when o.value_numeric=2 then (select concept_id from concept where uuid='f4ee3bcc-947c-4390-9190-a335c2cd5868')
	 when o.value_numeric=4 then 664
	 when o.value_numeric=8 then 160008
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163670 
and o.value_numeric in (1,2,4,8)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 9 as migration9;	

/*migration of dst*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,159984,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
case when o.value_numeric=1 then 162204
     when o.value_numeric=2 then 162203
	 when o.value_numeric=4 then 1138
	 else null end ,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163671 
and o.value_numeric in (1,2,4)  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 10 as migration10;

/*migration of poids*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,obs_group_id,value_numeric,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,5089,e.encounter_id,e.encounter_datetime,e.location_id,og.obs_id,
o.value_numeric,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o,itech.obs_concept_group og
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163672 
and o.value_numeric>0  
and og.person_id=e.patient_id and e.encounter_id=og.encounter_id;

select 11 as migration11;

/* NON ÉLIGIBILITÉ MÉDICALE AUX ARV */
/*migration of refus volontaire de prendre des ARVs*/ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1667,e.encounter_id,e.encounter_datetime,e.location_id,
127750,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163598 
and o.value_boolean=1;

select 12 as migration12;

/*migration of refus Décision médicale */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1667,e.encounter_id,e.encounter_datetime,e.location_id,
162591,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163599 
and o.value_boolean=1;

select 13 as migration13;

/*migration of Infection opportunistes (IO) */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1667,e.encounter_id,e.encounter_datetime,e.location_id,
131768,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163600 
and o.value_boolean=1;

select 13 as migration13;


/* Troubles psychiatriques */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1667,e.encounter_id,e.encounter_datetime,e.location_id,
134337,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163601 
and o.value_boolean=1;

select 14 as migration14;

/* Déni */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1667,e.encounter_id,e.encounter_datetime,e.location_id,
155891,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163602 
and o.value_boolean=1;

select 15 as migration15;

/* Maladies intercurrentes non IO */
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1667,e.encounter_id,e.encounter_datetime,e.location_id,
136766,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163603 
and o.value_boolean=1;

select 16 as migration16;

/* Autres Causes */ 
INSERT INTO obs(person_id,concept_id,encounter_id,obs_datetime,location_id,value_coded,comments,creator,date_created,uuid)
SELECT DISTINCT e.patient_id,1667,e.encounter_id,e.encounter_datetime,e.location_id,
5622,(select value_text from itech.obs t where t.encounter_id=c.encounter_id and t.concept_id=163605) as comments,1,e.date_created,UUID()
 FROM itech.encounter c, encounter e,itech.obs o
where e.uuid = c.encGuid and c.encounter_id=o.encounter_id and o.concept_id=163604 
and o.value_boolean=1;

select 17 as migration17;

END;
