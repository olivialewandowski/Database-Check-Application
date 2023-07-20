USE [ASM]
GO

/****** Object:  StoredProcedure [dbo].[procValidateUserID]    Script Date: 7/19/2023 10:58:03 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--This stored procedure will check if the USERID is valid against the SY01400 Table
CREATE PROCEDURE [dbo].[procValidateUserID]
	@UserID NVARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @IsValid BIT

IF EXISTS (SELECT 1 FROM SY01400 WHERE USERID = @UserID)
        SET @IsValid = 1
    ELSE
        SET @IsValid = 0

	IF @IsValid = 0
	BEGIN
		RAISERROR('There is no account associated with this User ID. Try again.', 16, 1)
		RETURN
	END

	INSERT INTO CM20200 (MDFUSRID)
	VALUES (@UserID)

	RETURN @IsValid
END
GO


