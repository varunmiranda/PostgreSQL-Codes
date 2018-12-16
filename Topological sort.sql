create database varunmiranda;
\connect varunmiranda

\echo Creating the relation graph with source and target

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

\echo Creating the relation graph nodes that will have all the nodes that are present in the graph

create table graph_nodes as
select g.source as node from graph g
union
select g.target as node from graph g;

\echo Creating a table top_sort that will ultimately store the topological sort of the graph

create table top_sort(node integer);

\echo Creating a function topologicalSort() that will fill the nodes in the table in the topological sort order

create or replace function topologicalSort()
returns table(node integer) as
$$ declare n int;
begin
    loop
        n := count(1) from graph;
        exit when n = 0;

        insert into top_sort
        select distinct g.source as node from graph g
        where g.source <> all(select target from graph)
        limit 1;

        delete from graph
        where source = any(select t.node from top_sort t);
    end loop;

insert into top_sort
select g.node from graph_nodes g
except
select t.node from top_sort t;

return query
select * from top_sort;

end;
$$ language plpgsql;

select * from topologicalSort();

\echo Dropping all the tables that were used

drop table graph;
drop table graph_nodes;
drop table top_sort;

\echo ------------------------------------------------------------------------------------------------------------------

\connect postgres
drop database varunmiranda;