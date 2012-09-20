/* PDFのアクセスログ */
drop table access_logs;
create table access_logs (
  /* 0: 項番  id  int8 */
  id integer,
  /* 1: 閲覧日時  log_date  varchar 10  yyyymmdd hhmmss */
  log_date datetime,
  /* 2: ログインユーザ  user_id varchar 100 "環境変数　REMOTE_USER ID or メールアドレス" */
  user_id varchar(100),
  /* 3: 会員ソサイエティ  society varchar 5 */
  society varchar(5),
  /* 4: 閲覧ファイル名  f_name  varchar 100 */
  f_name varchar(100),
  /* 5: 分冊  category  varchar 100 */
  category varchar(100),
  /* 6: 大分類  type  varchar 100 */
  type varchar(100),
  /* 7: リモートホストアドレス  remote_addr varchar 200 環境変数　REMOTE_ADDR */
  remote_addr varchar(200),
  /* 8: リモートホスト名  remote_host varchar 200 環境変数　REMOTE_HOST */
  remote_host varchar(200),
  /* 9:  ユーザエージェント  user_agent  varchar 100 環境変数　HTTP_USER_AGENT */
  user_agent varchar(100),
  /* 10:  リクエストURI uri varchar 500 */
  uri varchar(500),
  /* 11:  ブラウザ  browser varchar 50 */
  browser varchar(50),
  /* 12:  クライアントOS  os  varchar 500 */
  os varchar(500),
  /* 13:  閲覧状態  err int   "ファイル閲覧時：1 ログイン成功時：2" */
  err integer,
  /* 14:  ホスト名  host  varchar 200 ホスト名 */
  host varchar(200),
  /* 15:  アクセス種別  access  varchar 1 "・通常ユーザ認証時 ： 0 ・サイトライセンス認証時 ： 1 ・サイトライセンス認証時＋ユーザ認証 ： 2" */
  access varchar(1),
  /* 16:  あらまし（Summary)閲覧  summary_view  varchar 1 あらまし閲覧時　：　1 */
  summary_view varchar(1),
  /* 17:  archive閲覧フラグ table_of_contents_view  varchar 1 archive閲覧時：1 */
  table_of_contents_view varchar(1),
  /* 18:  最新号閲覧フラグ  index_view  varchar 1 最新号閲覧時：1 */
  index_view varchar(1),
  /* 19:  環境変数：X-Forwarded-For x_forwarded_for varchar 200 環境変数：X-Forwarded-For */
  x_forwarded_for varchar(200)
);
