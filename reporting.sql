/* ============================================================
   PawCareDB - reporting.sql
   ============================================================ */

USE PawCareDB;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO

/* ============================================================
   ACTIVE APPOINTMENTS VIEW
   ============================================================ */

DROP VIEW IF EXISTS dbo.vw_ActiveAppointments;
GO

CREATE VIEW dbo.vw_ActiveAppointments
AS
SELECT
    b.BookingID,
    b.AppointmentAt,
    p.PetID,
    p.PetName,
    p.Species,
    p.Breed,
    c.ClientID,
    c.FullName AS ClientName,
    c.Phone AS ClientPhone,
    v.VetID,
    v.FullName AS VetName,
    b.Reason,
    b.Status
FROM dbo.Bookings b
INNER JOIN dbo.Pets p
    ON p.PetID = b.PetID
INNER JOIN dbo.Clients c
    ON c.ClientID = p.ClientID
INNER JOIN dbo.Vets v
    ON v.VetID = b.VetID
WHERE b.Status = 'SCHEDULED';
GO

/* ============================================================
   INVOICE TOTALS VIEW
   ============================================================ */

DROP VIEW IF EXISTS dbo.vw_InvoiceTotals;
GO

CREATE VIEW dbo.vw_InvoiceTotals
AS
SELECT
    i.InvoiceID,
    i.ClientID,
    c.FullName AS ClientName,
    i.BookingID,
    i.InvoiceDate,
    i.Status,
    ISNULL(
        SUM(ii.Quantity * ii.UnitPrice),
        CONVERT(DECIMAL(38,2), 0)
    ) AS InvoiceTotal
FROM dbo.Invoices i
INNER JOIN dbo.Clients c
    ON c.ClientID = i.ClientID
LEFT JOIN dbo.InvoiceItems ii
    ON ii.InvoiceID = i.InvoiceID
GROUP BY
    i.InvoiceID,
    i.ClientID,
    c.FullName,
    i.BookingID,
    i.InvoiceDate,
    i.Status;
GO

/* ============================================================
   INDEXED VIEW
   ============================================================ */

DROP VIEW IF EXISTS dbo.vw_InvoiceSummaryIndexed;
GO

CREATE VIEW dbo.vw_InvoiceSummaryIndexed
WITH SCHEMABINDING
AS
SELECT
    ii.InvoiceID,
    COUNT_BIG(*) AS ItemCount,
    SUM(ii.Quantity) AS TotalQuantity,
    SUM(ii.Quantity * ii.UnitPrice) AS TotalAmount
FROM dbo.InvoiceItems AS ii
GROUP BY ii.InvoiceID;
GO

CREATE UNIQUE CLUSTERED INDEX IX_vw_InvoiceSummaryIndexed
ON dbo.vw_InvoiceSummaryIndexed(InvoiceID);
GO