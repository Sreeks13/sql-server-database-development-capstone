/* ============================================================
   PawCareDB - test_scheduling.sql
   ============================================================ */

USE PawCareDB;
GO

SET NOCOUNT ON;
GO

DECLARE @TestTime DATETIME2(0);

SET @TestTime =
    DATEADD(
        HOUR,
        9,
        DATEADD(
            DAY,
            30,
            CAST(CAST(GETDATE() AS DATE) AS DATETIME2(0))
        )
    );

DECLARE @BookingID INT;
DECLARE @AuditCount INT;

/* ============================================================
   TEST 1 - VALID BOOKING
   ============================================================ */

EXEC dbo.usp_CreateBooking
    @PetID = 4,
    @VetID = 3,
    @AppointmentAt = @TestTime,
    @Reason = N'Automated scheduling test';

SELECT @BookingID = MAX(BookingID)
FROM dbo.Bookings
WHERE PetID = 4
  AND VetID = 3
  AND AppointmentAt = @TestTime;

IF @BookingID IS NULL
    THROW 50900,
          'FAIL: valid booking was not created.',
          1;

SELECT @AuditCount = COUNT(*)
FROM dbo.BookingAudit
WHERE BookingID = @BookingID
  AND ActionType = 'INSERT';

IF @AuditCount <> 1
    THROW 50900,
          'FAIL: booking INSERT was not audited.',
          1;

PRINT 'PASS: valid booking';
PRINT 'PASS: INSERT audit';

/* ============================================================
   TEST 2 - DUPLICATE VET SLOT
   ============================================================ */

BEGIN TRY

    EXEC dbo.usp_CreateBooking
        @PetID = 5,
        @VetID = 3,
        @AppointmentAt = @TestTime,
        @Reason = N'Duplicate slot test';

    THROW 50900,
          'FAIL: duplicate veterinarian slot was accepted.',
          1;

END TRY
BEGIN CATCH

    IF ERROR_NUMBER() <> 50900
        THROW;

    PRINT 'PASS: duplicate veterinarian slot rejected';

END CATCH;

/* ============================================================
   TEST 3 - INVALID PET
   ============================================================ */

BEGIN TRY

    EXEC dbo.usp_CreateBooking
        @PetID = 999999,
        @VetID = 1,
        @AppointmentAt =
            DATEADD(DAY, 40, SYSDATETIME()),
        @Reason = N'Invalid pet test';

    THROW 50900,
          'FAIL: invalid pet was accepted.',
          1;

END TRY
BEGIN CATCH

    IF ERROR_NUMBER() <> 50900
        THROW;

    PRINT 'PASS: invalid pet rejected';

END CATCH;

/* ============================================================
   TEST 4 - CANCEL BOOKING
   ============================================================ */

EXEC dbo.usp_CancelBooking
    @BookingID = @BookingID;

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.Bookings
    WHERE BookingID = @BookingID
      AND Status = 'CANCELLED'
)
    THROW 50900,
          'FAIL: booking was not cancelled.',
          1;

SELECT @AuditCount = COUNT(*)
FROM dbo.BookingAudit
WHERE BookingID = @BookingID
  AND ActionType = 'UPDATE'
  AND OldStatus = 'SCHEDULED'
  AND NewStatus = 'CANCELLED';

IF @AuditCount <> 1
    THROW 50900,
          'FAIL: cancellation was not audited.',
          1;

PRINT 'PASS: booking cancellation';
PRINT 'PASS: cancellation audit';

PRINT 'PASS: test_scheduling.sql';
GO