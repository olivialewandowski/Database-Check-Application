USE [ASM]
GO

/****** Object:  StoredProcedure [dbo].[procBankAccountFileToTable]    Script Date: 7/19/2023 10:56:13 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

---This procedure takes any given BankAccount file and inserts it into the BankAccountTable
---The BankAccountTable works for both refund and disbursement accounts
---This procedure also returns three values, 1) the date of the last check for the month, the number of cleared checks and the total amount of the cleared checks
--Delete all other data than checks paid rows, update sum to take in to account swithced signs (company perspective). 
CREATE PROCEDURE [dbo].[procBankAccountFileToTable]
    @FilePath NVARCHAR(600),
    @AccountType NVARCHAR(20)
AS
BEGIN
    DELETE FROM BankAccountTable
    
    DECLARE @BulkInsertQuery NVARCHAR(1000)
    SET @BulkInsertQuery = 'BULK INSERT BankAccountTable FROM ''' + @FilePath + '''
        WITH 
        (
            FIRSTROW = 2,
            ROWTERMINATOR = ''\n'',
            FIELDTERMINATOR = '',''
        )' 

    EXEC sp_executesql @BulkInsertQuery

    UPDATE BankAccountTable
    SET [Amount] = -[Amount]

    IF @AccountType = 'Disbursement'
        UPDATE BankAccountTable SET [Client Account Name] = 'Disbursement'
    ELSE IF @AccountType = 'Refund'
        UPDATE BankAccountTable SET [Client Account Name] = 'Refund'

    DELETE FROM BankAccountTable
    WHERE [Type] != 'CHECKS PAID'

    DECLARE @LastDateOfMonth DATE
    DECLARE @ClearedCheckCount INT
    DECLARE @TotalDollarValue DECIMAL(18, 2)

    SELECT @LastDateOfMonth = EOMONTH(MAX([Post Date])) FROM BankAccountTable

    SELECT @ClearedCheckCount = COUNT(*)
    FROM BankAccountTable

    SELECT @TotalDollarValue = SUM([Amount])
    FROM BankAccountTable

    SELECT @LastDateOfMonth AS LastDateOfMonth, @ClearedCheckCount AS ClearedCheckCount, @TotalDollarValue AS TotalDollarValue
END
GO


