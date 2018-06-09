# Author:   Chris Compton
# Date:     September 2017

import os
import sys
import re
import csv
import pprint
import forms


markerTags = ['FORM_ID', 'FORM_DATE', 'FORM_NUM_1', 'FORM_NUM', 'FORM_REV', 'WKSHT_CD', 'SHEET_NAME', 'SECTION_NAME', 'SUBSECT_NAME', 'PART_NUM', 'PART_NAME']
columns = 9

form = {}
formLines = {}

extension = '.sql'
outputdir = 'processed'

print "TRUNCATE TABLE MCR_WORKSHEETS_AUTO;"


def processFile(dir, file):
    """Processes a csv HCRIS Worksheet file to format for
    importation into SQL Server"""
    myWorksheet = formatNameAsWorksheet(file)
    myYear = dir[2:4]

    if myWorksheet in forms.metaForms.keys() and myYear in forms.metaForms[myWorksheet].keys():

        print "-- Processing worksheet for: " + myWorksheet + " - " + myYear
    # LIMIT FILES HERE
    # if not re.match("508_Compliant_Version_of_G.csv", file):
    #     return

        for tag in markerTags:
            form[tag] = ''

        for meta in forms.metaForms[myWorksheet][myYear]:
            form[meta] = forms.metaForms[myWorksheet][myYear][meta]

        for i in range(0, columns):
            markerTags.append('CLMN_NUM_' + str(i))

        if not os.path.exists(outputdir):
            os.makedirs(outputdir)

        readin = open(dir + "/" + file, 'r')

        processedFileName = outputdir + "/" + re.sub('.csv$', '', file).split(" ")[-1] + "-" + dir[5:] + extension

        if os.path.exists(processedFileName):
            os.remove(processedFileName)

        #writeout = open(processedFileName, 'w')




        # Check delimiter, do replacement
        reLineMarker = "^\s?[0-9]{1,3} ," #
        reSubLineMarker = "^\s?[0-9]{1,3}\.[0-9]{1,2}\s?," #
        reSkip = ",*,"


        for line in readin:

            #print line

            for tag in markerTags:
                if re.match('CLMN_GROUP', line):
                    for i in range(0, columns):
                        form['CLMN_NUM_' + str(i)] = ''
                        form['CLMN_DESC_' + str(i)] = ''
                if not re.match('CLMN_NUM_', tag) and (re.match(tag + ':', line) or re.match('.*?' + tag + ':', line)):
                    val = formatMarker(tag, line)
                    form[tag] = val.replace('"','')
                elif re.match('CLMN_NUM_', tag) and (re.match(tag, line) or re.match('.*?' + tag, line)):
                    column = formatMarker(tag, line)
                    form[tag] = column[2]
                    form[tag.replace('_NUM_','_DESC_')] = column[0].replace('"','')
    
            #if re.match("Address", line):

            if re.match(reLineMarker, line) or re.match(reSubLineMarker, line):

                result = readAsCsv(line)

                formIndex = result[0].strip()
                formLines[formIndex] = form.copy()

                if re.match(reSubLineMarker, line):               
                    formLines[formIndex]['SUBLINE_NUM'] = result[0].strip().split(".").pop()
                else: 
                    formLines[formIndex]['SUBLINE_NUM'] = '00' 

                if len(form) > 0:
                    formLines[formIndex]['DB_VERSION'] = form['FORM_NUM'].split("-").pop()
                    formLines[formIndex]['WKSHT'] = form['WKSHT_CD'][:1]
                formLines[formIndex]['LINE_NUM_RAW'] = result[0].strip()
                formLines[formIndex]['LINE_NUM'] = formatLineNumber(formIndex)
                if myWorksheet == 'A':
                    formLines[formIndex]['LINE_DESC'] = sqlPrep(result[2].strip())
                else:	
                    formLines[formIndex]['LINE_DESC'] = sqlPrep(result[1].strip())        

            elif re.match(reSkip,line):
                skip = None
            else:
                #print line
                skip = None 



        # pp = pprint.PrettyPrinter(depth=6)
        # pp.pprint(formLines)
        


        # Good Output

        for line in formLines:
            if formLines[line]['FORM_NUM'] == '':
                print "-- " + str(formLines[line])
        
        for id in formLines:
            s1 = "','"
            s2 = ","
            row = formLines[id]

            query = "INSERT INTO MCR_WORKSHEETS_AUTO (" + s2.join(row.keys()) + ") VALUES ('" + s1.join(row.values()) + "');"
            print query


        # Close up shop
        readin.close()
        #writeout.close()






def readAsCsv(line):
    csv_reader = csv.reader( [ line ] )
    fields = None
    for row in csv_reader:
        fields = row

    return fields

def formatLineNumber(number):
    if len(number) > 3:
        number = number.split('.').pop(0) 

    if len(number) == 1:
        number = "00" + number
    elif len(number) == 2:
        number = "0" + number

    return number

def formatColumnNumber(number):
    if len(number) == 1:
        number = "00" + number
    elif len(number) == 2:
        number = "0" + number

    return number    

def formatNameAsWorksheet(file):
    part1 = file.split("_").pop()
    part2 = part1.split(".").pop(0)
    return part2

def formatMarker(marker, line):
    fields = readAsCsv(line)
    result = None

    for field in fields:
        if re.match(marker, field.strip()):
            result = field.replace('"','').strip().split(":").pop(1)

        # if re.match('FORM_DATE', marker) and re.match(marker, field.strip()):
        #     result =  str(result).replace('-','-1-')           

        if marker == 'PART_NUM':
            result =  str(result).replace('PART ','')

        if marker == 'FORM_REV':
            result =  str(result).replace('Rev. ','')

        if re.match('CLMN_NUM', marker) and re.match(marker, field.strip()):
            resultColumn = marker.split("_").pop()

            resultList = list()
            resultList.append(result)
            resultList.append(resultColumn)
            resultList.append(formatColumnNumber(resultColumn))

            return resultList

    return result

def sqlPrep(input):
    single = "'"
    """Performs a replacement of delimiters and text qualifiers in provided string"""
    result = re.sub(single, single+single, input)
    result = re.sub('"', '', result)
    return result
