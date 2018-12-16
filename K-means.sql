create database varunmiranda;
\connect varunmiranda

\echo Creating the relation dataSet (p,x,y)

create table dataSet(
p integer,
x float,
y float);

insert into dataSet values
(1,2.3,3.4),
(2,3.3,6.4),
(3,2.1,-9.8),
(4,10.1,15.8),
(5,-2.1,-9.8),
(6,-10.1,15.8),
(7,-2.3,-3.4),
(8,-3.3,-6.4),
(9,-2.1,50.8),
(10,-10.1,10.8),
(11,35.1,1.8),
(12,2.1,-9.8);

\echo Creating the kMeans function that takes k as the input parameter

create or replace function kMeans(k integer)
returns table(x float, y float) as
$$ declare
counter int8 = 0;
begin
create table kMeans_table as
select d.p, d.x, d.y from dataSet d 
limit k; 
    loop

        exit when counter = 100;

        create table dist_calc as
        select d.x, d.y, k.x as mx, k.y as my, sqrt((d.x - k.x)^2 + (d.y - k.y)^2) as dist, d.p as point, k.p as cluster from dataSet d, kMeans_table k;

        create table min_dist as
        select d.point, d.x, d.y, min(dist) as min_dist from dist_calc d
        group by d.point, d.x, d.y
        order by point;

        drop table kMeans_table;
        
        create table kMeans_table as
        with label as
        (select m.point, m.x, m.y, d.dist, d.cluster from dist_calc d, min_dist m
        where m.point = d.point
        and m.min_dist = d.dist)
        select l.cluster as p, cast (avg(l.x) as float) as x, cast (avg(l.y) as float) as y from label l
        group by l.cluster
        order by p; 

        counter := counter+1;

        drop table dist_calc;
        drop table min_dist;
    
    end loop;

return query
select k.x,k.y from kMeans_table k;
drop table kMeans_table;
end;
$$ language plpgsql;

\echo Executing the kMeans function

select * from kMeans(3);

\echo Dropping all the tables that were used

drop table dataSet;

\echo ------------------------------------------------------------------------------------------------------------------

\connect postgres
drop database varunmiranda;