#!/bin/bash 
#
# This script launches OpenSAT on test.wav to see if it compiled okay,
# and tests ldc on test2.mp3.
source ~/.bashrc
conda_dir=/home/vagrant/anaconda/bin

# Absolute path to this script. /home/user/bin/foo.sh
SCRIPT=$(readlink -f $0)
# Absolute path this script is in. /home/user/bin
BASEDIR=`dirname $SCRIPT`
# Path to OpenSAT (go on folder up and to opensat)
OPENSATDIR=$(dirname $BASEDIR)/OpenSAT
LDC_SAD_DIR=$(dirname $BASEDIR)/ldc_sad_hmm
DIARTKDIR=$(dirname $BASEDIR)/ib_diarization_toolkit

# First test ldc_sad_hmm
cd $LDC_SAD_DIR
$conda_dir/python perform_sad.py -L /vagrant /vagrant/test2.mp3 > /dev/null 2>&1 || exit 1
# convert output to rttm, for diartk.
grep ' speech' /vagrant/test2.lab | awk -v fname=$base '{print "SPEAKER" "\t" fname "\t" 1  "\t" $1  "\t" $2-$1 "\t" "<NA>" "\t" "<NA>"  "\t" $3  "\t"  "<NA>"}'   > /vagrant/test2.rttm
echo "LDC_SAD passed the test..."

# now test Noisemes
cd $OPENSATDIR
sh runOpenSAT.sh /vagrant/test.wav > /dev/null 2>&1 || exit 1
rm -rf $OPENSATDIR/SSSF/data/feature $OPENSATDIR/SSSF/data/hyp
echo "Noisemes passed the test..."

# finally test DIARTK
cd $DIARTKDIR
# Diartk need wav not mp3, but test.wav is too short and make diartk crash ...
sox /vagrant/test2.mp3 /vagrant/test2.wav
sh run-rttm.sh /vagrant/test2.wav /vagrant/test2.rttm > /dev/null 2&1 || exit 1
echo "DiarTK passed the test..."

# test finished
echo "Congratulations, everything is OK!..."
