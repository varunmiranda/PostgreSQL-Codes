create database varunmiranda;
\connect varunmiranda

\echo Creating a relation A with integer values

create table A(    
x integer);

insert into A(x) values
(1),(2),(3),(4);

\echo Creating a relation Powerset that stores '{}' initially

create table powerset(
value int[]);

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
n int8 := count(1) from A;
i int;
begin
    for i in 1..n 
    loop
        insert into powerset 
        select powerset.value||A.x from powerset,A
        where not(memberof(A.x,powerset.value));
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

\echo Creating the function that makes sure that only the supersets of X are printed

create or replace function superSetsOfSets(X int[])
returns table(powerset int[]) as
$$
    select * from distinct_powerset
    where X <@ distinct_powerset.powerset;
$$ language sql;

\echo Calling the function and printing the final output

select superSetsOfSets('{1,3}');

\echo Dropping all the tables that were used

drop table A;
drop table powerset;
drop table distinct_powerset;

\echo ------------------------------------------------------------------------------------------------------------------

\connect postgres
drop database varunmiranda;