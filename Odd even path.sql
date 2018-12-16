create database varunmiranda;
\connect varunmiranda

\echo Creating the relation graph with source and target

create table graph(
source integer,
target integer);

insert into graph(source,target) values
(1,2),
(2,3),
(3,1),
(0,1),
(3,4),
(4,5),
(5,6);

\echo Creating the relation graph nodes that will have all the nodes that are present in the graph

create table graph_nodes as
select g.source as node from graph g
union
select g.target as node from graph g;

\echo Creating a base graph relation that takes care of lengths 0, 1 and 2

create table base_graph as
select distinct g.node as source, g.node as target, 0 as length, 0 as flag from (select node from graph_nodes) g
union
select g.source, g.target, 1 as length, 1 as flag from graph g
union
select g1.source, g2.target, 2 as length, 0 as flag from graph g1, graph g2
where g1.target = g2.source
order by length, source, target;

\echo Creating a function pathLength() that will check for path lengths > 2 till no paths will be present for that length

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

\echo Executing the function pathLength()

do $$ begin
perform pathLength();
end $$;

\echo ------------------------------------------------------------------------------------------------------------------

\echo PROBLEM 2 (i)

\echo Even Length Path

create or replace function connectedByEvenLengthPath()
returns table(source integer, target integer) as
$$
    select distinct source, target from base_graph
    where flag = 0;
$$ language sql;

select * from connectedByEvenLengthPath();

\echo ------------------------------------------------------------------------------------------------------------------

\echo PROBLEM 2 (ii)

\echo Odd Length Path

create or replace function connectedByOddLengthPath()
returns table(source integer, target integer) as
$$
    select distinct source, target from base_graph
    where flag = 1;
$$ language sql;

select * from connectedByOddLengthPath();

\echo Dropping all the tables that were used

drop table graph;
drop table graph_nodes;
drop table base_graph;

\echo ------------------------------------------------------------------------------------------------------------------

\connect postgres
drop database varunmiranda;