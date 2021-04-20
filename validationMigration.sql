CREATE PROCEDURE validation_Migration()
BEGIN

  DECLARE done INT DEFAULT FALSE;
select concat ('patient openmrs:',count(distinct patient_id)) from openmrs.patient;
select concat ('patient isante:',count(distinct patientID)) from itech.patient where patStatus<255;

select 'form isante' as isanteForm;

select ec.frName,count(e.encounter_id) as form 
from itech.encounter e ,itech.encTypeLookup ec
where e.encounterType=ec.encounterType group by 1;


select 'form openmrs' as openmrsForm;

select ec.name,count(e.encounter_id) as form 
from openmrs.encounter e ,openmrs.encounter_type ec
where e.encounter_type=ec.encounter_type_id group by 1;


select 'openmrs visit' as openmrsVisit;
select count(*) from openmrs.visit;


select 'isante visit' as isanteVisit;
select count(distinct patientID) as patient,count(distinct visitDate) as visit from itech.encounter;


/* drugs */

select 'drug isante' as drug;
select count(distinct patientId),count(drugID) from itech.prescritions;

select 'drug openmrs' as drug;
select count(distinct e.patient_id),
count(distinct concept_id) from openmrs.obs o, openmrs.encounter e 
where o.encounter_id=e.encounter_id and 
o.concept_id='1282' and 
e.encounter_type in 
(select encouter_type_id 
  from encounter_type 
  where uuid in ('10d73929-54b6-4d18-a647-8b7316bc1ae3','a9392241-109f-4d67-885b-57cc4b8c638f'));

/* labs */
select 'lab isante' as drug;
select count(distinct patientId),count(labID) from itech.labs;

select 'lab openmrs' as drug;
select count(distinct e.patient_id) as patient,
count(concept_id) from openmrs.obs o, openmrs.encounter e 
where o.encounter_id=e.encounter_id and 
o.concept_id='1271' and 
e.encounter_type in 
(select encounter_type_id 
  from openmrs.encounter_type 
  where uuid in ('f037e97b-471e-4898-a07c-b8e169e0ddc4'));

end;