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
	where teaching.semester = '20221' and subject.name = 'so so du lieu';
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
			select avg(e.midterm_score*(100-s.percentage_final_exam)/100 + e.final_score*s.percentage_final_exam/100) into gpa
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