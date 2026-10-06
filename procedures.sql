/* ============================================================
   PawCareDB - procedures.sql
   ============================================================ */

USE PawCareDB;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ============================================================
   CREATE BOOKING
   ============================================================ */

DROP PROCEDURE IF EXISTS dbo.usp_CreateBooking;
GO

CREATE PROCEDURE dbo.usp_CreateBooking
    @PetID INT,
    @VetID INT,
    @AppointmentAt DATETIME2(0),
    @Reason NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Pets
        WHERE PetID = @PetID
          AND Active = 1
    )
        THROW 50900,
              'Pet does not exist or is inactive.',
              1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Vets
        WHERE VetID = @VetID
          AND Active = 1
    )
        THROW 50900,
              'Veterinarian does not exist or is inactive.',
              1;

    IF @AppointmentAt <= SYSDATETIME()
        THROW 50900,
              'Appointment must be in the future.',
              1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.Bookings
        WHERE VetID = @VetID
          AND AppointmentAt = @AppointmentAt
          AND Status = 'SCHEDULED'
    )
        THROW 50900,
              'Veterinarian already has a scheduled booking at this time.',
              1;

    INSERT INTO dbo.Bookings
    (
        PetID,
        VetID,
        AppointmentAt,
        Reason,
        Status
    )
    VALUES
    (
        @PetID,
        @VetID,
        @AppointmentAt,
        @Reason,
        'SCHEDULED'
    );

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS BookingID;
END;
GO

/* ============================================================
   CANCEL BOOKING
   ============================================================ */

DROP PROCEDURE IF EXISTS dbo.usp_CancelBooking;
GO

CREATE PROCEDURE dbo.usp_CancelBooking
    @BookingID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Bookings
        WHERE BookingID = @BookingID
    )
        THROW 50900,
              'Booking does not exist.',
              1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.Bookings
        WHERE BookingID = @BookingID
          AND Status IN ('COMPLETED','CANCELLED')
    )
        THROW 50900,
              'Booking cannot be cancelled in its current status.',
              1;

    UPDATE dbo.Bookings
    SET Status = 'CANCELLED'
    WHERE BookingID = @BookingID;

    SELECT
        BookingID,
        Status
    FROM dbo.Bookings
    WHERE BookingID = @BookingID;
END;
GO

/* ============================================================
   ADD TREATMENT
   ============================================================ */

DROP PROCEDURE IF EXISTS dbo.usp_AddTreatment;
GO

CREATE PROCEDURE dbo.usp_AddTreatment
    @BookingID INT,
    @TreatmentName NVARCHAR(200),
    @Description NVARCHAR(1000) = NULL,
    @Cost DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Bookings
        WHERE BookingID = @BookingID
          AND Status <> 'CANCELLED'
    )
        THROW 50900,
              'Booking does not exist or is cancelled.',
              1;

    IF NULLIF(LTRIM(RTRIM(@TreatmentName)), N'') IS NULL
        THROW 50900,
              'Treatment name is required.',
              1;

    IF @Cost < 0
        THROW 50900,
              'Treatment cost cannot be negative.',
              1;

    INSERT INTO dbo.Treatments
    (
        BookingID,
        TreatmentName,
        Description,
        Cost
    )
    VALUES
    (
        @BookingID,
        @TreatmentName,
        @Description,
        @Cost
    );

    UPDATE dbo.Bookings
    SET Status = 'COMPLETED'
    WHERE BookingID = @BookingID
      AND Status = 'SCHEDULED';

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS TreatmentID;
END;
GO

/* ============================================================
   CREATE INVOICE
   ============================================================ */

DROP PROCEDURE IF EXISTS dbo.usp_CreateInvoice;
GO

CREATE PROCEDURE dbo.usp_CreateInvoice
    @ClientID INT,
    @BookingID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Clients
        WHERE ClientID = @ClientID
    )
        THROW 50900,
              'Client does not exist.',
              1;

    IF @BookingID IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM dbo.Bookings b
           INNER JOIN dbo.Pets p
               ON p.PetID = b.PetID
           WHERE b.BookingID = @BookingID
             AND p.ClientID = @ClientID
       )
        THROW 50900,
              'Booking does not belong to the supplied client.',
              1;

    INSERT INTO dbo.Invoices
    (
        ClientID,
        BookingID,
        Status
    )
    VALUES
    (
        @ClientID,
        @BookingID,
        'UNPAID'
    );

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS InvoiceID;
END;
GO

/* ============================================================
   PET AGE FUNCTION
   ============================================================ */

DROP FUNCTION IF EXISTS dbo.fn_PetAge;
GO

CREATE FUNCTION dbo.fn_PetAge
(
    @DateOfBirth DATE
)
RETURNS INT
AS
BEGIN
    IF @DateOfBirth IS NULL
        RETURN NULL;

    DECLARE @Today DATE =
        CAST(GETDATE() AS DATE);

    DECLARE @Age INT =
        DATEDIFF(YEAR, @DateOfBirth, @Today);

    IF DATEADD(YEAR, @Age, @DateOfBirth) > @Today
        SET @Age = @Age - 1;

    RETURN @Age;
END;
GO