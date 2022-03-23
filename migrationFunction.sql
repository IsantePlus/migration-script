drop function if exists IsNumeric;
CREATE FUNCTION IsNumeric (val varchar(255)) RETURNS tinyint 
 RETURN val REGEXP '^(-|\\+){0,1}([0-9]+\\.[0-9]*|[0-9]*\\.[0-9]+|[0-9]+)$';

DROP FUNCTION if exists FindNumericValue;
DELIMITER $$
 
CREATE FUNCTION FindNumericValue(val VARCHAR(255)) RETURNS VARCHAR(255)
    DETERMINISTIC
BEGIN
		DECLARE idx INT DEFAULT 0;
		IF ISNULL(val) THEN RETURN NULL; END IF;

		IF LENGTH(val) = 0 THEN RETURN ""; END IF;
 SET idx = LENGTH(val);
		WHILE idx > 0 DO
			IF IsNumeric(SUBSTRING(val,idx,1)) = 0 THEN
				SET val = REPLACE(val,SUBSTRING(val,idx,1),"");
				SET idx = LENGTH(val)+1;
			END IF;
				SET idx = idx - 1;
		END WHILE;
			RETURN val;
END
$$
DELIMITER ;

DROP FUNCTION if exists `formatDate`;
DELIMITER $$
CREATE FUNCTION `formatDate`( dateYy Varchar(10),dateMm Varchar(10),dateDd Varchar(10) ) RETURNS DATE
BEGIN

  IF (FindNumericValue(dateYy)<0 or dateYy='' or dateYy is null)
  THEN 
    RETURN null;
  END IF;
  
  IF (dateYy='00')
  THEN 
     set dateYy='2000';
  END IF;
  
  IF(length(dateYy)<=2) 
  THEN 
   set dateYy=concat('20',FindNumericValue(dateYy));
   END IF;
  
  IF(dateMm is null or dateMm='XX' or dateMm='' or dateMm>12 or dateMm<1)
  THEN 
   set dateMm='01';
   END IF;
 
  IF(dateDd is null or dateDd='XX' or dateDd='' or dateDd>31 or dateDd<1)
  THEN 
   set dateDd='01';
   END IF;
 
 IF(length(dateDd)<=2) 
  THEN 
   set dateDd=concat('0',FindNumericValue(dateDd));
   END IF;
 
 IF((dateMm='01' or dateMm='03' or dateMm='05' or dateMm='07' or dateMm='08' or dateMm='10' or dateMm='12') and dateDd>31)
 THEN 
  set dateDd='31';
  END IF;
 
  IF((dateMm='04' or dateMm='06' or dateMm='09' or dateMm='11') and dateDd>30)
 THEN 
  set dateDd='30';
  END IF;
  
 IF((dateMm='02') and mod(dateYy,4)>0 and dateDd>28)
 THEN 
  set dateDd='28';
  END IF;
  
   IF((dateMm='02') and mod(dateYy,4)=0 and dateDd>29)
 THEN 
  set dateDd='29';
  END IF;
 
  RETURN date_format(concat(trim(dateYy),'-',trim(dateMm),'-',trim(dateDd)),'%y-%m-%d');
END$$
DELIMITER ;
DROP FUNCTION if exists `digits`;
DELIMITER $$

CREATE FUNCTION `digits`( str longtext ) RETURNS char(32) CHARSET utf8
BEGIN
  DECLARE i, len SMALLINT DEFAULT 1;
  DECLARE ret VARCHAR(255) DEFAULT '';
  DECLARE c CHAR(1);
  DECLARE pos SMALLINT;
  DECLARE after_p CHAR(100);
  IF str IS NULL
  THEN 
    RETURN "0.0";
  END IF;
  SET len = CHAR_LENGTH( str );
  l:REPEAT
    BEGIN
      SET c = MID( str, i, 1 );
      IF c BETWEEN '0' AND '9' THEN 
        SET ret=CONCAT(ret,c);
      ELSEIF c = '.' OR c = ',' THEN
		IF c = '.' THEN
			SET pos=INSTR(str, '.' );
            SET after_p=MID(str,pos,pos+2);
			
			IF FindNumericValue(ret) = '' THEN
            SET ret=FindNumericValue(after_p);
			ELSE 
			 SET ret=CONCAT(FindNumericValue(ret),'.',FindNumericValue(after_p));
            END IF;
			LEAVE l;
		ELSEIF c = ',' THEN 
			SET pos=INSTR(str, ',');
            SET after_p=MID(str,pos,pos+2);
			IF FindNumericValue(ret) = '' THEN
            SET ret=FindNumericValue(after_p);
			ELSE 
			 SET ret=CONCAT(FindNumericValue(ret),'.',FindNumericValue(after_p));            
            END IF;
			LEAVE l;
		END IF;
      END IF;
      
      SET i = i + 1;
      
    END;
  UNTIL i > len END REPEAT;
  
    IF ret=""
  THEN 
    RETURN "0.0";
  END IF;
  
  RETURN ret;
END$$
DELIMITER ;