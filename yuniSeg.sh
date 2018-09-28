#!/bin/bash
# Since the script is built to be launched outside of the vm, source
# the .bashrc which is not necessarily sourced!
source ~/.bashrc
conda_dir=/home/vagrant/anaconda/bin

# run YuniSeg with hard coded models & configs found here and in /vagrant
# assumes Python environment in /home/${user}/

# Absolute path to this script. /home/user/bin/foo.sh
SCRIPT=$(readlink -f $0)
# Absolute path this script is in. /home/user/bin
BASEDIR=`dirname $SCRIPT`
# Path to YuniSeg (go one folder up and to Yunitator)
YUNITATDIR=$(dirname $BASEDIR)/Yunitator

if [ $# -ne 1 ]; then
  echo "Usage: $0 <dirname>"
  echo "where dirname is the name of the folder"
  echo "containing the wav and rttm files"
  exit 1
fi

audio_dir=/vagrant/$1
filename=$(basename "$audio_dir")
dirname=$(dirname "$audio_dir")
extension="${filename##*.}"
basename="${filename%.*}"
# Check audio_dir to see if empty or if contains empty wav
bash $BASEDIR/check_folder.sh $audio_dir


# this is set in user's login .bashrc, but may not be if run from outside VM
export PATH=/home/${user}/anaconda/bin:$PATH

# let's get our bearings: set CWD to the path of Yunitator
cd $YUNITATDIR

# Iterate over files
echo "Starting"
for f in `ls $audio_dir/*.wav`; do
    ./runYuniSeg.sh $f
done

echo "$0 finished running"

# take all the .rttm in $audio_dir/Yunitemp/ and move them to /vagrant/data
for sad in `ls $audio_dir/Yunitemp/*.yuniSeg.rttm`; do
    _rttm=$(basename $sad)
    rttm=$audio_dir/yunitator_${_rttm}
    mv $sad $rttm
done

# simply remove hyp and feature
rm -rf $audio_dir/Yunitemp
