USE [ASM]
GO

/****** Object:  StoredProcedure [dbo].[procCompareChecksAndExceptions]    Script Date: 7/19/2023 10:56:41 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[procCompareChecksAndExceptions]
AS
BEGIN
    IF OBJECT_ID('tempdb..#TempBankAccountTable') IS NOT NULL
        DROP TABLE #TempBankAccountTable

    SELECT *, 0 AS Exception1, 0 AS Exception2, 0 AS Exception3, 0 AS Exception4, 0 AS Exception5
    INTO #TempBankAccountTable
    FROM BankAccountTable

    IF OBJECT_ID('tempdb..#TempCM20200') IS NOT NULL
        DROP TABLE #TempCM20200

    SELECT *
    INTO #TempCM20200
    FROM CM20200

    UPDATE #TempBankAccountTable
    SET Exception1 = 1
    WHERE [Customer Reference] IN (
        SELECT [Customer Reference]
        FROM #TempBankAccountTable
        GROUP BY [Customer Reference]
        HAVING COUNT([Customer Reference]) > 1
    )

    UPDATE #TempBankAccountTable
    SET Exception2 = 1
    WHERE [Customer Reference] IN (
        SELECT [CMTrxNum]
        FROM #TempCM20200
        GROUP BY [CMTrxNum]
        HAVING COUNT([CMTrxNum]) > 1
    )

    UPDATE #TempBankAccountTable
    SET Exception3 = 1
    WHERE [Customer Reference] IN (
        SELECT t1.[Customer Reference]
        FROM #TempBankAccountTable t1
        JOIN #TempCM20200 t2 ON t1.[Customer Reference] = t2.[CMTrxNum]
        WHERE t1.Amount <> t2.TRXAMNT
    )

    UPDATE #TempBankAccountTable
    SET Exception4 = 1
    WHERE EXISTS (
        SELECT 1
        FROM #TempBankAccountTable t1
        JOIN #TempCM20200 t2 ON t1.[Customer Reference] = t2.[CMTrxNum]
        WHERE t1.[Customer Reference] = #TempBankAccountTable.[Customer Reference]
        AND (t2.RECONUM = 3 OR t2.RECONUM = 4 OR t2.RECONUM = 5)
    )

    UPDATE #TempBankAccountTable
    SET Exception5 = 1
    WHERE NOT EXISTS (
        SELECT 1
        FROM #TempCM20200
        WHERE #TempBankAccountTable.[Customer Reference] = [CMTrxNum]
    )

    SELECT [Customer Reference] AS ClearedChecks
    FROM #TempBankAccountTable
    WHERE Exception1 = 0 AND Exception2 = 0 AND Exception3 = 0 AND Exception4 = 0 AND Exception5 = 0

    SELECT [Customer Reference] AS UnclearedChecks, Exception1, Exception2, Exception3, Exception4, Exception5
    FROM #TempBankAccountTable
    WHERE Exception1 = 1 OR Exception2 = 1 OR Exception3 = 1 OR Exception4 = 1 OR Exception5 = 1
    
    DROP TABLE #TempBankAccountTable
    DROP TABLE #TempCM20200
END
GO


