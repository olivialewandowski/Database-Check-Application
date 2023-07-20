USE [ASM]
GO

/****** Object:  StoredProcedure [dbo].[procSearchCheckRegister]    Script Date: 7/19/2023 10:57:39 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--The user is selecting the Status and CheckRegisterType from a drop down menu so their input can never be invalid 
--However, the check number and check amount can be invalid so return an error message if so.
--Essentially, return an error message in any case that the inputted parameters don't match any given checks.
--
CREATE PROCEDURE [dbo].[procSearchCheckRegister]
  @CheckRegisterType NVARCHAR(20),
  @Status NVARCHAR(10) = NULL,
  @CheckNumber VARCHAR(20) = NULL,
  @CheckAmount DECIMAL(10, 2) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  
  DECLARE @Query NVARCHAR(MAX);
  SET @Query = 'SELECT CHEKBKID, TRXDATE, CMTrxNum, paidtorcvdfrom, DSCRIPTN, VOIDED,
				RECONUM, ClrdAmt, TRXAMNT, clearedate, MODIFDT, MDFUSRID
                FROM CM20200
                WHERE TRXAMNT <> 0';

  IF @CheckRegisterType = 'DISBURSEMENT'
  BEGIN
    SET @Query = @Query + 'AND CHEKBKID IN (''DISBURSEMENT-FC'', ''PAYROLL-FC'')';
  END
  ELSE IF @CheckRegisterType = 'REFUND'
  BEGIN
    SET @Query = @Query + ' AND CHEKBKID = ''REFUND''';
  END
  
  IF @Status = 'Cleared'
  BEGIN
    SET @Query = @Query + ' AND RECONUM > 0';
  END
  ELSE IF @Status = 'Uncleared'
  BEGIN
    SET @Query = @Query + ' AND RECONUM = 0';
  END 

  IF @CheckNumber IS NOT NULL
  BEGIN
    SET @Query = @Query + ' AND CMTrxNum = ''' + @CheckNumber + ''''
  END
  
  IF @CheckAmount IS NOT NULL
  BEGIN
    SET @Query = @Query + ' AND TRXAMNT = ' + CAST(@CheckAmount AS NVARCHAR(50))
  END
  
  SET @Query = @Query + ' ORDER BY CHEKBKID, TRXDATE, CMTrxNum'
   
  PRINT @Query

  EXEC(@Query);
END
GO


