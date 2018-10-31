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
elif [[ $system = "tocombosad" ]]; then
    sys_name="tocombo_sad"
elif [[ $system = "opensmile" ]]; then
    sys_name="opensmile_sad"
elif [[ $system = "lena_sad" ]]; then
    sys_name="lena_sad"

else
    echo "Please Specify the System you wish to evaluate."
    echo "Choose between ldc_sad, noiseme_sad, tocombosad and opensmile."
    exit
fi


# Set CWD to path of Dscore
cd $LDC_SAD_DIR

$BASEDIR/create_ref_sys.sh $audio_dir $sys_name true

echo "evaluating"
#$conda_dir/python score_batch.py /vagrant/data/${sys_name}_eval.df /vagrant/temp_ref /vagrant/temp_sys
# create /vagrant/results if it doesn't exist
echo "filename	DCF	FA	MISS" > $audio_dir/${sys_name}_eval.df
for lab in `ls $audio_dir/temp_sys/*.lab`; do
    base=$(basename $lab .lab)
    if [ ! -s $audio_dir/temp_ref/$base.lab  ]; then
        if [ ! -s $audio_dir/temp_sys/$base.lab ]; then
            echo $base"	0.00%	0.00%	0.00%" >> $audio_dir/${sys_name}_eval.df
        else
            echo $base"	25.00%	100.00%	0.00%" >> $audio_dir/${sys_name}_eval.df
        fi
    elif [ ! -s $audio_dir/temp_sys/$base.lab ] && [ -s $audio_dir/temp_ref/$base.lab ]; then
        echo $base"	75.00%	0.00%	100.00%" >> $audio_dir/${sys_name}_eval.df
    else
        $conda_dir/python score.py $audio_dir/temp_ref $lab | awk -v var="$base" -F" " '{if ($1=="DCF:") {print var"\t"$2"\t"$4"\t"$6}}' >> $audio_dir/${sys_name}_eval.df
    fi

done
# small detail: remove the commas from the output
sed -i "s/,//g" $audio_dir/${sys_name}_eval.df
echo "done evaluating, check $1/${sys_name}_eval.df for the results"
# remove temps
rm -rf $audio_dir/temp_ref $audio_dir/temp_sys

