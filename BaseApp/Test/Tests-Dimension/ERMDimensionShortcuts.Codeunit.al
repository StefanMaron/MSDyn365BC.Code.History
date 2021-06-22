codeunit 134485 "ERM Dimension Shortcuts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension] [Shortcuts]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDimShortcutVisibility()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [GIVEN] Dimension Shortcuts defined by General Ledger Setup
        Initialize;
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', '', 1, '', 0D);

        // [WHEN] Open page Sales Order
        SalesOrder.OpenNew;

        // [THEN] Defined Dimension Shortcuts are visible, others are not
        AssertVisibility(1, SalesOrder.SalesLines."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(2, SalesOrder.SalesLines."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(3, SalesOrder.SalesLines.ShortcutDimCode3.Visible);
        AssertVisibility(4, SalesOrder.SalesLines.ShortcutDimCode4.Visible);
        AssertVisibility(5, SalesOrder.SalesLines.ShortcutDimCode5.Visible);
        AssertVisibility(6, SalesOrder.SalesLines.ShortcutDimCode6.Visible);
        AssertVisibility(7, SalesOrder.SalesLines.ShortcutDimCode7.Visible);
        AssertVisibility(8, SalesOrder.SalesLines.ShortcutDimCode8.Visible);
        SalesOrder.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteDimShortcutVisibility()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [GIVEN] Dimension Shortcuts defined by General Ledger Setup
        Initialize;
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote, '', '', 1, '', 0D);

        // [WHEN] Open page Sales Quote
        SalesQuote.OpenNew;

        // [THEN] Defined Dimension Shortcuts are visible, others are not
        AssertVisibility(1, SalesQuote.SalesLines."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(2, SalesQuote.SalesLines."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(3, SalesQuote.SalesLines.ShortcutDimCode3.Visible);
        AssertVisibility(4, SalesQuote.SalesLines.ShortcutDimCode4.Visible);
        AssertVisibility(5, SalesQuote.SalesLines.ShortcutDimCode5.Visible);
        AssertVisibility(6, SalesQuote.SalesLines.ShortcutDimCode6.Visible);
        AssertVisibility(7, SalesQuote.SalesLines.ShortcutDimCode7.Visible);
        AssertVisibility(8, SalesQuote.SalesLines.ShortcutDimCode8.Visible);
        SalesQuote.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceDimShortcutVisibility()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [GIVEN] Dimension Shortcuts defined by General Ledger Setup
        Initialize;
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '', '', 1, '', 0D);

        // [WHEN] Open page Sales Invoice
        SalesInvoice.OpenNew;

        // [THEN] Defined Dimension Shortcuts are visible, others are not
        AssertVisibility(1, SalesInvoice.SalesLines."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(2, SalesInvoice.SalesLines."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(3, SalesInvoice.SalesLines.ShortcutDimCode3.Visible);
        AssertVisibility(4, SalesInvoice.SalesLines.ShortcutDimCode4.Visible);
        AssertVisibility(5, SalesInvoice.SalesLines.ShortcutDimCode5.Visible);
        AssertVisibility(6, SalesInvoice.SalesLines.ShortcutDimCode6.Visible);
        AssertVisibility(7, SalesInvoice.SalesLines.ShortcutDimCode7.Visible);
        AssertVisibility(8, SalesInvoice.SalesLines.ShortcutDimCode8.Visible);
        SalesInvoice.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoDimShortcutVisibility()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [GIVEN] Dimension Shortcuts defined by General Ledger Setup
        Initialize;
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '', '', 1, '', 0D);

        // [WHEN] Open page Sales Credit Memo
        SalesCreditMemo.OpenNew;

        // [THEN] Defined Dimension Shortcuts are visible, others are not
        AssertVisibility(1, SalesCreditMemo.SalesLines."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(2, SalesCreditMemo.SalesLines."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(3, SalesCreditMemo.SalesLines.ShortcutDimCode3.Visible);
        AssertVisibility(4, SalesCreditMemo.SalesLines.ShortcutDimCode4.Visible);
        AssertVisibility(5, SalesCreditMemo.SalesLines.ShortcutDimCode5.Visible);
        AssertVisibility(6, SalesCreditMemo.SalesLines.ShortcutDimCode6.Visible);
        AssertVisibility(7, SalesCreditMemo.SalesLines.ShortcutDimCode7.Visible);
        AssertVisibility(8, SalesCreditMemo.SalesLines.ShortcutDimCode8.Visible);
        SalesCreditMemo.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderDimShortcutVisibility()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [GIVEN] Dimension Shortcuts defined by General Ledger Setup
        Initialize;
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '', '', 1, '', 0D);

        // [WHEN] Open page Sales Return Order
        SalesReturnOrder.OpenNew;

        // [THEN] Defined Dimension Shortcuts are visible, others are not
        AssertVisibility(1, SalesReturnOrder.SalesLines."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(2, SalesReturnOrder.SalesLines."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(3, SalesReturnOrder.SalesLines.ShortcutDimCode3.Visible);
        AssertVisibility(4, SalesReturnOrder.SalesLines.ShortcutDimCode4.Visible);
        AssertVisibility(5, SalesReturnOrder.SalesLines.ShortcutDimCode5.Visible);
        AssertVisibility(6, SalesReturnOrder.SalesLines.ShortcutDimCode6.Visible);
        AssertVisibility(7, SalesReturnOrder.SalesLines.ShortcutDimCode7.Visible);
        AssertVisibility(8, SalesReturnOrder.SalesLines.ShortcutDimCode8.Visible);
        SalesReturnOrder.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderDimShortcutVisibility()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchOrder: TestPage "Purchase Order";
    begin
        // [GIVEN] Dimension Shortcuts defined by General Ledger Setup
        Initialize;
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '', '', 1, '', 0D);

        // [WHEN] Open page Purchase Order
        PurchOrder.OpenNew;

        // [THEN] Defined Dimension Shortcuts are visible, others are not
        AssertVisibility(1, PurchOrder.PurchLines."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(2, PurchOrder.PurchLines."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(3, PurchOrder.PurchLines.ShortcutDimCode3.Visible);
        AssertVisibility(4, PurchOrder.PurchLines.ShortcutDimCode4.Visible);
        AssertVisibility(5, PurchOrder.PurchLines.ShortcutDimCode5.Visible);
        AssertVisibility(6, PurchOrder.PurchLines.ShortcutDimCode6.Visible);
        AssertVisibility(7, PurchOrder.PurchLines.ShortcutDimCode7.Visible);
        AssertVisibility(8, PurchOrder.PurchLines.ShortcutDimCode8.Visible);
        PurchOrder.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchQuoteDimShortcutVisibility()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchQuote: TestPage "Purchase Quote";
    begin
        // [GIVEN] Dimension Shortcuts defined by General Ledger Setup
        Initialize;
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchHeader, PurchLine, PurchHeader."Document Type"::Quote, '', '', 1, '', 0D);

        // [WHEN] Open page Purchase Quote
        PurchQuote.OpenNew;

        // [THEN] Defined Dimension Shortcuts are visible, others are not
        AssertVisibility(1, PurchQuote.PurchLines."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(2, PurchQuote.PurchLines."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(3, PurchQuote.PurchLines.ShortcutDimCode3.Visible);
        AssertVisibility(4, PurchQuote.PurchLines.ShortcutDimCode4.Visible);
        AssertVisibility(5, PurchQuote.PurchLines.ShortcutDimCode5.Visible);
        AssertVisibility(6, PurchQuote.PurchLines.ShortcutDimCode6.Visible);
        AssertVisibility(7, PurchQuote.PurchLines.ShortcutDimCode7.Visible);
        AssertVisibility(8, PurchQuote.PurchLines.ShortcutDimCode8.Visible);
        PurchQuote.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceDimShortcutVisibility()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvoice: TestPage "Purchase Invoice";
    begin
        // [GIVEN] Dimension Shortcuts defined by General Ledger Setup
        Initialize;
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '', '', 1, '', 0D);

        // [WHEN] Open page Purchase Invoice
        PurchInvoice.OpenNew;

        // [THEN] Defined Dimension Shortcuts are visible, others are not
        AssertVisibility(1, PurchInvoice.PurchLines."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(2, PurchInvoice.PurchLines."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(3, PurchInvoice.PurchLines.ShortcutDimCode3.Visible);
        AssertVisibility(4, PurchInvoice.PurchLines.ShortcutDimCode4.Visible);
        AssertVisibility(5, PurchInvoice.PurchLines.ShortcutDimCode5.Visible);
        AssertVisibility(6, PurchInvoice.PurchLines.ShortcutDimCode6.Visible);
        AssertVisibility(7, PurchInvoice.PurchLines.ShortcutDimCode7.Visible);
        AssertVisibility(8, PurchInvoice.PurchLines.ShortcutDimCode8.Visible);
        PurchInvoice.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoDimShortcutVisibility()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [GIVEN] Dimension Shortcuts defined by General Ledger Setup
        Initialize;
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchHeader, PurchLine, PurchHeader."Document Type"::"Credit Memo", '', '', 1, '', 0D);

        // [WHEN] Open page Purchase Credit Memo
        PurchCreditMemo.OpenNew;

        // [THEN] Defined Dimension Shortcuts are visible, others are not
        AssertVisibility(1, PurchCreditMemo.PurchLines."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(2, PurchCreditMemo.PurchLines."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(3, PurchCreditMemo.PurchLines.ShortcutDimCode3.Visible);
        AssertVisibility(4, PurchCreditMemo.PurchLines.ShortcutDimCode4.Visible);
        AssertVisibility(5, PurchCreditMemo.PurchLines.ShortcutDimCode5.Visible);
        AssertVisibility(6, PurchCreditMemo.PurchLines.ShortcutDimCode6.Visible);
        AssertVisibility(7, PurchCreditMemo.PurchLines.ShortcutDimCode7.Visible);
        AssertVisibility(8, PurchCreditMemo.PurchLines.ShortcutDimCode8.Visible);
        PurchCreditMemo.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnOrderDimShortcutVisibility()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchReturnOrder: TestPage "Purchase Return Order";
    begin
        // [GIVEN] Dimension Shortcuts defined by General Ledger Setup
        Initialize;
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order", '', '', 1, '', 0D);

        // [WHEN] Open page Purchase Return Order
        PurchReturnOrder.OpenNew;

        // [THEN] Defined Dimension Shortcuts are visible, others are not
        AssertVisibility(1, PurchReturnOrder.PurchLines."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(2, PurchReturnOrder.PurchLines."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(3, PurchReturnOrder.PurchLines.ShortcutDimCode3.Visible);
        AssertVisibility(4, PurchReturnOrder.PurchLines.ShortcutDimCode4.Visible);
        AssertVisibility(5, PurchReturnOrder.PurchLines.ShortcutDimCode5.Visible);
        AssertVisibility(6, PurchReturnOrder.PurchLines.ShortcutDimCode6.Visible);
        AssertVisibility(7, PurchReturnOrder.PurchLines.ShortcutDimCode7.Visible);
        AssertVisibility(8, PurchReturnOrder.PurchLines.ShortcutDimCode8.Visible);
        PurchReturnOrder.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDimShortcutVisibilityAll()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [GIVEN] All Dimension Shortcuts defined by General Ledger Setup
        Initialize;

        SetGLSetupAllDimensions;

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', '', 1, '', 0D);

        // [WHEN] Open page Sales Order
        SalesOrder.OpenNew;

        // [THEN] All Dimension Shortcuts are visible
        Assert.IsTrue(SalesOrder.SalesLines.ShortcutDimCode3.Visible, 'Dim Shortcut 3 must be visible');
        Assert.IsTrue(SalesOrder.SalesLines.ShortcutDimCode4.Visible, 'Dim Shortcut 4 must be visible');
        Assert.IsTrue(SalesOrder.SalesLines.ShortcutDimCode5.Visible, 'Dim Shortcut 5 must be visible');
        Assert.IsTrue(SalesOrder.SalesLines.ShortcutDimCode6.Visible, 'Dim Shortcut 6 must be visible');
        Assert.IsTrue(SalesOrder.SalesLines.ShortcutDimCode7.Visible, 'Dim Shortcut 7 must be visible');
        Assert.IsTrue(SalesOrder.SalesLines.ShortcutDimCode8.Visible, 'Dim Shortcut 8 must be visible');
        SalesOrder.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDimShortcutVisibilityNone()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [GIVEN] None Dimension Shortcuts defined by General Ledger Setup
        Initialize;
        ClearDimShortcuts;

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', '', 1, '', 0D);

        // [WHEN] Open page Sales Order
        SalesOrder.OpenNew;

        // [THEN] None Dimension Shortcuts are visible
        Assert.IsFalse(SalesOrder.SalesLines.ShortcutDimCode3.Visible, 'Dim Shortcut 3 must not be visible');
        Assert.IsFalse(SalesOrder.SalesLines.ShortcutDimCode4.Visible, 'Dim Shortcut 4 must not be visible');
        Assert.IsFalse(SalesOrder.SalesLines.ShortcutDimCode5.Visible, 'Dim Shortcut 5 must not be visible');
        Assert.IsFalse(SalesOrder.SalesLines.ShortcutDimCode6.Visible, 'Dim Shortcut 6 must not be visible');
        Assert.IsFalse(SalesOrder.SalesLines.ShortcutDimCode7.Visible, 'Dim Shortcut 7 must not be visible');
        Assert.IsFalse(SalesOrder.SalesLines.ShortcutDimCode8.Visible, 'Dim Shortcut 8 must not be visible');
        SalesOrder.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDimShortcutVisibilitySelected()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        DimShortcuts: array[6] of Boolean;
    begin
        // [GIVEN] Three random Dimension Shortcuts defined by General Ledger Setup
        Initialize;

        Clear(DimShortcuts);
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        ClearDimShortcuts;
        AssignGLSetupShortcuts(DimShortcuts);

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', '', 1, '', 0D);

        // [WHEN] Open page Sales Order
        SalesOrder.OpenNew;

        // [THEN] Only 3 defined Dimension Shortcuts are visible, others 3 are not
        Assert.AreEqual(SalesOrder.SalesLines.ShortcutDimCode3.Visible, DimShortcuts[1], 'Dim Shortcut 3');
        Assert.AreEqual(SalesOrder.SalesLines.ShortcutDimCode4.Visible, DimShortcuts[2], 'Dim Shortcut 4');
        Assert.AreEqual(SalesOrder.SalesLines.ShortcutDimCode5.Visible, DimShortcuts[3], 'Dim Shortcut 5');
        Assert.AreEqual(SalesOrder.SalesLines.ShortcutDimCode6.Visible, DimShortcuts[4], 'Dim Shortcut 6');
        Assert.AreEqual(SalesOrder.SalesLines.ShortcutDimCode7.Visible, DimShortcuts[5], 'Dim Shortcut 7');
        Assert.AreEqual(SalesOrder.SalesLines.ShortcutDimCode8.Visible, DimShortcuts[6], 'Dim Shortcut 8');
        SalesOrder.Close;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteArchiveDimShortcutVisibility()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ArchiveManagement: Codeunit ArchiveManagement;
        SalesQuoteArchive: TestPage "Sales Quote Archive";
    begin
        // [SCENARIO 302075] Sales quote archive line dimensions shortcuts displayed properly
        Initialize;

        // [GIVEN] Set up all 8 dimensions in General Ledger Setup
        SetGLSetupAllDimensions;

        // [GIVEN] Make sales quote archive
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote, '', '', 1, '', 0D);
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        // [WHEN] Open page Sales Quote Archive
        SalesQuoteArchive.OpenEdit;
        SalesQuoteArchive.FILTER.SetFilter("No.", SalesHeader."No.");

        // [THEN] All defined Dimension Shortcuts are visible
        AssertVisibility(1, SalesQuoteArchive.SalesLinesArchive."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(2, SalesQuoteArchive.SalesLinesArchive."Shortcut Dimension 2 Code".Visible);
        AssertVisibility(3, SalesQuoteArchive.SalesLinesArchive.ShortcutDimCode3.Visible);
        AssertVisibility(4, SalesQuoteArchive.SalesLinesArchive.ShortcutDimCode4.Visible);
        AssertVisibility(5, SalesQuoteArchive.SalesLinesArchive.ShortcutDimCode5.Visible);
        AssertVisibility(6, SalesQuoteArchive.SalesLinesArchive.ShortcutDimCode6.Visible);
        AssertVisibility(7, SalesQuoteArchive.SalesLinesArchive.ShortcutDimCode7.Visible);
        AssertVisibility(8, SalesQuoteArchive.SalesLinesArchive.ShortcutDimCode8.Visible);
        SalesQuoteArchive.Close;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchQuoteArchiveDimShortcutVisibility()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ArchiveManagement: Codeunit ArchiveManagement;
        PurchaseQuoteArchive: TestPage "Purchase Quote Archive";
    begin
        // [SCENARIO 302075] Purchase quote archive line dimensions shortcuts displayed properly
        Initialize;

        // [GIVEN] Set up all 8 dimensions in General Ledger Setup
        SetGLSetupAllDimensions;

        // [GIVEN] Make purchase quote archive
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Quote, '', '', 1, '', 0D);
        ArchiveManagement.ArchivePurchDocument(PurchaseHeader);

        // [WHEN] Open page Purchase Quote Archive
        PurchaseQuoteArchive.OpenEdit;
        PurchaseQuoteArchive.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] All defined Dimension Shortcuts are visible
        AssertVisibility(1, PurchaseQuoteArchive.PurchLinesArchive."Shortcut Dimension 1 Code".Visible);
        AssertVisibility(2, PurchaseQuoteArchive.PurchLinesArchive."Shortcut Dimension 2 Code".Visible);
        AssertVisibility(3, PurchaseQuoteArchive.PurchLinesArchive.ShortcutDimCode3.Visible);
        AssertVisibility(4, PurchaseQuoteArchive.PurchLinesArchive.ShortcutDimCode4.Visible);
        AssertVisibility(5, PurchaseQuoteArchive.PurchLinesArchive.ShortcutDimCode5.Visible);
        AssertVisibility(6, PurchaseQuoteArchive.PurchLinesArchive.ShortcutDimCode6.Visible);
        AssertVisibility(7, PurchaseQuoteArchive.PurchLinesArchive.ShortcutDimCode7.Visible);
        AssertVisibility(8, PurchaseQuoteArchive.PurchLinesArchive.ShortcutDimCode8.Visible);
        PurchaseQuoteArchive.Close;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Dimension Shortcuts");
        LibrarySetupStorage.Restore;
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Dimension Shortcuts");

        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Dimension Shortcuts");
    end;

    local procedure AssignGLSetupShortcuts(DimShortcuts: array[6] of Boolean)
    var
        Dimension: Record Dimension;
        GLSetup: Record "General Ledger Setup";
        DimIndex: Integer;
    begin
        GLSetup.Get();
        for DimIndex := 1 to 6 do
            if DimShortcuts[DimIndex] then begin
                LibraryDimension.CreateDimension(Dimension);
                case DimIndex of
                    1:
                        GLSetup.Validate("Shortcut Dimension 3 Code", Dimension.Code);
                    2:
                        GLSetup.Validate("Shortcut Dimension 4 Code", Dimension.Code);
                    3:
                        GLSetup.Validate("Shortcut Dimension 5 Code", Dimension.Code);
                    4:
                        GLSetup.Validate("Shortcut Dimension 6 Code", Dimension.Code);
                    5:
                        GLSetup.Validate("Shortcut Dimension 7 Code", Dimension.Code);
                    6:
                        GLSetup.Validate("Shortcut Dimension 8 Code", Dimension.Code);
                end;
            end;

        GLSetup.Modify();
    end;

    local procedure AssertVisibility(DimNo: Integer; ShortcutVisible: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
        UseSetupShortcut: Boolean;
    begin
        GLSetup.Get();
        case DimNo of
            1:
                UseSetupShortcut := GLSetup."Shortcut Dimension 1 Code" <> '';
            2:
                UseSetupShortcut := GLSetup."Shortcut Dimension 2 Code" <> '';
            3:
                UseSetupShortcut := GLSetup."Shortcut Dimension 3 Code" <> '';
            4:
                UseSetupShortcut := GLSetup."Shortcut Dimension 4 Code" <> '';
            5:
                UseSetupShortcut := GLSetup."Shortcut Dimension 5 Code" <> '';
            6:
                UseSetupShortcut := GLSetup."Shortcut Dimension 6 Code" <> '';
            7:
                UseSetupShortcut := GLSetup."Shortcut Dimension 7 Code" <> '';
            8:
                UseSetupShortcut := GLSetup."Shortcut Dimension 8 Code" <> '';
        end;
        if UseSetupShortcut then
            Assert.AreEqual(ShortcutVisible, UseSetupShortcut, StrSubstNo('Dim Shortcut %1 must be visible', DimNo))
        else
            Assert.AreEqual(ShortcutVisible, UseSetupShortcut, StrSubstNo('Dim Shortcut %1 must not be visible', DimNo));
    end;

    local procedure ClearDimShortcuts()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Shortcut Dimension 3 Code", '');
        GLSetup.Validate("Shortcut Dimension 4 Code", '');
        GLSetup.Validate("Shortcut Dimension 5 Code", '');
        GLSetup.Validate("Shortcut Dimension 6 Code", '');
        GLSetup.Validate("Shortcut Dimension 7 Code", '');
        GLSetup.Validate("Shortcut Dimension 8 Code", '');
        GLSetup.Modify();
    end;

    local procedure SetGLSetupAllDimensions()
    var
        GLSetup: Record "General Ledger Setup";
        Dimension: Record Dimension;
    begin
        GLSetup.Get();
        LibraryDimension.CreateDimension(Dimension);
        GLSetup.Validate("Shortcut Dimension 3 Code", Dimension.Code);
        LibraryDimension.CreateDimension(Dimension);
        GLSetup.Validate("Shortcut Dimension 4 Code", Dimension.Code);
        LibraryDimension.CreateDimension(Dimension);
        GLSetup.Validate("Shortcut Dimension 5 Code", Dimension.Code);
        LibraryDimension.CreateDimension(Dimension);
        GLSetup.Validate("Shortcut Dimension 6 Code", Dimension.Code);
        LibraryDimension.CreateDimension(Dimension);
        GLSetup.Validate("Shortcut Dimension 7 Code", Dimension.Code);
        LibraryDimension.CreateDimension(Dimension);
        GLSetup.Validate("Shortcut Dimension 8 Code", Dimension.Code);
        GLSetup.Modify();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;
}

