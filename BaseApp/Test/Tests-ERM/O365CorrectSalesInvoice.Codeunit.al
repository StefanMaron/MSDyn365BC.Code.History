codeunit 138015 "O365 Correct Sales Invoice"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cancelled Document] [Invoice] [Sales]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJob: Codeunit "Library - Job";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        IsInitialized: Boolean;
        EntriesSuccessfullyUnappliedMsg: Label 'The entries were successfully unapplied.';
        ShippedQtyReturnedCorrectErr: Label 'You cannot correct this posted sales invoice because item %1 %2 has already been fully or partially returned.', Comment = '%1 = Item no. %2 = Item description.';
        ShippedQtyReturnedCancelErr: Label 'You cannot cancel this posted sales invoice because item %1 %2 has already been fully or partially returned.', Comment = '%1 = Item no. %2 = Item description.';
        AmountSalesInvErr: Label 'Amount must have a value in Sales Invoice Header';

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure TestPageActionCorrectInvoice()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize;

        if GLEntry.FindLast then;

        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvoiceHeader);
        CheckSomethingIsPosted(Item, Cust);

        // EXERCISE
        PostedSalesInvoice.OpenEdit;
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
        PostedSalesInvoice.CorrectInvoice.Invoke;

        // VERIFY: Sales Header must match before and after Correct Invoice
        CheckEverythingIsReverted(Item, Cust, GLEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesCrMemoPageHandler')]
    [Scope('OnPrem')]
    procedure TestPageActionCancelInvoice()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize;

        if GLEntry.FindLast then;

        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvoiceHeader);
        CheckSomethingIsPosted(Item, Cust);

        // EXERCISE
        PostedSalesInvoice.OpenEdit;
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
        PostedSalesInvoice.CancelInvoice.Invoke;

        PostedSalesInvoice.OpenEdit;
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
        PostedSalesInvoice.Cancelled.AssertEquals(true);

        // VERIFY: Sales Header must match before and after Correct Invoice
        CheckEverythingIsReverted(Item, Cust, GLEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure TestListPageActionCorrectInvoice()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
    begin
        Initialize;

        if GLEntry.FindLast then;

        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvoiceHeader);
        CheckSomethingIsPosted(Item, Cust);

        // EXERCISE
        PostedSalesInvoices.OpenEdit;
        PostedSalesInvoices.GotoRecord(SalesInvoiceHeader);
        PostedSalesInvoices.CorrectInvoice.Invoke;

        // VERIFY: Sales Header must match before and after Correct Invoice
        CheckEverythingIsReverted(Item, Cust, GLEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesCrMemoPageHandler')]
    [Scope('OnPrem')]
    procedure TestListPageActionCancelInvoice()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
    begin
        Initialize;

        if GLEntry.FindLast then;

        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvoiceHeader);
        CheckSomethingIsPosted(Item, Cust);

        // EXERCISE
        PostedSalesInvoices.OpenEdit;
        PostedSalesInvoices.GotoRecord(SalesInvoiceHeader);
        PostedSalesInvoices.CancelInvoice.Invoke;

        PostedSalesInvoices.Cancelled.AssertEquals(true);

        // VERIFY: Sales Header must match before and after Correct Invoice
        CheckEverythingIsReverted(Item, Cust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceCostReversing()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        SalesHeaderCorrection: Record "Sales Header";
        LastItemLedgEntry: Record "Item Ledger Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize;

        if GLEntry.FindLast then;

        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvoiceHeader);

        LastItemLedgEntry.FindLast;
        Assert.AreEqual(-1, LastItemLedgEntry."Shipped Qty. Not Returned", '');

        // EXERCISE
        TurnOffExactCostReversing;
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);

        // VERIFY: The correction must use Exact Cost reversing
        LastItemLedgEntry.Find;
        Assert.AreEqual(
          0, LastItemLedgEntry."Shipped Qty. Not Returned",
          'The quantity on the shipment item ledger should appear as returned');

        CheckEverythingIsReverted(Item, Cust, GLEntry);

        // VERIFY: Check exact reversing work even when new costs are introduced
        CreateAndPostPurchInvForItem(Item, 1, 1);

        CheckEverythingIsReverted(Item, Cust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCancelInvoice()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize;

        if GLEntry.FindLast then;

        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvoiceHeader);
        CheckSomethingIsPosted(Item, Cust);

        // EXERCISE
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // VERIFY: Sales Header must match before and after Correct Invoice
        CheckEverythingIsReverted(Item, Cust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCancelInvoiceJobWithResource()
    var
        Cust: Record Customer;
        Resource: Record Resource;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        ResLedgerEntry: Record "Res. Ledger Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        Quantity: Decimal;
    begin
        Initialize;

        if GLEntry.FindLast then;
        Quantity := 2;
        CreateAndPostSalesInvForNewJobResAndCust(Resource, Cust, 1, Quantity, SalesInvoiceHeader);

        ResLedgerEntry.FindLast;
        Assert.AreEqual(ResLedgerEntry."Document No.", SalesInvoiceHeader."No.",
          'Document No. on Res. Ledger Entry and Sales Inv Header are different');
        Assert.AreEqual(-ResLedgerEntry.Quantity, Quantity,
          'Quantity on Res. Ledger Entry and Sales Line do not match');

        // EXERCISE
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // VERIFY: Sales Header must match before and after Correct Invoice
        CheckGLEntryIsReverted(Cust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoice()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        SalesHeaderCorrection: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize;

        if GLEntry.FindLast then;

        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvoiceHeader);
        CheckSomethingIsPosted(Item, Cust);

        // EXERCISE
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);

        // VERIFY: Sales Header must match before and after Correct Invoice
        CheckEverythingIsReverted(Item, Cust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceJobWithResource()
    var
        Cust: Record Customer;
        Resource: Record Resource;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        SalesHeaderCorrection: Record "Sales Header";
        ResLedgerEntry: Record "Res. Ledger Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        Quantity: Decimal;
    begin
        Initialize;

        if GLEntry.FindLast then;
        Quantity := 2;
        CreateAndPostSalesInvForNewJobResAndCust(Resource, Cust, 1, Quantity, SalesInvoiceHeader);

        ResLedgerEntry.FindLast;
        Assert.AreEqual(ResLedgerEntry."Document No.", SalesInvoiceHeader."No.",
          'Document No. on Res. Ledger Entry and Sales Inv Header are different');
        Assert.AreEqual(-ResLedgerEntry.Quantity, Quantity,
          'Quantity on Res. Ledger Entry and Sales Line do not match');

        // EXERCISE
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);

        // VERIFY: Sales Header must match before and after Correct Invoice
        CheckGLEntryIsReverted(Cust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateNewCreditMemoFromInvoice()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        SalesHeaderCorrection: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        DescText: Text;
        ExpectedAmount: Decimal;
        StrPosition: Integer;
    begin
        // [FEATURE] [Corrective Credit Memo]
        Initialize;

        if GLEntry.FindLast then;

        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvoiceHeader);
        CheckSomethingIsPosted(Item, Cust);

        // EXERCISE
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesHeaderCorrection);

        // VERIFY: New Sales Credit Memo must match Posted Sales Invoice

        // Created customer match Sales Header
        Assert.AreEqual(Cust."No.", SalesHeaderCorrection."Sell-to Customer No.", 'Wrong Customer for Credit Memo');

        // 1. Sales Line expect to be a Document description
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesHeaderCorrection."No.");

        SalesLine.FindFirst;
        ExpectedAmount := 0;
        StrPosition := StrPos(SalesLine.Description, SalesInvoiceHeader."No.");

        Assert.AreNotEqual(0, StrPosition, 'Wrong invoice number in Description line');
        Assert.AreEqual(ExpectedAmount, SalesLine.Amount, 'Wrong amount for Credit Memo Sales Line');

        // Last Sales Line expect to be the Item created.
        SalesLine.FindLast;
        ExpectedAmount := 1;
        DescText := Item.Description;
        Assert.AreEqual(DescText, SalesLine.Description, 'Wrong description text for Credit Memo Sales Line');
        Assert.AreEqual(ExpectedAmount, SalesLine.Amount, 'Wrong amount for Credit Memo Sales Line');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPageActionCreateNewCreditMemoFromInvoice()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        SalesHeaderCorrection: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        DescText: Text;
        ExpectedAmount: Decimal;
        StrPosition: Integer;
    begin
        // [FEATURE] [Corrective Credit Memo]
        Initialize;

        if GLEntry.FindLast then;

        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvoiceHeader);
        CheckSomethingIsPosted(Item, Cust);

        SalesCreditMemo.Trap;

        // EXERCISE
        PostedSalesInvoice.OpenView;
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
        PostedSalesInvoice.CreateCreditMemo.Invoke;

        SalesCreditMemo.Close;

        // VERIFY: New Sales Credit Memo must match Posted Sales Invoice
        SalesHeaderCorrection.SetRange("Applies-to Doc. No.", SalesInvoiceHeader."No.");
        SalesHeaderCorrection.SetRange("Applies-to Doc. Type", SalesHeaderCorrection."Applies-to Doc. Type"::Invoice);
        SalesHeaderCorrection.FindFirst;

        // Created customer match Sales Header
        Assert.AreEqual(Cust."No.", SalesHeaderCorrection."Sell-to Customer No.", 'Wrong Customer for Credit Memo');

        // 1. Sales Line expect to be a Document description
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesHeaderCorrection."No.");

        SalesLine.FindFirst;
        ExpectedAmount := 0;
        StrPosition := StrPos(SalesLine.Description, SalesInvoiceHeader."No.");

        Assert.AreNotEqual(0, StrPosition, 'Wrong invoice number in Description line');
        Assert.AreEqual(ExpectedAmount, SalesLine.Amount, 'Wrong amount for Credit Memo Sales Line');

        // Last Sales Line expect to be the Item created.
        SalesLine.FindLast;
        ExpectedAmount := 1;
        DescText := Item.Description;
        Assert.AreEqual(DescText, SalesLine.Description, 'Wrong description text for Credit Memo Sales Line');
        Assert.AreEqual(ExpectedAmount, SalesLine.Amount, 'Wrong amount for Credit Memo Sales Line');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceTwice()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeaderCorrection: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        NoOfCancellationsOnSameInvoice: Integer;
    begin
        Initialize;

        if GLEntry.FindLast then;

        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvoiceHeader);
        CheckSomethingIsPosted(Item, Cust);

        for NoOfCancellationsOnSameInvoice := 1 to 2 do
            if NoOfCancellationsOnSameInvoice = 1 then begin
                // EXERCISE
                CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);
                CheckEverythingIsReverted(Item, Cust, GLEntry);
            end else begin
                if GLEntry.FindLast then;
                SalesInvoiceHeader.Find;

                // VERIFY : It should not be possible to cancel a posted invoice twice
                asserterror CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);
                CheckNothingIsCreated(Cust."No.", GLEntry);

                // VERIFY : It should not be possible to cancel a posted invoice twice
                asserterror CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);
                CheckNothingIsCreated(Cust."No.", GLEntry);
            end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectRecreatedInvoice()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeaderCorrection: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        NoOfRecreatedInvoices: Integer;
    begin
        Initialize;

        if GLEntry.FindLast then;

        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvoiceHeader);

        for NoOfRecreatedInvoices := 1 to 2 do begin
            // EXERCISE
            CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);
            CheckEverythingIsReverted(Item, Cust, GLEntry);

            // VERIFY: That invoices created from a correction and also be posted and cancelled
            SalesInvoiceHeader.Get(LibrarySmallBusiness.PostSalesInvoice(SalesHeaderCorrection));
            CheckSomethingIsPosted(Item, Cust);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangedCust()
    var
        SellToCust: Record Customer;
        BillToCust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        SalesHeaderCorrection: Record "Sales Header";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize;

        if GLEntry.FindLast then;

        CreateItemsWithPrice(Item, 1);

        CreateSellToWithDifferentBillToCust(SellToCust, BillToCust);

        SellItem(SellToCust, Item, 1, SalesInvoiceHeader);
        CheckSomethingIsPosted(Item, BillToCust);

        BillToCust.Find;
        CurrencyExchangeRate.FindFirst;
        BillToCust.Validate("Currency Code", CurrencyExchangeRate."Currency Code");
        BillToCust.Modify(true);
        Commit();

        // EXERCISE
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);

        // VERIFY: Sales Header must match before and after Correct Invoice
        CheckEverythingIsReverted(Item, BillToCust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSellToCustIsBlocked()
    var
        SellToCust: Record Customer;
        BillToCust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeaderTmp: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize;

        CreateItemsWithPrice(Item, 0);
        CreateSellToWithDifferentBillToCust(SellToCust, BillToCust);
        SellItem(SellToCust, Item, 1, SalesInvoiceHeader);

        SellToCust.Get(SellToCust."No.");
        SellToCust.Validate(Blocked, SellToCust.Blocked::All);
        SellToCust.Modify(true);
        Commit();

        if GLEntry.FindLast then;

        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderTmp);

        // VERIFY: It should not be possible to cancel a Posted Invoice when the Sell-To Customer is marked as blocked
        CheckNothingIsCreated(BillToCust."No.", GLEntry);

        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // VERIFY: It should not be possible to cancel a Posted Invoice when the Sell-To Customer is marked as blocked
        CheckNothingIsCreated(BillToCust."No.", GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBillToCustIsBlocked()
    var
        SellToCust: Record Customer;
        BillToCust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeaderTmp: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize;

        CreateItemsWithPrice(Item, 0);
        CreateSellToWithDifferentBillToCust(SellToCust, BillToCust);
        SellItem(SellToCust, Item, 1, SalesInvoiceHeader);

        BillToCust.Get(BillToCust."No.");
        BillToCust.Validate(Blocked, BillToCust.Blocked::All);
        BillToCust.Modify(true);
        Commit();

        if GLEntry.FindLast then;
        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderTmp);

        // VERIFY: It should not be possible to cancel a Posted Invoice when the Bill-To Customer is marked as blocked
        CheckNothingIsCreated(BillToCust."No.", GLEntry);

        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // VERIFY: It should not be possible to cancel a Posted Invoice when the Bill-To Customer is marked as blocked
        CheckNothingIsCreated(BillToCust."No.", GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSellToCustIsPrivacyBlocked()
    var
        SellToCust: Record Customer;
        BillToCust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeaderTmp: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize;

        CreateItemsWithPrice(Item, 0);
        CreateSellToWithDifferentBillToCust(SellToCust, BillToCust);
        SellItem(SellToCust, Item, 1, SalesInvoiceHeader);

        SellToCust.Get(SellToCust."No.");
        SellToCust.Validate("Privacy Blocked", true);
        SellToCust.Modify(true);
        Commit();

        if GLEntry.FindLast then;

        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderTmp);

        // VERIFY: It should not be possible to cancel a Posted Invoice when the Sell-To Customer is marked as blocked
        CheckNothingIsCreated(BillToCust."No.", GLEntry);

        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // VERIFY: It should not be possible to cancel a Posted Invoice when the Sell-To Customer is marked as blocked
        CheckNothingIsCreated(BillToCust."No.", GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBillToCustIsPrivacyBlocked()
    var
        SellToCust: Record Customer;
        BillToCust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeaderTmp: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize;

        CreateItemsWithPrice(Item, 0);
        CreateSellToWithDifferentBillToCust(SellToCust, BillToCust);
        SellItem(SellToCust, Item, 1, SalesInvoiceHeader);

        BillToCust.Get(BillToCust."No.");
        BillToCust.Validate("Privacy Blocked", true);
        BillToCust.Modify(true);
        Commit();

        if GLEntry.FindLast then;
        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderTmp);

        // VERIFY: It should not be possible to cancel a Posted Invoice when the Bill-To Customer is marked as blocked
        CheckNothingIsCreated(BillToCust."No.", GLEntry);

        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // VERIFY: It should not be possible to cancel a Posted Invoice when the Bill-To Customer is marked as blocked
        CheckNothingIsCreated(BillToCust."No.", GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemBlocked()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        SalesHeaderCorrection: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize;

        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvoiceHeader);

        Item.Find;
        Item.Validate(Blocked, true);
        Item.Modify(true);
        Commit();

        if GLEntry.FindLast then;

        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);

        // VERIFY
        CheckNothingIsCreated(Cust."No.", GLEntry);

        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // VERIFY
        CheckNothingIsCreated(Cust."No.", GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemGLAccBlocked()
    var
        SellToCust: Record Customer;
        BillToCust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLAcc: Record "G/L Account";
        InvtPostingSetup: Record "Inventory Posting Setup";
    begin
        Initialize;

        CreateItemsWithPrice(Item, 1);

        CreateSellToWithDifferentBillToCust(SellToCust, BillToCust);

        SellItem(SellToCust, Item, 1, SalesInvoiceHeader);

        InvtPostingSetup.Get(SellToCust."Location Code", Item."Inventory Posting Group");
        GLAcc.Get(InvtPostingSetup."Inventory Account");
        BlockGLAcc(GLAcc);

        CorrectAndCancelWithFailureAndVerificaltion(SalesInvoiceHeader);

        UnblockGLAcc(GLAcc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustGLAccBlocked()
    var
        SellToCust: Record Customer;
        BillToCust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLAcc: Record "G/L Account";
        CustPostingGroup: Record "Customer Posting Group";
    begin
        Initialize;

        CreateItemsWithPrice(Item, 0);

        CreateSellToWithDifferentBillToCust(SellToCust, BillToCust);

        SellItem(SellToCust, Item, 1, SalesInvoiceHeader);

        CustPostingGroup.Get(BillToCust."Customer Posting Group");
        GLAcc.Get(CustPostingGroup."Receivables Account");
        BlockGLAcc(GLAcc);

        CorrectAndCancelWithFailureAndVerificaltion(SalesInvoiceHeader);

        UnblockGLAcc(GLAcc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATGLAccBlocked()
    var
        SellToCust: Record Customer;
        BillToCust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLAcc: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        Initialize;

        CreateItemsWithPrice(Item, 1);

        CreateSellToWithDifferentBillToCust(SellToCust, BillToCust);

        VATPostingSetup.Get(BillToCust."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        GLAcc.Get(VATPostingSetup."Sales VAT Account");

        SellItem(SellToCust, Item, 1, SalesInvoiceHeader);

        // VERIFY: It should not be possible to correct a posted invoice when the VAT account is blocked
        VerifyCorrectionFailsOnBlockedGLAcc(GLAcc, BillToCust, SalesInvoiceHeader);
        VerifyCorrectionFailsOnMandatoryDimGLAcc(GLAcc, BillToCust, SalesInvoiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesGLAccBlocked()
    var
        SellToCust: Record Customer;
        BillToCust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLAcc: Record "G/L Account";
        GenPostingSetup: Record "General Posting Setup";
        TempGLAcc: Record "G/L Account" temporary;
    begin
        Initialize;

        CreateItemsWithPrice(Item, 1);
        CreateSellToWithDifferentBillToCust(SellToCust, BillToCust);
        SellItem(SellToCust, Item, 1, SalesInvoiceHeader);

        GenPostingSetup.Get(BillToCust."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        GLAcc.SetFilter("No.", '%1|%2|%3|%4',
          GenPostingSetup."Sales Credit Memo Account",
          GenPostingSetup."COGS Account",
          GenPostingSetup."Sales Line Disc. Account",
          GenPostingSetup."Sales Account");
        CopyGLAccToGLAcc(GLAcc, TempGLAcc);

        // VERIFY: It should not be possible to correct a posted invoice when the sales income statements accounts are blocked
        // or Dimensions are mandatory
        TempGLAcc.FindSet;
        repeat
            VerifyCorrectionFailsOnBlockedGLAcc(TempGLAcc, BillToCust, SalesInvoiceHeader);
            VerifyCorrectionFailsOnMandatoryDimGLAcc(TempGLAcc, BillToCust, SalesInvoiceHeader);
        until TempGLAcc.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCommentLines()
    var
        SalesHeader: Record "Sales Header";
        Cust: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeaderTmp: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        StandardText: Record "Standard Text";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize;

        if GLEntry.FindLast then;

        CreateSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesHeader, SalesLine);

        StandardText.FindFirst;

        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, 1);
        SalesLine.Validate(Type, SalesLine.Type::" ");
        SalesLine.Validate("No.", StandardText.Code);
        SalesLine.Modify(true);

        SalesInvoiceHeader.Get(LibrarySmallBusiness.PostSalesInvoice(SalesHeader));

        // EXERCISE
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderTmp);

        // VERIFY: Sales Header must match before and after Correct Invoice
        CheckEverythingIsReverted(Item, Cust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceUsingGLAccount()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        SalesHeaderTmp: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize;

        CreateSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesHeader, SalesLine);

        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, 1);
        SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
        SalesLine.Validate("No.", LibraryERM.CreateGLAccountWithSalesSetup);
        SalesLine.Validate("Unit Price", 1);
        SalesLine.Modify(true);

        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, 1);
        SalesLine.Validate(Type, SalesLine.Type::" ");
        SalesLine.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(SalesLine.Description)));
        SalesLine.Modify(true);

        SalesInvoiceHeader.Get(LibrarySmallBusiness.PostSalesInvoice(SalesHeader));

        GLEntry.FindLast;

        // // EXERCISE
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderTmp);
        CheckEverythingIsReverted(Item, Cust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCancelInvoiceUsingGLAccount()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize;

        CreateSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesHeader, SalesLine);

        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, 1);
        SalesLine.Validate(Type, SalesLine.Type::" ");
        SalesLine.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(SalesLine.Description)));
        SalesLine.Modify(true);

        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, 1);
        SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
        SalesLine.Validate("No.", LibraryERM.CreateGLAccountWithSalesSetup);
        SalesLine.Validate("Unit Price", 1);
        SalesLine.Modify(true);

        SalesInvoiceHeader.Get(LibrarySmallBusiness.PostSalesInvoice(SalesHeader));

        GLEntry.FindLast;

        // EXERCISE
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);
        CheckEverythingIsReverted(Item, Cust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostingDateBlocked()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeaderTmp: Record "Sales Header";
        GLSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize;

        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvoiceHeader);

        GLSetup.Get();
        GLSetup."Allow Posting To" := CalcDate('<-1D>', WorkDate);
        GLSetup.Modify(true);
        Commit();

        if GLEntry.FindLast then;

        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderTmp);
        CheckNothingIsCreated(Cust."No.", GLEntry);

        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);
        CheckNothingIsCreated(Cust."No.", GLEntry);

        GLSetup.Get();
        GLSetup."Allow Posting To" := 0D;
        GLSetup.Modify(true);
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostingDateInvtBlocked()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeaderTmp: Record "Sales Header";
        InvtPeriod: Record "Inventory Period";
        GLEntry: Record "G/L Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize;

        CreateItemsWithPrice(Item, 0);

        CreateAndPostPurchInvForItem(Item, 1, 1);

        LibrarySmallBusiness.CreateCustomer(Cust);
        SellItem(Cust, Item, 1, SalesInvoiceHeader);

        LibraryCosting.AdjustCostItemEntries('', '');

        InvtPeriod.Init();
        InvtPeriod."Ending Date" := CalcDate('<+1D>', WorkDate);
        InvtPeriod.Closed := true;
        InvtPeriod.Insert();
        Commit();

        GLEntry.FindLast;

        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderTmp);
        CheckNothingIsCreated(Cust."No.", GLEntry);

        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);
        CheckNothingIsCreated(Cust."No.", GLEntry);

        InvtPeriod.Delete();
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvoiceLineLessThanZero()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        Initialize;

        // EXERCISE
        asserterror CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 10, -1, SalesInvoiceHeader);

        // EXERCISE
        asserterror CreateAndPostSalesInvForNewItemAndCust(Item, Cust, -10, 1, SalesInvoiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExternalDoc()
    var
        SalesHeader: Record "Sales Header";
        Cust: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        OldSalesSetup: Record "Sales & Receivables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        GLEntry: Record "G/L Entry";
        SalesHeaderCorrection: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize;

        CreateItemsWithPrice(Item, 0);
        LibrarySmallBusiness.CreateCustomer(Cust);

        if GLEntry.FindLast then;

        SalesSetup.Get();
        SalesSetup.Validate("Ext. Doc. No. Mandatory", false);
        SalesSetup.Modify(true);

        // Create the invoice and post it
        LibrarySmallBusiness.CreateSalesInvoiceHeader(SalesHeader, Cust);
        SalesHeader.Validate("External Document No.", '');
        SalesHeader.Modify(true);
        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, 1);
        SalesInvoiceHeader.Get(LibrarySmallBusiness.PostSalesInvoice(SalesHeader));

        SalesSetup.Get();
        OldSalesSetup := SalesSetup;
        SalesSetup.Validate("Ext. Doc. No. Mandatory", true);
        SalesSetup.Modify(true);
        Commit();

        GLEntry.FindLast;

        // CHECK: IT SHOULD NOT BE POSSIBLE TO UNDO WHEN EXTERNAL DOC IS MANDATORY
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);

        // VERIFY
        CheckNothingIsCreated(Cust."No.", GLEntry);

        // CHECK: IT SHOULD NOT BE POSSIBLE TO UNDO WHEN EXTERNAL DOC IS MANDATORY
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // VERIFY
        CheckNothingIsCreated(Cust."No.", GLEntry);

        SalesSetup.Get();
        SalesSetup.Validate("Ext. Doc. No. Mandatory", OldSalesSetup."Ext. Doc. No. Mandatory");
        SalesSetup.Modify(true);
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemLedgEntryApplied()
    var
        SalesHeader: Record "Sales Header";
        Cust: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        SalesHeaderCorrection: Record "Sales Header";
        LastItemLedgEntry: Record "Item Ledger Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        LibrarySales: Codeunit "Library - Sales";
    begin
        Initialize;

        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 2, 1, SalesInvoiceHeader);

        LastItemLedgEntry.FindLast;
        Assert.AreEqual(-1, LastItemLedgEntry."Shipped Qty. Not Returned", '');

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        SalesLine.Validate("Appl.-from Item Entry", LastItemLedgEntry."Entry No.");
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LastItemLedgEntry.Find;
        Assert.AreEqual(0, LastItemLedgEntry."Shipped Qty. Not Returned", '');

        // Introduce new cost
        CreateAndPostPurchInvForItem(Item, 1000, 1);

        GLEntry.FindLast;

        // CHECK: IT SHOULD NOT BE POSSIBLE TO UNDO WHEN EXTERNAL DOC IS MANDATORY
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);
        Assert.ExpectedError(StrSubstNo(ShippedQtyReturnedCorrectErr, Item."No.", Item.Description));

        // VERIFY
        CheckNothingIsCreated(Cust."No.", GLEntry);

        // CHECK: IT SHOULD NOT BE POSSIBLE TO UNDO WHEN EXTERNAL DOC IS MANDATORY
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);
        Assert.ExpectedError(StrSubstNo(ShippedQtyReturnedCancelErr, Item."No.", Item.Description));

        // VERIFY
        CheckNothingIsCreated(Cust."No.", GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPaymentAlreadyMade()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        SalesHeaderCorrection: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize;

        CreateItemsWithPrice(Item, 1);

        LibrarySmallBusiness.CreateCustomer(Cust);
        SetupCustToPayInCash(Cust);

        SellItem(Cust, Item, 1, SalesInvoiceHeader);

        SalesInvoiceHeader.CalcFields(Closed);
        Assert.IsTrue(SalesInvoiceHeader.Closed, 'Cash Payment should have closed the Posted Invoice');

        if GLEntry.FindLast then;

        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);

        // VERIFY
        CheckNothingIsCreated(Cust."No.", GLEntry);

        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // VERIFY
        CheckNothingIsCreated(Cust."No.", GLEntry);
    end;

    [Test]
    [HandlerFunctions('UnapplyCustomerEntries,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceWithUnappliedPayment()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        SalesHeaderCorrection: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        // [SCENARIO] Correcting a sales invoice paid in cash where the payment has been manually unapplied
        Initialize;

        if GLEntry.FindLast then;

        // [GIVEN] An item
        CreateItemsWithPrice(Item, 1);

        // [GIVEN] A cash customer
        LibrarySmallBusiness.CreateCustomer(Cust);
        SetupCustToPayInCash(Cust);

        // [GIVEN] A posted sales invoice
        SellItem(Cust, Item, 1, SalesInvoiceHeader);

        // [WHEN] Unapplying the payment for the posted sales invoice
        LibraryVariableStorage.Enqueue(EntriesSuccessfullyUnappliedMsg);
        CustEntryApplyPostedEntries.UnApplyCustLedgEntry(SalesInvoiceHeader."Cust. Ledger Entry No.");

        // [THEN] The sales invoice can be corrected
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);

        // [THEN] Everything is reverted
        CheckValueEntriesAreReverted(Item, Cust);
        CheckGLEntryIsReverted(Cust, GLEntry);

        // [THEN] The customer balance shows that the customer is owed his cash payment.
        Cust.CalcFields(Balance);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        Cust.TestField(Balance, -SalesInvoiceHeader."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCancelInvoiceBasedOnOrder()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize;

        if GLEntry.FindLast then;

        CreateAndPostSalesOrderForNewItemAndCust(Item, Cust, 1, 1, SalesInvoiceHeader);
        CheckSomethingIsPosted(Item, Cust);

        // EXERCISE
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // VERIFY: Sales Header must match before and after Correct Invoice
        CheckEverythingIsReverted(Item, Cust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceBasedOnOrder()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        SalesHeaderCorrection: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize;

        if GLEntry.FindLast then;

        CreateAndPostSalesOrderForNewItemAndCust(Item, Cust, 1, 1, SalesInvoiceHeader);
        CheckSomethingIsPosted(Item, Cust);

        // EXERCISE
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);

        // VERIFY: Sales Header must match before and after Correct Invoice
        CheckEverythingIsReverted(Item, Cust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_DrillDownCancelledFieldOfPostedSalesInvoicePage()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 168492] "Posted Sales Credit Memo" page is opened when drill down field "Cancelled" on "Posted Sales Invoice" page

        Initialize;

        // [GIVEN] Posted Credit Memo "B" cancelled Posted Invoice "A"
        CancelInvoice(SalesInvHeader, SalesCrMemoHeader);

        // [GIVEN] "Posted Sales Invoice" page is opened
        PostedSalesInvoice.OpenEdit;
        PostedSalesInvoice.GotoRecord(SalesInvHeader);
        PostedSalesCreditMemo.Trap;

        // [WHEN] Press Drill down on field "Cancelled" of "Posted Sales Invoice" page
        PostedSalesInvoice.Cancelled.DrillDown;

        // [THEN] "Posted Sales Credit Memo" page is opened and "No." = "B"
        PostedSalesCreditMemo."No.".AssertEquals(SalesCrMemoHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_DrillDownCancelledFieldOfPostedSalesInvoicesPage()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 168492] "Posted Sales Credit Memo" page is opened when drill down field "Cancelled" on "Posted Sales Invoices" page

        Initialize;

        // [GIVEN] Posted Credit Memo "B" cancelled Posted Invoice "A"
        CancelInvoice(SalesInvHeader, SalesCrMemoHeader);

        // [GIVEN] "Posted Sales Invoice" page is opened
        PostedSalesInvoices.OpenEdit;
        PostedSalesInvoices.GotoRecord(SalesInvHeader);
        PostedSalesCreditMemo.Trap;

        // [WHEN] Press Drill down on field "Cancelled" of "Posted Sales Invoice" page
        PostedSalesInvoices.Cancelled.DrillDown;

        // [THEN] "Posted Sales Credit Memo" page is opened and "No." = "B"
        PostedSalesCreditMemo."No.".AssertEquals(SalesCrMemoHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceFoundationSetupDisabled()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [UT] [UI] [Sales] [Invoice]
        // [SCENARIO 227897] "Correct" and "Cancel" actions are visible on "Posted Sales Invoice" page when foundation setup is disabled
        LibraryApplicationArea.DisableApplicationAreaSetup;

        PostedSalesInvoice.OpenView;
        Assert.IsTrue(PostedSalesInvoice.Cancelled.Visible, 'Cancelled.Visible');
        Assert.IsTrue(PostedSalesInvoice.CorrectInvoice.Visible, 'action Correct.Visible');
        Assert.IsTrue(PostedSalesInvoice.CancelInvoice.Visible, 'action Cancel.Visible');
        Assert.IsFalse(PostedSalesInvoice.ShowCreditMemo.Visible, 'action ShowCreditMemo.Visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelInvoiceActionInvisibleOnCancelledPostedSalesInvoice()
    var
        CancelledDocument: record "Cancelled Document";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [UT] [UI] [Sales] [Invoice]
        // [SCENARIO] "Correct" and "Cancel" actions are not visible on "Posted Sales Invoice" page if invoice is cancelled.
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader.Insert();
        LibrarySmallBusiness.MockCancelledDocument(Database::"Sales Invoice Header", SalesInvoiceHeader."No.", '');

        // [WHEN] Open the cancelled Posted Sales Invoice
        PostedSalesInvoice.Trap();
        Page.Run(Page::"Posted Sales Invoice", SalesInvoiceHeader);
        // [THEN] Actions CorrectInvoice and CancelInvoice are invisible, action ShowCreditMemo is visible
        Assert.IsTrue(PostedSalesInvoice.Cancelled.Visible, 'Cancelled.Visible');
        Assert.IsFalse(PostedSalesInvoice.CorrectInvoice.Visible, 'action Correct.Visible');
        Assert.IsFalse(PostedSalesInvoice.CancelInvoice.Visible, 'action Cancel.Visible');
        Assert.IsTrue(PostedSalesInvoice.ShowCreditMemo.Visible, 'action ShowCreditMemo.Visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelInvoiceActionInvisibleOnCancelledPostedSalesInvoiceList()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
    begin
        // [FEATURE] [UT] [UI] [Sales] [Invoice]
        // [SCENARIO] "Correct" and "Cancel" actions are not visible on "Posted Sales Invoices" list page if invoice is cancelled.
        Initialize();
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader.Insert();
        LibrarySmallBusiness.MockCancelledDocument(Database::"Sales Invoice Header", SalesInvoiceHeader."No.", '');

        // [WHEN] Open the list page on the cancelled Posted Sales Invoice
        PostedSalesInvoices.OpenView();
        PostedSalesInvoices.GoToRecord(SalesInvoiceHeader);
        // [THEN] Actions CorrectInvoice and CancelInvoice are invisible, action ShowCreditMemo is visible
        Assert.IsTrue(PostedSalesInvoices.Cancelled.Visible, 'Cancelled.Visible');
        Assert.IsFalse(PostedSalesInvoices.CorrectInvoice.Visible, 'action Correct.Visible');
        Assert.IsFalse(PostedSalesInvoices.CancelInvoice.Visible, 'action Cancel.Visible');
        Assert.IsTrue(PostedSalesInvoices.ShowCreditMemo.Visible, 'action ShowCreditMemo.Visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceZeroAmountDeclineCancel()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [SCENARIO 352180] Posted Sales Invoice with zero amount line cannot be corrected
        Initialize();

        // [GIVEN] Posted Sales Invoice with 1 line and Unit Price/Line Amount = 0
        CreateAndPostSalesInvForNewItemAndCust(Item, Customer, 0, 1, SalesInvoiceHeader);

        // [WHEN] Invoice is corrected
        // [THEN] Error message 'Amount must have a value in Sales Invoice Header' appears
        asserterror CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, FALSE);
        Assert.ExpectedError(AmountSalesInvErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectPostedSalesInvoice2LinesOneZeroUnitPrice()
    var
        Customer: Record Customer;
        Item1: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLineType: Enum "Sales Line Type";
        PostedSalesInvoiceNo: Code[20];
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [SCENARIO 352180] Posted Sales Invoice with zero linr amount line can be corrected
        Initialize();

        // [GIVEN] Posted Sales Invoice PSI1 with 2 lines. 
        // Item1, Qty = 1, Unit Price = 0, Line Amount = 0
        // Item2, Qty = 1, Unit Price = 10, Line Amount = 10
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, LibrarySales.CreateCustomerNo());
        CreateItemsWithPrice(Item1, 0);
        CreateItemsWithPrice(Item2, 10);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLineType::Item, Item1."No.", 1);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLineType::Item, Item2."No.", 1);
        PostedSalesInvoiceNo := LibrarySales.PostSalesDocument(Salesheader, TRUE, TRUE);
        SalesInvoiceHeader.GET(PostedSalesInvoiceNo);

        // [WHEN] Correct Posted Invoice is invoked
        CorrectPostedSalesInvoice.CancelPostedInvoiceStartNewInvoice(SalesInvoiceHeader, SalesHeader);

        // [THEN] New Sales Invoice created lines equal to PSI1
        SalesLine.Reset();
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);

        SalesLine.SetRange("No.", Item1."No.");
        SalesLine.FindFirst();
        SalesLine.TestField("Unit Price", 0);

        SalesLine.SetRange("No.", Item2."No.");
        SalesLine.FindFirst();
        SalesLine.TestField("Unit Price", 10);
    end;

    local procedure Initialize()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Correct Sales Invoice");
        // Initialize setup.
        LibrarySetupStorage.Restore;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Correct Sales Invoice");

        if not LibraryFiscalYear.AccountingPeriodsExists then
            LibraryFiscalYear.CreateFiscalYear;

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.UpdateGenProdPostingGroup;
        LibraryApplicationArea.EnableFoundationSetup;

        SalesSetup.Get();
        if SalesSetup."Order Nos." = '' then
            SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode);

        if SalesSetup."Posted Shipment Nos." = '' then
            SalesSetup.Validate("Posted Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode);

        SalesSetup.Modify();

        LibraryERMCountryData.UpdateSalesReceivablesSetup;
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Correct Sales Invoice");
    end;

    local procedure VerifyCorrectionFailsOnBlockedGLAcc(GLAcc: Record "G/L Account"; BillToCust: Record Customer; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        GLEntry: Record "G/L Entry";
        SalesHeaderCorrection: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        BlockGLAcc(GLAcc);

        GLEntry.FindLast;

        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);

        // VERIFY
        CheckNothingIsCreated(BillToCust."No.", GLEntry);

        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // VERIFY
        CheckNothingIsCreated(BillToCust."No.", GLEntry);

        UnblockGLAcc(GLAcc);
    end;

    local procedure VerifyCorrectionFailsOnMandatoryDimGLAcc(GLAcc: Record "G/L Account"; BillToCust: Record Customer; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        DefaultDim: Record "Default Dimension";
        GLEntry: Record "G/L Entry";
        SalesHeaderCorrection: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // Make Dimension Mandatory
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          DefaultDim, DATABASE::"G/L Account", GLAcc."No.", DefaultDim."Value Posting"::"Code Mandatory");
        Commit();

        if GLEntry.FindLast then;

        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);

        // VERIFY
        CheckNothingIsCreated(BillToCust."No.", GLEntry);

        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // VERIFY
        CheckNothingIsCreated(BillToCust."No.", GLEntry);

        // Unblock the Dimension
        DefaultDim.Delete(true);
        Commit();
    end;

    local procedure CreateItemsWithPrice(var Item: Record Item; UnitPrice: Decimal)
    begin
        CreateServiceItemWithPrice(Item, UnitPrice);
        CreateInventoryItemWithPrice(Item, UnitPrice);
    end;

    local procedure CreateResourceWithPrice(var Resource: Record Resource; UnitPrice: Decimal)
    begin
        LibraryResource.CreateResourceNew(Resource);
        Resource.Validate("Unit Price", UnitPrice);
        Resource.Modify();
    end;

    local procedure CreateInventoryItemWithPrice(var Item: Record Item; UnitPrice: Decimal)
    begin
        LibrarySmallBusiness.CreateItem(Item);
        Item."Unit Price" := UnitPrice;
        Item.Type := Item.Type::Inventory;
        Item.Modify();
    end;

    local procedure CreateServiceItemWithPrice(var Item: Record Item; UnitPrice: Decimal)
    begin
        LibrarySmallBusiness.CreateItem(Item);
        Item."Unit Price" := UnitPrice;
        Item.Type := Item.Type::Service;
        Item.Modify();
    end;

    local procedure SellItem(SellToCust: Record Customer; Item: Record Item; Qty: Decimal; var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesInvoiceForItem(SellToCust, Item, Qty, SalesHeader, SalesLine);
        SalesInvoiceHeader.Get(LibrarySmallBusiness.PostSalesInvoice(SalesHeader));
    end;

    local procedure CopyGLAccToGLAcc(var FromGLAcc: Record "G/L Account"; var ToGLAcc: Record "G/L Account")
    begin
        FromGLAcc.FindSet;
        repeat
            ToGLAcc := FromGLAcc;
            if ToGLAcc.Insert() then;
        until FromGLAcc.Next = 0;
    end;

    local procedure BlockGLAcc(var GLAcc: Record "G/L Account")
    begin
        GLAcc.Find;
        GLAcc.Validate(Blocked, true);
        GLAcc.Modify(true);
        Commit();
    end;

    local procedure UnblockGLAcc(var GLAcc: Record "G/L Account")
    begin
        GLAcc.Find;
        GLAcc.Validate(Blocked, false);
        GLAcc.Modify(true);
        Commit();
    end;

    local procedure CreateSellToWithDifferentBillToCust(var SellToCust: Record Customer; var BillToCust: Record Customer)
    begin
        LibrarySmallBusiness.CreateCustomer(SellToCust);
        LibrarySmallBusiness.CreateCustomer(BillToCust);
        SellToCust.Validate("Bill-to Customer No.", BillToCust."No.");
        SellToCust.Modify(true);
    end;

    local procedure CreateAndPostSalesInvForNewItemAndCust(var Item: Record Item; var Cust: Record Customer; UnitPrice: Decimal; Qty: Decimal; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        CreateItemsWithPrice(Item, UnitPrice);
        Item.Description := 'Test Item';
        Item.Modify();
        LibrarySmallBusiness.CreateCustomer(Cust);
        SellItem(Cust, Item, Qty, SalesInvoiceHeader);
    end;

    local procedure CreateAndPostSalesInvForNewJobResAndCust(var Resource: Record Resource; var Cust: Record Customer; UnitPrice: Decimal; Qty: Decimal; var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Job: Record Job;
    begin
        CreateResourceWithPrice(Resource, UnitPrice);
        LibrarySales.CreateCustomer(Cust);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Resource, Resource."No.", Qty);
        LibraryJob.CreateJob(Job);
        SalesLine.Validate("Job No.", Job."No.");
        SalesLine.Modify(true);
        SalesInvoiceHeader.Get(LibrarySmallBusiness.PostSalesInvoice(SalesHeader));
    end;

    local procedure CreateSalesInvForNewItemAndCust(var Item: Record Item; var Cust: Record Customer; UnitPrice: Decimal; Qty: Decimal; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        CreateItemsWithPrice(Item, UnitPrice);
        LibrarySmallBusiness.CreateCustomer(Cust);
        CreateSalesInvoiceForItem(Cust, Item, Qty, SalesHeader, SalesLine);
    end;

    local procedure CreateSalesInvoiceForItem(Cust: Record Customer; Item: Record Item; Qty: Decimal; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        LibrarySmallBusiness.CreateSalesInvoiceHeader(SalesHeader, Cust);
        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, Qty);
    end;

    local procedure CreateAndPostPurchInvForItem(Item: Record Item; Qty: Decimal; UnitCost: Decimal)
    var
        PurchSetup: Record "Purchases & Payables Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Vend: Record Vendor;
    begin
        PurchSetup.Get();
        PurchSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchSetup.Modify(true);

        LibrarySmallBusiness.CreateVendor(Vend);

        LibrarySmallBusiness.CreatePurchaseInvoiceHeader(PurchHeader, Vend);
        LibrarySmallBusiness.CreatePurchaseLine(PurchLine, PurchHeader, Item, Qty);

        PurchLine.Validate("Unit Cost", UnitCost);
        PurchLine.Modify(true);
        LibrarySmallBusiness.PostPurchaseInvoice(PurchHeader);
    end;

    local procedure CreateAndPostSalesOrderForNewItemAndCust(var Item: Record Item; var Cust: Record Customer; UnitPrice: Decimal; Qty: Decimal; var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateItemsWithPrice(Item, UnitPrice);
        Item.Description := 'Test Item';
        Item.Modify();
        LibrarySmallBusiness.CreateCustomer(Cust);
        LibrarySmallBusiness.CreateSalesOrderHeader(SalesHeader, Cust);
        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, Qty);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CorrectAndCancelWithFailureAndVerificaltion(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeaderCorrection: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        if GLEntry.FindLast then;
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);
        CheckNothingIsCreated(SalesInvoiceHeader."Bill-to Customer No.", GLEntry);
        if GLEntry.FindLast then;
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);
        CheckNothingIsCreated(SalesInvoiceHeader."Bill-to Customer No.", GLEntry);
    end;

    local procedure CancelInvoice(var SalesInvHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        Item: Record Item;
        Cust: Record Customer;
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        CreateAndPostSalesInvForNewItemAndCust(Item, Cust, 1, 1, SalesInvHeader);
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvHeader);
        LibrarySmallBusiness.FindSalesCorrectiveCrMemo(SalesCrMemoHeader, SalesInvHeader);
    end;

    local procedure SetupCustToPayInCash(var Cust: Record Customer)
    var
        PaymentMethod: Record "Payment Method";
    begin
        // Get a Cash Payment method
        PaymentMethod.SetRange("Bal. Account Type", PaymentMethod."Bal. Account Type"::"G/L Account");
        PaymentMethod.SetFilter("Bal. Account No.", '<>%1', '');
        if not PaymentMethod.FindFirst then begin
            LibraryERM.CreatePaymentMethod(PaymentMethod);
            PaymentMethod.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo);
            PaymentMethod.Modify(true);
        end;

        // Setup the customer to alway pay in cash
        Cust.Validate("Application Method", Cust."Application Method"::"Apply to Oldest");
        Cust.Validate("Payment Method Code", PaymentMethod.Code);
        Cust.Modify(true);
    end;

    local procedure TurnOffExactCostReversing()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.Validate("Exact Cost Reversing Mandatory", false);
        SalesSetup.Modify(true);
        Commit();
    end;

    local procedure CheckSomethingIsPosted(Item: Record Item; Cust: Record Customer)
    begin
        // Inventory should go back to zero
        Item.CalcFields(Inventory);
        Assert.IsTrue(Item.Inventory < 0, '');

        // Customer balance should go back to zero
        Cust.CalcFields(Balance);
        Assert.IsTrue(Cust.Balance > 0, '');
    end;

    local procedure CheckEverythingIsReverted(Item: Record Item; Cust: Record Customer; LastGLEntry: Record "G/L Entry")
    begin
        CheckValueEntriesAreReverted(Item, Cust);
        CheckCustomerBalanceIsZero(Cust);
        CheckGLEntryIsReverted(Cust, LastGLEntry);
    end;

    local procedure CheckValueEntriesAreReverted(Item: Record Item; Cust: Record Customer)
    var
        ValueEntry: Record "Value Entry";
        TotalCost: Decimal;
        TotalQty: Decimal;
    begin
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        ValueEntry.SetRange("Source Type", ValueEntry."Source Type"::Customer);
        ValueEntry.SETRANGE("Source No. 2", Cust."No."); // NAVCZ
        ValueEntry.FindSet;
        repeat
            TotalQty += ValueEntry."Item Ledger Entry Quantity";
            TotalCost += ValueEntry."Cost Amount (Actual)";
        until ValueEntry.Next = 0;
        Assert.AreEqual(0, TotalQty, '');
        Assert.AreEqual(0, TotalCost, '');
    end;

    local procedure CheckGLEntryIsReverted(Cust: Record Customer; LastGLEntry: Record "G/L Entry")
    var
        CustPostingGroup: Record "Customer Posting Group";
        GLEntry: Record "G/L Entry";
        TotalDebit: Decimal;
        TotalCredit: Decimal;
    begin
        CustPostingGroup.Get(Cust."Customer Posting Group");
        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntry."Entry No.");
        GLEntry.FindSet;
        repeat
            TotalDebit += GLEntry."Credit Amount";
            TotalCredit += GLEntry."Debit Amount";
        until GLEntry.Next = 0;

        Assert.AreEqual(TotalDebit, TotalCredit, '');
    end;

    local procedure CheckCustomerBalanceIsZero(Cust: Record Customer)
    begin
        // Customer balance should go back to zero
        Cust.CalcFields(Balance);
        Assert.AreEqual(0, Cust.Balance, '');
    end;

    local procedure CheckNothingIsCreated(CustNo: Code[20]; LastGLEntry: Record "G/L Entry")
    var
        SalesHeader: Record "Sales Header";
    begin
        Assert.IsTrue(LastGLEntry.Next = 0, 'No new G/L entries are created');
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.SetRange("Bill-to Customer No.", CustNo);
        Assert.IsTrue(SalesHeader.IsEmpty, 'The Credit Memo should not have been created');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText, Message);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoicePageHandler(var SalesInvoice: TestPage "Sales Invoice")
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesCrMemoPageHandler(var PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo")
    begin
        PostedSalesCreditMemo.Corrective.AssertEquals(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyCustomerEntries(var UnapplyCustomerEntries: TestPage "Unapply Customer Entries")
    begin
        UnapplyCustomerEntries.Unapply.Invoke;
    end;
}

