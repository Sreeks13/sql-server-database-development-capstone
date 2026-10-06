/* ============================================================
   PawCareDB - schema.sql
   ============================================================ */

IF DB_ID(N'PawCareDB') IS NULL
BEGIN
    THROW 50900, 'PawCareDB database must exist before running schema.sql.', 1;
END;
GO

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

/* Clean existing objects */
DROP TRIGGER IF EXISTS dbo.trg_Bookings_Audit;
GO

DROP VIEW IF EXISTS dbo.vw_InvoiceSummaryIndexed;
GO

DROP VIEW IF EXISTS dbo.vw_InvoiceTotals;
GO

DROP VIEW IF EXISTS dbo.vw_ActiveAppointments;
GO

DROP FUNCTION IF EXISTS dbo.fn_PetAge;
GO

DROP PROCEDURE IF EXISTS dbo.usp_CreateBooking;
GO

DROP PROCEDURE IF EXISTS dbo.usp_CancelBooking;
GO

DROP PROCEDURE IF EXISTS dbo.usp_AddTreatment;
GO

DROP PROCEDURE IF EXISTS dbo.usp_CreateInvoice;
GO

DROP TABLE IF EXISTS dbo.BookingAudit;
DROP TABLE IF EXISTS dbo.InvoiceItems;
DROP TABLE IF EXISTS dbo.Invoices;
DROP TABLE IF EXISTS dbo.Treatments;
DROP TABLE IF EXISTS dbo.Bookings;
DROP TABLE IF EXISTS dbo.Pets;
DROP TABLE IF EXISTS dbo.Vets;
DROP TABLE IF EXISTS dbo.Clients;
GO

/* ============================================================
   CLIENTS
   ============================================================ */

CREATE TABLE dbo.Clients
(
    ClientID INT IDENTITY(1,1) NOT NULL,
    FullName NVARCHAR(150) NOT NULL,
    Phone NVARCHAR(30) NOT NULL,
    Email NVARCHAR(150) NULL,
    AddressLine NVARCHAR(250) NULL,
    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_Clients_CreatedAt
        DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_Clients
        PRIMARY KEY (ClientID),

    CONSTRAINT UQ_Clients_Email
        UNIQUE (Email)
);
GO

/* ============================================================
   PETS
   ============================================================ */

CREATE TABLE dbo.Pets
(
    PetID INT IDENTITY(1,1) NOT NULL,
    ClientID INT NOT NULL,
    PetName NVARCHAR(100) NOT NULL,
    Species NVARCHAR(50) NOT NULL,
    Breed NVARCHAR(100) NULL,
    DateOfBirth DATE NULL,
    Sex CHAR(1) NULL,
    WeightKg DECIMAL(6,2) NULL,
    Active BIT NOT NULL
        CONSTRAINT DF_Pets_Active DEFAULT 1,
    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_Pets_CreatedAt
        DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_Pets
        PRIMARY KEY (PetID),

    CONSTRAINT FK_Pets_Clients
        FOREIGN KEY (ClientID)
        REFERENCES dbo.Clients(ClientID),

    CONSTRAINT CK_Pets_Sex
        CHECK (Sex IS NULL OR Sex IN ('M','F')),

    CONSTRAINT CK_Pets_Weight
        CHECK (WeightKg IS NULL OR WeightKg > 0)
);
GO

/* ============================================================
   VETS
   ============================================================ */

CREATE TABLE dbo.Vets
(
    VetID INT IDENTITY(1,1) NOT NULL,
    FullName NVARCHAR(150) NOT NULL,
    Specialization NVARCHAR(150) NULL,
    Phone NVARCHAR(30) NULL,
    Active BIT NOT NULL
        CONSTRAINT DF_Vets_Active DEFAULT 1,

    CONSTRAINT PK_Vets
        PRIMARY KEY (VetID)
);
GO

/* ============================================================
   BOOKINGS
   ============================================================ */

CREATE TABLE dbo.Bookings
(
    BookingID INT IDENTITY(1,1) NOT NULL,
    PetID INT NOT NULL,
    VetID INT NOT NULL,
    AppointmentAt DATETIME2(0) NOT NULL,
    Reason NVARCHAR(500) NULL,
    Status VARCHAR(20) NOT NULL
        CONSTRAINT DF_Bookings_Status
        DEFAULT 'SCHEDULED',
    Notes NVARCHAR(1000) NULL,
    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_Bookings_CreatedAt
        DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_Bookings
        PRIMARY KEY (BookingID),

    CONSTRAINT FK_Bookings_Pets
        FOREIGN KEY (PetID)
        REFERENCES dbo.Pets(PetID),

    CONSTRAINT FK_Bookings_Vets
        FOREIGN KEY (VetID)
        REFERENCES dbo.Vets(VetID),

    CONSTRAINT CK_Bookings_Status
        CHECK
        (
            Status IN
            (
                'SCHEDULED',
                'COMPLETED',
                'CANCELLED',
                'NO_SHOW'
            )
        )
);
GO

/* ============================================================
   TREATMENTS
   ============================================================ */

CREATE TABLE dbo.Treatments
(
    TreatmentID INT IDENTITY(1,1) NOT NULL,
    BookingID INT NOT NULL,
    TreatmentName NVARCHAR(200) NOT NULL,
    Description NVARCHAR(1000) NULL,
    Cost DECIMAL(12,2) NOT NULL,
    TreatmentAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_Treatments_TreatmentAt
        DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_Treatments
        PRIMARY KEY (TreatmentID),

    CONSTRAINT FK_Treatments_Bookings
        FOREIGN KEY (BookingID)
        REFERENCES dbo.Bookings(BookingID),

    CONSTRAINT CK_Treatments_Cost
        CHECK (Cost >= 0)
);
GO

/* ============================================================
   INVOICES
   ============================================================ */

CREATE TABLE dbo.Invoices
(
    InvoiceID INT IDENTITY(1,1) NOT NULL,
    ClientID INT NOT NULL,
    BookingID INT NULL,
    InvoiceDate DATETIME2(0) NOT NULL
        CONSTRAINT DF_Invoices_InvoiceDate
        DEFAULT SYSUTCDATETIME(),
    Status VARCHAR(20) NOT NULL
        CONSTRAINT DF_Invoices_Status
        DEFAULT 'UNPAID',

    CONSTRAINT PK_Invoices
        PRIMARY KEY (InvoiceID),

    CONSTRAINT FK_Invoices_Clients
        FOREIGN KEY (ClientID)
        REFERENCES dbo.Clients(ClientID),

    CONSTRAINT FK_Invoices_Bookings
        FOREIGN KEY (BookingID)
        REFERENCES dbo.Bookings(BookingID),

    CONSTRAINT CK_Invoices_Status
        CHECK (Status IN ('UNPAID','PAID','VOID'))
);
GO

/* ============================================================
   INVOICE ITEMS
   ============================================================ */

CREATE TABLE dbo.InvoiceItems
(
    InvoiceItemID INT IDENTITY(1,1) NOT NULL,
    InvoiceID INT NOT NULL,
    Description NVARCHAR(250) NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(12,2) NOT NULL,

    CONSTRAINT PK_InvoiceItems
        PRIMARY KEY (InvoiceItemID),

    CONSTRAINT FK_InvoiceItems_Invoices
        FOREIGN KEY (InvoiceID)
        REFERENCES dbo.Invoices(InvoiceID),

    CONSTRAINT CK_InvoiceItems_Quantity
        CHECK (Quantity > 0),

    CONSTRAINT CK_InvoiceItems_UnitPrice
        CHECK (UnitPrice >= 0)
);
GO

/* ============================================================
   BOOKING AUDIT
   ============================================================ */

CREATE TABLE dbo.BookingAudit
(
    AuditID BIGINT IDENTITY(1,1) NOT NULL,
    BookingID INT NULL,
    ActionType VARCHAR(10) NOT NULL,
    OldStatus VARCHAR(20) NULL,
    NewStatus VARCHAR(20) NULL,
    ChangedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_BookingAudit_ChangedAt
        DEFAULT SYSUTCDATETIME(),
    ChangedBy SYSNAME NOT NULL
        CONSTRAINT DF_BookingAudit_ChangedBy
        DEFAULT SUSER_SNAME(),

    CONSTRAINT PK_BookingAudit
        PRIMARY KEY (AuditID),

    CONSTRAINT CK_BookingAudit_Action
        CHECK (ActionType IN ('INSERT','UPDATE','DELETE'))
);
GO

/* ============================================================
   INDEXES
   ============================================================ */

CREATE INDEX IX_Pets_ClientID
ON dbo.Pets(ClientID);
GO

CREATE INDEX IX_Bookings_VetTime
ON dbo.Bookings(VetID, AppointmentAt, Status);
GO

CREATE INDEX IX_Bookings_PetTime
ON dbo.Bookings(PetID, AppointmentAt);
GO

CREATE INDEX IX_Treatments_BookingID
ON dbo.Treatments(BookingID);
GO

CREATE INDEX IX_Invoices_ClientID
ON dbo.Invoices(ClientID);
GO

CREATE INDEX IX_InvoiceItems_InvoiceID
ON dbo.InvoiceItems(InvoiceID);
GO