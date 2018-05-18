#!/bin/bash
# tocombo_sad.sh
# Since the script is built to be launched outside of the vm, source
# the .bashrc which is not necessarily sourced!
source ~/.bashrc
conda_dir=/home/vagrant/anaconda/bin

# run OpenSAT with hard coded models & configs found here and in /vagrant

# Absolute path to this script. /home/user/bin/foo.sh
SCRIPT=$(readlink -f $0)
# Absolute path this script is in. /home/user/bin
BASEDIR=`dirname $SCRIPT`
# Path to OpenSAT (go on folder up and to opensat)
TOCOMBOSADDIR=$(dirname $BASEDIR)/To-Combo-SAD

if [ $# -ne 1 ]; then
  echo "Usage: tocombo_sad.sh <dirname>"
  echo "where dirname is a folder on the host"
  echo "containing the wav files (/vagrant/dirname/ in the VM)"
  exit 1
fi

audio_dir=/vagrant/$1
filename=$(basename "$audio_dir")
dirname=$(dirname "$audio_dir")
extension="${filename##*.}"
basename="${filename%.*}"

# Check audio_dir to see if empty or if contains empty wav
bash $BASEDIR/check_folder.sh $audio_dir

# let's get our bearings: set CWD to path of OpenSAT
cd $TOCOMBOSADDIR

mkdir -p $audio_dir/feat
rm -f $audio_dir/feat/filelist.txt
touch $audio_dir/feat/filelist.txt

for f in $audio_dir/*.wav; do
   echo $f >> $audio_dir/feat/filelist.txt
done
echo "finished"

MCR=/usr/local/MATLAB/MATLAB_Runtime/v93
export LD_LIBRARY_PATH=$MCR/runtime/glnxa64:$MCR/bin/glnxa64:$MCR/sys/os/glnxa64:

./run_get_TOcomboSAD_output_v3.sh $MCR $audio_dir/feat/filelist.txt 0 0.5 $TOCOMBOSADDIR/UBMnodct256Hub5.txt

for f in $audio_dir/*.ToCombo.txt; do
  bn=`basename $f .wav.ToCombo.txt`
  python $TOCOMBOSADDIR/tocombo2rttm.py $f $bn > $audio_dir/tocombosad_$bn.rttm
done

