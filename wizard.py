import os
import re
import hcris

# We don't always want to process all data we have in files.
# This provides specificity depending on need.

directories = [
    '1996',
    '2010'
]

for dir in directories:
    filelist = os.listdir(dir)
    print("\n-- ************  " + dir + "  ************\n")
    for file in filelist:
        hcris.processFile(dir,file)

