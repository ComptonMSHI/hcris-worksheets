import os
import re
import hcris

SQLProductionMode = 1
SQLStartYear = 1995
SQLEndYear = 2017
SQLPath = "/data/mcr/Output"
SQLFolder = "2018-05-06"
SQLColumns = 15


# We don't always want to process all data we have in files.
# This provides specificity depending on need.

directories = [
    '1996',
    '2010'
]

print("DECLARE @INSTALL_PRODUCTION INT = %s" % SQLProductionMode)

print("DECLARE @INSTALL_START_YEAR INT = %d" % SQLStartYear)
print("DECLARE @INSTALL_END_YEAR INT = %d" % SQLEndYear)
print("DECLARE @INSTALL_FROM_PATH VARCHAR(255) = N'%s'" % SQLPath)
print("DECLARE @INSTALL_FROM_FOLDER VARCHAR(255) = N'%s'" % SQLFolder)

print("TRUNCATE TABLE MCR_WORKSHEETS_AUTO;")
print("EXEC spBuildCrosswalk @ProductionMode = @INSTALL_PRODUCTION;")
print("EXEC spLoadWorksheetTemplates @ColumnCount = %d, @ProductionMode = @INSTALL_PRODUCTION;" % SQLColumns)

for dir in directories:
    filelist = os.listdir("forms/" + dir)
    print("\n-- ************  " + dir + "  ************\n")
    for file in filelist:
        hcris.processFile("forms/" + dir,file)


print("EXEC spBuildWorksheets @ColumnCount = %d, @ProductionMode = @INSTALL_PRODUCTION;" % SQLColumns)

