DROP PROCEDURE IF EXISTS spBuildWorksheets;
GO

/*
EXEC spBuildWorksheets
    @ColumnCount = 15
	, @ProductionMode = 1
*/

-- 0 = Test Mode 		- All actions simulated.  No permanent changes.
-- 1 = Production Mode 	- All actions permanent.  Will drop and create tables.

CREATE PROC
    spBuildWorksheets
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


        DROP TABLE IF EXISTS [MCR_AVAILABLE];

        CREATE TABLE [MCR_AVAILABLE] (
            FORM        CHAR(10),
            WKSHT       CHAR(1),
            WKSHT_CD    CHAR(7) NOT NULL
        );



        DROP TABLE IF EXISTS [MCR_WORKSHEETS];

        CREATE TABLE [MCR_WORKSHEETS] (
            [DB_VERSION] [int] NULL,			-- * FUNCTIONAL - Derived from FORM_NUM (10|96)$

            /* FORM */
            [FORM_NUM] [varchar](20) NULL, 		-- ! "2522-10" [CHANGED] (Missing "C")
            [FORM_ID] [varchar](10) NULL,		-- ! "40-604" [NEW]
            [FORM_REV] [int] NULL,				-- ! "2" [NEW]
            [FORM_DATE] [varchar](5) NULL,			-- ! "8/1/2011" [NEW]

            [FORM_NUM_1] [varchar](10) NULL,		-- * "4090"

            /* WORKSHEET */
            [WKSHT] [varchar](3) NULL,			-- * "G"
            [WKSHT_CD] [varchar](7) NULL,				-- FUNCTIONAL - Text String Derived from WKSHT, WKSHT_CD
            [SHEET_NAME] [varchar](500) NULL,		-- * "Statement of Revenues and Expenses"

            /* PART */
            [PART_NUM] [varchar](2) NULL,			-- * "I"
            [PART_NAME] [varchar](500) NULL,		-- * "Patient Revenues"

            /* SECTION */
            [SECTION_NAME] [varchar](500) NULL,		-- * "Assets"

            /* SUBSECTION */
            [SUBSECTION_NAME] [varchar](500) NULL,	-- * "General Inpatient Routine Care Services"	

            /* LINE */
            [LINE_NUM_RAW] [varchar](8) NULL,	-- * "1"
            [LINE_DESC] [varchar](500) NULL,		-- * " Cash on hand and in banks" NEEDS TRIM
            [LINE_NUM] [varchar](3) NULL,				--
            [NO_LINE_DESC_FLG] [int] NULL,			-- "1" or NULL

            /* SUBLINE */
            [SUBLINE_NUM] [varchar](2) NULL,		-- ?

            /* COLUMN */
            [CLMN_NUM_RAW] [varchar](8) NULL,		-- ?
            [CLMN_DESC] [varchar](500) NULL,		-- ! "Plant Fund" [NOT_USED]
            [CLMN_NUM] [varchar](3) NULL,				-- ! "1" [NOT USED]

            /* SUBCOLUMN */
            [SUBCLMN_NUM] [varchar](2) NULL			--

        );

        DECLARE @COLUMNS INT = @ColumnCount
        DECLARE @SQLString NVARCHAR(MAX) = ''

        SET @SQLString = '
                            INSERT INTO MCR_WORKSHEETS
                            select 
                            w.DB_VERSION,
                            w.FORM_NUM,
                            w.FORM_ID,
                            w.FORM_REV,
                            w.FORM_DATE,
                            w.FORM_NUM_1,
                            w.WKSHT,
                            w.WKSHT_CD,
                            w.SHEET_NAME,
                            w.PART_NUM,
                            w.PART_NAME,
                            w.SECTION_NAME,
                            w.SUBSECT_NAME as SUBSECTION_NAME,
                            w.LINE_NUM_RAW,
                            w.LINE_DESC,
                            w.LINE_NUM,
                            w.NO_LINE_DESC_FLG,
                            w.SUBLINE_NUM,
                            w.CLMN_NUM_RAW,
                            result.COL_DESC as CLMN_DESC,
                            result.COL_NUM as CLMN_NUM,
                            w.SUBCLMN_NUM
                            from MCR_WORKSHEETS_AUTO w cross apply
                                (values (w.CLMN_NUM_1, w.CLMN_DESC_1)'

        WHILE @COLUMNS >= 1
            BEGIN
                SET @SQLString = @SQLString +
                        ', (w.CLMN_NUM_' + CONVERT(VARCHAR(3),@COLUMNS) +  
                        ', w.CLMN_DESC_' + CONVERT(VARCHAR(3),@COLUMNS) + ')'
                        
                SET @COLUMNS -= 1
            END

            SET @SQLString = @SQLString + ') result(COL_NUM, COL_DESC);'

            EXEC SP_EXECUTESQL @SQLString;            

        -- TODO: This needs to be fixed on import!!!  Raw line with subline is not importing with SSIS.

        UPDATE MCR_WORKSHEETS SET LINE_NUM_RAW = CONCAT(CONVERT(int, LINE_NUM),'.',SUBLINE_NUM) WHERE SUBLINE_NUM Is Not Null AND LINE_NUM_RAW Is Null;

        -- This is run after the worksheets table is built


        UPDATE MCR_WORKSHEETS SET 
            LINE_DESC = TRIM(LINE_DESC)
            , CLMN_DESC = TRIM(CLMN_DESC)
            , SECTION_NAME = TRIM(SECTION_NAME);
            
        SELECT DISTINCT * INTO #MCR_WORKSHEETS
            FROM MCR_WORKSHEETS;

        DROP TABLE MCR_WORKSHEETS;

        SELECT * INTO MCR_WORKSHEETS 
            FROM #MCR_WORKSHEETS
            WHERE CLMN_NUM = '001';

        DROP TABLE #MCR_WORKSHEETS;


        --UPDATE MCR_WORKSHEETS SET CLMN_NUM = '000' WHERE CLMN_NUM Is Null OR CLMN_NUM = '';
        --UPDATE MCR_WORKSHEETS SET SUBCLMN_NUM = '00' WHERE SUBCLMN_NUM Is Null OR SUBCLMN_NUM = '';


        DROP INDEX IF EXISTS i2 ON MCR_WORKSHEETS;
        CREATE INDEX i2 ON MCR_WORKSHEETS (FORM_NUM, WKSHT, WKSHT_CD);

        DROP INDEX IF EXISTS i2a ON MCR_WORKSHEETS;
        CREATE INDEX i2a ON MCR_WORKSHEETS (FORM_NUM, WKSHT_CD);	

        DROP INDEX IF EXISTS i2c ON MCR_WORKSHEETS;
        CREATE INDEX i2c ON MCR_WORKSHEETS (WKSHT);

        DROP INDEX IF EXISTS i2d ON MCR_WORKSHEETS;
        CREATE INDEX i2d ON MCR_WORKSHEETS (FORM_NUM ASC, WKSHT_CD ASC, LINE_NUM_RAW ASC);

        DROP INDEX IF EXISTS i2e ON MCR_WORKSHEETS;
        CREATE INDEX i2e ON MCR_WORKSHEETS (CLMN_NUM, LINE_NUM, FORM_NUM, WKSHT_CD);


        --DROP TABLE IF EXISTS [MCR_WORKSHEETS_AUTO];



    END

GO
