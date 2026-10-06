USE PawCareDB;
GO

SET NOCOUNT ON;

PRINT 'TEST TREATMENTS';
GO

DECLARE @BookingID INT;

SELECT TOP (1)
    @BookingID = BookingID
FROM dbo.Bookings
WHERE Status = 'SCHEDULED'
ORDER BY BookingID;

IF @BookingID IS NULL
BEGIN
    THROW 50900,
          'FAIL: No scheduled booking exists for treatment test.',
          1;
END;
GO

DECLARE @BookingID2 INT;

SELECT TOP (1)
    @BookingID2 = BookingID
FROM dbo.Bookings
WHERE Status = 'SCHEDULED'
ORDER BY BookingID;

DECLARE @TreatmentResult TABLE
(
    TreatmentID INT
);

BEGIN TRY

    INSERT INTO @TreatmentResult
    EXEC dbo.usp_AddTreatment
        @BookingID = @BookingID2,
        @TreatmentName = 'Automated Test Treatment',
        @Description = 'Treatment created by automated test',
        @Cost = 250.00;

END TRY
BEGIN CATCH

    THROW;

END CATCH;

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.Treatments
    WHERE BookingID = @BookingID2
      AND TreatmentName = 'Automated Test Treatment'
      AND Cost = 250.00
)
BEGIN
    THROW 50900,
          'FAIL: Treatment was not inserted.',
          1;
END;

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.Bookings
    WHERE BookingID = @BookingID2
      AND Status = 'COMPLETED'
)
BEGIN
    THROW 50900,
          'FAIL: Booking was not completed after treatment.',
          1;
END;

BEGIN TRY

    EXEC dbo.usp_AddTreatment
        @BookingID = @BookingID2,
        @TreatmentName = 'Invalid Treatment',
        @Description = 'This must fail',
        @Cost = -100.00;

    THROW 50900,
          'FAIL: Negative treatment cost was accepted.',
          1;

END TRY
BEGIN CATCH

    IF ERROR_NUMBER() <> 50900
    BEGIN
        THROW;
    END;

END CATCH;

PRINT 'PASS: treatment tests';
GO
