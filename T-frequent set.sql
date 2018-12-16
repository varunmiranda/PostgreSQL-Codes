create database varunmiranda;
\connect varunmiranda

\echo Creating the documents table

create table documents(
doc text,
words text[]);

insert into documents(doc,words) values
('d1','{A,B,C}'),
('d2','{B,C,D}'),
('d3','{A,E}'),
('d4','{B,B,A,D}'),
('d5','{E,F}'),
('d6','{A,D,G}'),
('d7','{C,B,A}'),
('d8','{B,A}');

\echo Creating a table W that will store all the distinct words in all the documents

create table W as
select distinct unnest(d.words) as words from documents d;

\echo Creating a relation Powerset that stores '{}' initially

create table powerset(
value text[]);

insert into powerset values ('{}');

\echo Creating a memberof function

create or replace function memberof(x anyelement, A anyarray)
returns boolean as
$$
select x = some(A);
$$ language sql;

\echo Creating a looping function called powersets() that generates all the possible powersets with duplicates

create or replace function powersets()
returns void as 
$$ declare 
n int8 := count(1) from W;
i int;
begin
    for i in 1..n 
    loop
        insert into powerset 
        select powerset.value||W.words from powerset,W
        where not(memberof(W.words,powerset.value));
    end loop;
end;
$$ language plpgsql;

\echo Calling the powersets() function that returns void but performs the operation

do $$ begin
perform powersets();
end $$;

\echo Removing Duplicates and storing it in a new table   

create table distinct_powerset as

with distinct_powerset as
(select distinct value from powerset)

select distinct g.array_agg as powerset from
(select u.row_number, array_agg(u.unnest) from
(select unnest(value) as unnest, row_number() over (order by value) from distinct_powerset order by row_number,unnest) u
group by u.row_number) g;

\echo On unnesting '{}' disappears so reintroducing that in the powerset table

insert into distinct_powerset values ('{}');

\echo Creating the function that returns each t-frequent set

create or replace function frequentSets(t int)
returns table(powerset text[]) as
$$
    select g.powerset from
    (select distinct p.powerset, count(d.words) as count from distinct_powerset p, documents d
    where p.powerset <@ d.words
    group by p.powerset) g
    where g.count >= t; 
$$ language sql;

\echo Calling the function and printing the final output

select powerset as sets from frequentSets(1);

\echo Dropping all the tables that were used

drop table documents;
drop table W;
drop table powerset;
drop table distinct_powerset;

\echo ------------------------------------------------------------------------------------------------------------------

\connect postgres
drop database varunmiranda;