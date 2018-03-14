#!/bin/bash
#
# Run script to generate HTK MFCC features, given a WAV audio file
# then given a speech/nonspeech file (extension .rttm), run DiarTK
# (also known as ib_diarization_toolkit) to produce RTTM clustered
# utterances and generated speaker IDs

# Assumes 10ms frame size in .scp file; to change, edit line in htkconfig:
#   TARGETRATE = 100000.0
source ~/.bashrc
conda_dir=/home/vagrant/anaconda/bin

# Absolute path to this script. /home/user/bin/foo.sh
SCRIPT=$(readlink -f $0)
# Absolute path this script is in. /home/user/bin
BASEDIR=`dirname $SCRIPT`
# Path to OpenSAT (go on folder up and to opensat)
DIARTKDIR=$(dirname $BASEDIR)/ib_diarization_toolkit
# let's get our bearings: set CWD to the path of OpenSAT
cd $DIARTKDIR

# path to the wav files
audio_dir=/vagrant/data

for fin in `ls $audio_dir/*.wav`; do
    filename=$(basename "$fin")
    basename="${filename%.*}"
    
    # create temp dir
    workdir=/vagrant/temp_diartk
    
    mkdir -p $workdir
    
    featfile=$workdir/$basename.fea
    scpfile=$workdir/$basename.scp
    
    # first-first convert RTTM to DiarTK's version of a .scp file
    # SCP format:
    #   <basename>_<start>_<end>=<filename>[start,end]
    # RTTM format:
    #   Type file chan tbeg tdur ortho stype name conf Slat
    # math: convert RTTM seconds to HTK (10ms default) frames = multiply by 100
    grep SPEAKER /vagrant/data/${basename}.rttm | awk -v base="$basename" -v feats="$featfile" '{begg=$4*100;endd=($4+$5)*100; print base "_" begg "_" endd "="feats "[" begg "," endd "]"}' > $scpfile
    
    # first generate HTK features
    HCopy -T 2 -C htkconfig $fin $featfile
    
    # next run DiarTK
    scripts/run.diarizeme.sh $featfile $scpfile $workdir $basename
    
    # print results
    #cat $workdir/$basename.out
    cp $workdir/$basename.rttm /vagrant/data/diartk_diar_${basename}.rttm
done