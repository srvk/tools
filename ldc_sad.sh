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

# Set CWD as LDC_SAD_HMM
cd $LDC_SAD_DIR

# launch ldc
echo "using ldc_sad_hmm to perform Speech Activity Detecton"
$conda_dir/python perform_sad.py  -L /vagrant/data /vagrant/data/*.wav
echo "finished using ldc_sad_hmm. Please look inside /vagrant/data to see the output in *.lab format"

# move all files to name them correctly
for wav in `ls /vagrant/data/*.wav`; do
    # retrieve filename and remove .wav
    base=$(basename $wav .wav)
    lab=/vagrant/data/ldc_sad_${base}.lab
    mv /vagrant/data/${base}.lab $lab
done

