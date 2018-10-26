#!/usr/bin/env bash
# First run eaf2txt.py to get a txt file
# Then run selcha2clean.sh to get a clean transcription, number of words and number of syllables
LC_CTYPE=C
#########VARIABLES
#Variables that have been passed by the user
SELFILE=$1
ORTHO=$2
#########
#Make them work within the vm by appending the data directory
DATA_DIR=/vagrant
SELFILE="$DATA_DIR/$SELFILE"
ORTHO="$DATA_DIR/$ORTHO"
DIRNAME=$(dirname "${ORTHO}")
CLEAN_TRANSCRIPT=$DIRNAME"/clean_transcript.txt"
PHONEMIZED=$DIRNAME"/phonemized.txt"

echo "Cleaning $SELFILE"


### HANDLING REPETITIONS ###
###    word [x2]         ###
### or <phrase> [x2]     ###
cut -f 4 -d$'\t' $SELFILE |
sed "s/\[ \+/\[/g" |
sed "s/ \+\[/\[/g" |
sed -r "s/\[X([0-9]+)/\[x\1/g" |
sed "s/> \+/>/g" > ${CLEAN_TRANSCRIPT}.tmp

python -c "
import re
for line in open(\"${CLEAN_TRANSCRIPT}.tmp\"):

    if '<' in line and '>' in line:
        newline = re.sub('<(.*)>\[x([0-9]+)\]', r'\1 \2', line)
        if newline != line:
            n = int(newline[-2:-1])
            newline = newline[:-2]*n
        else:
            newline = line
    else:
        reg = re.sub('(.*)\[x([0-9]+)\]', r'\1\2', line)
        newline=[]
        for word in reg.split():
            if word[-1].isdigit():
                newline += [word[:-1]]*int(word[-1])
            else:
                newline += [word]
        newline = ' '.join(newline)
    newline = newline.rstrip() # Remove all \newline and let the print function puts only one of them
    print(newline)
" > ${CLEAN_TRANSCRIPT}2.tmp


### CLEAN human-made inconsistencies

cat ${CLEAN_TRANSCRIPT}2.tmp |
sed "s/\_/ /g" |
sed '/^0(.*) .$/d' |
sed  's/\..*$//g' | #this code deletes bulletpoints (Û+numbers
sed  's/\?.*$//g' |
sed  's/\!.*$//g' |
tr -d '\"' |
tr -d '\^' | #used to be identical to previous line
tr -d '\/' |
sed 's/\+/ /g' |
tr -d '\.' |
tr -d '\?' |
tr -d '!' |
tr -d ';' |
tr -d '\<' |
tr -d '\>' |
tr -d ','  |
tr -d ':'  |
tr -d '~'  |
sed 's/&=[^ ]*//g' |
sed 's/&[^ ]*//g' |  #delete words beginning with & ##IMPORTANT CHOICE COULD HAVE CHOSEN TO NOT DELETE SUCH NEOLOGISMS/NONWORDS
sed 's/\[[^[]*\]//g' | #delete comments
#sed 's/([^(]*)//g' | #IMPORTANT CHOICE -- UNCOMMENT THIS LINE AND COMMENT OUT THE NEXT TO DELETE MATERIAL NOTED AS NOT PRONOUNCED
sed 's/(//g' | sed 's/)//g' | #IMPORTANT CHOICE -- UNCOMMENT THIS LINE AND COMMENT OUT THE PRECEDING TO REMOVE PARENTHESES TAGGING UNPRONOUNCED MATERIAL
sed 's/xxx//g' |
sed 's/www//g' |
sed 's/XXX//g' |
sed 's/yyy//g' |
sed 's/0*//g' |
sed 's/[^ ]*@s:[^ ]*//g' | #delete words tagged as being a switch into another language
#sed 's/[^ ]*@o//g' | #delete words tagged as onomatopeic
sed 's/@[^ ]*//g' | #delete tags beginning with @ IMPORTANT CHOICE, COULD HAVE CHOSEN TO DELETE FAMILIAR/ONOMAT WORDS
sed "s/\'/ /g"  |
tr -s ' ' |
sed 's/ $//g' |
sed 's/^ //g' |
sed 's/^[ ]*//g' |
sed 's/ $//g' |
#sed '/^$/d' | # We don't want to remove end lines here
sed '/^ $/d' |
sed 's/\^//g' |
sed 's/\-//g' |
sed 's/\[\=//g' | # We observed [= occurrences that we're not interested in. Has to be careful about that one
sed 's/[0-9]//g' | # We remove all of the remaining numbers
#tr -d '\t' |
awk '{gsub("\"",""); print}' > ${CLEAN_TRANSCRIPT}3.tmp



# Phonemize the clean version
phonemize ${CLEAN_TRANSCRIPT}3.tmp -o ${PHONEMIZED}.tmp -s -

## Append number of syllables to the phonemized transcription
cat ${PHONEMIZED}.tmp | awk -F- '{print $0"\t"NF-1}' > ${PHONEMIZED}

## Append number of words to the clean transcription
cat ${CLEAN_TRANSCRIPT}3.tmp | awk -F'[ ]' '{print $0"\t"NF}' > ${CLEAN_TRANSCRIPT}

## Concatenate those 2 files
python -c "
import re
transcript_f = open(\"${CLEAN_TRANSCRIPT}\")
phonemized_f = open(\"${PHONEMIZED}\")

for transcript_l in transcript_f.readlines():
    nb_words = transcript_l.split('\t')[1]
    if int(nb_words) == 0:
        x=2
        print(\"\t0\t\t0\")
    else:
        phoneme_l = phonemized_f.readline()
        transcript_l = transcript_l.rstrip()
        phoneme_l = phoneme_l.rstrip()
        print(transcript_l+'\t'+phoneme_l)
" > $ORTHO.tmp

## Now we concatenate the original csv files and the clean ortho (by column)
### Extract everything except transcript column from the original file
cut -f1,2,3,5 -d$'\t' $SELFILE > ${ORTHO}2.tmp

### Concatenate the latter columns to the clean one contained in _tmp3.txt
paste -d$'\t' ${ORTHO}2.tmp ${ORTHO}.tmp > $ORTHO

##This is to process all the "junk" that were generated when making the
##changes from included to ortho.  For e.g., the cleaning process
##generated double spaces between 2 words (while not present in
##included)
sed -i -e 's/ $//g' $ORTHO
#
rm ${DIRNAME}/*.tmp
rm ${CLEAN_TRANSCRIPT}
rm ${PHONEMIZED}