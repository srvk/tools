#!/bin/bash

# opensmile-vad.sh
# runs OpenSMILE's VAD module in scripts/vad/
# given a wav file

if [ $# -lt 1 ]; then
  echo "USAGE: $0 <INPUT FILE>"
  exit 1
fi

filename=$(basename "$1")
dirname=$(dirname "$1")
extension="${filename##*.}"
basename="${filename%.*}"

audio_dir=/vagrant/$1
OSHOME=/home/vagrant/openSMILE-2.1.0/
CONFIG_FILE=/vagrant/conf/vad/vad_segmenter_aclew.conf
#OUTPUT_DIR=$dirname/feature
OPENSMILE=$OSHOME/bin/linux_x64_standalone_static/SMILExtract

#mkdir -p $OUTPUT_DIR

cd $OSHOME/scripts/vad

# Use OpenSMILE 2.1.0  
for sad in `ls $audio_dir/*.wav`; do
    file=$sad
    id=`basename $file`
    id=${id%.wav}
    LD_LIBRARY_PATH=/home/vagrant/usr/local/lib \
	$OPENSMILE \
	-C $CONFIG_FILE \
	-I $file \
	-turndebug 1 \
	-logfile opensmile-vad.log 2>&1 | grep "of segment" | paste -sd ' \n' | awk -v FN=$id '{print "SPEAKER\t"FN"\t1\t"$5"\t"($11-$5)"\t<NA>\t<NA>\tspeech\t<NA>"}' > $audio_dir/opensmile_sad_$id.rttm
done
