#!/bin/bash
# Since the script is built to be launched outside of the vm, source
# the .bashrc which is not necessarily sourced!
source ~/.bashrc
conda_dir=/home/vagrant/anaconda/bin

# launch ldc
echo "using ldc_sad_hmm to perform Speech Activity Detecton"
$conda_dir/python perform_sad.py  -L /vagrant/data /vagrant/data/*.wav
echo "finished using ldc_sad_hmm. Please look inside /vagrant/data to see the output in *.lab format"

# move all files to name them correctly
for wav in `ls $audio_dir/*.wav`; do
    base=$(basename $wav)
    fname=$(base%.*)
    lab=/vagrant/data/ldc_sad_${fname}.lab
    mv $sad $lab
done

