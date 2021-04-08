

INSERT INTO `itech`.`clinicLookup` (`department`, `commune`, `clinic`, `category`, `type`, `siteCode`, `network`, `inCPHR`, `dbSite`, `ipAddress`, `dbVersion`, `lat`, `lng`, `oldClinicName`, `hostname`) VALUES ('Ouest', 'Delmas', 'Institut des maladies infectieuses et Santé reproductives - IMIS', 'Autre', 'privé', '11440', 'GHESKIO', '1', '0', '0', NULL, NULL, NULL, 'Institut des maladies infectieuses et Santé reproductives - IMIS', 'IMIS');

/*create encounter for disc form for all hivPositive patient*/
insert into encounter(siteCode,patientID,visitDateDd,visitDateMm,visitDateYy,lastModified,encounterType,seqNum,encStatus,formVersion,creator,createDate,lastModifier,dbSite)
select location_id,patientID,DAY(now()),MONTH(now()),RIGHT(YEAR(now()),2),now(),case when isPediatric=1 then 21 else 12 end as encounterType ,0,0,1,'admin',now(),'admin',c.dbSite from patient p, clinicLookup c  where c.siteCode=p.location_id  and p.hivPositive=1;

/* patient sur ARV */
INSERT INTO `discEnrollment` (`siteCode`, `patientID`, `visitDateDd`, `visitDateMm`, `visitDateYy`, `seqNum`, disEnrollDd,	disEnrollMm	,disEnrollYy, `clinicName`, reasonDiscTransfer	,`ending`, `reasonDiscRef`,  `everOn`, `partStop`, `dbSite`) 
select location_id,patientID,DAY(now()),MONTH(now()),RIGHT(YEAR(now()),2),0,DAY(now()),MONTH(now()),RIGHT(YEAR(now()),2),11440,1,1,2,1,1,c.dbSite from patient p, clinicLookup c  where c.siteCode=p.location_id and patientStatus in (6,8,9);

/* patient sur ARV */
INSERT INTO `discEnrollment` (`siteCode`, `patientID`, `visitDateDd`, `visitDateMm`, `visitDateYy`, `seqNum`, disEnrollDd,	disEnrollMm	,disEnrollYy, `clinicName`, reasonDiscTransfer	,`ending`, `reasonDiscRef`,  `everOn`, `partStop`, `dbSite`) 
select location_id,patientID,DAY(now()),MONTH(now()),RIGHT(YEAR(now()),2),0,DAY(now()),MONTH(now()),RIGHT(YEAR(now()),2),11440,1,0,2,2,1,c.dbSite from patient p, clinicLookup c  where c.siteCode=p.location_id and (patientStatus in (11,7,10) or (patientStatus not in (6,8,9) and hivPositive=1));


INSERT INTO `discEnrollment` (`siteCode`, `patientID`, `visitDateDd`, `visitDateMm`, `visitDateYy`, `seqNum`, disEnrollDd,	disEnrollMm	,disEnrollYy, `clinicName`, reasonDiscTransfer	,`ending`, `reasonDiscRef`,  `everOn`, `partStop`, `dbSite`) 
select location_id,patientID,DAY(now()),MONTH(now()),RIGHT(YEAR(now()),2),0,DAY(now()),MONTH(now()),RIGHT(YEAR(now()),2),11440,1,0,2,2,1,c.dbSite from patient p, clinicLookup c  where c.siteCode=p.location_id and (patientStatus is null and hivPositive=1);


8 impasse bercy ,  rue rosa canapevert , 10h 