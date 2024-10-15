codeunit 144018 QuoteManagement
{
    // // [FEATURE] [Sales]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        ArchiveManagement: Codeunit ArchiveManagement;
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        QuoteMgt: Codeunit QuoteMgt;
        TotalTxt: Label 'Total';
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        Initialized: Boolean;
        TotalErr: Label 'Total should be the first word in end-total';
        ExpectRecTxt: Label 'Expect to find a record';

    [Test]
    [HandlerFunctions('QuoteAnalysisRequestPageHandler,QuoteAnalysisConfirmHandler')]
    [Scope('OnPrem')]
    procedure QuoteAnalysisWithQuoteArchive()
    var
        SalesPersonPurchaser: Record "Salesperson/Purchaser";
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        Customer: Record Customer;
        Item: Record Item;
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        SalesOrder: TestPage "Sales Order";
        SalespersonPurchaserCode: Code[10];
        ArchiveType: Option " ","Converted To Order","Posted Order",Deleted;
    begin
        Initialize;
        LibraryNotificationMgt.DisableMyNotification(ItemCheckAvail.GetItemAvailabilityNotificationId);

        LibrarySales.CreateCustomer(Customer);

        LibraryInventory.CreateItem(Item);

        SalespersonPurchaserCode := CreateSalesPersonPurchaser;

        // Create Sales quote 1
        CreateSalesQuote(SalesHeader1, Customer."No.", SalespersonPurchaserCode, Item."No.");

        // Archive Sales Quote 1
        ReleaseSalesDoc.PerformManualRelease(SalesHeader1);
        ArchiveManagement.ArchSalesNoConfirmWithQuote(SalesHeader1, ArchiveType::"Converted To Order");

        // Make it as an order. This is a prequisite that the Report can run.
        // It is needed in order that the salesperson purchaser gets some activity.
        // We cannot run a report on a lazy salesperson.
        // Else we would get a division by zero error. (TFS 91065)
        SalesOrder.Trap;
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order (Yes/No)", SalesHeader1);
        SalesOrder.Close;
        // Create Sales quote 2
        CreateSalesQuote(SalesHeader2, Customer."No.", SalespersonPurchaserCode, Item."No.");

        Commit;

        // Set a filter that we only get the quotes/orders for this salespersonpurchaser.
        SalesPersonPurchaser.SetRange(Code, SalespersonPurchaserCode);

        REPORT.Run(REPORT::"Quote Analysis", true, false, SalesPersonPurchaser);

        // Verify Report Content
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('Code_SalespersonPurchaser', SalespersonPurchaserCode);

        // Expect 4 rows, 2 created + 2 totaling
        Assert.AreEqual(4, LibraryReportDataset.RowCount, 'Expected 4 rows to be found in the report');

        // See if we find the quote for sales header 2.
        LibraryReportDataset.SetRange('No_SalesHead', SalesHeader2."No.");
        LibraryReportDataset.GetNextRow;
        Assert.AreEqual(1, LibraryReportDataset.RowCount, 'Expect only 1 row found in report');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalcSalesHeader()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize;
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote);

        // Exercise
        QuoteMgt.ReCalc(SalesHeader, false);

        // Verify
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::"End-Total");

        Assert.IsTrue(SalesLine.Find('-'), ExpectRecTxt);
        repeat
            VerifyTextStartsWith(TotalTxt, SalesLine.Description, TotalErr);
        until SalesLine.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalcSalesInvoiceHeader()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        Initialize;
        CreateSalesInvoiceHeader(SalesInvoiceHeader);

        // Exercise
        QuoteMgt.RecalcPostedInvoice(SalesInvoiceHeader);

        // Verify
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::"End-Total");

        Assert.IsTrue(SalesInvoiceLine.Find('-'), ExpectRecTxt);
        repeat
            VerifyTextStartsWith(TotalTxt, SalesInvoiceLine.Description, TotalErr);
        until SalesInvoiceLine.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalcSalesCreditMemo()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        Initialize;
        CreateSalesMemoHeader(SalesCrMemoHeader);

        // Exercise
        QuoteMgt.RecalcPostedCreditMemo(SalesCrMemoHeader);

        // Verify
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::"End-Total");

        Assert.IsTrue(SalesCrMemoLine.Find('-'), ExpectRecTxt);
        repeat
            VerifyTextStartsWith(TotalTxt, SalesCrMemoLine.Description, TotalErr);
        until SalesCrMemoLine.Next = 0;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RecalculateLineOnSalesOrderPage()
    var
        SalesHeader: Record "Sales Header";
        DummySalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        EndTotalAmountText: Text;
    begin
        // [FEATURE] [Recalculate Lines]
        // [SCENARIO 220610] The Recalculate Lines function works on Sales Order page
        Initialize;

        // [GIVEN] Sales Order with lines in the following order: Item, Begin-Total, Item, End-Total
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order);

        // [WHEN] Recalculate Lines
        SalesOrder.OpenView;
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.RecalculateLines.Invoke;

        // [THEN] Description in End-Total on page line started with 'Total'
        SalesOrder.SalesLines.FILTER.SetFilter(Type, Format(DummySalesLine.Type::"End-Total"));
        VerifyTextStartsWith(TotalTxt, SalesOrder.SalesLines.Description.Value, TotalErr);

        // [THEN] "Line Amount" in End-Total line on page equals "Line Amount" in line with item between Begin-Total and End-Total
        EndTotalAmountText := SalesOrder.SalesLines."Line Amount".Value;
        SalesOrder.SalesLines.Previous();
        Assert.AreEqual(SalesOrder.SalesLines."Line Amount".Value, EndTotalAmountText, '');

        // [THEN] "Line Amount" in End-Total line equals zero
        // [THEN] Description in End-Total on page line started with 'Total'
        VerifySpecialSalesLine(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RecalculateLineOnSalesInvoicePage()
    var
        SalesHeader: Record "Sales Header";
        DummySalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        EndTotalAmountText: Text;
    begin
        // [FEATURE] [Recalculate Lines]
        // [SCENARIO 220610] The Recalculate Lines function works Sales Invoice page
        Initialize;

        // [GIVEN] Sales Order with lines in the following order: Item, Begin-Total, Item, End-Total
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [WHEN] Recalculate Lines
        SalesInvoice.OpenView;
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.RecalculateLines.Invoke;

        // [THEN] Description in End-Total on page line started with 'Total'
        SalesInvoice.SalesLines.FILTER.SetFilter(Type, Format(DummySalesLine.Type::"End-Total"));
        VerifyTextStartsWith(TotalTxt, SalesInvoice.SalesLines.Description.Value, TotalErr);

        // [THEN] "Line Amount" in End-Total line on page equals "Line Amount" in line with item between Begin-Total and End-Total
        EndTotalAmountText := SalesInvoice.SalesLines."Line Amount".Value;
        SalesInvoice.SalesLines.Previous();
        Assert.AreEqual(SalesInvoice.SalesLines."Line Amount".Value, EndTotalAmountText, '');

        // [THEN] "Line Amount" in End-Total line equals zero
        // [THEN] Description in End-Total on page line started with 'Total'
        VerifySpecialSalesLine(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RecalculateLineOnSalesCrMemoPage()
    var
        SalesHeader: Record "Sales Header";
        DummySalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        EndTotalAmountText: Text;
    begin
        // [FEATURE] [Recalculate Lines]
        // [SCENARIO 220610] The Recalculate Lines function works on Sales Credit Memo page
        Initialize;

        // [GIVEN] Sales Order with lines in the following order: Item, Begin-Total, Item, End-Total
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        // [WHEN] Recalculate Lines
        SalesCreditMemo.OpenView;
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo.RecalculateLines.Invoke;

        // [THEN] Description in End-Total on page line started with 'Total'
        SalesCreditMemo.SalesLines.FILTER.SetFilter(Type, Format(DummySalesLine.Type::"End-Total"));
        VerifyTextStartsWith(TotalTxt, SalesCreditMemo.SalesLines.Description.Value, TotalErr);

        // [THEN] "Line Amount" in End-Total line on page equals "Line Amount" in line with item between Begin-Total and End-Total
        EndTotalAmountText := SalesCreditMemo.SalesLines."Line Amount".Value;
        SalesCreditMemo.SalesLines.Previous();
        Assert.AreEqual(SalesCreditMemo.SalesLines."Line Amount".Value, EndTotalAmountText, '');

        // [THEN] "Line Amount" in End-Total line equals zero
        // [THEN] Description in End-Total on page line started with 'Total'
        VerifySpecialSalesLine(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RecalculateLineOnBlanketSalesOrderPage()
    var
        SalesHeader: Record "Sales Header";
        DummySalesLine: Record "Sales Line";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        EndTotalAmountText: Text;
    begin
        // [FEATURE] [Recalculate Lines]
        // [SCENARIO 220610] The Recalculate Lines function works on Blanket Sales Order page
        Initialize;

        // [GIVEN] Sales Order with lines in the following order: Item, Begin-Total, Item, End-Total
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order");

        // [WHEN] Recalculate Lines
        BlanketSalesOrder.OpenView;
        BlanketSalesOrder.GotoRecord(SalesHeader);
        BlanketSalesOrder.RecalculateLines.Invoke;

        // [THEN] Description in End-Total on page line started with 'Total'
        BlanketSalesOrder.SalesLines.FILTER.SetFilter(Type, Format(DummySalesLine.Type::"End-Total"));
        VerifyTextStartsWith(TotalTxt, BlanketSalesOrder.SalesLines.Description.Value, TotalErr);

        // [THEN] "Line Amount" in End-Total line on page equals "Line Amount" in line with item between Begin-Total and End-Total
        EndTotalAmountText := BlanketSalesOrder.SalesLines."Line Amount".Value;
        BlanketSalesOrder.SalesLines.Previous();
        Assert.AreEqual(BlanketSalesOrder.SalesLines."Line Amount".Value, EndTotalAmountText, '');

        // [THEN] "Line Amount" in End-Total line equals zero
        // [THEN] Description in End-Total on page line started with 'Total'
        VerifySpecialSalesLine(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RecalculateLineOnSalesReturnOrderPage()
    var
        SalesHeader: Record "Sales Header";
        DummySalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
        EndTotalAmountText: Text;
    begin
        // [FEATURE] [Recalculate Lines]
        // [SCENARIO 220610] The Recalculate Lines function works on Sales Return Order page
        Initialize;

        // [GIVEN] Sales Order with lines in the following order: Item, Begin-Total, Item, End-Total
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order");

        // [WHEN] Recalculate Lines
        SalesReturnOrder.OpenView;
        SalesReturnOrder.GotoRecord(SalesHeader);
        SalesReturnOrder.RecalculateLines.Invoke;

        // [THEN] Description in End-Total on page line started with 'Total'
        SalesReturnOrder.SalesLines.FILTER.SetFilter(Type, Format(DummySalesLine.Type::"End-Total"));
        VerifyTextStartsWith(TotalTxt, SalesReturnOrder.SalesLines.Description.Value, TotalErr);

        // [THEN] "Line Amount" in End-Total line on page equals "Line Amount" in line with item between Begin-Total and End-Total
        EndTotalAmountText := SalesReturnOrder.SalesLines."Line Amount".Value;
        SalesReturnOrder.SalesLines.Previous();
        Assert.AreEqual(SalesReturnOrder.SalesLines."Line Amount".Value, EndTotalAmountText, '');

        // [THEN] "Line Amount" in End-Total line equals zero
        // [THEN] Description in End-Total on page line started with 'Total'
        VerifySpecialSalesLine(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure QuoteArchiveOptionIsRestoredFromArchivedDocument()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // [FEATURE] [Sales] [Quote] [Archive]
        // [SCENARIO 267323] "Quote Variant" option value is restored from archived sales quote.
        Initialize;

        // [GIVEN] Sales Quote with a line set up for "Quote Variant" = "Variant".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo);
        CreateSalesLine(SalesLine, SalesHeader, LibraryInventory.CreateItemNo, SalesLine.Type::Item);
        SalesLine.Validate("Quote Variant", SalesLine."Quote Variant"::Variant);
        SalesLine.Modify(true);

        // [GIVEN] The sales quote is archived.
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);

        // [WHEN] Restore sales quote from archive.
        FindArchivedSalesDoc(SalesHeaderArchive, SalesHeader);
        ArchiveManagement.RestoreSalesDocument(SalesHeaderArchive);

        // [THEN] "Quote Variant" = "Variant" on the restored sales quote line.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Quote Variant", SalesLine."Quote Variant"::Variant);
    end;

    local procedure Initialize()
    begin
        if not Initialized then begin
            LibraryERMCountryData.UpdateGeneralPostingSetup;
            Initialized := true;
        end
    end;

    local procedure CreateSalesQuote(var SalesHeader: Record "Sales Header"; CustomerNumber: Code[20]; SalesPersonCode: Code[10]; ItemCode: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, CustomerNumber);
        SalesHeader.Validate("Salesperson Code", SalesPersonCode);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, ItemCode, SalesLine.Type::Item);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; ItemNumber: Code[20]; Type: Option)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, ItemNumber, LibraryRandom.RandInt(1000));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(1000));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesPersonPurchaser(): Code[10]
    var
        SalesPersonPurchaser: Record "Salesperson/Purchaser";
    begin
        LibrarySales.CreateSalesperson(SalesPersonPurchaser);
        SalesPersonPurchaser."Commission %" := LibraryRandom.RandInt(100);
        SalesPersonPurchaser.Modify(true);
        exit(SalesPersonPurchaser.Code);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; SalesHeaderType: Option)
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeaderType, Customer."No.");

        CreateSalesLine(SalesLine, SalesHeader, Item."No.", SalesLine.Type::Item);
        CreateSalesLineTotal(SalesLine, SalesHeader, SalesLine.Type::"Begin-Total");
        CreateSalesLine(SalesLine, SalesHeader, Item."No.", SalesLine.Type::Item);
        CreateSalesLineTotal(SalesLine, SalesHeader, SalesLine.Type::"End-Total");
    end;

    local procedure CreateSalesLineTotal(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; Type: Option)
    var
        RecRef: RecordRef;
    begin
        SalesLine.Init;
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        RecRef.GetTable(SalesLine);
        SalesLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, SalesLine.FieldNo("Line No.")));
        SalesLine.Insert(true);

        SalesLine.Validate(Type, Type);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesInvoiceHeader(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);

        SalesInvoiceHeader.Init;
        SalesInvoiceHeader.TransferFields(SalesHeader);
        SalesInvoiceHeader.Insert;

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");

        Assert.IsTrue(SalesLine.Find('-'), ExpectRecTxt);
        repeat
            SalesInvoiceLine.Init;
            SalesInvoiceLine.TransferFields(SalesLine);
            RecRef.GetTable(SalesInvoiceLine);
            SalesInvoiceLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, SalesInvoiceLine.FieldNo("Line No.")));
            SalesInvoiceLine.Insert;
        until SalesLine.Next = 0;
    end;

    local procedure CreateSalesMemoHeader(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        SalesCrMemoHeader.Init;
        SalesCrMemoHeader.TransferFields(SalesHeader);
        SalesCrMemoHeader.Insert;

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");

        Assert.IsTrue(SalesLine.Find('-'), ExpectRecTxt);
        repeat
            SalesCrMemoLine.Init;
            SalesCrMemoLine.TransferFields(SalesLine);
            RecRef.GetTable(SalesCrMemoLine);
            SalesCrMemoLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, SalesCrMemoLine.FieldNo("Line No.")));
            SalesCrMemoLine.Insert;
        until SalesLine.Next = 0;
    end;

    local procedure FindArchivedSalesDoc(var SalesHeaderArchive: Record "Sales Header Archive"; SalesHeader: Record "Sales Header")
    begin
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.FindFirst;
    end;

    local procedure VerifySpecialSalesLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::"End-Total");
        SalesLine.FindFirst;
        SalesLine.TestField("Line Amount", 0);
        VerifyTextStartsWith(TotalTxt, SalesLine.Description, TotalErr);
    end;

    local procedure VerifyTextStartsWith(BeginingText: Text; ActualText: Text; ErrorMsg: Text)
    begin
        Assert.AreEqual(1, StrPos(ActualText, BeginingText), ErrorMsg);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure QuoteAnalysisRequestPageHandler(var QuoteAnalysis: TestRequestPage "Quote Analysis")
    begin
        // Set new page per salesperson to true.
        QuoteAnalysis.PagePerSalesperson.SetValue(true);
        QuoteAnalysis.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure QuoteAnalysisConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

