create database varunmiranda;
\connect varunmiranda

--Queue and stack

create or replace function queue(a int[],x integer)
returns int[] as
$$
select a || x;
$$ language sql;

create or replace function stack(a int[],x integer)
returns int[] as
$$
select x || a;
$$ language sql;

--Common pop function for both queue and stack

create or replace function pop(a int[])
returns int[] as
$$
select array_remove(a,a[1]);
$$ language sql;

\echo ------------------------------------------------------------------------------------------------------------------

\connect postgres
drop database varunmiranda;