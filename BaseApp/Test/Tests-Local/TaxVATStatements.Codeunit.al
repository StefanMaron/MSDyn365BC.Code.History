codeunit 144201 "Tax VAT Statements"
{
    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryTax: Codeunit "Library - Tax";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        RowNotFoundErr: Label 'There is no dataset row corresponding to Element Name %1 with value %2.', Comment = '%1=Field Caption,%2=Field Value;';

    local procedure Initialize()
    begin
        LibraryRandom.SetSeed(1);  // Use Random Number Generator to generate the seed for RANDOM function.
        LibraryVariableStorage.Clear;

        LibraryTax.SetUseVATDate(true);

        if isInitialized then
            exit;

        LibraryTax.CreateStatReportingSetup;
        LibraryTax.SetVATStatementInformation;
        LibraryTax.SetCompanyType(2); // Corporate

        isInitialized := true;
    end;

    [Test]
    [HandlerFunctions('ReportCalcAndPostVATSettlementHandler,RequestPageVATStatementHandler,YesConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintingVATStatementDPHDP3()
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        PrintingVATStatement();
    end;

    [Scope('OnPrem')]
    procedure PrintingVATStatement()
    var
        VATEntry: Record "VAT Entry";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementName: Record "VAT Statement Name";
        VATStatementTemplate: Record "VAT Statement Template";
        StartingDate: Date;
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
        RowNo: Code[10];
        TotalAmount: Decimal;
        Sign: Integer;
    begin
        // 1. Setup
        Initialize;
        RevertToVATStatementLineDeprEnumValues(VATStatementLine);

        FindVATStatementTemplate(VATStatementTemplate);

        StartingDate := LibraryTax.GetVATPeriodStartingDate;
        DocumentNo := GetSettlementNo(StartingDate);
        GLAccountNo := LibraryERM.CreateGLAccountNo;
        CalcAndPostVATSettlement(StartingDate, DocumentNo, GLAccountNo);
        LibraryTax.SelectVATStatementName(VATStatementName);

        // 2. Exercise
        PrintVATStatement(VATStatementName, StartingDate, DocumentNo);

        // 3. Verify
        VATStatementLine.Reset();
        VATStatementLine.SetRange("Statement Template Name", VATStatementTemplate.Name);
        VATStatementLine.SetRange("Statement Name", VATStatementName.Name);
        VATStatementLine.SetRange(Type, VATStatementLine.Type::Formula);
        VATStatementLine.SetRange(Print, true);
        VATStatementLine.FindFirst;
        RowNo := VATStatementLine."Row No.";

        VATStatementLine.SetRange(Type);
        VATStatementLine.SetRange(Print);
        VATStatementLine.SetFilter("Row No.", VATStatementLine."Row Totaling");
        if VATStatementLine.FindSet then
            repeat
                VATEntry.Reset();
                VATEntry.SetRange("Document No.", DocumentNo);
                VATEntry.SetRange("VAT Bus. Posting Group", VATStatementLine."VAT Bus. Posting Group");
                VATEntry.SetRange("VAT Prod. Posting Group", VATStatementLine."VAT Prod. Posting Group");
                case VATStatementLine."Gen. Posting Type" of
                    VATStatementLine."Gen. Posting Type"::Purchase:
                        VATEntry.SetFilter(Amount, '<=0');
                    VATStatementLine."Gen. Posting Type"::Sale:
                        VATEntry.SetFilter(Amount, '>=0');
                end;

                Sign := 1;
                if VATStatementLine."Print with" = VATStatementLine."Print with"::"Opposite Sign" then
                    Sign := -1;

                if VATEntry.FindFirst then
                    case VATStatementLine."Amount Type" of
                        VATStatementLine."Amount Type"::Amount:
                            TotalAmount += Sign * VATEntry.Amount;
                        VATStatementLine."Amount Type"::Base:
                            TotalAmount += Sign * VATEntry.Base;
                    end;
            until VATStatementLine.Next = 0;

        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('VatStmtLineRowNo', RowNo);
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'VatStmtLineRowNo', RowNo));
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalAmount', TotalAmount);

        // 4. Tear Down
        isInitialized := false;
    end;

    [Test]
    [HandlerFunctions('ReportCalcAndPostVATSettlementHandler,PageExportVATStatementHandler,YesConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ExportingVATStatementDPHDP3()
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        ExportingVATStatement();
    end;

    [Scope('OnPrem')]
    procedure ExportingVATStatement()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATStatementTemplate: Record "VAT Statement Template";
        StartingDate: Date;
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // 1. Setup
        Initialize;

        FindVATStatementTemplate(VATStatementTemplate);
        FindVATStatementLine(VATStatementLine, VATStatementTemplate.Name, '');

        StartingDate := LibraryTax.GetVATPeriodStartingDate;
        DocumentNo := GetSettlementNo(StartingDate);
        GLAccountNo := LibraryERM.CreateGLAccountNo;
        CalcAndPostVATSettlement(StartingDate, DocumentNo, GLAccountNo);

        // 2. Exercise
        RunExportVATStatement(
          VATStatementLine."Statement Template Name", VATStatementLine."Statement Name", StartingDate);

        // 3. Verify
        // Check that export is without error

        isInitialized := false;
    end;

    [Test]
    [HandlerFunctions('ReportCalcAndPostVATSettlementHandler,RequestPageVATStatementHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure AdditionalVATStatement()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLn: Record "Gen. Journal Line";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        StartingDate: Date;
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // 1. Setup
        Initialize;
        RevertToVATStatementLineDeprEnumValues(VATStatementLine);

        StartingDate := LibraryTax.GetVATPeriodStartingDate;
        DocumentNo := GetSettlementNo(StartingDate);
        GLAccountNo := LibraryERM.CreateGLAccountNo;
        Commit();
        CalcAndPostVATSettlement(StartingDate, DocumentNo, GLAccountNo);
        LibraryTax.ReopenVATPeriod(StartingDate);
        SelectGenJournalBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLn, GenJnlBatch."Journal Template Name", GenJnlBatch.Name, 0,
          GenJnlLn."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup,
          -LibraryRandom.RandDec(1000, 2));

        GenJnlLn.Validate("Posting Date", CalcDate('<+10D>', StartingDate));
        GenJnlLn.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJnlLn);

        DocumentNo := StrSubstNo('%1A', DocumentNo);
        Commit();
        CalcAndPostVATSettlement(StartingDate, DocumentNo, GLAccountNo);

        LibraryTax.SelectVATStatementName(VATStatementName);

        // 2. Exercise
        PrintVATStatement(VATStatementName, StartingDate, DocumentNo);

        // 3. Verify
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('VatStmtLineRowNo', '2DAN');
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'VatStmtLineRowNo', '2DAN'));
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalAmount', -GenJnlLn."VAT Amount");
    end;

    local procedure CalcAndPostVATSettlement(StartingDate: Date; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(CalcDate('<+1M-1D>', StartingDate));
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(GLAccountNo);
        LibraryVariableStorage.Enqueue(true);

        REPORT.Run(REPORT::"Calc. and Post VAT Settlement");
    end;

    local procedure CreateVATAttributeCode(var VATAttributeCode: Record "VAT Attribute Code"; VATStmtTempName: Code[10]; XMLCode: Code[20])
    begin
        LibraryTax.CreateVATAttributeCode(VATAttributeCode, VATStmtTempName);
        VATAttributeCode."XML Code" := XMLCode;
        VATAttributeCode.Modify();
    end;

    local procedure FindVATStatementLine(var VATStatementLine: Record "VAT Statement Line"; VATStmtTempName: Code[10]; RowNo: Code[10])
    begin
        VATStatementLine.Reset();
        VATStatementLine.SetRange("Statement Template Name", VATStmtTempName);
        VATStatementLine.SetRange("Row No.", RowNo);
        VATStatementLine.FindFirst;
    end;

    local procedure FindVATStatementTemplate(var VATStatementTemplate: Record "VAT Statement Template")
    begin
        LibraryTax.FindVATStatementTemplate(VATStatementTemplate);
        SetAttributeCodes(VATStatementTemplate.Name);
    end;

    local procedure GetSettlementNo(StartingDate: Date): Code[20]
    begin
        exit(StrSubstNo('VYRDPH%1%2', Date2DMY(StartingDate, 2), Date2DMY(StartingDate, 3)));
    end;

    local procedure PrintVATStatement(VATStatementName: Record "VAT Statement Name"; StartingDate: Date; DocumentNo: Code[20])
    var
        VATStmtLn: Record "VAT Statement Line";
    begin
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(DocumentNo);

        VATStmtLn.SetRange("Statement Template Name", VATStatementName."Statement Template Name");
        VATStmtLn.SetRange("Statement Name", VATStatementName.Name);

        LibraryTax.PrintVATStatement(VATStmtLn, true);
    end;

    local procedure RunExportVATStatement(StmtTempName: Code[10]; StmtName: Code[10]; StartingDate: Date)
    var
        FileMgt: Codeunit "File Management";
    begin
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(Date2DMY(StartingDate, 2));
        LibraryVariableStorage.Enqueue(Date2DMY(StartingDate, 3));
        LibraryVariableStorage.Enqueue(GetSettlementNo(StartingDate));

        LibraryTax.RunExportVATStatement(StmtTempName, StmtName);
    end;

    local procedure SetAttributeCode(var VATStatementLine: Record "VAT Statement Line"; AttributeCode: Code[20])
    begin
        LibraryTax.SetAttributeCode(VATStatementLine, AttributeCode);
    end;

    local procedure SetAttributeCodes(VATStatementTemplate: Code[10])
    var
        VATAttributeCode1: Record "VAT Attribute Code";
        VATAttributeCode2: Record "VAT Attribute Code";
        VATStatementLine: Record "VAT Statement Line";
    begin
        CreateVATAttributeCode(VATAttributeCode1, VATStatementTemplate, 'OBRAT5');
        CreateVATAttributeCode(VATAttributeCode2, VATStatementTemplate, 'PLN23');

        FindVATStatementLine(VATStatementLine, VATStatementTemplate, '40D');
        SetAttributeCode(VATStatementLine, VATAttributeCode1.Code);
        FindVATStatementLine(VATStatementLine, VATStatementTemplate, '3D');
        SetAttributeCode(VATStatementLine, VATAttributeCode2.Code);
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PageExportVATStatementHandler(var ExportVATStatement: TestPage "Export VAT Statement")
    var
        FieldValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(FieldValue);
        ExportVATStatement.Selection.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        ExportVATStatement.PeriodSelection.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        ExportVATStatement.Month.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        ExportVATStatement.Year.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        ExportVATStatement.SettlementNoFilter.SetValue(FieldValue);

        ExportVATStatement.OK.Invoke;
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure ReportCalcAndPostVATSettlementHandler(var CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement")
    var
        StartingDate: Date;
        EndingDate: Date;
        PostingDate: Date;
        DocumentNo: Code[20];
        SettlementAccountNo: Code[20];
        Post: Boolean;
    begin
        StartingDate := LibraryVariableStorage.DequeueDate;
        EndingDate := CalcDate('<+1M>', StartingDate);
        PostingDate := LibraryVariableStorage.DequeueDate;
        DocumentNo := CopyStr(LibraryVariableStorage.DequeueText, 1, 20);
        SettlementAccountNo := CopyStr(LibraryVariableStorage.DequeueText, 1, 20);
        Post := LibraryVariableStorage.DequeueBoolean;

        CalcAndPostVATSettlement.InitializeRequest(
          StartingDate, EndingDate, PostingDate, DocumentNo, SettlementAccountNo, false, Post);
        CalcAndPostVATSettlement.SaveAsXml(LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageVATStatementHandler(var VATStatement: TestRequestPage "VAT Statement")
    var
        StartingDate: Date;
        EndingDate: Date;
        Selection: Option;
        PeriodSelection: Option;
        DocumentNo: Code[20];
    begin
        StartingDate := LibraryVariableStorage.DequeueDate;
        EndingDate := CalcDate('<+1M>', StartingDate);
        Selection := LibraryVariableStorage.DequeueInteger;
        PeriodSelection := LibraryVariableStorage.DequeueInteger;
        DocumentNo := CopyStr(LibraryVariableStorage.DequeueText, 1, 20);

        VATStatement.StartingDate.SetValue(StartingDate);
        VATStatement.EndingDate.SetValue(EndingDate);
        VATStatement.Selection.SetValue(Selection);
        VATStatement.PeriodSelection.SetValue(PeriodSelection);
        VATStatement.SettlementNoFilter.SetValue(DocumentNo);

        VATStatement.SaveAsXml(
          LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    /// <summary> 
    /// Revert to VAT Statement Line Type::Formula.
    /// </summary>
    /// <remarks>
    /// If the demodata are already adjusted to the new Enum "VAT Statement Line Type" value(11700; "Formula CZL"), 
    /// revert back to the obsoleted value required by this test codeunit.
    /// </remarks>
    local procedure RevertToVATStatementLineDeprEnumValues(var VATStatementLine: Record "VAT Statement Line");
    begin
        VATStatementLine.Reset();
        VATStatementLine.SetRange(Type, 11700);
        if VATStatementLine.IsEmpty() then
            exit;
        VATStatementLine.ModifyAll(Type, VATStatementLine.Type::Formula, false);
        VATStatementLine.Reset();
    end;
}

