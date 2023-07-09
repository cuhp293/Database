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
	SELECT lecturer.lecturer_id, lecturer.name, COUNT(lecturer_id) AS so_mon
FROM lecturer
JOIN teaching USING (lecturer_id)
JOIN class USING (class_id)
JOIN subject USING (subject_id)
GROUP BY lecturer.lecturer_id, lecturer.name
ORDER BY so_mon DESC
LIMIT 1;

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
	select student_id, 
	-- Đưa ra danh sách học phần, điểm cuối kì cao nhất, thấp nhất, trung bình trong kì A
-- 3. View
	-- Thời khoá biểu của sinh viên trong kì
	-- Danh sách học phần giảng viên A dạy trong kì
-- 4. Function/Procedure
	-- Cho 1 mã sinh viên, kì học, tính GPA kì đấy
	-- Cho 1 mã lớp, kiểm tra số sinh viên có vượt qua số sinh viên giới hạn chưa
-- 5. Trigger
	-- Cập nhật số sinh viên 1 lớp trong kì
	-- Nếu số sinh viên 1 lớp > tối đa thì khoá đăng kí