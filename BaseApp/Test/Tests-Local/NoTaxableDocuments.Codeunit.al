codeunit 147515 "No Taxable Documents"
{
    Permissions = TableData "VAT Entry" = rim,
                  TableData "No Taxable Entry" = rd,
                  TableData "Cust. Ledger Entry" = d,
                  TableData "Vendor Ledger Entry" = d;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [No Taxable VAT]
    end;

    var
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibrarySII: Codeunit "Library - SII";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        VATCalcTypeMustBeErr: Label 'VAT Calculation Type must be equal to ''No Taxable VAT''  in VAT Posting Setup';

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntryForSimpleSalesInvoice()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 293795] No Taxable Entry is created for Sales Invoice with VAT Calculation type = No Taxable
        LibraryLowerPermissions.SetO365Full();
        LibrarySII.PostSalesDocWithNoTaxableVAT(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, false, 0);
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        VerifySalesNoTaxableEntries(CustLedgerEntry, -CustLedgerEntry.Amount, -CustLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntryForSimpleSalesCrMemo()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 293795] No Taxable Entry is created for Sales Credit Memo with VAT Calculation type = No Taxable
        LibraryLowerPermissions.SetO365Full();
        LibrarySII.PostSalesDocWithNoTaxableVAT(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", false, 0);
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        VerifySalesNoTaxableEntries(CustLedgerEntry, -CustLedgerEntry.Amount, -CustLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntryForSimpleServiceInvoice()
    var
        ServiceHeader: Record "Service Header";
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 293795] No Taxable Entry is created for Service Invoice with VAT Calculation type = No Taxable
        LibraryLowerPermissions.SetO365Full();
        LibrarySII.FindCustLedgEntryForPostedServInvoice(
          CustLedgerEntry,
          LibrarySII.PostServiceDocWithNonTaxableVAT(ServiceHeader."Document Type"::Invoice,
            VATPostingSetup."No Taxable Type"::"Non Taxable Art 7-14 and others"));
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        VerifySalesNoTaxableEntries(CustLedgerEntry, -CustLedgerEntry.Amount, -CustLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntryForSimpleServiceCrMemo()
    var
        ServiceHeader: Record "Service Header";
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 293795] No Taxable Entry is created for Service Credit Memo with VAT Calculation type = No Taxable
        LibraryLowerPermissions.SetO365Full();
        LibrarySII.FindCustLedgEntryForPostedServCrMemo(
          CustLedgerEntry,
          LibrarySII.PostServiceDocWithNonTaxableVAT(ServiceHeader."Document Type"::"Credit Memo",
            VATPostingSetup."No Taxable Type"::"Non Taxable Art 7-14 and others"));
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        VerifySalesNoTaxableEntries(CustLedgerEntry, -CustLedgerEntry.Amount, -CustLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntryForSimplePurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 293795] No Taxable Entry is created for Purchase Invoice with VAT Calculation type = No Taxable
        LibraryLowerPermissions.SetO365Full();
        CreatePurchaseDocumentWithNoTaxableVAT(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)");

        VerifyPurchNoTaxableEntries(VendorLedgerEntry, -VendorLedgerEntry.Amount, -VendorLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntryForSimplePurchaseCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 293795] No Taxable Entry is created for Purchase Credit Memo with VAT Calculation type = No Taxable
        LibraryLowerPermissions.SetO365Full();
        CreatePurchaseDocumentWithNoTaxableVAT(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", InvoiceNo);
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)");

        VerifyPurchNoTaxableEntries(VendorLedgerEntry, -VendorLedgerEntry.Amount, -VendorLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntrySalesInvoiceGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 293795] No Taxable Entry is created for Sales Invoice posted from Gen. Journal with VAT Calculation type = No Taxable
        LibraryLowerPermissions.SetO365Full();
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", CreateGLAccountNoTaxableSale, 1);

        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        VerifySalesNoTaxableEntries(CustLedgerEntry, -CustLedgerEntry.Amount, -CustLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntrySalesInvoiceBalGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 293795] No Taxable Entry is created for Sales Invoice posted from bal. Gen. Journal with VAT Calculation type = No Taxable
        LibraryLowerPermissions.SetO365Full();
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", CreateGLAccountNoTaxableSale,
          GenJournalLine."Bal. Account Type"::Customer, LibrarySales.CreateCustomerNo, -1);

        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        VerifySalesNoTaxableEntries(CustLedgerEntry, -CustLedgerEntry.Amount, -CustLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntrySalesCreditMemoGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 293795] No Taxable Entry is created for Sales Credit Memo posted from Gen. Journal with VAT Calculation type = No Taxable
        LibraryLowerPermissions.SetO365Full();
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", CreateGLAccountNoTaxableSale, -1);

        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        VerifySalesNoTaxableEntries(CustLedgerEntry, -CustLedgerEntry.Amount, -CustLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntrySalesCreditMemoBalGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 293795] No Taxable Entry is created for Sales Credit Memo posted from bal. Gen. Journal with VAT Calculation type = No Taxable
        LibraryLowerPermissions.SetO365Full();
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::"G/L Account", CreateGLAccountNoTaxableSale,
          GenJournalLine."Bal. Account Type"::Customer, LibrarySales.CreateCustomerNo, 1);

        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        VerifySalesNoTaxableEntries(CustLedgerEntry, -CustLedgerEntry.Amount, -CustLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntryPurchInvoiceGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 293795] No Taxable Entry is created for Purchase Invoice posted from Gen. Journal with VAT Calculation type = No Taxable
        LibraryLowerPermissions.SetO365Full();
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", CreateGLAccountNoTaxablePurch, -1);

        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        VerifyPurchNoTaxableEntries(VendorLedgerEntry, -VendorLedgerEntry.Amount, -VendorLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntryPurchInvoiceBalGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 293795] No Taxable Entry is created for Purchase Invoice posted from bal. Gen. Journal with VAT Calculation type = No Taxable
        LibraryLowerPermissions.SetO365Full();
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", CreateGLAccountNoTaxablePurch,
          GenJournalLine."Bal. Account Type"::Vendor, LibraryPurchase.CreateVendorNo, 1);

        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        VerifyPurchNoTaxableEntries(VendorLedgerEntry, -VendorLedgerEntry.Amount, -VendorLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntryPurchCreditMemoGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 293795] No Taxable Entry is created for Purchase Credit Memo posted from Gen. Journal with VAT Calculation type = No Taxable
        LibraryLowerPermissions.SetO365Full();
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", CreateGLAccountNoTaxablePurch, 1);

        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        VerifyPurchNoTaxableEntries(VendorLedgerEntry, -VendorLedgerEntry.Amount, -VendorLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntryPurchCreditMemoBalGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 293795] No Taxable Entry is created for Purchase Credit Memo posted from bal. Gen. Journal with VAT Calculation type = No Taxable
        LibraryLowerPermissions.SetO365Full();
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::"G/L Account", CreateGLAccountNoTaxablePurch,
          GenJournalLine."Bal. Account Type"::Vendor, LibraryPurchase.CreateVendorNo, -1);

        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        VerifyPurchNoTaxableEntries(VendorLedgerEntry, -VendorLedgerEntry.Amount, -VendorLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure NoTaxableEntryReverseSalesInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales] [Reverse]
        // [SCENARIO 293795] No Taxable entries created for reversal when Sales Invoice is reversed
        LibraryLowerPermissions.SetO365Full();
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", CreateGLAccountNoTaxableSale, 1);

        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        LibraryERM.ReverseTransaction(CustLedgerEntry."Transaction No.");

        VerifyReversedSalesNoTaxableEntries(CustLedgerEntry, -CustLedgerEntry.Amount, -CustLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure NoTaxableEntryReversePurchInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase] [Reverse]
        // [SCENARIO 293795] No Taxable entries created for reversal when Sales Invoice is reversed
        LibraryLowerPermissions.SetO365Full();
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", CreateGLAccountNoTaxablePurch, -1);

        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)");

        LibraryERM.ReverseTransaction(VendorLedgerEntry."Transaction No.");
        VerifyReversedPurchNoTaxableEntries(VendorLedgerEntry, -VendorLedgerEntry.Amount, -VendorLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradeSalesInvoice()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales] [Upgrade]
        // [SCENARIO 293795] No Taxable Entry is created for Sales Invoice with VAT Calculation type = No Taxable
        // [SCENARIO 293795] when run upgrade codeunit "No Taxable Generate Entries"
        DeleteCVLedgerEntries();
        LibraryLowerPermissions.SetO365Full();
        LibrarySII.PostSalesDocWithNoTaxableVAT(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, false, 0);
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        DeleteNoTaxableEntries();
        Codeunit.Run(Codeunit::"No Taxable - Generate Entries");

        VerifySalesNoTaxableEntries(CustLedgerEntry, -CustLedgerEntry.Amount, -CustLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradeSalesCrMemo()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales] [Upgrade]
        // [SCENARIO 293795] No Taxable Entry is created for Sales Credit memo with VAT Calculation type = No Taxable
        // [SCENARIO 293795] when run upgrade codeunit "No Taxable Generate Entries"
        DeleteCVLedgerEntries();
        LibraryLowerPermissions.SetO365Full();
        LibrarySII.PostSalesDocWithNoTaxableVAT(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", false, 0);
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        DeleteNoTaxableEntries();
        Codeunit.Run(Codeunit::"No Taxable - Generate Entries");

        VerifySalesNoTaxableEntries(CustLedgerEntry, -CustLedgerEntry.Amount, -CustLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradeServiceInvoice()
    var
        ServiceHeader: Record "Service Header";
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Service] [Upgrade]
        // [SCENARIO 293795] No Taxable Entry is created for Service Invoice with VAT Calculation type = No Taxable
        // [SCENARIO 293795] when run upgrade codeunit "No Taxable Generate Entries"
        DeleteCVLedgerEntries();
        LibraryLowerPermissions.SetO365Full();
        LibrarySII.FindCustLedgEntryForPostedServInvoice(
          CustLedgerEntry,
          LibrarySII.PostServiceDocWithNonTaxableVAT(ServiceHeader."Document Type"::Invoice,
            VATPostingSetup."No Taxable Type"::"Non Taxable Art 7-14 and others"));
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        DeleteNoTaxableEntries();
        Codeunit.Run(Codeunit::"No Taxable - Generate Entries");

        VerifySalesNoTaxableEntries(CustLedgerEntry, -CustLedgerEntry.Amount, -CustLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradeServiceCrMemo()
    var
        ServiceHeader: Record "Service Header";
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Service] [Upgrade]
        // [SCENARIO 293795] No Taxable Entry is created for Service Credit Memo with VAT Calculation type = No Taxable
        // [SCENARIO 293795] when run upgrade codeunit "No Taxable Generate Entries"
        DeleteCVLedgerEntries();
        LibraryLowerPermissions.SetO365Full();
        LibrarySII.FindCustLedgEntryForPostedServCrMemo(
          CustLedgerEntry,
          LibrarySII.PostServiceDocWithNonTaxableVAT(ServiceHeader."Document Type"::"Credit Memo",
            VATPostingSetup."No Taxable Type"::"Non Taxable Art 7-14 and others"));
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        DeleteNoTaxableEntries();
        Codeunit.Run(Codeunit::"No Taxable - Generate Entries");

        VerifySalesNoTaxableEntries(CustLedgerEntry, -CustLedgerEntry.Amount, -CustLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradePurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Upgrade]
        // [SCENARIO 293795] No Taxable Entry is created for Purchase Invoice with VAT Calculation type = No Taxable
        // [SCENARIO 293795] when run upgrade codeunit "No Taxable Generate Entries"
        DeleteCVLedgerEntries();
        LibraryLowerPermissions.SetO365Full();
        CreatePurchaseDocumentWithNoTaxableVAT(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        DeleteNoTaxableEntries();
        Codeunit.Run(Codeunit::"No Taxable - Generate Entries");

        VerifyPurchNoTaxableEntries(VendorLedgerEntry, -VendorLedgerEntry.Amount, -VendorLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradePurchaseCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Upgrade]
        // [SCENARIO 293795] No Taxable Entry is created for Purchase Credit Memo with VAT Calculation type = No Taxable
        // [SCENARIO 293795] when run upgrade codeunit "No Taxable Generate Entries"
        DeleteCVLedgerEntries();
        LibraryLowerPermissions.SetO365Full();
        CreatePurchaseDocumentWithNoTaxableVAT(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", InvoiceNo);
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        DeleteNoTaxableEntries();
        Codeunit.Run(Codeunit::"No Taxable - Generate Entries");

        VerifyPurchNoTaxableEntries(VendorLedgerEntry, -VendorLedgerEntry.Amount, -VendorLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradeSalesInvoiceGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales] [Upgrade]
        // [SCENARIO 293795] No Taxable Entry is created for Sales Invoice posted from Gen. Journal with VAT Calculation type = No Taxable
        // [SCENARIO 293795] when run upgrade codeunit "No Taxable Generate Entries"
        DeleteCVLedgerEntries();
        LibraryLowerPermissions.SetO365Full();
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", CreateGLAccountNoTaxableSale, 1);

        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        DeleteNoTaxableEntries();
        Codeunit.Run(Codeunit::"No Taxable - Generate Entries");

        VerifySalesNoTaxableEntries(CustLedgerEntry, -CustLedgerEntry.Amount, -CustLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradeSalesInvoiceBalGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales] [Upgrade]
        // [SCENARIO 293795] No Taxable Entry is created for Sales Invoice posted from bal. Gen. Journal with VAT Calculation type = No Taxable
        // [SCENARIO 293795] when run upgrade codeunit "No Taxable Generate Entries"
        DeleteCVLedgerEntries();
        LibraryLowerPermissions.SetO365Full();
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", CreateGLAccountNoTaxableSale,
          GenJournalLine."Bal. Account Type"::Customer, LibrarySales.CreateCustomerNo, -1);

        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        DeleteNoTaxableEntries();
        Codeunit.Run(Codeunit::"No Taxable - Generate Entries");

        VerifySalesNoTaxableEntries(CustLedgerEntry, -CustLedgerEntry.Amount, -CustLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradeSalesCreditMemoGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales] [Upgrade]
        // [SCENARIO 293795] No Taxable Entry is created for Sales Credit Memo posted from Gen. Journal with VAT Calculation type = No Taxable
        // [SCENARIO 293795] when run upgrade codeunit "No Taxable Generate Entries"
        DeleteCVLedgerEntries();
        LibraryLowerPermissions.SetO365Full();
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", CreateGLAccountNoTaxableSale, -1);

        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        DeleteNoTaxableEntries();
        Codeunit.Run(Codeunit::"No Taxable - Generate Entries");

        VerifySalesNoTaxableEntries(CustLedgerEntry, -CustLedgerEntry.Amount, -CustLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradeSalesCreditMemoBalGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales] [Upgrade]
        // [SCENARIO 293795] No Taxable Entry is created for Sales Credit Memo posted from Gen. Journal with VAT Calculation type = No Taxable
        // [SCENARIO 293795] when run upgrade codeunit "No Taxable Generate Entries"
        DeleteCVLedgerEntries();
        LibraryLowerPermissions.SetO365Full();
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::"G/L Account", CreateGLAccountNoTaxableSale,
          GenJournalLine."Bal. Account Type"::Customer, LibrarySales.CreateCustomerNo, 1);

        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        DeleteNoTaxableEntries();
        Codeunit.Run(Codeunit::"No Taxable - Generate Entries");

        VerifySalesNoTaxableEntries(CustLedgerEntry, -CustLedgerEntry.Amount, -CustLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradePurchInvoiceGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase] [Upgrade]
        // [SCENARIO 293795] No Taxable Entry is created for Purchase Invoice posted from Gen. Journal with VAT Calculation type = No Taxable
        // [SCENARIO 293795] when run upgrade codeunit "No Taxable Generate Entries"
        DeleteCVLedgerEntries();
        LibraryLowerPermissions.SetO365Full();
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", CreateGLAccountNoTaxablePurch, -1);

        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        DeleteNoTaxableEntries();
        Codeunit.Run(Codeunit::"No Taxable - Generate Entries");

        VerifyPurchNoTaxableEntries(VendorLedgerEntry, -VendorLedgerEntry.Amount, -VendorLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradePurchInvoiceBalGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase] [Upgrade]
        // [SCENARIO 293795] No Taxable Entry is created for Purchase Invoice posted from bal. Gen. Journal with VAT Calculation type = No Taxable
        // [SCENARIO 293795] when run upgrade codeunit "No Taxable Generate Entries"
        DeleteCVLedgerEntries();
        LibraryLowerPermissions.SetO365Full();
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", CreateGLAccountNoTaxablePurch,
          GenJournalLine."Bal. Account Type"::Vendor, LibraryPurchase.CreateVendorNo, 1);

        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        DeleteNoTaxableEntries();
        Codeunit.Run(Codeunit::"No Taxable - Generate Entries");

        VerifyPurchNoTaxableEntries(VendorLedgerEntry, -VendorLedgerEntry.Amount, -VendorLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradePurchCreditMemoGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase] [Upgrade]
        // [SCENARIO 293795] No Taxable Entry is created for Purchase Credit Memo posted from Gen. Journal with VAT Calculation type = No Taxable
        // [SCENARIO 293795] when run upgrade codeunit "No Taxable Generate Entries"
        DeleteCVLedgerEntries();
        LibraryLowerPermissions.SetO365Full();
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", CreateGLAccountNoTaxablePurch, 1);

        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        DeleteNoTaxableEntries();
        Codeunit.Run(Codeunit::"No Taxable - Generate Entries");

        VerifyPurchNoTaxableEntries(VendorLedgerEntry, -VendorLedgerEntry.Amount, -VendorLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradePurchCreditMemoBalGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase] [Upgrade]
        // [SCENARIO 293795] No Taxable Entry is created for Purchase Credit Memo posted from bal. Gen. Journal with VAT Calculation type = No Taxable
        // [SCENARIO 293795] when run upgrade codeunit "No Taxable Generate Entries"
        DeleteCVLedgerEntries();
        LibraryLowerPermissions.SetO365Full();
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::"G/L Account", CreateGLAccountNoTaxablePurch,
          GenJournalLine."Bal. Account Type"::Vendor, LibraryPurchase.CreateVendorNo, -1);

        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        DeleteNoTaxableEntries();
        Codeunit.Run(Codeunit::"No Taxable - Generate Entries");

        VerifyPurchNoTaxableEntries(VendorLedgerEntry, -VendorLedgerEntry.Amount, -VendorLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradeSalesInvoiceWithLineOfNormalVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Sales] [Upgrade]
        // [SCENARIO 314078] No Taxable Entry is not created for Sales Invoice with VAT Calculation type = Normal
        // [SCENARIO 314078] when run upgrade codeunit "No Taxable Generate Entries"
        DeleteCVLedgerEntries();
        LibraryLowerPermissions.SetO365Full();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        DeleteNoTaxableEntries();
        ResetNoTaxableTypeVATEntries(SalesHeader."VAT Bus. Posting Group");
        Codeunit.Run(Codeunit::"No Taxable - Generate Entries");

        VATPostingSetup.Get(SalesHeader."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        VerifyNoTaxableEntriesNotCreated(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradePurchaseInvoiceWithLineOfNormalVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Purchase] [Upgrade]
        // [SCENARIO 314078] No Taxable Entry is not created for Purchase Invoice with VAT Calculation type = Normal
        // [SCENARIO 314078] when run upgrade codeunit "No Taxable Generate Entries"
        DeleteCVLedgerEntries();
        LibraryLowerPermissions.SetO365Full();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        DeleteNoTaxableEntries();
        ResetNoTaxableTypeVATEntries(PurchaseHeader."VAT Bus. Posting Group");
        Codeunit.Run(Codeunit::"No Taxable - Generate Entries");

        VATPostingSetup.Get(PurchaseHeader."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        VerifyNoTaxableEntriesNotCreated(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradeSalesInvoiceGenJournalNormalVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Sales] [Upgrade]
        // [SCENARIO 314078] No Taxable Entry is not created for Sales Invoice posted from Gen. Journal with normal VAT
        // [SCENARIO 314078] when run upgrade codeunit "No Taxable Generate Entries"
        DeleteCVLedgerEntries();
        LibraryLowerPermissions.SetO365Full();
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, 1);

        DeleteNoTaxableEntries();
        Codeunit.Run(Codeunit::"No Taxable - Generate Entries");

        GLAccount.Get(GenJournalLine."Bal. Account No.");
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        VerifyNoTaxableEntriesNotCreated(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradePurchInvoiceGenJournalNormalVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Purchase] [Upgrade]
        // [SCENARIO 314078] No Taxable Entry is not created for Purchase Invoice posted from Gen. Journal with normal VAT
        // [SCENARIO 314078] when run upgrade codeunit "No Taxable Generate Entries"
        DeleteCVLedgerEntries();
        LibraryLowerPermissions.SetO365Full();
        CreatePostGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup, -1);

        DeleteNoTaxableEntries();
        Codeunit.Run(Codeunit::"No Taxable - Generate Entries");

        GLAccount.Get(GenJournalLine."Bal. Account No.");
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        VerifyNoTaxableEntriesNotCreated(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenPostNormalVATNoTaxablePurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 466990] Error when post purchase invoice with normal No Taxable VAT Posting Setup
        LibraryLowerPermissions.SetO365Full();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Librarypurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, 1);
        MockNormalNoTaxableVATPostingSetup(VATPostingSetup, PurchaseHeader."VAT Bus. Posting Group");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);

        // [WHEN] Post purchase invoice
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Error appeared: "VAT Calculation Type must be No Taxable VAT"
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(VATCalcTypeMustBeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenPostNormalVATNoTaxableSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 466990] Error when post sales invoice with normal No Taxable VAT Posting Setup
        LibraryLowerPermissions.SetO365Full();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, 1);
        MockNormalNoTaxableVATPostingSetup(VATPostingSetup, SalesHeader."VAT Bus. Posting Group");
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Modify(true);

        // [WHEN] Post sales invoice
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Error appeared: "VAT Calculation Type must be No Taxable VAT"
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(VATCalcTypeMustBeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenPostNormalVATNoTaxableServiceInvoice()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 466990] Error when post service invoice with normal No Taxable VAT Posting Setup
        LibraryLowerPermissions.SetO365Full();
        LibrarySII.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '');
        MockNormalNoTaxableVATPostingSetup(VATPostingSetup, ServiceHeader."VAT Bus. Posting Group");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        LibraryService.CreateServiceLineWithQuantity(
            ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", GLAccount."No.", 1);
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        ServiceLine.Modify(true);

        // [WHEN] Post service invoice
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, true, true);

        // [THEN] Error appeared: "VAT Calculation Type must be No Taxable VAT"
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(VATCalcTypeMustBeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenPostNormalVATNoTaxableGeneralJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [General Journal]
        // [SCENARIO 466990] Error when post general journal line with normal No Taxable VAT Posting Setup
        LibraryLowerPermissions.SetO365Full();
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        MockNormalNoTaxableVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          -LibraryRandom.RandDecInRange(100, 200, 2));
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Sale);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::Customer);
        GenJournalLine.Validate("Bal. Account No.", LibrarySales.CreateCustomerNo());
        GenJournalLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Modify(true);

        // [WHEN] Post general journal line
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Error appeared: "VAT Calculation Type must be No Taxable VAT"
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(VATCalcTypeMustBeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPostingSetupNormalWithNoTaxableTypeChangeToNoTaxable()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 466990] Allowed to change VAT Calculation Type from Normal to No Taxable when we have posted VAT Entries
        LibraryLowerPermissions.SetO365Full();
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        MockNormalNoTaxableVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code);
        MockVATEntry(VATPostingSetup);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");
        VATPostingSetup.TestField("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPostingSetupNormalWithNoTaxableTypeChangeToFullVAT()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 466990] Error when change VAT Calculation Type from Normal to Full VAT when we have posted VAT Entries
        LibraryLowerPermissions.SetO365Full();
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        MockNormalNoTaxableVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code);
        MockVATEntry(VATPostingSetup);
        asserterror VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Full VAT");
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('You cannot change the VAT posting setup');
    end;

    local procedure CreateGLAccountNoTaxableSale(): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"No Taxable VAT", 0);
        exit(
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
    end;

    local procedure CreateGLAccountNoTaxablePurch(): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"No Taxable VAT", 0);
        exit(
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
    end;

    local procedure CreatePostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; Sign: Integer)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, DocumentType, AccountType, AccountNo, Sign * LibraryRandom.RandDecInRange(100, 200, 2));
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePurchaseDocumentWithNoTaxableVAT(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup, 1);
        PurchaseLine.Validate(
          "VAT Prod. Posting Group", LibrarySII.CreateSpecificNoTaxableVATSetup(PurchaseHeader."VAT Bus. Posting Group", false, 0));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure DeleteCVLedgerEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        CustLedgerEntry.DeleteAll();
        VendorLedgerEntry.DeleteAll();
    end;

    local procedure DeleteNoTaxableEntries()
    var
        NoTaxableEntry: Record "No Taxable Entry";
    begin
        NoTaxableEntry.DeleteAll();
    end;

    local procedure MockNormalNoTaxableVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGr: Code[20])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGr, VATProductPostingGroup.Code);
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Normal VAT";
        VATPostingSetup."VAT %" := 0;
        VATPostingSetup."No Taxable Type" := VATPostingSetup."No Taxable Type"::"Non Taxable Due To Localization Rules";
        VATPostingSetup.Modify();
    end;

    local procedure MockVATEntry(VATPostingSetup: Record "VAT Posting Setup")
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATEntry."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATEntry.Insert();
    end;

    local procedure ResetNoTaxableTypeVATEntries(VATBusPostGroupCode: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("VAT Bus. Posting Group", VATBusPostGroupCode);
        VATEntry.ModifyAll("No Taxable Type", 0);
    end;

    local procedure VerifySalesNoTaxableEntries(CustLedgerEntry: Record "Cust. Ledger Entry"; ExpectedAmount: Decimal; ExpectedAmountLCY: Decimal)
    var
        NoTaxableEntry: Record "No Taxable Entry";
    begin
        NoTaxableEntry.FilterNoTaxableEntry(
          NoTaxableEntry.Type::Sale.AsInteger(), CustLedgerEntry."Customer No.",
          CustLedgerEntry."Document Type".AsInteger(), CustLedgerEntry."Document No.", CustLedgerEntry."Posting Date", false);
        NoTaxableEntry.FindFirst();
        NoTaxableEntry.TestField(Amount, ExpectedAmount);
        NoTaxableEntry.TestField("Amount (LCY)", ExpectedAmountLCY);
    end;

    local procedure VerifyPurchNoTaxableEntries(VendorLedgerEntry: Record "Vendor Ledger Entry"; ExpectedAmount: Decimal; ExpectedAmountLCY: Decimal)
    var
        NoTaxableEntry: Record "No Taxable Entry";
    begin
        NoTaxableEntry.FilterNoTaxableEntry(
          NoTaxableEntry.Type::Purchase.AsInteger(), VendorLedgerEntry."Vendor No.",
          VendorLedgerEntry."Document Type".AsInteger(), VendorLedgerEntry."Document No.", VendorLedgerEntry."Posting Date", false);
        NoTaxableEntry.FindFirst();
        NoTaxableEntry.TestField(Amount, ExpectedAmount);
        NoTaxableEntry.TestField("Amount (LCY)", ExpectedAmountLCY);
    end;

    local procedure VerifyReversedSalesNoTaxableEntries(CustLedgerEntry: Record "Cust. Ledger Entry"; ExpectedAmount: Decimal; ExpectedAmountLCY: Decimal)
    var
        NoTaxableEntry: Record "No Taxable Entry";
    begin
        NoTaxableEntry.FilterNoTaxableEntry(
          NoTaxableEntry.Type::Sale.AsInteger(), CustLedgerEntry."Customer No.",
          CustLedgerEntry."Document Type".AsInteger(), CustLedgerEntry."Document No.", CustLedgerEntry."Posting Date", true);

        Assert.RecordCount(NoTaxableEntry, 2);
        NoTaxableEntry.FindFirst();
        NoTaxableEntry.TestField(Amount, ExpectedAmount);
        NoTaxableEntry.TestField("Amount (LCY)", ExpectedAmountLCY);

        NoTaxableEntry.FindLast();
        NoTaxableEntry.TestField(Amount, -ExpectedAmount);
        NoTaxableEntry.TestField("Amount (LCY)", -ExpectedAmountLCY);
    end;

    local procedure VerifyReversedPurchNoTaxableEntries(VendorLedgerEntry: Record "Vendor Ledger Entry"; ExpectedAmount: Decimal; ExpectedAmountLCY: Decimal)
    var
        NoTaxableEntry: Record "No Taxable Entry";
    begin
        NoTaxableEntry.FilterNoTaxableEntry(
          NoTaxableEntry.Type::Purchase.AsInteger(), VendorLedgerEntry."Vendor No.",
          VendorLedgerEntry."Document Type".AsInteger(), VendorLedgerEntry."Document No.", VendorLedgerEntry."Posting Date", true);
        VerifyReversedAmounts(NoTaxableEntry, ExpectedAmount, ExpectedAmountLCY);
    end;

    local procedure VerifyReversedAmounts(var NoTaxableEntry: Record "No Taxable Entry"; ExpectedAmount: Decimal; ExpectedAmountLCY: Decimal)
    begin
        Assert.RecordCount(NoTaxableEntry, 2);
        NoTaxableEntry.FindFirst();
        NoTaxableEntry.TestField(Amount, ExpectedAmount);
        NoTaxableEntry.TestField("Amount (LCY)", ExpectedAmountLCY);
        NoTaxableEntry.FindLast();
        NoTaxableEntry.TestField(Amount, -ExpectedAmount);
        NoTaxableEntry.TestField("Amount (LCY)", -ExpectedAmountLCY);
    end;

    local procedure VerifyNoTaxableTypeVATEntries(VATPostingSetup: Record "VAT Posting Setup")
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATEntry.FindFirst();
        VATEntry.TestField("No Taxable Type", VATPostingSetup."No Taxable Type");
    end;

    local procedure VerifyNoTaxableEntriesNotCreated(VATPostingSetup: Record "VAT Posting Setup")
    var
        NoTaxableEntry: Record "No Taxable Entry";
    begin
        NoTaxableEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        NoTaxableEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Assert.RecordIsEmpty(NoTaxableEntry);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

