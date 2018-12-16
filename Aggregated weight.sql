create database varunmiranda;
\connect varunmiranda

\echo Creating a partsubpart relation

create table partsubpart(
pid integer,
sid integer,
quantity integer    
);

insert into partsubpart(pid,sid,quantity) values
(1,2,4),
(1,3,1),
(3,4,1),
(3,5,2),
(3,6,3),
(6,7,2),
(6,8,3);

\echo Creating basicpart relation

create table basicpart(
pid integer,
weight integer   
);

insert into basicpart(pid,weight) values
(2,5),
(4,50),
(5,3),
(7,6),
(8,10);

\echo Creating an aggregatedWeight function that accepts a p integer

create or replace function aggregatedWeight(p integer)
returns table(agg_weight bigint) as
$$ declare  
n int8 := 2;
counter int;
begin

    create table all_parts (pid integer, sid integer, quantity integer, weight integer); 
    
    insert into all_parts
    select p1.pid, 0 as sid, 1 as quantity, p1.weight from basicpart p1;

    insert into all_parts
    select ps.pid, ps.sid, ps.quantity, p1.weight from partsubpart ps, basicpart p1
    where ps.sid = p1.pid;

    create table agg_qty as
    select ps1.pid, ps2.sid, ps1.quantity * ps2.quantity as quantity, 2 as length from partsubpart ps1, partsubpart ps2
    where ps1.sid = ps2.pid;

    insert into all_parts
    select a.pid, a.sid, a.quantity, p1.weight from agg_qty a, basicpart p1
    where a.sid = p1.pid;

    loop

        counter = count(1) from (select 1 from agg_qty where sid <> all(select pid from basicpart) and length = n) c;

        exit when counter = 0;

        insert into agg_qty
        select a.pid, ps2.sid, a.quantity * ps2.quantity as quantity, n+1 as length from agg_qty a, partsubpart ps2
        where a.sid = ps2.pid
        and a.length = n;

        insert into all_parts
        select a.pid, a.sid, a.quantity, p1.weight from agg_qty a, basicpart p1
        where a.sid = p1.pid
        and a.length = n+1;

        n := n+1;

    end loop;

return query
select sum(ap.quantity * ap.weight) as agg_weight from all_parts ap
where ap.pid = p;

drop table all_parts;
drop table agg_qty;

end;
$$ language plpgsql;

\echo Executing the aggregatedWeight function

select * from aggregatedWeight(1);

\echo Dropping all the tables that were used

drop table partsubpart;
drop table basicpart;

\echo ------------------------------------------------------------------------------------------------------------------

\connect postgres
drop database varunmiranda;