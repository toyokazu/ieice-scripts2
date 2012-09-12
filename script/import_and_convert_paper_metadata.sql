/* TSV ファイルのインポート */
.separator "\t"
.import output_j.txt ja_paper_metadata
.import output_ej.txt en_ja_paper_metadata
.import output_e.txt en_paper_metadata
create index ja_paper_metadata_index on ja_paper_metadata ( id );
create index en_ja_paper_metadata_index on en_ja_paper_metadata ( id );
create index en_paper_metadata_index on en_paper_metadata ( id );
