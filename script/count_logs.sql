/* datetime(substr(log_date, 0, 20)) という変換で，log_date を秒単位に変換できる */
/* ただし，それを使ったカウント丸めは未実施 */
select * from (select f_name, count(*) as count from access_logs where f_name like '%.pdf' and f_name not like '%_000.pdf' and err = 1 and summary_view != 1 group by f_name) order by count desc;
