create database varunmiranda;
\connect varunmiranda

\echo Creating the relation graph with source, target and weight

create table graph(
source integer,
target integer,
weight integer);

insert into graph values
(0,1,2),
(1,0,2),
(0,4,10),
(4,0,10),
(1,3,3),
(3,1,3),
(1,4,7),
(4,1,7),
(2,3,4),
(3,2,4),
(3,4,5),
(4,3,5),
(4,2,6),
(2,4,6);

\echo Creating the relation graph nodes that will have all the nodes that are present in the graph

create table graph_nodes as
select g.source as node from graph g
union
select g.target as node from graph g;

\echo Creating the base graph relation that will take care of all weights between nodes of path lengths 0, 1 and 2

create table base_graph as

with base_view as
(select distinct g.node as source, g.node as target, 0 as weight, 0 as length from (select node from graph_nodes) g
union
select g.*, 1 as length from graph g
union
select g1.source, g2.target, g1.weight + g2.weight as weight, 2 as length from graph g1, graph g2
where g1.target = g2.source
order by length)

select b.source, b.target, b.weight, b.length from base_view b inner join
(select source, target, min(weight) as weight from base_view group by source, target) b1
on b.source = b1.source and b.target = b1.target and b.weight = b1.weight;

\echo Creating a function pathWeights() that will check for weights for path lengths > 2 till no paths will be present for that length

create or replace function pathWeights()
returns void as
$$ declare
n int8 := 2;
counter int;
begin
    loop

        counter := count (1) from
        (select 1 from base_graph g1, graph g2, base_graph g3
        where g1.target = g2.source
        and g1.length = n
        and g1.source = g3.source
        and g2.target = g3.target
        and g3.weight > g1.weight + g2.weight) c;

        exit when counter = 0;

        insert into base_graph
        select g1.source, g2.target, g1.weight + g2.weight as weight, n+1 as length from base_graph g1, graph g2, base_graph g3
        where g1.target = g2.source
        and g1.length = n
        and g1.source = g3.source
        and g2.target = g3.target
        and g3.weight > g1.weight + g2.weight
        order by length;

        n := n+1;
    
    end loop;
end;
$$ language plpgsql;

\echo Executing the function pathWeights()

do $$ begin
perform pathWeights();
end $$;

\echo Creating and executing the Djikstra function with an input parameter s

create or replace function Djikstra(s integer)
returns table(target integer, distanceToTarget integer) as
$$
    select target, min(weight) as distanceToTarget from base_graph
    where source = s
    group by target;

$$ language sql;

select * from Djikstra(0);

\echo Dropping all the tables that were used

drop table graph;
drop table graph_nodes;
drop table base_graph;

\echo ------------------------------------------------------------------------------------------------------------------

\connect postgres
drop database varunmiranda;