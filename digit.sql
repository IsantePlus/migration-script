DROP FUNCTION if exists `digits`;
DELIMITER $$
CREATE FUNCTION `digits`( str longtext ) RETURNS char(32) CHARSET utf8
BEGIN
  DECLARE i, len SMALLINT DEFAULT 1;
  DECLARE ret CHAR(32) DEFAULT '';
  DECLARE c CHAR(1);
  DECLARE pos SMALLINT;
  DECLARE after_p CHAR(20);
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
            SET ret=CONCAT(FindNumericValue(ret),'.',FindNumericValue(after_p));
            LEAVE l;
		ELSEIF c = ',' THEN 
			SET pos=INSTR(str, ',');
            SET after_p=MID(str,pos,pos+2);
            SET ret=CONCAT(FindNumericValue(ret),'.',FindNumericValue(after_p));
            LEAVE l;
		END IF;
      END IF;
      
      SET i = i + 1;
      
    END;
  UNTIL i > len END REPEAT;
  
  IF ret=''
  THEN 
    RETURN "0.0";
  END IF;
  
  RETURN ret;
  
END$$
DELIMITER ;

drop procedure if exists migrationIsante;
DELIMITER $$ 