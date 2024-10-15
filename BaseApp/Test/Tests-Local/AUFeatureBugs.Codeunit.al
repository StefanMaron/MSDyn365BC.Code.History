codeunit 145403 "AU Feature Bugs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryAPACLocalization: Codeunit "Library - APAC Localization";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        AmountMustBeZeroMsg: Label 'Amount must be zero.';

    [Test]
    [Scope('OnPrem')]
    procedure PaymentAppliedToPurchaseInvoiceWithWHT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [WHT]
        // [SCENARIO] Payment Journal is posted successfully when applied to Invoice with WHT.

        // [GIVEN] Create and post Purchase Invoice and apply Payment to it.
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(true, true, true, true);  // Using TRUE for EnableTaxInvoices,EnableWHT,PrintTaxInvoicesOnPosting,UnrealizedVAT.
        FindAndUpdateVATPostingSetup(VATPostingSetup);
        DocumentNo := CreateAndPostPurchaseInvoice(VATPostingSetup);
        CreateAndApplyPaymentToPurchaseInvoice(GenJournalLine, DocumentNo);

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify that Payment is fully applied to Invoice.
        VerifyVendorLedgerEntry(GenJournalLine."Account No.");

        // Tear Down: Roll back VAT Posting Setup and General Ledger Setup.
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."Unrealized VAT Type");
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Enable Tax Invoices", GeneralLedgerSetup."Enable WHT", GeneralLedgerSetup."Print Tax Invoices on Posting",
          GeneralLedgerSetup."Unrealized VAT");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostGeneralJnlLineAndReverseEntryWithGST()
    var
        DocumentNo: Code[20];
    begin
        // [FEATURE] [GST] [Purchase] [Reverse]
        // [SCENARIO] reversed GST Purchase Entry gets created.

        // [GIVEN] Create and Post General Journal Line, Reverse them and Check GST Purchase Entry.
        DocumentNo := CreateAndPostGeneralJournalLine;

        // Exercise: Reverse Posted Entry.
        ReverseEntry;

        // [THEN] Verify that reversed GST Purchase Entry gets created.
        VerifyGSTPurchaseEntry(DocumentNo);
    end;

    local procedure CreateAndPostGeneralJournalLine(): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
    begin
        CreateVATPostingSetup(VATPostingSetup);
        LibraryPurchase.CreateVendor(Vendor);
        CreateGeneralJournalBatch(GenJournalBatch);
        with GenJournalLine do begin
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, "Document Type"::Invoice,
              "Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithVATPostingSetup(
                VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase), LibraryRandom.RandInt(100));
            Validate("Bal. Account Type", "Bal. Account Type"::Vendor);
            Validate("Bal. Account No.", Vendor."No.");
            Modify(true);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
            exit("Document No.");
        end;
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(10));
        VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure ReverseEntry()
    var
        ReversalEntry: Record "Reversal Entry";
        GLRegister: Record "G/L Register";
    begin
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegister."No.");
    end;

    local procedure CreateAndApplyPaymentToPurchaseInvoice(var GenJournalLine: Record "Gen. Journal Line"; AppliesToDocNo: Code[20])
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(AppliesToDocNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        LibraryERM.CreateBankAccount(BankAccount);
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, PurchInvHeader."Buy-from Vendor No.", PurchInvHeader."Amount Including VAT");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostPurchaseInvoice(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        CreateWHTPostingSetup(WHTPostingSetup);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(VATPostingSetup."VAT Bus. Posting Group",
            WHTPostingSetup."WHT Business Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group",
            WHTPostingSetup."WHT Product Posting Group"), LibraryRandom.RandDec(10, 2));  // Using random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));  // Post as Receive and Invoice.
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGLAccount(VATProdPostingGroup: Code[20]; WHTProductPostingGroup: Code[20]): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Validate("WHT Product Posting Group", WHTProductPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]; WHTBusinessPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(ABN, '');  // As required by the test case using ABN as blank.
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Validate("WHT Business Posting Group", WHTBusinessPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateWHTPostingSetup(var WHTPostingSetup: Record "WHT Posting Setup")
    var
        GLAccount: Record "G/L Account";
        WHTBusinessPostingGroup: Record "WHT Business Posting Group";
        WHTProductPostingGroup: Record "WHT Product Posting Group";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryAPACLocalization.CreateWHTBusinessPostingGroup(WHTBusinessPostingGroup);
        LibraryAPACLocalization.CreateWHTProductPostingGroup(WHTProductPostingGroup);
        LibraryAPACLocalization.CreateWHTPostingSetup(WHTPostingSetup, WHTBusinessPostingGroup.Code, WHTProductPostingGroup.Code);
        WHTPostingSetup.Validate("WHT %", LibraryRandom.RandDec(10, 2));
        WHTPostingSetup.Validate("WHT Minimum Invoice Amount", LibraryRandom.RandDec(1000, 2));
        WHTPostingSetup.Validate("Realized WHT Type", WHTPostingSetup."Realized WHT Type"::Payment);
        WHTPostingSetup.Validate("Prepaid WHT Account Code", GLAccount."No.");
        WHTPostingSetup.Validate("Payable WHT Account Code", GLAccount."No.");
        WHTPostingSetup.Validate("Purch. WHT Adj. Account No.", GLAccount."No.");
        WHTPostingSetup.Validate("Sales WHT Adj. Account No.", GLAccount."No.");
        WHTPostingSetup.Modify(true);
    end;

    local procedure FindAndUpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
          VATPostingSetup."Unrealized VAT Type"::Percentage);
    end;

    local procedure UpdateGeneralLedgerSetup(EnableTaxInvoices: Boolean; EnableWHT: Boolean; PrintTaxInvoicesOnPosting: Boolean; UnrealizedVAT: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Enable Tax Invoices", EnableTaxInvoices);
        GeneralLedgerSetup.Validate("Enable WHT", EnableWHT);
        GeneralLedgerSetup.Validate("Print Tax Invoices on Posting", PrintTaxInvoicesOnPosting);
        GeneralLedgerSetup.Validate("Unrealized VAT", UnrealizedVAT);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateVATPostingSetup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; UnrealizedVATType: Option)
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        VATPostingSetup.Validate("Unrealized VAT Type", UnrealizedVATType);
        VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", GLAccount."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure VerifyVendorLedgerEntry(VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.TestField(Open, false);
        VendorLedgerEntry.TestField("Remaining Amount", 0);
    end;

    local procedure VerifyGSTPurchaseEntry(DocumentNo: Code[20])
    var
        GSTPurchaseEntry: Record "GST Purchase Entry";
    begin
        with GSTPurchaseEntry do begin
            SetRange("Document No.", DocumentNo);
            SetRange("Document Type", "Document Type"::Invoice);
            FindFirst();
            CalcSums(Amount);
            Assert.AreEqual(Amount, 0, AmountMustBeZeroMsg);
        end;
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
        // Message Handler.
    end;
}

