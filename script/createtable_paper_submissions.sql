/* ja_paper_submissions の作成（paper_id は後で追加 -> ここで追加） */
drop table ja_paper_submissions;
create table ja_paper_submissions (
  id1 integer,
  id2 integer,
  tmp_id1 varchar(7),
  tmp_id2 varchar(1),
  tmp_id3 varchar(1),
  tmp_id4 varchar(1),
  tmp_id5 varchar(4),
  submission_id varchar(11),
  soccode varchar(2),
  title_j varchar(256),
  title_e varchar(256),
  volume1 varchar(64),
  inputnum integer,
  author_name_j varchar(64),
  author_name_e varchar(64),
  membernum varchar(10),
  orgcode integer,
  org_name_j varchar(64),
  org_name_e varchar(64),
  paper_id varchar(32)
);
/* en_paper_submissions の作成（paper_id は後で追加 -> ここで追加） */
drop table en_paper_submissions;
create table en_paper_submissions (
  id1 integer,
  id2 integer,
  tmp_id1 varchar(4),
  tmp_id2 varchar(1),
  tmp_id3 varchar(1),
  tmp_id4 varchar(1),
  tmp_id5 varchar(4),
  submission_id varchar(11),
  soccode varchar(2),
  title_j varchar(256),
  title_e varchar(256),
  volume1 varchar(64),
  inputnum integer,
  author_name_j varchar(64),
  author_name_e varchar(64),
  membernum varchar(10),
  orgcode integer,
  org_name_j varchar(64),
  org_name_e varchar(64),
  paper_id varchar(32)
);
