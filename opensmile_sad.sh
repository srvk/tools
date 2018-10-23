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
    > $audio_dir/${id}.opensmile_sad.txt #Make it empty if already present
    echo "Processing $id ..."
    LD_LIBRARY_PATH=/home/vagrant/usr/local/lib \
	$OPENSMILE \
	-C $CONFIG_FILE \
	-I $file \
	-turndebug 1 \
	-noconsoleoutput 1 \
	-saveSegmentTimes $audio_dir/${id}.opensmile_sad.txt \
	-logfile $audio_dir/opensmile-vad.log > /dev/null
done

for output in $(ls $audio_dir/*.opensmile_sad.txt); do
    id=$(basename $output .opensmile_sad.txt)
    awk -F ';|,' -v FN=$id '{ start_on = $2; start_off = $3 ; print "SPEAKER "FN" 1 "start_on" "(start_off-start_on)" <NA> <NA> speech <NA>" }' $output > $audio_dir/opensmile_sad_$id.rttm
done

