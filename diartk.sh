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
if [ $# -ne 2 ]; then
  echo "Usage: diartk.sh <dirname> <transcription>"
  echo "where dirname is the name of the folder"
  echo "containing the wav files, and transcription"
  echo "specifies which transcription you want to use."
  echo "Choices are:"
  echo "  ldc_sad"
  echo "  noisemes"
  echo "  tocombosad"
  echo "  opensmile"
  echo "  textgrid"
  echo "  eaf"
  echo "  rttm"
  exit 1;
fi

audio_dir=/vagrant/$1
trs_format=$2

# Check audio_dir to see if empty or if contains empty wav
bash $BASEDIR/check_folder.sh $audio_dir


for fin in `ls $audio_dir/*.wav`; do
    filename=$(basename "$fin")
    basename="${filename%.*}"
    echo "treating $basename"
    
    # create temp dir
    workdir=$audio_dir/temp_diartk
    
    mkdir -p $workdir
    
    featfile=$workdir/$basename.fea
    scpfile=$workdir/$basename.scp
    
    # first-first convert RTTM to DiarTK's version of a .scp file
    # SCP format:
    #   <basename>_<start>_<end>=<filename>[start,end]
    # RTTM format:
    #   Type file chan tbeg tdur ortho stype name conf Slat
    # math: convert RTTM seconds to HTK (10ms default) frames = multiply by 100
    case $trs_format in
      "ldc_sad")
       sys="ldcSad"
       $conda_dir/python /vagrant/toolbox/rttm2scp.py $audio_dir/ldc_sad_${basename}.rttm $scpfile
      ;;
      "")
       # add default case
       echo "Warning: no SAD source specified, using Noisemes by default, at your own risk."
       echo "Next time, please specify SAD."
       sys="noisemesSad"
       $conda_dir/python /vagrant/toolbox/rttm2scp.py $audio_dir/noisemes_sad_${basename}.rttm $scpfile
      ;;
      "noisemes")
       sys="noisemesSad"
       $conda_dir/python /vagrant/toolbox/rttm2scp.py $audio_dir/noisemes_sad_${basename}.rttm $scpfile
      ;;
      "tocombosad")
       sys="tocomboSad"
        $conda_dir/python /vagrant/toolbox/rttm2scp.py $audio_dir/tocombo_sad_${basename}.rttm $scpfile
      ;;
      "opensmile")
       sys="opensmileSad"
        $conda_dir/python /vagrant/toolbox/rttm2scp.py $audio_dir/opensmile_sad_${basename}.rttm $scpfile
      ;;
      "textgrid") 
       sys="goldSad"
       $conda_dir/python /home/vagrant/varia/textgrid2rttm.py $audio_dir/${basename}.TextGrid $workdir/${basename}.rttm
       $conda_dir/python /vagrant/toolbox/rttm2scp.py $workdir/${basename}.rttm $scpfile
       rm $workdir/$basename.rttm
      ;;
      "eaf")
       sys="goldSad"
       $conda_dir/python /home/vagrant/varia/elan2rttm.py $audio_dir/${basename}.eaf $workdir/${basename}.rttm
       $conda_dir/python /vagrant/toolbox/rttm2scp.py $workdir/${basename}.rttm $scpfile
       rm $workdir/$basename.rttm
      ;;
      "rttm")
       sys="goldSad"
       # Since somes reference rttm files are spaced rather than tabbed, we need to
       # tab them before using them. It's only the case for the original rttm.
       # This solution is temporary and will be removed as soon as we respect the tabulation
       # specification.
       cp $audio_dir/${basename}.rttm $audio_dir/temp_diartk/${basename}.rttm
       sed -i 's/ \+/\t/g' $audio_dir/temp_diartk/${basename}.rttm
       $conda_dir/python /vagrant/toolbox/rttm2scp.py $audio_dir/temp_diartk/${basename}.rttm $scpfile
      ;;
      *)
       echo "ERROR: please choose SAD system between:"
       echo "  ldc_sad"
       echo "  noisemes"
       echo "  tocombosad"
       echo "  opensmile"
       echo "  textgrid"
       echo "  eaf"
       echo "  rttm"
       echo "Now exiting..."
       exit 1
      ;;
    esac
   
    # don't process files with empty transcription
    if [ -s $scpfile ]; then 
        # first generate HTK features
        HCopy -T 2 -C htkconfig $fin $featfile
        
        # next run DiarTK
        scripts/run.diarizeme.sh $featfile $scpfile $workdir $basename
        
        # print results
        #cat $workdir/$basename.out
        cp $workdir/$basename.rttm $audio_dir/diartk_${sys}_${basename}.rttm
    fi
    if [ ! -s $audio_dir/diartk_${sys}_${basename}.rttm ]; then
        # if diarization failed, still write an empty file...
        touch $audio_dir/diartk_${sys}_${basename}.rttm
    fi

done
