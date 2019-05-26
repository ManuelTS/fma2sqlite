#!/bin/bash
# Converts the Foundational Model of Anatomy (FMA) .csv file into a minimal SQLite database. Dependency check:
[[ ! -f $1 ]] && echo "File \"$1\" not found, program aborted." && exit 1
for progi in {sqlite3,perl,sed}; do # Check required programs
    [[ ! -x "$(command -v $progi)" ]] && echo "$progi required, install with \"sudo apt install -y $progi\"" && exit 1
done

echo "" && echo "Preprocessing..."
read -r columnCount < $1 # Cannot be done via pure line reading, since hidden line breaks are in the CSV, do it via first line header , count!
columnCount=$(echo "$columnCount" | tr -cd , | wc -c) # Strip everything but the commas, and then count number of characters left
(( columnCount += 1 ))
sed -i -r ':a;N;$!ba;s/\n/,/g' $1 # Replace all line breaks with commas
perl -pi -w -E 'BEGIN{$/=\1}; y/,/;/ if $in; $in = ! $in if $_ eq "\""' $1 # Replace all commas in quotes with semicolons
sed -i -r ':a;s/\|/;/;ta' $1 # Replace all pipes with semicolons

fc=${1##*/} # fc=file context
fc=${fc%.*}
fc=(${1%/*} $fc"_dump.sql" $fc".sqlite") # 0=path, 1=dump.ending, 2=dbName.ending
fc=("${fc[0]}/${fc[1]}" "${fc[0]}/${fc[2]}")
rm -f ${fc[1]} # Delete old sqlite, dump is overwritten

echo "Creating database dump file..." && echo "BEGIN TRANSACTION; DROP TABLE IF EXISTS fma; DROP TABLE IF EXISTS synonyms; DROP TABLE IF EXISTS definitions; DROP TABLE IF EXISTS hierarchy; CREATE TABLE fma (pk INTEGER PRIMARY KEY, name TEXT NOT NULL); CREATE TABLE synonyms (id INTEGER NOT NULL, synonym TEXT NOT NULL, type INTEGER NOT NULL); CREATE TABLE definitions (id INTEGER NOT NULL, definition TEXT NOT NULL); CREATE TABLE hierarchy (id INTEGER NOT NULL, parent INTEGER NOT NULL);" > ${fc[0]} # Create dump File

columnIndex=0 # of current cell in CSV
id=0 # of current anatomy

while read -d ',' column; do # Read words delimited by comma
    if (( columnIndex >= columnCount )); then # Skip first line
        mod=$(( columnIndex % columnCount ))
        case "$mod" in # Adjusted indicies to line length denoted by , count
            "0") # id
                id=${column##*fma} # Remove URL prefix
                id=${id#"${id%%[!0]*}"} # Remove leading zeros
                [[ $id =~ [a-zA-Z] ]] && id=0 # If ID is not an integer, no other entries will be made for this anatomy
                columnIndex=$(( columnCount * 2 )) # to avoid maximum value overflow
                ;;
            "1" | "2" | "142") # prefLabel, synonyms, non_english_equivalent
                column=${column//;/, }
                column=${column//\.,/}
                type=1 # synonyms, non_english_equivalent, synonym,
                (( mod == 1 )) && type=0 # prefLabel
                (( id != 0 )) && [[ -n "$column" ]] && echo "INSERT INTO synonyms (id, synonym, type) VALUES ($id, \"${column//\"}\", $type);" >> ${fc[0]}
                ;;
            "3") # definitions
                column=${column//;/, }
                column=${column//\.,/}
                (( id != 0 )) && [[ -n "$column" ]] && echo "INSERT INTO definitions (id, definition) VALUES ($id, \"${column//\"}\");" >> ${fc[0]}
                ;;
            "7") # parents
                column=${column##*fma} # in FMA 5.0.0 id 85802 had a malformed parent led to the following check:
                column=${column#"${column%%[!0]*}"} # Remove leading zeros
                (( id != 0 )) && [[ $column =~ ^[0-9]+$ ]] && echo "INSERT INTO hierarchy (id, parent) VALUES ($id, $column);" >> ${fc[0]} # if integer
                ;;
            "165") # preferred name
                (( id != 0 )) && [[ -n "$column" ]] && echo "INSERT INTO fma (pk, name) VALUES ($id, \"${column//\"}\");" >> ${fc[0]}
                ;;
        esac
    fi
    (( columnIndex += 1 ))
done < $1

echo "COMMIT; VACUUM;" >> ${fc[0]}
sqlite3 ${fc[1]} < ${fc[0]}
echo "Generated \"${fc[1]}\" database." && echo ""
unset fc
