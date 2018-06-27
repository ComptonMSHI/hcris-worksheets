
DROP PROCEDURE IF EXISTS spLoadWorksheetTemplates;
GO

/*
EXEC spLoadWorksheetTemplates 
	@ColumnCount = 15
	, @ProductionMode = 1
*/

-- 0 = Test Mode 		- All actions simulated.  No permanent changes.
-- 1 = Production Mode 	- All actions permanent.  Will drop and create tables.

CREATE PROC
    spLoadWorksheetTemplates
        @ColumnCount INTEGER = 8,
        @ProductionMode INTEGER = 0
    AS BEGIN


        /************************************************************
            MODE
        ************************************************************/

        IF @ProductionMode = 1
            BEGIN
                print '*** RUNNING IN PRODUCTION MODE! TABLES DROPPED AND CREATED.'
            END
        ELSE
            BEGIN
                print '*** RUNNING IN TEST MODE! NO PERMANENT ACTION TAKEN.'
            END




            DROP TABLE IF EXISTS [MCR_WORKSHEETS_AUTO]

            CREATE TABLE [MCR_WORKSHEETS_AUTO] (
                [DB_VERSION] [int] NOT NULL,			-- * FUNCTIONAL - Derived from FORM_NUM (10|96)$

            /* EVERYTHING GOES DOWN (Y Axis) [ROW/LINE FOCUSED] */

                /* FORM */
                [FORM_NUM] [varchar](20) NOT NULL, 		-- ! "2522-10" [CHANGED] (Missing "C")
                [FORM_ID] [varchar](10) NOT NULL,		-- ! "40-604" [NEW]
                [FORM_REV] [int] NOT NULL,				-- ! "2" [NEW]
                [FORM_DATE] [varchar](10) NOT NULL,			-- ! "8/1/2011" [NEW]

                [FORM_NUM_1] [varchar](10) NULL,		-- * "4090"

                /* WORKSHEET */
                [WKSHT] [varchar](3) NOT NULL,			-- * "G"
                [WKSHT_CD] [varchar](7) NULL,			--
                [SHEET_NAME] [varchar](500) NULL,		-- * "Statement of Revenues and Expenses"

                /* PART */
                [PART_NUM] [varchar](2) NULL,			-- * "I"
                [PART_NAME] [varchar](500) NULL,		-- * "Patient Revenues"


                /* SECTION */
                [SECTION_NAME] [varchar](500) NULL,		-- * "Assets"

                /* SUBSECTION */
                [SUBSECT_NAME] [varchar](500) NULL,	-- * "General Inpatient Routine Care Services"	


                /* LINE */
                [LINE_NUM_RAW] [varchar](8) NULL,	-- * "1"
                [LINE_DESC] [varchar](500) NULL,		-- * " Cash on hand and in banks" NEEDS TRIM
                [LINE_NUM] [varchar](6) NULL,				--
                [NO_LINE_DESC_FLG] [int] NULL,			-- "1" or NULL

                /* SUBLINE */
                [SUBLINE_NUM] [varchar](2) NULL,		-- ?

            /* EVERYTHING GOES OVER (X Axis) [COLUMN FOCUSED] PIVOTED */

                /* COLUMN */
                [CLMN_NUM_RAW] [varchar](8) NULL,		-- ?
                [CLMN_DESC] [varchar](500) NULL,		-- ! "Plant Fund" [NOT_USED]
                [CLMN_NUM] [varchar](6) NULL,				-- ! "1" [NOT USED]

            -- ! UNPIVOT REQUIRED FOR FINAL ROW DATA
            --	[CLMN_NUM_N]							-- ! [NEW]
            --	[CLMN_DESC_N]							-- ! [NEW]
                -- 	Example Columns:
                -- 		* CLMN_NUM_3
                -- 		* CLMN_DESC_3
                            
                
                /* SUBCOLUMN */
                [SUBCLMN_NUM] [varchar](2) NULL			--

            );


            /* CREATE THE PIVOTED COLUMNS (X Axis Format) - SET MAX COLUMNS NEEDED */

            DECLARE @COLUMNS INT = @ColumnCount
            DECLARE @SQLString NVARCHAR(MAX) = ''

            WHILE @COLUMNS >= 0
                BEGIN
                    SET @SQLString = '
                        ALTER TABLE [MCR_WORKSHEETS_AUTO] ADD 
                            CLMN_NUM_' + CONVERT(VARCHAR(3),@COLUMNS) + ' varchar(3) NULL, 
                            CLMN_DESC_' + CONVERT(VARCHAR(3),@COLUMNS) + ' varchar(200) NULL;  
                        ' + @SQLString;
                    SET @COLUMNS -= 1
                END
                EXEC SP_EXECUTESQL @SQLString;







    END

GO
