-- 1.Create table
create table student (
	student_id char(8) primary key,
	name char(100),
	gender char(10),
	clazz char(20),
	dob date,
	phone char(10),
	address char(100),
	hometown char(100),
	major char(10),
	cpa real,
	email char(100),
	warning_level int
);

create table subject (
	subject_id char(8) primary key,
	name char(100),
	so_tin int,
	required_subject char(8),
	percentage real,
	check(percentage > 0 and percentage < 1)
);

create table lecturer (
	lecturer_id char(8) primary key,
	name char(100),
	phone char(100),
	email char(100),
	year int,
	gender char(10),
	school char(10)
);

create table class (
	class_id char(8) primary key,
	place char(100),
	timing char(10),
	subject_id char(8),
	num_of_student int,
	max_of_student int,
	foreign key (subject_id) references subject(subject_id),
	check (num_of_student <= max_of_student)
);

create table enrollment (
	student_id char(8),
	foreign key (student_id) references student(student_id),
	subject_id char(8),
	foreign key (subject_id) references subject(subject_id),
	semester char(5),
	midterm_score real,
	endterm_score real,
	primary key (student_id, subject_id, semester)
);

create table enroll_class (
	student_id char(8),
	foreign key (student_id) references student(student_id),
	class_id char(8),
	foreign key (class_id) references class(class_id),
	time_enroll date,
	primary key (student_id, class_id)
);

create table teaching (
	lecturer_id char(8),
	foreign key (lecturer_id) references lecturer(lecturer_id),
	class_id char(8),
	foreign key (class_id) references class(class_id),
	semester char(5),
	primary key (lecturer_id, class_id, semester)
);

-- 2. Query
	-- Thêm, sửa, xoá sinh viên
	-- Thêm
	insert into student(student_id, name, gender, clazz, dob, phone, address, hometown, major, cpa, email, warning_level)
	values ('20213698', 'asd', 'nam', 'viet nhat 03', '2003-2-1', '09123453', 'ninh binh', 'ninh binh', 'cnnt', '2.99', 'adf@gmail.com', '0');
	-- Sửa
	update student
	set name = 'asdfaf'
	where student_id = '20213698';
	-- Xoá
	delete from student
	where student_id = '20213698';
	
	-- Chọn ra sinh viên được học bổng theo thứ tự giảm dần (cpa > 3.6)
	select * from student 
	where cpa > 3.6
	order by student_id desc;
	
	-- Chọn ra sinh viên học môn A ở kì 20211
	select student.student_id, student.name
	from student join enroll_class using (student_id)
	join class using (class_id)
	join subject using(subject_id)
	join teaching using (class_id)
	where teaching.semester = '20221' and subject.name = 'A';
	
	-- Chọn giảng viên dạy nhiều môn nhất kì B
	select lecturer.lecturer_id, lecturer.name, count(lecturer_id) as so_mon
	from lecturer
	join teaching using (lecturer_id)
	join class using (class_id)
	join subject using (subject_id)
	group by lecturer.lecturer_id, lecturer.name
	order by so_mon desc
	limit 1;

	-- Tính số sinh viên nữ của các lớp có mã HP 'IT3090'
	select count(*) from student
	join enrollment using(student_id)
	join subject using (subject_id)
	where student.gender = 'nu'
	and subject.name = 'IT3090';
	
	-- Hiển thị tên lớp và số lượng sinh viên tương ứng trong mỗi lớp. Sắp xếp kết quả theo số lượng sinh viên giảm dần
	select class.class_id, count(class.class_id) as num_student from class
	join enroll_class using(class_id)
	join student using(student_id)
	group by class.class_id
	order by num_student desc;
	
	-- Sinh viên có điểm môn X > điểm trung bình của cả lớp
	select * from student
	join enrollment on student.student_id = enrollment.student_id
	join subject on enrollment.subject_id = subject.subject_id
	where (subject.percentage * enrollment.endterm_score + (1 - subject.percentage) * enrollment.midterm_score) >
		(select avg(subject.percentage * enrollment.endterm_score + (1 - subject.percentage) * enrollment.midterm_score)
		from enrollment
		join subject on enrollment.subject_id = subject.subject_id);
	
	-- Đưa ra danh sách học phần, điểm cuối kì cao nhất, thấp nhất, trung bình trong kì A
	select subject.subject_id,
		   subject.name AS subject_name,
    	   max(subject.percentage * enrollment.endterm_score + (1 - subject.percentage) * enrollment.midterm_score) as max_score,
    	   min(subject.percentage * enrollment.endterm_score + (1 - subject.percentage) * enrollment.midterm_score) as min_score,
    	   avg(subject.percentage * enrollment.endterm_score + (1 - subject.percentage) * enrollment.midterm_score) as avg_score
	from subject
	join enrollment on subject.subject_id = enrollment.subject_id
	where enrollment.semester = 'A'
	group by subject.subject_id, subject.name;
-- 3. View
	-- Thời khoá biểu của sinh viên trong kì
	create view student_schedule as
	select c.timing, c.place, s.name as subject_name
	from enroll_class ec
	join class c on ec.class_id = c.class_id
	join subject s on c.subject_id = s.subject_id;
	
	-- Danh sách học phần giảng viên A dạy trong kì
	create view lecturer_subject as
	select subject.subject_id, subject.name as course_name, class.timing, class.place
	from teaching
	join lecturer on teaching.lecturer_id = lecturer.lecturer_id
	join class on teaching.class_id = class.class_id
	join subject on class.subject_id = subject.subject_id;
-- 4. Function/Procedure
	-- Cho 1 mã sinh viên, kì học, tính GPA kì đấy
	create or replace function s_gpa(s_id int, se int)
	returns float
	language plpgsql
	as
	$$
		declare
		gpa float;
		begin
			select avg(e.midterm_score*(1-s.percentage_final_exam)/1 + e.final_score*s.percentage_final_exam/1) into gpa
			from enrollment e join subject s using (subject_id)
			group by (e.student_id, e.semester)
			having (e.student_id = s_id and e.semester = se);
			return gpa;
		end;
	$$;
	-- Cho 1 mã lớp, kiểm tra số sinh viên có vượt qua số sinh viên giới hạn chưa
	create or replace function check_s_function(c_id char(8))
	returns int
	language plpgsql
	as
	$$
		declare
		s_num int;
		max_of_student int;
		n int;
		begin
			select count(*) into s_num
			from class
			join enroll_class using(class_id)
			join student using(student_id)
			where class_id = c_id
			group by class.class_id;
			
			select max_students into max_of_student
			from class
			where class_id = c_id;
			
			if s_num > max_of_student then
				raise notice 'Lớp đầy.';
				n = 1;
			else n = 0;
			end if;
			return n;
		end;
	$$;
-- 5. Trigger
	-- Cập nhật số sinh viên 1 lớp trong kì
	create or replace function update_student()
	returns trigger
	language plpgsql
	as
	$$
		begin
			update class set num_of_student = num_of_student + 1
			where class_id = old.class_id;
		end;
	$$;
	
	create trigger update_s_trigger
	before update on enroll_class
	for each row
	execute procedure update_student();
	
	-- Nếu số sinh viên 1 lớp > tối đa thì khoá đăng kí
	create or replace function check_dk()
	returns trigger
	language plpgsql
	as
	$$
		begin
			if new.num_of_student > new.max_of_student then
				raise exception 'Khoá đăng kí do lớp đầy.';
			end if;
			return new;
		end;
	$$;
	
	create trigger check_trigger
	before insert or update on enroll_class
	for each row
	when (new.student_id is not null)
	execute function check_dk();
-- 6. Index
	-- Tìm kiếm, truy vấn trên cột student_id nhanh hơn
	create index test
	on student(student_id);
	-- Tìm kiếm, truy vấn trên cột class_id nhanh hơn
	create index test1
	on class(class_id);
-- 7. Insert data
	insert into student (student_id, name, gender, clazz, dob, phone, address, hometown, major, cpa, email, warning_level, tin_no)
	values	('S0000001', 'John Doe', 'male', 'Class A', '2000-01-01', '1234567890', '123 Street, City', 'Hometown A', 'Major A', 3.5, 'john.doe@example.com', 1, 0),
		('S0000002', 'Jane Smith', 'female', 'Class B', '2001-02-02', '9876543210', '456 Road, Town', 'Hometown B', 'Major B', 3.8, 'jane.smith@example.com', 0, 2),
		('S0000003', 'David Johnson', 'male', 'Class C', '2002-03-03', '5555555555', '789 Avenue, Village', 'Hometown C', 'Major C', 3.2, 'david.johnson@example.com', 2, 1),
		('S0000004', 'Emily Williams', 'female', 'Class A', '2003-04-04', '6666666666', '321 Lane, City', 'Hometown D', 'Major A', 3.7, 'emily.williams@example.com', 3, 0),
		('S0000005', 'Michael Brown', 'male', 'Class B', '2004-05-05', '4444444444', '654 Street, Town', 'Hometown E', 'Major B', 3.6, 'michael.brown@example.com', 0, 1),
		('S0000006', 'Olivia Johnson', 'female', 'Class C', '2005-06-06', '2222222222', '987 Road, Village', 'Hometown F', 'Major C', 3.9, 'olivia.johnson@example.com', 1, 2),
		('S0000007', 'William Davis', 'male', 'Class A', '2006-07-07', '3333333333', '159 Avenue, City', 'Hometown G', 'Major A', 3.4, 'william.davis@example.com', 2, 0),
		('S0000008', 'Sophia Wilson', 'female', 'Class B', '2007-08-08', '7777777777', '753 Road, Town', 'Hometown H', 'Major B', 3.8, 'sophia.wilson@example.com', 0, 1),
		('S0000009', 'James Anderson', 'male', 'Class C', '2008-09-09', '8888888888', '852 Street, Village', 'Hometown I', 'Major C', 3.1, 'james.anderson@example.com', 1, 2),
		('S0000010', 'Ava Taylor', 'female', 'Class A', '2009-10-10', '9999999999', '753 Avenue, City', 'Hometown J', 'Major A', 3.5, 'ava.taylor@example.com', 2, 0);
	insert into subject (subject_id, name, so_tin, required_subject, percentage)
	values	('SUB001', 'Co so du lieu', 3, NULL, 0.7),
		('SUB002', 'Tin hoc dai cuong', 4, NULL, 0.6),
		('SUB003', 'Kien truc may tinh', 3, NULL, 0.7),
		('SUB004', 'Tinh toan khoa hoc', 3, NULL, 0.5),
		('SUB005', 'C basic', 2, NULL, 0.6);
	insert into lecturer (lecturer_id, name, phone, email, year, gender, school)
	values	('L1', 'John Doe', '123456789', 'john.doe@example.com', 1980, 'Male', 'School A'),
		('L2', 'Jane Smith', '987654321', 'jane.smith@example.com', 1970, 'Female', 'School B'),
		('L3', 'Michael Johnson', '555555555', 'michael.johnson@example.com', 1982, 'Male', 'School A'),
		('L4', 'Emily Davis', '111111111', 'emily.davis@example.com', 1978, 'Female', 'School B'),
		('L5', 'Robert Wilson', '999999999', 'robert.wilson@example.com', 1977, 'Male', 'School C'),
		('L6', 'Sophia Anderson', '222222222', 'sophia.anderson@example.com', 1988, 'Female', 'School A'),
		('L7', 'William Martinez', '777777777', 'william.martinez@example.com', 1956, 'Male', 'School B'),
		('L8', 'Olivia Taylor', '444444444', 'olivia.taylor@example.com',1999, 'Female', 'School C'),
		('L9', 'James Robinson', '666666666', 'james.robinson@example.com', 1967, 'Male', 'School A'),
		('L10', 'Ava Clark', '888888888', 'ava.clark@example.com', 1978, 'Female', 'School C');
	insert into enrollment  (student_id,subject_id,semester,midterm_score, endterm_score)
	values	('S0000001', 'SUB001', '20221', 2.5, 6),
		('S0000001', 'SUB003', '20221', 3, 2),
		('S0000001', 'SUB005', '20221', 10, 8),
		('S0000002', 'SUB004', '20221', 5, 5),
		('S0000002', 'SUB005', '20221', 2, 10),
		('S0000002', 'SUB001', '20221', 10, 2),
		('S0000002', 'SUB002', '20221', 5, 5),
		('S0000003', 'SUB003', '20221', 10, 6),
		('S0000003', 'SUB004', '20221', 8, 4),
		('S0000004', 'SUB005', '20221', 10, 10),
		('S0000005', 'SUB001', '20221', 10, 6),
		('S0000006', 'SUB002', '20221', 4.5, 6.5),
		('S0000007', 'SUB003', '20221', 4.5, 2),
		('S0000007', 'SUB004', '20221', 5.5, 9.5),
		('S0000001', 'SUB003', '20222', 4, 6),
		('S0000002', 'SUB003', '20222', 2, 1),
		('S0000009', 'SUB001', '20222', 2, 4),
		('S0000008', 'SUB001', '20222', 10, 6),
		('S0000010', 'SUB001', '20222', 9, 8),
		('S0000001', 'SUB001', '20222', 10, 10);
	insert into class (class_id, place , timing, subject_id, num_of_student, max_of_student, min_of_student)
	values	('CL01', 'D9 - 501', '3-4', 'SUB001', 123, 150, 12),
		('CL02', 'D9 - 503', '1-4', 'SUB001', 100, 150, 12),
		('CL03', 'D9 - 502', '3-6', 'SUB002', 99, 150, 12),
		('CL04', 'D3 - 501', '1-4', 'SUB002', 47, 50, 12),
		('CL05', 'D6 - 501', '2-4', 'SUB002', 12, 150, 12),
		('CL06', 'D8 - 501', '3-4', 'SUB002', 112, 150, 12),
		('CL07', 'D35 - 501', '1-4', 'SUB003', 31, 50, 12),
		('CL08', 'D9 - 401', '2-4', 'SUB003', 100, 150, 12),
		('CL09', 'D9 - 301', '3-4', 'SUB003', 110, 150, 12),
		('CL10', 'D9 - 201', '1-4', 'SUB003', 24, 60, 12),
		('CL11', 'D9 - 101', '3-6', 'SUB004', 20, 50, 12),
		('CL12', 'D9 - 204', '3-5', 'SUB005', 12, 150, 12),
		('CL13', 'D9 - 205', '3-7', 'SUB005', 13, 150, 12),
		('CL14', 'D9 - 206', '2-4', 'SUB005', 100, 150, 12),
		('CL15', 'D9 - 207', '3-4', 'SUB005', 149, 150, 12);
	insert into enroll_class (student_id, class_id, time_enroll)
	values	('S0000001', 'CL01', '12-10-2021'),
		('S0000002', 'CL01', '12-10-2021'),
		('S0000003', 'CL07', '12-10-2021'),
		('S0000004', 'CL12', '17-10-2021'),
		('S0000005', 'CL01', '9-8-2021'),
		('S0000006', 'CL03', '17-10-2021'),
		('S0000007', 'CL07', '9-8-2021'),
		('S0000008', 'CL02', '2-9-2022'),
		('S0000009', 'CL02', '2-9-2022'),
		('S0000010', 'CL02', '12-10-2022'),
		('S0000001', 'CL02', '12-10-2022'),
		('S0000002', 'CL04', '12-10-2022'),
		('S0000003', 'CL11', '12-10-2021'),
		('S0000001', 'CL07', '12-10-2021'),
		('S0000002', 'CL12', '12-10-2021');
	insert into teaching (lecturer_id, class_id,semester)
	values	('L1', 'CL01', '20221'),
		('L1', 'CL10', '20221'),
		('L2', 'CL02', '20221'),
		('L3', 'CL03', '20221'),
		('L3', 'CL04', '20221'),
		('L3', 'CL05', '20221'),
		('L4', 'CL06', '20221'),
		('L5', 'CL08', '20221'),
		('L7', 'CL07', '20221'),
		('L7', 'CL11', '20222'),
		('L7', 'CL13', '20222'),
		('L7', 'CL15', '20222'),
		('L8', 'CL12', '20222'),
		('L9', 'CL14', '20222'),
		('L9', 'CL09', '20222');
