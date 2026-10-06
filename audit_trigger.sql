/* ============================================================
   PawCareDB - audit_trigger.sql
   ============================================================ */

USE PawCareDB;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

DROP TRIGGER IF EXISTS dbo.trg_Bookings_Audit;
GO

CREATE TRIGGER dbo.trg_Bookings_Audit
ON dbo.Bookings
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    /* INSERT */
    INSERT INTO dbo.BookingAudit
    (
        BookingID,
        ActionType,
        OldStatus,
        NewStatus
    )
    SELECT
        i.BookingID,
        'INSERT',
        NULL,
        i.Status
    FROM inserted i
    LEFT JOIN deleted d
        ON d.BookingID = i.BookingID
    WHERE d.BookingID IS NULL;

    /* DELETE */
    INSERT INTO dbo.BookingAudit
    (
        BookingID,
        ActionType,
        OldStatus,
        NewStatus
    )
    SELECT
        d.BookingID,
        'DELETE',
        d.Status,
        NULL
    FROM deleted d
    LEFT JOIN inserted i
        ON i.BookingID = d.BookingID
    WHERE i.BookingID IS NULL;

    /* UPDATE */
    INSERT INTO dbo.BookingAudit
    (
        BookingID,
        ActionType,
        OldStatus,
        NewStatus
    )
    SELECT
        i.BookingID,
        'UPDATE',
        d.Status,
        i.Status
    FROM inserted i
    INNER JOIN deleted d
        ON d.BookingID = i.BookingID;
END;
GO