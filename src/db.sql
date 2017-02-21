
create table if not exists user(id int(25) PRIMARY key auto_increment,name VARCHAR(20) not null,pwd VARCHAR(50),dept int(25))ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
truncate table user;

insert into user(name,pwd,dept) values('jack1','123',1);
insert into user(name,pwd ,dept) values('jack2','123',2);
insert into user(name,pwd ,dept) values('jack3','123',3);
insert into user(name,pwd ,dept) values('jack4','123',4);
insert into user(name,pwd ,dept) values('jack11','123',1);
insert into user(name,pwd ,dept) values('jack22','123',2);
insert into user(name,pwd ,dept) values('jack33','123',3);
insert into user(name,pwd ,dept) values('jack44','123',4);

