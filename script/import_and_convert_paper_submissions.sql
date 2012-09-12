/* TSV ファイルのインポート */
.separator "\t"
.import output_a_j-utf8-with_paper_id.txt ja_paper_submissions
.import output_b_j-utf8-with_paper_id.txt ja_paper_submissions
.import output_c_j-utf8-with_paper_id.txt ja_paper_submissions
.import output_d_j-utf8-with_paper_id.txt ja_paper_submissions
.import output_a_e-utf8-with_paper_id.txt en_paper_submissions
.import output_b_e-utf8-with_paper_id.txt en_paper_submissions
.import output_c_e-utf8-with_paper_id.txt en_paper_submissions
.import output_d_e-utf8-with_paper_id.txt en_paper_submissions
/* "" の一括削除 */
/* update ja_paper_submissions set volume1 = replace(volume1, '"', ''); */
update ja_paper_submissions set title_j = replace(title_j, '"', ''), title_e = replace(title_e, '"', ''), volume1 = replace(volume1, '"', '');
/* update en_paper_submissions set volume1 = replace(volume1, '"', ''); */
update en_paper_submissions set title_j = replace(title_j, '"', ''), title_e = replace(title_e, '"', ''), volume1 = replace(volume1, '"', '');
/* paper_id カラムの追加（paper_id は TSV 上で生成することに変更） */
/*
alter table ja_paper_submissions add column paper_id varchar(32);
alter table en_paper_submissions add column paper_id varchar(32);
*/
/* create index */
create index ja_paper_submissions_index on ja_paper_submissions ( paper_id );
create index en_paper_submissions_index on en_paper_submissions ( paper_id );
