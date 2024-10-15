codeunit 142077 "UT TAB Bank Rec"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Reconciliation]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        NotExistValueErr: Label 'Value must not exist';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetupNewLineBankCommentLine()
    var
        BankCommentLine: Record "Bank Comment Line";
        BankAccountNo: Code[20];
    begin
        // Purpose of the test is to validate SetupNew Line fucntion for Table 10122 Bank Comment Line.

        // Setup.
        Initialize;
        BankAccountNo := CreateBankCommentLine;

        // Exercise.
        BankCommentLine.SetUpNewLine;

        // Verify:
        BankCommentLine.SetRange("Bank Account No.", BankAccountNo);
        BankCommentLine.FindFirst;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CurrencyCodeExistValidateBankRecSubLine()
    begin
        // Purpose of the test is to validate Currency Code not blank for Table 10126 Bank Rec. Sub-line.
        CurrencyCodeValidateBankRecSubLine(CreateCurrencyAndExchangeRate);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CurrencyCodeBlankBankRecSubLine()
    begin
        // Purpose of the test is to validate Currency Code blank for Table 10126 Bank Rec. Sub-line.
        CurrencyCodeValidateBankRecSubLine('');
    end;

    local procedure CurrencyCodeValidateBankRecSubLine(CurrencyCode: Code[10])
    var
        BankRecSubLine: Record "Bank Rec. Sub-line";
    begin
        // Setup.
        Initialize;
        CreateBankRecHeaderAndBankRecSubLine(BankRecSubLine, CurrencyCode);

        // Exercise.
        BankRecSubLine.Validate("Currency Code", CurrencyCode);

        // Verify.
        BankRecSubLine.TestField("Currency Code", CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('BankReconciliationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintRecordPostedBankRecHeader()
    var
        PostedBankRecHeader: Record "Posted Bank Rec. Header";
    begin
        // Purpose of the test is to run PrintRecords function of Table 10123 Posted Bank Rec. Header.

        // Setup.
        Initialize;
        CreatePostedBankRecHeader(PostedBankRecHeader);

        // Pre-Exercise
        SetBankReconciliationReports;

        // Exercise.
        PostedBankRecHeader.PrintRecords(false);  // Using False to hide the Show RequestForm.

        // Verify: Purpose for exercise is to execute the PrintRecords Blocks Sucessfully.
    end;

    [Test]
    [HandlerFunctions('EditDimensionSetEntriesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowDocDimPostedBankRecHeader()
    var
        PostedBankRecHeader: Record "Posted Bank Rec. Header";
    begin
        // Purpose of the test is to run ShowDocDim function of Table 10123 Posted Bank Rec. Header.

        // Setup.
        Initialize;
        CreatePostedBankRecHeader(PostedBankRecHeader);

        // Exercise.
        PostedBankRecHeader.ShowDocDim;

        // Verify: Purpose for exercise is to execute the ShowDim Blocks Sucessfully.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnNavigatePostedBankRecHeader()
    var
        PostedBankRecHeader: Record "Posted Bank Rec. Header";
    begin
        // Purpose of the test is to run Navigate function of Table 10123 Posted Bank Rec. Header.

        // Setup.
        Initialize;
        CreatePostedBankRecHeader(PostedBankRecHeader);

        // Exercise.
        OpenPagePostedBankRecWorksheetToNavigate(PostedBankRecHeader."Bank Account No.");

        // Verify: Purpose for exercise is to execute the Navigate Blocks Sucessfully.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeletePostedBankRecHeader()
    var
        PostedBankRecHeader: Record "Posted Bank Rec. Header";
    begin
        // Purpose of the test is to On Delete function of Table 10123 Posted Bank Rec. Header.

        // Setup.
        Initialize;
        CreatePostedBankRecHeader(PostedBankRecHeader);

        // Exercise.
        asserterror PostedBankRecHeader.Delete(true);  // Use AssertError to handle error after deletion.

        // Verify.
        Assert.IsFalse(PostedBankRecHeader.Get(PostedBankRecHeader."Bank Account No."), NotExistValueErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CreateDimPostedBankRecLine()
    var
        PostedBankRecLine: Record "Posted Bank Rec. Line";
    begin
        // Purpose of the test is to run CreateDimPosted function of Table 10124 Posted Bank Rec. Line.

        // Setup.
        Initialize;
        CreatePostedBankRecLine(PostedBankRecLine);

        // Exercise.
        PostedBankRecLine.CreateDim(
          LibraryRandom.RandInt(10), LibraryUTUtility.GetNewCode10,
          LibraryRandom.RandInt(10), LibraryUTUtility.GetNewCode10,
          LibraryRandom.RandInt(10), LibraryUTUtility.GetNewCode10,
          LibraryRandom.RandInt(10), LibraryUTUtility.GetNewCode10,
          LibraryRandom.RandInt(10), LibraryUTUtility.GetNewCode10);

        // Verify: Purpose for exercise is to execute the CreateDimPosted Blocks Sucessfully.
    end;

    [Test]
    [HandlerFunctions('EditDimensionSetEntriesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowDimensionPostedBankRecLine()
    var
        PostedBankRecLine: Record "Posted Bank Rec. Line";
    begin
        // Purpose of the test is to run ShowDimensionPosted function of Table 10124 Posted Bank Rec. Line.

        // Setup.
        Initialize;
        CreatePostedBankRecLine(PostedBankRecLine);

        // Exercise.
        PostedBankRecLine.ShowDimensions;

        // Verify: Purpose for exercise is to execute the ShowDimension Blocks Sucessfully.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ValidateShortcutDimCodePostedBankRecLine()
    var
        PostedBankRecLine: Record "Posted Bank Rec. Line";
    begin
        // Purpose of the test is to ValidateShortcutDimCode function of Table 10124 Posted Bank Rec. Line.

        // Setup.
        Initialize;
        CreatePostedBankRecLine(PostedBankRecLine);

        // Exercise.
        PostedBankRecLine.ValidateShortcutDimCode(LibraryRandom.RandInt(10), PostedBankRecLine."Shortcut Dimension 1 Code");

        // Verify: Purpose for exercise is to execute the ValidateShortcutDimCode Blocks Sucessfully.
    end;

    [Test]
    [HandlerFunctions('DimensionValueListPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure LookUpShortcutDimCodePostedBankRecLine()
    var
        PostedBankRecLine: Record "Posted Bank Rec. Line";
    begin
        // Purpose of the test is to ValidateLookUpShortcutDimCode function of Table 10124 Posted Bank Rec. Line.

        // Setup.
        Initialize;
        CreatePostedBankRecLine(PostedBankRecLine);

        // Exercise.
        PostedBankRecLine.LookupShortcutDimCode(LibraryRandom.RandInt(10), PostedBankRecLine."Shortcut Dimension 1 Code");

        // Verify: Purpose for exercise is to execute the ValidateLookupShortcutDimCode Blocks Sucessfully.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeletePostedBankRecLine()
    var
        PostedBankRecLine: Record "Posted Bank Rec. Line";
    begin
        // Purpose of the test is to On Delete function of Table 10124 Posted Bank Rec. Line.

        // Setup.
        Initialize;
        CreatePostedBankCommentLine(PostedBankRecLine);

        // Exercise.
        PostedBankRecLine.Delete(true);

        // Verify.
        Assert.IsFalse(PostedBankRecLine.Get(PostedBankRecLine."Bank Account No."), NotExistValueErr);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
    end;

    local procedure CreateBankCommentLine(): Code[20]
    var
        BankCommentLine: Record "Bank Comment Line";
    begin
        BankCommentLine."Table Name" := BankCommentLine."Table Name"::"Bank Rec.";
        BankCommentLine."Bank Account No." := LibraryUTUtility.GetNewCode;
        BankCommentLine."No." := LibraryUTUtility.GetNewCode;
        BankCommentLine."Line No." := LibraryRandom.RandInt(100);
        BankCommentLine.Insert();
        exit(BankCommentLine."Bank Account No.");
    end;

    local procedure CreateBankRecHeaderAndBankRecSubLine(var BankRecSubline: Record "Bank Rec. Sub-line"; CurrencyCode: Code[10])
    var
        BankRecHeader: Record "Bank Rec. Header";
    begin
        BankRecHeader."Bank Account No." := LibraryUTUtility.GetNewCode;
        BankRecHeader."Statement No." := LibraryUTUtility.GetNewCode;
        BankRecHeader."Statement Date" := WorkDate;
        BankRecHeader."Currency Code" := CurrencyCode;
        BankRecHeader.Insert();
        BankRecSubline."Bank Account No." := BankRecHeader."Bank Account No.";
        BankRecSubline."Statement No." := BankRecHeader."Statement No.";
        BankRecSubline."Bank Rec. Line No." := LibraryRandom.RandInt(100);
        BankRecSubline."Line No." := BankRecSubline."Bank Rec. Line No.";
        BankRecSubline.Insert();
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        Currency.Code := LibraryUTUtility.GetNewCode10;
        Currency.Insert();
        CurrencyExchangeRate."Currency Code" := Currency.Code;
        CurrencyExchangeRate."Starting Date" := WorkDate;
        CurrencyExchangeRate."Exchange Rate Amount" := LibraryRandom.RandDec(10, 2);
        CurrencyExchangeRate."Relational Exch. Rate Amount" := CurrencyExchangeRate."Exchange Rate Amount";
        CurrencyExchangeRate.Insert();
        exit(CurrencyExchangeRate."Currency Code");
    end;

    local procedure CreateDimension(): Code[20]
    var
        Dimension: Record Dimension;
    begin
        Dimension.Code := LibraryUTUtility.GetNewCode;
        Dimension.Insert();
        exit(Dimension.Code);
    end;

    local procedure CreateDimensionValue(): Integer
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue."Dimension Code" := CreateDimension;
        DimensionValue."Dimension Value ID" := LibraryRandom.RandInt(100);
        DimensionValue.Insert();
        exit(DimensionValue."Dimension Value ID");
    end;

    local procedure CreatePostedBankRecHeader(var PostedBankRecHeader: Record "Posted Bank Rec. Header")
    begin
        PostedBankRecHeader."Bank Account No." := LibraryUTUtility.GetNewCode;
        PostedBankRecHeader."Statement No." := LibraryUTUtility.GetNewCode;
        PostedBankRecHeader."Dimension Set ID" := CreateDimensionValue;
        PostedBankRecHeader.Insert();
    end;

    local procedure CreatePostedBankRecLine(var PostedBankRecLine: Record "Posted Bank Rec. Line")
    var
        PostedBankRecHeader: Record "Posted Bank Rec. Header";
    begin
        CreatePostedBankRecHeader(PostedBankRecHeader);
        PostedBankRecLine."Bank Account No." := PostedBankRecHeader."Bank Account No.";
        PostedBankRecLine."Statement No." := PostedBankRecHeader."Statement No.";
        PostedBankRecLine."Record Type" := PostedBankRecLine."Record Type"::Adjustment;
        PostedBankRecLine."Account Type" := PostedBankRecLine."Account Type"::"Bank Account";
        PostedBankRecLine."Account No." := PostedBankRecHeader."Bank Account No.";
        PostedBankRecLine.Amount := LibraryRandom.RandDec(10, 2);
        PostedBankRecLine."Dimension Set ID" := PostedBankRecHeader."Dimension Set ID";
        PostedBankRecLine.Insert();
    end;

    local procedure CreatePostedBankCommentLine(var PostedBankRecLine: Record "Posted Bank Rec. Line")
    var
        BankCommentLine: Record "Bank Comment Line";
    begin
        CreatePostedBankRecLine(PostedBankRecLine);
        BankCommentLine."Table Name" := BankCommentLine."Table Name"::"Posted Bank Rec.";
        BankCommentLine."Bank Account No." := PostedBankRecLine."Bank Account No.";
        BankCommentLine."No." := PostedBankRecLine."Statement No.";
        BankCommentLine."Line No." := PostedBankRecLine."Line No.";
        BankCommentLine.Insert();
    end;

    local procedure OpenPagePostedBankRecWorksheetToNavigate(BankAccountNo: Code[20])
    var
        PostedBankRecWorksheet: TestPage "Posted Bank Rec. Worksheet";
        Navigate: TestPage Navigate;
    begin
        Navigate.Trap;
        PostedBankRecWorksheet.OpenEdit;
        PostedBankRecWorksheet.FILTER.SetFilter("Bank Account No.", BankAccountNo);
        PostedBankRecWorksheet.Navigate.Invoke;
        PostedBankRecWorksheet.Close;
        Navigate.Close;
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure BankReconciliationHandler(var BankReconciliation: Report "Bank Reconciliation")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionValueListPageHandler(var DimensionValueList: TestPage "Dimension Value List")
    begin
        DimensionValueList.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EditDimensionSetEntriesHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    begin
        EditDimensionSetEntries.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;

    local procedure SetBankReconciliationReports()
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"B.Stmt", ReportSelections.Usage::"B.Recon.Test");
        ReportSelections.DeleteAll();

        AddReconciliationReport(ReportSelections.Usage::"B.Stmt", 1, REPORT::"Bank Reconciliation");
        AddReconciliationReport(ReportSelections.Usage::"B.Recon.Test", 1, REPORT::"Bank Rec. Test Report");
    end;

    local procedure AddReconciliationReport(Usage: Option; Sequence: Integer; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Usage := Usage;
        ReportSelections.Sequence := Format(Sequence);
        ReportSelections."Report ID" := ReportID;
        ReportSelections.Insert();
    end;
}

