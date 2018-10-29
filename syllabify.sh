#!/usr/bin/env bash

### Script parameters
INPUT=$1
OUTPUT=$2
LANG=$3
VOWELS=$4
###

EXTENSION=${INPUT##*.}

display_usage() {
    echo "Given the path to a file (.tmp or .txt) containing sentences, a language (english, spanish or tzeltal),"
    echo "and a list of vowels, create a .syll file containing the original sentence, the phonemized/syllabified"
    echo "version of it, and the number of syllables present in the original sentence."
    echo "usage: $0 [input] [output] [language] [vowels]"
    echo "  input       The file path where to find the transcription. Has to be txt or tmp extension. (REQUIRED)"
    echo "  output      The output path. (REQUIRED)"
    echo "  language    The language of the transcription (OPTIONAL, default = english)"
    echo "  vowels      The list of vowels of the language if language set on spanish or tzeltal (OPTIONAL, default = aeiou)"
	exit 1
	}

if [ -z "$1" ] || [ -z "$2" ] || ! [[ $EXTENSION =~ ^(txt|tmp)$ ]]; then
    display_usage
    exit 1
fi

if [ -z "$3" ]; then
        echo "No languages has been provided. Setting this parameter to english."
        LANG="english"
fi

if [ "$3" == "spanish" ] || [ "$3" == "tzeltal" ]; then
    if [ -z "$4" ]; then
        echo "Language set on spanish or tzeltal. But no vowels have been provided."
        echo "Setting this parameter to aeiou"
        VOWELS="aeiou"
    fi
fi

if [ "$3" == "english" ]; then
    echo "Pĥonemizing $INPUT ..."
    # Phonemize the clean version
    phonemize ${INPUT} -o ${OUTPUT}.tmp -s -

    ## Append number of syllables to the phonemized transcription
    cat ${OUTPUT}.tmp | awk -F- '{print $0"\t"NF-1}' > ${OUTPUT}
fi

rm ${OUTPUT}.tmp