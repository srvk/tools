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
LDC_SAD_DIR=$(dirname $BASEDIR)/ldc_sad_hmm

if [ $# -ne 1 ]; then
  echo "Usage: ldc_sad.sh <dirname>"
  echo "where dirname is the name of the folder"
  echo "containing the wav files"
fi
audio_dir=/vagrant/$1

# Check audio_dir to see if empty or if contains empty wav
bash $BASEDIR/check_folder.sh $audio_dir

# Set CWD as LDC_SAD_HMM
cd $LDC_SAD_DIR

# launch ldc
echo "using ldc_sad_hmm to perform Speech Activity Detecton"
$conda_dir/python perform_sad.py  -L $audio_dir $audio_dir/*.wav
echo "finished using ldc_sad_hmm. Please look inside /vagrant/data to see the output in *.lab format"

# move all files to name them correctly
for wav in `ls $audio_dir/*.wav`; do
    # retrieve filename and remove .wav
    base=$(basename $wav .wav)
    rttm_out=$audio_dir/ldc_sad_${base}.rttm
    grep ' speech' $audio_dir/${base}.lab | awk -v fname=$base '{print "SPEAKER" "\t" fname "\t" 1  "\t" $1  "\t" $2-$1 "\t" "<NA>" "\t" "<NA>"  "\t" $3  "\t"  "<NA>"}'   > $rttm_out
done

