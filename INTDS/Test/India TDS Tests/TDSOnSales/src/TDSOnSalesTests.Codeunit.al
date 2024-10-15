codeunit 18683 "TDS On Sales Tests"
{
    Subtype = Test;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure CheckTDSCertificateReceivableInGeneralJournal()
    var
        Customer: Record Customer;
        TDSPostingSetup: Record "TDS Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        VoucherType: Enum "Gen. Journal Template Type";
    begin
        // [Scenario 357191][Check if the system is allowing to place check mark in TDS Certificate receivable field in General Journal.]
        // [Given] Customer Setup &  G/L Account Setups
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [When] Creation of GenjnlLine and Marking TDS Certificate True.
        LibraryTDSCustomer.CreateGenJournalLineWithTDSCertificateReceivable(GenJournalLine, Customer."No.", VoucherType::General, TDSPostingSetup."TDS Section");

        // [Then] Verification of Feild value.
        Assert.IsTrue(GenJournalLine."TDS Certificate Receivable", CertifcateValidationErr);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,VoucherAccountDebit')]
    procedure CreateBankReceiptVoucherWithTDSReceivable()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        BankAccount: Record "Bank Account";
        Location: Record Location;
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        // [Scenario 357198][Check if the system is allowing to place check mark in TDS Certificate receivable field in Bank Receipt Voucher-TDSC009.]
        // [Given] Customer Setup &  G/L Account Setups & Bank Receipt Voucher.
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());
        CreateBankAccWithVoucherAccount(AccountType::"Bank Account", VoucherType::"Bank Receipt Voucher", BankAccount, Location);

        // [When] Creation of GenjnlLine and Marking TDS Certificate True.
        LibraryTDSCustomer.CreateGenJournalLineWithTDSCertificateReceivableForBank(GenJournalLine, Customer."No.", BankAccount."No.", VoucherType::"Bank Receipt Voucher", TDSPostingSetup."TDS Section", Location.Code);

        // [Then] Verification of Feild value.
        Assert.IsTrue(GenJournalLine."TDS Certificate Receivable", CertifcateValidationErr);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,VoucherAccountDebit')]
    procedure CreateCashReceiptVoucherWithTDSReceivable()
    var
        Customer: Record Customer;
        Location: Record Location;
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        // [Scenario 357204][Check if the system is allowing to place check mark in TDS Certificate receivable field in Cash Receipt Journals - TDSC016/TDSC017.]
        // [Given] Customer Setup &  G/L Account Setups & Cash Receipt Voucher.
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());
        CreateGLAccWithVoucherAccount(AccountType::"G/L Account", VoucherType::"Cash Receipt Voucher", GLAccount, Location);

        // [When] Creation of GenjnlLine and Marking TDS Certificate True.
        LibraryTDSCustomer.CreateGenJournalLineWithTDSCertificateReceivableForGL(GenJournalLine, Customer."No.", GLAccount."No.", VoucherType::"Cash Receipt Voucher",
                                                                        TDSPostingSetup."TDS Section", Location.Code);

        // [Then] Verification of Feild value.
        Assert.IsTrue(GenJournalLine."TDS Certificate Receivable", CertifcateValidationErr);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,CertificateUpdatePage,RectifyTDSCertificate')]
    procedure CheckRectifyTDSCertificateWhenTDSCertificateSetFalse()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        VoucherType: Enum "Gen. Journal Template Type";
    begin
        // [Senerio 357239]	[Check if the system is deleting entry from Rectify TDS Cert. Details window when check mark removed from TDS Certificate Received field of Rectify TDS Cert. Details window - TDSC052]
        // [Given] Customer Setup &  G/L Account Setups & TDS Tax Setups.
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [When] Creation of GenjnlLine and Marking TDS Certificate True & Posting.
        LibraryTDSCustomer.CreateGenJournalLineWithTDSCertificateReceivable(GenJournalLine, Customer."No.", VoucherType::General, TDSPostingSetup."TDS Section");
        Storage.Set('DocumentNo', GenJournalLine."Document No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [Then] Verification of Certificate Update Page & Rectify TDS Certificate Page.
        UpdateAndRectifyCertificate(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,CertificateUpdatePage,RectifyTDSCertificateView')]
    procedure CheckIfSystemIsDeletingEntryInUpdateWindow()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        VoucherType: Enum "Gen. Journal Template Type";
    begin
        // [Scenario 357238][Check if the system is deleting entry in Update TDS Cert. Details window and generating entry in Rectify TDS Cert. Details window, when check mark is placed in TDS Certificate Received field of Update TDS Cert. Details window - TDSC051]
        // [Given] Customer Setup &  G/L Account Setups & TCS Setup,TCS Section Created Tax Rate Setup.
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [When] Creation of GenjnlLine and Marking TDS Certificate True with TDS Section.
        LibraryTDSCustomer.CreateGenJournalLineWithTDSCertificateReceivable(GenJournalLine, Customer."No.", VoucherType::General, TDSPostingSetup."TDS Section");
        Storage.Set('DocumentNo', GenJournalLine."Document No.");

        // [When] Posting of General journal Line 
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN]  Update and Rectify TDS Certificate.
        UpdateAndRectifyCertificate(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,CertificateUpdatePage,RectifyTDSCertificateFalse')]
    procedure CheckIfSystemIsGeneratingEntryInUpdateTDSCertficateWindow()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        VoucherType: Enum "Gen. Journal Template Type";
    begin
        //[Scenario 357240][Check if the system is generating entry in Update TDS Cert. Details window when check mark removed from TDS Certificate Received field of Rectify TDS Cert. Details window - TDSC053]
        // [Given] Customer Setup &  G/L Account Setups & TCS Setup,TCS Section Created Tax Rate Setup.
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [When] Creation of GenjnlLine and Marking TDS Certificate True with TDS Section.
        LibraryTDSCustomer.CreateGenJournalLineWithTDSCertificateReceivable(GenJournalLine, Customer."No.", VoucherType::General, TDSPostingSetup."TDS Section");
        Storage.Set('DocumentNo', GenJournalLine."Document No.");

        // [When] Posting of GenjnlLine 
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN]  Update and Rectify TDS Certificate.
        UpdateAndRectifyCertificate(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    [Test]

    [HandlerFunctions('TaxRatePageHandler,UncheckCertificateUpdatePage,CertificateAssignHandlerView')]
    procedure AssingCertificateIfCheckMarkRemovedFromUpdateDetials()
    var
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        VoucherType: Enum "Gen. Journal Template Type";
    begin
        // [Senerio 357241[Check if the system is generating entry in Assign TDS Cert. Details window when check mark removed from TDS Certificate Receivable field of Update TDS Cert. Details window -TDSC054.]
        // [Given] Customer Setup &  G/L Account Setups & TCS Setup,TCS Section Created Tax Rate Setup.
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [When] Creation of GenjnlLine and Marking TDS Certificate True with TDS Section.
        LibraryTDSCustomer.CreateGenJournalLineWithTDSCertificateReceivable(GenJournalLine, Customer."No.", VoucherType::General, TDSPostingSetup."TDS Section");
        Storage.Set('DocumentNo', GenJournalLine."Document No.");

        // [When] Posting of GenjnlLine 
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        UpdateAndAssignCertificate(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure CheckTDSCertificateReceivableInCustomerLedger()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VoucherType: Enum "Gen. Journal Template Type";
        ReceivableFalseErr: Label 'The feild value is false';
    begin
        //[Senerio 357214] [Check if the system is flowing TDS Certificate receivable field in Customer Ledger Entry -TDSC027]
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create and Post General Journal
        LibraryTDSCustomer.CreateGenJournalLineWithTDSCertificateReceivable(GenJournalLine, Customer."No.", VoucherType::General, TDSPostingSetup."TDS Section");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify TDS Certificate Receivable on customer ledger entry
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange("TDS Certificate Receivable", true);
        CustLedgEntry.FindFirst();
        Assert.IsTrue(CustLedgEntry."TDS Certificate Receivable", ReceivableFalseErr);
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,CertificateAssignHandler')]
    procedure IncaseofTrueCheckVisibleinAssignPageofCertificate()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        VoucherType: Enum "Gen. Journal Template Type";
    begin
        //[Senerio 357194] [Check if the system is generating  entry in Assign TDS Cert. Details window when check mark is placed  in TDS Certificate receivable field in General Journals - TDSC005]
        //[GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [When] Creation of GenjnlLine and Marking TDS Certificate True & Posting.
        LibraryTDSCustomer.CreateGenJournalLineWithTDSCertificateReceivable(GenJournalLine, Customer."No.", VoucherType::General, TDSPostingSetup."TDS Section");
        Storage.Set('DocumentNo', GenJournalLine."Document No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[THEN] Verification of Entry in Assign TDS Certificate
        AssignCertifcate(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,DisplayCertificateAssignPage')]
    procedure IncaseofFalseCheckVisibleinAssignPageofCertificate()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        TDSPostingSetup: Record "TDS Posting Setup";
        ConcessionalCode: Record "Concessional Code";
        VoucherType: Enum "Gen. Journal Template Type";
    begin
        // [Senerio 357195] [Check if the system is generating  entry in Assign TDS Cert. Details window when check mark is not placed  in TDS Certificate receivable field in General Journals - TDSC006]
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [WHEN] Create and Post General Voucher
        LibraryTDSCustomer.CreateGenJournalLineWithoutTDSCertificateReceivable(GenJournalLine, Customer."No.", VoucherType::General, '');
        Storage.Set('DocumentNo', GenJournalLine."Document No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify  for TDS Certificate Receivable on Assign TDS Page
        AssignCertifcate(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,DisplayCertificateAssignPageReceived')]
    procedure IncaseofFalseAssignCertificateTrue()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        VoucherType: Enum "Gen. Journal Template Type";
    begin
        // [Senerio 357237] [Check if the system is deleting entry from Assign TDS Cert details window and generating entry in Update TDS Cert. Details window when check mark is placed  in Assign TDS Cert details window - TDSC050]
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [WHEN] Create and Post General Journals
        LibraryTDSCustomer.CreateGenJournalLineWithoutTDSCertificateReceivable(GenJournalLine, Customer."No.", VoucherType::General, '');
        Storage.Set('DocumentNo', GenJournalLine."Document No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify  for TDS Certificate Receivable on Assign TDS Page
        AssignCertifcate(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,ViewCertificateUpdatePage')]
    procedure CheckInCaseOfCertificateReceivableIsTrue()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        VoucherType: Enum "Gen. Journal Template Type";
    begin
        // [Senerio 357192] [Check if the system is generating entry in Update TDS Cert. Details window when check mark is placed  in TDS Certificate receivable field in General Journals - TDSC003]
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [WHEN] Create and Post GenJournalLine with TDSCertifcateReceivable
        LibraryTDSCustomer.CreateGenJournalLineWithTDSCertificateReceivable(GenJournalLine, Customer."No.", VoucherType::General, TDSPostingSetup."TDS Section");
        Storage.Set('DocumentNo', GenJournalLine."Document No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify  for TDS Certificate Receivable on Update TDS Certificate Page
        UpdateCertificate(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,CertificateUpdateDetials')]
    procedure CheckInCaseOfCertificateReceivableISFlase()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        VoucherType: Enum "Gen. Journal Template Type";
    begin
        //[Senerio 357193] [Check if the system is generating entry in Update TDS Cert. Details window when check mark is not placed  in TDS Certificate receivable field in General Journals -TDSC004]
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());

        // [WHEN] Create and Post GenJournalLine with TDSCertifcateReceivable
        LibraryTDSCustomer.CreateGenJournalLineWithoutTDSCertificateReceivable(GenJournalLine, Customer."No.", VoucherType::General, '');
        Storage.Set('DocumentNo', GenJournalLine."Document No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify  for TDS Certificate Receivable on Update TDS Certificate Page
        UpdateCertificate(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,ViewCertificateUpdatePage,VoucherAccountDebit')]
    procedure CheckInCaseOfCertificateReceivableISTrueInCashReceiptJournal()
    var
        Customer: Record Customer;
        Location: Record Location;
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        // [Senerio 357242][Check if the system is generating entry in Update TDS Cert. Details window when check mark is placed  in TDS Certificate receivable field in Cash Receipt Journals - TDSC055]
        //[GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());
        CreateGLAccWithVoucherAccount(AccountType::"G/L Account", VoucherType::"Cash Receipt Voucher", GLAccount, Location);

        // [WHEN] Create and Post Cash Receipt Voucher
        LibraryTDSCustomer.CreateGenJournalLineWithTDSCertificateReceivableForGL(GenJournalLine, Customer."No.", GLAccount."No.", VoucherType::"Cash Receipt Voucher",
                                                                        TDSPostingSetup."TDS Section", Location.Code);
        Storage.Set('DocumentNo', GenJournalLine."Document No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify  for TDS Certificate Receivable on Update TDS Certificate Page
        UpdateCertificate(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,ViewCertificateUpdatePage,VoucherAccountDebit')]
    procedure CheckInCaseOfCertificateReceivableISTrueInJournalVoucher()
    var
        Customer: Record Customer;
        Location: Record Location;
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        // [Senerio 357210][Check if the system is generating entry in Update TDS Cert. Details window when check mark is placed  in TDS Certificate receivable field in Journal Voucher - TDSC023]
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());
        CreateGLAccWithVoucherAccount(AccountType::"G/L Account", VoucherType::"Journal Voucher", GLAccount, Location);

        // [WHEN] Create and Post Journal Voucher
        LibraryTDSCustomer.CreateGenJournalLineWithTDSCertificateReceivableForGL(GenJournalLine, Customer."No.", GLAccount."No.", VoucherType::"Journal Voucher",
                                                                        TDSPostingSetup."TDS Section", Location.Code);
        Storage.Set('DocumentNo', GenJournalLine."Document No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify  for TDS Certificate Receivable on Update TDS Certificate Page
        UpdateCertificate(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,CertificateUpdateDetials,VoucherAccountDebit')]
    procedure CheckInCaseOfCertificateReceivableIsFalseInJournalVoucher()
    var
        Customer: Record Customer;
        Location: Record Location;
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        //[Senerio 357211] [Check if the system is generating entry in Update TDS Cert. Details window when check mark is not placed  in TDS Certificate receivable field in Journal Voucher - TDSC024]
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());
        CreateGLAccWithVoucherAccount(AccountType::"G/L Account", VoucherType::"Journal Voucher", GLAccount, Location);

        // [WHEN] Create and Post Journal Voucher
        LibraryTDSCustomer.CreateGenJournalLineWithoutTDSCertificateReceivableForGL(GenJournalLine, Customer."No.", GLAccount."No.", VoucherType::"Journal Voucher",
                                                                        '', Location.Code);
        Storage.Set('DocumentNo', GenJournalLine."Document No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify  for TDS Certificate Receivable on Update TDS Certificate Page
        UpdateCertificate(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,CertificateAssignHandler,VoucherAccountDebit')]
    procedure CheckInCaseOfCertificateReceivableIsTrueInJournalVoucherAssignPage()
    var
        Customer: Record Customer;
        Location: Record Location;
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        // [Senerio 357212]	[Check if the system is generating  entry in Assign TDS Cert. Details window when check mark is placed  in TDS Certificate receivable field in Journal Voucher - TDSC025]
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());
        CreateGLAccWithVoucherAccount(AccountType::"G/L Account", VoucherType::"Journal Voucher", GLAccount, Location);

        // [WHEN] Create and Post Journal Voucher
        LibraryTDSCustomer.CreateGenJournalLineWithTDSCertificateReceivableForGL(GenJournalLine, Customer."No.", GLAccount."No.", VoucherType::"Journal Voucher",
                                                                        TDSPostingSetup."TDS Section", Location.Code);
        Storage.Set('DocumentNo', GenJournalLine."Document No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify  for TDS Certificate Receivable on Assign TDS Certificate Page
        AssignCertifcate(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,CertificateAssignHandlerView,VoucherAccountDebit')]
    procedure CheckInCaseOfCertificateReceivableIsFalseInJournalVoucherAssignPage()
    var
        Customer: Record Customer;
        Location: Record Location;
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        // [Senerio 357213] [Check if the system is generating  entry in Assign TDS Cert. Details window when check mark is not placed  in TDS Certificate receivable field in Journal Voucher -TDSC026]
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());
        CreateGLAccWithVoucherAccount(AccountType::"G/L Account", VoucherType::"Journal Voucher", GLAccount, Location);

        // [WHEN] Create and Post Journal Voucher
        LibraryTDSCustomer.CreateGenJournalLineWithoutTDSCertificateReceivableForGL(GenJournalLine, Customer."No.", GLAccount."No.", VoucherType::"Journal Voucher",
                                                                        '', Location.Code);
        Storage.Set('DocumentNo', GenJournalLine."Document No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify  for TDS Certificate Receivable on Assign TDS Certificate Page
        AssignCertifcate(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,CertificateUpdateDetials,VoucherAccountDebit')]
    procedure CheckInCaseOfCertificateReceivableIsFalseInCashReceiptJournal()
    var
        Customer: Record Customer;
        Location: Record Location;
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        AccountType: Enum "Gen. Journal Account Type";
        VoucherType: Enum "Gen. Journal Template Type";
    begin
        // [Senerio 357243] [Check if the system is generating entry in Update TDS Cert. Details window when check mark is not placed  in TDS Certificate receivable field in Cash Receipt Journals - TDSC056]
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());
        CreateGLAccWithVoucherAccount(AccountType::"G/L Account", VoucherType::"Cash Receipt Voucher", GLAccount, Location);

        // [WHEN] Create and Post Cash Receipt Voucher
        LibraryTDSCustomer.CreateGenJournalLineWithoutTDSCertificateReceivableForGL(GenJournalLine, Customer."No.", GLAccount."No.", VoucherType::"Cash Receipt Voucher",
                                                                        '', Location.Code);
        Storage.Set('DocumentNo', GenJournalLine."Document No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify  for TDS Certificate Receivable on Update TDS Certificate Page
        UpdateCertificate(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,CertificateAssignHandler,VoucherAccountDebit')]
    procedure CheckInAssingTDSCaseOfCertificateReceivableIsTrueInCashReceiptJournal()
    var
        Customer: Record Customer;
        Location: Record Location;
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        // [Senerio 357244] [Check if the system is generating  entry in Assign TDS Cert. Details window when check mark is placed  in TDS Certificate receivable field in Cash Receipt Journals -TDSC057]
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());
        CreateGLAccWithVoucherAccount(AccountType::"G/L Account", VoucherType::"Cash Receipt Voucher", GLAccount, Location);

        // [WHEN] Create and Post Cash Receipt Voucher
        LibraryTDSCustomer.CreateGenJournalLineWithTDSCertificateReceivableForGL(GenJournalLine, Customer."No.", GLAccount."No.", VoucherType::"Cash Receipt Voucher",
                                                                        TDSPostingSetup."TDS Section", Location.Code);
        Storage.Set('DocumentNo', GenJournalLine."Document No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify  for TDS Certificate Receivable on Assing TDS Certificate Page
        AssignCertifcate(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,CertificateAssignHandlerView,VoucherAccountDebit')]
    procedure CheckInAssingTDSCaseOfCertificateReceivableIsFalseInCashReceiptJournal()
    var
        Customer: Record Customer;
        Location: Record Location;
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        VoucherType: Enum "Gen. Journal Template Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        // [Senerio 357245][Check if the system is generating  entry in Assign TDS Cert. Details window when check mark is not placed in TDS Certificate receivable field in Cash Receipt Journals -TDSC058]
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", ConcessionalCode.Code, WorkDate());
        CreateGLAccWithVoucherAccount(AccountType::"G/L Account", VoucherType::"Cash Receipt Voucher", GLAccount, Location);

        // [WHEN] Create and Post Cash Receipt Voucher
        LibraryTDSCustomer.CreateGenJournalLineWithoutTDSCertificateReceivableForGL(GenJournalLine, Customer."No.", GLAccount."No.", VoucherType::"Cash Receipt Voucher",
                                                                        '', Location.Code);
        Storage.Set('DocumentNo', GenJournalLine."Document No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify  for TDS Certificate Receivable on Assing TDS Certificate Page
        AssignCertifcate(Customer."No.", TDSPostingSetup."TDS Section");
    end;


    [Test]
    [HandlerFunctions('TaxRatePageHandler,DisplayCertificateAssignPage')]
    procedure SalesOrderWithTDSCertReceFlaseWithAssignTDSCertificate()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        DocumentNo: Code[20];
    begin
        // [Senerio 357229]	[Check if the system is generating  entry in Assign TDS Cert. Details window when check mark is not placed  in TDS Certificate receivable field in Sales Order header - TDSC042]
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create and post sales invoice without TDS Certificate receivable
        DocumentNo := LibraryTDSCustomer.CreateAndPostSalesDocumentWithoutTDSCertificateReceivable(
            SalesHeader,
            SalesHeader."Document Type"::Order,
            Customer."No.");

        // [THEN] Verify TDS Certificate Receivable on Update TDS Certificate Page
        Storage.Set('DocumentNo', DocumentNo);
        AssignCertifcate(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,CheckWithoutTDSCertRecOnUpdateTDSCertDetailsPage')]
    procedure SalesInvoiceWithoutTDSCertReceWithUpdateTDSCertificate()
    var
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        //[Senerio 357231][Check if the system is generating entry in Update TDS Cert. Details window when check mark is not placed  in TDS Certificate receivable field in Sales Invoice header - TDSC044]
        //[GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());

        //[WHEN] Create and post sales invoice without TDS Certificate receivable
        DocumentNo := LibraryTDSCustomer.CreateAndPostSalesDocumentWithoutTDSCertificateReceivable(
            SalesHeader,
            SalesHeader."Document Type"::Invoice,
            Customer."No.");

        // [THEN] Verify TDS Certificate Receivable on Update TDS Certificate Page
        LibraryVarStorage.Enqueue(DocumentNo);
        UpdateCertificate(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,AssignHandlerForFlase')]
    procedure SalesInvoiceWithoutTDSCertReceWithAssignTDSCertificate()
    var
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        //[Senerio 357233][Check if the system is generating  entry in Assign TDS Cert. Details window when check mark is not placed  in TDS Certificate receivable field in Sales Invoice header -TDSC046]
        //[GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());

        //[WHEN] Create and post sales invoice without TDS Certificate receivable
        DocumentNo := LibraryTDSCustomer.CreateAndPostSalesDocumentWithoutTDSCertificateReceivable(
            SalesHeader,
            SalesHeader."Document Type"::Invoice,
            Customer."No.");

        // [THEN] Verify TDS Certificate Receivable on Assign TDS Certificate Page
        Storage.Set('DocumentNo', DocumentNo);
        AssignCertifcate(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,CheckTDSCertRecOnUpdateTDSCertDetailsPage')]
    procedure SalesInvoiceWithTDSCertReceWithUpdateTDSCertificate()
    var
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // [Senerio 357230][Check if the system is generating entry in Update TDS Cert. Details window when check mark is placed  in TDS Certificate receivable field in Sales Invoice header -TDSC043]
        // [GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());

        // [WHEN] Create and post sales invoice without TDS Certificate receivable
        DocumentNo := LibraryTDSCustomer.CreateAndPostSalesDocumentWithTDSCertificateReceivable(
            SalesHeader,
            SalesHeader."Document Type"::Invoice,
            Customer."No.");

        // [THEN] Verify TDS Certificate Receivable on Update TDS Certificate Page
        Storage.Set('DocumentNo', DocumentNo);
        UpdateCertificate(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    [Test]
    [HandlerFunctions('TaxRatePageHandler,CertificateAssignHandler')]
    procedure SalesInvoiceWithTDSCertReceWithAssignTDSCertificate()
    var
        Customer: Record Customer;
        ConcessionalCode: Record "Concessional Code";
        TDSPostingSetup: Record "TDS Posting Setup";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        //[Senerio 357232][Check if the system is generating  entry in Assign TDS Cert. Details window when check mark is placed  in TDS Certificate receivable field in Sales Invoice header -TDSC045]
        //[GIVEN] Created Setup for TDS Section, Assessee Code, Customer, TDS Setup, TDS Accounting Period and TDS Rates
        LibraryTDSCustomer.CreateTDSonCustomerSetup(Customer, TDSPostingSetup, ConcessionalCode);
        GetTaxComponentsAndCreateTaxRate(TDSPostingSetup."TDS Section", Customer."Assessee Code", '', WorkDate());

        //[WHEN] Create and post sales invoice without TDS Certificate receivable
        DocumentNo := LibraryTDSCustomer.CreateAndPostSalesDocumentWithTDSCertificateReceivable(
            SalesHeader,
            SalesHeader."Document Type"::Invoice,
            Customer."No.");

        //[THEN] Verify TDS Certificate Receivable on Assign TDS Certificate Page
        LibraryVarStorage.Enqueue(DocumentNo);
        AssignCertifcate(Customer."No.", TDSPostingSetup."TDS Section");
    end;

    [PageHandler]
    procedure CheckTDSCertRecOnUpdateTDSCertDetailsPage(var UpdateTDSCertDetails: TestPage "Update TDS Cert. Details")
    var
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
    begin
        DocumentNo := Storage.Get('DocumentNo');
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
        Assert.ExpectedError(RowNotFoundErr);
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; VAR Reply: Boolean)
    begin
        Reply := TRUE;
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

    local procedure CreateTaxRate()
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
        if IsForeignVendor then begin
            TaxRate.AttributeValue5.SetValue('');
            TaxRate.AttributeValue6.SetValue('');
            TaxRate.AttributeValue7.SetValue('');
        end;
        GenerateTaxComponentsPercentage();
        TaxRate.AttributeValue8.SetValue(TDSPercentage);
        TaxRate.AttributeValue9.SetValue(NonPANTDSPercentage);
        TaxRate.AttributeValue10.SetValue(SurchargePercentage);
        TaxRate.AttributeValue11.SetValue(eCessPercentage);
        TaxRate.AttributeValue12.SetValue(SHECessPercentage);
        TaxRate.AttributeValue13.SetValue(TDSThresholdAmount);
        TaxRate.AttributeValue14.SetValue(SurchargeThresholdAmount);
        if IsWorkTax then begin
            TaxRate.AttributeValue15.SetValue('');
            TaxRate.AttributeValue16.SetValue('');
        end;
        TaxRate.OK().Invoke();
    end;

    local procedure UpdateCertificate(CustomerCode: Code[20]; TDSSection: Code[10])
    var
        UpdateCertifcate: TestPage "Update TDS Certificate Details";
        Year: Integer;
    begin
        UpdateCertifcate.OpenEdit();
        UpdateCertifcate.CustomerNo.SetValue("CustomerCode");
        UpdateCertifcate.CertificateNo.SetValue(LibraryUtility.GenerateRandomText(20));
        UpdateCertifcate.CertificateDate.SetValue(LibraryUtility.GenerateRandomDate(WorkDate(), CALCDATE('<1Y>', Today)));
        UpdateCertifcate.CertificateAmount.SetValue(LibraryRandom.RandDec(100000, 2));
        Year := DATE2DMY(WorkDate(), 3);
        UpdateCertifcate.FinancialYear.SetValue(Year);
        UpdateCertifcate.TDSSection.SetValue(TDSSection);
        UpdateCertifcate."Update TDS Cert. Details".Invoke();
    end;

    local procedure UpdateAndRectifyCertificate(CustomerCode: Code[20]; TDSSection: Code[10])
    var
        UpdateCertifcate: TestPage "Update TDS Certificate Details";
        Year: Integer;
    begin
        UpdateCertifcate.OpenEdit();
        UpdateCertifcate.CustomerNo.SetValue("CustomerCode");
        UpdateCertifcate.CertificateNo.SetValue(LibraryUtility.GenerateRandomText(20));
        UpdateCertifcate.CertificateDate.SetValue(LibraryUtility.GenerateRandomDate(WorkDate(), CALCDATE('<1Y>', Today)));
        UpdateCertifcate.CertificateAmount.SetValue(LibraryRandom.RandDec(100000, 2));
        Year := DATE2DMY(WorkDate(), 3);
        UpdateCertifcate.FinancialYear.SetValue(Year);
        UpdateCertifcate.TDSSection.SetValue(TDSSection);
        UpdateCertifcate."Update TDS Cert. Details".Invoke();
        UpdateCertifcate."Rectify TDS Cert. Details".Invoke();
    end;

    local procedure UpdateAndAssignCertificate(CustomerCode: Code[20]; TDSSection: Code[10])
    var
        UpdateCertifcate: TestPage "Update TDS Certificate Details";
        Year: Integer;
    begin
        UpdateCertifcate.OpenEdit();
        UpdateCertifcate.CustomerNo.SetValue("CustomerCode");
        UpdateCertifcate.CertificateNo.SetValue(LibraryUtility.GenerateRandomText(20));
        UpdateCertifcate.CertificateDate.SetValue(LibraryUtility.GenerateRandomDate(WorkDate(), CALCDATE('<1Y>', Today)));
        UpdateCertifcate.CertificateAmount.SetValue(LibraryRandom.RandDec(100000, 2));
        Year := DATE2DMY(WorkDate(), 3);
        UpdateCertifcate.FinancialYear.SetValue(Year);
        UpdateCertifcate.TDSSection.SetValue(TDSSection);
        UpdateCertifcate."Update TDS Cert. Details".Invoke();
        UpdateCertifcate."Assign TDS Cert. Details".Invoke();
    end;

    local procedure AssignCertifcate(CustomerCode: Code[20]; TDSSection: Code[10])
    var
        UpdateCertifcate: TestPage "Update TDS Certificate Details";
        Year: Integer;
    begin
        UpdateCertifcate.OpenEdit();
        UpdateCertifcate.CustomerNo.SetValue(CustomerCode);
        UpdateCertifcate.CertificateNo.SetValue(LibraryUtility.GenerateRandomText(20));
        UpdateCertifcate.CertificateDate.SetValue(LibraryUtility.GenerateRandomDate(WorkDate(), CALCDATE('<1Y>', Today)));
        UpdateCertifcate.CertificateAmount.SetValue(LibraryRandom.RandDec(100, 2));
        Year := DATE2DMY(WorkDate(), 3);
        UpdateCertifcate.FinancialYear.SetValue(Year);
        UpdateCertifcate.TDSSection.SetValue(TDSSection);
        UpdateCertifcate."Assign TDS Cert. Details".Invoke();
    end;

    local procedure CreateBankAccWithVoucherAccount(AccountType: Enum "Gen. Journal Account Type";
                        VoucherType: enum "Gen. Journal Template Type"; var BankAccount: Record "Bank Account"; var Location: Record Location): Code[20]
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryTDSCustomer.CreateLocationWithTANNo(Location);
        StorageEnum.Set('AccountType', format(AccountType));
        Storage.Set('AccountNo', BankAccount."No.");
        CreateVoucherAccountSetup(VoucherType, Location.Code);
        exit(BankAccount."No.");
    end;

    local procedure CreateGLAccWithVoucherAccount(AccountType: Enum "Gen. Journal Account Type";
                    VoucherType: enum "Gen. Journal Template Type"; var GLAccount: Record "G/L Account"; var Location: Record Location): Code[20]
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryTDSCustomer.CreateLocationWithTANNo(Location);
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

    [PageHandler]
    procedure UncheckCertificateUpdatePage(var UpdateTDSCertDetails: TestPage "Update TDS Cert. Details")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
        EntryNo: Integer;
    begin
        EntryNo := LibraryTDSCustomer.GetEntryNo(Storage.Get('DocumentNo'));
        CustLedgerEntry.SetRange("Entry No.", EntryNo);
        if CustLedgerEntry.FindFirst() then
            UpdateTDSCertDetails."TDS Certificate Receivable".SetValue(false);
        LibraryVarStorage.Enqueue(DocumentNo);
    end;

    [PageHandler]
    procedure ViewCertificateUpdatePage(var UpdateTDSCertDetails: TestPage "Update TDS Cert. Details")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryNo: Integer;
    begin
        EntryNo := LibraryTDSCustomer.GetEntryNo(Storage.Get('DocumentNo'));
        CustLedgerEntry.SetRange("Entry No.", EntryNo);
        if CustLedgerEntry.FindFirst() then
            UpdateTDSCertDetails.GoToRecord(CustLedgerEntry);
    end;

    [PageHandler]
    procedure CertificateUpdatePage(var UpdateTDSCertDetails: TestPage "Update TDS Cert. Details")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryNo: Integer;
    begin
        EntryNo := LibraryTDSCustomer.GetEntryNo(Storage.Get('DocumentNo'));
        CustLedgerEntry.SetRange("Entry No.", EntryNo);
        if CustLedgerEntry.FindFirst() then
            UpdateTDSCertDetails.GoToRecord(CustLedgerEntry);
        UpdateTDSCertDetails."TDS Certificate Received".SetValue(true);
        UpdateTDSCertDetails."Update TDS Cert. Details".Invoke();
    end;

    [PageHandler]
    procedure RectifyTDSCertificate(var RectifyTDSCertDetails: TestPage "Rectify TDS Cert. Details")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryNo: Integer;
    begin
        EntryNo := LibraryTDSCustomer.GetEntryNo(Storage.Get('DocumentNo'));
        CustLedgerEntry.SetRange("Entry No.", EntryNo);
        if CustLedgerEntry.FindFirst() then
            RectifyTDSCertDetails.GoToRecord(CustLedgerEntry);
        RectifyTDSCertDetails."TDS Certificate Received".SetValue(false);
    end;

    [PageHandler]
    procedure RectifyTDSCertificateFalse(var RectifyTDSCertDetails: TestPage "Rectify TDS Cert. Details")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryNo: Integer;
    begin
        EntryNo := LibraryTDSCustomer.GetEntryNo(Storage.Get('DocumentNo'));
        CustLedgerEntry.SetRange("Entry No.", EntryNo);
        if CustLedgerEntry.FindFirst() then
            RectifyTDSCertDetails.GoToRecord(CustLedgerEntry);
        RectifyTDSCertDetails."TDS Certificate Received".SetValue(false);
    end;

    [PageHandler]
    procedure RectifyTDSCertificateView(var RectifyTDSCertDetails: TestPage "Rectify TDS Cert. Details")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryNo: Integer;
    begin
        EntryNo := LibraryTDSCustomer.GetEntryNo(Storage.Get('DocumentNo'));
        CustLedgerEntry.SetRange("Entry No.", EntryNo);
        if CustLedgerEntry.FindFirst() then
            RectifyTDSCertDetails.GoToRecord(CustLedgerEntry);
    end;

    [PageHandler]
    procedure CertificateUpdateDetials(var UpdateTDSCertDetails: TestPage "Update TDS Cert. Details")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryNo: Integer;
    begin
        EntryNo := LibraryTDSCustomer.GetEntryNo(Storage.Get('DocumentNo'));
        CustLedgerEntry.SetRange("Entry No.", EntryNo);
        CustLedgerEntry.FindFirst();
        asserterror UpdateTDSCertDetails.GoToRecord(CustLedgerEntry);
        LibAssert.ExpectedError(RowNotFoundErr);
    end;

    [PageHandler]
    procedure DisplayCertificateAssignPage(var AssignTDSCertDetails: TestPage "Assign TDS Cert. Details")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryNo: Integer;
    begin
        EntryNo := LibraryTDSCustomer.GetEntryNo(Storage.Get('DocumentNo'));
        CustLedgerEntry.Reset();
        CustLedgerEntry.SetRange("Entry No.", EntryNo);
        CustLedgerEntry.FindFirst();
        AssignTDSCertDetails.GoToRecord(CustLedgerEntry);
    end;

    [PageHandler]
    procedure DisplayCertificateAssignPageReceived(var AssignTDSCertDetails: TestPage "Assign TDS Cert. Details")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryNo: Integer;
    begin
        EntryNo := LibraryTDSCustomer.GetEntryNo(Storage.Get('DocumentNo'));
        CustLedgerEntry.SetRange("Entry No.", EntryNo);
        CustLedgerEntry.FindFirst();
        AssignTDSCertDetails.GoToRecord(CustLedgerEntry);
        AssignTDSCertDetails."TDS Certificate Receivable".SetValue(true);
        AssignTDSCertDetails.Close();
    end;

    [PageHandler]
    procedure CertificateAssignHandlerView(var AssignTDSCertDetails: TestPage "Assign TDS Cert. Details")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryNo: Integer;
    begin
        EntryNo := LibraryTDSCustomer.GetEntryNo(Storage.Get('DocumentNo'));
        CustLedgerEntry.SetRange("Entry No.", EntryNo);
        CustLedgerEntry.FindFirst();
        AssignTDSCertDetails.GoToRecord(CustLedgerEntry);
    end;


    [PageHandler]
    procedure CertificateAssignHandler(var AssignTDSCertDetails: TestPage "Assign TDS Cert. Details")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryNo: Integer;
    begin
        EntryNo := LibraryTDSCustomer.GetEntryNo(Storage.Get('DocumentNo'));
        CustLedgerEntry.SetRange("Entry No.", EntryNo);
        CustLedgerEntry.FindFirst();
        asserterror AssignTDSCertDetails.GoToRecord(CustLedgerEntry);
        LibAssert.ExpectedError(RowNotFoundErr);
    end;

    [PageHandler]
    procedure AssignHandlerForFlase(var AssignTDSCertDetails: TestPage "Assign TDS Cert. Details")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryNo: Integer;
    begin
        EntryNo := LibraryTDSCustomer.GetEntryNo(Storage.Get('DocumentNo'));
        CustLedgerEntry.SetRange("Entry No.", EntryNo);
        CustLedgerEntry.FindFirst();
        AssignTDSCertDetails.GoToRecord(CustLedgerEntry);
    end;

    var
        LibraryVarStorage: Codeunit "Library - Variable Storage";
        LibraryTDSCustomer: Codeunit "Library TDS On Customer";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibAssert: Codeunit "Library Assert";
        Section: Code[10];
        TDSAssesseeCode: Code[10];
        TDSConcessionalCode: Code[10];
        WorkTaxNatureOfDeduction: Code[10];
        NatureOfRemittance: Code[10];
        ActApplicable: Code[10];
        CountryCode: Code[10];
        TDSEffectiveDate: Date;
        TDSPercentage: Decimal;
        NonPANTDSPercentage: Decimal;
        SurchargePercentage: Decimal;
        eCessPercentage: Decimal;
        SHECessPercentage: Decimal;
        TDSThresholdAmount: Decimal;
        SurchargeThresholdAmount: Decimal;
        WorkTaxParcentage: Decimal;
        IsWorkTax: Boolean;
        IsForeignVendor: Boolean;
        Storage: Dictionary of [Text, Code[20]];
        StorageEnum: Dictionary of [Text, Text];
        CertifcateValidationErr: Label 'TDS Certificate Receivable is false';
        RowNotFoundErr: Label 'The row does not exist on the TestPage.';
}