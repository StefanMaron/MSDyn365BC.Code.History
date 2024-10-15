codeunit 134398 "ERM Sales/Purch. Correct. Docs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Corrective Documents]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectSalesInvoiceWithLinePointingRoundingAccount()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice] [Credit Memo]
        // [SCENARIO 224605] Cassie can correct posted sales invoice with line pointing to customer's rounding G/L Account.
        Initialize;

        // [GIVEN] Invoice rounding is enabled in sales setup
        LibrarySales.SetInvoiceRounding(true);

        // [GIVEN] Posted invoice with line pointed to customer's rounding G/L Account.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        CreateSalesLinesWithRoundingGLAcccount(SalesHeader, Customer);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.Get(DocumentNo);

        // [WHEN] Correct posted invoice
        Clear(SalesHeader);
        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, false);
        CorrectPostedSalesInvoice.CancelPostedInvoiceStartNewInvoice(SalesInvoiceHeader, SalesHeader);

        // [THEN] System created new invoice with two lines copied from posted invoice
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        Assert.RecordCount(SalesLine, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPurchaseInvoiceWithLinePointingRoundingAccount()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice] [Credit Memo]
        // [SCENARIO 224605] Cassie can correct posted zero balanced purchase invoice
        Initialize;

        // [GIVEN] Cassie can correct posted purchase invoice with line pointing to customer's rounding G/L Account.
        LibraryPurchase.SetInvoiceRounding(true);

        // [GIVEN] Posted invoice with line pointed to vendor's rounding G/L Account.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        CreatePurchaseLinesWithRoundingGLAcccount(PurchaseHeader, Vendor);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.Get(DocumentNo);

        // [WHEN] Correct posted invoice
        Clear(PurchaseHeader);
        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, false);
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeader);

        // [THEN] System created new invoice with two lines copied from posted invoice
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.RecordCount(PurchaseLine, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectSalesInvoiceWithoutDiscountPosting()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice] [Credit Memo]
        // [SCENARIO 299514] Cassie can correct posted sales invoice when "Sales Line Disc. Account" is not set and "Discount Posting" = "No Discounts" in setup
        Initialize;

        LibrarySales.SetDiscountPosting(SalesReceivablesSetup."Discount Posting"::"No Discounts");

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Modify(true);
        CleanSalesLineDiscAccountOnGenPostingSetup(SalesLine, GeneralPostingSetup);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.Get(DocumentNo);

        Clear(SalesHeader);
        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, false);
        CorrectPostedSalesInvoice.CancelPostedInvoiceStartNewInvoice(SalesInvoiceHeader, SalesHeader);

        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Invoice);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPurchaseInvoiceWithoutDiscountPosting()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice] [Credit Memo]
        // [SCENARIO 299514] Cassie can correct posted purchase invoice when "Purch. Line Disc. Account" is not set and "Discount Posting" = "No Discounts" in setup
        Initialize;

        LibraryPurchase.SetDiscountPosting(PurchasesPayablesSetup."Discount Posting"::"No Discounts");

        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        PurchaseLine.Modify(true);
        CleanPurchLineDiscAccountOnGenPostingSetup(PurchaseLine, GeneralPostingSetup);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.Get(DocumentNo);

        Clear(PurchaseHeader);
        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, false);
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeader);

        PurchaseHeader.TestField("Document Type", PurchaseHeader."Document Type"::Invoice);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales/Purch. Correct. Docs");
        LibrarySetupStorage.Restore;

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales/Purch. Correct. Docs");

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdateSalesReceivablesSetup;
        LibraryERMCountryData.UpdatePurchasesPayablesSetup;
        LibraryERMCountryData.CreateGeneralPostingSetupData;

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        IsInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales/Purch. Correct. Docs");
    end;

    local procedure CreateSalesLinesWithRoundingGLAcccount(SalesHeader: Record "Sales Header"; Customer: Record Customer)
    var
        SalesLine: Record "Sales Line";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        with SalesLine do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, 1);
            Validate("Unit Price", LibraryRandom.RandIntInRange(20, 40));
            Modify(true);

            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, 1);
            Validate("Unit Price", -LibraryRandom.RandIntInRange(5, 10));
            Modify(true);
        end;

        with CustomerPostingGroup do begin
            Get(Customer."Customer Posting Group");
            Validate("Invoice Rounding Account", SalesLine."No.");
            Modify(true);
        end;
    end;

    local procedure CreatePurchaseLinesWithRoundingGLAcccount(PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor)
    var
        PurchaseLine: Record "Purchase Line";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        with PurchaseLine do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup, 1);
            Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(20, 40));
            Modify(true);

            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup, 1);
            Validate("Direct Unit Cost", -LibraryRandom.RandIntInRange(5, 10));
            Modify(true);
        end;

        with VendorPostingGroup do begin
            Get(Vendor."Vendor Posting Group");
            Validate("Invoice Rounding Account", PurchaseLine."No.");
            Modify(true);
        end;
    end;

    local procedure CleanSalesLineDiscAccountOnGenPostingSetup(SalesLine: Record "Sales Line"; var OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        OldGeneralPostingSetup.Copy(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Sales Line Disc. Account", '');
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CleanPurchLineDiscAccountOnGenPostingSetup(PurchaseLine: Record "Purchase Line"; var OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        OldGeneralPostingSetup.Copy(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Purch. Line Disc. Account", '');
        GeneralPostingSetup.Modify(true);
    end;

    local procedure RestoreGenPostingSetup(OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(OldGeneralPostingSetup."Gen. Bus. Posting Group", OldGeneralPostingSetup."Gen. Prod. Posting Group");
        GeneralPostingSetup."Sales Line Disc. Account" := OldGeneralPostingSetup."Sales Inv. Disc. Account";
        GeneralPostingSetup."Purch. Line Disc. Account" := OldGeneralPostingSetup."Purch. Line Disc. Account";
        GeneralPostingSetup.Modify;
    end;
}

