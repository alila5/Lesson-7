
-- Практическое задание тема №8
-- 1.	Создайте хранимую функцию hello(), которая будет возвращать приветствие, в зависимости от текущего времени суток.
--  С 6:00 до 12:00 функция должна возвращать фразу "Доброе утро", с 12:00 до 18:00 функция должна возвращать фразу "Добрый день", 
-- с 18:00 до 00:00 — "Добрый вечер", с 00:00 до 6:00 — "Доброй ночи".

USE shop;
DROP FUNCTION  IF EXISTS hello;

DELIMITER  //
 
CREATE FUNCTION hello ()
RETURNS TEXT DETERMINISTIC
 BEGIN 
	DECLARE t text DEFAULT 'Нужно уточнить ' ;
	DECLARE time int DEFAULT 0 ;
	SET time = HOUR(time(now()));
	 IF  6 < time  AND time < 12   THEN
		SET t = 'Доброе утро' ;
	 ELSEIF 12 <= time AND time <= 18  THEN
		SET t='Добрый день';
	 ELSEIF 18 < time   THEN
		SET t='Добрый вечер';
	 ELSE 
		SET t = 'Доброй ночи';
	END IF;

 RETURN t ;
END//
 
DELIMITER ;

SELECT hello();


-- 2.	В таблице products есть два текстовых поля: name с названием товара и description с его описанием. 
-- Допустимо присутствие обоих полей или одно из них. Ситуация, когда оба поля принимают неопределенное значение NULL неприемлема. 
-- Используя триггеры, добейтесь того, чтобы одно из этих полей или оба поля были заполнены. 
-- При попытке присвоить полям NULL-значение необходимо отменить операцию.



-- для проверки в базе данных shop создается таблица flight. Суть задания от этого не меняется.

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
	-- DECLARE t text DEFAULT 'Нужно уточнить ' ;
 	IF NEW.from_nm IS NULL AND NEW.to_nm IS NULL THEN
-- 		SET NEW.from_nm= '111'
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insert canceled';
 	END IF;
END//
DELIMITER  ;

-- Проверим вставку NULL
DELETE FROM flight;
INSERT INTO flight (from_nm, to_nm) VALUES
  (Null, Null),
  ('Угорщина', 'irkutsk'),
  ('kazan', 'novgorod'),
  ('sainkt-peterburg', 'omsk'),
  ('Пекин', 'Анадырь');

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



-- Проверм  update устанавливая  одно из полей  в  NULL
DELETE FROM flight;
INSERT INTO flight (from_nm, to_nm) VALUES
  (NULL, 'irkutsk'),
  ('kazan', 'novgorod'),
  ('sainkt-peterburg', 'omsk'),
  ('Пекин', 'Анадырь');
 
SELECT @min_id := MIN(id) FROM flight;

UPDATE flight  SET to_nm = NULL WHERE id = @min_id;
 
SELECT * FROM shop.flight;

-- Проверм  update устанавливая два поля в  NULL
DELETE FROM flight;
INSERT INTO flight (from_nm, to_nm) VALUES
  ('Угорщина', 'irkutsk'),
  ('kazan', 'novgorod'),
  ('sainkt-peterburg', 'omsk'),
  ('Пекин', 'Анадырь');
 
 
SELECT @min_id := MIN(id) FROM flight;

 UPDATE flight SET from_nm = NULL, to_nm = NULL WHERE id = @min_id;
 
 SELECT * FROM shop.flight;

-- 3.	(по желанию) Напишите хранимую функцию для вычисления произвольного числа Фибоначчи. 
-- Числами Фибоначчи называется последовательность в которой число равно сумме двух предыдущих чисел. 
-- Вызов функции FIBONACCI(10) должен возвращать число 55.


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
-- Так и не понял что это за ошибка если брать числа больше 49. Точнее не понял как с ошибкой справиться.


 -- Практическое задание тема №9

-- 1.	Создайте таблицу logs типа Archive. Пусть при каждом создании записи в таблицах users, 
-- catalogs и products в таблицу logs помещается время и дата создания записи, название таблицы,
-- идентификатор первичного ключа и содержимое поля name.
 
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

-- 2.	(по желанию) Создайте SQL-запрос, который помещает в таблицу users миллион записей.

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


