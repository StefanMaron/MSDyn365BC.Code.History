codeunit 18682 "TDS On Customer Tests"
{
    Subtype = Test;

    var
        LibraryVarStorage: Codeunit "Library - Variable Storage";
        Section: Code[10];
        TDSAssesseeCode: Code[10];
        TDSConcessionalCode: Code[10];
        TDSEffectiveDate: Date;
        TDSPercentage, NonPANTDSPercentage : Decimal;
        eCessPercentage, SHECessPercentage, SurchargePercentage : Decimal;
        TDSThresholdAmount, SurchargeThresholdAmount : Decimal;
        Storage: Dictionary of [Text, Code[20]];
        StorageEnum: Dictionary of [Text, Text];

    //[Scenario 357190] Check if the progrm is not considering any Threshold limit while calculating TDS amount in different journals
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure GeneralJournalWithTDSOnCustomer()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VoucherType: Enum "Gen. Journal Template Type";
    begin
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create and Post General Journal
        LibraryTDSC.CreateGenJournalLineWithTDSCertificateReceivable(GenJournalLine, Customer."No.", VoucherType::General, TDSPostingSetup."TDS Section");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify TDS Certificate Receivable on customer ledger entry
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange("TDS Certificate Receivable", true);
        CustLedgEntry.FindFirst();
        Assert.RecordIsNotEmpty(CustLedgEntry);
    end;

    //[Scenario 357196] Check if the progrm is not considering any Threshold limit while calculating TDS amount in different journals
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VoucherAccountDebit')]
    procedure BankReceiptVoucherWithTDSOnCustomerAndWithThresholdOverlook()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        BankAccount: Record "Bank Account";
        Location: Record Location;
        TDSPostingSetup: Record "TDS Posting Setup";
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());
        CreateBankAccWithVoucherAccount(AccountType::"Bank Account", VoucherType::"Bank Receipt Voucher", BankAccount, Location);

        // [WHEN] Create and Post Bank Receipt Journal
        LibraryTDSC.CreateGenJournalLineWithTDSCertificateReceivableForBank(GenJournalLine, Customer."No.", BankAccount."No.", VoucherType::"Bank Receipt Voucher", TDSPostingSetup."TDS Section", Location.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify entry TDS receivale account on G/L Entry
        LibraryTDSC.VerifyGLEntryCount(GenJournalLine."Journal Batch Name", 3);
    end;

    //[Scenario 357197] Check if the program is calculating TDS while creating customer Receipt using the Bank Receipt Voucher
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VoucherAccountDebit')]
    procedure BankReceiptVoucherWithTDSOnCustomer()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccount: Record "Bank Account";
        Location: Record Location;
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());
        CreateBankAccWithVoucherAccount(AccountType::"Bank Account", VoucherType::"Bank Receipt Voucher", BankAccount, Location);

        // [WHEN] Create and Post Bank Receipt Voucher
        LibraryTDSC.CreateGenJournalLineWithTDSCertificateReceivableForBank(GenJournalLine, Customer."No.", BankAccount."No.", VoucherType::"Bank Receipt Voucher", TDSPostingSetup."TDS Section", Location.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify TDS Certificate Receivable on customer ledger entry
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange("TDS Certificate Receivable", true);
        CustLedgEntry.FindFirst();
        Assert.RecordIsNotEmpty(CustLedgEntry);
    end;

    //[Scenario 357215] Check if the program is not calculating TDS while creating Customer’s sales order - TDSC028
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure SalesOrderWithTDSOnCustomer()
    var
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        SalesHeader: Record "Sales Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());

        //[WHEN] Create and post sales order with TDS Certificate receivable
        LibraryTDSC.CreateAndPostSalesDocumentWithTDSCertificateReceivable(
            SalesHeader,
            SalesHeader."Document Type"::Order,
            Customer."No.");

        // [THEN] Verify TDS Certificate Receivable on customer ledger entry
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange("TDS Certificate Receivable", true);
        CustLedgEntry.FindFirst();
        Assert.RecordIsNotEmpty(CustLedgEntry);
    end;

    //[Scenario 357203] Check if the program is calculating TDS while creating customer Receipt using the Cash Receipt Voucher - TDSC014/TDSC015
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VoucherAccountDebit')]
    procedure CashReceiptVoucherWithTDSOnCustomer()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        GLAccount: Record "G/L Account";
        Location: Record Location;
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());
        CreateGLAccWithVoucherAccount(AccountType::"G/L Account", VoucherType::"Cash Receipt Voucher", GLAccount, Location);

        // [WHEN] Create and Post Cash Receipt Voucher
        LibraryTDSC.CreateGenJournalLineWithTDSCertificateReceivableForGL(GenJournalLine, Customer."No.", GLAccount."No.", VoucherType::"Cash Receipt Voucher",
                                                                        TDSPostingSetup."TDS Section", Location.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify TDS Certificate Receivable on customer ledger entry
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange("TDS Certificate Receivable", true);
        CustLedgEntry.FindFirst();
        Assert.RecordIsNotEmpty(CustLedgEntry);
    end;

    //[Scenario 357216] Check if the program is not calculating TDS while creating Customer’s sales invoice
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure SalesInvoiceWithTDSOnCustomer()
    var
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        SalesHeader: Record "Sales Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());

        //[WHEN] Create and post sales invoice with TDS Certificate receivable
        LibraryTDSC.CreateAndPostSalesDocumentWithTDSCertificateReceivable(
            SalesHeader,
            SalesHeader."Document Type"::Invoice,
            Customer."No.");

        // [THEN] Verify TDS Certificate Receivable on customer ledger entry    
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange("TDS Certificate Receivable", true);
        CustLedgEntry.FindFirst();
        Assert.RecordIsNotEmpty(CustLedgEntry);
    end;

    //[Scenario 357217] Check if the program is not calculating TDS while creating Customer’s sales credit memo
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure SalesCreditMemoWithTDSOnCustomer()
    var
        Customer: Record customer;
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        SalesHeader: Record "Sales Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());

        //[WHEN] Create and post sales credit memo with TDS Certificate receivable
        LibraryTDSC.CreateAndPostSalesDocumentWithTDSCertificateReceivable(
            SalesHeader,
            SalesHeader."Document Type"::"Credit Memo",
            Customer."No.");

        // [THEN] Verify TDS Certificate Receivable on customer ledger entry
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange("TDS Certificate Receivable", true);
        CustLedgEntry.FindFirst();
        Assert.RecordIsNotEmpty(CustLedgEntry);
    end;

    //[Scenario 357218] Check if the program is not calculating TDS while creating Customer’s sales return order
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure SalesReturnOrderWithTDSOnCustomer()
    var
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        SalesHeader: Record "Sales Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());

        //[WHEN] Create and post sales return order with TDS Certificate receivable
        LibraryTDSC.CreateAndPostSalesDocumentWithTDSCertificateReceivable(
            SalesHeader,
            SalesHeader."Document Type"::"Return Order",
            Customer."No.");

        // [THEN] Verify TDS Certificate Receivable on customer ledger entry
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange("TDS Certificate Receivable", true);
        CustLedgEntry.FindFirst();
        Assert.RecordIsNotEmpty(CustLedgEntry);
    end;

    //[Scenario 357219] Check if the system is allowing to place check mark in TDS Certificate receivable field in Sales Order header
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure SalesOrderWithTDSOnCustomerToCheckTDSCertificateReceivable()
    var
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        SalesHeader: Record "Sales Header";
    begin
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());

        //[WHEN] Create sales order with TDS Certificate Receivable
        LibraryTDSC.CreateSalesDocumentWithTDSCertificateReceivable(
            SalesHeader,
            SalesHeader."Document Type"::Order,
            Customer."No.");

        //[THEN] Check TDS Certificate Receivable  is marked true on sales order 
        Assert.Equal(true, SalesHeader."TDS Certificate Receivable");
    end;

    //[Scenario 357220] Check if the system is allowing to place check mark in TDS Certificate receivable field in Sales invoice header
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure SalesInvoiceWithTDSOnCustomerToCheckTDSCertificateReceivable()
    var
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        SalesHeader: Record "Sales Header";
    begin
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());

        //[WHEN] Create sales invoice with TDS Certificate receivable
        LibraryTDSC.CreateSalesDocumentWithTDSCertificateReceivable(
            SalesHeader,
            SalesHeader."Document Type"::Invoice,
            Customer."No.");

        //[THEN] Check TDS Certificate Receivable  is marked true on sales invoice
        Assert.Equal(True, SalesHeader."TDS Certificate Receivable");
    end;

    //[Scenario 357226] Check if the system is generating entry in Update TDS Cert. Details window when check mark is placed  in TDS Certificate receivable field in Sales Order header
    [Test]
    [HandlerFunctions('TaxRatePageHandler,CheckTDSCertRecOnUpdateTDSCertDetailsPage')]
    procedure SalesOrderWithTDSCertReceWithUpdateTDSCertificate()
    var
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());

        //[WHEN] Create and post sales order with TDS Certificate receivable
        DocumentNo := LibraryTDSC.CreateAndPostSalesDocumentWithTDSCertificateReceivable(
            SalesHeader,
            SalesHeader."Document Type"::Order,
            Customer."No.");

        // [THEN] Verify TDS Certificate Receivable on Update TDS Certificate Page
        LibraryVarStorage.Clear();
        LibraryVarStorage.Enqueue(DocumentNo);
        UpdateTDSCertifcateDetails(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    //[Scenario 357227] Check if the system is generating entry in Update TDS Cert. Details window when check mark is not placed  in TDS Certificate receivable field in Sales Order header
    [Test]
    [HandlerFunctions('TaxRatePageHandler,CheckWithoutTDSCertRecOnUpdateTDSCertDetailsPage')]
    procedure SalesOrderWithoutTDSCertReceWithUpdateTDSCertificate()
    var
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        //[GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());

        //[WHEN] Create and post sales invoice without TDS Certificate receivable
        DocumentNo := LibraryTDSC.CreateAndPostSalesDocumentWithoutTDSCertificateReceivable(
            SalesHeader,
            SalesHeader."Document Type"::Invoice,
            Customer."No.");

        // [THEN] Verify TDS Certificate Receivable on Update TDS Certificate Page
        LibraryVarStorage.Clear();
        LibraryVarStorage.Enqueue(DocumentNo);
        UpdateTDSCertifcateDetails(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    //[Scenario 357246] Check if the program is calculating TDS with concessional code while creating customer Receipt using the General Journal
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure GeneralJournalWithTDSOnCustomerAndWithConcessionalCode()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VoucherType: Enum "Gen. Journal Template Type";
    begin
        //[GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [WHEN] Create and Post General Journal
        LibraryTDSC.CreateGenJournalLineWithTDSCertificateReceivable(GenJournalLine, Customer."No.", VoucherType::General, TDSPostingSetup."TDS Section");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify TDS Certificate Receivable on customer ledger entry
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange("TDS Certificate Receivable", true);
        CustLedgEntry.FindFirst();
        Assert.RecordIsNotEmpty(CustLedgEntry);
    end;

    //[Scenario 357247] Check if the program is calculating TDS with concessional code while creating customer Receipt using the Bank Receipt Voucher
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VoucherAccountDebit')]
    procedure BankReceiptVoucherWithTDSOnCustomerAndWithConcessionalCode()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccount: Record "Bank Account";
        Location: Record Location;
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        //[GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());
        CreateBankAccWithVoucherAccount(AccountType::"Bank Account", VoucherType::"Bank Receipt Voucher", BankAccount, Location);

        // [WHEN] Create and Post bank receipt voucher
        LibraryTDSC.CreateGenJournalLineWithTDSCertificateReceivableForBank(GenJournalLine, Customer."No.", BankAccount."No.", VoucherType::"Bank Receipt Voucher", TDSPostingSetup."TDS Section", Location.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify TDS Certificate Receivable on customer ledger entry
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange("TDS Certificate Receivable", true);
        CustLedgEntry.FindFirst();
        Assert.RecordIsNotEmpty(CustLedgEntry);
    End;

    //[Scenario 357248] Check if the program is calculating TDS with concessional code while creating customer Receipt using the Cash Receipt Voucher
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VoucherAccountDebit')]
    procedure CashReceiptVoucherWithTDSOnCustomerAndWithConcessionalCode()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        GLAccount: Record "G/L Account";
        Location: Record Location;
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        //[GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());
        CreateGLAccWithVoucherAccount(AccountType::"G/L Account", VoucherType::"Cash Receipt Voucher", GLAccount, Location);

        // [WHEN] Create and Post cash receipt voucher
        LibraryTDSC.CreateGenJournalLineWithTDSCertificateReceivableForGL(GenJournalLine, Customer."No.", GLAccount."No.", VoucherType::"Cash Receipt Voucher", TDSPostingSetup."TDS Section", Location.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify TDS Certificate Receivable on customer ledger entry
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange("TDS Certificate Receivable", true);
        CustLedgEntry.FindFirst();
        Assert.RecordIsNotEmpty(CustLedgEntry);
    End;

    //[Scenario 357190] Check if the progrm is not considering any Threshold limit while calculating TDS amount in different journals
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure JournalVoucherWithTDSOnCustomer()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        GLAccount: Record "G/L Account";
        Location: Record Location;
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        //[GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());
        CreateGLAccWithVoucherAccount(AccountType::"G/L Account", VoucherType::"Journal Voucher", GLAccount, Location);

        // [WHEN] Create Journal Voucher
        LibraryTDSC.CreateGenJournalLineWithTDSCertificateReceivableForGL(GenJournalLine, Customer."No.", GLAccount."No.", VoucherType::"Journal Voucher",
                                                                        TDSPostingSetup."TDS Section", Location.Code);

        //[THEN] Check TDS Certificate Receivable  is marked true on journal voucher
        Assert.Equal(true, GenJournalLine."TDS Certificate Receivable");
    end;

    //[Scenario 357228] Check if the system is generating  entry in Assign TDS Cert. Details window when check mark is placed  in TDS Certificate receivable field in Sales Order header
    [Test]
    [HandlerFunctions('TaxRatePageHandler,CheckTDSCertRecOnAssignTDSCertDetailsPage')]
    procedure SalesOrderWithTDSCertReceWithAssignTDSCertificate()
    var
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        SalesHeader: Record "Sales Header";
    begin
        //[GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());

        //[WHEN] Create and post sales order with TDS Certificate receivable
        LibraryTDSC.CreateAndPostSalesDocumentWithTDSCertificateReceivable(
            SalesHeader,
            SalesHeader."Document Type"::Order,
            Customer."No.");

        // [THEN] Verify TDS Certificate Receivable on Update TDS Certificate Page
        LibraryVarStorage.Clear();
        LibraryVarStorage.Enqueue(Customer."No.");
        AssignTDSCertifcateDetails(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    //[Scenario 357199] Check if the system is generating entry in Update TDS Cert. Details window when check mark is placed  in TDS Certificate receivable field in Bank Receipt Voucher
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VoucherAccountDebit,CheckTDSCertRecOnUpdateTDSCertDetailsPage')]
    procedure BankReceiptVoucherWithTDSCertReceiAndUpdateTDSCertificate()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        BankAccount: Record "Bank Account";
        Location: Record Location;
        DocumentNo: Code[20];
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        //[GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());
        CreateBankAccWithVoucherAccount(AccountType::"Bank Account", VoucherType::"Bank Receipt Voucher", BankAccount, Location);

        // [WHEN] Create and Post Bank Receipt Voucher
        LibraryTDSC.CreateGenJournalLineWithTDSCertificateReceivableForBank(GenJournalLine, Customer."No.", BankAccount."No.", VoucherType::"Bank Receipt Voucher", TDSPostingSetup."TDS Section", Location.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify posted entry for TDS Certificate Receivable on Update TDS Certificate Page
        DocumentNo := LibraryTDSC.VerifyGLEntryCount(GenJournalLine."Journal Batch Name", 3);
        LibraryVarStorage.Clear();
        LibraryVarStorage.Enqueue(DocumentNo);
        UpdateTDSCertifcateDetails(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    //[Scenario 357199] Check if the system is generating entry in Update TDS Cert. Details window when check mark is placed  in TDS Certificate receivable field in Bank Receipt Voucher
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VoucherAccountDebit,CheckWithoutTDSCertRecOnUpdateTDSCertDetailsPage')]
    procedure BankReceiptVoucherWithoutTDSCertReceiAndUpdateTDSCertificate()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        BankAccount: Record "Bank Account";
        Location: Record Location;
        DocumentNo: Code[20];
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        //[GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());
        CreateBankAccWithVoucherAccount(AccountType::"Bank Account", VoucherType::"Bank Receipt Voucher", BankAccount, Location);

        // [WHEN] Create and Post Bank Receipt Voucher
        LibraryTDSC.CreateGenJournalLineWithoutTDSCertificateReceivableForBank(GenJournalLine, Customer."No.", BankAccount."No.", VoucherType::"Bank Receipt Voucher", '', Location.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify posted entry for TDS Certificate Receivable on Update TDS Certificate Page
        DocumentNo := LibraryTDSC.VerifyGLEntryCount(GenJournalLine."Journal Batch Name", 2);
        LibraryVarStorage.Clear();
        LibraryVarStorage.Enqueue(DocumentNo);
        UpdateTDSCertifcateDetails(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    //[Scenario 357205] Check if the system is generating entry in Update TDS Cert. Details window when check mark is placed  in TDS Certificate receivable field in Cash Receipt Voucher
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VoucherAccountDebit,CheckTDSCertRecOnUpdateTDSCertDetailsPage')]
    procedure CashReceiptVoucherWithTDSCertReceiAndUpdateTDSCertificate()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        GLAccount: Record "G/L Account";
        Location: Record Location;
        DocumentNo: Code[20];
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        //[GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());
        CreateGLAccWithVoucherAccount(AccountType::"G/L Account", VoucherType::"Cash Receipt Voucher", GLAccount, Location);

        // [WHEN] Create and Post Cash Receipt Voucher
        LibraryTDSC.CreateGenJournalLineWithTDSCertificateReceivableForGL(GenJournalLine, Customer."No.", GLAccount."No.", VoucherType::"Cash Receipt Voucher", TDSPostingSetup."TDS Section", Location.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify posted entry for TDS Certificate Receivable on Update TDS Certificate Page
        DocumentNo := LibraryTDSC.VerifyGLEntryCount(GenJournalLine."Journal Batch Name", 3);
        LibraryVarStorage.Clear();
        LibraryVarStorage.Enqueue(DocumentNo);
        UpdateTDSCertifcateDetails(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    //[Scenario 357206] Check if the system is generating entry in Update TDS Cert. Details window when check mark is placed  in TDS Certificate receivable field in Bank Receipt Voucher
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VoucherAccountDebit,CheckWithoutTDSCertRecOnUpdateTDSCertDetailsPage')]
    procedure CashReceiptVoucherWithoutTDSCertReceiAndUpdateTDSCertificate()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        GLAccount: Record "G/L Account";
        Location: Record Location;
        TDSPostingSetup: Record "TDS Posting Setup";
        DocumentNo: Code[20];
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        //[GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());
        CreateGLAccWithVoucherAccount(AccountType::"G/L Account", VoucherType::"Cash Receipt Voucher", GLAccount, Location);

        // [WHEN] Create and Post Cash Receipt Voucher without TDS Certificate receivable
        LibraryTDSC.CreateGenJournalLineWithoutTDSCertificateReceivableForGL(GenJournalLine, Customer."No.", GLAccount."No.", VoucherType::"Cash Receipt Voucher", '', Location.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify posted entry for TDS Certificate Receivable on Update TDS Certificate Page
        DocumentNo := LibraryTDSC.VerifyGLEntryCount(GenJournalLine."Journal Batch Name", 2);
        LibraryVarStorage.Clear();
        LibraryVarStorage.Enqueue(DocumentNo);
        UpdateTDSCertifcateDetails(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    //[Scenario 357201] Check if the system is generating  entry in Assign TDS Cert. Details window when check mark is placed  in TDS Certificate receivable field in Bank Receipt Voucher
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VoucherAccountDebit,CheckTDSCertRecOnAssignTDSCertDetailsPage')]
    procedure BankReceiptVoucherWithTDSCertReceiAndAssignTDSCertificate()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        BankAccount: Record "Bank Account";
        Location: Record Location;
        DocumentNo: Code[20];
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        //[GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());
        CreateBankAccWithVoucherAccount(AccountType::"Bank Account", VoucherType::"Bank Receipt Voucher", BankAccount, Location);

        // [WHEN] Create and Post Bank Receipt Voucher
        LibraryTDSC.CreateGenJournalLineWithTDSCertificateReceivableForBank(GenJournalLine, Customer."No.", BankAccount."No.", VoucherType::"Bank Receipt Voucher", TDSPostingSetup."TDS Section", Location.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify posted entry for TDS Certificate Receivable on Update TDS Certificate Page
        DocumentNo := LibraryTDSC.VerifyGLEntryCount(GenJournalLine."Journal Batch Name", 3);
        LibraryVarStorage.Clear();
        LibraryVarStorage.Enqueue(DocumentNo);
        AssignTDSCertifcateDetails(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    //[Scenario 357202] Check if the system is generating  entry in Assign TDS Cert. Details window when check mark is not placed  in TDS Certificate receivable field in Bank Receipt Voucher
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VoucherAccountDebit,CheckTDSCertRecOnAssignTDSCertDetailsPage')]
    procedure BankReceiptVoucherWithoutTDSCertReceiAndAssignTDSCertificate()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        BankAccount: Record "Bank Account";
        Location: Record Location;
        DocumentNo: Code[20];
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        //[GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());
        CreateBankAccWithVoucherAccount(AccountType::"Bank Account", VoucherType::"Bank Receipt Voucher", BankAccount, Location);

        // [WHEN] Create and Post Bank Receipt Voucher without TDS Certificate Page
        LibraryTDSC.CreateGenJournalLineWithoutTDSCertificateReceivableForBank(GenJournalLine, Customer."No.", BankAccount."No.", VoucherType::"Bank Receipt Voucher", '', Location.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify posted entry for TDS Certificate Receivable on Update TDS Certificate Page
        DocumentNo := LibraryTDSC.VerifyGLEntryCount(GenJournalLine."Journal Batch Name", 2);
        LibraryVarStorage.Clear();
        LibraryVarStorage.Enqueue(DocumentNo);
        AssignTDSCertifcateDetails(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    //[Scenario 357207] Check if the system is generating  entry in Assign TDS Cert. Details window when check mark is placed  in TDS Certificate receivable field in Cash Receipt Voucher
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VoucherAccountDebit,CheckTDSCertRecOnAssignTDSCertDetailsPage')]
    procedure CashReceiptVoucherWithTDSCertReceiAndAssignTDSCertificate()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        GLAccount: Record "G/L Account";
        Location: Record Location;
        DocumentNo: Code[20];
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        //[GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());
        CreateGLAccWithVoucherAccount(AccountType::"G/L Account", VoucherType::"Cash Receipt Voucher", GLAccount, Location);

        // [WHEN] Create and Post Cash Receipt Voucher
        LibraryTDSC.CreateGenJournalLineWithTDSCertificateReceivableForGL(GenJournalLine, Customer."No.", GLAccount."No.", VoucherType::"Cash Receipt Voucher", TDSPostingSetup."TDS Section", Location.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify posted entry for TDS Certificate Receivable on Update TDS Certificate Page
        DocumentNo := LibraryTDSC.VerifyGLEntryCount(GenJournalLine."Journal Batch Name", 3);
        LibraryVarStorage.Clear();
        LibraryVarStorage.Enqueue(DocumentNo);
        AssignTDSCertifcateDetails(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    //[Scenario 357208] Check if the system is generating  entry in Assign TDS Cert. Details window when check mark is not placed  in TDS Certificate receivable field in Cash Receipt Voucher
    [Test]
    [HandlerFunctions('TaxRatePageHandler,VoucherAccountDebit,CheckTDSCertRecOnAssignTDSCertDetailsPage')]
    procedure CashReceiptVoucherWithoutTDSCertReceiAndAssignTDSCertificate()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        GLAccount: Record "G/L Account";
        Location: Record Location;
        DocumentNo: Code[20];
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        //[GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSC.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());
        CreateGLAccWithVoucherAccount(AccountType::"G/L Account", VoucherType::"Cash Receipt Voucher", GLAccount, Location);

        // [WHEN] Create and Post Cash Receipt Voucher without TDS Certificate receivable
        LibraryTDSC.CreateGenJournalLineWithoutTDSCertificateReceivableForGL(GenJournalLine, Customer."No.", GLAccount."No.", VoucherType::"Cash Receipt Voucher", '', Location.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify posted entry for TDS Certificate Receivable on Update TDS Certificate Page
        DocumentNo := LibraryTDSC.VerifyGLEntryCount(GenJournalLine."Journal Batch Name", 2);
        LibraryVarStorage.Clear();
        LibraryVarStorage.Enqueue(DocumentNo);
        AssignTDSCertifcateDetails(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    local procedure UpdateTDSCertifcateDetails(CustomerNo: Code[20]; TDSSection: code[10])
    var
        UpdateCertifcate: TestPage "Update TDS Certificate Details";
        Year: Integer;
    begin
        UpdateCertifcate.OpenEdit();
        UpdateCertifcate.CustomerNo.SetValue(CustomerNo);
        UpdateCertifcate.CertificateNo.SetValue(LibraryUtility.GenerateRandomText(20));
        UpdateCertifcate.CertificateDate.SetValue(LibraryUtility.GenerateRandomDate(WorkDate(), CALCDATE('<1Y>', Today)));
        UpdateCertifcate.CertificateAmount.SetValue(LibraryRandom.RandDec(100, 2));
        Year := DATE2DMY(WorkDate(), 3);
        UpdateCertifcate.FinancialYear.SetValue(Year);
        UpdateCertifcate.TDSSection.SetValue(TDSSection);
        UpdateCertifcate."Update TDS Cert. Details".Invoke();
    end;

    local procedure AssignTDSCertifcateDetails(CustomerNo: Code[20]; TDSSection: code[10])
    var
        UpdateCertifcate: TestPage "Update TDS Certificate Details";
        Year: Integer;
    begin
        UpdateCertifcate.OpenEdit();
        UpdateCertifcate.CustomerNo.SetValue(CustomerNo);
        UpdateCertifcate.CertificateNo.SetValue(LibraryUtility.GenerateRandomText(20));
        UpdateCertifcate.CertificateDate.SetValue(LibraryUtility.GenerateRandomDate(WorkDate(), CALCDATE('<1Y>', Today)));
        UpdateCertifcate.CertificateAmount.SetValue(LibraryRandom.RandDec(100, 2));
        Year := DATE2DMY(WorkDate(), 3);
        UpdateCertifcate.FinancialYear.SetValue(Year);
        UpdateCertifcate.TDSSection.SetValue(TDSSection);
        UpdateCertifcate."Assign TDS Cert. Details".Invoke();
    end;


    [PageHandler]
    procedure CheckTDSCertRecOnUpdateTDSCertDetailsPage(var UpdateTDSCertDetails: TestPage "Update TDS Cert. Details")
    var
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
        Value: Variant;
    begin
        LibraryVarStorage.Dequeue(Value);
        DocumentNo := Value;
        CustomerLedgerEntry.SetRange("Document No.", DocumentNo);
        CustomerLedgerEntry.SetRange("TDS Certificate Receivable", true);
        if CustomerLedgerEntry.FindFirst() then;
        UpdateTDSCertDetails.GoToRecord(CustomerLedgerEntry);
        Assert.Equal(true, UpdateTDSCertDetails."TDS Certificate Receivable".AsBoolean());
    end;

    [PageHandler]
    procedure CheckWithoutTDSCertRecOnUpdateTDSCertDetailsPage(var UpdateTDSCertDetails: TestPage "Update TDS Cert. Details")
    var
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
        Value: Variant;
    begin
        LibraryVarStorage.Dequeue(Value);
        DocumentNo := Value;
        CustomerLedgerEntry.SetRange("Document No.", DocumentNo);
        CustomerLedgerEntry.SetRange("TDS Certificate Receivable", false);
        if CustomerLedgerEntry.FindFirst() then;
        asserterror UpdateTDSCertDetails.GoToRecord(CustomerLedgerEntry);
        Assert.ExpectedError('The row does not exist on the TestPage.');
    end;

    [PageHandler]
    procedure CheckTDSCertRecOnAssignTDSCertDetailsPage(var AssignTDSCertDetails: TestPage "Assign TDS Cert. Details")
    var
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        Value: Variant;
    begin
        LibraryVarStorage.Dequeue(Value);
        CustomerNo := Value;
        CustomerLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustomerLedgerEntry.SetRange("TDS Certificate Receivable", false);
        if not CustomerLedgerEntry.FindFirst() then;
        asserterror AssignTDSCertDetails.GoToRecord(CustomerLedgerEntry);
        Assert.ExpectedError('The row does not exist on the TestPage.');
    end;

    [PageHandler]
    procedure CheckWithoutTDSCertRecOnAssignTDSCertDetailsPage(var AssignTDSCertDetails: TestPage "Assign TDS Cert. Details")
    var
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        Value: Variant;
    begin
        LibraryVarStorage.Dequeue(Value);
        CustomerNo := Value;
        CustomerLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustomerLedgerEntry.SetRange("TDS Certificate Receivable", false);
        if CustomerLedgerEntry.FindFirst() then;
        AssignTDSCertDetails.GoToRecord(CustomerLedgerEntry);
        Assert.RecordIsnotEmpty(CustomerLedgerEntry);
    end;

    local procedure GetTaxComponentsAndCreateTaxRate(TDSSection: Code[10]; AssesseeCode: Code[10]; ConcessionalCode: Code[10]; EffectiveDate: Date)
    begin
        Section := TDSSection;
        TDSAssesseeCode := AssesseeCode;
        TDSConcessionalCode := ConcessionalCode;
        TDSEffectiveDate := EffectiveDate;
        CreateTaxRate();
    end;

    local procedure GenerateTaxComponentsPercentage()
    begin
        TDSPercentage := LibraryRandom.RandIntInRange(2, 4);
        NonPANTDSPercentage := LibraryRandom.RandIntInRange(8, 10);
        SurchargePercentage := LibraryRandom.RandIntInRange(8, 10);
        eCessPercentage := LibraryRandom.RandIntInRange(4, 6);
        SHECessPercentage := LibraryRandom.RandIntInRange(4, 6);
        TDSThresholdAmount := LibraryRandom.RandDec(10000, 2);
        SurchargeThresholdAmount := LibraryRandom.RandDec(5000, 2);
    end;

    Local procedure CreateTaxRate()
    var
        TDSSetup: Record "TDS Setup";
        PageTaxtype: TestPage "Tax Types";
    begin
        if not TDSSetup.Get() then
            exit;
        PageTaxtype.OpenEdit();
        PageTaxtype.Filter.SetFilter(Code, TDSSetup."Tax Type");
        PageTaxtype.TaxRates.Invoke();
    end;

    [PageHandler]
    procedure TaxRatePageHandler(var TaxRate: TestPage "Tax Rates");
    begin
        TaxRate.AttributeValue1.SetValue(Section);
        TaxRate.AttributeValue2.SetValue(TDSAssesseeCode);
        TaxRate.AttributeValue3.SetValue(TDSEffectiveDate);
        TaxRate.AttributeValue4.SetValue(TDSConcessionalCode);
        TaxRate.AttributeValue5.SetValue('');
        TaxRate.AttributeValue6.SetValue('');
        TaxRate.AttributeValue7.SetValue('');
        GenerateTaxComponentsPercentage();
        TaxRate.AttributeValue8.SetValue(TDSPercentage);
        TaxRate.AttributeValue9.SetValue(NonPANTDSPercentage);
        TaxRate.AttributeValue10.SetValue(SurchargePercentage);
        TaxRate.AttributeValue11.SetValue(eCessPercentage);
        TaxRate.AttributeValue12.SetValue(SHECessPercentage);
        TaxRate.AttributeValue13.SetValue(TDSThresholdAmount);
        TaxRate.AttributeValue14.SetValue(SurchargeThresholdAmount);
        TaxRate.AttributeValue15.SetValue('');
        TaxRate.AttributeValue16.SetValue('');
        TaxRate.OK().Invoke();
    end;

    local procedure CreateBankAccWithVoucherAccount(AccountType: Enum "Gen. Journal Account Type";
                    VoucherType: enum "Gen. Journal Template Type"; var BankAccount: Record "Bank Account"; var Location: Record Location): Code[20]
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryTDSC.CreateLocationWithTANNo(Location);
        StorageEnum.Set('AccountType', format(AccountType));
        Storage.Set('AccountNo', BankAccount."No.");
        CreateVoucherAccountSetup(VoucherType, Location.Code);
        exit(BankAccount."No.");
    end;

    local procedure CreateGLAccWithVoucherAccount(AccountType: Enum "Gen. Journal Account Type";
                    VoucherType: enum "Gen. Journal Template Type"; var GLAccount: Record "G/L Account"; var Location: Record Location): Code[20]
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryTDSC.CreateLocationWithTANNo(Location);
        StorageEnum.Set('AccountType', format(AccountType));
        Storage.Set('AccountNo', GLAccount."No.");
        CreateVoucherAccountSetup(VoucherType, Location.Code);
        exit(GLAccount."No.");
    end;

    local procedure CreateVoucherAccountSetup(SubType: Enum "Gen. Journal Template Type"; LocationCode: Code[10])
    var
        VoucherSetupPage: TestPage "Journal Voucher Posting Setup";
        LocationCard: TestPage "Location Card";
    begin
        LocationCard.OpenEdit();
        LocationCard.GoToKey(LocationCode);
        VoucherSetupPage.Trap();
        LocationCard."Voucher Setup".Invoke();
        VoucherSetupPage.Filter.SetFilter(Type, Format(SubType));
        VoucherSetupPage.Filter.SetFilter("Location Code", LocationCode);
        case SubType of
            SubType::"Bank Payment Voucher", SubType::"Cash Payment Voucher", SubType::"Contra Voucher":
                begin
                    VoucherSetupPage."Transaction Direction".SetValue('Credit');
                    VoucherSetupPage."Credit Account".Invoke();
                end;
            SubType::"Cash Receipt Voucher", SubType::"Bank Receipt Voucher", SubType::"Journal Voucher":
                begin
                    VoucherSetupPage."Transaction Direction".SetValue('Debit');
                    VoucherSetupPage."Debit Account".Invoke();
                end;
        end;
    end;

    [PageHandler]
    procedure VoucherAccountCredit(var VoucherCrAccount: TestPage "Voucher Posting Credit Account");
    var
        AccountType: Enum "Gen. Journal Account Type";
    begin
        Evaluate(AccountType, StorageEnum.Get('AccountType'));
        VoucherCrAccount.Type.SetValue(AccountType);
        VoucherCrAccount."Account No.".SetValue(Storage.Get('AccountNo'));
        VoucherCrAccount.OK().Invoke();
    end;

    [PageHandler]
    procedure VoucherAccountDebit(var VoucherDrAccount: TestPage "Voucher Posting Debit Accounts");
    var
        AccountType: Enum "Gen. Journal Account Type";
    begin
        Evaluate(AccountType, StorageEnum.Get('AccountType'));
        VoucherDrAccount.Type.SetValue(AccountType);
        VoucherDrAccount."Account No.".SetValue(Storage.Get('AccountNo'));
        VoucherDrAccount.OK().Invoke();
    end;

    var
        LibraryTDSC: Codeunit "Library TDS On Customer";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
}