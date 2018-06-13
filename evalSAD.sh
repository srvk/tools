#!/bin/bash
# Since the script is built to be launched outside of the vm, source
# the .bashrc which is not necessarily sourced!
source ~/.bashrc
conda_dir=/home/vagrant/anaconda/bin

# Absolute path to this script. /home/user/bin/foo.sh
SCRIPT=$(readlink -f $0)
# Absolute path this script is in. /home/user/bin
BASEDIR=`dirname $SCRIPT`
# Path to OpenSAT (go on folder up and to opensat)
#DSCOREDIR=$(dirname $BASEDIR)/dscore
LDC_SAD_DIR=$(dirname $BASEDIR)/ldc_sad_hmm


# data directory
audio_dir=/vagrant/$1
filename=$(basename "$audio_dir")
dirname=$(dirname "$audio_dir")
extension="${filename##*.}"
basename="${filename%.*}"

# check system to evaluate - either LDC, OpenSAT or "MySystem"
system=$2

if [[ $system = "ldc_sad" ]]; then
    sys_name="ldc_sad"
elif [[ $system = "noisemes" ]]; then
    sys_name="noisemes_sad"
elif [[ $system = "tocombo_sad" ]]; then
    sys_name="tocombosad"
elif [[ $system = "opensmile_sad" ]]; then
    sys_name="opensmile_sad"
elif [[ $system = "lena_sad" ]]; then
    sys_name="lena_sad"

else
    echo "Please Specify the System you wish to evaluate."
    echo "Choose between ldc_sad, noiseme_sad, tocombo_sad and opensmile_sad."
    exit
fi


# Set CWD to path of Dscore
#cd $DSCOREDIR
cd $LDC_SAD_DIR

# create temp dir and copy gold rttm inside it
mkdir $audio_dir/temp_ref

for wav in `ls $audio_dir/*.wav`; do
    base=$(basename $wav .wav)
    #cp $audio_dir/${base}.rttm /vagrant/temp_ref/${base}.rttm
    awk '{print $4" "($4+$5)" speech"}' $audio_dir/${base}.rttm > $audio_dir/temp_ref/${base}.lab
done

# create temp dir and copy system .lab inside it,
# while also converting them to .rttm
mkdir $audio_dir/temp_sys

for rttm in `ls $audio_dir/${sys_name}_*.rttm`; do
    base=$(basename $rttm .rttm)
    out=`echo $base | cut -d '_' -f 3-`
    #cp $rttm $audio_dir/temp_sys/$out
    awk '{print $4" "($4+$5)" speech"}' $rttm > $audio_dir/temp_sys/${out}.lab
done

# check that temp_sys is not empty, otherwise exit and remove it.
if [ -z "$(ls -A $audio_dir/temp_sys)" ]; then
    echo "didn't find any transcription from the system you specified. Please run the SAD before Evaluating."
    rm -rf $audio_dir/temp_sys $audio_dir/temp_ref
    exit
fi

## convert lab to rttm and remove labs
#echo "gathering all files to evaluate"
#sh /vagrant/toolbox/lab2rttm.sh /vagrant/temp_sys
#
#rm /vagrant/temp_sys/*.lab

# evaluate using score.py
# output of score.py is of this format: 
#   DCF: 0.00%, FA: 0.00%, MISS: 0.00%
#   DUR: 0.01 sec
#
echo "evaluating"
#$conda_dir/python score_batch.py /vagrant/data/${sys_name}_eval.df /vagrant/temp_ref /vagrant/temp_sys
# create /vagrant/results if it doesn't exist
echo "filename	DCF	FA	MISS" > $audio_dir/${sys_name}_eval.df
for lab in `ls $audio_dir/temp_sys/*.lab`; do
    base=$(basename $lab .lab)
    $conda_dir/python score.py $audio_dir/temp_ref $lab | awk -v var="$base" -F" " '{if ($1=="DCF:") {print var"	"$2"	"$4"	"$6}}' >> $audio_dir/${sys_name}_eval.df
    if [ ! -s $audio_dir/temp_ref/$base.lab  ]; then
        echo $base"	NA	NA	NA" >> $audio_dir/${sys_name}_eval.df
    elif [ ! -s $audio_dir/temp_sys/$base.lab ]; then
        echo $base"	75.00%	0.00%	100.00%" >> $audio_dir/${sys_name}_eval.df



    fi

done
# small detail: remove the commas from the output
sed -i "s/,//g" $audio_dir/${sys_name}_eval.df
echo "done evaluating, check $1/${sys_name}_eval.df for the results"
# remove temps
rm -rf $audio_dir/temp_ref $audio_dir/temp_sys

