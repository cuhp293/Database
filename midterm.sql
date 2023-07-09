--1
create table Book (
	book_id char(10) primary key,
	tittle char(50) NOT NULL,
	publisher char(20) NOT NULL,
	published_year bigint check(published_year > 1900),
	total_number_of_copies int check(total_number_of_copies >= 0),
	current_number_of_copies int check(current_number_of_copies >= 0),
	check(total_number_of_copies >= current_number_of_copies)
);
create table Borrower (
	borrower_id char(10) primary key,
	name char(50) NOT NULL,
	address text,
	telephone_number char(12)
);
create table BorrowCard(
	card_id int generated always as identity primary key,
	borrower_id char(10),
	borrow_date date NOT NULL,
	expected_return_date date NOT NULL,
	actual_return_date date,
	foreign key (borrower_id) references Borrower(borrower_id)
);
create table BorrowCardItem(
	card_id int generated always as identity,
	book_id char(10),
	primary key (card_id, book_id),
	foreign key (card_id) references BorrowCard(card_id),
	foreign key (book_id) references Book(book_id)
);
--2
select * from book
where published_year = '2020' and publisher = 'Wiley';
--3
select publisher, count(*) as total from book
group by (publisher);
--4
select book_id, tittle from book
join borrowcarditem using (book_id) as C1
join borrowcard using (card_id) where extract (year from borrow_date) = '2020'
group by (book_id, tittle) order by (count(*)) desc limit 5;
--5
select * from borrower where borrower_id in
(select borrower_id from borrowcard where actual_return_date = NULL);
--6
select * from borrower where borrower_id in
(select borrower_id from borrowcard
 where expected_return_date < actual_return_date
 or actual_return_date = NULL)
order by (name) asc;
--7
delete from book where book_id not in
(select book_id from borrowcard);
--8
update book
set total_number_of_copies = total_number_of_copies + 10,
	current_number_of_copies = current_number_of_copies + 10
where book_id in
(select book_id from book
 join borrowcarditem using (book_id)
 where publisher = 'Willey'
 group by (book_id) order by (count(*)) desc limit 5);
--9
select borrower_id, name from borrower where borrower_id in (
(select borrower_id from borrowcarditem
 join borrowcard using (card_id)
 join book using  (book_id)
 where publisher = 'Willey')
intersect (select borrower_id from borrowcarditem
		   join borrowcard using (card_id)
		   join book using (book_id) where publisher = 'Addison-Wesley')
);