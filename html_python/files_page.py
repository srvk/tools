import html_python.page as page
import html_python.utils as utils
import html_python.style_css as style_css
import numpy as np
import os
import glob
from collections import OrderedDict


class FilesPage(page.Page):

    def __init__(self, output_folder, results_folder):
        # Initialize self.output_folder & self.results_folder
        page.Page.__init__(self, output_folder, results_folder)

        # List of gold files
        self.gold_files = [fn for fn in glob.iglob(os.path.join(self.results_folder, '*.rttm'))
                      if not os.path.basename(fn).startswith(('ldc_sad', 'diartk', 'noisemes_sad',
                                                              'opensmile', 'tocombo_sad'))]

        # Name of the html that will be generated
        self.name = 'files.html'

        # File descriptor
        self.html = open(os.path.join(self.output_folder, self.name), 'w')

        tabs = '<link rel="stylesheet" type="text/css" href="' + style_css.css_name + '">\n' + \
               '<div id="menu">\n' + \
               '<ul id="onglets">\n' + \
               '<li class="active"><a href="files.html"> Files </a></li>\n' + \
               '<li><a href="models.html"> Models </a></li>\n' + \
               '</ul>\n' + \
               '</div>'
        self.html.write(tabs)#write tabs

        # Compute statistics
        self._compute_statistics()

    def _compute_statistics(self):

        self.audio_stats = []
        self.gold_stats = []

        # Empty OrderedDict that will contains the unique keys of the gold file
        # We use only the keys, it's to fake an OrderedSet that doesn't exist natively in python.
        # The difficulty here is that gold2.rttm could have some participants that gold1.rttm doesn't have.
        # We still want to consider them in all of the rttm to present the results in a table.
        self.gold_keys = OrderedDict({})

        for gold in self.gold_files: #for each reference rttm file

            wav_path = os.path.splitext(gold)[0]+'.wav'

            # Get .wav information
            audio_stats_file = utils.analyze_wav(wav_path)
            self.audio_stats.append(audio_stats_file)

            # Analyze gold
            dur_wav = audio_stats_file['duration (s)']
            gold_stats_file = utils.analyze_rttm(gold, dur_wav)
            self.gold_keys = OrderedDict.fromkeys(self.gold_keys.keys() + gold_stats_file.keys())
            self.gold_stats.append(gold_stats_file)


    def _write_value(self, value, number_of_digits = 4):
        if isinstance(value, str):
            self.html.write('<td> %s </td>\n' % value)
        elif isinstance(value, float) or isinstance(value, np.float64) or isinstance(value, np.float32):
            self.html.write('<td> %.*f</td>\n' % (number_of_digits,value))
        elif isinstance(value, int):
            self.html.write('<td> %d </td>\n' % value)

    def write_audio_stats(self):

        keys = self.audio_stats[0].keys()

        # Open table
        self.html.write('<h2>Audio level statistics</h2>\n<table>\n')

        # Write first line of the table
        self.html.write('<tr>\n')
        for k in keys:
            self.html.write('<th> %s </th>\n' % k)
        self.html.write('</tr>\n')

        # Write audio statistics
        for d in self.audio_stats:
            self.html.write('<tr>\n')
            for key, value in d.items():
                self._write_value(value, 4)

            self.html.write('</tr>\n')

        # Close table
        self.html.write('</table>')

    def write_gold_stats(self):

        keys = self.gold_stats[0].keys()

        # Open table
        self.html.write('<h2>Annotation level statistics</h2>\n<table>\n')

        # Write first line of the table
        self.html.write('<tr>\n')
        for k in self.gold_keys:
            self.html.write('<th> %s </th>\n' % k)
        self.html.write('</tr>\n')

        # Write gold statistics
        for d in self.gold_stats:
            self.html.write('<tr>\n')
            for key in self.gold_keys:
                if key in d:
                    self._write_value(d[key], 2)
                else:
                    self._write_value("")
            self.html.write('</tr>\n')

        # Close table
        self.html.write('</table>')

    def write_statistics(self):
        self.write_audio_stats()
        self.write_gold_stats()

    def close(self):
        self.html.close()