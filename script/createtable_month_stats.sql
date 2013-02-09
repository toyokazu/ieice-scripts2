/* paper stats */
drop table paper_stats;
create table paper_stats (
  paper_id varchar(32),
  stats_date varchar(16),
  stats_datetime datetime,
  access_count integer,
  uniq_address_count integer,
  address_count integer,
  access_rank integer,
  uniq_access_rank integer
);
create index paper_stats_id_index on paper_stats (paper_id);
create index paper_stats_time_string_index on paper_stats (stats_date);
create index paper_stats_time_index on paper_stats (stats_datetime);
drop table address_stats;
create table address_stats (
  ip_address varchar(128),
  stats_date varchar(16),
  stats_datetime datetime,
  access_count integer,
  uniq_paper_count integer,
  paper_count integer,
  access_rank integer,
  uniq_access_rank integer,
  network_address varchar(256),
  network_owner_jpnic varchar(256),
  network_owner_radb varchar(256)
);
create index address_stats_id_index on address_stats (ip_address);
create index address_stats_time_string_index on address_stats (stats_date);
create index address_stats_time_index on address_stats (stats_datetime);
drop table month_stats;
create table month_stats (
  stats_date varchar(16),
  stats_datetime datetime,
  avg_paper integer,
  var_paper integer,
  dev_paper float,
  num_paper integer,
  thresh_num_paper integer,
  avg_remote_addr integer,
  var_remote_addr integer,
  dev_remote_addr float,
  num_remote_addr integer,
  thresh_num_remote_addr integer,
  num_bots integer,
  num_others integer
);
create index month_stats_time_string_index on month_stats (stats_date);
create index month_stats_time_index on month_stats (stats_datetime);
