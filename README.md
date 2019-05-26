# FMA 2 SQLite
A bash script converts at least the [FMA](http://si.washington.edu/projects/fma) CSV 5.0.0 from [Bipolar](http://bioportal.bioontology.org/ontologies/FMA) into a minimal SQLite database. Inspired by an [mhalle/fma-sqlite issue](https://github.com/mhalle/fma-sqlite/issues/2). The `FMA` file size is reduced from uncompressed ~47.1 MB in CSV to uncompressed ~ 15.8 MB in SQLite as many redundant and empty fields are excluded. A `dump.sql` file is created for easy recreation and portability, once the `.sqlite` database file is created and the program is finished, you can safely delete the `dump.sql` file.

# Requirements and Execution

## Requirements
Download a [FMA CSV file](http://bioportal.bioontology.org/ontologies/FMA), the latest ist suggested.

## Execution
On your command line execute:

```
bash fma2sqlite ./path_2_csv_file.csv
```
the result will be an minimal `SQLite` database.

# Database
The `FMA 5.0.0` database in the `dat/` directory is compressed with [7z](https://www.7-zip.org) for faster downloading.

## Structure
No foreign keys are used, since parents or entries referred to in the `fma` table may not exist during the insertion process.
```
CREATE TABLE fma (pk INTEGER PRIMARY KEY,
                  name TEXT NOT NULL);
CREATE TABLE synonyms (id INTEGER NOT NULL,
                       synonym TEXT NOT NULL,
                       type INTEGER NOT NULL); -- 0=preferred_Label, 1=synonym
CREATE TABLE definitions (id INTEGER NOT NULL,
                          definition TEXT NOT NULL);
CREATE TABLE hierarchy (id INTEGER NOT NULL,
                        parent INTEGER NOT NULL);
```

# Warning
Due to preprocessing, the script can only be ran once on a `.csv` file. Make a backup copy first!

As the break lines are inconsistent with the single anatomy datasets in `FMA 5.0.0 CSV`, the 'dump.sql' creation is only done via commas making the process very slow but reliable at least. Another inconsistency error in `FMA 5.0.0 CSV` was the dataset with the `FMA ID 85802`, which had an malformed parent entry. Malformed parents being not an integer ID are ignored. I already repored the error
```
Hello Bioporal,
in your FMA 5.0.0 CSV file the following entry is wrong:

http://purl.org/sig/ont/fma/fma85802,FMA attribute entity,,,false,,,http://www.w3.org/2002/07/owl#Thing,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,85802,,,,,,,,,,,,,,,,,,,,,,,,fma:fma85802,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

since the parent "http://www.w3.org/2002/07/owl#Thing" does not contain a valid FMA id. I guess some other errors are in other anatomy datasets too, since my automatic parsing threw some errors. I will just exclude this anatomy from my parsing and hope future releases will have the errors fixed.

Best,
Manuel T. Schrempf
```
Same applies for the following entry from `FMA 5.0.0 CSV`
```
http://purl.org/dc/terms/Agent,Agent,,,false,,,http://www.w3.org/2002/07/owl#Thing,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
```
which had no `FMA ID` whatsoever. A validation from [Bipolar](http://bioportal.bioontology.org/ontologies/FMA) before they make the [FMA](http://si.washington.edu/projects/fma) public would be beneficial and eradicate special error handling.
