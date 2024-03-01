# Rosetta Ligand Docking with Rosettascripts

### ligand preparation

1. ligandファイル(**sdf**)を準備
    - PDBからのインストール、RDKitによる準備が可能。RDKitでは`Chem.SDWriter`にmolオブジェクトを読ませる
    - .pdbで準備すると以降回らないコードがある
    - SMILESから準備する場合は`scripts/smiles2sdf.py`で変換

1. ConformerGeneratorでligand conformerを生成
    - Rosettaはligandの配座を変形しないため、ConformerGeneratorを用いてあらかじめ複数の3次元配座を生成しておく。
    - `ConformarGenerator.sh`から実行可能。
    - リガンドの数が多い場合、途中でコードが止まることがある。`_conf`とついたファイルがないものに限定して逐次処理する(`ConformarGenerator.sh`に実装済み)


### protein preparation

1. pdbファイルの準備
    - PDBからダウンロードするのが最速
    - PyMOLを使用して余計な低分子(結晶化のための長鎖アルコールなど)、水、余計なサブタイプを除く。PyMOLを起動して`remove chain XXX(該当する分子の2or3字表記)`によってGUIベースで除去可能
    - もしくは`scripts/exract_ligand.py --chain XXX(PDBファイル内での特定コード) --remove_chain`から除ける

1. Relax
    - タンパク質をligand freeな状態でエネルギー最適化する
    - ligandを入れた状態での最適化も可能 (240228 induced fitとの違いは分かっていない)
    - `scripts/prepare_protein.sh`を参照

### Ligand Docking

- pythonコードを含むため仮想環境をアクティベートしておく
- `execute.sh` 参照
- とにかくオプションやxmlの選択肢が多いことに留意する。[Movers-RosettaScripts](https://new.rosettacommons.org/docs/latest/scripting_documentation/RosettaScripts/Movers/Movers-RosettaScripts)と[RosettaScripts](https://new.rosettacommons.org/docs/latest/scripting_documentation/RosettaScripts/RosettaScripts#rosettascript-sections_output_scorefxn)に記述があるが、目的意識をもって読まないとわけがわからなくなる。
- Virtual Screening の際は、複数段階のドッキングで探索範囲を狭めていく。`execute_vs.sh`参照

### 後解析
- `sc_parser.sh` で Rosetta score file を csv に変換する
- `select_score.py` で ファイルをスコア順で選定する
- PLIPでドッキングポーズの解析が可能