codeunit 144043 "Test ESR Import"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryLSV: Codeunit "Library - LSV";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        EsrMgt: Codeunit EsrMgt;
        FileManagement: Codeunit "File Management";
        ESRAccountNumber1Txt: Label '01-002654-0';
        ESRAccountNumber2Txt: Label '01-000162-8';
        ESRAccountNumber3Txt: Label '01-048062-7';
        ESRAccountNumber4Txt: Label '03-000002-2';

    [Test]
    [HandlerFunctions('MessageHandler,SelectESRSetupItem')]
    [Scope('OnPrem')]
    procedure VerifyBalanceAccountNumberAndTypeInJournalLine()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ESRFileName: Text;
    begin
        Init();

        // Create a sales journal entry with lines.
        LibrarySales.CreateCustomer(Customer);
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, Customer."No.",
          -(100 + LibraryRandom.RandDec(100, 2)));

        // Import the below file and verify that the gen. journal line has the imported records.
        ESRFileName := ESRImportFile1();
        VerifyESRImportBasedOnAccountNumber('01-13980-3', 23, '', ESRFileName);

        // Verify that the created sales journal entry is intact as a result of the import.
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.SetRange("Bal. Account No.", GenJournalLine."Bal. Account No.");
        GenJournalLine.SetRange("Source Code", 'ESR', '');

        Assert.IsTrue(GenJournalLine.IsEmpty, 'There should not be any journal line with the imported G/L account');

        FILE.Erase(ESRFileName);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SelectESRSetupItem')]
    [Scope('OnPrem')]
    procedure ImportESRRecordsOfRecordType3WithoutCRLF()
    var
        ESRFileName: Text;
    begin
        Init();
        ESRFileName := RecordType3WithoutCRLF();

        VerifyESRImportBasedOnAccountNumber(ESRAccountNumber1Txt, 107, '', ESRFileName);

        FILE.Erase(ESRFileName);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SelectESRSetupItem')]
    [Scope('OnPrem')]
    procedure ImportESRRecordsOfRecordType3WithCRLF()
    var
        ESRFileName: Text;
    begin
        Init();
        ESRFileName := RecordType3WithCRLF();

        VerifyESRImportBasedOnAccountNumber(ESRAccountNumber1Txt, 45, '', ESRFileName);

        FILE.Erase(ESRFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportESRRecordsOfRecordType3WithoutCRLFAndReferenceInvoice()
    var
        ESRFileName: Text;
    begin
        Init();
        ESRFileName := RecordType3WithoutCRLFAndReferenceInvoice();

        // Should not use hardcoded values
        // VerifyESRImportBasedOnDocumentNumber(ESRAccountNumber2Txt,3,ESRFileName,'CHF','103009','103018');

        FILE.Erase(ESRFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportESRRecordsOfRecordType3WithCRLFAndReferenceInvoice()
    var
        ESRFileName: Text;
    begin
        Init();
        ESRFileName := RecordType3WithCRLFAndReferenceInvoice();

        // Should not use hardcoded values
        // VerifyESRImportBasedOnDocumentNumber(ESRAccountNumber2Txt,3,ESRFileName,'CHF','103009','103018');

        FILE.Erase(ESRFileName);
    end;

    [Test]
    [HandlerFunctions('SelectESRSetupItem')]
    [Scope('OnPrem')]
    procedure ImportCorruptESRRecordsOfRecordType4()
    var
        GLAccount: Record "G/L Account";
        ESRSetup: Record "ESR Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ESRFileName: Text;
    begin
        Init();
        ESRFileName := CorruptRecordType4WithoutCRLF();

        LibraryERM.CreateGLAccount(GLAccount);
        CreateESRSetup(ESRSetup, ESRFileName, ESRAccountNumber1Txt, GLAccount."No.");
        LibraryVariableStorage.Enqueue(ESRSetup."Bank Code");

        CreateGeneralJournalBatch(GenJournalBatch);

        // Create a journal line based on the batch, but do not set the G/L account. That is set by the ESRMgt code unit.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));

        DeleteESRRelatedGenJournalEntries();
        asserterror EsrMgt.ImportEsrFile(GenJournalLine);
        Assert.IsTrue(StrPos(GetLastErrorText, ESRSetup."Bank Code") > 0, 'Unexpected error message');

        FILE.Erase(ESRFileName);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SelectESRSetupItem')]
    [Scope('OnPrem')]
    procedure ImportCorruptESRFile()
    var
        ESRFileName: Text;
    begin
        Init();
        ESRFileName := CorruptESRFileWithChecksumError();

        VerifyESRImportBasedOnAccountNumber(ESRAccountNumber1Txt, 107, '492', ESRFileName);

        FILE.Erase(ESRFileName);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SelectESRSetupItem')]
    [Scope('OnPrem')]
    procedure ImportESRRecordsOfRecordType4CHFWithoutCRLF()
    var
        ESRFileName: Text;
    begin
        Init();
        ESRFileName := RecordType4CHFWithoutCRLF();

        VerifyESRImportBasedOnAccountNumber(ESRAccountNumber3Txt, 28, 'CHF', ESRFileName);

        FILE.Erase(ESRFileName);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SelectESRSetupItem')]
    [Scope('OnPrem')]
    procedure ImportESRRecordsOfRecordType4CHFWithCRLF()
    var
        ESRFileName: Text;
    begin
        Init();
        ESRFileName := RecordType4CHFWithCRLF();

        VerifyESRImportBasedOnAccountNumber(ESRAccountNumber3Txt, 28, 'CHF', ESRFileName);

        FILE.Erase(ESRFileName);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SelectESRSetupItem')]
    [Scope('OnPrem')]
    procedure ImportESRRecordsOfRecordType4OtherCurrencyWithoutCRLF()
    begin
        VerifyImportESRRecordsOfRecordType4OtherCurrency(false, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SelectESRSetupItem')]
    [Scope('OnPrem')]
    procedure ImportESRRecordsOfRecordType4OtherCurrencyWithCRLF()
    begin
        VerifyImportESRRecordsOfRecordType4OtherCurrency(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportESRRecordsOfRecordType4CHFWithoutCRLFAndReferenceInvoice()
    var
        ESRFileName: Text;
    begin
        Init();
        ESRFileName := RecordType4CHFWithoutCRLFAndReferenceInvoice();

        // Should not use hardcoded values
        // VerifyESRImportBasedOnDocumentNumber(ESRAccountNumber3Txt,2,ESRFileName,'CHF','103018','103018');

        FILE.Erase(ESRFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportESRRecordsOfRecordType4CHFWithCRLFAndReferenceInvoice()
    var
        ESRFileName: Text;
    begin
        Init();
        ESRFileName := RecordType4CHFWithCRLFAndReferenceInvoice();

        // Should not use hardcoded values
        // VerifyESRImportBasedOnDocumentNumber(ESRAccountNumber3Txt,2,ESRFileName,'CHF','103018','103018');

        FILE.Erase(ESRFileName);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SelectESRSetupItem')]
    [Scope('OnPrem')]
    procedure ImportESRRecordsOfRecordType4OtherCurrencyWithoutCRLFAndRefernceInvoice()
    begin
        VerifyImportESRRecordsOfRecordType4OtherCurrency(false, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SelectESRSetupItem')]
    [Scope('OnPrem')]
    procedure ImportESRRecordsOfRecordType4OtherCurrencyWithCRLFAndRefernceInvoice()
    begin
        VerifyImportESRRecordsOfRecordType4OtherCurrency(true, true);
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,MessageHandler,LSVCloseCollectionReqPageHandler,WriteLSVFileReqPageHandler,LSVConfirmHandler,SelectESRSetupItem,CustomerESRJournalReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerESRJournalReportLayoutAmmountTest()
    var
        "Layout": Option Amount,"ESR Information";
    begin
        CustomerESRJournalReportTest(Layout::Amount)
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,MessageHandler,LSVCloseCollectionReqPageHandler,WriteLSVFileReqPageHandler,LSVConfirmHandler,SelectESRSetupItem,CustomerESRJournalReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerESRJournalReportLayoutESRInformationTest()
    var
        "Layout": Option Amount,"ESR Information";
    begin
        CustomerESRJournalReportTest(Layout::"ESR Information")
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,MessageHandler,LSVCloseCollectionReqPageHandler,WriteLSVFileReqPageHandler,LSVConfirmHandler,SelectESRSetupItem')]
    [Scope('OnPrem')]
    procedure ImportESRFileForDifferenceReferenceNumber()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        LSVJournalLine: Record "LSV Journal Line";
        LSVJournal: Record "LSV Journal";
        ESRSetup: Record "ESR Setup";
        LSVSetup: Record "LSV Setup";
        DocumentNo: Code[20];
    begin
        Init();

        // Prepare LSV data.
        DocumentNo := PrepareLSVData(Customer, LSVJournal, LSVSetup, ESRSetup);

        // Prepare the file.
        RecordForDifferenceReferenceNumber(ESRSetup."ESR Filename", DocumentNo);

        // Invoke ESR
        InvokeESRImport(ESRSetup, GenJournalBatch, ESRAccountNumber2Txt, LSVSetup."Bal. Account No.", ESRSetup."ESR Filename",
          1, 'CHF');

        // Check that the line on the LSV Journal List has the flag Closed by Import File
        VerifyLSVJournalLine(LSVJournal."No.", Customer."No.", DocumentNo, LSVJournalLine."LSV Status"::"Closed by Import File");
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,MessageHandler,LSVCloseCollectionReqPageHandler,WriteLSVFileReqPageHandler,LSVConfirmHandler,SelectESRSetupItem')]
    [Scope('OnPrem')]
    procedure ImportESRFileAndVerifyMultipleOpenInvoiceErrorMessage()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        LSVJournalLine: Record "LSV Journal Line";
        LSVJournal: Record "LSV Journal";
        ESRSetup: Record "ESR Setup";
        LSVSetup: Record "LSV Setup";
        DocumentNo: Code[20];
    begin
        Init();

        // Prepare LSV data.
        DocumentNo := PrepareLSVData(Customer, LSVJournal, LSVSetup, ESRSetup);

        // Prepare the file.
        RecordForMultipleOpenInvoice(ESRSetup."ESR Filename", DocumentNo);

        LibraryVariableStorage.Enqueue(ESRSetup."Bank Code");
        CreateGeneralJournalBatch(GenJournalBatch);

        // Create a journal line based on the batch, but do not set the G/L account. That is set by the ESRMgt code unit.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));

        DeleteESRRelatedGenJournalEntries();

        asserterror EsrMgt.ImportEsrFile(GenJournalLine);
        Assert.IsTrue(StrPos(GetLastErrorText, DocumentNo) > 0, 'Unexpected error message');

        // Check that the line on the LSV Journal List has the flag Opened by Import File
        VerifyLSVJournalLine(LSVJournal."No.", Customer."No.", DocumentNo, LSVJournalLine."LSV Status"::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportESRFileWhenJournalIsNotEmpty()
    var
        GLAccount: Record "G/L Account";
        ESRSetup: Record "ESR Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ESRFileName: Text;
    begin
        Init();
        ESRFileName := RecordType4CHFWithCRLF();

        LibraryERM.CreateGLAccount(GLAccount);
        CreateESRSetup(ESRSetup, ESRFileName, ESRAccountNumber1Txt, GLAccount."No.");
        LibraryVariableStorage.Enqueue(ESRSetup."Bank Code");

        CreateGeneralJournalBatch(GenJournalBatch);

        // Create a journal line based on the batch, and set the G/L account.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));

        asserterror EsrMgt.ImportEsrFile(GenJournalLine);
        Assert.IsTrue(StrPos(GetLastErrorText, GenJournalLine."Journal Batch Name") > 0, 'Unexpected error message');

        FILE.Erase(ESRFileName);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectESRSetupItem(var ESRSetupListItems: TestPage "ESR Setup List")
    var
        ESRSetup: Record "ESR Setup";
        BankCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankCode);
        Assert.IsTrue(ESRSetup.Get(BankCode), 'ESR setup not found');
        ESRSetupListItems.GotoRecord(ESRSetup);
        ESRSetupListItems.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ESRImportFileRecordNumber: Variant;
        HandleMessage: Variant;
        ShouldHandleMessage: Boolean;
    begin
        // The message should contain that ESRImportFileRecordNumber records were imported.
        LibraryVariableStorage.Dequeue(HandleMessage);
        ShouldHandleMessage := HandleMessage;
        if ShouldHandleMessage then begin
            LibraryVariableStorage.Dequeue(ESRImportFileRecordNumber);
            Assert.IsTrue(StrPos(Message, ESRImportFileRecordNumber) > 0, 'Unexpected dialog.');
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure LSVConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LSVSuggestCollectionReqPageHandler(var LSVSuggestCollection: TestRequestPage "LSV Suggest Collection")
    begin
        LSVSuggestCollection.FromDueDate.SetValue(WorkDate());
        LSVSuggestCollection.ToDueDate.SetValue(WorkDate());
        LSVSuggestCollection.Customer.SetFilter("No.", RetrieveLSVCustomerForCollection());
        LSVSuggestCollection.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LSVCloseCollectionReqPageHandler(var LSVCloseCollection: TestRequestPage "LSV Close Collection")
    begin
        LSVCloseCollection.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WriteLSVFileReqPageHandler(var WriteLSVFile: TestRequestPage "Write LSV File")
    begin
        WriteLSVFile.TestSending.SetValue(false);
        WriteLSVFile.OK().Invoke();
    end;

    local procedure Init()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CustomerESRJournalReportTest("Layout": Option Amount,"ESR Information")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        LSVJournal: Record "LSV Journal";
        ESRSetup: Record "ESR Setup";
        LSVSetup: Record "LSV Setup";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        Init();

        // Prepare LSV data.
        DocumentNo := PrepareLSVData(Customer, LSVJournal, LSVSetup, ESRSetup);

        // Prepare the file.
        RecordForDifferenceReferenceNumber(ESRSetup."ESR Filename", DocumentNo);

        // Invoke ESR
        InvokeESRImport(ESRSetup, GenJournalBatch, ESRAccountNumber2Txt, LSVSetup."Bal. Account No.", ESRSetup."ESR Filename",
          1, 'CHF');

        Commit();
        LibraryVariableStorage.Enqueue(Layout);
        REPORT.Run(REPORT::"Customer ESR Journal", true, false);

        // Verify
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'Wrong number of rows');

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('IntLayout', Layout);
        LibraryReportDataset.AssertCurrentRowValueEquals('Customer_Name', Customer.Name);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustLedgEntry_DueDate', Format(WorkDate()));

        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Customer);
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Account No.", Customer."No.");
        GenJournalLine.FindFirst();

        LibraryReportDataset.AssertCurrentRowValueEquals('AmountLCY_GenJournalLine', -GenJournalLine."Amount (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('PostingDate_GenJournalLine', Format(GenJournalLine."Posting Date", 0, 4));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerESRJournalReportRequestPageHandler(var RequestPage: TestRequestPage "Customer ESR Journal")
    var
        "Layout": Variant;
    begin
        LibraryVariableStorage.Dequeue(Layout);

        RequestPage.Layout.SetValue(Layout);
        RequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Normal]
    local procedure PrepareLSVData(var Customer: Record Customer; var LSVJournal: Record "LSV Journal"; var LSVSetup: Record "LSV Setup"; var ESRSetup: Record "ESR Setup") DocumentNo: Code[20]
    begin
        DocumentNo := PrepareLSVSalesDocsForCollection(Customer, LSVJournal, LSVSetup, ESRSetup);
        LibraryVariableStorage.Enqueue(Customer."No.");
        SuggestLSVJournalLines(LSVJournal);
        CollectLSVJournalLines(LSVJournal);
        WriteLSVFile(LSVJournal);
        exit(DocumentNo);
    end;

    local procedure PrepareLSVSalesDocsForCollection(var Customer: Record Customer; var LSVJnl: Record "LSV Journal"; var LSVSetup: Record "LSV Setup"; var ESRSetup: Record "ESR Setup"): Code[20]
    var
        SalesHeader: Record "Sales Header";
        ESRFileName: Text;
    begin
        ESRFileName := CreateFileName();
        SetupLSV(LSVSetup, ESRSetup, ESRFileName);
        LibraryLSV.CreateLSVJournal(LSVJnl, LSVSetup);
        LibraryLSV.CreateLSVCustomer(Customer, LSVSetup."LSV Payment Method Code");
        LibraryLSV.CreateLSVCustomerBankAccount(Customer);
        CreateLSVSalesDoc(SalesHeader, Customer."No.", SalesHeader."Document Type"::Invoice);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesHeader."Last Posting No.")
    end;

    local procedure SuggestLSVJournalLines(var LSVJnl: Record "LSV Journal")
    var
        LSVJnlList: TestPage "LSV Journal List";
    begin
        Commit();
        LSVJnlList.OpenView();
        LSVJnlList.GotoRecord(LSVJnl);

        // We do not care of the message
        LibraryVariableStorage.Enqueue(false);
        LSVJnlList.LSVSuggestCollection.Invoke();
    end;

    local procedure CreateLSVSalesDoc(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; DocType: Enum "Sales Document Type")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.FindItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustomerNo);
        SalesHeader.Validate("Payment Discount %", LibraryRandom.RandDec(10, 2));
        SalesHeader.Validate("Due Date", WorkDate());
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
    end;

    local procedure CollectLSVJournalLines(var LSVJnl: Record "LSV Journal")
    var
        LSVJnlList: TestPage "LSV Journal List";
    begin
        Commit();
        LSVJnlList.OpenView();
        LSVJnlList.GotoRecord(LSVJnl);

        // We do not care of the message
        LibraryVariableStorage.Enqueue(false);
        LSVJnlList.LSVCloseCollection.Invoke();
    end;

    local procedure RetrieveLSVCustomerForCollection() CustomerNo: Code[20]
    var
        CustomerNoAsVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNoAsVar);
        Evaluate(CustomerNo, CustomerNoAsVar);
    end;

    local procedure WriteLSVFile(var LSVJnl: Record "LSV Journal")
    var
        LSVJnlList: TestPage "LSV Journal List";
    begin
        LSVJnlList.OpenView();
        LSVJnlList.GotoRecord(LSVJnl);

        // We do not care of the message
        LibraryVariableStorage.Enqueue(false);
        LSVJnlList.WriteLSVFile.Invoke();
    end;

    local procedure SetupLSV(var LSVSetup: Record "LSV Setup"; var ESRSetup: Record "ESR Setup"; FileName: Text)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        CreateESRSetup(ESRSetup, FileName, ESRAccountNumber1Txt, GLAccount."No.");
        LibraryLSV.CreateLSVSetup(LSVSetup, ESRSetup);
        LSVSetup.Validate("Bal. Account Type", LSVSetup."Bal. Account Type"::"G/L Account");
        LSVSetup.Validate("Bal. Account No.", GLAccount."No.");
        LSVSetup.Validate("DebitDirect Import Filename", TemporaryPath + LSVSetup."LSV Filename");
        LSVSetup.Validate("Backup Folder", TemporaryPath);
        LSVSetup.Validate("Backup Copy", true);
        LSVSetup.Modify(true);
    end;

    [Normal]
    local procedure VerifyImportESRRecordsOfRecordType4OtherCurrency(IsForCRLF: Boolean; IsForReferenceInvoice: Boolean)
    var
        GLAccount: Record "G/L Account";
        ESRSetup: Record "ESR Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        CurrencyCode: Code[3];
        ESRFileName: Text;
        StartingDate: Date;
    begin
        Init();

        LibraryERM.CreateGLAccount(GLAccount);
        CreateExchangeRate(GLAccount, CurrencyCode, StartingDate);
        if IsForReferenceInvoice then
            ESRFileName := RecordType4OtherCurrencyAndReferenceInvoice(IsForCRLF, CurrencyCode, StartingDate)
        else
            ESRFileName := RecordType4OtherCurrency(IsForCRLF, CurrencyCode, StartingDate);

        InvokeESRImport(ESRSetup, GenJournalBatch, ESRAccountNumber4Txt, GLAccount."No.", ESRFileName, 2, CurrencyCode);

        // Verify that import was successfull by verifying that if the verification is for non reference based invoices than
        // a.  Currency code matches
        // b. For reference based invoices a customer entry should be created too.

        GenJournalLine.SetFilter("Journal Batch Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetFilter(
          "Bal. Account Type", '%1|%2',
          GenJournalLine."Account Type"::"G/L Account",
          GenJournalLine."Account Type"::Customer);

        if not IsForReferenceInvoice then
            GenJournalLine.SetFilter("Currency Code", CurrencyCode);
        GenJournalLine.SetFilter("Source Code", 'ESR');

        Assert.IsTrue(GenJournalLine.Count = 2, 'Wrong number of records imported.');

        FILE.Erase(ESRFileName);
    end;

    [Normal]
    local procedure VerifyESRImportBasedOnAccountNumber(ESRAccountNumber: Code[11]; ExpectedImportedRecordNumber: Integer; ExpectedMessageTxt: Text; FileName: Text)
    var
        ESRSetup: Record "ESR Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        InvokeESRImport(ESRSetup, GenJournalBatch, ESRAccountNumber, GLAccount."No.", FileName,
          ExpectedImportedRecordNumber, ExpectedMessageTxt);

        // Verify that import was successfull by verifying the balance account number and type.
        GenJournalLine.SetRange("Bal. Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.SetRange("Bal. Account No.", GLAccount."No.");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Source Code", 'ESR');

        Assert.IsTrue(
          GenJournalLine.Count = ExpectedImportedRecordNumber,
          StrSubstNo('Wrong number of records imported. Expected %1. Actual %2', ExpectedImportedRecordNumber, GenJournalLine.Count));
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
    end;

    [Normal]
    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJournalBatch.Modify(true);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    [Normal]
    local procedure InvokeESRImport(var ESRSetup: Record "ESR Setup"; var GenJournalBatch: Record "Gen. Journal Batch"; ESRAccountNumber: Code[11]; GLAccountNumber: Code[20]; FileName: Text; ExpectedImportedRecordNumber: Integer; ExpectedDialogMsg: Text)
    begin
        if StrLen(ESRSetup."Bank Code") = 0 then
            CreateESRSetup(ESRSetup, FileName, ESRAccountNumber, GLAccountNumber);

        // Create a new batch with no lines.
        CreateGeneralJournalBatch(GenJournalBatch);

        // Open the form Cash Receipt Journal Page and invoke Import ESR file on the batch with no lines.
        LibraryVariableStorage.Enqueue(ESRSetup."Bank Code");
        LibraryVariableStorage.Enqueue(true);

        if StrLen(ExpectedDialogMsg) = 0 then
            LibraryVariableStorage.Enqueue(Format(ExpectedImportedRecordNumber))
        else
            LibraryVariableStorage.Enqueue(Format(ExpectedDialogMsg));

        // Remove all imported lines before invoking the page.
        DeleteESRRelatedGenJournalEntries();
        LoadCashReceiptJournalPageAndInvokeESRImport(GenJournalBatch."Journal Template Name");
    end;

    [Normal]
    local procedure LoadCashReceiptJournalPageAndInvokeESRImport(JournalBatchName: Code[10])
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // Commit is required for opening Cash Receipt Journal Page.
        Commit();
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.CurrentJnlBatchName.SetValue := JournalBatchName;
        CashReceiptJournal.FILTER.SetFilter("Document Type", JournalBatchName);
        CashReceiptJournal."Read ESR File".Invoke();
        CashReceiptJournal.Close();
    end;

    local procedure WriteLine(TmpStream: OutStream; Text: Text)
    begin
        TmpStream.WriteText(Text);
        TmpStream.WriteText();
    end;

    [Normal]
    local procedure CreateFileName() FileName: Text
    begin
        FileName := TemporaryPath() + CopyStr(Format(CreateGuid()), 2, 8);
        Assert.IsTrue(StrLen(FileName) <= 50, StrSubstNo('Cannot create files larger than 50 characters: %1', FileName));
    end;

    [Normal]
    local procedure CreateESRSetup(var ESRSetup: Record "ESR Setup"; ESRFileName: Text; ESRAccountNumber: Code[11]; GLAccountNumber: Code[20])
    var
        TempESRFileName: Code[50];
        ESRBackupFolderName: Code[50];
    begin
        TempESRFileName := CopyStr(ESRFileName, 1, 50);
        ESRBackupFolderName := CopyStr(FileManagement.GetDirectoryName(TempESRFileName) + '\', 1, 50);
        LibraryLSV.CreateESRSetup(ESRSetup);
        ESRSetup.Validate("ESR Filename", TempESRFileName);
        ESRSetup.Validate("Bal. Account Type", ESRSetup."Bal. Account Type"::"G/L Account");
        ESRSetup.Validate("Backup Folder", ESRBackupFolderName);
        ESRSetup.Validate("ESR Account No.", ESRAccountNumber);
        ESRSetup.Validate("ESR Main Bank", true);
        ESRSetup.Validate("Bal. Account No.", GLAccountNumber);
        ESRSetup.Modify(true);
    end;

    [Normal]
    local procedure CreateExchangeRate(var GLAccount: Record "G/L Account"; var CurrencyCode: Code[3]; var StartingDate: Date)
    var
        Currency: Record Currency;
    begin
        // We cannot use LibraryERM since we need exactly 3 bytes CurrencyCodes that we can properly fill out the ESR file.
        CurrencyCode := Format(LibraryRandom.RandIntInRange(100, 999));
        StartingDate := WorkDate();
#if not CLEAN25
        GLAccount."Currency Code" := CurrencyCode;
#else
        GLAccount."Source Currency Code" := CurrencyCode;
#endif
        GLAccount.Modify(true);

        if not Currency.Get(CurrencyCode) then begin
            Currency.Init();
            Currency.Validate(Code, CurrencyCode);
            Currency.Insert(true);
#if not CLEAN25
            LibraryERM.CreateExchangeRate(GLAccount."Currency Code", StartingDate,
              LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
#else
            LibraryERM.CreateExchangeRate(GLAccount."Source Currency Code", StartingDate,
              LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
#endif
        end;
    end;

    [Normal]
    local procedure DeleteESRRelatedGenJournalEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Source Code", 'ESR');
        GenJournalLine.DeleteAll();
    end;

    [Normal]
    local procedure VerifyLSVJournalLine(LSVJournalNo: Integer; CustomerNo: Code[20]; AppliesToDocNo: Code[20]; LSVStatus: Option)
    var
        LSVJournalLine: Record "LSV Journal Line";
    begin
        // Check that the line on the LSV Journal List has the flag
        LSVJournalLine.SetRange("LSV Journal No.", LSVJournalNo);
        LSVJournalLine.SetRange("Customer No.", CustomerNo);
        LSVJournalLine.SetRange("Applies-to Doc. No.", AppliesToDocNo);

        LSVJournalLine.FindFirst();
        Assert.IsTrue(LSVJournalLine."LSV Status" = LSVStatus,
          StrSubstNo('LSV journal Line has wrong status. Expected: %1. Found: %2', LSVStatus, LSVJournalLine."LSV Status"));
    end;

    local procedure ESRImportFile1() FileName: Text
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileName := CreateFileName();
        FileHdl.Create(FileName);
        FileHdl.CreateOutStream(TmpStream);

        WriteLine(TmpStream, '00201200026480006000000000000001000380100000892650' +
          '00000000010033010033010033000000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000503000000327650' +
          '00000000010033010033010033000000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000355400002399500' +
          '00000000010033010033010033000000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000351500002135300' +
          '00000000010033010033010033000000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000509300000971650' +
          '00025216210033010033010033000025216200000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000359900001497350' +
          '008  020010032910032910033000239000100000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000415900015539500' +
          '040  050010032910032910033000292000100000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000267200000689500' +
          '040  050010032910032910033000544000100000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000410600000455700' +
          '00000000010033110033110033100000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000411400000218450' +
          '00000000010033110033110033100000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000378800000109200' +
          '00000000010033110033110033100000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000375600001532750' +
          '00000000010033110033110033100000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000357800000210900' +
          '00000000010033110033110033100000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000387700053709600' +
          '00000000010033110033110033100000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000379300000105450' +
          '00000000010033110033110033100000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000391200000500900' +
          '00000000010033110033110033100000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000393300000067800' +
          '00000000010033110033110033100000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000382400054614000' +
          '00000000010033110033110033100000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000358300014122500' +
          '00000000010033110033110033100000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000404600000052700' +
          '00048782810033110033110033100048782800000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000400700000293750' +
          '00049740310033110033110033100049740300000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000366700007500350' +
          '008  020010033010033010033100188000100000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201200026480006000000000000001000372500000256100' +
          '008  020010033010033010033100213000100000000000000' +
          '                          ');
        WriteLine(TmpStream, '99901200026499999999999999999999999999900001582032' +
          '5000000000023100401000000000000000000             ' +
          '                          ');

        FileHdl.Close();
    end;

    local procedure RecordType3WithoutCRLF() FileName: Text
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileName := CreateFileName();
        FileHdl.Create(FileName);
        FileHdl.CreateOutStream(TmpStream);
        TmpStream.WriteText('00201002654090000300000000000001000140700000534750' +
          '00000000007011107011107011100000000000000000000000' +
          '                            0020100265409000030000' +
          '00000000010010471000007134000000000000701110701110' +
          '7011100000000000000000000000                      ' +
          '      00201002654090000300000000000001001091600000' +
          '71340000000000007011107011107011100000000000000000' +
          '000000                            0020100265409000' +
          '03000000000000010013118000002905000000000000701110' +
          '7011107011100000000000000000000000                ' +
          '            00201002654090000300000000000001001985' +
          '40000048905000000000007011107011107011100000000000' +
          '000000000000                            0020100265' +
          '40900003000000000000010020859000003389500000000000' +
          '7011107011107011100000000000000000000000          ' +
          '                  00201002654090000300000000000001' +
          '00222380000006455000000000007011107011107011100000' +
          '000000000000000000                            0020' +
          '10026540900003000000000000010023014000003551000000' +
          '0000007011107011107011100000000000000000000000    ' +
          '                        00201002654090000300000000' +
          '00000100240000000009685000000000007011107011107011' +
          '100000000000000000000000                          ' +
          '  002010026540900003000000000000010024110000000645' +
          '50000000000070111070111070111000000000000000000000' +
          '00                            00201002654090000300' +
          '00000000000100242230000014850000000000007011107011' +
          '107011100000000000000000000000                    ' +
          '        002010026540900003000000000000010032483000' +
          '00532600000000000070111070111070111000000000000000' +
          '00000000                            01201002654090' +
          '00030000010111111326424600000013245000000000006122' +
          '807010307010300000000000000000000145              ' +
          '              002010026540900003000001011209532646' +
          '46400000639250000000000070108070108070108000000000' +
          '00000000000000                            00201002' +
          '65409000030000010117033262665090000700000000000000' +
          '007011107011107011100000000000000000000000        ' +
          '                    002010026540900003000001011715' +
          '73264948900000344700000000000061229070103070103000' +
          '00000000000000000000                            00' +
          '20100265409000030000010122106262618660000027760000' +
          '000000007010807010807010800000000000000000000000  ' +
          '                          002010026540900003000001' +
          '01221062626187400008050650000000000070108070108070' +
          '10800000000000000000000000                        ' +
          '    0020100265409000030000010122106262618820000079' +
          '09500000000000701080701080701080000000000000000000' +
          '0000                            002010026540900003' +
          '00000101221063264453500000186950000000000070108070' +
          '10807010800000000000000000000000                  ' +
          '          0020100265409000030000010123053326501550' +
          '00000748000000000000701100701100701100000000000000' +
          '0000000000                            002010026540' +
          '90000300000101230652625877900000232450000000000070' +
          '10507010507010500000000000000000000000            ' +
          '                0020100265409000030000010134103326' +
          '44936000000835000000000000701110701110701110000000' +
          '0000000000000000                            002010' +
          '02654090000300000101350142626133500000018400000000' +
          '00007011007011107011100000000000000000000000      ' +
          '                      0020100265409000030000010135' +
          '01426261340001426123500000000000701100701110701110' +
          '0000000000000000000000                            ' +
          '00201002654090000300000101350142626135100001436700' +
          '00000000007011007011107011100000000000000000000000' +
          '                            0020100265409000030000' +
          '01013501426261366000004287500000000000701100701110' +
          '7011100000000000000000000000                      ' +
          '      00201002654090000300000101350142626137400443' +
          '95775000000000007011007011107011100000000000000000' +
          '000000                            0020100265409000' +
          '03000001013501426261382000008070000000000000701100' +
          '7011107011100000000000000000000000                ' +
          '            00201002654090000300000101380432621771' +
          '00000017050000000000007011107011107011100000000000' +
          '000000000000                            0020100265' +
          '40900003000001013804326234618000001895500000000000' +
          '7011107011107011100000000000000000000000          ' +
          '                  00201002654090000300000101390253' +
          '26499000000036610000000000007010507010807010800000' +
          '000000000000000000                            0020' +
          '10026540900003000001013902532650167000002867500000' +
          '0000007010507010807010800000000000000000000000    ' +
          '                        00201002654090000300000101' +
          '39025326506870000022060000000000007011007011107011' +
          '100000000000000000000000                          ' +
          '  002010026540900003000001014110332646295000004029' +
          '50000000000070105070108070108000000000000000000000' +
          '00                            00201002654090000300' +
          '00010144002326463500001838510000000000007010507010' +
          '507010500000000000000000000000                    ' +
          '        002010026540900003000001015097732645791000' +
          '00220600000000000070103070104070104000000000000000' +
          '00000000                            00201002654090' +
          '00030000010151541326441800000012275000000000007010' +
          '307010307010300000000000000000000000              ' +
          '              002010026540900003000001015207732646' +
          '09500000275100000000000070111070111070111000000000' +
          '00000000000000                            00201002' +
          '65409000030000010152486326456030000016410000000000' +
          '007010507010507010500000000000000000000000        ' +
          '                    002010026540900003000001015250' +
          '13265001500001182000000000000070109070110070110000' +
          '00000000000000000000                            00' +
          '20100265409000030000010153111262656920000055595000' +
          '000000007010507010807010800000000000000000000000  ' +
          '                          002010026540900003000001' +
          '01531112626571100000691050000000000070105070108070' +
          '10800000000000000000000000                        ' +
          '    0020100265409000030000010153213326431490000015' +
          '33500000000000701050701050701050000000000000000000' +
          '0000                            002010026540900003' +
          '00000101534892626207200000287300000000000070108070' +
          '10907010900000000000000000000000                  ' +
          '          0020100265409000030000010153489262620880' +
          '00002001500000000000701080701090701090000000000000' +
          '0000000000                            002010026540' +
          '90000300000101534893265043800000277050000000000070' +
          '10807010907010900000000000000000000000            ' +
          '                0020100265409000030000010153833262' +
          '54869000001528000000000000612290701030701030000000' +
          '0000000000000000                            002010' +
          '02654090000300000101538332625490400000842100000000' +
          '00007010307010307010300000000000000000000000      ' +
          '                      0020100265409000030000010153' +
          '83326254912000001100000000000000612290701030701030' +
          '0000000000000000000000                            ' +
          '00201002654090000300000101546183265009900000267600' +
          '00000000007010407010407010400000000000000000000000' +
          '                            0020100265409000030000' +
          '01015461832650353000000721000000000000701040701040' +
          '7010400000000000000000000000                      ' +
          '      00201002654090000300000101546183265115300000' +
          '15335000000000007010407010407010400000000000000000' +
          '000000                            0020100265409000' +
          '03000001015605632645966000000861000000000000701090' +
          '7010907010900000000000000000000000                ' +
          '            00201002654090000300000101567313264289' +
          '70000234255000000000007010307010407010400000000000' +
          '000000000000                            0020100265' +
          '40900003000001015673132642902000002033500000000000' +
          '7010307010407010400000000000000000000000          ' +
          '                  00201002654090000300000101567313' +
          '26429180000010760000000000007010307010407010400000' +
          '000000000000000000                            0020' +
          '10026540900003000001015699232641732000002469500000' +
          '0000007010807010907010900000000000000000000000    ' +
          '                        00201002654090000300000101' +
          '57150262566620000709155000000000007010807010807010' +
          '800000000000000000000000                          ' +
          '  012010026540900003000001015747032651581000000368' +
          '00000000000070105070109070109000000000000000000000' +
          '90                            00201002654090000300' +
          '00010158773326478570000059450000000000007010907011' +
          '007011000000000000000000000000                    ' +
          '        002010026540900003000001020103732651967000' +
          '11300400000000000070109070110070110000000000000000' +
          '00000000                            00201002654090' +
          '00030000010201103326460390000022060000000000007010' +
          '507010807010800000000000000000000000              ' +
          '              002010026540900003000001021209126259' +
          '61800000004850000000000070103070103070103000000000' +
          '00000000000000                            00201002' +
          '65409000030000010217094326440020000015765000000000' +
          '007010307010307010300000000000000000000000        ' +
          '                    002010026540900003000001021900' +
          '73264390200001257400000000000070105070105070105000' +
          '00000000000000000000                            00' +
          '20100265409000030000010219007326450950000150005000' +
          '000000007010507010507010500000000000000000000000  ' +
          '                          002010026540900003000001' +
          '02190073264510500002310700000000000070105070105070' +
          '10500000000000000000000000                        ' +
          '    0020100265409000030000010221057262571230000024' +
          '75000000000000701080701080701080000000000000000000' +
          '0000                            002010026540900003' +
          '00000102230022625612700000025800000000000070105070' +
          '10507010500000000000000000000000                  ' +
          '          0020100265409000030000010223002262561350' +
          '00000258000000000000701050701050701050000000000000' +
          '0000000000                            002010026540' +
          '90000300000102230022625614000000025800000000000070' +
          '10507010507010500000000000000000000000            ' +
          '                0020100265409000030000010223002326' +
          '46704000000767000000000000701050701050701050000000' +
          '0000000000000000                            002010' +
          '02654090000300000102230412625875900000033850000000' +
          '00007010407010507010500000000000000000000000      ' +
          '                      0020100265409000030000010223' +
          '04132644678000003658500000000000701040701050701050' +
          '0000000000000000000000                            ' +
          '00201002654090000300000102411252625917200032111510' +
          '00000000007011007011107011100000000000000000000000' +
          '                            0020100265409000030000' +
          '01024112526259188000023164500000000000701100701110' +
          '7011100000000000000000000000                      ' +
          '      00201002654090000300000102411252625919300003' +
          '46040000000000007011007011107011100000000000000000' +
          '000000                            0020100265409000' +
          '03000001024112526259201000006520500000000000701100' +
          '7011107011100000000000000000000000                ' +
          '            00201002654090000300000102411252625923' +
          '20000139535000000000007011007011107011100000000000' +
          '000000000000                            0020100265' +
          '40900003000001024112526259248000001179500000000000' +
          '7011007011107011100000000000000000000000          ' +
          '                  00201002654090000300000102411513' +
          '26467490000016410000000000007010907010907010900000' +
          '000000000000000000                            0020' +
          '10026540900003000001024213232646584000001361000000' +
          '0000007011007011007011000000000000000000000000    ' +
          '                        00201002654090000300000102' +
          '42181262539220000018810000000000007010307010307010' +
          '300000000000000000000000                          ' +
          '  002010026540900003000001024218126253938000000645' +
          '50000000000070103070103070103000000000000000000000' +
          '00                            00201002654090000300' +
          '00010242181262539430000062195000000000007010307010' +
          '307010300000000000000000000000                    ' +
          '        002010026540900003000001024306926257355000' +
          '00484200000000000070104070104070104000000000000000' +
          '00000000                            00201002654090' +
          '00030000010243069262575150001636848000000000007010' +
          '407010407010400000000000000000000000              ' +
          '              002010026540900003000001024306926257' +
          '52000114464840000000000070104070104070104000000000' +
          '00000000000000                            00201002' +
          '65409000030000010243069262575310000271525000000000' +
          '007010407010407010400000000000000000000000        ' +
          '                    002010026540900003000001024306' +
          '92625754600000878650000000000070104070104070104000' +
          '00000000000000000000                            00' +
          '20100265409000030000010243069262575540000180785000' +
          '000000007010407010407010400000000000000000000000  ' +
          '                          002010026540900003000001' +
          '02430692625756200000356350000000000070104070104070' +
          '10400000000000000000000000                        ' +
          '    0020100265409000030000010243069262575780000011' +
          '38000000000000701040701040701040000000000000000000' +
          '0000                            002010026540900003' +
          '00000102430692625758300000147700000000000070104070' +
          '10407010400000000000000000000000                  ' +
          '          0020100265409000030000010243069262575990' +
          '00010576500000000000701040701040701040000000000000' +
          '0000000000                            002010026540' +
          '90000300000106460742626209200000015350000000000070' +
          '11107011107011100000000000000000000000            ' +
          '                0020100265409000030000010646074262' +
          '62100000000398500000000000701110701110701110000000' +
          '0000000000000000                            002010' +
          '02654090000300000106460742626218700000161150000000' +
          '00007011107011107011100000000000000000000000      ' +
          '                      0020100265409000030000010646' +
          '07426262195000001467000000000000701110701110701110' +
          '0000000000000000000000                            ' +
          '00201002654090000300000106460742626220500000009100' +
          '00000000007011107011107011100000000000000000000000' +
          '                            0020100265409000030000' +
          '01064607426262221000001622500000000000701110701110' +
          '7011100000000000000000000000                      ' +
          '      00201002654090000300000106503852626182400000' +
          '52100000000000007010407010407010400000000000000000' +
          '000000                            0020100265409000' +
          '03000001065038526261848000002711500000000000701040' +
          '7010407010400000000000000000000000                ' +
          '            00201002654090000300000106576022625621' +
          '80000015765000000000007011107011107011100000000000' +
          '000000000000                            0020100265' +
          '40900003000001065792332645171000006441000000000000' +
          '7010307010307010300000000000000000000000          ' +
          '                  00201002654090000300000106587003' +
          '26474770000010330000000000007010907010907010900000' +
          '000000000000000000                            9990' +
          '10026540999999999999999999999999999000084728258000' +
          '000000107070111000002260000000000                 ' +
          '                        ');

        FileHdl.Close();
    end;

    local procedure RecordType3WithCRLF() FileName: Text
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileName := CreateFileName();
        FileHdl.Create(FileName);
        FileHdl.CreateOutStream(TmpStream);

        WriteLine(TmpStream, '00201004056420234300000111111108410029400000191700' +
          '00000000098092998092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108410001100000051400' +
          '00000000098092898092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '01201004056420234300000111111108409926600000014000' +
          '00000000098092498092908092900670208600000000000060' +
          '                          ');
        WriteLine(TmpStream, '01201004056420234300000111111108409699000000266700' +
          '00000000098092498092908092900003009400000000000145' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409655100008800000' +
          '00000000098092998092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '01201004056420234300000111111108409605700000114450' +
          '00000000098092498092908092900713540800000000000145' +
          '                          ');
        WriteLine(TmpStream, '01201004056420234300000111111108409534500000022400' +
          '00000000098092498092908092900571467400000000000060' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409459200000022400' +
          '00000000098092498092908092900077020900000000000000' +
          '                          ');
        WriteLine(TmpStream, '01201004056420234300000111111108409446500000439850' +
          '00000000098092498092908092900673204600000000000145' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409429300000049400' +
          '00000000098092498092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409330200000201400' +
          '00000000098092598092908092900002053200000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409310000000169550' +
          '00000000098092998092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409299200000349450' +
          '00000000098092998092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409281200000704800' +
          '00000000098092398092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409273200000043200' +
          '00000000098092498092908092900002007400000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409269300000056650' +
          '00000000098092998092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409258000000204800' +
          '00000000098092498092908092900013000300000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409217300000596600' +
          '00000000098092998092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409188200001126200' +
          '00000000098092998092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409185100000234400' +
          '00000000098092298092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409169700000176050' +
          '00000000098092898092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409163600000495250' +
          '00000000098092698092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '01201004056420234300000111111108409146100001285450' +
          '00000000098092498092908092900260524400000000000265' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409123200000487750' +
          '00000000098092998092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108406309900008647550' +
          '00000000098092998092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108408567500005444700' +
          '00000000098092498092908092900006009200000000000000' +
          '                          ');
        WriteLine(TmpStream, '00501004056420234300000111111108408476900000103950' +
          '00000000098091498092908092900800007800000000000000' +
          '                          ');
        WriteLine(TmpStream, '10201004056420234300000111111108408399900002286950' +
          '00000000098092498092908092900018030100000000000000' +
          '                          ');
        WriteLine(TmpStream, '00501004056420234300000111111108408274200000046850' +
          '00000000098091498092908092900800007700000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409110900000306600' +
          '00000000098092998092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409085200000726400' +
          '00000000098092598092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409070000001518750' +
          '00000000098092998092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '01201004056420234300000111111108409058100000819900' +
          '00000000098092498092908092900002011300000000000145' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409017800000868750' +
          '00000000098092998092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409016200000323550' +
          '00000000098092998092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108409009800000166800' +
          '00000000098092898092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '01201004056420234300000111111108408998900000562650' +
          '00000000098092498092908092900263772900000000000145' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108408974500000249250' +
          '00000000098092998092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108408968100000788100' +
          '00000000098092898092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '01201004056420234300000111111108408887200000185550' +
          '00000000098092498092908092900661669800000000000145' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108408882500000029250' +
          '00000000098092598092908092900800014000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108408853500001420250' +
          '00000000098092598092908092800000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '01201004056420234300000111111108408739200002798550' +
          '00000000098092498092908092900577849200000000000265' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108408623000000044400' +
          '00000000098092898092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '00201004056420234300000111111108408588500000255700' +
          '00000000098092398092908092900000000000000000000000' +
          '                          ');
        WriteLine(TmpStream, '99901004056499999999999999999999999999900000433967' +
          '0000000000045980929000001520000000004             ' +
          '                          ');

        FileHdl.Close();
    end;

    [Normal]
    local procedure RecordType3WithoutCRLFAndReferenceInvoice() FileName: Text
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileName := CreateFileName();
        FileHdl.Create(FileName);
        FileHdl.CreateOutStream(TmpStream);
        TmpStream.WriteText(
          '0020100016281234560400000000000010301860000761270000000000001012001012008012000000000000000000000000' +
          '                            ' +
          '0020100016281234560400200000000010300900000039140000000000001012001012008012000000000000000000000000' +
          '                            ' +
          '999010001628999999999999999999999999999000000800410000000000002010120000000000000000000' +
          '                                         ');

        FileHdl.Close();
    end;

    local procedure RecordType3WithCRLFAndReferenceInvoice() FileName: Text
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileName := CreateFileName();
        FileHdl.Create(FileName);
        FileHdl.CreateOutStream(TmpStream);

        WriteLine(TmpStream, '00201000162812345604000000000000103018600007612700' +
          '00000000001012001012008012000000000000000000000000');
        WriteLine(TmpStream, '00201000162812345604002000000000103009000000391400' +
          '00000000001012001012008012000000000000000000000000');
        WriteLine(TmpStream, '99901000162899999999999999999999999999900000080041' +
          '0000000000002010120000000000000000000             ');

        FileHdl.Close();
    end;

    local procedure CorruptRecordType4WithoutCRLF() FileName: Text
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileName := CreateFileName();
        FileHdl.Create(FileName);
        FileHdl.CreateOutStream(TmpStream);

        TmpStream.WriteText('211011030000022000000000009876268207900079EUR00000' +
          '00190150002000101100121000230001200000001220001009' +
          '20001011200010120CHF000205                        ' +
          '                                                  ' +
          '311021030000022000000000009876268207900079EUR00000' +
          '00180000002000101400121000020001200000001220001014' +
          '20001014200010160CHF000000                        ' +
          '                                                  ' +
          '311021030000022000000000009876268207900079EUR00000' +
          '00380300002000101300121000020001200000001220001014' +
          '20001014200010160CHF000000                        ' +
          '                                                  ' +
          '211011030000022000011111255455698788904785EUR00000' +
          '00010150002000101100121000230001300000001220001009' +
          '20001011200010120CHF000060                        ' +
          '                                                  ' +
          '211021030000022000011111255455698788904785EUR00000' +
          '00010150002000101300121000020001300000001220001014' +
          '20001014200010160CHF000000                        ' +
          '                                                  ' +
          '211021030000022000011111255455698788904785EUR00000' +
          '00010150002000101400121000020001300000001220001014' +
          '20001014200010160CHF000000                        ' +
          '                                                  ' +
          '211021030000022004000000000002667871312801EUR00000' +
          '00180750002000101800102000000420400000011220001018' +
          '20001018200010190CHF000000                        ' +
          '                                                  ' +
          '211021030000022302355339450400102302000087EUR00000' +
          '00200800002000092700102000000231400000011220000927' +
          '20000927200009280CHF000000                        ' +
          '                                                  ' +
          '981991030000022999999999999999999999999999EUR00000' +
          '011624500000000000820001020CHF00000000265         ' +
          '                                                  ' +
          '                                                  ' +
          '011011010480627000000000000000000598989529CHF00000' +
          '00100000002000101100121000120000200000001220001008' +
          '20001011200010121CHF000145                        ' +
          '                                                  ' +
          '011021010480627000000000000000000598989529CHF00000' +
          '00170950002000101600121000210000300000001220001017' +
          '20001017200010181CHF000000                        ' +
          '                                                  ' +
          '011011010480627000000000000000000598989529CHF00000' +
          '00200000002000101100121000230000300000001220001009' +
          '20001011200010120CHF000145                        ' +
          '                                                  ' +
          '011011010480627000000000000000000598989529CHF00000' +
          '00250050002000101100121000110000300000001220001008' +
          '20001011200010121CHF000145                        ' +
          '                                                  ' +
          '011011010480627000000000000000000598989529CHF00000' +
          '00250050002000101100121000110000400000001220001008' +
          '20001011200010121CHF000145                        ' +
          '                                                  ' +
          '011011010480627000000000000000000598989529CHF00000' +
          '00250050002000101100121000120000300000001220001008' +
          '20001011200010121CHF000145                        ' +
          '                                                  ' +
          '011011010480627000000000000000000598989529CHF00000' +
          '00250050002000101100121000120000400000001220001008' +
          '20001011200010121CHF000145                        ' +
          '                                                  ' +
          '011011010480627000000000000000000598989529CHF00000' +
          '00250050002000101100121000230000200000001220001009' +
          '20001011200010120CHF000145                        ' +
          '                                                  ' +
          '011011010480627000000000000000000598989529CHF00000' +
          '00250050002000101100121000230000500000001220001009' +
          '20001011200010120CHF000145                        ' +
          '                                                  ' +
          '011021010480627000000000000000000598989529CHF00000' +
          '00250050002000101200121000040000300000001220001012' +
          '20001012200010131CHF000000                        ' +
          '                                                  ' +
          '011021010480627000000000000000000598989529CHF00000' +
          '00250050002000101300121000030000300000001220001014' +
          '20001014200010161CHF000000                        ' +
          '                                                  ' +
          '011021010480627000000000000000000598989529CHF00000' +
          '00250050002000101400121000010000300000001220001014' +
          '20001014200010161CHF000000                        ' +
          '                                                  ' +
          '011021010480627000000000000000000598989529CHF00000' +
          '00250050002000101400121000020000200000001220001014' +
          '20001014200010160CHF000000                        ' +
          '                                                  ' +
          '011011010480627000000000000000000598989529CHF00000' +
          '00300000002000101100121000230000400000001220001009' +
          '20001011200010120CHF000145                        ' +
          '                                                  ' +
          '011011010480627000000000000000000598989529CHF00000' +
          '02200300002000101100121000110000200000001220001008' +
          '20001011200010121CHF001450                        ' +
          '                                                  ' +
          '011021010480627000000000000000000598989529CHF00000' +
          '03200400002000101300121000020000200000001220001014' +
          '20001014200010160CHF000000                        ' +
          '                                                  ' +
          '031021010480627000000000000000000598989529CHF00000' +
          '00250050002000101300121000020000500000001220001014' +
          '20001014200010160CHF000000                        ' +
          '                                                  ' +
          '031021010480627000000000000000000598989529CHF00000' +
          '00250050002000101400121000010000200000001220001014' +
          '20001014200010161CHF000000                        ' +
          '                                                  ' +
          '031021010480627000000000000000000598989529CHF00000' +
          '00250050002000101400121000020000500000001220001014' +
          '20001014200010160CHF000000                        ' +
          '                                                  ' +
          '031021010480627000000000000000000598989529CHF00000' +
          '00600100002000101200121000040000200000001220001012' +
          '20001012200010131CHF000000                        ' +
          '                                                  ' +
          '111021010480627000000000000000000598989529CHF00000' +
          '00200000002000101300121000020000300000001220001014' +
          '20001014200010160CHF000000                        ' +
          '                                                  ' +
          '111021010480627000000000000000000598989529CHF00000' +
          '00200000002000101400121000020000300000001220001014' +
          '20001014200010160CHF000000                        ' +
          '                                                  ' +
          '131021010480627000000000000000000598989529CHF00000' +
          '00100000002000101200121000040000400000001220001012' +
          '20001012200010131CHF000000                        ' +
          '                                                  ' +
          '131021010480627000000000000000000598989529CHF00000' +
          '00100000002000101300121000030000400000001220001014' +
          '20001014200010161CHF000000                        ' +
          '                                                  ' +
          '131021010480627000000000000000000598989529CHF00000' +
          '00100000002000101400121000010000400000001220001014' +
          '20001014200010161CHF000000                        ' +
          '                                                  ' +
          '131021010480627000000000000000000598989529CHF00000' +
          '00300000002000101300121000020000400000001220001014' +
          '20001014200010160CHF000000                        ' +
          '                                                  ' +
          '131021010480627000000000000000000598989529CHF00000' +
          '00300000002000101400121000020000400000001220001014' +
          '20001014200010160CHF000000                        ' +
          '                                                  ' +
          '011021010480627000000011111111111111111111CHF00000' +
          '00250050002000101300121000030000200000001220001014' +
          '20001014200010160CHF000000                        ' +
          '                                                  ' +
          '991991010480627999999999999999999999999999CHF00000' +
          '115724500000000002820001020CHF00000002755         ' +
          '                                                  ' +
          '                                                  ');

        FileHdl.Close();
    end;

    local procedure RecordType4CHFWithoutCRLF() FileName: Text
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileName := CreateFileName();
        FileHdl.Create(FileName);
        FileHdl.CreateOutStream(TmpStream);

        TmpStream.WriteText('011011010480627000000000000000000598989529CHF00000' +
          '00100000002000101100121000120000200000001220001008' +
          '20001011200710121CHF000145                        ' +
          '                                                  ' +
          '011021010480627000000000000000000598989529CHF00000' +
          '00170950002000101600121000210000300000001220001017' +
          '20001017200710181CHF000000                        ' +
          '                                                  ' +
          '011011010480627000000000000000000598989529CHF00000' +
          '00200000002000101100121000230000300000001220001009' +
          '20001011200710120CHF000145                        ' +
          '                                                  ' +
          '011011010480627000000000000000000598989529CHF00000' +
          '00250050002000101100121000110000300000001220001008' +
          '20001011200710121CHF000145                        ' +
          '                                                  ' +
          '011011010480627000000000000000000598989529CHF00000' +
          '00250050002000101100121000110000400000001220001008' +
          '20001011200710121CHF000145                        ' +
          '                                                  ' +
          '011011010480627000000000000000000598989529CHF00000' +
          '00250050002000101100121000120000300000001220001008' +
          '20001011200710121CHF000145                        ' +
          '                                                  ' +
          '011011010480627000000000000000000598989529CHF00000' +
          '00250050002000101100121000120000400000001220001008' +
          '20001011200710121CHF000145                        ' +
          '                                                  ' +
          '011011010480627000000000000000000598989529CHF00000' +
          '00250050002000101100121000230000200000001220001009' +
          '20001011200710120CHF000145                        ' +
          '                                                  ' +
          '011011010480627000000000000000000598989529CHF00000' +
          '00250050002000101100121000230000500000001220001009' +
          '20001011200710120CHF000145                        ' +
          '                                                  ' +
          '011021010480627000000000000000000598989529CHF00000' +
          '00250050002000101200121000040000300000001220001012' +
          '20001012200710131CHF000000                        ' +
          '                                                  ' +
          '011021010480627000000000000000000598989529CHF00000' +
          '00250050002000101300121000030000300000001220001014' +
          '20001014200710161CHF000000                        ' +
          '                                                  ' +
          '011021010480627000000000000000000598989529CHF00000' +
          '00250050002000101400121000010000300000001220001014' +
          '20001014200710161CHF000000                        ' +
          '                                                  ' +
          '011021010480627000000000000000000598989529CHF00000' +
          '00250050002000101400121000020000200000001220001014' +
          '20001014200710160CHF000000                        ' +
          '                                                  ' +
          '011011010480627000000000000000000598989529CHF00000' +
          '00300000002000101100121000230000400000001220001009' +
          '20001011200710120CHF000145                        ' +
          '                                                  ' +
          '011011010480627000000000000000000598989529CHF00000' +
          '02200300002000101100121000110000200000001220001008' +
          '20001011200710121CHF001450                        ' +
          '                                                  ' +
          '011021010480627000000000000000000598989529CHF00000' +
          '03200400002000101300121000020000200000001220001014' +
          '20001014200710160CHF000000                        ' +
          '                                                  ' +
          '031021010480627000000000000000000598989529CHF00000' +
          '00250050002000101300121000020000500000001220001014' +
          '20001014200710160CHF000000                        ' +
          '                                                  ' +
          '031021010480627000000000000000000598989529CHF00000' +
          '00250050002000101400121000010000200000001220001014' +
          '20001014200710161CHF000000                        ' +
          '                                                  ' +
          '031021010480627000000000000000000598989529CHF00000' +
          '00250050002000101400121000020000500000001220001014' +
          '20001014200710160CHF000000                        ' +
          '                                                  ' +
          '031021010480627000000000000000000598989529CHF00000' +
          '00600100002000101200121000040000200000001220001012' +
          '20001012200710131CHF000000                        ' +
          '                                                  ' +
          '111021010480627000000000000000000598989529CHF00000' +
          '00200000002000101300121000020000300000001220001014' +
          '20001014200710160CHF000000                        ' +
          '                                                  ' +
          '111021010480627000000000000000000598989529CHF00000' +
          '00200000002000101400121000020000300000001220001014' +
          '20001014200710160CHF000000                        ' +
          '                                                  ' +
          '131021010480627000000000000000000598989529CHF00000' +
          '00100000002000101200121000040000400000001220001012' +
          '20001012200710131CHF000000                        ' +
          '                                                  ' +
          '131021010480627000000000000000000598989529CHF00000' +
          '00100000002000101300121000030000400000001220001014' +
          '20001014200710161CHF000000                        ' +
          '                                                  ' +
          '131021010480627000000000000000000598989529CHF00000' +
          '00100000002000101400121000010000400000001220001014' +
          '20001014200710161CHF000000                        ' +
          '                                                  ' +
          '131021010480627000000000000000000598989529CHF00000' +
          '00300000002000101300121000020000400000001220001014' +
          '20001014200710160CHF000000                        ' +
          '                                                  ' +
          '131021010480627000000000000000000598989529CHF00000' +
          '00300000002000101400121000020000400000001220001014' +
          '20001014200010160CHF000000                        ' +
          '                                                  ' +
          '011021010480627000000011111111111111111111CHF00000' +
          '00250050002000101300121000030000200000001220001014' +
          '20001014200710160CHF000000                        ' +
          '                                                  ' +
          '991991010480627999999999999999999999999999CHF00000' +
          '115724500000000002820001020CHF00000002755         ' +
          '                                                  ' +
          '                                                  ');

        FileHdl.Close();
    end;

    local procedure RecordType4OtherCurrency(IsWithCRLF: Boolean; CurrencyCode: Text; StartingDate: Date) FileName: Text
    var
        TmpStream: OutStream;
        FileHdl: File;
        FormattedDate: Text;
        Buffer: Text;
        Cr: Char;
        Lf: Char;
    begin
        FileName := CreateFileName();
        FileHdl.Create(FileName);
        FileHdl.CreateOutStream(TmpStream);
        FormattedDate := Format(StartingDate, 0, '<Year4><Month,2><Day,2>');
        Buffer := '211011030000022000000000009876268207900079' +
          CurrencyCode +
          '000000019015000200010110012100023000120000000122000100920001011' +
          FormattedDate +
          '0CHF000205' + PadStr(' ', 74);

        if IsWithCRLF then begin
            Cr := 13;
            Lf := 10;
            Buffer := Buffer + Format(Cr) + Format(Lf);
        end;

        Buffer := Buffer + '981991030000022999999999999999999999999999' +
          CurrencyCode +
          '00000001901500000000000120001020CHF00000000265' +
          PadStr(' ', 109);

        TmpStream.WriteText(Buffer);

        FileHdl.Close();
    end;

    [Normal]
    local procedure RecordType4CHFWithCRLF() FileName: Text
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileName := CreateFileName();
        FileHdl.Create(FileName);
        FileHdl.CreateOutStream(TmpStream);
        WriteLine(TmpStream, '011011010480627000000000000000000598989529CHF00000' +
          '00100000002000101100121000120000200000001220001008' +
          '20001011200710121CHF000145                        ' +
          '                                                  ');
        WriteLine(TmpStream, '011021010480627000000000000000000598989529CHF00000' +
          '00170950002000101600121000210000300000001220001017' +
          '20001017200710181CHF000000                        ' +
          '                                                  ');
        WriteLine(TmpStream, '011011010480627000000000000000000598989529CHF00000' +
          '00200000002000101100121000230000300000001220001009' +
          '20001011200710120CHF000145                        ' +
          '                                                  ');
        WriteLine(TmpStream, '011011010480627000000000000000000598989529CHF00000' +
          '00250050002000101100121000110000300000001220001008' +
          '20001011200710121CHF000145                        ' +
          '                                                  ');
        WriteLine(TmpStream, '011011010480627000000000000000000598989529CHF00000' +
          '00250050002000101100121000110000400000001220001008' +
          '20001011200710121CHF000145                        ' +
          '                                                  ');
        WriteLine(TmpStream, '011011010480627000000000000000000598989529CHF00000' +
          '00250050002000101100121000120000300000001220001008' +
          '20001011200710121CHF000145                        ' +
          '                                                  ');
        WriteLine(TmpStream, '011011010480627000000000000000000598989529CHF00000' +
          '00250050002000101100121000120000400000001220001008' +
          '20001011200710121CHF000145                        ' +
          '                                                  ');
        WriteLine(TmpStream, '011011010480627000000000000000000598989529CHF00000' +
          '00250050002000101100121000230000200000001220001009' +
          '20001011200710120CHF000145                        ' +
          '                                                  ');
        WriteLine(TmpStream, '011011010480627000000000000000000598989529CHF00000' +
          '00250050002000101100121000230000500000001220001009' +
          '20001011200710120CHF000145                        ' +
          '                                                  ');
        WriteLine(TmpStream, '011021010480627000000000000000000598989529CHF00000' +
          '00250050002000101200121000040000300000001220001012' +
          '20001012200710131CHF000000                        ' +
          '                                                  ');
        WriteLine(TmpStream, '011021010480627000000000000000000598989529CHF00000' +
          '00250050002000101300121000030000300000001220001014' +
          '20001014200710161CHF000000                        ' +
          '                                                  ');
        WriteLine(TmpStream, '011021010480627000000000000000000598989529CHF00000' +
          '00250050002000101400121000010000300000001220001014' +
          '20001014200710161CHF000000                        ' +
          '                                                  ');
        WriteLine(TmpStream, '011021010480627000000000000000000598989529CHF00000' +
          '00250050002000101400121000020000200000001220001014' +
          '20001014200710160CHF000000                        ' +
          '                                                  ');
        WriteLine(TmpStream, '011011010480627000000000000000000598989529CHF00000' +
          '00300000002000101100121000230000400000001220001009' +
          '20001011200710120CHF000145                        ' +
          '                                                  ');
        WriteLine(TmpStream, '011011010480627000000000000000000598989529CHF00000' +
          '02200300002000101100121000110000200000001220001008' +
          '20001011200710121CHF001450                        ' +
          '                                                  ');
        WriteLine(TmpStream, '011021010480627000000000000000000598989529CHF00000' +
          '03200400002000101300121000020000200000001220001014' +
          '20001014200710160CHF000000                        ' +
          '                                                  ');
        WriteLine(TmpStream, '031021010480627000000000000000000598989529CHF00000' +
          '00250050002000101300121000020000500000001220001014' +
          '20001014200710160CHF000000                        ' +
          '                                                  ');
        WriteLine(TmpStream, '031021010480627000000000000000000598989529CHF00000' +
          '00250050002000101400121000010000200000001220001014' +
          '20001014200710161CHF000000                        ' +
          '                                                  ');
        WriteLine(TmpStream, '031021010480627000000000000000000598989529CHF00000' +
          '00250050002000101400121000020000500000001220001014' +
          '20001014200710160CHF000000                        ' +
          '                                                  ');
        WriteLine(TmpStream, '031021010480627000000000000000000598989529CHF00000' +
          '00600100002000101200121000040000200000001220001012' +
          '20001012200710131CHF000000                        ' +
          '                                                  ');
        WriteLine(TmpStream, '111021010480627000000000000000000598989529CHF00000' +
          '00200000002000101300121000020000300000001220001014' +
          '20001014200710160CHF000000                        ' +
          '                                                  ');

        WriteLine(TmpStream, '111021010480627000000000000000000598989529CHF00000' +
          '00200000002000101400121000020000300000001220001014' +
          '20001014200710160CHF000000                        ' +
          '                                                  ');
        WriteLine(TmpStream, '131021010480627000000000000000000598989529CHF00000' +
          '00100000002000101200121000040000400000001220001012' +
          '20001012200710131CHF000000                        ' +
          '                                                  ');
        WriteLine(TmpStream, '131021010480627000000000000000000598989529CHF00000' +
          '00100000002000101300121000030000400000001220001014' +
          '20001014200710161CHF000000                        ' +
          '                                                  ');
        WriteLine(TmpStream, '131021010480627000000000000000000598989529CHF00000' +
          '00100000002000101400121000010000400000001220001014' +
          '20001014200710161CHF000000                        ' +
          '                                                  ');
        WriteLine(TmpStream, '131021010480627000000000000000000598989529CHF00000' +
          '00300000002000101300121000020000400000001220001014' +
          '20001014200710160CHF000000                        ' +
          '                                                  ');
        WriteLine(TmpStream, '131021010480627000000000000000000598989529CHF00000' +
          '00300000002000101400121000020000400000001220001014' +
          '20001014200710160CHF000000                        ' +
          '                                                  ');
        WriteLine(TmpStream, '011021010480627000000011111111111111111111CHF00000' +
          '00250050002000101300121000030000200000001220001014' +
          '20001014200710160CHF000000                        ' +
          '                                                  ');
        WriteLine(TmpStream, '991991010480627999999999999999999999999999CHF00000' +
          '115724500000000002820001020CHF00000002755         ' +
          '                                                  ' +
          '                                                  ');
        FileHdl.Close();
    end;

    local procedure RecordType4CHFWithoutCRLFAndReferenceInvoice() FileName: Text
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileName := CreateFileName();
        FileHdl.Create(FileName);
        FileHdl.CreateOutStream(TmpStream);

        TmpStream.WriteText('011011010480627000000000000000000001030189CHF00000' +
          '07612700002000101100121000120000200000001220010120' +
          '20010121200801231CHF000145                        ' +
          '                                                  ' +
          '991991010480627999999999999999999999999999CHF00000' +
          '076127000000000000120001020CHF00000002755         ' +
          '                                                  ' +
          '                                                  ');

        FileHdl.Close();
    end;

    local procedure RecordType4CHFWithCRLFAndReferenceInvoice() FileName: Text
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileName := CreateFileName();
        FileHdl.Create(FileName);
        FileHdl.CreateOutStream(TmpStream);

        WriteLine(TmpStream, '011011010480627000000000000000000001030189CHF00000' +
          '07612700002000101100121000120000200000001220010120' +
          '20010121200801231CHF000145                        ' +
          '                                                  ');
        WriteLine(TmpStream, '991991010480627999999999999999999999999999CHF00000' +
          '076127000000000000120001020CHF00000002755         ' +
          '                                                  ' +
          '                                                  ');

        FileHdl.Close();
    end;

    local procedure RecordType4OtherCurrencyAndReferenceInvoice(IsWithCRLF: Boolean; CurrencyCode: Text; StartingDate: Date) FileName: Text
    var
        TmpStream: OutStream;
        FileHdl: File;
        FormattedDate: Text;
        Buffer: Text;
        Cr: Char;
        Lf: Char;
    begin
        FileName := CreateFileName();
        FileHdl.Create(FileName);
        FileHdl.CreateOutStream(TmpStream);
        FormattedDate := Format(StartingDate, 0, '<Year4><Month,2><Day,2>');
        Buffer := '211011030000022000000000000000000001030072' +
          CurrencyCode +
          '000000324849000200010110012020123000120000000122001011820010119' +
          FormattedDate +
          '0CHF000205' + PadStr(' ', 74);

        if IsWithCRLF then begin
            Cr := 13;
            Lf := 10;
            Buffer := Buffer + Format(Cr) + Format(Lf);
        end;

        Buffer := Buffer + '981991030000022999999999999999999999999999' +
          CurrencyCode +
          '00000032484900000000000120001020CHF00000000265' +
          PadStr(' ', 109);

        TmpStream.WriteText(Buffer);

        FileHdl.Close();
    end;

    local procedure CorruptESRFileWithChecksumError() FileName: Text
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileName := CreateFileName();
        FileHdl.Create(FileName);
        FileHdl.CreateOutStream(TmpStream);

        TmpStream.WriteText('00201002654090000300000000000001000140700000534750' +
          '00000000007011107011107011100000000000000000000000' +
          '                            0020100265409000030000' +
          '00000000010010471000007134000000000000701110701110' +
          '7011100000000000000000000000                      ' +
          '      00201002654090000300000000000001001091600000' +
          '71340000000000007011107011107011100000000000000000' +
          '000000                            0020100265409000' +
          '03000000000000010013118000002905000000000000701110' +
          '7011107011100000000000000000000000                ' +
          '            00201002654090000300000000000001001985' +
          '40000048905000000000007011107011107011100000000000' +
          '000000000000                            0020100265' +
          '40900003000000000000010020859000003389500000000000' +
          '7011107011107011100000000000000000000000          ' +
          '                  00201002654090000300000000000001' +
          '00222380000006455000000000007011107011107011100000' +
          '000000000000000000                            0020' +
          '10026540900003000000000000010023014000003551000000' +
          '0000007011107011107011100000000000000000000000    ' +
          '                        00201002654090000300000000' +
          '00000100240000000009685000000000007011107011107011' +
          '100000000000000000000000                          ' +
          '  002010026540900003000000000000010024110000000645' +
          '50000000000070111070111070111000000000000000000000' +
          '00                            00201002654090000300' +
          '00000000000100242230000014850000000000007011107011' +
          '107011100000000000000000000000                    ' +
          '        002010026540900003000000000000010032483000' +
          '00532600000000000070111070111070111000000000000000' +
          '00000000                            01201002654090' +
          '00030000010111111326424600000013245000000000006122' +
          '807010307010300000000000000000000145              ' +
          '              002010026540900003000001011209532646' +
          '46400000639250000000000070108070108070108000000000' +
          '00000000000000                            00201002' +
          '65409000030000010117033262665090000700000000000000' +
          '007011107011107011100000000000000000000000        ' +
          '                    002010026540900003000001011715' +
          '73264948900000344700000000000061229070103070103000' +
          '00000000000000000000                            00' +
          '20100265409000030000010122106262618660000027760000' +
          '000000007010807010807010800000000000000000000000  ' +
          '                          002010026540900003000001' +
          '01221062626187400008050650000000000070108070108070' +
          '10800000000000000000000000                        ' +
          '    0020100265409000030000010122106262618820000079' +
          '09500000000000701080701080701080000000000000000000' +
          '0000                            002010026540900003' +
          '00000101221063264453500000186950000000000070108070' +
          '10807010800000000000000000000000                  ' +
          '          0020100265409000030000010123053326501550' +
          '00000748000000000000701100701100701100000000000000' +
          '0000000000                            002010026540' +
          '90000300000101230652625877900000232450000000000070' +
          '10507010507010500000000000000000000000            ' +
          '                0020100265409000030000010134103326' +
          '44936000000835000000000000701110701110701110000000' +
          '0000000000000000                            002010' +
          '02654090000300000101350142626133500000018400000000' +
          '00007011007011107011100000000000000000000000      ' +
          '                      0020100265409000030000010135' +
          '01426261340001426123500000000000701100701110701110' +
          '0000000000000000000000                            ' +
          '00201002654090000300000101350142626135100001436700' +
          '00000000007011007011107011100000000000000000000000' +
          '                            0020100265409000030000' +
          '01013501426261366000004287500000000000701100701110' +
          '7011100000000000000000000000                      ' +
          '      00201002654090000300000101350142626137400443' +
          '95775000000000007011007011107011100000000000000000' +
          '000000                            0020100265409000' +
          '03000001013501426261382000008070000000000000701100' +
          '7011107011100000000000000000000000                ' +
          '            00201002654090000300000101380432621771' +
          '00000017050000000000007011107011107011100000000000' +
          '000000000000                            0020100265' +
          '40900003000001013804326234618000001895500000000000' +
          '7011107011107011100000000000000000000000          ' +
          '                  00201002654090000300000101390253' +
          '26499000000036610000000000007010507010807010800000' +
          '000000000000000000                            0020' +
          '10026540900003000001013902532650167000002867500000' +
          '0000007010507010807010800000000000000000000000    ' +
          '                        00201002654090000300000101' +
          '39025326506870000022060000000000007011007011107011' +
          '100000000000000000000000                          ' +
          '  002010026540900003000001014110332646295000004029' +
          '50000000000070105070108070108000000000000000000000' +
          '00                            00201002654090000300' +
          '00010144002326463500001838510000000000007010507010' +
          '507010500000000000000000000000                    ' +
          '        002010026540900003000001015097732645791000' +
          '00220600000000000070103070104070104000000000000000' +
          '00000000                            00201002654090' +
          '00030000010151541326441800000012275000000000007010' +
          '307010307010300000000000000000000000              ' +
          '              002010026540900003000001015207732646' +
          '09500000275100000000000070111070111070111000000000' +
          '00000000000000                            00201002' +
          '65409000030000010152486326456030000016410000000000' +
          '007010507010507010500000000000000000000000        ' +
          '                    002010026540900003000001015250' +
          '13265001500001182000000000000070109070110070110000' +
          '00000000000000000000                            00' +
          '20100265409000030000010153111262656920000055595000' +
          '000000007010507010807010800000000000000000000000  ' +
          '                          002010026540900003000001' +
          '01531112626571100000691050000000000070105070108070' +
          '10800000000000000000000000                        ' +
          '    0020100265409000030000010153213326431490000015' +
          '33500000000000701050701050701050000000000000000000' +
          '0000                            002010026540900003' +
          '00000101534892626207200000287300000000000070108070' +
          '10907010900000000000000000000000                  ' +
          '          0020100265409000030000010153489262620880' +
          '00002001500000000000701080701090701090000000000000' +
          '0000000000                            002010026540' +
          '90000300000101534893265043800000277050000000000070' +
          '10807010907010900000000000000000000000            ' +
          '                0020100265409000030000010153833262' +
          '54869000001528000000000000612290701030701030000000' +
          '0000000000000000                            002010' +
          '02654090000300000101538332625490400000842100000000' +
          '00007010307010307010300000000000000000000000      ' +
          '                      0020100265409000030000010153' +
          '83326254912000001100000000000000612290701030701030' +
          '0000000000000000000000                            ' +
          '00201002654090000300000101546183265009900000267600' +
          '00000000007010407010407010400000000000000000000000' +
          '                            0020100265409000030000' +
          '01015461832650353000000721000000000000701040701040' +
          '7010400000000000000000000000                      ' +
          '      00201002654090000300000101546183265115300000' +
          '15335000000000007010407010407010400000000000000000' +
          '000000                            0020100265409000' +
          '03000001015605632645966000000861000000000000701090' +
          '7010907010900000000000000000000000                ' +
          '            00201002654090000300000101567313264289' +
          '70000234255000000000007010307010407010400000000000' +
          '000000000000                            0020100265' +
          '40900003000001015673132642902000002033500000000000' +
          '7010307010407010400000000000000000000000          ' +
          '                  00201002654090000300000101567313' +
          '26429180000010760000000000007010307010407010400000' +
          '000000000000000000                            0020' +
          '10026540900003000001015699232641732000002469500000' +
          '0000007010807010907010900000000000000000000000    ' +
          '                        00201002654090000300000101' +
          '57150262566620000709155000000000007010807010807010' +
          '800000000000000000000000                          ' +
          '  012010026540900003000001015747032651581000000368' +
          '00000000000070105070109070109000000000000000000000' +
          '90                            00201002654090000300' +
          '00010158773326478570000059450000000000007010907011' +
          '007011000000000000000000000000                    ' +
          '        002010026540900003000001020103732651967000' +
          '11300400000000000070109070110070110000000000000000' +
          '00000000                            00201002654090' +
          '00030000010201103326460390000022060000000000007010' +
          '507010807010800000000000000000000000              ' +
          '              002010026540900003000001021209126259' +
          '61800000004850000000000070103070103070103000000000' +
          '00000000000000                            00201002' +
          '65409000030000010217094326440020000015765000000000' +
          '007010307010307010300000000000000000000000        ' +
          '                    002010026540900003000001021900' +
          '73264390200001257400000000000070105070105070105000' +
          '00000000000000000000                            00' +
          '20100265409000030000010219007326450950000150005000' +
          '000000007010507010507010500000000000000000000000  ' +
          '                          002010026540900003000001' +
          '02190073264510500002310700000000000070105070105070' +
          '10500000000000000000000000                        ' +
          '    0020100265409000030000010221057262571230000024' +
          '75000000000000701080701080701080000000000000000000' +
          '0000                            002010026540900003' +
          '00000102230022625612700000025800000000000070105070' +
          '10507010500000000000000000000000                  ' +
          '          0020100265409000030000010223002262561350' +
          '00000258000000000000701050701050701050000000000000' +
          '0000000000                            002010026540' +
          '90000300000102230022625614000000025800000000000070' +
          '10507010507010500000000000000000000000            ' +
          '                0020100265409000030000010223002326' +
          '46704000000767000000000000701050701050701050000000' +
          '0000000000000000                            002010' +
          '02654090000300000102230412625875900000033850000000' +
          '00007010407010507010500000000000000000000000      ' +
          '                      0020100265409000030000010223' +
          '04132644678000003658500000000000701040701050701050' +
          '0000000000000000000000                            ' +
          '00201002654090000300000102411252625917200032111510' +
          '00000000007011007011107011100000000000000000000000' +
          '                            0020100265409000030000' +
          '01024112526259188000023164500000000000701100701110' +
          '7011100000000000000000000000                      ' +
          '      00201002654090000300000102411252625919300003' +
          '46040000000000007011007011107011100000000000000000' +
          '000000                            0020100265409000' +
          '03000001024112526259201000006520500000000000701100' +
          '7011107011100000000000000000000000                ' +
          '            00201002654090000300000102411252625923' +
          '20000139535000000000007011007011107011100000000000' +
          '000000000000                            0020100265' +
          '40900003000001024112526259248000001179500000000000' +
          '7011007011107011100000000000000000000000          ' +
          '                  00201002654090000300000102411513' +
          '26467490000016410000000000007010907010907010900000' +
          '000000000000000000                            0020' +
          '10026540900003000001024213232646584000001361000000' +
          '0000007011007011007011000000000000000000000000    ' +
          '                        00201002654090000300000102' +
          '42181262539220000018810000000000007010307010307010' +
          '300000000000000000000000                          ' +
          '  002010026540900003000001024218126253938000000645' +
          '50000000000070103070103070103000000000000000000000' +
          '00                            00201002654090000300' +
          '00010242181262539430000062195000000000007010307010' +
          '307010300000000000000000000000                    ' +
          '        002010026540900003000001024306926257355000' +
          '00484200000000000070104070104070104000000000000000' +
          '00000000                            00201002654090' +
          '00030000010243069262575150001636848000000000007010' +
          '407010407010400000000000000000000000              ' +
          '              002010026540900003000001024306926257' +
          '52000114464840000000000070104070104070104000000000' +
          '00000000000000                            00201002' +
          '65409000030000010243069262575310000271525000000000' +
          '007010407010407010400000000000000000000000        ' +
          '                    002010026540900003000001024306' +
          '92625754600000878650000000000070104070104070104000' +
          '00000000000000000000                            00' +
          '20100265409000030000010243069262575540000180785000' +
          '000000007010407010407010400000000000000000000000  ' +
          '                          002010026540900003000001' +
          '02430692625756200000356350000000000070104070104070' +
          '10400000000000000000000000                        ' +
          '    0020100265409000030000010243069262575780000011' +
          '38000000000000701040701040701040000000000000000000' +
          '0000                            002010026540900003' +
          '00000102430692625758300000147700000000000070104070' +
          '10407010400000000000000000000000                  ' +
          '          0020100265409000030000010243069262575990' +
          '00010576500000000000701040701040701040000000000000' +
          '0000000000                            002010026540' +
          '90000300000106460742626209200000015350000000000070' +
          '11107011107011100000000000000000000000            ' +
          '                0020100265409000030000010646074262' +
          '62100000000398500000000000701110701110701110000000' +
          '0000000000000000                            002010' +
          '02654090000300000106460742626218700000161150000000' +
          '00007011107011107011100000000000000000000000      ' +
          '                      0020100265409000030000010646' +
          '07426262195000001467000000000000701110701110701110' +
          '0000000000000000000000                            ' +
          '00201002654090000300000106460742626220500000009100' +
          '00000000007011107011107011100000000000000000000000' +
          '                            0020100265409000030000' +
          '01064607426262221000001622500000000000701110701110' +
          '7011100000000000000000000000                      ' +
          '      00201002654090000300000106503852626182400000' +
          '52100000000000007010407010407010400000000000000000' +
          '000000                            0020100265409000' +
          '03000001065038526261848000002711500000000000701040' +
          '7010407010400000000000000000000000                ' +
          '            00201002654090000300000106576022625621' +
          '80000015765000000000007011107011107011100000000000' +
          '000000000000                            0020100265' +
          '40900003000001065792332645171000006441000000000000' +
          '7010307010307010300000000000000000000000          ' +
          '                  00201002654090000300000106587003' +
          '26474770000010330000000000007010907010907010900000' +
          '000000000000000000                            9990' +
          '10026540999999999999999999999999999000123801518000' +
          '000000492070111000002260000000000                 ' +
          '                        ');

        FileHdl.Close();
    end;

    [Normal]
    local procedure RecordForDifferenceReferenceNumber(FileName: Text; DocumentNumber: Text)
    var
        TmpStream: OutStream;
        FileHdl: File;
        PaddedString: Text;
        Length: Integer;
    begin
        FileHdl.Create(FileName);
        FileHdl.CreateOutStream(TmpStream);

        Length := StrLen(DocumentNumber);
        if Length < 8 then
            PaddedString := PadStr('', 8 - Length, '0');

        WriteLine(TmpStream,
          '202010001628123456040000000000' +
          PaddedString + DocumentNumber +
          '60000052260000000000006052006052006052000000000000000000000000');

        WriteLine(TmpStream,
          '999010001628999999999999999999999999999000000052260000000000001060520000000000000000000' + PadStr(' ', 13));

        FileHdl.Close();
    end;

    [Normal]
    local procedure RecordForMultipleOpenInvoice(FileName: Text; DocumentNumber: Text)
    var
        TmpStream: OutStream;
        FileHdl: File;
        PaddedString: Text;
        Length: Integer;
    begin
        FileHdl.Create(FileName);
        FileHdl.CreateOutStream(TmpStream);

        Length := StrLen(DocumentNumber);
        if Length < 8 then
            PaddedString := PadStr('', 8 - Length, '0');

        WriteLine(TmpStream,
          '208010001628123456040000000000' +
          PaddedString + DocumentNumber +
          '60000052260000000000006052006052006052000000000000000000000000');

        WriteLine(TmpStream,
          '208010001628123456040020000000' +
          PaddedString + DocumentNumber +
          '00000100000000000000006052006052006052000000000000000000000000');

        WriteLine(TmpStream,
          '9990100016289999999999999999999999999990000001522600000000000042060520000000000000000000' + PadStr(' ', 13));

        FileHdl.Close();
    end;
}

