SELECT name 'Table without Identity column'
FROM SYS.Tables
WHERE OBJECTPROPERTY(object_id,'TableHasIdentity') = 0
      AND type = 'U'
