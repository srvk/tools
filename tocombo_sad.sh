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

# create temp dir to store audio files with 1 channels, if needed (i.e. if audio to treat has 2 or more channels.)
# Indeed, To Combo Sad Fails when there are more than 1 channels.
if [[ ! -d $audio_dir/tocombo_temp ]]; then
    mkdir $audio_dir/tocombo_temp
    temp_dir=$audio_dir/tocombo_temp
fi

for f in $audio_dir/*.wav; do
   # Check if audio has 1 channel or more. If it has more, use sox to create a temp audio file w/ 1 channel.
   n_chan=$(soxi $f | grep Channels | cut -d ':' -f 2)
   if [[ $n_chan -gt 1 ]]; then 
       base=$(basename $f)
       sox -c $n_chan $f -c 1 $temp_dir/$base
       f=$temp_dir/$base
   fi

   echo $f >> $audio_dir/feat/filelist.txt

done
echo "finished"

MCR=/usr/local/MATLAB/MATLAB_Runtime/v93
export LD_LIBRARY_PATH=$MCR/runtime/glnxa64:$MCR/bin/glnxa64:$MCR/sys/os/glnxa64:

./run_get_TOcomboSAD_output_v3.sh $MCR $audio_dir/feat/filelist.txt 0 0.5 $TOCOMBOSADDIR/UBMnodct256Hub5.txt

# Retrieve the outputs from the temp folder
mv $temp_dir/*ToCombo.txt $audio_dir

# Delete the temp directory
rm -rf $temp_dir

for f in $audio_dir/*.ToCombo.txt; do
  bn=`basename $f .wav.ToCombo.txt`
  python $TOCOMBOSADDIR/tocombo2rttm.py $f $bn > $audio_dir/tocombo_sad_$bn.rttm
done

