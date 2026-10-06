USE PawCareDB;
GO

-- ============================================================
-- FRONT DESK REPORT 1
-- ACTIVE APPOINTMENTS
-- ============================================================

SELECT
    BookingID,
    AppointmentAt,
    PetName,
    Species,
    Breed,
    ClientName,
    ClientPhone,
    VetName,
    Reason,
    Status
FROM dbo.vw_ActiveAppointments
ORDER BY AppointmentAt;
GO

-- ============================================================
-- FRONT DESK REPORT 2
-- ALL INVOICES
-- ============================================================

SELECT
    InvoiceID,
    ClientName,
    BookingID,
    InvoiceDate,
    Status,
    InvoiceTotal
FROM dbo.vw_InvoiceTotals
ORDER BY InvoiceDate DESC, InvoiceID DESC;
GO

-- ============================================================
-- FRONT DESK REPORT 3
-- UNPAID INVOICES
-- ============================================================

SELECT
    InvoiceID,
    ClientID,
    ClientName,
    BookingID,
    InvoiceDate,
    InvoiceTotal
FROM dbo.vw_InvoiceTotals
WHERE Status = 'UNPAID'
ORDER BY InvoiceDate;
GO

-- ============================================================
-- FRONT DESK REPORT 4
-- INVOICE SUMMARY
-- ============================================================

SELECT
    InvoiceID,
    ItemCount,
    TotalQuantity,
    TotalAmount
FROM dbo.vw_InvoiceSummaryIndexed
ORDER BY InvoiceID;
GO

-- ============================================================
-- FRONT DESK REPORT 5
-- BOOKING AUDIT TRAIL
-- ============================================================

SELECT
    AuditID,
    BookingID,
    ActionType,
    OldStatus,
    NewStatus,
    ChangedAt
FROM dbo.BookingAudit
ORDER BY ChangedAt, AuditID;
GO

-- ============================================================
-- FRONT DESK REPORT 6
-- PET MEDICAL HISTORY
-- ============================================================

SELECT
    p.PetID,
    p.PetName,
    dbo.fn_PetAge(p.DateOfBirth) AS PetAge,
    c.FullName AS Owner,
    b.BookingID,
    b.AppointmentAt,
    b.Status,
    t.TreatmentName,
    t.Description,
    t.Cost,
    t.TreatmentDate
FROM dbo.Pets AS p
INNER JOIN dbo.Clients AS c
    ON c.ClientID = p.ClientID
LEFT JOIN dbo.Bookings AS b
    ON b.PetID = p.PetID
LEFT JOIN dbo.Treatments AS t
    ON t.BookingID = b.BookingID
ORDER BY
    p.PetName,
    b.AppointmentAt;
GO

-- ============================================================
-- FRONT DESK REPORT 7
-- CLIENT BALANCES
-- ============================================================

SELECT
    ClientID,
    ClientName,

    SUM
    (
        CASE
            WHEN Status = 'UNPAID'
            THEN InvoiceTotal
            ELSE 0
        END
    ) AS OutstandingBalance,

    SUM
    (
        CASE
            WHEN Status = 'PAID'
            THEN InvoiceTotal
            ELSE 0
        END
    ) AS PaidAmount,

    SUM(InvoiceTotal) AS TotalBilled

FROM dbo.vw_InvoiceTotals

GROUP BY
    ClientID,
    ClientName

ORDER BY
    ClientName;
GO
