codeunit 144073 "ERM Corrected Invoice"
{
    // // [FEATURE] [UT]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        CorrInvDoesNotExistErr: Label 'The Corrected Invoice No. does not exist';
        IncorrectAccOrBalAccTypeErr: Label 'Account Type or Bal. Account Type must be a Customer or Vendor.';
        DocumentTypeMustBeCrMemoErr: Label 'Document Type must be equal to ''Credit Memo''';

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoCorrectedInvExists()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [Sales] [Document]
        // [SCENARIO 261095] Stan can specify the existing value of Sales Invoice in field "Corrected Invoice No." of Sales Credit Memo

        CustNo := LibrarySales.CreateCustomerNo;
        DocNo := MockSalesInvoice(CustNo);

        SalesHeader.Init();
        SalesHeader.Validate("Bill-to Customer No.", CustNo);
        SalesHeader.Validate("Corrected Invoice No.", DocNo);
        SalesHeader.TestField("Corrected Invoice No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoCorrectedInvDoesNotExist()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
    begin
        // [FEATURE] [Sales] [Document]
        // [SCENARIO 261095] Stan cannot specify the not existed value of Sales Invoice in field "Corrected Invoice No." of Sales Credit Memo

        CustNo := LibrarySales.CreateCustomerNo;

        SalesHeader.Init();
        SalesHeader.Validate("Bill-to Customer No.", CustNo);
        asserterror SalesHeader.Validate("Corrected Invoice No.", LibraryUtility.GenerateGUID);
        Assert.ExpectedError(CorrInvDoesNotExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoCorrectedInvExists()
    var
        PurchHeader: Record "Purchase Header";
        VendNo: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Document]
        // [SCENARIO 261095] Stan can specify the existing value of Purchase Invoice in field "Corrected Invoice No." of Purchase Credit Memo

        VendNo := LibraryPurchase.CreateVendorNo;
        DocNo := MockPurchInvoice(VendNo);

        PurchHeader.Init();
        PurchHeader.Validate("Pay-to Vendor No.", VendNo);
        PurchHeader.Validate("Corrected Invoice No.", DocNo);
        PurchHeader.TestField("Corrected Invoice No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoCorrectedInvDoesNotExist()
    var
        PurchHeader: Record "Purchase Header";
        VendNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Document]
        // [SCENARIO 261095] Stan can specify the not existed value of Purchase Invoice in field "Corrected Invoice No." of Purchase Credit Memo

        VendNo := LibraryPurchase.CreateVendorNo;

        PurchHeader.Init();
        PurchHeader.Validate("Pay-to Vendor No.", VendNo);
        asserterror PurchHeader.Validate("Corrected Invoice No.", LibraryUtility.GenerateGUID);
        Assert.ExpectedError(CorrInvDoesNotExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToSpecifyCorrTypeInJournalWithInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Journal]
        // [SCENARIO 261095] Stan cannot specify "Correction Type" in General Journal Line with "Document Type" = Invoice

        GenJournalLine.Init();
        asserterror GenJournalLine.Validate("Correction Type", GenJournalLine."Correction Type"::Difference);
        Assert.ExpectedError(DocumentTypeMustBeCrMemoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToSpecifyCorrInvNoInJournalWithInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Journal]
        // [SCENARIO 261095] Stan cannot specify "Corrected Invoice No." in General Journal Line with "Document Type" = Invoice

        GenJournalLine.Init();
        asserterror GenJournalLine.Validate("Corrected Invoice No.", LibraryUtility.GenerateGUID);
        Assert.ExpectedError(DocumentTypeMustBeCrMemoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToSpecifyCorrTypeInJournalWithGLAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Journal]
        // [SCENARIO 261095] Stan cannot specify "Correction Type" in General Journal Line with "G/L Account" for either "Account Type" or "Bal. Account Type"

        GenJournalLine.Init();
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::"Credit Memo");
        asserterror GenJournalLine.Validate("Correction Type", GenJournalLine."Correction Type"::Difference);
        Assert.ExpectedError(IncorrectAccOrBalAccTypeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToSpecifyCorrInvNoInJournalWithGLAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Journal]
        // [SCENARIO 261095] Stan cannot specify "Corrected Invoice No." in General Journal Line with "G/L Account" for either "Account Type" or "Bal. Account Type"

        GenJournalLine.Init();
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::"Credit Memo");
        asserterror GenJournalLine.Validate("Corrected Invoice No.", LibraryUtility.GenerateGUID);
        Assert.ExpectedError(IncorrectAccOrBalAccTypeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineWithSalesCrMemoCorrectedInvExists()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustNo: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [Sales] [Journal]
        // [SCENARIO 261095] Stan can specify the existing value of Sales Invoice in field "Corrected Invoice No." of General Journal Line

        CustNo := LibrarySales.CreateCustomerNo;
        DocNo := MockSalesInvoice(CustNo);

        GenJournalLine.Init();
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::"Credit Memo");
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
        GenJournalLine.Validate("Account No.", CustNo);
        GenJournalLine.Validate("Corrected Invoice No.", DocNo);
        GenJournalLine.TestField("Corrected Invoice No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineWithSalesCrMemoCorrectedInvDoesNotExist()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustNo: Code[20];
    begin
        // [FEATURE] [Sales] [Journal]
        // [SCENARIO 261095] Stan cannot specify the not existed value of Sales Invoice in field "Corrected Invoice No." of General Journal Line

        CustNo := LibrarySales.CreateCustomerNo;

        GenJournalLine.Init();
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::"Credit Memo");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Account Type"::Customer);
        GenJournalLine.Validate("Bal. Account No.", CustNo);
        asserterror GenJournalLine.Validate("Corrected Invoice No.", LibraryUtility.GenerateGUID);
        Assert.ExpectedError(CorrInvDoesNotExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineWithPurchCrMemoCorrectedInvExists()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendNo: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Journal]
        // [SCENARIO 261095] Stan can specify the existing value of Purchase Invoice in field "Corrected Invoice No." of General Journal Line

        VendNo := LibraryPurchase.CreateVendorNo;
        DocNo := MockPurchInvoice(VendNo);

        GenJournalLine.Init();
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::"Credit Memo");
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.Validate("Account No.", VendNo);
        GenJournalLine.Validate("Corrected Invoice No.", DocNo);
        GenJournalLine.TestField("Corrected Invoice No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineWithPurchCrMemoCorrectedInvDoesNotExist()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Journal]
        // [SCENARIO 261095] Stan cannot specify the not existed value of Purchase Invoice in field "Corrected Invoice No." of General Journal Line

        VendNo := LibraryPurchase.CreateVendorNo;

        GenJournalLine.Init();
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::"Credit Memo");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.Validate("Bal. Account No.", VendNo);
        asserterror GenJournalLine.Validate("Corrected Invoice No.", LibraryUtility.GenerateGUID);
        Assert.ExpectedError(CorrInvDoesNotExistErr);
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoicesModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoCorrectedDocNoLookUpOK()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        CustNo: Code[20];
        ExpectedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo] [LookUP] [Corrected Invoice No]
        // [SCENARIO 267532] When Stan looks up "Corrected Invoice No." on Sales Credit Memo page and then selects Invoice on Posted Sales Invoices page and confirms his choice
        // [SCENARIO 267532] then "Corrected Invoice No." = Posted Sales Invoice "No."

        // [GIVEN] Posted Sales Invoice "I"
        CustNo := LibrarySales.CreateCustomerNo;
        ExpectedInvoiceNo := MockSalesInvoice(CustNo);
        LibraryVariableStorage.Enqueue(ExpectedInvoiceNo);

        // [GIVEN] Stan opened Sales Credit Memo page and looked up "Corrected Invoice No."
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustNo);
        SalesCreditMemo.OpenEdit;
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo."Corrected Invoice No.".Lookup;

        // [WHEN] Stan selects Invoice "I" on page Posted Sales Invoices and pushes OK

        // [THEN] Sales Credit Memo has "Corrected Invoice No." = "I"
        SalesCreditMemo."Corrected Invoice No.".AssertEquals(ExpectedInvoiceNo);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseInvoicesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoCorrectedDocNoLookUpOK()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        VendorNo: Code[20];
        ExpectedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo] [LookUP] [Corrected Invoice No]
        // [SCENARIO 267532] When Stan looks up "Corrected Invoice No." on Purchase Credit Memo page and then selects Invoice on Posted Purchase Invoices page and confirms his choice
        // [SCENARIO 267532] then "Corrected Invoice No." = Posted Purchase Invoice "No."

        // [GIVEN] Posted Purchase Invoice "I"
        VendorNo := LibraryPurchase.CreateVendorNo;
        ExpectedInvoiceNo := MockPurchInvoice(VendorNo);
        LibraryVariableStorage.Enqueue(ExpectedInvoiceNo);

        // [GIVEN] Stan opened Purchase Credit Memo page and looked up "Corrected Invoice No."
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchaseCreditMemo.OpenEdit;
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PurchaseCreditMemo."Corrected Invoice No.".Lookup;

        // [WHEN] Stan selects Invoice "I" on page Posted Purchase Invoices and pushes OK

        // [THEN] Purchase Credit Memo has "Corrected Invoice No." = "I"
        PurchaseCreditMemo."Corrected Invoice No.".AssertEquals(ExpectedInvoiceNo);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostedServiceInvoicesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoCorrectedDocNoLookUpOK()
    var
        ServiceHeader: Record "Service Header";
        ServiceCreditMemo: TestPage "Service Credit Memo";
        CustNo: Code[20];
        ExpectedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Service] [Credit Memo] [LookUP] [Corrected Invoice No]
        // [SCENARIO 267532] When Stan looks up "Corrected Invoice No." on Service Credit Memo page and then selects Invoice on Posted Service Invoices page and confirms his choice
        // [SCENARIO 267532] then "Corrected Invoice No." = Posted Service Invoice "No."

        // [GIVEN] Posted Service Invoice "I"
        CustNo := LibrarySales.CreateCustomerNo;
        ExpectedInvoiceNo := MockServiceInvoice(CustNo);
        LibraryVariableStorage.Enqueue(ExpectedInvoiceNo);

        // [GIVEN] Stan opened Service Credit Memo page and looked up "Corrected Invoice No."
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", CustNo);
        ServiceCreditMemo.OpenEdit;
        ServiceCreditMemo.GotoRecord(ServiceHeader);
        ServiceCreditMemo."Corrected Invoice No.".Lookup;

        // [WHEN] Stan selects Invoice "I" on page Posted Service Invoices and pushes OK

        // [THEN] Service Credit Memo has "Corrected Invoice No." = "I"
        ServiceCreditMemo."Corrected Invoice No.".AssertEquals(ExpectedInvoiceNo);
        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure MockSalesInvoice(CustNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID;
        SalesInvoiceHeader."Bill-to Customer No." := CustNo;
        SalesInvoiceHeader.Insert();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure MockPurchInvoice(VendNo: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Init();
        PurchInvHeader."No." := LibraryUtility.GenerateGUID;
        PurchInvHeader."Pay-to Vendor No." := VendNo;
        PurchInvHeader.Insert();
        exit(PurchInvHeader."No.");
    end;

    local procedure MockServiceInvoice(CustNo: Code[20]): Code[20]
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.Init();
        ServiceInvoiceHeader."No." := LibraryUtility.GenerateGUID;
        ServiceInvoiceHeader."Bill-to Customer No." := CustNo;
        ServiceInvoiceHeader.Insert();
        exit(ServiceInvoiceHeader."No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicesModalPageHandler(var PostedSalesInvoices: TestPage "Posted Sales Invoices")
    begin
        PostedSalesInvoices.GotoKey(LibraryVariableStorage.DequeueText);
        PostedSalesInvoices.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoicesModalPageHandler(var PostedPurchaseInvoices: TestPage "Posted Purchase Invoices")
    begin
        PostedPurchaseInvoices.GotoKey(LibraryVariableStorage.DequeueText);
        PostedPurchaseInvoices.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoicesModalPageHandler(var PostedServiceInvoices: TestPage "Posted Service Invoices")
    begin
        PostedServiceInvoices.GotoKey(LibraryVariableStorage.DequeueText);
        PostedServiceInvoices.OK.Invoke;
    end;
}

