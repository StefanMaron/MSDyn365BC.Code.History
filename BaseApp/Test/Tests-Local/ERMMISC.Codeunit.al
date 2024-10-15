codeunit 144018 "ERM MISC"
{
    // 1. Verify Transaction Mode Code and Bank Account Code after Posting Service Order.
    // 2. Verify Transaction Mode Code and Bank Account Code after Posting Service Invoice.
    // 3. Verify Transaction Mode Code and Bank Account Code after Posting Service Credit Memo.
    // 4. Verify Payment Discount after posting Sales Return Order.
    // 5. Verify Payment Discount after posting Purchase Return Order.
    // 
    // Covers Test Cases for WI -  341960
    // ----------------------------------------------------------------------------------------------
    // Test Function Name                                                                      TFS ID
    // ----------------------------------------------------------------------------------------------
    // CustomerLedgerEntryAfterPostServiceOrder                                                217682
    // CustomerLedgerEntryAfterPostServiceInvoice                                              217684
    // CustomerLedgerEntryAfterPostServiceCreditMemo                                           217685
    // GLEntryAfterPostSalesReturnOrder                                                        242420
    // GLEntryAfterPostPurchaseReturnOrder                                                     242421

    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        AmountError: Label '%1 must be %2 in %3.';
        FileManagement: Codeunit "File Management";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryNLLocalization: Codeunit "Library - NL Localization";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        isInitialized: Boolean;
        EntryExitPointErr: Label 'Reported Entry/Exit Point is incorrect.';
        AdvChecklistErr: Label 'There are one or more errors. For details, see the journal error FactBox.';

    [Test]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntryAfterPostServiceOrder()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Purpose of this test is to validate Transaction Mode Code and Bank Account Code in Table 21 - Cust. Ledger Entry with Service Order.
        CreateAndPostServiceDocument(ServiceHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntryAfterPostServiceInvoice()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Purpose of this test is to validate Transaction Mode Code and Bank Account Code in Table 21 - Cust. Ledger Entry with Service Invoice.
        CreateAndPostServiceDocument(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntryAfterPostServiceCreditMemo()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Purpose of this test is to validate Transaction Mode Code and Bank Account Code in Table 21 - Cust. Ledger Entry with Service Credit Memo.
        CreateAndPostServiceDocument(ServiceHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('CreateIntrastatDeclDiskReqPageHandler')]
    [Scope('OnPrem')]
    procedure VatRegistrationNoInIntrastatFile()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FileTempBlob: Codeunit "Temp Blob";
        FileInStream: InStream;
        FileLine: Text;
        CountryCode: Code[10];
    begin
        // [FEATURE] [Intrastat] [Export]
        // [SCENARIO 379343] : Create Intrastat decl. with length of "Company Information"."VAT Registration No." field 14 characters
        Initialize();

        // [GIVEN] VAT Registration No of 14 symbol length in Company Information
        CountryCode := SetIntrastatDataOnCompanyInfo;

        // [GIVEN] Intrastat Journal with One Intrastat Journal Line
        CreateSimpleIntrastatJnlTemplateAndBatch(IntrastatJnlBatch);
        CreateIntrastatJnlLineWithMandatoryFields(IntrastatJnlLine,
          IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name, CountryCode);

        // [WHEN] Create Intrastat Declaration Disc
        RunIntrastatMakeDiskTaxAuth2022(FileTempBlob, true);

        // [THEN] We have LAST 12 characters "VAT Registration No." from 5 position in Header and from 8 position in lines in intrastat declaration file.
        FileTempBlob.CreateInStream(FileInStream);
        FileInStream.ReadText(FileLine);
        Assert.AreEqual(GetExpectedVATRegNo, CopyStr(FileLine, 5, 12), '');

        FileInStream.ReadText(FileLine);
        Assert.AreEqual(GetExpectedVATRegNo, CopyStr(FileLine, 8, 12), '');
    end;

    local procedure CreateAndPostServiceDocument(DocumentType: Enum "Service Document Type")
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup: Create and Post Service Document with Transaction Mode Code and Bank Account Code.
        Initialize();
        CreateServiceDocument(ServiceHeader, DocumentType, CreateItem);

        // Exercise.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);  // Post as Ship and Invoice.

        // Verify: Verify Transaction Mode Code and Bank Account Code in Customer Ledger Entry.
        VerifyTransacModeCodeAndBankAccCodeInCustLedgEntry(ServiceHeader);
    end;

    [Test]
    [HandlerFunctions('GenJournalTemplListCBGPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostSalesReturnOrder()
    var
        CBGStatementLine: Record "CBG Statement Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        Amount: Decimal;
    begin
        // Purpose of this test is to Verify Payment Discount can be calculated when Document Type = Credit Memo & using the column Applies-To Doc No. in Bank/Giro journal line with posting Sales Return Order.

        // Setup: Create and Post Sales Return Order.
        Initialize();
        Amount := CreateAndPostSalesReturnOrder(SalesHeader);
        SalesCrMemoHeader.SetRange("Return Order No.", SalesHeader."No.");
        SalesCrMemoHeader.FindFirst();
        CreateAndPostBankGiroJournalAndVerifyGLEntry(
          CBGStatementLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", SalesCrMemoHeader."No.", Amount);
    end;

    [Test]
    [HandlerFunctions('GenJournalTemplListCBGPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostPurchaseReturnOrder()
    var
        CBGStatementLine: Record "CBG Statement Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseHeader: Record "Purchase Header";
        Amount: Decimal;
    begin
        // Purpose of this test is to Verify Payment Discount can be calculated when Document Type = Credit Memo & using the column Applies-To Doc No. in Bank/Giro journal line with posting Purchase Return Order.

        // Setup: Create and Post Purchase Return Order.
        Initialize();
        Amount := CreateAndPostPurchaseReturnOrder(PurchaseHeader);
        PurchCrMemoHdr.SetRange("Return Order No.", PurchaseHeader."No.");
        PurchCrMemoHdr.FindFirst();
        CreateAndPostBankGiroJournalAndVerifyGLEntry(
          CBGStatementLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", PurchCrMemoHdr."No.", Amount);
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure GLAccWhereUsedBankAccountPostingGroup()
    var
        GLAccount: Record "G/L Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        CalcGLAccWhereUsed: Codeunit "Calc. G/L Acc. Where-Used";
    begin
        // [FEATURE] [G/L Account Where-Used]
        // [SCENARIO 251566] Bank Account Posting Group should be shown on Where-Used page
        Initialize();

        // [GIVEN] Bank Account Posting Group with "Acc.No. Pmt./Rcpt. in Process" = "G"
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Direct Posting", false);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
        LibraryERM.CreateBankAccountPostingGroup(BankAccountPostingGroup);
        BankAccountPostingGroup.Validate("Acc.No. Pmt./Rcpt. in Process", GLAccount."No.");
        BankAccountPostingGroup.Modify(true);

        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(BankAccountPostingGroup.FieldName("Acc.No. Pmt./Rcpt. in Process"));

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(BankAccountPostingGroup."Acc.No. Pmt./Rcpt. in Process");

        // [THEN] Bank Account Posting Group is shown on "G/L Account Where-Used List"
        // Verify in WhereUsedHandler

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure GLAccWhereUsedBankAccountPostingGroupW1AndLocalFieldAndW1Table()
    var
        GLAccount: Record "G/L Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        CustomerPostingGroup: Record "Customer Posting Group";
        TransactionMode: Record "Transaction Mode";
        CalcGLAccWhereUsed: Codeunit "Calc. G/L Acc. Where-Used";
    begin
        // [FEATURE] [G/L Account Where-Used]
        // [SCENARIO 251566] G/L Account is shown for all fields in the same table and in another table
        Initialize();

        // [GIVEN] G/L Account "G" is used in Bank Account Posting Group as "Acc.No. Pmt./Rcpt. in Process" and "G/L Account No."
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Direct Posting", false);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
        LibraryERM.CreateBankAccountPostingGroup(BankAccountPostingGroup);
        BankAccountPostingGroup.Validate("G/L Account No.", GLAccount."No.");
        BankAccountPostingGroup.Validate("Acc.No. Pmt./Rcpt. in Process", GLAccount."No.");
        BankAccountPostingGroup.Modify(true);

        // [GIVEN] G/L Account "G" is used in Customer Posting Group as "Receivables Account"
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup.Validate("Receivables Account", GLAccount."No.");
        CustomerPostingGroup.Modify(true);

        // [GIVEN] Transaction Mode has "Acc. No. Pmt./Rcpt. in Process" = "G"
        LibraryNLLocalization.CreateTransactionMode(TransactionMode, TransactionMode."Account Type"::Customer);
        TransactionMode.Validate("Acc. No. Pmt./Rcpt. in Process", GLAccount."No.");
        TransactionMode.Modify(true);

        LibraryVariableStorage.Enqueue(4);
        LibraryVariableStorage.Enqueue(BankAccountPostingGroup.FieldName("G/L Account No."));
        LibraryVariableStorage.Enqueue(BankAccountPostingGroup.FieldName("Acc.No. Pmt./Rcpt. in Process"));
        LibraryVariableStorage.Enqueue(CustomerPostingGroup.FieldName("Receivables Account"));
        LibraryVariableStorage.Enqueue(TransactionMode.FieldName("Acc. No. Pmt./Rcpt. in Process"));

        // [WHEN] Run Where-Used function for G/L Account "G"
        CalcGLAccWhereUsed.CheckGLAcc(GLAccount."No.");

        // [THEN] Bank Account Posting Group is shown on "G/L Account Where-Used List" with local and W1 field
        // [THEN] Customer Posting Group is shown on "G/L Account Where-Used List"
        // [THEN] Transaction Mode is shown on "G/L Account Where-Used List"

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CBGStatementNoWhenInsertNewRecordForNewTemplate()
    var
        CBGStatement: Record "CBG Statement";
    begin
        // [FEATURE] [UT] [Bank/Giro Journal] [CBG Statement]
        // [SCENARIO 271072] When insert CBG Statement for new Template, then CBG Statement."No." always equals to 1
        Initialize();

        // [GIVEN] Init CBG Statement with "Journal Template Name" = new Gen Journal Template and "No." = 1001
        CBGStatement.Init();
        CBGStatement.Validate("Journal Template Name", CreateGenJournalTemplateWithBankAccount(CreateBankAccountNo));
        CBGStatement.Validate("No.", LibraryRandom.RandIntInRange(1000, 2000));

        // [WHEN] Insert CBG Statement
        CBGStatement.Insert(true);

        // [THEN] CBG Statement "No." = 1
        CBGStatement.TestField("No.", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CBGStatementNoWhenInsertNewRecord()
    var
        CBGStatement: Record "CBG Statement";
        GenJnlTemplateName: Code[10];
        FirstCBGStatementNo: Integer;
        SecondCBGStatementNo: Integer;
    begin
        // [FEATURE] [Bank/Giro Journal] [CBG Statement]
        // [SCENARIO 271072] When insert new CBG Statement for the Template, then CBG Statement."No." = Last CBG Statement "No." for the same Template increased by 1.
        Initialize();

        // [GIVEN] Gen. Journal Template "T"
        GenJnlTemplateName := CreateGenJournalTemplateWithBankAccount(CreateBankAccountNo);

        // [GIVEN] CBG Statement with Journal Template Name = "T" and "No." = 1;
        FirstCBGStatementNo := CreateCBGStatementWithTemplate(GenJnlTemplateName);

        // [GIVEN] CBG Statement with Journal Template Name = "T" and "No." = 2;
        SecondCBGStatementNo := CreateCBGStatementWithTemplate(GenJnlTemplateName);

        // [GIVEN] Deleted CBG Statement with "No." = 1
        DeleteCBGStatement(GenJnlTemplateName, FirstCBGStatementNo);

        // [GIVEN] New CBG Statement with Journal Template Name = "T"
        CBGStatement.Init();
        CBGStatement.Validate("Journal Template Name", GenJnlTemplateName);

        // [WHEN] Insert new CBG Statement
        CBGStatement.Insert(true);

        // [THEN] New CBG Statement "No." = 3
        CBGStatement.TestField("No.", SecondCBGStatementNo + 1);
    end;

    [Test]
    [HandlerFunctions('GenJournalTemplListCBGPageHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalWhenCreateNewFromTemplate()
    var
        BankGiroJournal: TestPage "Bank/Giro Journal";
        BankAccountNo: Code[20];
    begin
        // [FEATURE] [UI] [Bank/Giro Journal]
        // [SCENARIO 271072] Stan creates new Bank/Giro Journal from template without errors on Bank/Giro Journal page
        Initialize();

        // [GIVEN] Bank Account "B"
        BankAccountNo := CreateBankAccountNo;

        // [GIVEN] Gen Journal Template with Bal. Account = "B"
        LibraryVariableStorage.Enqueue(CreateGenJournalTemplateWithBankAccount(BankAccountNo));

        // [GIVEN] Stan pushed "New" on page Bank/Giro Journal List
        BankGiroJournal.OpenNew();

        // [GIVEN] Page Gen. Journal Templ. List (CBG) opened and Stan selected Template on page
        // Selection is done in GenJournalTemplListCBGPageHandler

        // [WHEN] Stan pushes OK on page Gen. Journal Templ. List (CBG)
        // Selection is done in GenJournalTemplListCBGPageHandler

        // [THEN] Page Bank/Giro Journal opens with "Account No." = "B" and "No." = 0
        BankGiroJournal."Account No.".AssertEquals(BankAccountNo);
        BankGiroJournal."No.".AssertEquals(0);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('GenJournalTemplListCBGPageHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalUpdateNoWhenInsertCBGStatement()
    var
        CBGStatement: Record "CBG Statement";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        GenJnlTemplateName: Code[10];
    begin
        // [FEATURE] [UI] [Bank/Giro Journal]
        // [SCENARIO 271072] No is updated on Bank/Giro Journal page when CBG Statement is inserted
        Initialize();

        // [GIVEN] Stan created new Bank/Giro Journal from new Template
        GenJnlTemplateName := CreateGenJournalTemplateWithBankAccount(CreateBankAccountNo);
        LibraryVariableStorage.Enqueue(GenJnlTemplateName);
        BankGiroJournal.OpenNew();

        // [WHEN] Stan switches to field "Opening Balance"
        BankGiroJournal."Opening Balance".SetValue(LibraryRandom.RandDecInRange(10, 20, 2));

        // [THEN] CBG Statement with No. = 1 is inserted for new Template
        CBGStatement.SetRange("Journal Template Name", GenJnlTemplateName);
        CBGStatement.FindLast();
        CBGStatement.TestField("No.", 1);

        // [THEN] Stan can see No. = 1 on Bank/Giro Journal page
        BankGiroJournal."No.".AssertEquals(CBGStatement."No.");

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CreateIntrastatDeclDiskReqPageHandler')]
    [Scope('OnPrem')]
    procedure EmptyEntryExitPointInIntrastatFile()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FileTempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Intrastat] [Export]
        // [SCENARIO 345161] Create Intrastat Decl. with an empty "Entry/Exit Point" on Intrastat Jnl. Line
        Initialize();

        // [GIVEN] Prepare Intrastat Journal with one Intrastat Journal Line
        CreateSimpleIntrastatJnlTemplateAndBatch(IntrastatJnlBatch);
        CreateIntrastatJnlLineWithMandatoryFields(IntrastatJnlLine,
          IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name, SetIntrastatDataOnCompanyInfo);

        // [GIVEN] Set an empty "Entry/Exit Point" on Intrastat Jnl. Line
        IntrastatJnlLine.Validate("Entry/Exit Point", '');
        IntrastatJnlLine.Modify(true);
        Commit();
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Create Intrastat Declaration Disc
        RunIntrastatMakeDiskTaxAuth2022(FileTempBlob, true);

        // [THEN] "Entry/Exit Point" in reported file equals '00'
        Assert.AreEqual('00', GetEntryExitPointFromDeclarationFile(FileTempBlob), EntryExitPointErr);
    end;

    [Test]
    [HandlerFunctions('CreateIntrastatDeclDiskReqPageHandler')]
    [Scope('OnPrem')]
    procedure FilledEntryExitPointInIntrastatFile()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FileTempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Intrastat] [Export]
        // [SCENARIO 345161] Create Intrastat Decl. with a filled "Entry/Exit Point" on Intrastat Jnl. Line
        Initialize();

        // [GIVEN] Prepare Intrastat Journal with one Intrastat Journal Line, which "Entry/Exit Point" equals 'XX'
        CreateSimpleIntrastatJnlTemplateAndBatch(IntrastatJnlBatch);
        CreateIntrastatJnlLineWithMandatoryFields(IntrastatJnlLine,
          IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name, SetIntrastatDataOnCompanyInfo);
        Commit();
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Create Intrastat Declaration Disc
        RunIntrastatMakeDiskTaxAuth2022(FileTempBlob, true);

        // [THEN] "Entry/Exit Point" in reported file equals 'XX'
        Assert.AreEqual(
          CopyStr(IntrastatJnlLine."Entry/Exit Point", 1, 2),
          GetEntryExitPointFromDeclarationFile(FileTempBlob),
          EntryExitPointErr);
    end;

    [Test]
    [HandlerFunctions('CreateIntrastatDeclDiskReqPageHandler')]
    [Scope('OnPrem')]
    procedure PartnerIDInShipmentIntrastatFileCounterpartyFalse()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FileTempBlob: Codeunit "Temp Blob";
        CountryRegion: Record "Country/Region";
    begin
        // [FEATURE] [Intrastat] [Create Intrastat Decl. Disk] [Export] [Shipment]
        // [SCENARIO 376893] Create Intrastat Decl. with "Partner VAT ID" in shipment Intrastat Jnl. Line when Counterparty = false
        // [SCENARIO 400682] Zero Special Unit value is exported with "+" sign
        Initialize();

        // [GIVEN] Prepare shipment Intrastat Journal Line whith "Partner VAT ID" = 'NL23456789456' and Transaction Specification = '12'
        PrepareIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment);

        // [WHEN] Run Create Intrastat Declaration Disc with Counterparty = true
        RunIntrastatMakeDiskTaxAuth2022(FileTempBlob, true);

        // [THEN] Intrastat Declaration is created with Transaction = '12' and 'Partner ID' = 'NL23456789456'
        CountryRegion.Get(IntrastatJnlLine."Country/Region of Origin Code");
        VerifyTransactionAndPatnerIDInDeclarationFile(
          FileTempBlob, PadStr('', 17 - StrLen(IntrastatJnlLine."Partner VAT ID"), ' ') + IntrastatJnlLine."Partner VAT ID",
          CountryRegion."Intrastat Code", '+');
    end;

    [Test]
    [HandlerFunctions('CreateIntrastatDeclDiskReqPageHandler')]
    [Scope('OnPrem')]
    procedure PartnerIDInShipmentIntrastatFileCounterpartyTrue()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        CountryRegion: Record "Country/Region";
        FileTempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Intrastat] [Create Intrastat Decl. Disk] [Export] [Shipment]
        // [SCENARIO 376893] Create Intrastat Decl. with "Partner VAT ID" in shipment Intrastat Jnl. Line when Counterparty = true
        // [SCENARIO 391946] Transaction Type is exported blanked
        // [SCENARIO 394821] Transaction Specification and Partner VAT ID values are exported
        // [SCENARIO 394821] Country/Region of Origin code is taken from non-blanked CountryRegion."Intrastat Code"
        Initialize();

        // [GIVEN] Prepare shipment Intrastat Journal Line whith "Partner VAT ID" = 'NL0123456789' and Transaction Specification = '12'
        PrepareIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment);

        // [WHEN] Run Create Intrastat Declaration Disc with Counterparty = true
        RunIntrastatMakeDiskTaxAuth2022(FileTempBlob, true);

        // [THEN] Intrastat Declaration is created with Transaction = '12' and 'Partner ID' = '     NL0123456789'
        // [THEN] Intrastat Code is exported as Country of Origin (TFS 391822)
        CountryRegion.Get(IntrastatJnlLine."Country/Region of Origin Code");
        VerifyTransactionAndPatnerIDInDeclarationFile(
          FileTempBlob,
          PadStr('', 17 - StrLen(IntrastatJnlLine."Partner VAT ID"), ' ') + IntrastatJnlLine."Partner VAT ID",
          CountryRegion."Intrastat Code", '+');
    end;

    [Test]
    [HandlerFunctions('CreateIntrastatDeclDiskReqPageHandler')]
    procedure PartnerIDInShipmentIntrastatFileCounterpartyTrueCountryCodeOrigin()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Item: Record Item;
        CountryRegion: Record "Country/Region";
        FileTempBlob: Codeunit "Temp Blob";
        FileInstream: InStream;
        LineContent: Text;
    begin
        // [FEATURE] [Intrastat] [Create Intrastat Decl. Disk] [Export] [Shipment]
        // [SCENARIO 386323] "Country/Region of Origin" aligned left in exported file
        // [SCENARIO 394821] Country/Region of Origin code is taken from journal "Country/Region of Origin Code"
        // [SCENARIO 394821] in case of blanked "Intrastat Code" value
        Initialize();

        PrepareIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment);
        Item.Get(IntrastatJnlLine."Item No.");
        Item.Validate("Country/Region of Origin Code", CreateCountryRegionCode());
        Item.Modify(true);
        IntrastatJnlLine.Validate("Country/Region of Origin Code", Item."Country/Region of Origin Code");
        IntrastatJnlLine.Modify(true);

        CountryRegion.Get(Item."Country/Region of Origin Code");
        CountryRegion."Intrastat Code" := ''; // TFS 394821
        CountryRegion.Modify();

        RunIntrastatMakeDiskTaxAuth2022(FileTempBlob, true);

        FileTempBlob.CreateInStream(FileInstream);
        FileInstream.ReadText(LineContent);
        FileInstream.ReadText(LineContent);

        Assert.ExpectedMessage(
          StrSubstNo('%1 %2', CountryRegion."Intrastat Code", IntrastatJnlLine."Country/Region Code"),
          LineContent);
        VerifyTransactionAndPatnerIDInDeclarationFile(
          FileTempBlob,
          PadStr('', 17 - StrLen(IntrastatJnlLine."Partner VAT ID"), ' ') + IntrastatJnlLine."Partner VAT ID",
          IntrastatJnlLine."Country/Region of Origin Code", '+');
    end;

    [Test]
    [HandlerFunctions('CreateIntrastatDeclDiskReqPageHandler')]
    [Scope('OnPrem')]
    procedure PartnerIDInReceiptIntrastatFileCounterpartyFalse()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FileTempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Intrastat] [Create Intrastat Decl. Disk] [Export] [Receipt]
        // [SCENARIO 389253] Create Intrastat Decl. with "Partner VAT ID" in receipt Intrastat Jnl. Line when Counterparty = false
        // [SCENARIO 391946] Transaction Type value is exported
        Initialize();

        // [GIVEN] Prepare receipt Intrastat Journal Line whith "Partner VAT ID" = 'NL23456789456' and Transaction Specification = '12'
        PrepareIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);

        // [WHEN] Run Create Intrastat Declaration Disc with Counterparty = false
        RunIntrastatMakeDiskTaxAuth2022(FileTempBlob, true);

        // [THEN] Intrastat Declaration is created with Transaction = '12' and 'Partner ID' = '                 '
        VerifyTransactionAndPatnerIDInDeclarationFile(FileTempBlob, '                 ', '  ', '+');
    end;

    [Test]
    [HandlerFunctions('CreateIntrastatDeclDiskReqPageHandler')]
    [Scope('OnPrem')]
    procedure PartnerIDInReceiptIntrastatFileCounterpartyTrue()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        CountryRegion: Record "Country/Region";
        FileTempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Intrastat] [Create Intrastat Decl. Disk] [Export] [Receipt]
        // [SCENARIO 389253] Create Intrastat Decl. with "Partner VAT ID" in receipt Intrastat Jnl. Line when Counterparty = true
        // [SCENARIO 391946] Transaction Type value is exported
        // [SCENARIO 394821] Transaction Specification and Partner VAT ID values are not exported (blanked)
        Initialize();

        // [GIVEN] Prepare receipt Intrastat Journal Line whith "Partner VAT ID" = 'NL0123456789' and Transaction Specification = '12'
        PrepareIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);

        // [WHEN] Run Create Intrastat Declaration Disc with Counterparty = true
        RunIntrastatMakeDiskTaxAuth2022(FileTempBlob, true);

        // [THEN] Intrastat Declaration is created with Transaction = '12' and 'Partner ID' = '     NL0123456789'
        // [THEN] Blanked Intrastat Code is exported as Country of Origin (TFS 391822)
        CountryRegion.Get(IntrastatJnlLine."Country/Region of Origin Code");
        VerifyTransactionAndPatnerIDInDeclarationFile(
          FileTempBlob,
          PadStr('', 17, ' '),
          '  ', '+');
    end;

    [Test]
    [HandlerFunctions('CreateIntrastatDeclDiskReqPageHandler')]
    procedure TransactionSpecificationIsCheckedForShipmentIntrastatFileCounterpartyTrue()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FileTempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Intrastat] [Create Intrastat Decl. Disk] [Export] [Shipment]
        // [SCENARIO 391946] Report 11413 "Create Intrastat Decl. Disk" checks for "Transaction Specification" for shipments when Counterparty = true
        Initialize();

        // [GIVEN] Prepare shipment intrastat journal line with blanked "Transaction Specification"
        PrepareIntrastatJnlLineWithBlankedTransactionSpecification(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment);

        // [WHEN] Run Create Intrastat Declaration Disc with Counterparty = true
        asserterror RunIntrastatMakeDiskTaxAuth2022(FileTempBlob, true);

        // [THEN] Testfield error occurs: "Transaction Specification must have a value"
#if CLEAN19
        VerifyAdvanvedChecklistError(IntrastatJnlLine,IntrastatJnlLine.FieldName("Transaction Specification"));
#else
        VerifyTestfieldChecklistError(IntrastatJnlLine.FieldName("Transaction Specification"));
#endif
    end;


    [Test]
    [HandlerFunctions('IntrastatChecklistRPH')]
    procedure ChecklistReportChecksForTransactionSpecificationForShipments()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat] [Intrastat - Checklist] [Shipment]
        // [SCENARIO 396535] Report 502 "Intrastat - Checklist" checks for "Transaction Specification" for shipments
        Initialize();
        EnableAdvancedChecklist();

        // [GIVEN] Prepare shipment intrastat journal line with blanked "Transaction Specification"
        PrepareIntrastatJnlLineWithBlankedTransactionSpecification(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment);

        // [WHEN] Run "Intrastat - Checklist" report
        RunIntrastatChecklistReport(IntrastatJnlLine);

        // [THEN] Error log contains 1 error: "Transaction Specification must have a value"
        VerifyBatchError(IntrastatJnlLine, IntrastatJnlLine.FieldName("Transaction Specification"));
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistRPH')]
    procedure ChecklistReportChecksForTransactionSpecificationForReceipts()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat] [Intrastat - Checklist] [Receipt]
        // [SCENARIO 396535] Report 502 "Intrastat - Checklist" checks for "Transaction Specification" for receipts
        Initialize();
        EnableAdvancedChecklist();

        // [GIVEN] Prepare receipt intrastat journal line with blanked "Transaction Specification"
        PrepareIntrastatJnlLineWithBlankedTransactionSpecification(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);

        // [WHEN] Run "Intrastat - Checklist" report
        RunIntrastatChecklistReport(IntrastatJnlLine);

        // [THEN] Error log contains 1 error: "Transaction Specification must have a value"
        VerifyBatchError(IntrastatJnlLine, IntrastatJnlLine.FieldName("Transaction Specification"));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatChecklistRPH')]
    procedure ChecklistReportForCorrectionShipmentLine()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Intrastat] [Intrastat - Checklist] [Shipment] [Correction] [UI]
        // [SCENARIO 394971] Report 502 "Intrastat - Checklist" in case of correction for shipments
        // [SCENARIO 395404] Quantity has been printed with negative sign
        // [SCENARIO 396681] Total Weight and Statistical Amount have been printed with negative sign
        // [SCENARIO 396680] Report 594 "Get Item Ledger Entries" creates "Receipt" intrastat journal line with negative amounts
        Initialize();

        // [GIVEN] Posted purchase return order
        CreatePostPurchaseReturnOrderWithSingleLine(ItemNo);

        // [GIVEN] Run "Suggest Lines" from intrastat journal page
        RunSuggestLines(IntrastatJnlLine, ItemNo);

        // [WHEN] Run "Intrastat - Checklist" report
        RunIntrastatChecklistReport(IntrastatJnlLine);

        // [THEN] "Receipt" line type has been printed
        Assert.IsTrue(IntrastatJnlLine.Quantity < 0, 'expected Quantity < 0');
        Assert.IsTrue(IntrastatJnlLine."Total Weight" < 0, 'expected Total Weight < 0');
        Assert.IsTrue(IntrastatJnlLine."Statistical Value" < 0, 'expected Statistical Value < 0');

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('IntrastatJnlLineType', 'Receipt');
        LibraryReportDataset.AssertElementWithValueExists('IntrastatJnlLineQty', IntrastatJnlLine.Quantity); // TFS 395404
        LibraryReportDataset.AssertElementWithValueExists('IntrastatJnlLineTotalWt', IntrastatJnlLine."Total Weight"); // TFS 396681
        LibraryReportDataset.AssertElementWithValueExists('IntrastatJnlLineTotalWt2', ROUND(IntrastatJnlLine."Total Weight", 1)); // TFS 396681
        LibraryReportDataset.AssertElementWithValueExists('IntrastatJnlLinSubTotalWt', ROUND(IntrastatJnlLine."Total Weight", 1)); // TFS 396681
        LibraryReportDataset.AssertElementWithValueExists('IntrastatJnlLineStatVal', IntrastatJnlLine."Statistical Value"); // TFS 396681
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatChecklistRPH')]
    procedure ChecklistReportForCorrectionReceiptLine()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Intrastat] [Intrastat - Checklist] [Receipt] [Correction] [UI]
        // [SCENARIO 394971] Report 502 "Intrastat - Checklist" in case of correction for receipts
        // [SCENARIO 395404] Quantity has been printed with negative sign
        // [SCENARIO 396681] Total Weight and Statistical Amount have been printed with negative sign
        // [SCENARIO 396680] Report 594 "Get Item Ledger Entries" creates "Shipment" intrastat journal line with negative amounts
        Initialize();

        // [GIVEN] Posted sales return order
        CreatePostSalesReturnOrderWithSingleLine(ItemNo);

        // [GIVEN] Run "Suggest Lines" from intrastat journal page
        RunSuggestLines(IntrastatJnlLine, ItemNo);

        // [WHEN] Run "Intrastat - Checklist" report
        RunIntrastatChecklistReport(IntrastatJnlLine);

        // [THEN] "Shipment" line type has been printed
        Assert.IsTrue(IntrastatJnlLine.Quantity < 0, 'expected Quantity < 0');
        Assert.IsTrue(IntrastatJnlLine."Total Weight" < 0, 'expected Total Weight < 0');
        Assert.IsTrue(IntrastatJnlLine."Statistical Value" < 0, 'expected Statistical Value < 0');

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('IntrastatJnlLineType', 'Shipment');
        LibraryReportDataset.AssertElementWithValueExists('IntrastatJnlLineQty', IntrastatJnlLine.Quantity); // TFS 395404
        LibraryReportDataset.AssertElementWithValueExists('IntrastatJnlLineTotalWt', IntrastatJnlLine."Total Weight"); // TFS 396681
        LibraryReportDataset.AssertElementWithValueExists('IntrastatJnlLineTotalWt2', ROUND(IntrastatJnlLine."Total Weight", 1)); // TFS 396681
        LibraryReportDataset.AssertElementWithValueExists('IntrastatJnlLinSubTotalWt', ROUND(IntrastatJnlLine."Total Weight", 1)); // TFS 396681
        LibraryReportDataset.AssertElementWithValueExists('IntrastatJnlLineStatVal', IntrastatJnlLine."Statistical Value"); // TFS 396681
    end;

    [Test]
    [HandlerFunctions('IntrastatFormRPH')]
    procedure IntrastatFormChecksForTransactionSpecificationForShipments()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat] [Intrastat - Form] [Shipments]
        // [SCENARIO 396535] Report 501 "Intrastat - Form" checks for "Transaction Specification" for shipments
        Initialize();
        EnableAdvancedChecklist();

        // [GIVEN] Prepare shipment intrastat journal line with blanked "Transaction Specification"
        PrepareIntrastatJnlLineWithBlankedTransactionSpecification(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment);

        // [WHEN] Run "Intrastat - Form" report
        asserterror RunIntrastatFormReport(IntrastatJnlLine, Format(IntrastatJnlLine.Type::Shipment));

        // [THEN] Testfield error occurs: "Transaction Specification must have a value"
        VerifyAdvanvedChecklistError(IntrastatJnlLine, IntrastatJnlLine.FieldName("Transaction Specification"));
    end;

    [Test]
    [HandlerFunctions('IntrastatFormRPH')]
    procedure IntrastatFormChecksForTransactionSpecificationForReceipts()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat] [Intrastat - Form] [Receipt]
        // [SCENARIO 396535] Report 501 "Intrastat - Form" checks for "Transaction Specification" for receipts
        Initialize();
        EnableAdvancedChecklist();

        // [GIVEN] Prepare receipt intrastat journal line with blanked "Transaction Specification"
        PrepareIntrastatJnlLineWithBlankedTransactionSpecification(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);

        // [WHEN] Run "Intrastat - Form" report
        asserterror RunIntrastatFormReport(IntrastatJnlLine, Format(IntrastatJnlLine.Type::Receipt));

        // [THEN] Testfield error occurs: "Transaction Specification must have a value"
        VerifyAdvanvedChecklistError(IntrastatJnlLine, IntrastatJnlLine.FieldName("Transaction Specification"));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatFormRPH')]
    procedure IntrastatFormForCorrectionShipmentLine()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Intrastat] [Intrastat - Form] [Shipments] [Correction]
        // [SCENARIO 394971] Report 501 "Intrastat - Form"  in case of correction for shipments
        // [SCENARIO 395404] Quantity has been printed with negative sign
        // [SCENARIO 396681] Total Weight and Statistical Amount have been printed with negative sign
        // [SCENARIO 396680] Report 594 "Get Item Ledger Entries" creates "Receipt" intrastat journal line with negative amounts
        Initialize();

        // [GIVEN] Posted purchase return order
        CreatePostPurchaseReturnOrderWithSingleLine(ItemNo);

        // [GIVEN] Run "Suggest Lines" from intrastat journal page
        RunSuggestLines(IntrastatJnlLine, ItemNo);
        IntrastatJnlLine."Transaction Type" := LibraryUtility.GenerateGUID();
        IntrastatJnlLine.Modify();

        // [WHEN] Run "Intrastat - Form" report
        RunIntrastatFormReport(IntrastatJnlLine, Format(IntrastatJnlLine.Type::Receipt));

        // [THEN] "Receipt" line type has been printed
        Assert.IsTrue(IntrastatJnlLine.Quantity < 0, 'expected Quantity < 0');
        Assert.IsTrue(IntrastatJnlLine."Total Weight" < 0, 'expected Total Weight < 0');
        Assert.IsTrue(IntrastatJnlLine."Statistical Value" < 0, 'expected Statistical Value < 0');

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Type_IntraJnlLine', 'Receipt');
        LibraryReportDataset.AssertElementWithValueExists('Quantity_IntraJnlLine', IntrastatJnlLine.Quantity); // TFS 395404
        LibraryReportDataset.AssertElementWithValueExists('TotalWeight_IntraJnlLine', ROUND(IntrastatJnlLine."Total Weight", 1)); // TFS 396681
        LibraryReportDataset.AssertElementWithValueExists('SubTotalWeight', ROUND(IntrastatJnlLine."Total Weight", 1)); // TFS 396681
        LibraryReportDataset.AssertElementWithValueExists('StatisValue_IntraJnlLine', IntrastatJnlLine."Statistical Value"); // TFS 396681
        LibraryReportDataset.AssertElementWithValueExists(
            'IntraJnlLine_TransactionSpecification', IntrastatJnlLine."Transaction Specification"); // TFS 421239
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatFormRPH')]
    procedure IntrastatFormForCorrectionReceiptLine()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Intrastat] [Intrastat - Form] [Receipt] [Correction]
        // [SCENARIO 394971] Report 501 "Intrastat - Form"  in case of correction for receipts
        // [SCENARIO 395404] Quantity has been printed with negative sign
        // [SCENARIO 396681] Total Weight and Statistical Amount have been printed with negative sign
        // [SCENARIO 396680] Report 594 "Get Item Ledger Entries" creates "Shipment" intrastat journal line with negative amounts
        Initialize();
        EnableAdvancedChecklist();

        // [GIVEN] Posted sales return order
        CreatePostSalesReturnOrderWithSingleLine(ItemNo);

        // [GIVEN] Run "Suggest Lines" from intrastat journal page
        RunSuggestLines(IntrastatJnlLine, ItemNo);
        IntrastatJnlLine."Transaction Specification" := LibraryUtility.GenerateGUID();
        IntrastatJnlLine."Country/Region of Origin Code" := LibraryUtility.GenerateGUID();
        IntrastatJnlLine.Modify();

        // [WHEN] Run "Intrastat - Form" report
        RunIntrastatFormReport(IntrastatJnlLine, Format(IntrastatJnlLine.Type::Shipment));

        // [THEN] "Shipment" line type has been printed
        Assert.IsTrue(IntrastatJnlLine.Quantity < 0, 'expected Quantity < 0');
        Assert.IsTrue(IntrastatJnlLine."Total Weight" < 0, 'expected Total Weight < 0');
        Assert.IsTrue(IntrastatJnlLine."Statistical Value" < 0, 'expected Statistical Value < 0');

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Type_IntraJnlLine', 'Shipment');
        LibraryReportDataset.AssertElementWithValueExists('Quantity_IntraJnlLine', IntrastatJnlLine.Quantity); // TFS 395404
        LibraryReportDataset.AssertElementWithValueExists('TotalWeight_IntraJnlLine', ROUND(IntrastatJnlLine."Total Weight", 1)); // TFS 396681
        LibraryReportDataset.AssertElementWithValueExists('SubTotalWeight', ROUND(IntrastatJnlLine."Total Weight", 1)); // TFS 396681
        LibraryReportDataset.AssertElementWithValueExists('StatisValue_IntraJnlLine', IntrastatJnlLine."Statistical Value"); // TFS 396681
        LibraryReportDataset.AssertElementWithValueExists(
            'IntraJnlLine_TransactionSpecification', IntrastatJnlLine."Transaction Specification"); // TFS 421239
    end;

    [Test]
    procedure TestCheckIntrastatJournalLineForCorrection()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        IntrastatLocalMgt: Codeunit "Intrastat Local Mgt.";
        ItemDirectType: Option;
    begin
        // [FEATURE] [Intrastat] [UT]
        // [SCENARIO 394971] COD 11400 "Local Functionality Mgt.".CheckIntrastatJournalLineForCorrection()
        Initialize();

        IntrastatJnlLine."Source Entry No." := -1;
        Assert.IsFalse(IntrastatLocalMgt.CheckIntrastatJournalLineForCorrection(IntrastatJnlLine, ItemDirectType), '');

        IntrastatJnlLine."Source Entry No." := MockItemLedgerEntry(ItemLedgerEntry."Document Type"::"Purchase Return Shipment");
        Assert.IsTrue(IntrastatLocalMgt.CheckIntrastatJournalLineForCorrection(IntrastatJnlLine, ItemDirectType), '');
        Assert.AreEqual(IntrastatJnlLine.Type::Receipt, ItemDirectType, '');

        IntrastatJnlLine."Source Entry No." := MockItemLedgerEntry(ItemLedgerEntry."Document Type"::"Purchase Credit Memo");
        Assert.IsTrue(IntrastatLocalMgt.CheckIntrastatJournalLineForCorrection(IntrastatJnlLine, ItemDirectType), '');
        Assert.AreEqual(IntrastatJnlLine.Type::Receipt, ItemDirectType, '');

        IntrastatJnlLine."Source Entry No." := MockItemLedgerEntry(ItemLedgerEntry."Document Type"::"Sales Return Receipt");
        Assert.IsTrue(IntrastatLocalMgt.CheckIntrastatJournalLineForCorrection(IntrastatJnlLine, ItemDirectType), '');
        Assert.AreEqual(IntrastatJnlLine.Type::Shipment, ItemDirectType, '');

        IntrastatJnlLine."Source Entry No." := MockItemLedgerEntry(ItemLedgerEntry."Document Type"::"Sales Credit Memo");
        Assert.IsTrue(IntrastatLocalMgt.CheckIntrastatJournalLineForCorrection(IntrastatJnlLine, ItemDirectType), '');
        Assert.AreEqual(IntrastatJnlLine.Type::Shipment, ItemDirectType, '');

        IntrastatJnlLine."Source Entry No." := MockItemLedgerEntry(ItemLedgerEntry."Document Type"::"Service Credit Memo");
        Assert.IsTrue(IntrastatLocalMgt.CheckIntrastatJournalLineForCorrection(IntrastatJnlLine, ItemDirectType), '');
        Assert.AreEqual(IntrastatJnlLine.Type::Shipment, ItemDirectType, '');
    end;

    [Test]
    [HandlerFunctions('CreateIntrastatDeclDiskReqPageHandler')]
    procedure CreateDeclReportChecksForTransactionSpecificationForShipmentsCounterparty()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FileTempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Intrastat] [Create Intrastat Decl. Disk] [Shipment] [Counterparty]
        // [SCENARIO 396535] Report 11413 "Create Intrastat Decl. Disk" checks for "Transaction Specification" for shipments (counterparty = true)
        Initialize();
        EnableAdvancedChecklist();

        // [GIVEN] Prepare shipment intrastat journal line with blanked "Transaction Specification"
        PrepareIntrastatJnlLineWithBlankedTransactionSpecification(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment);

        // [WHEN] Run "Create Intrastat Decl. Disk" report (counterparty = true)
        asserterror RunIntrastatMakeDiskTaxAuth2022(FileTempBlob, true);

        // [THEN] Error log contains 1 error: "Transaction Specification must have a value"
        VerifyBatchError(IntrastatJnlLine, IntrastatJnlLine.FIELDNAME("Transaction Specification"));
    end;

    [Test]
    [HandlerFunctions('CreateIntrastatDeclDiskReqPageHandler')]
    procedure CreateDeclReportChecksForTransactionSpecificationForReceiptsCounterparty()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FileTempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Intrastat] [Create Intrastat Decl. Disk] [Receipt] [Counterparty]
        // [SCENARIO 396535] Report 11413 "Create Intrastat Decl. Disk" checks for "Transaction Specification" for receipts (counterparty = true)
        Initialize();
        EnableAdvancedChecklist();

        // [GIVEN] Prepare receipt intrastat journal line with blanked "Transaction Specification"
        PrepareIntrastatJnlLineWithBlankedTransactionSpecification(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);

        // [WHEN] Run "Create Intrastat Decl. Disk" report (counterparty = true)
        asserterror RunIntrastatMakeDiskTaxAuth2022(FileTempBlob, true);

        // [THEN] Error log contains 1 error: "Transaction Specification must have a value"
        VerifyBatchError(IntrastatJnlLine, IntrastatJnlLine.FIELDNAME("Transaction Specification"));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,CreateIntrastatDeclDiskReqPageHandler')]
    procedure CreateDeclReportWithNegativeZeroSSpecialUnitsForCorrection()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        ItemNo: Code[20];
        FileTempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Intrastat] [Create Intrastat Decl. Disk] [Shipment] [Correction]
        // [SCENARIO 431037] Report 11413 "Create Intrastat Decl. Disk" prints "+0" for the special units in case of correction
        Initialize();

        // [GIVEN] Intrastat journal line for shipment correction and "Supplementary Units" = false
        CreatePostPurchaseReturnOrderWithSingleLine(ItemNo);
        RunSuggestLines(IntrastatJnlLine, ItemNo);
        IntrastatJnlLine."Transport Method" := LibraryUtility.GenerateGUID();
        IntrastatJnlLine."Transaction Type" := 'X';
        IntrastatJnlLine."Entry/Exit Point" := LibraryUtility.GenerateGUID();
        IntrastatJnlLine."Transaction Specification" := Format(LibraryRandom.RandIntInRange(10, 99));
        IntrastatJnlLine.Modify();

        // [WHEN] Run "Create Intrastat Decl. Disk" report
        RunIntrastatMakeDiskTaxAuth2022(FileTempBlob, true);

        // [THEN] Special Unit value is exposted as "+0"
        VerifyTransactionAndPatnerIDInDeclarationFile(FileTempBlob, '                 ', '  ', '+');
    end;

    [Test]
    [HandlerFunctions('CreateIntrastatDeclDiskReqPageHandler')]
    procedure CreateDeclReport2022ExportsTransactionSpecificationForReceiptsCounterparty()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FileTempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Intrastat] [Create Intrastat Decl. Disk] [Receipt] [Counterparty]
        // [SCENARIO 396535] Report 11413 "Create Intrastat Decl. Disk" exports "Transaction Specification"
        // [SCENARIO 396535] for receipts (counterparty = true) in case of Export Format 2022
        Initialize();
        EnableAdvancedChecklist();

        // [GIVEN] Receipt intrastat journal line with typed "Transaction Specification"
        PrepareIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);
        IntrastatJnlLine.TestField("Transaction Specification");

        // [WHEN] Run "Create Intrastat Decl. Disk" report (counterparty = true, Export Format = 2022)
        RunIntrastatMakeDiskTaxAuth2022(FileTempBlob, true);

        // [THEN] "Transaction Specification" is exported
        VerifyTransactionAndPatnerIDInDeclarationFile(
          FileTempBlob, PadStr('', 17, ' '), '  ', '+');
    end;

    [Test]
    [HandlerFunctions('IntrastatFormRPH')]
    procedure IntrastatFormForTransactionTypeForShipments()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat] [Intrastat - Form] [Shipments]
        // [SCENARIO 444687] Report 501 "Intrastat - Form" does not check "Transaction Type" for shipments.
        Initialize();

        // [GIVEN] Shipment intrastat journal line with blank "Transaction Type".
        PrepareIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment);
        IntrastatJnlLine."Transaction Type" := '';
        IntrastatJnlLine.Modify();

        // [WHEN] Run "Intrastat - Form" report.
        RunIntrastatFormReport(IntrastatJnlLine, Format(IntrastatJnlLine.Type::Shipment));

        // [THEN] No errors are thrown.
    end;

    [Test]
    [HandlerFunctions('IntrastatFormRPH')]
    procedure IntrastatFormForTransactionTypeForReceipts()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat] [Intrastat - Form] [Receipt]
        // [SCENARIO 451331] Report 501 "Intrastat - Form" does not check "Transaction Type" for receipts.
        Initialize();

        // [GIVEN] Receipt intrastat journal line with blank "Transaction Type".
        PrepareIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);
        IntrastatJnlLine."Transaction Type" := '';
        IntrastatJnlLine.Modify();

        // [WHEN] Run "Intrastat - Form" report
        RunIntrastatFormReport(IntrastatJnlLine, Format(IntrastatJnlLine.Type::Receipt));

        // [THEN] No errors are thrown.
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistRPH')]
    procedure IntrastatChecklistReportForTransactionTypeForShipments()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat] [Intrastat - Checklist] [Shipments]
        // [SCENARIO 451331] Report 502 "Intrastat - Checklist" does not check "Transaction Type" for shipments.
        Initialize();

        // [GIVEN] Shipment intrastat journal line with blank "Transaction Type".
        PrepareIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment);
        IntrastatJnlLine."Transaction Type" := '';
        IntrastatJnlLine.Modify();

        // [WHEN] Run "Intrastat - Checklist" report.
        RunIntrastatChecklistReport(IntrastatJnlLine);

        // [THEN] No errors are thrown.
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistRPH')]
    procedure IntrastatChecklistReportForTransactionTypeForReceipts()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat] [Intrastat - Checklist] [Receipt]
        // [SCENARIO 451331] Report 502 "Intrastat - Checklist" does not check "Transaction Type" for receipts.
        Initialize();

        // [GIVEN] Receipt intrastat journal line with blank "Transaction Type".
        PrepareIntrastatJournalLine(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);
        IntrastatJnlLine."Transaction Type" := '';
        IntrastatJnlLine.Modify();

        // [WHEN] Run "Intrastat - Checklist" report.
        RunIntrastatChecklistReport(IntrastatJnlLine);

        // [THEN] No errors are thrown.
    end;

    local procedure Initialize()
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatSetup: Record "Intrastat Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM MISC");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        IntrastatSetup.DeleteAll();
        IntrastatJnlTemplate.DeleteAll(true);

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM MISC");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        SetIntrastatCodeOnCountryRegion();
        LibrarySetupStorage.Save(DATABASE::"Company Information");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM MISC");
    end;

    local procedure EnableAdvancedChecklist()
#if not CLEAN19
    var
        IntrastatSetup: Record "Intrastat Setup";
    begin
        if not IntrastatSetup.Get() then
            IntrastatSetup.Insert();
        IntrastatSetup."Use Advanced Checklist" := true;
        IntrastatSetup."Report Receipts" := true;
        IntrastatSetup."Report Shipments" := true;
        IntrastatSetup.Modify();
#else
    begin
#endif
    end;

    local procedure GetEntryExitPointFromDeclarationFile(var FileTempBlob: Codeunit "Temp Blob"): Text[12]
    var
        FileInStream: InStream;
        DeclarationString: Text[256];
    begin
        FileTempBlob.CreateInStream(FileInStream);
        FileInStream.ReadText(DeclarationString);
        FileInStream.ReadText(DeclarationString);
        DeclarationString := CopyStr(DeclarationString, 33, 2);
        exit(DeclarationString);
    end;

    local procedure PrepareIntrastatJnlLineWithBlankedTransactionSpecification(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; Type: Option)
    begin
        PrepareIntrastatJournalLine(IntrastatJnlLine, Type);
        IntrastatJnlLine."Transaction Specification" := '';
        IntrastatJnlLine.Modify();
    end;


    local procedure PrepareIntrastatJournalLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; Type: Option)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        CreateSimpleIntrastatJnlTemplateAndBatch(IntrastatJnlBatch);
        CreateIntrastatJnlLineWithMandatoryFields(IntrastatJnlLine,
          IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name, SetIntrastatDataOnCompanyInfo);
        UpdatePartnerIDInIntrastatJnlLine(IntrastatJnlLine, Type);
    end;

    local procedure CreateCBGStatementWithTemplate(GenJnlTemplateName: Code[10]): Integer
    var
        CBGStatement: Record "CBG Statement";
    begin
        CBGStatement.Init();
        CBGStatement.Validate("Journal Template Name", GenJnlTemplateName);
        CBGStatement.Insert(true);
        exit(CBGStatement."No.");
    end;

    local procedure DeleteCBGStatement(GenJnlTemplateName: Code[10]; CBGStatementNo: Integer)
    var
        CBGStatement: Record "CBG Statement";
    begin
        CBGStatement.Get(GenJnlTemplateName, CBGStatementNo);
        CBGStatement.Delete(true);
    end;

    local procedure CreateBankAccountNo(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        exit(BankAccount."No.");
    end;

    local procedure CreateGenJournalTemplateWithBankAccount(BankAccountNo: Code[20]): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Bank);
        GenJournalTemplate.Validate("Bal. Account Type", GenJournalTemplate."Bal. Account Type"::"Bank Account");
        GenJournalTemplate.Validate("Bal. Account No.", BankAccountNo);
        GenJournalTemplate.Validate("No. Series", LibraryERM.CreateNoSeriesCode);
        GenJournalTemplate.Modify(true);
        exit(GenJournalTemplate.Name);
    end;

    local procedure CreateAndPostBankGiroJournalAndVerifyGLEntry(AccountType: Option; AccountNo: Code[20]; AppliesToDocNo: Code[20]; Amount: Decimal)
    var
        CBGStatement: Record "CBG Statement";
    begin
        // Setup: Create and Post Bank Giro Journal.
        CreateBankGiroJournal(CBGStatement, AccountType, AccountNo, AppliesToDocNo, Amount);
        LibraryVariableStorage.Enqueue(CBGStatement."Journal Template Name");  // Enqueue value for GenJournalTemplListCBGPageHandler.

        // Exercise.
        PostBankGiroJournal(CBGStatement."Journal Template Name", CBGStatement."Document No.");

        // Verify: Verify Payment Discount Amount.
        VerifyGLEntry(CBGStatement."Document No.", -Amount);
    end;

    local procedure CreateBankGiroJournal(var CBGStatement: Record "CBG Statement"; AccountType: Option; AccountNo: Code[20]; AppliesToDocNo: Code[20]; Amount: Decimal)
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        CBGStatement.Validate("Journal Template Name", 'POSTBANK');  // Use Hard Code value for POSTBANK.
        CBGStatement.Validate("No.", LibraryRandom.RandInt(10));
        CBGStatement.Insert(true);
        CBGStatementLine.Validate("Journal Template Name", CBGStatement."Journal Template Name");
        CBGStatementLine.Validate("No.", CBGStatement."No.");
        CBGStatementLine.Validate("Line No.", LibraryRandom.RandInt(10));
        CBGStatementLine.Insert(true);
        CBGStatementLine.Validate(Date, WorkDate());
        CBGStatementLine.Validate("Account Type", AccountType);
        CBGStatementLine.Validate("Account No.", AccountNo);
        CBGStatementLine.Validate("Applies-to Doc. Type", CBGStatementLine."Applies-to Doc. Type"::"Credit Memo");
        CBGStatementLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        CBGStatementLine.Validate(Amount, Amount);
        CBGStatementLine.Modify(true);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        TransactionMode: Record "Transaction Mode";
    begin
        TransactionMode.FindFirst();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Transaction Mode Code", TransactionMode.Code);
        Customer.Validate("Preferred Bank Account Code", CreateCustomerBankAccount(Customer."No."));
        Customer.Validate("Payment Terms Code", CreatePaymentTerms);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerBankAccount(CustomerNo: Code[20]): Code[10]
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CustomerBankAccount.Validate("Customer No.", CustomerNo);
        CustomerBankAccount.Validate(
          Code, LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo("Customer No."), DATABASE::"Customer Bank Account"));
        CustomerBankAccount.Insert(true);
        exit(CustomerBankAccount.Code);
    end;

    local procedure CreateCountryRegionCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
        CountryRegionCode: Code[10];
    begin
        CountryRegionCode := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(2, 0), 1, 2);
        if not CountryRegion.Get(CountryRegionCode) then begin
            CountryRegion.Init();
            CountryRegion.Code := CountryRegionCode;
            CountryRegion."Intrastat Code" := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(2, 0), 1, 2);
            CountryRegion.Insert();
        end else
            if CountryRegion."Intrastat Code" = '' then begin
                CountryRegion."Intrastat Code" := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(2, 0), 1, 2);
                CountryRegion.Modify();
            end;

        exit(CountryRegionCode);
    end;

    local procedure CreateForeignVendorNo(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", FindCountryRegionCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateForeignCustomerNo(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", FindCountryRegionCode());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Price.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemForIntrastat(): Code[20]
    var
        Item: Record Item;
        TariffNumber: Record "Tariff Number";
    begin
        Item.Get(CreateItem);
        TariffNumber.FindFirst();
        Item.Validate("Tariff No.", TariffNumber."No.");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithTariffNo(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        with Item do begin
            Validate("Tariff No.", LibraryUtility.CreateCodeRecord(DATABASE::"Tariff Number"));
            Validate("Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
            Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
            Validate("Last Direct Cost", LibraryRandom.RandDecInRange(100, 200, 2));
            Validate("Net Weight", LibraryRandom.RandDecInRange(100, 200, 2));
            Modify(true);
        end;
    end;

    local procedure CreateIntrastatJournalTemplateAndBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; PostingDate: Date)
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        LibraryERM.CreateIntrastatJnlBatch(IntrastatJnlBatch, IntrastatJnlTemplate.Name);
        IntrastatJnlBatch.Validate("Statistics Period", Format(PostingDate, 0, '<Year,2><Month,2>'));
        IntrastatJnlBatch.Validate("Currency Identifier", 'EUR');
        IntrastatJnlBatch.Modify(true);
    end;

    local procedure CreateSimpleIntrastatJnlTemplateAndBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    begin
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        IntrastatJnlBatch.Validate("Currency Identifier", 'EUR');
        IntrastatJnlBatch.Modify(true);
    end;

    local procedure CreatePaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreatePurchasedItemsWithTariff(var Amount: array[2] of Decimal; var ItemFilter: Code[20])
    var
        Item: array[2] of Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreateItemWithTariffNo(Item[1]);
        CreateItemWithTariffNo(Item[2]);
        ItemFilter := Item[1]."No.";
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateForeignVendorNo);

        PurchaseHeader.Validate("Posting Date", CalcDate('<+1M>', WorkDate()));
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader,
          PurchaseLine.Type::Item, Item[1]."No.",
          LibraryRandom.RandDec(100, 2));
        Amount[1] := Round(PurchaseLine."Line Amount", 1);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader,
          PurchaseLine.Type::Item, Item[2]."No.",
          LibraryRandom.RandDec(100, 2));
        Amount[2] := Round(PurchaseLine."Line Amount", 1);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostPurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header") Amount: Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateVendor);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem, LibraryRandom.RandDec(10, 2));  // Taking Random Quantity.
        Amount := PurchaseLine."Outstanding Amount" - (PurchaseLine."Outstanding Amount" / PurchaseHeader."Payment Discount %") / 100;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePostPurchaseReturnOrderWithSingleLine(var ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        CreateItemWithTariffNo(Item);
        ItemNo := Item."No.";
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateForeignVendorNo());
        PurchaseHeader.Validate("Posting Date", CalcDate('<+1M>', WorkDate()));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesReturnOrder(var SalesHeader: Record "Sales Header") Amount: Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CreateCustomer);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem, LibraryRandom.RandDec(10, 2));  // Taking Random Quantity.
        Amount := SalesLine."Outstanding Amount" - (SalesLine."Outstanding Amount" / SalesHeader."Payment Discount %") / 100;
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreatePostSalesReturnOrderWithSingleLine(var ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        CreateItemWithTariffNo(Item);
        ItemNo := Item."No.";
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CreateForeignCustomerNo());
        SalesHeader.Validate("Posting Date", CalcDate('<+1M>', WorkDate()));
        SalesHeader.Validate("Ship-to Country/Region Code", SalesHeader."Sell-to Country/Region Code");
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; ItemNo: Code[20])
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CreateCustomer);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        if DocumentType = ServiceHeader."Document Type"::Order then begin
            LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
            LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
            ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        end;
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Taking Random Quantity.
        ServiceLine.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        TransactionMode: Record "Transaction Mode";
    begin
        TransactionMode.FindFirst();
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Transaction Mode Code", TransactionMode.Code);
        Vendor.Validate("Preferred Bank Account Code", CreateVendorBankAccount(Vendor."No."));
        Vendor.Validate("Payment Terms Code", CreatePaymentTerms);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorBankAccount(VendorNo: Code[20]): Code[10]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount.Validate("Vendor No.", VendorNo);
        VendorBankAccount.Validate(
          Code, LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("Vendor No."), DATABASE::"Vendor Bank Account"));
        VendorBankAccount.Insert(true);
        exit(VendorBankAccount.Code);
    end;

    local procedure MockItemLedgerEntry(DocumentType: Enum "Item Ledger Document Type"): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Document Type" := DocumentType;
        ItemLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(ItemLedgerEntry, ItemLedgerEntry.FieldNo("Entry No."));
        ItemLedgerEntry.Insert();
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure FindCountryRegionCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        with CountryRegion do begin
            SetFilter(Code, '<>%1', CompanyInformation."Country/Region Code");
            SetFilter("Intrastat Code", '<>%1', '');
            FindFirst();
            exit(Code);
        end;
    end;

    local procedure FindOrCreateIntrastatTransportMethod(): Code[10]
    begin
        exit(LibraryUtility.FindOrCreateCodeRecord(DATABASE::"Transport Method"));
    end;

    local procedure FindOrCreateIntrastatTransactionType(): Code[10]
    begin
        exit(LibraryUtility.FindOrCreateCodeRecord(DATABASE::"Transaction Type"));
    end;

    local procedure FindOrCreateIntrastatEntryExitPoint(): Code[10]
    begin
        exit(LibraryUtility.FindOrCreateCodeRecord(DATABASE::"Entry/Exit Point"));
    end;

    local procedure GetExpectedVATRegNo(): Text[12]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        exit(CopyStr(CompanyInformation."VAT Registration No.", 3, 12));
    end;

    local procedure PostBankGiroJournal(JournalTemplateName: Code[10]; DocumentNo: Code[20])
    var
        BankGiroJournal: TestPage "Bank/Giro Journal";
    begin
        BankGiroJournal.OpenEdit;
        BankGiroJournal.FILTER.SetFilter("Account No.", JournalTemplateName);
        BankGiroJournal.FILTER.SetFilter("Document No.", DocumentNo);
        BankGiroJournal.Post.Invoke;
    end;

    local procedure RunGetItemLedgerEntriesToCreateJnlLinesWithFutureDates(IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        IntrastatJournal.OpenEdit;
        LibraryVariableStorage.AssertEmpty;
        LibraryVariableStorage.Enqueue(CalcDate('<+1D>', WorkDate()));
        LibraryVariableStorage.Enqueue(CalcDate('<+1M>', WorkDate()));
        IntrastatJournal.GetEntries.Invoke;
        VerifyIntrastatJnlLinesExist(IntrastatJnlBatch);
        IntrastatJournal.Close();
    end;

    local procedure RunSuggestLines(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; ItemNo: Code[20])
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        Commit();
        RunGetItemLedgerEntriesToCreateJnlLinesWithFutureDates(IntrastatJnlBatch);

        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.SetFilter("Item No.", '<>%1', ItemNo);
        IntrastatJnlLine.DeleteAll();

        IntrastatJnlLine.SetRange("Item No.");
        IntrastatJnlLine.FindFirst();
    end;

    local procedure SetIntrastatCodeOnCountryRegion()
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        CountryRegion.Get(CompanyInformation."Country/Region Code");
        CountryRegion.Validate("Intrastat Code", CountryRegion.Code);
        CountryRegion.Modify(true);
    end;

    local procedure SetIntrastatDataOnCompanyInfo(): Code[10]
    var
        CountryRegion: Record "Country/Region";
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CountryRegion.Get(CreateCountryRegionCode());
        CountryRegion.Validate("Intrastat Code", CountryRegion.Code);
        CountryRegion.Modify(true);
        CompanyInformation."VAT Registration No." := UpperCase(LibraryUtility.GenerateRandomText(14));
        CompanyInformation."Country/Region Code" := CountryRegion.Code;
        CompanyInformation.Modify();
        exit(CountryRegion.Code);
    end;

    local procedure SetMandatoryFieldsOnJnlLines(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; TransportMethod: Code[10]; TransactionType: Code[10]; ExitEntryPoint: Code[10])
    begin
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.FindSet(true);
        repeat
            IntrastatJnlLine.Validate("Transport Method", TransportMethod);
            IntrastatJnlLine.Validate("Transaction Type", TransactionType);
            IntrastatJnlLine.Validate("Net Weight", LibraryRandom.RandDecInRange(1, 10, 2));
            IntrastatJnlLine.Validate("Entry/Exit Point", ExitEntryPoint);
            IntrastatJnlLine.Modify(true);
        until IntrastatJnlLine.Next() = 0;
    end;

    local procedure CreateIntrastatJnlLineWithMandatoryFields(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlTemplateName: Code[10]; IntrastatJnlBatchName: Code[10]; CountryCode: Code[10])
    begin
        LibraryERM.CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlTemplateName, IntrastatJnlBatchName);
        IntrastatJnlLine.Validate("Transport Method", LibraryUtility.FindOrCreateCodeRecord(DATABASE::"Transport Method"));
        IntrastatJnlLine.Validate("Transaction Type", LibraryUtility.FindOrCreateCodeRecord(DATABASE::"Transaction Type"));
        IntrastatJnlLine."Transaction Specification" := Format(LibraryRandom.RandIntInRange(10, 99));
        IntrastatJnlLine.Validate("Entry/Exit Point", LibraryUtility.FindOrCreateCodeRecord(DATABASE::"Entry/Exit Point"));
        IntrastatJnlLine.Validate(Date, WorkDate());
        IntrastatJnlLine.Validate("Item No.", CreateItemForIntrastat);
        IntrastatJnlLine.Validate("Source Entry No.", LibraryRandom.RandIntInRange(1, 10));
        IntrastatJnlLine.Validate(Quantity, LibraryRandom.RandIntInRange(1, 10));
        IntrastatJnlLine.Validate("Net Weight", LibraryRandom.RandDecInRange(1, 10, 2));
        IntrastatJnlLine.Validate("Country/Region Code", CountryCode);
        IntrastatJnlLine.Validate("Country/Region of Origin Code", CreateCountryRegionCode);
        IntrastatJnlLine.Modify(true);
    end;

    local procedure UpdatePartnerIDInIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlLineType: Option)
    begin
        IntrastatJnlLine.Type := IntrastatJnlLineType;
        IntrastatJnlLine."Transaction Specification" := Format(LibraryRandom.RandIntInRange(10, 99));
        IntrastatJnlLine."Partner VAT ID" := LibraryUtility.GenerateGUID();
        IntrastatJnlLine.Modify();
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Source Type", GLEntry."Source Type"::"Bank Account");
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision,
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), GLEntry.Amount, GLEntry.TableCaption()));
    end;


    local procedure RunIntrastatMakeDiskTaxAuth2022(var FileTempBlob: Codeunit "Temp Blob"; Counterparty: Boolean)
    var
        CreateIntrastatDeclDisk: Report "Create Intrastat Decl. Disk";
        ExportFormat: Enum "Intrastat Export Format";
        FileOutStream: OutStream;
    begin
        Commit();
        LibraryVariableStorage.Enqueue(Counterparty);
        FileTempBlob.CreateOutStream(FileOutStream);
        CreateIntrastatDeclDisk.InitializeRequest(FileOutStream, ExportFormat::"2022");
        CreateIntrastatDeclDisk.Run();
    end;

    local procedure RunIntrastatChecklistReport(IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        IntrastatJnlBatch."Journal Template Name" := IntrastatJnlLine."Journal Template Name";
        IntrastatJnlBatch.Name := IntrastatJnlLine."Journal Batch Name";
        IntrastatJnlBatch.SetRecFilter();
        Commit();
        Report.Run(Report::"Intrastat - Checklist", true, false, IntrastatJnlBatch);
    end;

    local procedure RunIntrastatFormReport(IntrastatJnlLine: Record "Intrastat Jnl. Line"; TypeFilter: Text)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        IntrastatJnlBatch."Journal Template Name" := IntrastatJnlLine."Journal Template Name";
        IntrastatJnlBatch.Name := IntrastatJnlLine."Journal Batch Name";
        IntrastatJnlBatch.SetRecFilter();
        LibraryVariableStorage.Enqueue(TypeFilter);
        Commit();
        Report.Run(Report::"Intrastat - Form", true, false, IntrastatJnlBatch);
    end;

    local procedure VerifyIntrastatJnlLinesExist(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        Assert.IsFalse(IntrastatJnlLine.IsEmpty, 'No Intrastat Journal Lines exist');
    end;

    local procedure VerifyTransacModeCodeAndBankAccCodeInCustLedgEntry(ServiceHeader: Record "Service Header")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", ServiceHeader."Customer No.");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Transaction Mode Code", ServiceHeader."Transaction Mode Code");
        CustLedgerEntry.TestField("Recipient Bank Account", ServiceHeader."Bank Account Code");
    end;

    local procedure VerifyTransactionAndPatnerIDInDeclarationFile(var FileTempBlob: Codeunit "Temp Blob"; ExpectedPartnedID: Text; ExpectedCountryOfOrigin: Text; ExpectedSpecialUnitSign: Text)
    var
        FileInStream: InStream;
        DeclarationString: Text[256];
    begin
        FileTempBlob.CreateInStream(FileInStream);
        FileInStream.ReadText(DeclarationString);
        FileInStream.ReadText(DeclarationString);
        Assert.AreEqual(ExpectedPartnedID, CopyStr(DeclarationString, 118, 17), 'Partner ID');
        Assert.AreEqual(ExpectedCountryOfOrigin, CopyStr(DeclarationString, 25, 2), 'Country of Origin');
        Assert.AreEqual(ExpectedSpecialUnitSign, CopyStr(DeclarationString, 81, 1), 'Special Unit + sign'); // TFS 400682
        Assert.AreEqual('         0', CopyStr(DeclarationString, 82, 10), 'Special Unit value');
    end;

    local procedure VerifyTestfieldChecklistError(FieldName: Text)
    begin
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(FieldName);
    end;

    local procedure VerifyAdvanvedChecklistError(IntrastatJnlLine: Record "Intrastat Jnl. Line"; FieldName: Text)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        ErrorMessage: Record "Error Message";
    begin
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(AdvChecklistErr);
        VerifyBatchError(IntrastatJnlLine, FieldName);
    end;

    local procedure VerifyBatchError(IntrastatJnlLine: Record "Intrastat Jnl. Line"; FieldName: Text)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        ErrorMessage: Record "Error Message";
    begin
        IntrastatJnlBatch."Journal Template Name" := IntrastatJnlLine."Journal Template Name";
        IntrastatJnlBatch.Name := IntrastatJnlLine."Journal Batch Name";
        ErrorMessage.SetContext(IntrastatJnlBatch);
        Assert.AreEqual(1, ErrorMessage.ErrorMessageCount(ErrorMessage."Message Type"::Error), '');
        ErrorMessage.FindFirst();
        Assert.ExpectedMessage(FieldName, ErrorMessage."Message");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GenJournalTemplListCBGPageHandler(var GenJournalTemplListCBG: TestPage "Gen. Journal Templ. List (CBG)")
    begin
        GenJournalTemplListCBG.FILTER.SetFilter(Name, LibraryVariableStorage.DequeueText);
        GenJournalTemplListCBG.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetItemLedgerEntriesRequestPageHandler(var GetItemLedgerEntriesReqPage: TestRequestPage "Get Item Ledger Entries")
    var
        StartDate: Variant;
        EndDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndDate);
        GetItemLedgerEntriesReqPage.StartingDate.SetValue(StartDate);
        GetItemLedgerEntriesReqPage.EndingDate.SetValue(EndDate);
        GetItemLedgerEntriesReqPage.IndirectCostPctReq.SetValue(0);
        GetItemLedgerEntriesReqPage.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhereUsedHandler(var GLAccountWhereUsedList: TestPage "G/L Account Where-Used List")
    var
        i: Integer;
    begin
        GLAccountWhereUsedList.First;
        for i := 2 to LibraryVariableStorage.DequeueInteger do begin // for 2 lines and more
            GLAccountWhereUsedList."Field Name".AssertEquals(LibraryVariableStorage.DequeueText);
            GLAccountWhereUsedList.Next();
        end;
        GLAccountWhereUsedList."Field Name".AssertEquals(LibraryVariableStorage.DequeueText);
        GLAccountWhereUsedList.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateIntrastatDeclDiskReqPageHandler(var CreateIntrastatDeclDisk: TestRequestPage "Create Intrastat Decl. Disk")
    begin
        CreateIntrastatDeclDisk.Counterparty.SetValue(LibraryVariableStorage.DequeueBoolean);
        CreateIntrastatDeclDisk.OK.Invoke;
    end;

    [RequestPageHandler]
    procedure IntrastatChecklistRPH(var IntrastatChecklist: TestRequestPage "Intrastat - Checklist")
    begin
        IntrastatChecklist.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure IntrastatFormRPH(var IntrastatForm: TestRequestPage "Intrastat - Form")
    begin
        IntrastatForm."Intrastat Jnl. Line".SetFilter(Type, LibraryVariableStorage.DequeueText());
        IntrastatForm.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

}

