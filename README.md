# IEICE Paper Meta Data Preprocessor 2

本スクリプトでは，論文誌検索システムのデータと論文誌投稿システムのデータを照合し，著者データに所属，会員番号の情報を追加します．また，論文誌検索システムのログから，論文の参照回数をカウントします．

## インストール方法

本スクリプトは git コマンド，ruby (1.9.2以上)，sqlite3 (3.7以上) を利用します．

### Windows 環境での RVM のセットアップ

以下，Windows での Ruby 実行環境のセットアップ手順です．

cygwin の最新版をインストールします．RVM ではユーザのホームディレクトリに ruby 関連のコマンドをインストールするので，ユーザ名にスペースが含まれる場合，個別に対応が必要になります．できればスペースを含まないユーザ名のユーザを作成してください．

http://www.cygwin.com/

1. setup.exe をダウンロードして実行します．
2. "Choose A Download Source" では，"Install from Internet" を選択します．
3. "Select Root Install Directory" では，デフォルトの C:\cygwin のままとし，All Users に対してインストールします．
4. "Select Local Package Directory" では，ダウンロードしたパッケージのキャッシュディレクトリを指定します．適当に空き容量のあるフォルダを指定してください．
5. "Select Your Internet Connection" では，Proxy 等を利用していない場合は "Direct Connection" を選択してください．
6. "Choose A Download Site" では，国内のサイトを適当に選択してください (例: http://ftp.jaist.ac.jp)．
7. "Select Packages" では，必要なパッケージを指定します．RVM では，git, curl 等のコマンドラインツールを利用するので，以下の項目が有効になっているか（Skip ではなくバージョン番号が左端に表示されているか）確認してください．

* Databases
    * libsqlite3-devel (3.7.3)
    * libsqlite3_0 (3.7.3)
    * sqlite3 (3.7.3)
* Devel
    * gcc
    * gcc-core
    * git
    * git-completion
    * libtool
    * make
    * readline
* Editors
    * vim
    * vim-common
* Libs
    * zlib
    * zlib-devel
* Net
    * ca-certificates
    * curl
    * libcurl-devel
    * openssl
    * openssh
* Utils
    * patch

SQLite は最新の3.7.13ではなく，3.7.3をインストールしてください (2012-11現在)．3.7.13 では .import コマンドで " (doboule-quotes) の扱いが変わるため，データ中に " を含む場合，区切り文字 (Tab等) が正しく認識されなくなります．

インストール完了後，Cygwin Terminal を実行します．

ホームディレクトリが作成されたら，以下のコマンドを実行して RVM をインストールします (https://rvm.io/rvm/install/ 参照)．

    $ curl -L https://get.rvm.io | bash -s stable --ruby

以下の設定を ~/.bashrc に追加します (~/.bash_profile に追加されているものを ~/.bashrc に追加)．

    $ vi $HOME/.bashrc
    [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

あと，もし shell が /bin/bash になっていない場合は修正しておく(主にマルチユーザの場合)．

    $ env | grep SHELL
    /bin/sh -> /bin/bash なら OK
    $ mkpasswd -l > /etc/passwd
    $ vi /etc/passwd
    ->該当ユーザ名の shell を /bin/bash に修正

--ruby オプションを指定していれば ruby がインストールされるはずですが，以下のコマンドで no ruby と表示される場合は，手動でインストールしてください．

    $ which ruby
    which: no ruby in (....)

    $ rvm install 1.9.3
    $ rvm use 1.9.3

これで ruby のインストールは完了です．あと，sqlite3 という Ruby のパッケージを利用しますので，それもインストールします．

    $ gem install sqlite3

### Linux (debian squeeze) での RVM のセットアップ

以下，Linux (debian squeeze) の場合の Ruby 実行環境のセットアップ手順です．

RVM が依存するパッケージをインストールします．

    % sudo aptitude install build-essential openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison subversion

以下のコマンドを実行して RVM をインストールします (https://rvm.io/rvm/install/ 参照)．

    $ curl -L https://get.rvm.io | bash -s stable --ruby

--ruby オプションを指定していれば ruby がインストールされるはずですが，以下のコマンドで no ruby と表示される場合は，手動でインストールしてください．

    $ which ruby
    ruby not found

    $ rvm install 1.9.3
    $ rvm use 1.9.3

これで ruby のインストールは完了です．あと，sqlite3 という Ruby のパッケージを利用しますので，それもインストールします．

    $ gem install sqlite3

### ieice-scripts2 のダウンロード

以下のコマンドでスクリプトを手元の環境にコピーします．

    % git clone https://github.com/toyokazu/ieice-scripts2.git
    % cd ieice-scripts2

以上でインストールは完了です．

## ieice-scripts2 の利用方法

以下 ieice-scripts2 に含まれるコマンド群の利用方法について説明します．

### 投稿論文管理システムならびに論文誌検索システムデータ名寄せコマンドの利用手順

まず設定ファイルを作成します．

    % cp ./config/tsv_files.yml.sample ./config/tsv_files.yml
    % cp ./config/database.yml.sample ./config/database.yml
    % vi ./config/tsv_files.yml
    tsv_submissions: ["wabun-a",
      "wabun-b",
      "wabun-c",
      "wabun-d",
      "trans-a",
      "trans-b",
      "trans-c",
      "trans-d"]
    tsv_tran_ja: "tran_ja"
    tsv_tran_en_ja: "tran_en_ja"
    tsv_tran_en: "tran_en"
    
    % vi ./config/database.yml
    database: papers.sqlite3

次に作業フォルダを作成します．

    % mkdir files
    % mkdir logs

設定ファイルには入力ファイル，出力ファイルのファイル名を指定します．入力ファイルは論文誌ごとに1つずつあると想定しています．また出力ファイルは，和文誌の日本語データ（final_ja.txt），和文誌の英語データ（final_en_ja.txt），英文誌の英語データ（final_en.txt）を出力することを想定しています．

入力ファイル，出力ファイルは files ディレクトリ以下で読み出し，書き込みされるため，ディレクトリを作成し，ここにファイルをコピーしてください．なお，ExcelファイルからTSVを作成した場合，文字コードがShiftJISになっています．その場合，例えば，以下の nkf.rb コマンドで ShiftJIS から Unicode UTF-8 に変換しておく必要があります．

    % ./script/nkf.rb -Sw files/output_a_j.txt > files/output_a_j-utf8.txt

この変換処理は preproc.rb の処理に含まれています．preproc.rb は import_databases.rb または import_databases.sh から呼び出されます．

変換する対象ファイル名 (wabun-X_YYYYMMDD.txt, trans-X_YYYYMMDD.txt) については，config/preproc.yml に指定します．config/preproc.yml.sample をコピーして利用してください．postfix (YYYYMMDD) についてはコマンド実行時に自動的に実行日時の値（例: 20121214) が付与されます．明示的に postfix を指定したい場合は，コマンドの後ろに YYYYMMDD を指定してください．

準備ができたら，以下のようにコマンドを実行します．

    % ./script/import_databases.rb 2> logs/import_logs.txt
    % ./script/output_merged_tsv.rb ja 2> logs/ja_logs.txt
    % ./script/output_merged_tsv.rb en 2> logs/en_logs.txt

明示的に処理したいファイルの日付 (postfix) を指定したい場合は，下記のように実行します．

    % ./script/import_databases.rb 20121214 2> logs/import_logs.txt
    % ./script/output_merged_tsv.rb ja 20121214 2> logs/ja_logs.txt
    % ./script/output_merged_tsv.rb en 20121214 2> logs/en_logs.txt

Windows の場合，import_databases.rb の代わりに import_databases.sh を利用してください．

    % ./script/import_databases.sh 2> logs/import_logs.txt
    % ./script/import_databases.sh 20121214 2> logs/import_logs.txt

以上で，files ディレクトリ以下に所属情報をマージした出力データ (tran_ja_YYYYMMDD.txt, tran_en_ja_YYYYMMDD.txt, tran_en_YYYYMMDD.txt) が出力されます．入力ファイル名，出力ファイル名は同様に config/preproc.yml に指定できます．ファイル名の

ログファイルをWindowsで読みやすくするためには ShiftJIS への変換が必要です．

    % ./script/nkf.rb -WsLw logs/ja_logs.txt > logs/ja_logs-win.txt

なお，生成したファイルを一旦削除して生成しなおすには，

    % ./script/clear_databases.rb

で削除を行います．Windows の場合は

    % ./script/clear_databases.sh

を利用してください．

### preproc.rb

投稿論文管理システムからの入力ファイル (TSV, ShiftJIS, Excel から生成) の文字コードを変換し (ShiftJIS -> UTF8)，volume1 の項目から paper_id を生成して付与します．import_databases.rb から呼び出されます．

### import_databases.rb

以下のような処理を実行します．

* データベースのスキーマ生成
* 投稿管理システムのデータ (submissions) に paper_id を付与して SQLite3 にインポート
* 論文誌検索システムのデータ (metadata) を SQLite3 にインポート
* データベースのインデックス生成

内部で，generate_paper_id.rb, createtable_xxx.sql, import_and_convert_xxx.rb を呼び出しています．Windows の場合は Cygwin で Ruby の Shell が想定どおりに動作しないので，import_databases.sh を利用してください．

### import_and_convert_xxx.rb

tsv_files.yml に指定されたファイル名のデータをSQLite3にインポートするためのSQL文を生成します．

### output_merged_tsv.rb

* import_databases.rb で生成したDBから，著者名リストに所属をマージしたTSVを出力します．
* オプションに ja または en を指定することで，和文論文誌，英文論文誌それぞれのデータを出力します．なお，和文論文誌データ処理時には，和文論文誌の英文データについても同時に出力します．

### 入出力フォーマット

まず，入力ファイルのフォーマットについて述べます．

#### 入力フォーマット (論文誌投稿システムから取得するデータのフォーマット)

上述のとおり，Excel から TSV, ShiftJIS に出力し，nkf で Unicode UTF-8 に変換してから利用します．

    # 0: id1　　　　受付番号の西暦部分
    # 1: id2　　　　受付番号4ケタ
    # 2: tmp_id1
    # 3: tmp_id2
    # 4: tmp_id3
    # 5: tmp_id4
    # 6: tmp_id5
    # 7: submission_id　受付番号
    # 8: soccode  特集号コード
    # 9: title_j     　和文タイトル
    # 10: title_e 　　　英文タイトル
    # 11: volume1　掲載号
    # 12: inputnum 著者順番
    # 13: name_j　　著者名（日本語）
    # 14: name_e 　著者名（英語）
    # 15: membernum　会員番号
    # 16: orgcode　　機関コード
    # 17: name_j　　　機関コード名（日本語）
    # 18: name_e　　 機関コード名（英語）

#### 出力フォーマット (論文誌検索システムから取得するデータのフォーマットと同じ)

TSV, Unicode UTF-8 で出力します．前述のとおり，和文誌の日本語データ（final_ja.txt），和文誌の英語データ（final_en_ja.txt），英文誌の英語データ（final_en.txt）の３つのファイルが出力されます．

    # 0: id, 文献ID
    # 1: vol, 巻 (年, ソサイエティ) Vol
    # 2: num, 号 Num
    # 3: s_page, 開始ページ番号
    # 4: e_page, 終了ページ番号
    # 5: date, 発行年月
    # 6: title, タイトル【検索用】
    # 7: author, 著者【検索用】
    # 8: abstract, 概要【検索用】
    # 9: keyword, キーワード（全角カンマ区切り）【検索用】
    # 10: special, 特集号名
    # 11: category1, 論文種別 (論文, レター)
    # 12: category2, 専門分野分類コード（大項目）
    # 13: category3, 専門分野分類名（大項目）※目次の見出しに利用
    # 14: disp_title, タイトル【表示用】
    # 15: disp_author, 著者名【表示用】
    # 16: disp_abstract, 概要【表示用】
    # 17: disp_keyword, キーワード（全角カンマ区切り）【表示用】
    # 18: err_fname, 正誤Web PDF
    # 19: err_comm, 正誤内容
    # 20: nodisp_comm, 非表示
    # 21: delflg, 削除
    # 22: mmflg, MM情報
    # 23: l_auth_pdf, レター著者PDF
    # 24: l_auth_link, レター著者内容
    # 25: err_1, 訂正元ファイル名
    # 26: err_2, 訂正先ファイル名
    # 27: recommend, 推薦論文
    # 28: 目次脚注正誤PDF
    # 29: comment, 名寄せ結果

なお，名寄せ後の著者名【表示用】は以下の様な出力になります(【検索用】は元のままです)．

    著者氏名1（著者会員番号1）＠著者所属1；著者氏名2＠著者所属2；著者氏名3（著者会員番号3）＠著者所属3；著者氏名4；著者氏名5（著者会員番号5）；...

名寄せに失敗した場合は，その原因を標準エラー出力に出力した上で，元データの著者リストをそのまま出力します．ただし区切り文字は "＠" から "；" に変更します．

投稿論文管理システムから取得できるデータは，基本的に vol, no, pp の情報で照合できるため，これらの情報がない場合は名寄せしません．

名寄せの結果は最後の項目に出力されます．以下に出力例を示します．

    COMPLETED: paper_id，著者リストともに照合できたもの
    DIFF_NUM_SUBMIT: submissions の著者数と，metadata の著者数が異なるもの
      e.g., DIFF_NUM_SUBMIT：【meta_author1＠meta_author2＠meta_author3】：【submit_author1＠submit_author2＠submit_author3＠submit_author4】：【submit_author1＠affiliation1；submit_author2（membernum2）＠affiliation2；submit_author3（membernum3）＠affiliation3；submit_author4（membernum4）＠affiliation4】
    DIFF_OTHER_SUBMIT: submissions の著者順，著者名の漢字などが metadata のものと異なるもの
      e.g., DIFF_OTHER_SUBMIT：【meta_author1＠meta_author2＠meta_author3】：【submit_author1＠submit_author2＠submit_author3】：【submit_author1＠affiliation1；submit_author2（membernum2）＠affiliation2；submit_author3（membernum3）＠affiliation3】
    DIFF_NUM_META_JA_EN: 'ja' metadata と 'en' metadata の著者数が異なるもの
      e.g., DIFF_NUM_META_JA_EN：【ja_meta_author1＠ja_meta_author2＠ja_meta_author3】：【en_meta_author1＠en_meta_author2＠en_meta_author3】：【】
    NO_MATCH: submissions のデータがないもの（古い文献）

### 論文誌検索システムでの論文のダウンロード回数集計スクリプト (1) の利用手順

DB上でインタラクティブにデータを分析する場合の方法です．件数が多くなるとインポートに非常に時間がかかるので，比較的少ない件数（1ヶ月分程度）のデータを分析する場合に利用してください．以下のコマンドで SQLite3 にログファイルをインポートします．

    % ./script/import_logs.rb 2> logs/log_import_log.txt
    % ./script/count_logs.rb 2> logs/log_count_log.txt

「ファイル名|ダウンロード回数」というフォーマットで files/downloads_count.txt に結果が出力されます．

なお，生成したファイルを一旦削除して生成しなおすには，

    % ./script/clear_logs.rb

で削除を行います．


### 論文誌検索システムでの論文のダウンロード回数集計スクリプト (2) の利用手順

TSV ファイルのまま入力ファイルを分析し，結果を CSV 形式で出力します．
入力ファイルは設定ファイル count_log_files.yml で指定します．

    % cp ./config/count_log_files.yml.sample ./config/count_log_files.yml
    % vi ./config/count_log_files.yml
    log_files: search_logs/search_log_*.bak
    output: downloads_count.txt

log_files で入力となるログファイル群を指定し，output で出力ファイル名を指定します．入力ファイルの指定にはワイルドカードなど，Ruby の Dir クラスで利用可能なパターン指定が利用できます．

class Dir
http://doc.ruby-lang.org/ja/1.9.3/class/Dir.html


入力ファイルを指定した上で，まず，以下のコマンドにより入力ファイルの文字コードを変換します．

    % ./script/preproc_logs.rb

次に，以下のコマンドで UTF-8 形式のファイルの論文参照回数をカウントし，出力ファイルに出力します．処理中のファイル名がエラー出力に提示されるので，どこまで処理されたか確認できます．

    % ./script/count_log_files.rb

なお，途中で停止した場合，処理完了したファイルまでのカウント結果を出力ファイルに出力します．処理開始時に出力ファイルが存在する場合は，その結果を反映した上で，続きをカウントします．そのため，処理中断時に残ったファイルがわかっていれば，続きから処理することができます．なお，現在の実装では，Bot と思われるクライアントからのアクセスは無視しています．

#### 入力フォーマット（タブ区切り）

    # 0: 項番  id  int8    
    # 1: 閲覧日時  log_date  varchar 10  yyyymmdd hhmmss
    # 2: ログインユーザ  user_id varchar 100 "環境変数　REMOTE_USER ID or メールアドレス"
    # 3: 会員ソサイエティ  society varchar 5 
    # 4: 閲覧ファイル名  f_name  varchar 100 
    # 5: 分冊  category  varchar 100 
    # 6: 大分類  type  varchar 100 
    # 7: リモートホストアドレス  remote_addr varchar 200 環境変数　REMOTE_ADDR
    # 8: リモートホスト名  remote_host varchar 200 環境変数　REMOTE_HOST
    # 9:  ユーザエージェント  user_agent  varchar 100 環境変数　HTTP_USER_AGENT
    # 10:  リクエストURI uri varchar 500 
    # 11:  ブラウザ  browser varchar 50  
    # 12:  クライアントOS  os  varchar 500 
    # 13:  閲覧状態  err int   "ファイル閲覧時：1 ログイン成功時：2"
    # 14:  ホスト名  host  varchar 200 ホスト名
    # 15:  アクセス種別  access  varchar 1 "・通常ユーザ認証時 ： 0 ・サイトライセンス認証時 ： 1 ・サイトライセンス認証時＋ユーザ認証 ： 2"
    # 16:  あらまし（Summary)閲覧  summary_view  varchar 1 あらまし閲覧時　：　1
    # 17:  archive閲覧フラグ table_of_contents_view  varchar 1 archive閲覧時：1
    # 18:  最新号閲覧フラグ  index_view  varchar 1 最新号閲覧時：1
    # 19:  環境変数：X-Forwarded-For x_forwarded_for varchar 200 環境変数：X-Forwarded-For

#### 出力フォーマット (カンマ区切り)

    論文ファイル, 参照回数
    j80-b_1_1.pdf, 1351

## License (MIT License)
Copyright (C) 2012 by Toyokazu Akiyama.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
