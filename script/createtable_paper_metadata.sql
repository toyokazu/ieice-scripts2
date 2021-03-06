/* ja_paper_metadata の作成 */
drop table ja_paper_metadata;
create table ja_paper_metadata (
  id varchar(32),
  vol varchar(10),
  num integer,
  s_page integer,
  e_page integer,
  date datetime,
  title varchar(256),
  author varchar(512),
  abstract varchar(2048),
  keyword varchar(512),
  special varchar(256),
  category1 varchar(32),
  category2 varchar(32),
  category3 varchar(32),
  disp_title varchar(256),
  disp_author varchar(512),
  disp_abstract varchar(2048),
  disp_keyword varchar(512),
  err_fname varchar(128),
  err_comm varchar(128),
  nodisp_comm varchar(10),
  delflg varchar(10),
  mmflg varchar(10),
  l_auth_pdf varchar(128),
  l_auth_link varchar(128),
  err_1 varchar(128),
  err_2 varchar(128),
  recommend varchar(128),
  footnote_err_pdf varchar(128),
  publish_date varchar(128)
);
/* en_ja_paper_metadta の作成 */
drop table en_ja_paper_metadata;
create table en_ja_paper_metadata (
  id varchar(32),
  vol varchar(10),
  num integer,
  s_page integer,
  e_page integer,
  date datetime,
  title varchar(256),
  author varchar(512),
  abstract varchar(2048),
  keyword varchar(512),
  special varchar(256),
  category1 varchar(32),
  category2 varchar(32),
  category3 varchar(32),
  disp_title varchar(256),
  disp_author varchar(512),
  disp_abstract varchar(2048),
  disp_keyword varchar(512),
  err_fname varchar(128),
  err_comm varchar(128),
  nodisp_comm varchar(10),
  delflg varchar(10),
  mmflg varchar(10),
  l_auth_pdf varchar(128),
  l_auth_link varchar(128),
  err_1 varchar(128),
  err_2 varchar(128),
  recommend varchar(128),
  footnote_err_pdf varchar(128),
  publish_date varchar(128)
);
/* en_paper_metadta の作成 */
drop table en_paper_metadata;
create table en_paper_metadata (
  id varchar(32),
  vol varchar(10),
  num integer,
  s_page integer,
  e_page integer,
  date datetime,
  title varchar(256),
  author varchar(512),
  abstract varchar(2048),
  keyword varchar(512),
  special varchar(256),
  category1 varchar(32),
  category2 varchar(32),
  category3 varchar(32),
  disp_title varchar(256),
  disp_author varchar(512),
  disp_abstract varchar(2048),
  disp_keyword varchar(512),
  err_fname varchar(128),
  err_comm varchar(128),
  nodisp_comm varchar(10),
  delflg varchar(10),
  mmflg varchar(10),
  l_auth_pdf varchar(128),
  l_auth_link varchar(128),
  err_1 varchar(128),
  err_2 varchar(128),
  recommend varchar(128),
  footnote_err_pdf varchar(128),
  publish_date varchar(128)
);
