# Rosetta Install Protocol

1. [Rosetta Commons License and Download](https://www.rosettacommons.org/software/license-and-download)からLicenseを取得
    - 学生はAcademic Licenseからfreeで取得可能
    - "Start Here" からLicenseを取得する
    - 成功した場合にユーザー名とパスワードが送られてくる

1. ダウンロードページからLinux版をダウンロード
    - source + binary 版のみ起動確認済み

1. open MPIのインストール
    - Rosettaを並列でランするために必要である

    ```bash
    # コンパイラ準備
    $ sudo apt install build-essensial gfortran
    # インストール
    $ wget https://www.open-mpi.org/software/ompi/v4.1/downloads/openmpi-4.1.4.tar.gz --no-check-certificate
    $ tar -zxvf openmpi-4.1.4.tar.gz
    $ cd openmpi-4.1.4
    $ ./configure --prefix=/usr/local/openmpi-4.1.4 CC=gcc CXX=g++
    $ sudo make -j[cpuコア数] all 2>&1 | tee make.log
    $ sudo make -j[cpuコア数] install 2>&1 | tee install.log
    ```

    必要に応じてPATHを通す

    ```bash:bashrc
    MPIROOT=/usr/local/openmpi-4.1.4
    export PATH=$MPIROOT/bin:$PATH
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$MPIROOT/lib
    export MANPATH=$MANPATH:$MPIROOT/share/man
    ```

1. Rosettaのインストール
    参照: https://qiita.com/Ag_smith/items/0e73d6d10e0b35c3f6d5
    - Serial版をインストールしてからmpi版をインストールする

    ```bash
    $ tar -zxvf rosetta_bin_linux_3.13_bundle.tgz
    $ mv <rosetta file> ~/rosetta_3.13
    $ cd rosetta_3.13/main/source
    $ sudo CC=gcc CXX=g++ ./scons.py -j[cpuコア数] mode=release bin
    $ sudo CC=gcc CXX=g++ ./scons.py -j[cpuコア数] mode=release extras=mpi bin
    ```

1. PyMOLのインストール
    - タンパク質構造の可視化ソフト。ドッキング後解析に必須。バイナリ版は30日で有料版を要求されるため、オープンソース版をインストールする。
    - Windows版はPythonのバージョンが変わるたびに入れなおす必要がある。以下のページに従う(https://qiita.com/hnishi/items/5e5e1fd4902fbe809e73 )。

    ```bash
    $ sudo apt install freeglut3-dev tcl8.6-dev tk8.6-dev libmsgpack-dev libpng-dev libfreetype6-dev $ libglm-dev libglew-dev python3-pyqt5.qtopengl python3-pip libxml2-dev libnetcdf-dev
    $ git clone https://github.com/schrodinger/pymol-open-source.git 
    $ git clone https://github.com/rcsb/mmtf-cpp.git 
    $ mv mmtf-cpp/include/mmtf* pymol-open-source/include/
    $ cd pymol-open-source
    $ prefix=$HOME/pymol-open-source-build
    $ modules=$prefix/modules
    $ export CPPFLAGS="-std=c++0x"
    $ python3 setup.py build install --home=$prefix --install-lib=$modules --install-scripts=$prefix
    $ cd /opt/pymol-open-source/modules/pymol
    $ ln -s _cmd.cpython-<python-version>-x86_64-linux-gnu.so _cmd.so # pymol python API に必要
    ```

    - --glutオプションを付けないとエラーを吐く場合がある
    - pythonモジュールとしてのpymolを使用したい場合は、pymol/modulesにPYTHONPATHを通す
    - Docker内でビルドする際に、ft2build.hが見つからないエラーが起こる場合は、CPATHに`/usr/include/freetype2`を追加しておく
    - C++のバージョンを固定する必要がある場合は`0x`を`17`などバージョン番号に変える

1. ConformerGeneratorのインストール
    - Rosettaはドッキング中にリガンドの配座を固定しているため、先に複数配座を生成して用意しておく必要がある
    - [Meiler Lab](http://servers.meilerlab.org/index.php/bclcommons/show/b_apps_id/1) からライセンスを取得してLinux版をインストール
    - 起動には`bcl.license`のファイルをディレクトリに置いておくことが必要

## Dockerを使う場合
本レポジトリの`Docker`ディレクトリ内に以下のファイルを揃えてビルドする
- rosetta_bin_linux_<version>_bundle.tgz
- bcl-4.3.0-Linux-x86_64.sh
- bcl.license
