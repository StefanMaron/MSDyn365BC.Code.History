codeunit 135300 "O365 Purch Item Charge Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Corrective Credit Memo] [Purchase] [Item Charges]
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IncorrectCreditMemoQtyAssignmentErr: Label 'Item charge assignment incorrect on corrective credit memo.';
        IncorrectAmountOfLinesErr: Label 'The amount of lines must be greater than 0.';
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";

    local procedure Initialize()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"O365 Purch Item Charge Tests");

        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableItemChargeSetup();

        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup."Receipt on Invoice" := true;
        PurchasesPayablesSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetupItemChargeTest()
    var
        ItemCharge: Record "Item Charge";
        ItemCharges: TestPage "Item Charges";
        ItemChargeNo: Code[20];
    begin
        // [FEATURE] [UI]
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] Creating a new item charge using the GUI
        ItemChargeNo := LibraryUtility.GenerateRandomCode(ItemCharge.FieldNo("No."), DATABASE::"Item Charge");

        ItemCharges.OpenNew;
        ItemCharges."No.".SetValue(ItemChargeNo);
        ItemCharges.OK.Invoke;

        // [THEN] The record is created
        ItemCharge.SetRange("No.", ItemChargeNo);
        ItemCharge.FindFirst;

        Assert.RecordIsNotEmpty(ItemCharge);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPageHandler,SuggestItemChargeAssgntByAmountHandler')]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoWithItemChargeTest()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        RandAmountOfItemLines: Integer;
    begin
        // [SCENARIO] Corrective Credit Memo reverses one invoice line with item charge.
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        RandAmountOfItemLines := LibraryRandom.RandIntInRange(1, 20);
        // [GIVEN] Create a purchase invoice with 1 assigned item charge and random amount of item lines

        CreatePurchHeader(PurchaseHeader, false);
        AddItemLinesToPurchHeader(PurchaseHeader, RandAmountOfItemLines);
        AddItemChargeLinesToPurchHeader(PurchaseHeader, 1);
        // [WHEN] Post and create a corrective credit memo
        PurchaseCreditMemo.Trap;
        PostAndVerifyCorrectiveCreditMemo(PurchaseHeader);
        // [THEN] Verify that the 'qty to assign' is not empty and is equal to the 'quantity' of the item charge
        VerifyCorrectiveCreditMemoWithAssignedItemCharge(PurchaseCreditMemo);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPageHandler,SuggestItemChargeAssgntByAmountHandler')]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoWithItemChargesTest()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        RandAmountOfItemLines: Integer;
        RandAmountOfItemChargeLines: Integer;
    begin
        // [SCENARIO] Corrective Credit Memo reverses multiple invoice lines with item charge.
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Create a purchase invoice with a random amount of assigned item charge and item lines.
        RandAmountOfItemLines := LibraryRandom.RandIntInRange(1, 20);
        RandAmountOfItemChargeLines := LibraryRandom.RandIntInRange(1, 20);

        CreatePurchHeader(PurchaseHeader, false);
        AddItemLinesToPurchHeader(PurchaseHeader, RandAmountOfItemLines);
        AddItemChargeLinesToPurchHeader(PurchaseHeader, RandAmountOfItemChargeLines);
        // [WHEN] Post and create a corrective credit memo.
        PurchaseCreditMemo.Trap;
        PostAndVerifyCorrectiveCreditMemo(PurchaseHeader);
        // [THEN] Verify that the 'qty to assign' is not empty and is equal to the 'quantity' of the item charge
        VerifyCorrectiveCreditMemoWithAssignedItemCharge(PurchaseCreditMemo);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPageHandler,SuggestItemChargeAssgntByAmountHandler')]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoFromLargeInvoiceWithItemChargeTest()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO] Corrective Credit Memo reverses multiple item lines and 1 invoice line with item charge.
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Create a purchase invoice with 50 item lines and 1 item charge
        CreatePurchHeader(PurchaseHeader, false);
        AddItemLinesToPurchHeader(PurchaseHeader, 50);
        AddItemChargeLinesToPurchHeader(PurchaseHeader, 1);
        // [WHEN] Post document, and create corrective credit memo
        PurchaseCreditMemo.Trap;
        PostAndVerifyCorrectiveCreditMemo(PurchaseHeader);
        // [THEN] Verify that the 'qty to assign' is not empty and is equal to the 'quantity' of the item charge
        VerifyCorrectiveCreditMemoWithAssignedItemCharge(PurchaseCreditMemo);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPageHandler')]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoWithItemChargeAndCurrencyTest()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [FCY]
        // [SCENARIO] Corrective Credit Memo reverses 1 item line and 1 invoice line with item charge in foreign currency.
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Create a purchase invoice, using a random currency, with 1 item and item charge
        CreatePurchHeader(PurchaseHeader, true);
        AddItemLinesToPurchHeader(PurchaseHeader, 1);
        AddItemChargeLinesToPurchHeader(PurchaseHeader, 1);
        // [WHEN] Post document, and create corrective credit memo
        PurchaseCreditMemo.Trap;
        PostAndVerifyCorrectiveCreditMemo(PurchaseHeader);
        // [THEN] Verify that the 'qty to assign' is not empty and is equal to the 'quantity' of the item charge
        VerifyCorrectiveCreditMemoWithAssignedItemCharge(PurchaseCreditMemo);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPageHandler')]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoWithoutItemChargeTest()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO] Corrective Credit Memo reverses 1 item line and 1 invoice line with item charge (while receipts disabled).
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Disable "receipt on invoice" in the Purchases & Payables Setup
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup."Receipt on Invoice" := false;
        PurchasesPayablesSetup.Modify(true);

        // [GIVEN] Create a purchase invoice with an item and an item charge
        CreatePurchHeader(PurchaseHeader, false);
        AddItemLinesToPurchHeader(PurchaseHeader, 1);
        AddItemChargeLinesToPurchHeader(PurchaseHeader, 1);
        // [WHEN] Post document, and create corrective credit memo
        PurchaseCreditMemo.Trap;
        PostAndVerifyCorrectiveCreditMemo(PurchaseHeader);
        // [THEN] Verify that the 'qty to assign' is 0
        VerifyCorrectiveCreditMemoWithoutAssignedItemCharge(PurchaseCreditMemo);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure PostAndVerifyCorrectiveCreditMemo(PurchaseHeader: Record "Purchase Header")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PostedDocNumber: Code[20];
    begin
        PostedDocNumber := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        PurchInvHeader.Get(PostedDocNumber);
        PostedPurchaseInvoice.OpenEdit;
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);
        PostedPurchaseInvoice.CreateCreditMemo.Invoke; // Opens CorrectiveCreditMemoPageHandler
    end;

    local procedure CreatePurchHeader(var PurchaseHeader: Record "Purchase Header"; UseRandomCurrency: Boolean)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo);

        if UseRandomCurrency then
            CreateCurrencyWithCurrencyFactor(PurchaseHeader);
    end;

    local procedure AddItemLinesToPurchHeader(var PurchaseHeader: Record "Purchase Header"; AmountOfItemLines: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        Assert.IsTrue(AmountOfItemLines > 0, IncorrectAmountOfLinesErr);

        for i := 1 to AmountOfItemLines do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', 1);
            PurchaseLine.Validate(Quantity, GenerateRandDecimalBetweenOneAndFive);
            PurchaseLine.Validate("Direct Unit Cost", GenerateRandDecimalBetweenOneAndFive);
            PurchaseLine.Modify(true);
        end;
    end;

    local procedure AddItemChargeLinesToPurchHeader(var PurchaseHeader: Record "Purchase Header"; AmountOfItemChargeLines: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        Assert.IsTrue(AmountOfItemChargeLines > 0, IncorrectAmountOfLinesErr);

        for i := 1 to AmountOfItemChargeLines do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", '', 1);
            PurchaseLine.Validate(Quantity, GenerateRandDecimalBetweenOneAndFive);
            PurchaseLine."Line Amount" := GenerateRandDecimalBetweenOneAndFive;
            PurchaseLine.Validate("Direct Unit Cost", GenerateRandDecimalBetweenOneAndFive);
            PurchaseLine.Modify(true);

            PurchaseLine.ShowItemChargeAssgnt;
        end;
    end;

    local procedure GenerateRandDecimalBetweenOneAndFive(): Decimal
    begin
        exit(LibraryRandom.RandDecInRange(1, 5, LibraryRandom.RandIntInRange(1, 5)));
    end;

    local procedure CreateCurrencyWithCurrencyFactor(var PurchaseHeader: Record "Purchase Header")
    var
        Currency: Record Currency;
        LibraryERM: Codeunit "Library - ERM";
    begin
        Currency.SetRange(Code, LibraryERM.CreateCurrencyWithExchangeRate(DMY2Date(1, 1, 2000), 1, 1));
        Currency.FindFirst;
        Currency.Validate("Currency Factor", LibraryRandom.RandDecInRange(1, 2, 5));
        Currency.Modify(true);

        PurchaseHeader."Currency Code" := Currency.Code;
        PurchaseHeader."Currency Factor" := Currency."Currency Factor";
        PurchaseHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrectiveCreditMemoWithAssignedItemCharge(var PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::"Credit Memo", Format(PurchaseCreditMemo."No."));
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
        PurchaseLine.FindSet;
        repeat
            PurchaseLine.CalcFields("Qty. to Assign");
            Assert.AreEqual(PurchaseLine.Quantity, PurchaseLine."Qty. to Assign", IncorrectCreditMemoQtyAssignmentErr)
        until PurchaseLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrectiveCreditMemoWithoutAssignedItemCharge(var PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::"Credit Memo", Format(PurchaseCreditMemo."No."));
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
        PurchaseLine.FindSet;
        repeat
            PurchaseLine.CalcFields("Qty. to Assign");
            Assert.IsTrue(PurchaseLine."Qty. to Assign" = 0, IncorrectCreditMemoQtyAssignmentErr);
        until PurchaseLine.Next = 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.SuggestItemChargeAssignment.Invoke;
        ItemChargeAssignmentPurch.OK.Invoke;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure SuggestItemChargeAssgntByAmountHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        // Pick assignment by amount
        Choice := 2;
    end;
}

