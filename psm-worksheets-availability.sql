DROP PROCEDURE IF EXISTS spSetWorksheetAvailabilityOn;
GO

/*
EXEC spSetWorksheetAvailabilityOn
        @Form = '2552-10'
        , @Worksheet = 'A000000'        
        , @ProductionMode = 0
*/

-- 0 = Test Mode 		- All actions simulated.  No permanent changes.
-- 1 = Production Mode 	- All actions permanent.  Will drop and create tables.

CREATE PROC
    spSetWorksheetAvailabilityOn
        @Form        CHAR(10),
        @Worksheet   CHAR(7),        
        @ProductionMode INTEGER = 0
    AS BEGIN


        IF @ProductionMode = 1
            BEGIN
                print '*** RUNNING IN PRODUCTION MODE! RECORD ADDED.'
                INSERT INTO [MCR_AVAILABLE] VALUES (@Form, SUBSTRING(@Worksheet,1,1), @Worksheet)
            END
        ELSE
            BEGIN
                print '*** RUNNING IN TEST MODE! NO PERMANENT ACTION TAKEN.'
                SELECT TOP 100 * FROM [MCR_AVAILABLE];
            END


    END

GO

DROP PROCEDURE IF EXISTS spSetWorksheetAvailabilityReset;
GO

/*
EXEC spSetWorksheetAvailabilityReset      
        , @ProductionMode = 0
*/

-- 0 = Test Mode 		- All actions simulated.  No permanent changes.
-- 1 = Production Mode 	- All actions permanent.  Will drop and create tables.

CREATE PROC
    spSetWorksheetAvailabilityReset      
        @ProductionMode INTEGER = 0
    AS BEGIN


        IF @ProductionMode = 1
            BEGIN
                print '*** RUNNING IN PRODUCTION MODE! TABLE TRUNCATED.'
                TRUNCATE TABLE [MCR_AVAILABLE];
            END
        ELSE
            BEGIN
                print '*** RUNNING IN TEST MODE! NO PERMANENT ACTION TAKEN.'
                SELECT TOP 100 * FROM [MCR_AVAILABLE];
            END


    END

GO
