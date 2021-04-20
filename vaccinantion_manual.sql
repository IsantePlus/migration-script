/*insert encounter for vaccination*/

insert into encTypeLookup(encounterType,frName,enName,newestFormVersion)
value(35,'vaccination','vaccination',0);



/*  vaccination VIH */
delete from itech.encounter where encounterType=35;

insert into itech.encounter(siteCode,patientID,visitDateDd,visitDateMm,visitDateYy,lastModified,encounterType,seqnum,encStatus,dbSite,formAuthor,creator,createDate,visitDate,encGuid)
select siteCode,patientID,day(visitDate),month(visitDate),DATE_FORMAT(visitdate,'%y'),visitDate,35,0,0,dbSite,'admin','admin',visitDate,visitDate,uuid()
from 
(select siteCode,i.dbSite,i.patientID,
min(date_format(date(concat(visitDateYy,'-',visitDateMm,'-',visitDateDd)),'%y-%m-%d')) as visitDate
from itech.immunizations i,itech.patient p 
where p.patientID=i.patientID
group by 1,2,3) it;

/*  vaccination soins de sante primaire */
insert into itech.encounter(siteCode,patientID,visitDateDd,visitDateMm,visitDateYy,lastModified,encounterType,seqnum,encStatus,dbSite,formAuthor,creator,createDate,visitDate,encGuid)
select siteCode,patientID,day(visitDate),month(visitDate),DATE_FORMAT(visitdate,'%y'),visitDate,35,0,0,dbSite,'admin','admin',visitDate,visitDate,uuid()
from( select e.siteCode,e.patientID,e.dbSite,min(e.visitDate) as visitDate	   
 from itech.encounter e,itech.obs o 
where o.encounter_id=e.encounter_id AND
o.concept_id in (70666,70693,70694,70695,70696,70697,70667,70668,70669,70670,70671,70673,70674,70675,70676,70677,71248,71249,71250,71251,71252,71412,71413,71414,71415,71416,71616,71617,71618,71610,71611,70683,70684,70685,70686,70687,71635,71636,71637,71638,71640,70688,70689,70690,70691,70692,71612,71613,71614,71615,71621,71622,71619,71620,71623,71624)
group by 1,2,3) it;


update itech.obs o, itech.encounter e 
set o.encounter_id=e.encounter_id 
where o.person_id=right(e.patientID,length(e.patientID)-5) and 
      e.encounterType=35 and
	  o.concept_id in (70666,70693,70694,70695,70696,70697,70667,
	                   70668,70669,70670,70671,70673,70674,70675,
					   70676,70677,71248,71249,71250,71251,71252,
					   71412,71413,71414,71415,71416,71616,71617,
					   71618,71610,71611,70683,70684,70685,70686,
					   70687,71635,71636,71637,71638,71640,70688,
					   70689,70690,70691,70692,71612,71613,71614,
					   71615,71621,71622,71619,71620,71623,71624);


INSERT INTO itech.typeToForm (encounterType, uuid) VALUES 
( 35 , '191bbeb5-e0ab-49bb-8df8-9346f5de8f61' );

UPDATE itech.typeToForm i, form t SET i.form_id = t.form_id,i.encounterTypeOpenmrs=t.encounter_type where i.uuid = t.uuid; 
 
 
 /* encounter migration data */ 
INSERT INTO encounter(encounter_type,patient_id,location_id,form_id,visit_id, encounter_datetime,creator,date_created,date_changed,uuid,voided)
SELECT distinct f.encounterTypeOpenmrs, p.person_id, v.location_id, f.form_id, v.visit_id,
date_format(date(concat(case when length(e.visitDateYy)=2 then concat('20',e.visitDateYy) else e.visitDateYy end,'-',e.visitDateMm,'-',e.visitDateDd)),'%y-%m-%d'),1,e.createDate,e.lastModified,e.encGuid,
case when e.encStatus>=255 then 1 else 0 end as voided
FROM itech.encounter e, person p, itech.patient j, visit v, itech.typeToForm f
WHERE p.uuid = j.patGuid and 
e.patientID = j.patientID AND 
v.patient_id = p.person_id AND 
v.date_started = date(concat(case when length(e.visitDateYy)=2 then concat('20',e.visitDateYy) else e.visitDateYy end,'-',e.visitDateMm,'-',e.visitDateDd)) AND 
e.encounterType=35 AND
e.encounterType = f.encounterType 
ON DUPLICATE KEY UPDATE
date_changed=VALUES(date_changed);


/*migration for form history */
insert into isanteplus_form_history(visit_id,encounter_id,patient_id,creator,date_created,date_changed,uuid)
select visit_id,encounter_id,e.patient_id,creator,date_format(date(date_created),'%y-%m-%d'),date_format(date(date_changed),'%y-%m-%d'), uuid() from encounter e where encounter_type not in (select e.encounter_type_id from encounter_type e where uuid='873f968a-73a8-4f9c-ac78-9f4778b751b6')
ON DUPLICATE KEY UPDATE
visit_id=values(visit_id),
encounter_id=values(encounter_id),
creator=values(creator),
date_created=values(date_created),
date_changed=values(date_changed);