codeunit 145006 "Reports and Documents"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        RowNotFoundErr: Label 'There is no dataset row corresponding to Element Name %1 with value %2.', Comment = '%1=Field Caption,%2=Field Value;';

    local procedure Initialize()
    begin
        LibraryRandom.SetSeed(1);  // Use Random Number Generator to generate the seed for RANDOM function.
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        UpdateGenJournalTemplate;
        UpdateItemJournalTemplate;

        isInitialized := true;
        Commit();
    end;

    [Test]
    [HandlerFunctions('RequestPageCustBalReconHandler')]
    [Scope('OnPrem')]
    procedure PrintingCustomerBalReconciliation()
    var
        GenJnlLn: Record "Gen. Journal Line";
        CustomerNo: Code[20];
    begin
        // 1. Setup
        Initialize;

        CustomerNo := LibrarySales.CreateCustomerNo;
        CreateAndPostGenJnlLineWithCustomer(GenJnlLn, CustomerNo);

        // 2. Exercise
        LibraryVariableStorage.Enqueue(CalcDate('<+1M>', GenJnlLn."Posting Date")); // return date
        LibraryVariableStorage.Enqueue(GenJnlLn."Posting Date"); // reconciliation date
        LibraryVariableStorage.Enqueue(true); // print detail
        LibraryVariableStorage.Enqueue(CustomerNo);
        PrintCustomerBalReconciliation;

        // 3. Verify
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('CVLedgEntry__Document_No__', GenJnlLn."Document No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'CVLedgEntry__Document_No__', GenJnlLn."Document No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('CVLedgEntry_Amount', GenJnlLn.Amount);
    end;

    [Test]
    [HandlerFunctions('RequestPageVendBalReconHandler')]
    [Scope('OnPrem')]
    procedure PrintingVendorBalReconciliation()
    var
        GenJnlLn: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // 1. Setup
        Initialize;

        VendorNo := LibraryPurchase.CreateVendorNo;
        CreateAndPostGenJnlLineWithVendor(GenJnlLn, VendorNo);

        // 2. Exercise
        LibraryVariableStorage.Enqueue(CalcDate('<+1M>', GenJnlLn."Posting Date")); // return date
        LibraryVariableStorage.Enqueue(GenJnlLn."Posting Date"); // reconciliation date
        LibraryVariableStorage.Enqueue(true); // print detail
        LibraryVariableStorage.Enqueue(VendorNo);
        PrintVendorBalReconciliation;

        // 3. Verify
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('CVLedgEntry__Document_No__', GenJnlLn."Document No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'CVLedgEntry__Document_No__', GenJnlLn."Document No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('CVLedgEntry_Amount', GenJnlLn.Amount);
    end;

    [Test]
    [HandlerFunctions('RequestPageGeneralJournalHandler')]
    [Scope('OnPrem')]
    procedure PrintingGeneralJournal()
    var
        GenJnlLn: Record "Gen. Journal Line";
        GLAccountNo: Code[20];
    begin
        // 1. Setup
        Initialize;

        GLAccountNo := LibraryERM.CreateGLAccountNo;
        CreateAndPostGenJnlLineWithGLAccount(GenJnlLn, GLAccountNo);

        // 2. Exercise
        LibraryVariableStorage.Enqueue(GenJnlLn."Posting Date"); // from date
        LibraryVariableStorage.Enqueue(GenJnlLn."Posting Date"); // to date
        PrintGeneralJournal;

        // 3. Verify
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('greTGLEntry__Document_No__', GenJnlLn."Document No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'greTGLEntry__Document_No__', GenJnlLn."Document No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('greTGLEntry__Debit_Amount_', GenJnlLn.Amount);
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('greTGLEntry__Credit_Amount_', GenJnlLn.Amount);
    end;

    [Test]
    [HandlerFunctions('RequestPageGeneralLedgerHandler')]
    [Scope('OnPrem')]
    procedure PrintingGeneralLedgerLevel1()
    begin
        PrintingGeneralLedgerLevel(900000, 999999, 1, false);
    end;

    [Test]
    [HandlerFunctions('RequestPageGeneralLedgerHandler')]
    [Scope('OnPrem')]
    procedure PrintingGeneralLedgerLevel2()
    begin
        PrintingGeneralLedgerLevel(990000, 999999, 2, true);
    end;

    local procedure PrintingGeneralLedgerLevel(MinGLAccountNo: Integer; MaxGLAccountNo: Integer; Level: Integer; PrintEntries: Boolean)
    var
        GenJnlLn1: Record "Gen. Journal Line";
        GenJnlLn2: Record "Gen. Journal Line";
        GLAccount1: Record "G/L Account";
        GLAccount2: Record "G/L Account";
    begin
        // 1. Setup
        Initialize;

        CreateGLAccount(GLAccount1, GetNextGLAccountNo(MinGLAccountNo, MaxGLAccountNo));
        CreateAndPostGenJnlLineWithGLAccount(GenJnlLn1, GLAccount1."No.");

        CreateGLAccount(GLAccount2, GetNextGLAccountNo(MinGLAccountNo, MaxGLAccountNo));
        CreateAndPostGenJnlLineWithGLAccount(GenJnlLn2, GLAccount2."No.");

        // 2. Exercise
        LibraryVariableStorage.Enqueue(Level); // level
        LibraryVariableStorage.Enqueue(PrintEntries); // print entries
        LibraryVariableStorage.Enqueue(GenJnlLn1."Posting Date");
        PrintGeneralLedger;

        // 3. Verify
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('gcoAccountFilter', CopyStr(GLAccount1."No.", 1, Level));
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'gcoAccountFilter', CopyStr(GLAccount1."No.", 1, Level)));
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('gdeEndDebit___gdeEndCredit', GenJnlLn1.Amount + GenJnlLn2.Amount);
        LibraryReportDataset.AssertElementTagWithValueExists('gboEntries', LowerCase(Format(PrintEntries, 0, 9)));
    end;

    [HandlerFunctions('RequestPageTurnoverReportByGlobDimHandler')]
    [Scope('OnPrem')]
    procedure PrintingTurnoverReportByGlobDim1()
    begin
        PrintingTurnoverReportByGlobDim(1);
    end;

    [HandlerFunctions('RequestPageTurnoverReportByGlobDimHandler')]
    [Scope('OnPrem')]
    procedure PrintingTurnoverReportByGlobDim2()
    begin
        PrintingTurnoverReportByGlobDim(2);
    end;

    local procedure PrintingTurnoverReportByGlobDim(DimensionNo: Integer)
    var
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        GenJnlLn: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        // 1. Setup
        Initialize;

        LibraryERM.CreateGLAccount(GLAccount);
        LibraryDimension.FindDimensionValue(DimensionValue, GetDimensionCode(DimensionNo));
        LibraryDimension.CreateDefaultDimensionGLAcc(
          DefaultDimension, GLAccount."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        CreateAndPostGenJnlLineWithGLAccount(GenJnlLn, GLAccount."No.");

        // 2. Exercise
        LibraryVariableStorage.Enqueue(DimensionNo);
        LibraryVariableStorage.Enqueue(GenJnlLn."Posting Date");
        PrintTurnoverReportByGlobDim;

        // 3. Verify
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('AccountNo', GLAccount."No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'AccountNo', GLAccount."No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('DimCodeText', DimensionValue.Code);
    end;

    [Test]
    [HandlerFunctions('RequestPageInventoryAccountToDateHandler')]
    [Scope('OnPrem')]
    procedure PrintingInventoryAccountToDate()
    var
        GenJnlLn: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        // 1. Setup
        Initialize;

        LibraryERM.CreateGLAccount(GLAccount);
        CreateAndPostGenJnlLineWithGLAccount(GenJnlLn, GLAccount."No.");

        // 2. Exercise
        LibraryVariableStorage.Enqueue(GLAccount."No.");
        LibraryVariableStorage.Enqueue(GenJnlLn."Posting Date");
        PrintInventoryAccountToDate;

        // 3. Verify
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_GLAcc', GLAccount."No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'No_GLAcc', GLAccount."No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('Amount_GLE', GenJnlLn.Amount);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,ReportGeneralLedgerDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FinancialDocuments()
    var
        GenJnlLn: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        // 1. Setup
        Initialize;

        LibraryERM.CreateGLAccount(GLAccount);

        // 2. Exercise
        CreateAndPostPrintGenJnlLine(GenJnlLn, GenJnlLn."Account Type"::"G/L Account", GLAccount."No.");

        // 3. Verify
        // execute ReportGeneralLedgerDocumentHandler
    end;

    [Test]
    [HandlerFunctions('ReportPostedInventoryDocumentHandler,YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseDocuments()
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        // 1. Setup
        Initialize;

        // 2. Exercise
        CreateAndPostPrintItemJnlLine(ItemJnlLine);

        // 3. Verify
        // execute ReportPostedInventoryDocumentHandler
    end;

    local procedure CreateAndPostGenJnlLine(var GenJnlLn: Record "Gen. Journal Line"; AccountType: Option; AccountNo: Code[20])
    begin
        CreateGenJnlLine(GenJnlLn, AccountType, AccountNo);
        LibraryERM.PostGeneralJnlLine(GenJnlLn);
    end;

    local procedure CreateAndPostGenJnlLineWithCustomer(var GenJnlLn: Record "Gen. Journal Line"; CustomerNo: Code[20])
    begin
        CreateAndPostGenJnlLine(GenJnlLn, GenJnlLn."Account Type"::Customer, CustomerNo);
    end;

    local procedure CreateAndPostGenJnlLineWithVendor(var GenJnlLn: Record "Gen. Journal Line"; VendorNo: Code[20])
    begin
        CreateAndPostGenJnlLine(GenJnlLn, GenJnlLn."Account Type"::Vendor, VendorNo);
    end;

    local procedure CreateAndPostGenJnlLineWithGLAccount(var GenJnlLn: Record "Gen. Journal Line"; GLAccountNo: Code[20])
    begin
        CreateAndPostGenJnlLine(GenJnlLn, GenJnlLn."Account Type"::"G/L Account", GLAccountNo);
    end;

    local procedure CreateAndPostPrintGenJnlLine(var GenJnlLn: Record "Gen. Journal Line"; AccountType: Option; AccountNo: Code[20])
    begin
        CreateGenJnlLine(GenJnlLn, AccountType, AccountNo);
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post+Print", GenJnlLn);
    end;

    local procedure CreateGenJnlLine(var GenJnlLn: Record "Gen. Journal Line"; AccountType: Option; AccountNo: Code[20])
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        LibraryERM.ClearGenJournalLines(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLn, GenJnlBatch."Journal Template Name", GenJnlBatch.Name, 0,
          AccountType, AccountNo, LibraryRandom.RandDec(1000, 2));
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account"; GLAccountNo: Code[20])
    begin
        GLAccount.Init();
        GLAccount.Validate("No.", GLAccountNo);
        GLAccount.Validate(Name, GLAccountNo);
        GLAccount.Insert(true);
    end;

    local procedure CreateItemJnlLine(var ItemJnlLine: Record "Item Journal Line")
    var
        Item: Record Item;
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.SelectItemJournalTemplateName(ItemJnlTemplate, ItemJnlTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(
          ItemJnlBatch, ItemJnlBatch."Template Type"::Item, ItemJnlTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJnlTemplate, ItemJnlBatch);
        LibraryInventory.CreateItemJournalLine(ItemJnlLine, ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name,
          ItemJnlLine."Entry Type"::"Negative Adjmt.", Item."No.", 1);
    end;

    local procedure CreateAndPostPrintItemJnlLine(var ItemJnlLine: Record "Item Journal Line")
    begin
        CreateItemJnlLine(ItemJnlLine);
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post+Print", ItemJnlLine);
    end;

    local procedure GetBalReconValues(var ReturnDate: Date; var ReconcileDate: Date; var PrintDetails: Boolean; var CustOrVendNo: Code[20])
    begin
        ReturnDate := LibraryVariableStorage.DequeueDate;
        ReconcileDate := LibraryVariableStorage.DequeueDate;
        PrintDetails := LibraryVariableStorage.DequeueBoolean;
        CustOrVendNo := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(CustOrVendNo));
    end;

    local procedure GetDimensionCode(DimensionNo: Integer): Code[20]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        case DimensionNo of
            1:
                exit(GLSetup."Shortcut Dimension 1 Code");
            2:
                exit(GLSetup."Shortcut Dimension 2 Code");
        end;
    end;

    local procedure GetNextGLAccountNo("Min": Integer; "Max": Integer): Code[20]
    begin
        exit(Format(LibraryRandom.RandIntInRange(Min, Max)));
    end;

    local procedure PrintCustomerBalReconciliation()
    begin
        REPORT.Run(REPORT::"Customer - Bal. Reconciliation", true, false);
    end;

    local procedure PrintGeneralJournal()
    begin
        REPORT.Run(REPORT::"General Journal", true, false);
    end;

    local procedure PrintGeneralLedger()
    begin
        REPORT.Run(REPORT::"General Ledger", true, false);
    end;

    local procedure PrintInventoryAccountToDate()
    begin
        REPORT.Run(REPORT::"Inventory Account to the date", true, false);
    end;

    local procedure PrintTurnoverReportByGlobDim()
    begin
        REPORT.Run(REPORT::"Turnover report by Glob. Dim.", true, false);
    end;

    local procedure PrintVendorBalReconciliation()
    begin
        REPORT.Run(REPORT::"Vendor - Bal. Reconciliation", true, false);
    end;

    local procedure UpdateGenJournalTemplate()
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        GenJnlTemplate.Reset();
        GenJnlTemplate.Get(LibraryERM.SelectGenJnlTemplate);
        GenJnlTemplate."Posting Report ID" := REPORT::"General Ledger Document";
        GenJnlTemplate.Modify();
    end;

    local procedure UpdateItemJournalTemplate()
    var
        ItemJnlTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJnlTemplate, ItemJnlTemplate.Type::Item);
        ItemJnlTemplate.Validate("Posting Report ID", REPORT::"Posted Inventory Document");
        ItemJnlTemplate.Modify();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure ReportGeneralLedgerDocumentHandler(var GeneralLedgerDocument: Report "General Ledger Document")
    begin
        GeneralLedgerDocument.SaveAsXml(LibraryReportDataset.GetFileName);
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure ReportPostedInventoryDocumentHandler(var PostedInventoryDocument: Report "Posted Inventory Document")
    begin
        PostedInventoryDocument.SaveAsXml(LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageCustBalReconHandler(var CustomerBalReconciliation: TestRequestPage "Customer - Bal. Reconciliation")
    var
        ReturnDate: Date;
        ReconcileDate: Date;
        PrintDetails: Boolean;
        CustOrVendNo: Code[20];
    begin
        GetBalReconValues(ReturnDate, ReconcileDate, PrintDetails, CustOrVendNo);
        CustomerBalReconciliation.ReturnDate.SetValue(ReturnDate);
        CustomerBalReconciliation.ReconcileDate.SetValue(ReconcileDate);
        CustomerBalReconciliation.PrintDetails.SetValue(PrintDetails);
        CustomerBalReconciliation.Customer.SetFilter("No.", CustOrVendNo);
        CustomerBalReconciliation.SaveAsXml(
          LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageVendBalReconHandler(var VendorBalReconciliation: TestRequestPage "Vendor - Bal. Reconciliation")
    var
        ReturnDate: Date;
        ReconcileDate: Date;
        PrintDetails: Boolean;
        CustOrVendNo: Code[20];
    begin
        GetBalReconValues(ReturnDate, ReconcileDate, PrintDetails, CustOrVendNo);
        VendorBalReconciliation.ReturnDate.SetValue(ReturnDate);
        VendorBalReconciliation.ReconcileDate.SetValue(ReconcileDate);
        VendorBalReconciliation.PrintDetails.SetValue(PrintDetails);
        VendorBalReconciliation.Vendor.SetFilter("No.", CustOrVendNo);
        VendorBalReconciliation.SaveAsXml(
          LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageGeneralJournalHandler(var GeneralJournal: TestRequestPage "General Journal")
    var
        FieldValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(FieldValue);
        GeneralJournal.FromDate.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        GeneralJournal.ToDate.SetValue(FieldValue);
        GeneralJournal.SaveAsXml(
          LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageGeneralLedgerHandler(var GeneralLedger: TestRequestPage "General Ledger")
    var
        FieldValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(FieldValue);
        GeneralLedger.Level.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        GeneralLedger.Entries.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        GeneralLedger."G/L Account".SetFilter("Date Filter", Format(FieldValue));
        GeneralLedger.SaveAsXml(
          LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageTurnoverReportByGlobDimHandler(var TurnoverreportbyGlobDim: TestRequestPage "Turnover report by Glob. Dim.")
    var
        FieldValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(FieldValue);
        TurnoverreportbyGlobDim.Detail.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        TurnoverreportbyGlobDim."G/L Account".SetFilter("Date Filter", Format(FieldValue));
        TurnoverreportbyGlobDim.SaveAsXml(
          LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageInventoryAccountToDateHandler(var InventoryAccounttothedate: TestRequestPage "Inventory Account to the date")
    var
        FieldValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(FieldValue);
        InventoryAccounttothedate."G/L Account".SetFilter("No.", FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        InventoryAccounttothedate."G/L Account".SetFilter("Date Filter", Format(FieldValue));
        InventoryAccounttothedate.SaveAsXml(
          LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
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

