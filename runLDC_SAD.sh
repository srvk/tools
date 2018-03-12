#!/bin/bash
echo "using ldc_sad_hmm to perform Speech Activity Detecton"
~/anaconda/bin/python perform_sad.py  -L /vagrant/data /vagrant/data/*.wav
echo "finished using ldc_sad_hmm. Please look inside /vagrant/data to see the output in *.lab format"
