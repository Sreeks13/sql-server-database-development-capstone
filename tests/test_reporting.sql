/* ============================================================
   PawCareDB - test_reporting.sql
   ============================================================ */

USE PawCareDB;
GO

SET NOCOUNT ON;
GO

/* ============================================================
   TEST 1 - ACTIVE APPOINTMENT VIEW
   ============================================================ */

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.vw_ActiveAppointments
)
    THROW 50900,
          'FAIL: active appointment view returned no rows.',
          1;

PRINT 'PASS: active appointment view';

/* ============================================================
   TEST 2 - INVOICE TOTAL
   ============================================================ */

DECLARE @InvoiceTotal DECIMAL(38,2);

SELECT @InvoiceTotal = InvoiceTotal
FROM dbo.vw_InvoiceTotals
WHERE InvoiceID = 1;

IF @InvoiceTotal <> 1250.00
    THROW 50900,
          'FAIL: invoice total is incorrect.',
          1;

PRINT 'PASS: invoice total';

/* ============================================================
   TEST 3 - INDEXED VIEW
   ============================================================ */

DECLARE @IndexedTotal DECIMAL(38,2);

SELECT @IndexedTotal = TotalAmount
FROM dbo.vw_InvoiceSummaryIndexed
WHERE InvoiceID = 1;

IF @IndexedTotal <> 1250.00
    THROW 50900,
          'FAIL: indexed view total is incorrect.',
          1;

PRINT 'PASS: indexed view';

/* ============================================================
   TEST 4 - PET AGE FUNCTION
   ============================================================ */

DECLARE @Age INT;

SELECT @Age =
    dbo.fn_PetAge('2020-04-15');

IF @Age IS NULL OR @Age < 0
    THROW 50900,
          'FAIL: pet age function returned invalid value.',
          1;

PRINT 'PASS: pet age function';

PRINT 'PASS: test_reporting.sql';
GO