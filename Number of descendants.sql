create database varunmiranda;
\connect varunmiranda

create table graph(
source integer,
target integer);

insert into graph(source,target) values
(1,2),
(1,3),
(2,3),
(2,4),
(3,7),
(7,4),
(4,5),
(4,6),
(7,6);

create table base_graph as
select g.source, g.target, 1 as length, 1 as flag from graph g
union
select g1.source, g2.target, 2 as length, 0 as flag from graph g1, graph g2
where g1.target = g2.source
order by length, source, target;

create or replace function pathLength()
returns void as
$$ declare
n int8 := 2;
f int8 := 1;
counter int;
begin
loop

counter := count (1) from
(select 1 from base_graph g1, graph g2
where g1.target = g2.source
and g1.length = n) c;

exit when counter = 0;

insert into base_graph
select g1.source, g2.target, n+1 as length, f as flag from base_graph g1, graph g2
where g1.target = g2.source
and g1.length = n
order by length;

create table grouped_graph as
select g.source, g.target, min(length) as length, g.flag from base_graph g
group by source,target,flag
order by length;

drop table base_graph;

create table base_graph as
select * from grouped_graph;

drop table grouped_graph;

n := n+1;
f := 1-f;
end loop;
end;
$$ language plpgsql;

do $$ begin
perform pathLength();
end $$;

create or replace function Descendants(s integer)
returns bigint as
$$
select count(1) from
(select distinct source, target from base_graph where s = source) s;

$$ language sql;​

\echo ------------------------------------------------------------------------------------------------------------------

\connect postgres
drop database varunmiranda;