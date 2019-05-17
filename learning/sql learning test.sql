create table months (id int, name varchar(10), days int);
insert into months values (1,'may',1);
INSERT INTO months (id,name,days) VALUES (2,'February',29);
SELECT * FROM months;
SELECT days FROM months;
SELECT days FROM months ORDER BY name DESC;
SELECT *
FROM months
WHERE name = 'january';
SELECT *
FROM months
WHERE days > 1
ORDER BY name;
