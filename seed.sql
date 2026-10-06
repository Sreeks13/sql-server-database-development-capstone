/* ============================================================
   PawCareDB - seed.sql
   ============================================================ */

USE PawCareDB;
GO

/* ============================================================
   CLIENTS
   ============================================================ */

IF NOT EXISTS
(
    SELECT 1 FROM dbo.Clients
)
BEGIN
    INSERT INTO dbo.Clients
    (
        FullName,
        Phone,
        Email,
        AddressLine
    )
    VALUES
    (
        N'Aarav Sharma',
        N'9876543210',
        N'aarav@example.com',
        N'Bengaluru'
    ),
    (
        N'Priya Nair',
        N'9876543211',
        N'priya@example.com',
        N'Chennai'
    ),
    (
        N'Rahul Mehta',
        N'9876543212',
        N'rahul@example.com',
        N'Mumbai'
    ),
    (
        N'Sneha Rao',
        N'9876543213',
        N'sneha@example.com',
        N'Hyderabad'
    );
END;
GO

/* ============================================================
   VETS
   ============================================================ */

IF NOT EXISTS
(
    SELECT 1 FROM dbo.Vets
)
BEGIN
    INSERT INTO dbo.Vets
    (
        FullName,
        Specialization,
        Phone
    )
    VALUES
    (
        N'Dr. Ananya Kapoor',
        N'General Veterinary Medicine',
        N'9000000001'
    ),
    (
        N'Dr. Vikram Singh',
        N'Surgery',
        N'9000000002'
    ),
    (
        N'Dr. Meera Iyer',
        N'Dermatology',
        N'9000000003'
    );
END;
GO

/* ============================================================
   PETS
   ============================================================ */

IF NOT EXISTS
(
    SELECT 1 FROM dbo.Pets
)
BEGIN
    INSERT INTO dbo.Pets
    (
        ClientID,
        PetName,
        Species,
        Breed,
        DateOfBirth,
        Sex,
        WeightKg
    )
    VALUES
    (
        1,
        N'Bruno',
        N'Dog',
        N'Labrador',
        '2020-04-15',
        'M',
        24.50
    ),
    (
        1,
        N'Milo',
        N'Cat',
        N'Persian',
        '2021-08-20',
        'M',
        4.80
    ),
    (
        2,
        N'Luna',
        N'Dog',
        N'Beagle',
        '2019-11-05',
        'F',
        12.30
    ),
    (
        3,
        N'Max',
        N'Dog',
        N'Golden Retriever',
        '2018-02-10',
        'M',
        28.70
    ),
    (
        4,
        N'Coco',
        N'Cat',
        N'Siamese',
        '2022-01-25',
        'F',
        3.90
    );
END;
GO

/* ============================================================
   BOOKINGS
   ============================================================ */

IF NOT EXISTS
(
    SELECT 1 FROM dbo.Bookings
)
BEGIN
    DECLARE @Tomorrow DATETIME2(0);

    SET @Tomorrow =
        DATEADD(
            DAY,
            1,
            CAST(CAST(GETDATE() AS DATE) AS DATETIME2(0))
        );

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
        1,
        1,
        DATEADD(HOUR, 10, @Tomorrow),
        N'Annual health check',
        N'SCHEDULED'
    ),
    (
        2,
        2,
        DATEADD(HOUR, 12, @Tomorrow),
        N'Dental examination',
        N'SCHEDULED'
    ),
    (
        3,
        1,
        DATEADD(HOUR, 14, @Tomorrow),
        N'Vaccination',
        N'SCHEDULED'
    );
END;
GO

/* ============================================================
   TREATMENTS
   ============================================================ */

IF NOT EXISTS
(
    SELECT 1 FROM dbo.Treatments
)
BEGIN
    INSERT INTO dbo.Treatments
    (
        BookingID,
        TreatmentName,
        Description,
        Cost
    )
    VALUES
    (
        1,
        N'General Examination',
        N'Routine physical examination',
        500.00
    ),
    (
        1,
        N'Vaccination',
        N'Annual vaccination',
        750.00
    ),
    (
        2,
        N'Dental Cleaning',
        N'Professional dental cleaning',
        1500.00
    );
END;
GO

/* Treatment means the appointment was completed. */
UPDATE dbo.Bookings
SET Status = 'COMPLETED'
WHERE BookingID IN (1,2)
  AND EXISTS
  (
      SELECT 1
      FROM dbo.Treatments
      WHERE Treatments.BookingID = Bookings.BookingID
  );
GO

/* ============================================================
   INVOICES
   ============================================================ */

IF NOT EXISTS
(
    SELECT 1 FROM dbo.Invoices
)
BEGIN
    INSERT INTO dbo.Invoices
    (
        ClientID,
        BookingID,
        Status
    )
    VALUES
    (
        1,
        1,
        N'PAID'
    ),
    (
        1,
        2,
        N'UNPAID'
    ),
    (
        2,
        NULL,
        N'UNPAID'
    );
END;
GO

/* ============================================================
   INVOICE ITEMS
   ============================================================ */

IF NOT EXISTS
(
    SELECT 1 FROM dbo.InvoiceItems
)
BEGIN
    INSERT INTO dbo.InvoiceItems
    (
        InvoiceID,
        Description,
        Quantity,
        UnitPrice
    )
    VALUES
    (
        1,
        N'General Examination',
        1,
        500.00
    ),
    (
        1,
        N'Vaccination',
        1,
        750.00
    ),
    (
        2,
        N'Dental Cleaning',
        1,
        1500.00
    ),
    (
        3,
        N'Consultation',
        1,
        500.00
    );
END;
GO