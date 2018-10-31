#!/usr/bin/env bash

audio_dir=$1
model_prefix=$2
create_lab=$3

base_directory=$(echo "$audio_dir" | awk -F "/" '{print $2}')

if [ "$base_directory" != "vagrant" ]; then
    audio_dir=/vagrant/$1
fi

display_usage() {
    echo "Given a folder, and a model prefix, creates a folder that contains the reference transcriptions"
    echo "and another folder containing the predicted transcriptions."
    echo "usage: $0 [audio_dir] [model_prefix] [create_lab]"
    echo "  audio_dir       The directory that contains the audio files and the transcription."
    echo "  model_prefix    The model prefix (beginning of the files generated by the model)."
    echo "  create_lab      (Optional, true or false) Indicates whether to create .lab files in the reference folder."
	exit 1
	}

if ! [[ $# =~ ^(2|3)$ ]]; then
    display_usage
fi

if [ -z "$3" ]; then
    create_lab=false
fi

if ! [[ $model_prefix =~ ^(ldc_sad|noisemes_sad|tocombo_sad|opensmile_sad|lena_sad|
                            diartk_ldcSad|diartk_noisemesSad|diartk_tocomboSad|diartk_opensmileSad|
                            diartk_goldSad|goldSad|yunitator|lena)$ ]]; then
    echo "You're trying to create folder containing the reference transcriptions, and the predicted ones."
    echo "However, you specified a wrong tool name."
    echo "Please, check the name of the SAD/diarization tool."
    exit 1;
fi

# Create temp_ref folder
mkdir $audio_dir/temp_ref
for wav in `ls $audio_dir/*.wav`; do
    base=$(basename $wav .wav)
    cp $audio_dir/${base}.rttm $audio_dir/temp_ref/${base}.rttm
    # Sort rttm by onset
    sort --key 4 --numeric-sort $audio_dir/${base}.rttm -o $audio_dir/temp_ref/${base}.rttm
    # Change tabulations to white-spaces
    sed -i 's/\t/ /g' $audio_dir/temp_ref/${base}.rttm
    # Replace two or more occurrences of whitespace by just one
    sed -i 's/ \+/ /g' $audio_dir/temp_ref/${base}.rttm
    if [ $create_lab == true ]; then
        awk '{print $4" "($4+$5)" speech"}' $audio_dir/temp_ref/${base}.rttm > $audio_dir/temp_ref/${base}.lab
    fi
done

# Create temp_sys folder and copy all of the sys rttm inside of it
# Remove the model_prefix of it
mkdir $audio_dir/temp_sys
for rttm in `ls $audio_dir/${model_prefix}_*.rttm`; do
    base=$(basename $rttm)
    out=`echo $base | sed "s/${model_prefix}\_//g"`
    cp $rttm $audio_dir/temp_sys/$out
    if [ $create_lab == true ]; then
        awk '{print $4" "($4+$5)" speech"}' $rttm > $audio_dir/temp_sys/${out}.lab
    fi
done

# check that temp_sys is not empty, otherwise exit and remove it.
if [ -z "$(ls -A $audio_dir/temp_sys)" ]; then
    echo "Didn't find any transcription from the model prefix you specified. Please get the ${model_prefix}_my_file.rttm before"
    rm -rf $audio_dir/temp_sys $audio_dir/temp_ref
    exit
fi
