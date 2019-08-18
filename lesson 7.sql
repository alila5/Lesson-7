
-- ������������ ������� ���� �8
-- 1.	�������� �������� ������� hello(), ������� ����� ���������� �����������, � ����������� �� �������� ������� �����.
--  � 6:00 �� 12:00 ������� ������ ���������� ����� "������ ����", � 12:00 �� 18:00 ������� ������ ���������� ����� "������ ����", 
-- � 18:00 �� 00:00 � "������ �����", � 00:00 �� 6:00 � "������ ����".

USE shop;
DROP FUNCTION  IF EXISTS hello;

DELIMITER  //
 
CREATE FUNCTION hello ()
RETURNS TEXT DETERMINISTIC
 BEGIN 
	DECLARE t text DEFAULT '����� �������� ' ;
	DECLARE time int DEFAULT 0 ;
	SET time = HOUR(time(now()));
	 IF  6 < time  AND time < 12   THEN
		SET t = '������ ����' ;
	 ELSEIF 12 <= time AND time <= 18  THEN
		SET t='������ ����';
	 ELSEIF 18 < time   THEN
		SET t='������ �����';
	 ELSE 
		SET t = '������ ����';
	END IF;

 RETURN t ;
END//
 
DELIMITER ;

SELECT hello();


-- 2.	� ������� products ���� ��� ��������� ����: name � ��������� ������ � description � ��� ���������. 
-- ��������� ����������� ����� ����� ��� ���� �� ���. ��������, ����� ��� ���� ��������� �������������� �������� NULL �����������. 
-- ��������� ��������, ��������� ����, ����� ���� �� ���� ����� ��� ��� ���� ���� ���������. 
-- ��� ������� ��������� ����� NULL-�������� ���������� �������� ��������.



-- ��� �������� � ���� ������ shop ��������� ������� flight. ���� ������� �� ����� �� ��������.

DROP TABLE IF EXISTS shop.flight;

CREATE TABLE shop.flight (
	id SERIAL PRIMARY KEY,  
	from_nm varchar(100) ,
	to_nm varchar(100) 
);


DROP TRIGGER IF EXISTS fl_ins;
DELIMITER  //
CREATE TRIGGER fl_ins BEFORE INSERT ON shop.flight
FOR EACH ROW
BEGIN
	-- DECLARE t text DEFAULT '����� �������� ' ;
 	IF NEW.from_nm IS NULL AND NEW.to_nm IS NULL THEN
-- 		SET NEW.from_nm= '111'
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insert canceled';
 	END IF;
END//
DELIMITER  ;

-- �������� ������� NULL
DELETE FROM flight;
INSERT INTO flight (from_nm, to_nm) VALUES
  (Null, Null),
  ('��������', 'irkutsk'),
  ('kazan', 'novgorod'),
  ('sainkt-peterburg', 'omsk'),
  ('�����', '�������');

DROP TRIGGER IF EXISTS fl_update;
DELIMITER  //
CREATE TRIGGER fl_update BEFORE UPDATE ON shop.flight
FOR EACH ROW
BEGIN
 	IF NEW.from_nm IS NULL AND OLD.to_nm IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Update canceled! Field "FROM" cannot be NULL because the field "TO" is equal to NULL ';
 	END IF;
 	IF NEW.to_nm IS NULL AND OLD.from_nm IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Update canceled! Field "TO" cannot be NULL because the field "FROM" is equal to NULL ';
 	END IF;
  	IF NEW.to_nm IS NULL AND new.from_nm IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Update canceled! Field "TO" cannot be NULL and the field "FROM" cannot be NULL';
 	END IF;
END//
DELIMITER  ;



-- �������  update ������������  ���� �� �����  �  NULL
DELETE FROM flight;
INSERT INTO flight (from_nm, to_nm) VALUES
  (NULL, 'irkutsk'),
  ('kazan', 'novgorod'),
  ('sainkt-peterburg', 'omsk'),
  ('�����', '�������');
 
SELECT @min_id := MIN(id) FROM flight;

UPDATE flight  SET to_nm = NULL WHERE id = @min_id;
 
SELECT * FROM shop.flight;

-- �������  update ������������ ��� ���� �  NULL
DELETE FROM flight;
INSERT INTO flight (from_nm, to_nm) VALUES
  ('��������', 'irkutsk'),
  ('kazan', 'novgorod'),
  ('sainkt-peterburg', 'omsk'),
  ('�����', '�������');
 
 
SELECT @min_id := MIN(id) FROM flight;

 UPDATE flight SET from_nm = NULL, to_nm = NULL WHERE id = @min_id;
 
 SELECT * FROM shop.flight;

-- 3.	(�� �������) �������� �������� ������� ��� ���������� ������������� ����� ���������. 
-- ������� ��������� ���������� ������������������ � ������� ����� ����� ����� ���� ���������� �����. 
-- ����� ������� FIBONACCI(10) ������ ���������� ����� 55.


DROP FUNCTION  IF EXISTS FIBONACCI;
DELIMITER  //
CREATE FUNCTION FIBONACCI (digit INT) 
RETURNS decimal DETERMINISTIC
 BEGIN
	DECLARE Counter INT DEFAULT 0;
	DECLARE One DECIMAL DEFAULT 0;
	DECLARE Two DECIMAL DEFAULT 0;
	SET Two = 1;
 	IF Digit > 2 THEN
  		SET Counter = 3;
 		SET One = 1;
 	END IF;
	WHILE Digit >= Counter DO
 		SET Two = One + Two;
 		SET One = Two - One;
 		SET Counter = Counter + 1;
 	END WHILE;
 RETURN Two;
END//


 SELECT fibonacci(55);  -- SQL Error [1264] [22001]: Data truncation: Out of range value for column 'Two' at row 1
-- ��� � �� ����� ��� ��� �� ������ ���� ����� ����� ������ 49. ������ �� ����� ��� � ������� ����������.


 -- ������������ ������� ���� �9

-- 1.	�������� ������� logs ���� Archive. ����� ��� ������ �������� ������ � �������� users, 
-- catalogs � products � ������� logs ���������� ����� � ���� �������� ������, �������� �������,
-- ������������� ���������� ����� � ���������� ���� name.
 
DROP TABLE IF EXISTS shop.logs;

CREATE TABLE shop.logs (
	id SERIAL PRIMARY KEY,
	tbl_nm varchar(100),
	id_log BIGINT,
	name_log  varchar(100),
	created_log DATETIME,
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

DROP TRIGGER IF EXISTS ins_users;
DELIMITER  //
CREATE TRIGGER ins_users AFTER INSERT ON shop.users
FOR EACH ROW
BEGIN
	INSERT INTO logs (tbl_nm, id_log, name_log, created_log) VALUES
		('users',NEW.id, NEW.name, NEW.created_at);
END//
DELIMITER  ;

DROP TRIGGER IF EXISTS ins_products;
DELIMITER  //
CREATE TRIGGER ins_products AFTER INSERT ON shop.products
FOR EACH ROW
BEGIN
	INSERT INTO logs (tbl_nm, id_log, name_log, created_log) VALUES
		('products',NEW.id, NEW.name, NEW.created_at);
END//
DELIMITER  ;

DROP TRIGGER IF EXISTS ins_catalogs;
DELIMITER  //
CREATE TRIGGER ins_catalogs AFTER INSERT ON shop.catalogs
FOR EACH ROW
BEGIN
	INSERT INTO logs (tbl_nm, id_log, name_log, created_log) VALUES
		('catalogs',NEW.id, NEW.name, now());
END//
DELIMITER  ;

-- 2.	(�� �������) �������� SQL-������, ������� �������� � ������� users ������� �������.

DROP PROCEDURE  IF EXISTS new_num_rec;
DELIMITER  //
CREATE PROCEDURE new_num_rec (IN digit INT) 
 BEGIN
	DECLARE i INT DEFAULT 0;
	WHILE digit >= i  DO
		INSERT INTO shop.users (name, birthday_at) VALUES
		(CONCAT('name_', i), now()-interval floor(10000*rand()) DAY);
 		SET i = i + 1;
 	END WHILE;
END//


CALL new_num_rec(1000000);

SELECT * FROM logs;


