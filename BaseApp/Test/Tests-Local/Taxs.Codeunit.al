codeunit 144200 Taxs
{
    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTax: Codeunit "Library - Tax";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        BankAccountMustBePublicErr: Label 'Bank Account No. %1 must be public.', Comment = '%1=Bank Account No.';
        BankAccountCanNotBePublicErr: Label 'Bank Account No. %1 can''t be public.', Comment = '%1=Bank Account No.';

    local procedure Initialize()
    begin
        LibraryRandom.SetSeed(1);  // Use Random Number Generator to generate the seed for RANDOM function.
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        UpdateSalesSetup;
        UpdateCompanyInformation;
        LibraryTax.CreateElectronicallyGovernSetup;
        LibraryTax.SetUncertaintyPayerWebService;

        isInitialized := true;
        Commit;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NondeductibleVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VATEntry: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        NonDeductibleVATSetup: Record "Non Deductible VAT Setup";
        PostedDocNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // 1.Setup:
        Initialize;

        CreateVATPostingSetup(VATPostingSetup, 10);
        CreateNonDeductibleVATSetup(
          NonDeductibleVATSetup,
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
          CalcDate('<-CY>', WorkDate), 10);

        CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        CreateGLAccount(GLAccount);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);

        CreatePurchaseInvoice(
          PurchHeader, PurchLine,
          Vendor."No.", PurchLine.Type::"G/L Account", GLAccount."No.");

        // 2.Exercise:

        PostedDocNo := PostPurchaseDocument(PurchHeader);

        // 3.Verify:

        PurchInvHeader.Get(PostedDocNo);

        VATAmount :=
          LibraryTax.RoundVAT(
            PurchLine.Amount * VATPostingSetup."VAT %" / 100 * (100 - NonDeductibleVATSetup."Non Deductible VAT %") / 100);
        VATBase := LibraryTax.RoundVAT(PurchLine.Amount + PurchLine.Amount * VATPostingSetup."VAT %" / 100 - VATAmount);

        VATEntry.SetCurrentKey("Document No.", "Posting Date");
        VATEntry.SetRange("Document No.", PurchInvHeader."No.");
        VATEntry.SetRange("Posting Date", PurchInvHeader."Posting Date");
        VATEntry.FindFirst;
        VATEntry.TestField(Base, VATBase);
        VATEntry.TestField(Amount, VATAmount);

        GLEntry.SetCurrentKey("Document No.", "Posting Date");
        GLEntry.SetRange("Document No.", PurchInvHeader."No.");
        GLEntry.SetRange("Posting Date", PurchInvHeader."Posting Date");
        GLEntry.FindSet;
        GLEntry.TestField("G/L Account No.", PurchLine."No.");
        GLEntry.TestField(Amount, VATBase);

        GLEntry.Next;
        GLEntry.TestField("G/L Account No.", VATPostingSetup."Purchase VAT Account");
        GLEntry.TestField(Amount, VATAmount);
    end;

    [Test]
    [HandlerFunctions('ModalChangeExchangeRateHandler')]
    [Scope('OnPrem')]
    procedure ExchangeRateForVAT()
    var
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        PurchHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        PurchaseInvoice: TestPage "Purchase Invoice";
        DocumentNo: Code[20];
        PostedDocumentNo: Code[20];
        VATAmount: Decimal;
        AmountExclVAT: Decimal;
        AmountInclVAT: Decimal;
    begin
        // 1.Setup:
        Initialize;

        UpdateSourceCodeSetup;

        CreateVATPostingSetup(VATPostingSetup, 25);
        VATPostingSetup.Validate("Purchase VAT Delay Account", GetNewGLAccountNo);
        VATPostingSetup.Modify(true);

        CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        CreateGLAccount(GLAccount);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);

        Currency.Get(CreateCurrencyCode);

        PurchaseInvoice.OpenNew;
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);
        PurchaseInvoice."Vendor Invoice No.".SetValue(PurchaseInvoice."No.".Value);
        PurchaseInvoice."Currency Code".SetValue(Currency.Code);
        PurchaseInvoice.Close;
        PurchaseInvoice.OpenEdit;
        PurchaseInvoice.FILTER.SetFilter("No.", PurchaseInvoice."No.".Value);
        LibraryVariableStorage.Enqueue(0.5);
        PurchaseInvoice."Currency Code".AssistEdit;
        LibraryVariableStorage.Enqueue(0.6);
        PurchaseInvoice.VATCurrencyCode.AssistEdit;

        PurchaseInvoice.PurchLines.Last;
        PurchaseInvoice.PurchLines.Next;
        PurchaseInvoice.PurchLines.Type.SetValue(1); // G/L Account
        PurchaseInvoice.PurchLines."No.".SetValue(GLAccount."No.");
        PurchaseInvoice.PurchLines.Quantity.SetValue(1);
        PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandInt(1000));
        PurchaseInvoice.PurchLines.Next;

        DocumentNo := PurchaseInvoice."No.".Value;
        Evaluate(VATAmount, PurchaseInvoice.PurchLines."Total VAT Amount".Value);
        Evaluate(AmountExclVAT, PurchaseInvoice.PurchLines."Total Amount Excl. VAT".Value);
        Evaluate(AmountInclVAT, PurchaseInvoice.PurchLines."Total Amount Incl. VAT".Value);

        PurchHeader.Get(PurchHeader."Document Type"::Invoice, DocumentNo);

        // 2.Exercise:

        PostedDocumentNo := PostPurchaseDocument(PurchHeader);

        // 3.Verify:

        GLEntry.Reset;
        GLEntry.SetRange("G/L Account No.", VATPostingSetup."Purchase VAT Account");
        GLEntry.SetRange("Posting Date", WorkDate);
        if GLEntry.FindLast then;
        GLEntry.TestField(Amount, 0.6 * VATAmount);

        GLEntry.SetRange("G/L Account No.", Currency."Realized Gains Acc.");
        if GLEntry.FindLast then;
        GLEntry.TestField(Amount, 0.5 * VATAmount - 0.6 * VATAmount);

        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        GLEntry.SetRange("G/L Account No.", VendorPostingGroup."Payables Account");
        if GLEntry.FindLast then;
        GLEntry.TestField(Amount, -0.5 * AmountInclVAT);

        VATEntry.Reset;
        VATEntry.SetRange("Document No.", PostedDocumentNo);
        VATEntry.SetRange("Posting Date", WorkDate);
        if VATEntry.FindLast then;
        VATEntry.TestField(Base, 0.6 * AmountExclVAT);
        VATEntry.TestField(Amount, 0.6 * VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    [Obsolete('The functionality of Postponing VAT on Sales Cr.Memo will be removed and this function should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
    procedure PostingSalesCrMemoWithPostponedVAT()
    var
        GLEntry: Record "G/L Entry";
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        SalesCrMemoLn: Record "Sales Cr.Memo Line";
        SalesHdr: Record "Sales Header";
        SalesLn: Record "Sales Line";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        PostedDocNo: Code[20];
    begin
        // 1. Setup:
        Initialize;

        CreateSalesCrMemoWithVATPostingSetup(SalesHdr, SalesLn, VATPostingSetup);

        // 2. Exercise:

        PostedDocNo := PostSalesDocument(SalesHdr);

        // 3. Verify:

        SalesCrMemoHdr.Get(PostedDocNo);
        SalesCrMemoHdr.TestField("Postponed VAT", true);
        SalesCrMemoLn.CalcVATAmountLines(SalesCrMemoHdr, TempVATAmountLine);

        VATEntry.SetCurrentKey("Document No.", "Posting Date");
        VATEntry.SetRange("Document No.", SalesCrMemoHdr."No.");
        VATEntry.SetRange("Posting Date", SalesCrMemoHdr."Posting Date");
        VATEntry.FindFirst;
        VATEntry.TestField("Postponed VAT", true);
        VATEntry.TestField(Base, 0);
        VATEntry.TestField(Amount, 0);
        VATEntry.TestField("Unrealized Base", TempVATAmountLine."VAT Base");
        VATEntry.TestField("Unrealized Amount", TempVATAmountLine."VAT Amount");

        GLEntry.SetCurrentKey("Document No.", "Posting Date");
        GLEntry.SetRange("Document No.", SalesCrMemoHdr."No.");
        GLEntry.SetRange("Posting Date", SalesCrMemoHdr."Posting Date");
        GLEntry.FindSet;
        GLEntry.TestField("G/L Account No.", SalesLn."No.");
        GLEntry.TestField(Amount, TempVATAmountLine."VAT Base");

        GLEntry.Next;
        GLEntry.TestField("G/L Account No.", VATPostingSetup."Sales VAT Postponed Account");
        GLEntry.TestField(Amount, TempVATAmountLine."VAT Amount");
    end;

    [Test]
    [HandlerFunctions('RequestPagePostOrCorrectPostponedVATHandler,YesConfirm,MessageHandler')]
    [Scope('OnPrem')]
    [Obsolete('The functionality of Postponing VAT on Sales Cr.Memo will be removed and this function should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
    procedure ConfirmationVATForSalesCrMemo()
    var
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        SalesCrMemoLn: Record "Sales Cr.Memo Line";
        VATPostingSetup: Record "VAT Posting Setup";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        NewDate: Date;
    begin
        // 1. Setup:
        Initialize;

        SetupConfirmationVAT(VATPostingSetup, SalesCrMemoHdr, NewDate);

        // 2. Exercise:
        PostOrCorrectPostponedVAT(SalesCrMemoHdr);

        // 3. Verify:
        CheckSalesCrMemo(SalesCrMemoHdr."No.", false, true, NewDate);

        SalesCrMemoLn.CalcVATAmountLines(SalesCrMemoHdr, TempVATAmountLine);

        TempVATAmountLine."VAT Amount" := -TempVATAmountLine."VAT Amount";
        TempVATAmountLine."VAT Base" := -TempVATAmountLine."VAT Base";
        CheckGLEntries(SalesCrMemoHdr."No.", NewDate, VATPostingSetup, TempVATAmountLine);
        CheckVATEntries(SalesCrMemoHdr."No.", NewDate, TempVATAmountLine);
    end;

    [Test]
    [HandlerFunctions('RequestPagePostOrCorrectPostponedVATHandler,YesConfirm,MessageHandler')]
    [Scope('OnPrem')]
    [Obsolete('The functionality of Postponing VAT on Sales Cr.Memo will be removed and this function should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
    procedure StornoConfirmationVATForSalesCrMemo()
    var
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        SalesCrMemoLn: Record "Sales Cr.Memo Line";
        VATPostingSetup: Record "VAT Posting Setup";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        NewDate: Date;
    begin
        // 1. Setup:
        Initialize;

        SetupConfirmationVAT(VATPostingSetup, SalesCrMemoHdr, NewDate);
        PostOrCorrectPostponedVAT(SalesCrMemoHdr);

        // 2. Exercise
        // storno
        LibraryVariableStorage.Enqueue(NewDate);
        LibraryVariableStorage.Enqueue(true);
        PostOrCorrectPostponedVAT(SalesCrMemoHdr);

        // 3. Verify:
        CheckSalesCrMemo(SalesCrMemoHdr."No.", true, false, NewDate);

        SalesCrMemoLn.CalcVATAmountLines(SalesCrMemoHdr, TempVATAmountLine);

        CheckGLEntries(SalesCrMemoHdr."No.", NewDate, VATPostingSetup, TempVATAmountLine);
        CheckVATEntries(SalesCrMemoHdr."No.", NewDate, TempVATAmountLine);
    end;

    [Test]
    [HandlerFunctions('RequestPagePostOrCorrectPostponedVATHandler,YesConfirm,MessageHandler')]
    [Scope('OnPrem')]
    [Obsolete('The functionality of Postponing VAT on Sales Cr.Memo will be removed and this function should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
    procedure CorrectionDateConfirmationVATForSalesCrMemo()
    var
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        SalesCrMemoLn: Record "Sales Cr.Memo Line";
        VATPostingSetup: Record "VAT Posting Setup";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        NewDate: Date;
    begin
        // 1. Setup:
        Initialize;

        SetupConfirmationVAT(VATPostingSetup, SalesCrMemoHdr, NewDate);
        PostOrCorrectPostponedVAT(SalesCrMemoHdr);

        // storno
        LibraryVariableStorage.Enqueue(NewDate);
        LibraryVariableStorage.Enqueue(true);
        PostOrCorrectPostponedVAT(SalesCrMemoHdr);

        // 2. Exercise
        // correction new date
        NewDate := CalcDate('<+10D>', SalesCrMemoHdr."Posting Date");
        LibraryVariableStorage.Enqueue(NewDate);
        LibraryVariableStorage.Enqueue(false);
        PostOrCorrectPostponedVAT(SalesCrMemoHdr);

        // 3. Verify:
        CheckSalesCrMemo(SalesCrMemoHdr."No.", false, true, NewDate);

        SalesCrMemoLn.CalcVATAmountLines(SalesCrMemoHdr, TempVATAmountLine);

        TempVATAmountLine."VAT Amount" := -TempVATAmountLine."VAT Amount";
        TempVATAmountLine."VAT Base" := -TempVATAmountLine."VAT Base";
        CheckGLEntries(SalesCrMemoHdr."No.", NewDate, VATPostingSetup, TempVATAmountLine);
        CheckVATEntries(SalesCrMemoHdr."No.", NewDate, TempVATAmountLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckingVendorCard()
    var
        Vendor: Record Vendor;
        VendorBankAccountPublic: Record "Vendor Bank Account";
        VendorBankAccountNotPublic: Record "Vendor Bank Account";
        UncPayerMgt: Codeunit "Unc. Payer Mgt.";
    begin
        // 1. Setup
        Initialize;

        CreateVendor(Vendor);
        Vendor.Validate("VAT Registration No.", LibraryTax.GetValidVATRegistrationNo);
        Vendor.Modify;

        LibraryPurchase.CreateVendorBankAccount(VendorBankAccountPublic, Vendor."No.");
        VendorBankAccountPublic."Bank Account No." := LibraryTax.GetPublicBankAccountNo;
        VendorBankAccountPublic.Modify;

        LibraryPurchase.CreateVendorBankAccount(VendorBankAccountNotPublic, Vendor."No.");
        VendorBankAccountNotPublic."Bank Account No." := LibraryTax.GetNotPublicBankAccountNo;
        VendorBankAccountNotPublic.Modify;

        // 2. Exercise
        LibraryTax.RunUncertaintyVATPayment(Vendor);

        // 3. Verify
        Vendor.Get(Vendor."No.");
        Vendor.CalcFields("Last Uncertainty Check Date", "VAT Uncertainty Payer");
        Vendor.TestField("Last Uncertainty Check Date", Today);
        Vendor.TestField("VAT Uncertainty Payer", Vendor."VAT Uncertainty Payer"::NO);

        Assert.IsTrue(
          UncPayerMgt.IsPublicBankAccount(
            Vendor."No.", Vendor."VAT Registration No.",
            VendorBankAccountPublic."Bank Account No.", VendorBankAccountPublic.IBAN),
          StrSubstNo(BankAccountMustBePublicErr, VendorBankAccountPublic."Bank Account No."));

        Assert.IsFalse(
          UncPayerMgt.IsPublicBankAccount(
            Vendor."No.", Vendor."VAT Registration No.",
            VendorBankAccountNotPublic."Bank Account No.", VendorBankAccountNotPublic.IBAN),
          StrSubstNo(BankAccountCanNotBePublicErr, VendorBankAccountNotPublic."Bank Account No."));
    end;

    [Test]
    [HandlerFunctions('RequestPageMassUncertaintyPayerGetHandler,YesConfirm,MessageHandler')]
    [Scope('OnPrem')]
    procedure MassCheckingVendorCards()
    var
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
    begin
        // 1. Setup
        Initialize;

        CreateVendor(Vendor1);
        Vendor1.Validate("VAT Registration No.", LibraryTax.GetValidVATRegistrationNo);
        Vendor1.Modify;

        CreateVendor(Vendor2);
        Vendor2.Validate("VAT Registration No.", LibraryTax.GetInvalidVATRegistrationNo);
        Vendor2.Modify;

        // 2. Exercise
        LibraryTax.RunMassUncertaintyPayerGet;

        // 3. Verify
        Vendor1.Get(Vendor1."No.");
        Vendor1.CalcFields("Last Uncertainty Check Date", "VAT Uncertainty Payer");
        Vendor1.TestField("Last Uncertainty Check Date", Today);
        Vendor1.TestField("VAT Uncertainty Payer", Vendor1."VAT Uncertainty Payer"::NO);

        Vendor2.Get(Vendor2."No.");
        Vendor2.CalcFields("Last Uncertainty Check Date", "VAT Uncertainty Payer");
        Vendor2.TestField("Last Uncertainty Check Date", Today);
        Vendor2.TestField("VAT Uncertainty Payer", Vendor2."VAT Uncertainty Payer"::NOTFOUND);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,YesConfirm')]
    [Scope('OnPrem')]
    procedure PostingOnNotPublicBankAccount()
    begin
        PostingOnBankAccount(false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostingOnPublicBankAccount()
    begin
        PostingOnBankAccount(true);
    end;

    local procedure PostingOnBankAccount(IsPublic: Boolean)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        PostedDocumentNo: Code[20];
    begin
        // 1. Setup
        Initialize;

        CreateVendor(Vendor);
        Vendor.Validate("VAT Registration No.", LibraryTax.GetValidVATRegistrationNo);
        Vendor.Modify;

        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");

        if IsPublic then
            VendorBankAccount."Bank Account No." := LibraryTax.GetPublicBankAccountNo
        else
            VendorBankAccount."Bank Account No." := LibraryTax.GetNotPublicBankAccountNo;

        VendorBankAccount.Modify;

        LibraryTax.RunUncertaintyVATPayment(Vendor);

        CreatePurchaseInvoice(
          PurchHeader, PurchLine, Vendor."No.", PurchLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup);
        PurchHeader.Validate("Bank Account Code", VendorBankAccount.Code);
        PurchHeader.Modify;

        // 2. Exercise
        PostedDocumentNo := PostPurchaseDocument(PurchHeader);

        // 3. Verify
        PurchInvHeader.Get(PostedDocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    [Obsolete('The functionality of VAT Registration in Other Countries will be removed and this function should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
    procedure VATRegistrationInMultipleCountriesSales()
    var
        Customer: Record Customer;
        RegistrationCountryRegion: Record "Registration Country/Region";
        SalesHdr: Record "Sales Header";
        SalesLn: Record "Sales Line";
    begin
        // 1 .Setup
        Initialize;

        CreateCustomer(Customer);
        CreateRegistrationCountry(
          RegistrationCountryRegion, RegistrationCountryRegion."Account Type"::Customer, Customer."No.");

        CreateSalesDocument(
          SalesHdr, SalesLn, SalesHdr."Document Type"::Order, Customer."No.", SalesLn.Type::"G/L Account", '');

        // 2. Exercise
        SalesHdr.Validate("VAT Country/Region Code", RegistrationCountryRegion."Country/Region Code");

        // 3. Verify
        SalesHdr.TestField("VAT Registration No.", RegistrationCountryRegion."VAT Registration No.");
        SalesHdr.TestField("VAT Bus. Posting Group", RegistrationCountryRegion."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    [Obsolete('The functionality of VAT Registration in Other Countries will be removed and this function should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
    procedure VATRegistrationInMultipleCountriesPurchase()
    var
        Vendor: Record Vendor;
        RegistrationCountryRegion: Record "Registration Country/Region";
        PurchHdr: Record "Purchase Header";
        PurchLn: Record "Purchase Line";
    begin
        // 1 .Setup
        Initialize;

        CreateVendor(Vendor);
        CreateRegistrationCountry(
          RegistrationCountryRegion, RegistrationCountryRegion."Account Type"::Vendor, Vendor."No.");

        CreatePurchaseDocument(
          PurchHdr, PurchLn, PurchHdr."Document Type"::Order, Vendor."No.", PurchLn.Type::"G/L Account", '');

        // 2. Exercise
        PurchHdr.Validate("VAT Country/Region Code", RegistrationCountryRegion."Country/Region Code");

        // 3. Verify
        PurchHdr.TestField("VAT Registration No.", RegistrationCountryRegion."VAT Registration No.");
        PurchHdr.TestField("VAT Bus. Posting Group", RegistrationCountryRegion."VAT Bus. Posting Group");
    end;

    local procedure CreateCurrencyCode(): Code[10]
    var
        CurrencyCode: Code[10];
    begin
        CurrencyCode := LibraryERM.CreateCurrencyWithGLAccountSetup;
        LibraryERM.CreateExchangeRate(
          CurrencyCode, LibraryERM.FindEarliestDateForExhRate, 1, 1);
        exit(CurrencyCode);
    end;

    local procedure CreateCustomer(var Cust: Record Customer)
    begin
        LibrarySales.CreateCustomer(Cust);
    end;

    local procedure CreateCustomerWithVATPostingSetup(var Cust: Record Customer; VATPostingSetup: Record "VAT Posting Setup")
    begin
        CreateCustomer(Cust);
        Cust.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Cust.Modify(true);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure CreateGLAccountWithVATPostingSetup(var GLAcc: Record "G/L Account"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        CreateGLAccount(GLAcc);
        GLAcc.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAcc.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAcc.Modify(true);
    end;

    local procedure CreateNonDeductibleVATSetup(var NonDeductibleVATSetup: Record "Non Deductible VAT Setup"; VATBusPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20]; FromDate: Date; NonDeductibleVATPer: Decimal)
    begin
        LibraryTax.CreateNonDeductibleVATSetup(
          NonDeductibleVATSetup, VATBusPostingGroupCode, VATProdPostingGroupCode, FromDate, NonDeductibleVATPer)
    end;

    local procedure CreatePurchaseDocument(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocumentType: Option; VendorNo: Code[20]; LineType: Option; LineNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocumentType, VendorNo);
        PurchHeader.Validate("Vendor Invoice No.", PurchHeader."No.");
        PurchHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, LineType, LineNo, 1);
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchLine.Modify(true);
    end;

    local procedure CreatePurchaseInvoice(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; VendorNo: Code[20]; LineType: Option; LineNo: Code[20])
    begin
        CreatePurchaseDocument(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, VendorNo, LineType, LineNo);
    end;

    [Obsolete('The functionality of VAT Registration in Other Countries will be removed and this function should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
    local procedure CreateRegistrationCountry(var RegistrationCountryRegion: Record "Registration Country/Region"; AccountType: Option; AccountNo: Code[20])
    var
        CountryRegion: Record "Country/Region";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.FindCountryRegion(CountryRegion);
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);

        RegistrationCountryRegion.Init;
        RegistrationCountryRegion."Account Type" := AccountType;
        RegistrationCountryRegion."Account No." := AccountNo;
        RegistrationCountryRegion."Country/Region Code" := CountryRegion.Code;
        RegistrationCountryRegion."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CountryRegion.Code);
        RegistrationCountryRegion."VAT Bus. Posting Group" := VATBusinessPostingGroup.Code;
        RegistrationCountryRegion.Insert(true);
    end;

    local procedure CreateSalesDocument(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line"; DocumentType: Option; CustomerNo: Code[20]; LineType: Option; LineNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHdr, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLn, SalesHdr, LineType, LineNo, 1);
        SalesLn.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLn.Modify(true);
    end;

    local procedure CreateSalesCrMemo(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line"; CustomerNo: Code[20]; LineType: Option; LineNo: Code[20])
    begin
        CreateSalesDocument(SalesHdr, SalesLn, SalesHdr."Document Type"::"Credit Memo", CustomerNo, LineType, LineNo);
    end;

    local procedure CreateSalesCrMemoWithVATPostingSetup(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line"; var VATPostingSetup: Record "VAT Posting Setup")
    var
        Cust: Record Customer;
        GLAcc: Record "G/L Account";
    begin
        CreateVATPostingSetup(VATPostingSetup, 25);
        CreateCustomerWithVATPostingSetup(Cust, VATPostingSetup);
        CreateGLAccountWithVATPostingSetup(GLAcc, VATPostingSetup);

        CreateSalesCrMemo(SalesHdr, SalesLn, Cust."No.", SalesLn.Type::"G/L Account", GLAcc."No.");
    end;

    local procedure CreateVATBusinessPostingGroup(var VATBusinessPostingGroup: Record "VAT Business Posting Group")
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup)
    end;

    local procedure CreateVATProductPostingGroup(var VATProductPostingGroup: Record "VAT Product Posting Group")
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATPer: Decimal)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        CreateVATProductPostingGroup(VATProductPostingGroup);

        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", VATPer);
        VATPostingSetup.Validate("VAT Identifier", Format(VATPostingSetup."VAT %"));
        VATPostingSetup.Validate("Non Deduct. VAT Corr. Account", GetNewGLAccountNo);
        VATPostingSetup.Validate("Purchase VAT Account", GetNewGLAccountNo);
        VATPostingSetup.Validate("Purchase VAT Delay Account", GetNewGLAccountNo);
        VATPostingSetup.Validate("Sales VAT Account", GetNewGLAccountNo);
        VATPostingSetup.Validate("Sales VAT Postponed Account", GetNewGLAccountNo);
        VATPostingSetup.Validate("Allow Non Deductible VAT", true);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVendor(var Vend: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vend);
    end;

    local procedure GetNewGLAccountNo(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CheckGLEntries(DocumentNo: Code[20]; PostingDate: Date; VATPostingSetup: Record "VAT Posting Setup"; VATAmountLine: Record "VAT Amount Line")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Document No.", "Posting Date");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.SetRange("G/L Account No.", VATPostingSetup."Sales VAT Postponed Account");
        GLEntry.FindLast;
        GLEntry.TestField(Amount, VATAmountLine."VAT Amount");

        GLEntry.SetRange("G/L Account No.", VATPostingSetup."Sales VAT Account");
        GLEntry.FindLast;
        GLEntry.TestField(Amount, -VATAmountLine."VAT Amount");
    end;

    local procedure CheckSalesCrMemo(DocumentNo: Code[20]; PostponedVAT: Boolean; PostponedVATRealized: Boolean; VATDate: Date)
    var
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHdr.Get(DocumentNo);
        SalesCrMemoHdr.TestField("Postponed VAT", PostponedVAT);
        SalesCrMemoHdr.TestField("Postponed VAT Realized", PostponedVATRealized);
        SalesCrMemoHdr.TestField("VAT Date", VATDate);
    end;

    local procedure CheckVATEntries(DocumentNo: Code[20]; PostingDate: Date; VATAmountLine: Record "VAT Amount Line")
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey("Document No.", "Posting Date");
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Posting Date", PostingDate);
        VATEntry.FindLast;
        VATEntry.TestField("Postponed VAT", true);
        VATEntry.TestField(Base, -VATAmountLine."VAT Base");
        VATEntry.TestField(Amount, -VATAmountLine."VAT Amount");
        VATEntry.TestField("Unrealized Base", 0);
        VATEntry.TestField("Unrealized Amount", 0);
    end;

    [Obsolete('The functionality of Postponing VAT on Sales Cr.Memo will be removed and this function should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
    local procedure PostOrCorrectPostponedVAT(var SalesCrMemoHdr: Record "Sales Cr.Memo Header")
    begin
        SalesCrMemoHdr.SetRecFilter;
        REPORT.RunModal(REPORT::"Post or Correct Postponed VAT", true, false, SalesCrMemoHdr);
    end;

    local procedure PostPurchaseDocument(var PurchHeader: Record "Purchase Header"): Code[20]
    begin
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure PostSalesDocument(var SalesHeader: Record "Sales Header"): Code[20]
    begin
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure SetupConfirmationVAT(var VATPostingSetup: Record "VAT Posting Setup"; var SalesCrMemoHdr: Record "Sales Cr.Memo Header"; var NewDate: Date)
    var
        SalesHdr: Record "Sales Header";
        SalesLn: Record "Sales Line";
        PostedDocNo: Code[20];
    begin
        CreateSalesCrMemoWithVATPostingSetup(SalesHdr, SalesLn, VATPostingSetup);
        PostedDocNo := PostSalesDocument(SalesHdr);

        SalesCrMemoHdr.Get(PostedDocNo);
        NewDate := CalcDate('<+5D>', SalesCrMemoHdr."Posting Date");
        LibraryVariableStorage.Enqueue(NewDate);
        LibraryVariableStorage.Enqueue(false);
    end;

    local procedure UpdateCompanyInformation()
    var
        CoInfo: Record "Company Information";
    begin
        CoInfo.Get;
        CoInfo."Country/Region Code" := 'CZ';
        CoInfo.Modify;
    end;

    local procedure UpdateSalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup."Credit Memo Confirmation" := true;
        SalesReceivablesSetup.Modify;
    end;

    local procedure UpdateSourceCodeSetup()
    var
        SourceCode: Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        LibraryERM.CreateSourceCode(SourceCode);
        SourceCodeSetup.Get;
        SourceCodeSetup.Validate("Purchase VAT Delay", SourceCode.Code);
        SourceCodeSetup.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalChangeExchangeRateHandler(var ChangeExchangeRate: TestPage "Change Exchange Rate")
    var
        RefExchRate: Variant;
    begin
        LibraryVariableStorage.Dequeue(RefExchRate);
        ChangeExchangeRate.RefExchRate.SetValue(RefExchRate);
        ChangeExchangeRate.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    [Obsolete('The functionality of Postponing VAT on Sales Cr.Memo will be removed and this function should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
    procedure RequestPagePostOrCorrectPostponedVATHandler(var PostOrCorrectPostponedVAT: TestRequestPage "Post or Correct Postponed VAT")
    var
        NewDate: Date;
        Correction: Boolean;
    begin
        NewDate := LibraryVariableStorage.DequeueDate;
        Correction := LibraryVariableStorage.DequeueBoolean;
        PostOrCorrectPostponedVAT.VATDate.SetValue(NewDate);
        PostOrCorrectPostponedVAT.CorrectEntries.SetValue(Correction);
        PostOrCorrectPostponedVAT.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageMassUncertaintyPayerGetHandler(var MassUncertaintyPayerGet: TestRequestPage "Mass Uncertainty Payer Get")
    begin
        MassUncertaintyPayerGet.UpdateOnlyUncertaintyPayers.SetValue(true);
        MassUncertaintyPayerGet.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirm(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler
    end;
}

