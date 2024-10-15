codeunit 144001 "LSV CH DD Test"
{
    // // [FEATURE] [LSV]
    // 
    // LSV CH Direct Debit Tests
    // 
    //   1. CreateLSVDirectDebitLines
    //   2. LaunchLSVWriteDirectDebitFile
    //   3. LaunchWriteLSVFile
    //   4. Try to import DD File with rejected lines.
    // 
    // TFS ID = 91091
    // Covers Test cases:
    // ---------------------------------------------------------------------------------------------------
    // Test Function Name                                                                       TFS ID
    // ---------------------------------------------------------------------------------------------------
    // LaunchLSVImportDirectDebitFile                                                            91091

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryLSV: Codeunit "Library - LSV";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        CollectionSuccesfullySuggestedMsg: Label 'Collection has been successfully suggested.';
        RecordNotFoundErr: Label '%1 record was not found.';
        UnexpectedMessageDialogErr: Label 'Unexpected message: %1';
        FileSuffixTxt: Label '-2';
        GenJournalLineNotPostedErr: Label 'Gen. Journal Line not posted.';
        PmtApplnErr: Label 'You cannot post and apply general journal line %1, %2, %3 because the corresponding balance contains VAT.', Comment = '%1 - Template name, %2 - Batch name, %3 - Line no.';

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVJournalLinesCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateLSVDirectDebitLines()
    var
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        LSVJnl: Record "LSV Journal";
        LSVJnlLine: Record "LSV Journal Line";
    begin
        // [FEATURE] [LSV Journal] [Payment Method Code]

        // [GIVEN] Two Sales Documents are posted: one with empty Payment Method Code, second - LSV
        PrepareLSVSalesDocForCollection(Customer, LSVJnl);

        // [WHEN] Create LSV Journal and Journal Lines
        SpecifyLSVCustomerForCollection(Customer."No.");
        CreateLSVJournalLines(LSVJnl);

        // [WHEN] LSV Journal and Lines are based only on Sales document with LSV Payment Method
        FindCustLedgerEntries(CustLedgEntry, Customer."No.");
        CheckCustLedgerEntriesAreOnHold(CustLedgEntry);
        FindLSVJournalLines(LSVJnlLine, LSVJnl."No.");
        ValidateLSVJournalLines(LSVJnlLine, CustLedgEntry);
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVCloseCollectionReqPageHandler,MessageHandler,WriteLSVDirectDebitFileReqPageHandler,WriteFileConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure LaunchLSVWriteDirectDebitFile()
    var
        LSVJnl: Record "LSV Journal";
        LSVBankCode: Code[20];
    begin
        // Setup
        LSVBankCode := PrepareLaunchLSVWriteDirectDebitFile(LSVJnl);

        // Exercise
        WriteLSVDirectDebitFile(LSVJnl);

        // Verify
        ValidateLSVFileIsCreated(LSVBankCode);
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVCloseCollectionReqPageHandler,MessageHandler,WriteLSVFileReqPageHandler,WriteFileConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure LaunchWriteLSVFile()
    var
        LSVJnl: Record "LSV Journal";
        LSVBankCode: Code[20];
    begin
        // Setup
        LSVBankCode := PrepareLaunchLSVWriteDirectDebitFile(LSVJnl);

        // Exercise
        WriteLSVFile(LSVJnl);

        // Verify
        ValidateLSVFileIsCreated(LSVBankCode);
    end;

    [Test]
    [HandlerFunctions('LSVSuggestCollectionReqPageHandler,LSVCloseCollectionReqPageHandler,MessageHandler,WriteLSVDirectDebitFileReqPageHandler,WriteFileConfirmHandlerYes,LSVSetupListModalPageHandler')]
    [Scope('OnPrem')]
    procedure LaunchLSVImportDirectDebitFile()
    var
        Customer: Record Customer;
        LSVJnl: Record "LSV Journal";
        GenJournalLine: Record "Gen. Journal Line";
        LSVBankCode: Code[20];
        PrevPath: Text[250];
    begin
        // Try to import DD File with rejected lines.

        // Pre-Setup
        LSVBankCode := PrepareLSVSalesDocForCollection(Customer, LSVJnl);
        CreatePostLSVSalesDocs(Customer."No.", 3);
        PrevPath := SetupImportFilePath(LSVBankCode, GetPathToDDFile(LSVBankCode, 1));
        SpecifyLSVCustomerForCollection(Customer."No.");
        Commit();

        // Setup
        CreateLSVJournalLines(LSVJnl);
        CloseLSVJournal(LSVJnl);

        // Exercise
        WriteLSVDirectDebitFile(LSVJnl);
        CreateLSVDirectDebitImportFile(LSVJnl);
        LibraryVariableStorage.Enqueue(LSVBankCode); // for LSV Setup List handler
        ImportLSVDirectDebitFile(GenJournalLine);
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GenJournalLine."Line No." := 10000;
        VerifyApplicationWithVATBalancingError(GenJournalLine);
        if true then
            exit; // We reject possibility to apply payment with VAT and Discount on a balance account until proper fix (split transaction)

        // Verify
        Assert.IsTrue(GenJournalLine.IsEmpty, GenJournalLineNotPostedErr);

        // Teardown
        SetupImportFilePath(LSVBankCode, PrevPath);
    end;

    local procedure PrepareLaunchLSVWriteDirectDebitFile(var LSVJnl: Record "LSV Journal") LSVBankCode: Code[20]
    var
        Customer: Record Customer;
    begin
        LSVBankCode := PrepareLSVSalesDocForCollection(Customer, LSVJnl);
        SpecifyLSVCustomerForCollection(Customer."No.");
        CreateLSVJournalLines(LSVJnl);
        CloseLSVJournal(LSVJnl);
    end;

    local procedure PrepareLSVSalesDocForCollection(var Customer: Record Customer; var LSVJnl: Record "LSV Journal") LSVBankCode: Code[20]
    var
        ESRSetup: Record "ESR Setup";
        LSVSetup: Record "LSV Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryLSV.CreateESRSetup(ESRSetup);
        LSVBankCode := LibraryLSV.CreateLSVSetup(LSVSetup, ESRSetup);
        with LSVSetup do begin
            "Bal. Account Type" := "Bal. Account Type"::"G/L Account";
            GLAccount.SetRange("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
            LibraryERM.FindGLAccount(GLAccount);
            "Bal. Account No." := GLAccount."No.";
            Modify;
        end;
        LibraryLSV.CreateLSVJournal(LSVJnl, LSVSetup);
        LibraryLSV.CreateLSVCustomer(Customer, '');
        CreatePostLSVSalesDocs(Customer."No.", 1);
        Customer."Payment Method Code" := LSVSetup."LSV Payment Method Code";
        Customer.Modify();
        LibraryLSV.CreateLSVCustomerBankAccount(Customer);
        CreatePostLSVSalesDocs(Customer."No.", 1);
    end;

    local procedure SetupImportFilePath(LSVBankCode: Code[20]; DDImportFileName: Text[250]) Result: Text[250]
    var
        LSVSetup: Record "LSV Setup";
    begin
        with LSVSetup do begin
            Get(LSVBankCode);
            Result := "DebitDirect Import Filename";
            "DebitDirect Import Filename" := DDImportFileName;
            Modify;
        end;
    end;

    local procedure GetPathToDDFile(LSVBankCode: Code[20]; PathType: Option Export,Import): Text[250]
    var
        LSVSetup: Record "LSV Setup";
    begin
        with LSVSetup do begin
            Get(LSVBankCode);
            case PathType of
                PathType::Export:
                    exit("LSV File Folder" + "LSV Filename");
                PathType::Import:
                    exit("LSV File Folder" + "LSV Filename" + FileSuffixTxt);
            end;
        end;
    end;

    local procedure CreateLSVSalesDoc(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.FindItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
    end;

    local procedure PostLSVSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreatePostLSVSalesDocs(CustomerNo: Code[20]; NoOfDocs: Integer)
    var
        SalesHeader: Record "Sales Header";
        i: Integer;
    begin
        for i := 1 to NoOfDocs do begin
            CreateLSVSalesDoc(SalesHeader, CustomerNo);
            PostLSVSalesDoc(SalesHeader);
        end;
    end;

    local procedure SpecifyLSVCustomerForCollection(CustomerNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(CustomerNo);
    end;

    local procedure CreateLSVJournalLines(var LSVJnl: Record "LSV Journal")
    var
        LSVJnlList: TestPage "LSV Journal List";
    begin
        LSVJnlList.OpenView;
        LSVJnlList.GotoRecord(LSVJnl);
        LSVJnlList.LSVSuggestCollection.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LSVSuggestCollectionReqPageHandler(var LSVSuggestCollection: TestRequestPage "LSV Suggest Collection")
    begin
        LSVSuggestCollection.FromDueDate.SetValue(WorkDate);
        LSVSuggestCollection.ToDueDate.SetValue(WorkDate);
        LSVSuggestCollection.Customer.SetFilter("No.", RetrieveLSVCustomerForCollection);
        LSVSuggestCollection.OK.Invoke;
    end;

    local procedure RetrieveLSVCustomerForCollection() CustomerNo: Code[20]
    var
        CustomerNoAsVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNoAsVar);
        Evaluate(CustomerNo, CustomerNoAsVar);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure LSVJournalLinesCreatedMessageHandler(Message: Text[1024])
    begin
        Assert.AreNotEqual(0, StrPos(Message, CollectionSuccesfullySuggestedMsg), StrSubstNo(UnexpectedMessageDialogErr, Message));
    end;

    local procedure FindCustLedgerEntries(var CustLedgEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20])
    begin
        CustLedgEntry.SetRange("Customer No.", CustomerNo);
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetFilter("Payment Method Code", '<>%1', '');
        CustLedgEntry.FindLast();
    end;

    local procedure CheckCustLedgerEntriesAreOnHold(CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        with CustLedgEntry do
            repeat
                Assert.AreEqual("On Hold", 'LSV', FieldCaption("On Hold"));
                Assert.AreEqual(Open, true, FieldCaption(Open));
            until Next = 0;
    end;

    local procedure FindLSVJournalLines(var LSVJnlLine: Record "LSV Journal Line"; LSVJnlNo: Integer)
    begin
        LSVJnlLine.SetRange("LSV Journal No.", LSVJnlNo);
        LSVJnlLine.FindSet();
    end;

    local procedure ValidateLSVJournalLines(LSVJnlLine: Record "LSV Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry")
    var
        LSVJournal: Record "LSV Journal";
    begin
        with LSVJnlLine do
            repeat
                SetRange("Customer No.", CustLedgEntry."Customer No.");
                SetRange("Currency Code", CustLedgEntry."Currency Code");
                SetRange("Applies-to Doc. No.", CustLedgEntry."Document No.");
                SetRange("Cust. Ledg. Entry No.", CustLedgEntry."Entry No.");
                CustLedgEntry.CalcFields(Amount);
                SetRange("Remaining Amount", CustLedgEntry.Amount);
                Assert.IsFalse(IsEmpty, StrSubstNo(RecordNotFoundErr, TableCaption));
            until CustLedgEntry.Next = 0;

        LSVJournal.Get(LSVJnlLine."LSV Journal No.");
        LSVJournal.CalcFields("No. Of Entries Plus");
        LSVJournal.TestField("No. Of Entries Plus", 1);
    end;

    local procedure CloseLSVJournal(var LSVJnl: Record "LSV Journal")
    var
        LSVJnlList: TestPage "LSV Journal List";
    begin
        LSVJnlList.OpenView;
        LSVJnlList.GotoRecord(LSVJnl);
        LSVJnlList.LSVCloseCollection.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LSVCloseCollectionReqPageHandler(var LSVCloseCollection: TestRequestPage "LSV Close Collection")
    begin
        LSVCloseCollection.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure WriteLSVDirectDebitFile(var LSVJnl: Record "LSV Journal")
    var
        LSVJnlList: TestPage "LSV Journal List";
    begin
        LSVJnlList.OpenView;
        LSVJnlList.GotoRecord(LSVJnl);
        LSVJnlList.WriteDebitDirectFile.Invoke;
    end;

    local procedure CreateLSVDirectDebitImportFile(var LSVJnl: Record "LSV Journal")
    var
        FileMgt: Codeunit "File Management";
        InFile: File;
        OutFile: File;
        InStr: InStream;
        OutStr: OutStream;
        PathToFile: Text;
        Line: Text[1024];
        i: Integer;
    begin
        with InFile do begin
            TextMode(true);
            Open(PathToFile);
            CreateInStream(InStr);
        end;
        with OutFile do begin
            TextMode(true);
            Create(PathToFile + FileSuffixTxt);
            CreateOutStream(OutStr);
        end;
        while not InStr.EOS do begin
            i += 1;
            InStr.ReadText(Line);
            if i > 1 then begin
                OutStr.WriteText(ModifyLineForImport(Line, (i = 3)));
                OutStr.WriteText;
            end;
        end;
        InFile.Close;
        OutFile.Close;
    end;

    local procedure ModifyLineForImport(Line: Text[1024]; SetRejected: Boolean): Text[1024]
    var
        MidText: Text[2];
        RejectionCode: Text[2];
    begin
        if CopyStr(Line, 36, 2) = '97' then
            exit(Line);

        if SetRejected then begin
            MidText := '84';
            RejectionCode := '02';
        end else begin
            MidText := '81';
            RejectionCode := '';
        end;
        Line := CopyStr(Line, 1, 35) + MidText + CopyStr(Line, 36 + StrLen(MidText));
        exit(CopyStr(Line, 1, 542) + RejectionCode + CopyStr(Line, 543 + StrLen(RejectionCode)));
    end;

    local procedure ImportLSVDirectDebitFile(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        LSVMgt: Codeunit LSVMgt;
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::"Cash Receipts");
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        with GenJournalLine do begin
            SetRange("Journal Template Name", GenJournalTemplate.Name);
            SetRange("Journal Batch Name", GenJournalBatch.Name);
            "Journal Template Name" := GenJournalTemplate.Name;
            "Journal Batch Name" := GenJournalBatch.Name;
        end;
        LSVMgt.ImportDebitDirectFile(GenJournalLine);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WriteLSVDirectDebitFileReqPageHandler(var LSVWriteDebitDirectFile: TestRequestPage "LSV Write DebitDirect File")
    begin
        LSVWriteDebitDirectFile.OK.Invoke;
    end;

    local procedure WriteLSVFile(var LSVJnl: Record "LSV Journal")
    var
        LSVJnlList: TestPage "LSV Journal List";
    begin
        LSVJnlList.OpenView;
        LSVJnlList.GotoRecord(LSVJnl);
        LSVJnlList.WriteLSVFile.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WriteLSVFileReqPageHandler(var WriteLSVFile: TestRequestPage "Write LSV File")
    begin
        WriteLSVFile.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure LSVSetupListModalPageHandler(var LSVSetupListModalPage: TestPage "LSV Setup List")
    var
        BankCodeVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankCodeVar);
        LSVSetupListModalPage.GotoKey(BankCodeVar);
        LSVSetupListModalPage.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure WriteFileConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure ValidateLSVFileIsCreated(LSVBankCode: Code[20])
    var
        LSVJnl: Record "LSV Journal";
    begin
        with LSVJnl do begin
            SetRange("LSV Bank Code", LSVBankCode);
            FindFirst();
            Assert.AreEqual("Collection Completed On", Today, FieldCaption("Collection Completed On"));
            Assert.AreEqual("Collection Completed By", UserId, FieldCaption("Collection Completed By"));
            Assert.AreEqual("File Written On", Today, FieldCaption("File Written On"));
            Assert.AreEqual("LSV Status", "LSV Status"::"File Created", FieldCaption("LSV Status"));
        end;
    end;

    local procedure VerifyApplicationWithVATBalancingError(GenJournalLine: Record "Gen. Journal Line")
    begin
        with GenJournalLine do
            Assert.ExpectedError(
              StrSubstNo(
                PmtApplnErr, "Journal Template Name", "Journal Batch Name", "Line No."));
    end;
}

