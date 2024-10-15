codeunit 144005 "ERM Tax Authority"
{
    // // [FEATURE] [Tax Authority - Audit File]
    // Test for feature Audit.
    //  1. Verify Posting date, Sourc Code, Entry No., VAT Business Posting Group, GL Account No., Description, Vendor/Customer
    //    Details  in generated Audit file with in Start Date/End Date.
    //  2. Verify total number entries and Credit/Debit Amount from GL Entry  in generated Audit file.
    //  3. Verify Reversal entry in generated Audit file.
    //  4. Verify no description with 'Transactie beginbalans' found in generated Audit file when ExcludeBalance on Tax Authority - Audit File set to TRUE.
    //  5. Verify description in generated Audit file when ExcludeBalance on Tax Authority - Audit File set to FALSE.
    //  6. Verify report header details in generated Audit file.
    //  7. Verify Tax Registration No. in generated Audit file when VAT Registration No. is blank on Company Information.
    //  8. Verify description in generated Audit file when Audit file contains closing G/L entries.
    //  9. Verify the Audit file can be overwritten.
    // 
    // Covers Test Cases for WI - 342836
    // ------------------------------------------------------------------------------------------------------
    // Test Function Name                          TFS ID
    // ------------------------------------------------------------------------------------------------------
    // TaxAuthorityAuditGLEnries                   151278, 151279, 151280, 151285, 151286, 151392, 151393
    // AuditTotalGLEntryAmount                     151281
    // AuditReversalEntry                          151282
    // 
    // Covers Test Cases for WI - 342837
    // ----------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                             TFS ID
    // ----------------------------------------------------------------------------------------------------------------
    // DescriptionWithExcludeBalanceTrue                                              151546
    // DescriptionWithExcludeBalanceFalse                                             151547
    // HeaderInformation                                                              151551,151548,173622,151650,151550
    // VATRegistrationNoBlank                                                         151539,173621
    // AuditFileWithClosingGLEntries                                                  151284
    // OverwriteAuditFile                                                             151543

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        DescriptionCap: Label 'description';
        JournalIDCap: Label 'journalID';
        LibraryRandom: Codeunit "Library - Random";
        ReverseEntriesQst: Label 'To reverse these entries, correcting entries will be posted.';
        CloseFiscalYearQst: Label 'Do you want to create and close the fiscal year?';
        SuccessfullyReversedMsg: Label 'The entries were successfully reversed.';
        SuccessfullyCreatedMsg: Label 'The journal lines have successfully been created.';
        UnexpectedMsg: Label 'Unexpected message.';
        NodeNotFoundMsg: Label 'A XML node with the value %1 could not be found.';
        DecimalFormatTxt: Label '<Precision,2:2><Standard Format,0>';
        DateFormatTxt: Label '<Year4>-<Month,2>-<Day,2>';
        LibraryXMLRead: Codeunit "Library - XML Read";
        StartDateCap: Label 'startDate';
        TaxRegistrationCap: Label 'taxRegistrationNr';
        TransactieBeginbalansCap: Label 'Transactie beginbalans';
        FileManagement: Codeunit "File Management";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TaxAuthorityAuditGLEnries()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Vendor: Record Vendor;
        TaxAuthorityAuditFile: Report "Tax Authority - Audit File";
        FileName: Text;
    begin
        // [SCENARIO 209589] Audit file have to contains formated values of Customer."No." and Vendor."No."

        // Setup: Create and post Sales Order, Purchase Order and Gen. Journal.
        Initialize;

        // [GIVEN] Posted purchase order for Vendor."No." = "VENDOR0001"
        PurchInvHeader.Get(CreateAndPostPurchaseOrder(GetPostingDate));

        // [GIVEN] Posted sales order for Customer."No." = "CUSTOMER0001"
        SalesInvoiceHeader.Get(CreateAndPostSalesOrder(GetPostingDate));
        FindGLEntry(GLEntry, PurchInvHeader."No.", false);
        FindGLEntry(GLEntry2, SalesInvoiceHeader."No.", false);
        Vendor.Get(PurchInvHeader."Buy-from Vendor No.");
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        CreateLedgerEntry(GenJournalBatch, CalcDate('<' + Format(LibraryRandom.RandIntInRange(1, 4)) + 'D>', GetPostingDate)); // Using Random for date formula.
        GLAccount.Get(GLEntry2."G/L Account No.");
        EnqueueValuesForRequestPage(GetPostingDate, true);  // Enqueue values for TaxAuthorityAuditFileRequestPageHandler.

        // [WHEN] Run report "Tax Authority - Audit File"
        FileName := FileManagement.ServerTempFileName('xaf');
        TaxAuthorityAuditFile.SetFileName(FileName);
        TaxAuthorityAuditFile.Run;

        // Verify: Verify Posting date, Sourc Code, Entry No., VAT Business Posting Group, GL Account No., Description, Vendor/Customer Details  in generated Audit file with in Start Date/End Date.
        VerifyTaxAuthorityAuditFile(FileName, 'effectiveDate', Format(GLEntry."Posting Date", 0, DateFormatTxt), 0);  // Date format required as XAF file date format.
        VerifyTaxAuthorityAuditFile(FileName, JournalIDCap, GLEntry."Source Code", 0);
        VerifyTaxAuthorityAuditFile(FileName, 'effectiveDate', Format(GLEntry."Posting Date", 0, DateFormatTxt), 1);  // Date format required as XAF file date format.
        VerifyTaxAuthorityAuditFile(FileName, JournalIDCap, GLEntry2."Source Code", 1);
        VerifyTaxAuthorityAuditFile(FileName, 'effectiveDate', Format(GLEntry2."Posting Date", 0, DateFormatTxt), 2);  // Date format required as XAF file date format.
        VerifyTaxAuthorityAuditFile(FileName, 'transactionID', '                 ' + Format(GLEntry."Transaction No."), 0);  // Blank space required as XAF file format.
        VerifyTaxAuthorityAuditFile(FileName, 'documentID', GLEntry."Document No.", 2);
        VerifyTaxAuthorityAuditFile(FileName, 'vatCode', GLEntry."VAT Prod. Posting Group", 1);
        VerifyTaxAuthorityAuditFile(FileName, 'vatAmount', ConvertStr(Format(GLEntry."VAT Amount", 0, DecimalFormatTxt), ',', '.'), 0);  // Decimal format required as XAF file format.
        VerifyTaxAuthorityAuditFile(FileName, 'period', '   ' + Format(Date2DMY(GetPostingDate, 2), 2), 0);  // Blank space required as XAF file format.
        VerifyTaxAuthorityAuditFile(FileName, 'accountID', GLEntry."G/L Account No.", 4);
        VerifyTaxAuthorityAuditFile(FileName, 'recordID', '                ' + Format(GLEntry."Entry No."), 0);  // Blank space required as XAF file format.
        VerifyTaxAuthorityAuditFile(FileName, 'accountDesc', GLAccount.Name, 5);
        VerifyTaxAuthorityAuditFile(FileName, 'accountType', 'Balans', 0);  // Hardcode required as per XAF file format.

        // [THEN] Value 'custSupID' for the first supplier = '2CUSTOMER0001'
        VerifyTaxAuthorityAuditFile(FileName, 'custSupID', '2' + CopyStr(Customer."No.", 1, 14), 0);  // 2 required as XAF file format.

        // [THEN] Value 'custSupID' for the second supplier = '3VENDOR0001'
        VerifyTaxAuthorityAuditFile(FileName, 'custSupID', '3' + CopyStr(Vendor."No.", 1, 14), 1);  // 3 required as XAF file format.
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AuditTotalGLEntryAmount()
    var
        GLEntry: Record "G/L Entry";
        TaxAuthorityAuditFile: Report "Tax Authority - Audit File";
        FileName: Text;
        PostingDate: Date;
        DocumentNo: Code[20];
    begin
        // Verify total number entries and Credit/Debit Amount from GL Entry  in generated Audit file.

        // Setup: Create and post Sales Order, find GL Entry.
        Initialize;
        // Use random posting date and clear all entries before posting to avoid clashes
        PostingDate := GetPostingDate;
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.DeleteAll;
        DocumentNo := CreateAndPostSalesOrder(PostingDate);
        Commit;
        EnqueueValuesForRequestPage(PostingDate, true);  // Enqueue values for TaxAuthorityAuditFileRequestPageHandler.

        // Exercise: Run Tax Authority - Audit File report.
        FileName := FileManagement.ServerTempFileName('xaf');
        TaxAuthorityAuditFile.SetFileName(FileName);
        TaxAuthorityAuditFile.Run;

        // Verify: Verify Total number entries and credit/debit amount from GL Entry  in generated Audit file.
        GLEntry.Reset;
        GLEntry.SetRange("Document No.", DocumentNo);
        VerifyTaxAuthorityAuditFile(FileName, 'numberEntries', Format(GLEntry.Count), 0);
        VerifyTaxAuthorityAuditFile(
          FileName, 'totalDebit', ConvertStr(Format(GetGLEntryAmount(DocumentNo, '>%1'), 0, DecimalFormatTxt), ',', '.'), 0);  // Decimal format required as XAF file format.
        VerifyTaxAuthorityAuditFile(
          FileName, 'totalCredit', ConvertStr(Format(Abs(GetGLEntryAmount(DocumentNo, '<%1')), 0, DecimalFormatTxt), ',', '.'), 0);  // Decimal format required as XAF file format.
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileRequestPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AuditReversalEntry()
    var
        GLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        TaxAuthorityAuditFile: Report "Tax Authority - Audit File";
        FileName: Text;
    begin
        // Verify Reversal entry in generated Audit file.

        // Setup: Create and post Gen Jouranl and reverse.
        Initialize;
        FindGLEntry(
          GLEntry, CreateLedgerEntry(GenJournalBatch, GetPostingDate), false);
        LibraryVariableStorage.Enqueue(ReverseEntriesQst);  // Enqueue for ConfirmHandler.
        ReverseTransaction(GLEntry."Transaction No.");
        EnqueueValuesForRequestPage(GLEntry."Posting Date", false);  // Enqueue values for TaxAuthorityAuditFileRequestPageHandler.

        // Exercise: Run Tax Authority - Audit File report.
        FileName := FileManagement.ServerTempFileName('xaf');
        TaxAuthorityAuditFile.SetFileName(FileName);
        TaxAuthorityAuditFile.Run;

        // Verify: Verify Reversal entry in generated Audit file.
        FindGLEntry(GLEntry2, GLEntry."Document No.", true);
        GLEntry2.FindLast;
        VerifyTaxAuthorityAuditFile(FileName, JournalIDCap, GLEntry2."Source Code", -1);
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DescriptionWithExcludeBalanceTrue()
    var
        [RunOnClient]
        NodeList: DotNet XmlNodeList;
        [RunOnClient]
        Node: DotNet XmlNode;
        FileName: Text;
    begin
        // Verify no description with 'Transactie beginbalans' found in generated Audit file when ExcludeBalance on Tax Authority - Audit File set to TRUE.

        // Setup and Exercise: Create and post Gen. Journal and run report.
        Initialize;
        FileName := FileManagement.ServerTempFileName('xaf');
        CreateLedgerEntryAndRunReport(FileName, true);  // TRUE for ExcludeBalance.

        // Verify: Verify Description in generated Audit file when ExcludeBalance on Tax Authority - Audit File set to TRUE.
        LibraryXMLRead.Initialize(FileName);
        LibraryXMLRead.GetNodeListByElementName(DescriptionCap, NodeList);
        Node := NodeList.Item(2);
        Assert.AreNotEqual(StrSubstNo(TransactieBeginbalansCap), Node.InnerText, UnexpectedMsg);
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DescriptionWithExcludeBalanceFalse()
    var
        FileName: Text;
    begin
        // Verify description in generated Audit file when ExcludeBalance on Tax Authority - Audit File set to FALSE.

        // Setup and Exercise: Create and post Gen. Journal and run report.
        Initialize;
        FileName := FileManagement.ServerTempFileName('xaf');
        CreateLedgerEntryAndRunReport(FileName, false);  // FALSE for ExludeBalance.

        // Verify.
        VerifyTaxAuthorityAuditFile(FileName, DescriptionCap, StrSubstNo(TransactieBeginbalansCap), 2);
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure HeaderInformation()
    var
        CompanyInformation: Record "Company Information";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TaxAuthorityAuditFile: Report "Tax Authority - Audit File";
        FileName: Text;
    begin
        // Verify report header details in generated Audit file.

        // Setup.
        Initialize;
        CompanyInformation.Get;
        UpdateCompanyInformation(CompanyInformation, CompanyInformation."VAT Registration No.");
        UpdateLCYCodeGLSetup(GeneralLedgerSetup);
        CreateAndPostSalesOrder(GetPostingDate);
        EnqueueValuesForRequestPage(GetPostingDate, false);  // Enqueue values for TaxAuthorityAuditFileRequestPageHandler.
        Commit;  // COMMIT required.

        // Exercise.
        FileName := FileManagement.ServerTempFileName('xaf');
        TaxAuthorityAuditFile.SetFileName(FileName);
        TaxAuthorityAuditFile.Run;

        // Verify: Verify Company ID, Postal code, Currency code, Date format in generated Audit file are according to the length prescribed by the tax authorities.
        VerifyTaxAuthorityAuditFile(FileName, 'companyID', CopyStr(CompanyInformation.Name, 1, 20), 0);
        VerifyTaxAuthorityAuditFile(FileName, 'companyPostalCode', CopyStr(CompanyInformation."Post Code", 1, 10), 0);
        VerifyTaxAuthorityAuditFile(FileName, 'currencyCode', CopyStr(GeneralLedgerSetup."LCY Code", 1, 3), 0);
        VerifyTaxAuthorityAuditFile(FileName, StartDateCap, Format(GetPostingDate, 0, DateFormatTxt), 0);
        VerifyTaxAuthorityAuditFile(FileName, 'endDate', Format(GetPostingDate, 0, DateFormatTxt), 0);
        VerifyTaxAuthorityAuditFile(FileName, 'dateCreated', Format(Today, 0, DateFormatTxt), 0);
        VerifyTaxAuthorityAuditFile(FileName, TaxRegistrationCap, CompanyInformation."VAT Registration No.", 0);
        VerifyTaxAuthorityAuditFile(FileName, 'transactionDate', Format(GetPostingDate, 0, DateFormatTxt), 0);
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATRegistrationNoBlank()
    var
        CompanyInformation: Record "Company Information";
        TaxAuthorityAuditFile: Report "Tax Authority - Audit File";
        FileName: Text;
    begin
        // Verify Tax Registration No. in generated Audit file when VAT Registration No. is blank on Company Information.

        // Setup.
        Initialize;
        UpdateCompanyInformation(CompanyInformation, '');  // '' for VAT Registration No.
        EnqueueValuesForRequestPage(GetPostingDate, false);  // Enqueue values for TaxAuthorityAuditFileRequestPageHandler.
        Commit;  // COMMIT required.

        // Exercise.
        FileName := FileManagement.ServerTempFileName('xaf');
        TaxAuthorityAuditFile.SetFileName(FileName);
        TaxAuthorityAuditFile.Run;

        // Verify: Verify Tax Registration No. in generated Audit file.
        VerifyTaxAuthorityAuditFile(FileName, TaxRegistrationCap, '', 0);
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileRequestPageHandler,CloseIncomeStatementRequestPageHandler,MessageHandler,CreateFiscalYearRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AuditFileWithClosingGLEntries()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        TaxAuthorityAuditFile: Report "Tax Authority - Audit File";
        ClosingDate: Date;
        FileName: Text;
        StartDate: Date;
    begin
        // Verify description in generated Audit file when Audit file contains closing G/L entries.

        // Setup.
        Initialize;
        LibraryVariableStorage.Enqueue(CloseFiscalYearQst);  // Enqueue for CreateFiscalYearRequestPageHandler.
        REPORT.Run(REPORT::"Create Fiscal Year"); // Create previous fiscal year.
        StartDate := LibraryFiscalYear.GetFirstPostingDate(true);
        CreateLedgerEntry(GenJournalBatch, StartDate);
        ClosingDate := CalcDate('<1Y - 1D>', StartDate);  // Getting last date of fiscal year, which is required for Close Income Statement.
        LibraryERM.CreateGLAccount(GLAccount);

        // Enqueue values for CloseIncomeStatementRequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(ClosingDate);
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        LibraryVariableStorage.Enqueue(GLAccount."No.");

        RunCloseIncomeStatement(GenJournalBatch);
        EnqueueValuesForRequestPage(ClosingDate, false);  // Enqueue values for TaxAuthorityAuditFileRequestPageHandler.
        Commit;  // COMMIT required.

        // Exercise.
        FileName := FileManagement.ServerTempFileName('xaf');
        TaxAuthorityAuditFile.SetFileName(FileName);
        TaxAuthorityAuditFile.Run;

        // Verify: Verify description in generated Audit file when Audit file contains closing G/L entries.
        VerifyTaxAuthorityAuditFile(FileName, DescriptionCap, 'Opening Entries', -1);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Tax Authority");
        LibraryVariableStorage.Clear;

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Tax Authority");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Tax Authority");
    end;

    local procedure GetPostingDate(): Date
    begin
        exit(LibraryRandom.RandDateFrom(Today, -5) - 1);
    end;

    local procedure CreateAndPostPurchaseOrder(PostingDate: Date): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem, LibraryRandom.RandDec(10, 2)); // Using Random for Quantity.
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesOrder(PostingDate: Date): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem, LibraryRandom.RandDec(10, 2));  // Using Random for Quantity.
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateLedgerEntryAndRunReport(FileName: Text; ExcludeBalance: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TaxAuthorityAuditFile: Report "Tax Authority - Audit File";
    begin
        CreateLedgerEntry(GenJournalBatch, CalcDate('<-1D>', GetPostingDate)); // necessary to create Balance at Date
        CreateLedgerEntry(GenJournalBatch, GetPostingDate);
        EnqueueValuesForRequestPage(GetPostingDate, ExcludeBalance);  // Enqueue values for TaxAuthorityAuditFileRequestPageHandler.

        // Exercise.
        TaxAuthorityAuditFile.SetFileName(FileName);
        TaxAuthorityAuditFile.Run;
    end;

    local procedure RunCloseIncomeStatement(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryVariableStorage.Enqueue(SuccessfullyCreatedMsg);  // Enqueue for MessageHandler.
        Commit;  // COMMIT required.
        REPORT.Run(REPORT::"Close Income Statement");

        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        exit(BankAccount."No.")
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer."No.")), 1, MaxStrLen(Customer."No."));
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Using Random for Unit Price.
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));  // Using Random for Unit Cost.
        Item.Modify(true);
        exit(Item."No.")
    end;

    local procedure CreateLedgerEntry(var GenJournalBatch: Record "Gen. Journal Batch"; PostingDate: Date) DocumentNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        SelectAndClearGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Bank Account", CreateBankAccount, LibraryRandom.RandDec(1000, 2));  // Using Random for Amount.
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor."No.")), 1, MaxStrLen(Vendor."No."));
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure EnqueueValuesForRequestPage(StartEndDate: Variant; ExcludeBalance: Variant)
    begin
        LibraryVariableStorage.Enqueue(StartEndDate);
        LibraryVariableStorage.Enqueue(ExcludeBalance);
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; Reversed: Boolean)
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange(Reversed, Reversed);
        GLEntry.FindFirst;
    end;

    local procedure GetGLEntryAmount(DocumentNo: Code[20]; Condition: Text[3]) Amount: Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetFilter(Amount, Condition, 0);
        GLEntry.FindSet;
        repeat
            Amount += GLEntry.Amount;
        until GLEntry.Next = 0;
    end;

    local procedure ReverseTransaction(TransactionNo: Integer)
    var
        ReversalEntry: Record "Reversal Entry";
    begin
        LibraryVariableStorage.Enqueue(SuccessfullyReversedMsg);  // Enqueue for MessageHandler.
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(TransactionNo);
        Commit;  // COMMIT required.
    end;

    local procedure SelectAndClearGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure UpdateCompanyInformation(var CompanyInformation: Record "Company Information"; VATRegistrationNo: Text[20])
    begin
        CompanyInformation.Get;
        CompanyInformation.Validate("Post Code", LibraryUtility.GenerateGUID + LibraryUtility.GenerateGUID);
        CompanyInformation.Validate("VAT Registration No.", VATRegistrationNo);
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateLCYCodeGLSetup(var GeneralLedgerSetup: Record "General Ledger Setup")
    begin
        GeneralLedgerSetup.Get;
        GeneralLedgerSetup.Validate("LCY Code", LibraryUtility.GenerateGUID);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure VerifyTaxAuthorityAuditFile(FileName: Text; ElementCap: Text[30]; Value: Text[100]; IndexNo: Integer)
    var
        [RunOnClient]
        NodeList: DotNet XmlNodeList;
        [RunOnClient]
        Node: DotNet XmlNode;
    begin
        // If IndexNo is set to a negative value, this function will search for a XML node with the value defined in the Value parameter.
        LibraryXMLRead.Initialize(FileName);
        LibraryXMLRead.GetNodeListByElementName(ElementCap, NodeList);
        if IndexNo >= 0 then begin
            Node := NodeList.Item(IndexNo);
            Assert.AreEqual(Value, Node.InnerText, ElementCap);
        end else begin
            for IndexNo := 0 to NodeList.Count - 1 do begin
                Node := NodeList.Item(IndexNo);
                if Node.InnerText = Value then
                    exit;
            end;
            Assert.Fail(StrSubstNo(NodeNotFoundMsg, Value));
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        Message: Variant;
    begin
        LibraryVariableStorage.Dequeue(Message);
        Assert.AreNotEqual(StrPos(Question, Message), 0, UnexpectedMsg);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ActualMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ActualMessage);
        Assert.AreEqual(Message, Format(ActualMessage), UnexpectedMsg);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateFiscalYearRequestPageHandler(var CreateFiscalYear: TestRequestPage "Create Fiscal Year")
    begin
        CreateFiscalYear.StartingDate.SetValue(CalcDate('<-1Y>', LibraryFiscalYear.GetFirstPostingDate(true)));  // Required prevoius year Start Date.
        CreateFiscalYear.NoOfPeriods.SetValue(12);
        CreateFiscalYear.PeriodLength.SetValue('<1M>');
        CreateFiscalYear.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementRequestPageHandler(var CloseIncomeStatement: TestRequestPage "Close Income Statement")
    var
        GenJournalTemplate: Variant;
        GenJournalBatch: Variant;
        FiscalYearEndingDate: Variant;
        RetainedEarningsAcc: Variant;
    begin
        LibraryVariableStorage.Dequeue(GenJournalTemplate);
        LibraryVariableStorage.Dequeue(FiscalYearEndingDate);
        LibraryVariableStorage.Dequeue(GenJournalBatch);
        LibraryVariableStorage.Dequeue(RetainedEarningsAcc);
        CloseIncomeStatement.GenJournalTemplate.SetValue(GenJournalTemplate);
        CloseIncomeStatement.FiscalYearEndingDate.SetValue(FiscalYearEndingDate);
        CloseIncomeStatement.GenJournalBatch.SetValue(GenJournalBatch);
        CloseIncomeStatement.RetainedEarningsAcc.SetValue(RetainedEarningsAcc);
        CloseIncomeStatement.PostingDescription.SetValue('Opening Entries');  // Used hard coded value as needed for verification in Audit File.
        CloseIncomeStatement.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TaxAuthorityAuditFileRequestPageHandler(var TaxAuthorityAuditFile: TestRequestPage "Tax Authority - Audit File")
    var
        StartEndDate: Variant;
        ExcludeBalance: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartEndDate);
        LibraryVariableStorage.Dequeue(ExcludeBalance);
        TaxAuthorityAuditFile.StartDate.SetValue(StartEndDate);
        TaxAuthorityAuditFile.EndDate.SetValue(StartEndDate);
        TaxAuthorityAuditFile.ExcludeBalance.SetValue(ExcludeBalance);
        TaxAuthorityAuditFile.OK.Invoke;
    end;
}

