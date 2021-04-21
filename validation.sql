drop procedure if exists validation;

DELIMITER $$ 
CREATE PROCEDURE validation()
BEGIN

select count(distinct patient_id) as patientOpenmrs from openmrs.patient;
select count(distinct patientID) as patientIsante  from itech.patient where patStatus<255;


select ec.frName as formIsante,count(e.encounter_id) as form 
from itech.encounter e ,itech.encTypeLookup ec
where e.encounterType=ec.encounterType group by 1;


select ec.name as formOpenmrs,count(e.encounter_id) as form 
from openmrs.encounter e ,openmrs.encounter_type ec
where e.encounter_type=ec.encounter_type_id group by 1;

select count(*) as visitOpenmrs from openmrs.visit;

select count(distinct patientID) as patient,count (visitDate) as visitIsante from 
(select distinct patientID,visitDate from itech.encounter) A group by 1;
/* drugs */

select count(distinct patientId) as patient,count(distinct drugID) as drugIsante from itech.prescriptions;

select count(distinct e.patient_id) as patient,
count(concept_id) as drugOpenmrs from openmrs.obs o, openmrs.encounter e 
where o.encounter_id=e.encounter_id and 
o.concept_id='1282' and 
e.encounter_type in 
(select encounter_type_id 
  from encounter_type 
  where uuid in ('10d73929-54b6-4d18-a647-8b7316bc1ae3','a9392241-109f-4d67-885b-57cc4b8c638f'));

/* labs */
select count(distinct patientId) as patient,count(labID) as labIsante from itech.labs;

select count(distinct e.patient_id) as patient,
count(concept_id) as lapOpenmrs from openmrs.obs o, openmrs.encounter e 
where o.encounter_id=e.encounter_id and 
o.concept_id='1271' and 
e.encounter_type in 
(select encounter_type_id 
  from openmrs.encounter_type 
  where uuid in ('f037e97b-471e-4898-a07c-b8e169e0ddc4'));

end;