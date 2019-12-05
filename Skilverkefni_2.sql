use ProgressTracker_V6;

/* 1:
	Smíðið trigger fyrir insert into Restrictors skipunina. 
	Triggernum er ætlað að koma í veg fyrir að einhver áfangi sé undanfari eða samfari síns sjálfs. 
	með öðrum orðum séu courseNumber og restrictorID með sama innihald þá stoppar triggerinn þetta með
	því að kasta villu og birta villuboð.
	Dæmi um insert sem triggerinn á að stoppa: insert into Restrictors values('GSF2B3U','GSF2B3U',1);
*/


drop trigger if exists before_restrictors_insert;
delimiter $$
create trigger before_restrictors_insert
before insert on Restrictors
for each row 
begin
	if(new.courseNumber = new.restrictorID) THEN
	SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT = 'Ekki setja áfanga sem undanfara eða samfara af sjálfum sér.';
    end if;
end $$
delimiter ;
-- insert into Restrictors(courseNumber,restrictorID,restrictorType)values('GSF2B3U','GSF2B3U',1);


-- 2:
-- Skrifið samskonar trigger fyrir update Restrictors skipunina.


drop trigger if exists before_restrictors_update;
delimiter $$
create trigger before_restrictors_update
before update on Restrictors
for each row 
begin
	if(new.courseNumber = new.restrictorID) THEN
	SIGNAL SQLSTATE '45000'
	SET MESSAGE_TEXT = 'Ekki setja áfanga sem undanfara eða samfara af sjálfum sér.';
    end if;
end $$
delimiter ;
-- update Restrictors set courseNumber = restrictorID where courseNumber = 'GSF2B3U';


/*
	3:
	Skrifið stored procedure sem leggur saman allar einingar sem nemandinn hefur lokið.
    Birta skal fullt nafn nemanda, heiti námsbrautar og fjölda lokinna eininga(
	Aðeins skal velja staðinn áfanga. passed = true
*/

delimiter $$
drop procedure if exists AStudentsCredit $$
    
create procedure AStudentsCredit(in varStudentID int)
begin
		select concat_ws(' ', students.firstName, students.lastName) as "Full Name",
        tracks.trackName as "Track Name", sum(courses.courseCredits) as "Total Credits"
        from courses join trackcourses join registration join students join tracks
        where courses.courseNumber = trackcourses.courseNumber
        and trackcourses.courseNumber = registration.courseNumber
        and students.studentID = registration.studentID
        and students.studentID = varStudentID
        and registration.passed = true;
end $$
delimiter ;
-- call AStudentsCredit(1);


/*
	4:
	Skrifið 3 stored procedure-a:
    AddStudent()
    AddMandatoryCourses()
    Hugmyndin er að þegar AddStudent hefur insertað í Students töfluna þá kallar hann á AddMandatoryCourses() sem skráir alla
    skylduáfanga á nemandann.
    Að endingu skrifið þið stored procedure-inn StudentRegistration() sem nota skal við sjálfstæða skráningu áfanga nemandans.
*/

-- 4.a

delimiter $$
drop procedure if exists AddStudent $$
    
create procedure AddStudent(in varFirstName varchar(55), in varLastName varchar(55), in varDOB date, in varStartSemester int, in varTrackID int, in varDate date)
begin
	declare varStudentID int;
    insert into Students(firstName,lastName,dob,startSemester)values(varFirstName,varLastName,varDOB,varStartSemester);
    set varStudentID = (select studentID from Students order by studentID desc limit 1);
    call AddMandatoryCourses(varStudentID,varTrackID,varDate,varStartSemester);
end $$
delimiter ;
-- call AddStudent("Sindri","Pálsson","1999-04-28",1,9,'2019-09-30'); select * from students; select * from registration;

-- 4.b

delimiter $$
drop procedure if exists AddMandatoryCourses $$
    
create procedure AddMandatoryCourses(in varStudentID int, in varTrackID int, in varDate date, in varSemester int)
begin
	declare varCourseNumber char(10);
	declare done int default false;
	declare ACursor cursor
		for select courseNumber from trackcourses  where mandatory = 1 and trackID = varTrackID;
	declare continue handler for not found set done = true;
	open ACursor;
	read_loop: loop
		fetch ACursor into varCourseNumber;
		if done then
			leave read_loop;
		end if;
		insert into Registration(studentID,trackID,courseNumber,registrationDate,passed,semesterID)values(varStudentID,varTrackID,varCourseNumber,varDate,false,varSemester);
	end loop;
	close ACursor;
end $$
delimiter ;
-- call AddMandatoryCourses(8,9,'2019-09-30',1); select * from registration;

-- 4.c

delimiter $$
drop procedure if exists StudentRegistration $$
    
create procedure StudentRegistration(in varStudentID int, in varTrackID int, in varCourseNumber char(10), in varDate date, in varPassed bool, in varSemester int)
begin
	insert into Registration(studentID,trackID,courseNumber,registrationDate,passed,semesterID)values(varStudentID,varTrackID,varCourseNumber,varDate,varPassed,varSemester);
end $$
delimiter ;
-- call StudentRegistration(8,9,'STÆ103','2019-09-30',false,1);