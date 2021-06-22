codeunit 135301 "O365 Sales Item Charge Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Corrective Credit Memo] [Sales] [Item Charge]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IncorrectCreditMemoQtyAssignmentErr: Label 'ENU=Item charge assignment incorrect on corrective credit memo.';
        IncorrectAmountOfLinesErr: Label 'ENU=The amount of lines must be greater than 0.';
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        isInitialized: Boolean;

    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"O365 Sales Item Charge Tests");

        LibraryVariableStorage.Clear;
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"O365 Sales Item Charge Tests");

        LibraryApplicationArea.EnableItemChargeSetup;

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Shipment on Invoice" := true;
        SalesReceivablesSetup.Modify(true);

        Commit();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"O365 Sales Item Charge Tests");
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPageHandler,SuggestItemChargeAssgntByAmountHandler')]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoWithItemChargeTest()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        RandAmountOfItemLines: Integer;
    begin
        // [SCENARIO] Corrective Credit Memo reverses one invoice line with item charge.
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Create a sales invoice with 1 assigned item charge and random amount of item lines
        RandAmountOfItemLines := LibraryRandom.RandIntInRange(1, 20);

        CreateSalesHeader(SalesHeader, false);
        AddItemLinesToSalesHeader(SalesHeader, RandAmountOfItemLines);
        AddItemChargeLinesToSalesHeader(SalesHeader, 1);
        // [WHEN] Post and create a corrective credit memo
        SalesCreditMemo.Trap;
        PostAndVerifyCorrectiveCreditMemo(SalesHeader);
        // [THEN] Verify that the 'qty to assign' is not empty and is equal to the 'quantity' of the item charge.
        VerifyCorrectiveCreditMemoWithItemCharge(SalesCreditMemo);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPageHandler,SuggestItemChargeAssgntByAmountHandler')]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoWithItemChargesTest()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        RandAmountOfItemLines: Integer;
        RandAmountOfItemChargeLines: Integer;
    begin
        // [SCENARIO] Corrective Credit Memo reverses multiple invoice lines with item charge.
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Create a sales invoice with a random amount of assigned item charge and item lines.
        RandAmountOfItemLines := LibraryRandom.RandIntInRange(1, 20);
        RandAmountOfItemChargeLines := LibraryRandom.RandIntInRange(1, 20);

        CreateSalesHeader(SalesHeader, false);
        AddItemLinesToSalesHeader(SalesHeader, RandAmountOfItemLines);
        AddItemChargeLinesToSalesHeader(SalesHeader, RandAmountOfItemChargeLines);
        // [WHEN] Post and create a corrective credit memo.
        SalesCreditMemo.Trap;
        PostAndVerifyCorrectiveCreditMemo(SalesHeader);
        // [THEN] Verify that the 'qty to assign' is not empty and is equal to the 'quantity' of the item charge.
        VerifyCorrectiveCreditMemoWithItemCharge(SalesCreditMemo);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPageHandler,SuggestItemChargeAssgntByAmountHandler')]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoFromLargeInvoiceWithItemChargeTest()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO] Corrective Credit Memo reverses multiple item lines and 1 invoice line with item charge.
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Create a sales invoice with 50 item lines and 1 item charge
        CreateSalesHeader(SalesHeader, false);
        AddItemLinesToSalesHeader(SalesHeader, 50);
        AddItemChargeLinesToSalesHeader(SalesHeader, 1);
        // [WHEN] Post document, and create corrective credit memo
        SalesCreditMemo.Trap;
        PostAndVerifyCorrectiveCreditMemo(SalesHeader);
        // [THEN] Verify that the 'qty to assign' is not empty and is equal to the 'quantity' of the item charge.
        VerifyCorrectiveCreditMemoWithItemCharge(SalesCreditMemo);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPageHandler')]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoWithItemChargeAndCurrencyTest()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [FCY]
        // [SCENARIO] Corrective Credit Memo reverses 1 item line and 1 invoice line with item charge in foreign currency.
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Create a sales invoice, using a random currency, with 1 item and item charge
        CreateSalesHeader(SalesHeader, true);
        AddItemLinesToSalesHeader(SalesHeader, 1);
        AddItemChargeLinesToSalesHeader(SalesHeader, 1);
        // [WHEN] Post document, and create corrective credit memo
        SalesCreditMemo.Trap;
        PostAndVerifyCorrectiveCreditMemo(SalesHeader);
        // [THEN] Verify that the 'qty to assign' is not empty and is equal to the 'quantity' of the item charge.
        VerifyCorrectiveCreditMemoWithItemCharge(SalesCreditMemo);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPageHandler')]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoWithoutItemChargeTest()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO] Corrective Credit Memo reverses 1 item line and 1 invoice line with item charge (while shipments disabled).
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Disable "shipment on invoice" in the Sales & Receivables Setup
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Shipment on Invoice" := false;
        SalesReceivablesSetup.Modify(true);

        // [GIVEN] Create a sales invoice with an item and an item charge
        CreateSalesHeader(SalesHeader, false);
        AddItemLinesToSalesHeader(SalesHeader, 1);
        AddItemChargeLinesToSalesHeader(SalesHeader, 1);
        // [WHEN] Post document, and create corrective credit memo
        SalesCreditMemo.Trap;
        PostAndVerifyCorrectiveCreditMemo(SalesHeader);
        // [THEN] Verify that the 'qty to assign' is 0
        VerifyCorrectiveCreditMemoWithoutItemCharge(SalesCreditMemo);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure PostAndVerifyCorrectiveCreditMemo(SalesHeader: Record "Sales Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedDocNumber: Code[20];
    begin
        PostedDocNumber := LibrarySales.PostSalesDocument(SalesHeader, false, true);
        SalesInvoiceHeader.Get(PostedDocNumber);
        PostedSalesInvoice.OpenEdit;
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
        PostedSalesInvoice.CreateCreditMemo.Invoke; // Opens CorrectiveCreditMemoPageHandler
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; UseRandomCurrency: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo);

        if UseRandomCurrency then
            CreateCurrencyWithCurrencyFactor(SalesHeader);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SalesLineType: Option)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLineType, '', 1);
        SalesLine.Validate(Quantity, GenerateRandDecimalBetweenOneAndFive);
        SalesLine."Line Amount" := GenerateRandDecimalBetweenOneAndFive;
        SalesLine."Unit Price" := GenerateRandDecimalBetweenOneAndFive;
        SalesLine.Modify(true);
    end;

    local procedure AddItemLinesToSalesHeader(var SalesHeader: Record "Sales Header"; AmountOfItemLines: Integer)
    var
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        Assert.IsTrue(AmountOfItemLines > 0, IncorrectAmountOfLinesErr);

        for i := 1 to AmountOfItemLines do
            CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item);
    end;

    local procedure AddItemChargeLinesToSalesHeader(var SalesHeader: Record "Sales Header"; AmountOfItemChargeLines: Integer)
    var
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        Assert.IsTrue(AmountOfItemChargeLines > 0, IncorrectAmountOfLinesErr);

        for i := 1 to AmountOfItemChargeLines do begin
            CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type::"Charge (Item)");
            SalesLine.ShowItemChargeAssgnt;
        end;
    end;

    local procedure GenerateRandDecimalBetweenOneAndFive(): Decimal
    begin
        exit(LibraryRandom.RandDecInRange(1, 5, LibraryRandom.RandIntInRange(1, 5)));
    end;

    local procedure CreateCurrencyWithCurrencyFactor(var SalesHeader: Record "Sales Header")
    var
        Currency: Record Currency;
        LibraryERM: Codeunit "Library - ERM";
    begin
        Currency.SetRange(Code, LibraryERM.CreateCurrencyWithExchangeRate(DMY2Date(1, 1, 2000), 1, 1));
        Currency.FindFirst;
        Currency.Validate("Currency Factor", LibraryRandom.RandDecInRange(1, 2, 5));
        Currency.Modify(true);

        SalesHeader."Currency Code" := Currency.Code;
        SalesHeader."Currency Factor" := Currency."Currency Factor";
        SalesHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrectiveCreditMemoWithItemCharge(var SalesCreditMemo: TestPage "Sales Credit Memo")
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", Format(SalesCreditMemo."No."));
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        SalesLine.FindSet;
        repeat
            SalesLine.CalcFields("Qty. to Assign");
            Assert.AreEqual(SalesLine.Quantity, SalesLine."Qty. to Assign", IncorrectCreditMemoQtyAssignmentErr);
        until SalesLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrectiveCreditMemoWithoutItemCharge(var SalesCreditMemo: TestPage "Sales Credit Memo")
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", Format(SalesCreditMemo."No."));
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        SalesLine.FindSet;
        repeat
            SalesLine.CalcFields("Qty. to Assign");
            Assert.IsTrue(SalesLine."Qty. to Assign" = 0, IncorrectCreditMemoQtyAssignmentErr);
        until SalesLine.Next = 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    begin
        ItemChargeAssignmentSales.SuggestItemChargeAssignment.Invoke;
        ItemChargeAssignmentSales.OK.Invoke;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure SuggestItemChargeAssgntByAmountHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        // Pick assignment by amount
        Choice := 2;
    end;
}

