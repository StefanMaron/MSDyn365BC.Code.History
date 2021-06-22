codeunit 134162 "Payroll Import Gen. Jnl Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Payroll] [Import]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryPaymentFormat: Codeunit "Library - Payment Format";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        NotFindReadWritingErr: Label 'You must specify either a reading/writing XMLport or a reading/writing codeunit.';

    [Test]
    [Scope('OnPrem')]
    procedure ImportPayrollFileEmptyBatch()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DataExchDef: Record "Data Exch. Def";
        TempBlob: Codeunit "Temp Blob";
        ImportPayrollTransaction: Codeunit "Import Payroll Transaction";
        GenJournalLineDocNo: array[2] of Code[20];
        GenJournalLineAmount: array[2] of Decimal;
    begin
        // [SCENARIO] Import a Payroll file into Empty Gen Jnl.

        // [GIVEN] A payroll xml file
        DefinePayrollImportFormat(DataExchDef);
        CreateTestValues(GenJournalLineDocNo, GenJournalLineAmount);
        WritePayrollFile(TempBlob, GenJournalLineDocNo, GenJournalLineAmount);

        // [GIVEN] Empty Gen. Journal Batch to import into.
        CreateGenJournal(GenJournalLine);
        GenJournalLine.Delete();

        // [WHEN] Import Payroll file into Gen. Journal
        ImportPayrollTransaction.ImportPayrollDataToGL(GenJournalLine, '', TempBlob, DataExchDef.Code);

        // [THEN] Gen. Jnl. Lines are created as per the file content.
        VerifyGenJnlLine(GenJournalLine, GenJournalLineDocNo, GenJournalLineAmount, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPayrollFileAppendToBatch()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DataExchDef: Record "Data Exch. Def";
        TempBlob: Codeunit "Temp Blob";
        ImportPayrollTransaction: Codeunit "Import Payroll Transaction";
        GenJournalLineDocNo: array[2] of Code[20];
        GenJournalLineAmount: array[2] of Decimal;
    begin
        // [SCENARIO] Import a Payroll file into Gen Jnl. with line

        // [GIVEN] Data Exchange Definition with defined Reading/Writing XMLport Number
        // [GIVEN] A payroll xml file
        DefinePayrollImportFormat(DataExchDef);
        CreateTestValues(GenJournalLineDocNo, GenJournalLineAmount);
        WritePayrollFile(TempBlob, GenJournalLineDocNo, GenJournalLineAmount);

        // [GIVEN] Gen. Journal Batch with existing line.
        CreateGenJournal(GenJournalLine);

        // [WHEN] Import Payroll file into Gen. Journal
        ImportPayrollTransaction.ImportPayrollDataToGL(GenJournalLine, '', TempBlob, DataExchDef.Code);

        // [THEN] Gen. Jnl. Lines are created as per the file content.
        VerifyGenJnlLine(GenJournalLine, GenJournalLineDocNo, GenJournalLineAmount, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPayrollFileTextFixedLength()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DataExchDef: Record "Data Exch. Def";
        TempBlob: Codeunit "Temp Blob";
        ImportPayrollTransaction: Codeunit "Import Payroll Transaction";
        AccountNo: Code[20];
        GenJournalLineDocNo: array[2] of Code[20];
        GenJournalLineAmount: array[2] of Decimal;
    begin
        // [SCENARIO 380588] Import a Payroll file into Gen Jnl. when fields having fixed length format

        // [GIVEN] Data Exchange Definition with defined Reading/Writing Codeunit Number
        // [GIVEN] A payroll file with 2 strings having fixed length fields without delimiter
        // [GIVEN] 1st: "Document No." = "D1", "Account No.",Amount = "A1"
        // [GIVEN] 2nd: "Document No." = "D2", "Account No.",Amount = "A2"
        DefinePayrollImportFixedFormat(DataExchDef);
        CreateTestValues(GenJournalLineDocNo, GenJournalLineAmount);
        AccountNo := LibraryERM.CreateGLAccountNo;
        CreateTempBlob(TempBlob, GenJournalLineDocNo, GenJournalLineAmount, AccountNo, DataExchDef.Code);

        // [GIVEN] Gen. Journal Batch with existing line
        CreateGenJournal(GenJournalLine);

        // [WHEN] Import Payroll file into Gen Jnl.
        ImportPayrollTransaction.ImportPayrollDataToGL(GenJournalLine, '', TempBlob, DataExchDef.Code);

        // [THEN] Gen. Jnl. Lines are created. "GJL1": "Document No." = "D1", Amount = "A1", "GJL2": "Document No." = "D2", Amount = "A2".
        VerifyGenJnlLine(GenJournalLine, GenJournalLineDocNo, GenJournalLineAmount, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenImportCodeunitAndXmlPortBothNotDefinedOnDataExchDef()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempBlob: Codeunit "Temp Blob";
        ImportPayrollTransaction: Codeunit "Import Payroll Transaction";
        DataExchDefCode: Code[10];
    begin
        // [FEATURE] [UT]

        // [SCENARIO 380588] Error on import a Payroll file into Gen Jnl. when neither XMLPORT nor CODEUNIT will be defined

        // [GIVEN] Data Exchange Definition having Reading/Writing Coueunit and XMLport set to zero.
        DataExchDefCode := MockDataExchDef(0, 0);
        GenJournalLine.Init();

        // [WHEN] Import Payroll file into Gen Jnl.
        asserterror ImportPayrollTransaction.ImportPayrollDataToGL(GenJournalLine, '', TempBlob, DataExchDefCode);

        // [THEN] Error "You must specify either a reading/writing XMLport or a reading/writing codeunit." is thrown
        Assert.ExpectedError(NotFindReadWritingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenImportCodeunitAndXmlPortBothDefinedOnDataExchDef()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempBlob: Codeunit "Temp Blob";
        ImportPayrollTransaction: Codeunit "Import Payroll Transaction";
        DataExchDefCode: Code[10];
    begin
        // [FEATURE] [UT]

        // [SCENARIO 380588] Error on import a Payroll file into Gen Jnl. when both XMLPORT and CODEUNIT will be defined

        // [GIVEN] Data Exchange Definition having both Reading/Writing Coueunit and XMLport.
        DataExchDefCode := MockDataExchDef(LibraryRandom.RandInt(100), LibraryRandom.RandInt(100));
        GenJournalLine.Init();

        // [WHEN] Import Payroll file into Gen Jnl.
        asserterror ImportPayrollTransaction.ImportPayrollDataToGL(GenJournalLine, '', TempBlob, DataExchDefCode);

        // [THEN] Error "You must specify either a reading/writing XMLport or a reading/writing codeunit." is thrown
        Assert.ExpectedError(NotFindReadWritingErr);
    end;

    local procedure DefinePayrollImportFormat(var DataExchDef: Record "Data Exch. Def")
    var
        GenJournalLine: Record "Gen. Journal Line";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        LibraryPaymentFormat.CreateDataExchDef(DataExchDef, 0, 0,
          0, XMLPORT::"Data Exch. Import - CSV", CODEUNIT::"Read Data Exch. from File", 0);
        DataExchDef.Validate(Type, DataExchDef.Type::"Payroll Import");
        DataExchDef.Validate("File Encoding", DataExchDef."File Encoding"::WINDOWS);
        DataExchDef.Validate("Column Separator", DataExchDef."Column Separator"::Comma);
        DataExchDef.Modify(true);

        DataExchLineDef.InsertRec(DataExchDef.Code, DataExchDef.Code, DataExchDef.Code, 2);

        DataExchColumnDef.InsertRec(DataExchDef.Code, DataExchLineDef.Code, 1, GenJournalLine.FieldCaption("Document No."),
          true, DataExchColumnDef."Data Type"::Text, '', '', GenJournalLine.FieldName("Document No."));
        DataExchColumnDef.InsertRec(DataExchDef.Code, DataExchLineDef.Code, 2, GenJournalLine.FieldCaption(Amount),
          true, DataExchColumnDef."Data Type"::Decimal, '<Precision,2><sign><Integer><Decimals><Comma,.>', 'en-US',
          GenJournalLine.FieldName(Amount));

        DataExchMapping.InsertRecForExport(DataExchDef.Code, DataExchLineDef.Code,
          DATABASE::"Gen. Journal Line", DataExchDef.Code, CODEUNIT::"Process Gen. Journal  Lines");
        DataExchFieldMapping.InsertRec(DataExchDef.Code, DataExchLineDef.Code,
          DATABASE::"Gen. Journal Line", 1, GenJournalLine.FieldNo("Document No."), false, 0);
        DataExchFieldMapping.InsertRec(DataExchDef.Code, DataExchLineDef.Code,
          DATABASE::"Gen. Journal Line", 2, GenJournalLine.FieldNo(Amount), false, 1);
    end;

    local procedure DefinePayrollImportFixedFormat(var DataExchDef: Record "Data Exch. Def")
    var
        GenJournalLine: Record "Gen. Journal Line";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        LibraryPaymentFormat.CreateDataExchDef(DataExchDef, 0, 0,
          CODEUNIT::"Fixed File Import", 0, CODEUNIT::"Read Data Exch. from File", 0);
        DataExchDef.Validate(Type, DataExchDef.Type::"Payroll Import");
        DataExchDef.Validate("File Type", DataExchDef."File Type"::"Fixed Text");
        DataExchDef.Modify(true);

        DataExchLineDef.InsertRec(DataExchDef.Code, DataExchDef.Code, DataExchDef.Code, 2);

        DataExchColumnDef.InsertRecForExport(
          DataExchDef.Code, DataExchLineDef.Code, 1, GenJournalLine.FieldCaption("Document No."),
          DataExchColumnDef."Data Type"::Text, '', 10, '');
        DataExchColumnDef.InsertRecForExport(
          DataExchDef.Code, DataExchLineDef.Code, 2, GenJournalLine.FieldCaption("Account No."),
          DataExchColumnDef."Data Type"::Text, '', 20, '');
        DataExchColumnDef.InsertRecForExport(
          DataExchDef.Code, DataExchLineDef.Code, 3, GenJournalLine.FieldCaption(Amount),
          DataExchColumnDef."Data Type"::Decimal, '<Precision,2><sign><Integer><Decimals><Comma,.>', 10, '');

        DataExchMapping.InsertRecForExport(DataExchDef.Code, DataExchLineDef.Code,
          DATABASE::"Gen. Journal Line", DataExchDef.Code, CODEUNIT::"Process Gen. Journal  Lines");
        DataExchFieldMapping.InsertRec(DataExchDef.Code, DataExchLineDef.Code,
          DATABASE::"Gen. Journal Line", 1, GenJournalLine.FieldNo("Document No."), false, 0);
        DataExchFieldMapping.InsertRec(DataExchDef.Code, DataExchLineDef.Code,
          DATABASE::"Gen. Journal Line", 2, GenJournalLine.FieldNo("Account No."), false, 0);
        DataExchFieldMapping.InsertRec(DataExchDef.Code, DataExchLineDef.Code,
          DATABASE::"Gen. Journal Line", 3, GenJournalLine.FieldNo(Amount), false, 1);
    end;

    local procedure MockDataExchDef(CodeuninNo: Integer; XMLPortNo: Integer): Code[10]
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        DataExchDef.Init();
        DataExchDef.Code := LibraryUtility.GenerateGUID;
        DataExchDef."Reading/Writing XMLport" := XMLPortNo;
        DataExchDef."Reading/Writing Codeunit" := CodeuninNo;
        DataExchDef.Insert();
        exit(DataExchDef.Code);
    end;

    local procedure CreateGenJournal(var GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo, 0);
        GenJournalLine."Document No." := '';
        GenJournalLine.Modify();
    end;

    local procedure CreateTestValues(var GenJournalLineDocNo: array[2] of Code[20]; var GenJournalLineAmount: array[2] of Decimal)
    begin
        GenJournalLineDocNo[1] := LibraryUtility.GenerateGUID;
        GenJournalLineAmount[1] := LibraryRandom.RandInt(100);
        GenJournalLineDocNo[2] := LibraryUtility.GenerateGUID;
        GenJournalLineAmount[2] := LibraryRandom.RandInt(100);
    end;

    local procedure CreateTempBlob(var TempBlob: Codeunit "Temp Blob"; var GenJournalLineDocNo: array[2] of Code[20]; var GenJournalLineAmount: array[2] of Decimal; AccountNo: Code[20]; DataExchDefCode: Code[20])
    var
        DataExch: Record "Data Exch.";
        TempBlobInStream: InStream;
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::MSDos);
        CreateTempBlobString(OutStream, GenJournalLineDocNo[1], GenJournalLineAmount[1], AccountNo);
        CreateTempBlobString(OutStream, GenJournalLineDocNo[2], GenJournalLineAmount[2], AccountNo);
        TempBlob.CreateInStream(TempBlobInStream);
        DataExch.InsertRec('', TempBlobInStream, DataExchDefCode);
    end;

    local procedure CreateTempBlobString(var OutStream: OutStream; GenJournalLineDocNo: Code[20]; GenJournalLineAmount: Decimal; AccountNo: Code[20])
    begin
        OutStream.WriteText(GenJournalLineDocNo, 10);
        OutStream.WriteText(PadStr(AccountNo, 20));
        OutStream.WriteText(Format(GenJournalLineAmount, 10));
        OutStream.WriteText;
    end;

    local procedure WritePayrollFile(var TempBlob: Codeunit "Temp Blob"; GenJournalLineDocNo: array[2] of Code[20]; GenJournalLineAmount: array[2] of Decimal)
    var
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::Windows);
        OutStream.WriteText(GenJournalLineDocNo[1] + ',' + Format(GenJournalLineAmount[1]));
        OutStream.WriteText;
        OutStream.WriteText(GenJournalLineDocNo[2] + ',' + Format(GenJournalLineAmount[2]));
        OutStream.WriteText;
    end;

    local procedure VerifyGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; ExpDocNo: array[2] of Code[20]; ExpAmount: array[2] of Decimal; ExpCountOfGenJournalLine: Integer)
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        Assert.RecordCount(GenJournalLine, ExpCountOfGenJournalLine);

        GenJournalLine.SetRange("Document No.", ExpDocNo[1]);
        GenJournalLine.FindFirst;
        GenJournalLine.TestField(Amount, ExpAmount[1]);
        GenJournalLine.SetRange("Document No.", ExpDocNo[2]);
        GenJournalLine.FindFirst;
        GenJournalLine.TestField(Amount, ExpAmount[2]);
    end;
}

