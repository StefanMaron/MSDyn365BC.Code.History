codeunit 132542 TestMappingToW1Tables
{
    Permissions = TableData "G/L Entry" = imd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        BalAccTypeErr: Label '%1 must be equal to ''%2''  in Data Exch. Def: Code=%3. Current value is ''%4''.', Comment = '%1=field caption,%2=definition type,%3=Data Exch. Def Code,%4=Data Exch. Def Code Value';
        BankStmtImpFormatBalAccErr: Label '%1 must be blank. When %2 = %3, then %1 on the Bank Account card will be used in %4 %5=''%6'',%7=''%8''.', Comment = '%1 = Bank Statement Import Format;%2 = Bal. Account Type;%3 = value;%4 = Gen. Journal Batch;%5 = Journal Template Name;%6 = value;%7 = Name;%8 = value';
        WrongNoOfLinesErr: Label 'Wrong number of lines imported.';

    [Test]
    [Scope('OnPrem')]
    procedure TestImportToGenJnlLineTwice()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExch: Record "Data Exch.";
        DataExch1: Record "Data Exch.";
        GenJnlLineTemplate: Record "Gen. Journal Line";
        GenJnlLineTemplate2: Record "Gen. Journal Line";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobANSI: Codeunit "Temp Blob";
        OutStream: OutStream;
        DocNo: Code[20];
        LineNo: Integer;
    begin
        // Pre-Setup
        Initialize;
        SetupFileDefinition(DataExchDef, DataExchLineDef);
        SetupFileMapping(DataExchDef.Code, DataExchLineDef.Code, DATABASE::"Gen. Journal Line", CODEUNIT::"Process Gen. Journal  Lines",
          GenJnlLineTemplate.FieldNo("Data Exch. Entry No."), GenJnlLineTemplate.FieldNo("Data Exch. Line No."),
          GenJnlLineTemplate.FieldNo("Posting Date"), GenJnlLineTemplate.FieldNo(Description), GenJnlLineTemplate.FieldNo(Amount), -1);

        // Setup Input Table
        TempBlobOEM.CreateOutStream(OutStream);
        WriteLine(OutStream, StrSubstNo('%1,%2,%3', Format(WorkDate, 6, '<Day,2><Month,2><Year,2>'), 'AnyText', 100));
        WriteLine(OutStream, StrSubstNo('%1,%2,%3', Format(WorkDate, 6, '<Day,2><Month,2><Year,2>'), 'AnyText', 100));
        ConvertOEMToANSI(TempBlobOEM, TempBlobANSI);
        SetupSourceMock(DataExchDef.Code, TempBlobANSI);

        // Exercise
        CreateRecTemplate(GenJnlLineTemplate, DataExchDef.Code);
        AddFiltersToRecTemplate(GenJnlLineTemplate);
        GenJnlLineTemplate.Delete(true); // The template needs to removed to not skew when comparing testresults.
        GenJnlLineTemplate.ImportBankStatement;
        DataExch.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExch.FindLast;

        LibraryERM.CreateGeneralJnlLine(
          GenJnlLineTemplate2, GenJnlLineTemplate."Journal Template Name", GenJnlLineTemplate."Journal Batch Name",
          GenJnlLineTemplate."Document Type"::Payment, GenJnlLineTemplate."Account Type"::"Bank Account", '', 0);
        GenJnlLineTemplate2.Delete;

        GenJnlLineTemplate2.ImportBankStatement;
        DataExch1.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExch1.FindLast;

        // Verify
        Assert.AreEqual(4, GenJnlLineTemplate.Count, 'Not all lines was created');
        LineNo := 10000;
        DocNo := GenJnlLineTemplate."Document No.";
        VerifyImportedGenJnlLinesWithDataExchNo(GenJnlLineTemplate, LineNo, DocNo, DataExch."Entry No.", 2);
        VerifyImportedGenJnlLinesWithDataExchNo(GenJnlLineTemplate, LineNo, DocNo, DataExch1."Entry No.", 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportExistingGenJnlLine()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        GenJnlLineTemplate: Record "Gen. Journal Line";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobANSI: Codeunit "Temp Blob";
        OutStream: OutStream;
        DocNo: Code[20];
        LineNo: Integer;
    begin
        // Pre-Setup
        Initialize;
        SetupFileDefinition(DataExchDef, DataExchLineDef);
        SetupFileMapping(DataExchDef.Code, DataExchLineDef.Code, DATABASE::"Gen. Journal Line", CODEUNIT::"Process Gen. Journal  Lines",
          GenJnlLineTemplate.FieldNo("Data Exch. Entry No."), GenJnlLineTemplate.FieldNo("Data Exch. Line No."),
          GenJnlLineTemplate.FieldNo("Posting Date"), GenJnlLineTemplate.FieldNo(Description), GenJnlLineTemplate.FieldNo(Amount), -1);

        // Setup Input Table
        TempBlobOEM.CreateOutStream(OutStream);
        WriteLine(OutStream, StrSubstNo('%1,%2,%3', Format(WorkDate, 6, '<Day,2><Month,2><Year,2>'), 'AnyText', 100));
        ConvertOEMToANSI(TempBlobOEM, TempBlobANSI);
        SetupSourceMock(DataExchDef.Code, TempBlobANSI);

        // Exercise
        CreateRecTemplate(GenJnlLineTemplate, DataExchDef.Code);
        AddFiltersToRecTemplate(GenJnlLineTemplate);
        GenJnlLineTemplate.ImportBankStatement;
        GenJnlLineTemplate.ImportBankStatement;

        // Verify
        Assert.AreEqual(3, GenJnlLineTemplate.Count, 'Not all lines was created');
        LineNo := 10000;
        DocNo := GenJnlLineTemplate."Document No.";
        VerifyImportedGenJnlLines(GenJnlLineTemplate, LineNo, DocNo, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportMultiRowMultiColumnsToGenJnlLine()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExch: Record "Data Exch.";
        GenJnlLineTemplate: Record "Gen. Journal Line";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobANSI: Codeunit "Temp Blob";
        OutStream: OutStream;
        AnyLineCount: Integer;
        AnyDate: array[1000] of Date;
        AnyText: array[1000] of Text;
        AnyDecimal: array[1000] of Decimal;
        i: Integer;
    begin
        // Pre-Setup
        Initialize;
        SetupFileDefinition(DataExchDef, DataExchLineDef);
        SetupFileMapping(DataExchDef.Code, DataExchLineDef.Code, DATABASE::"Gen. Journal Line", CODEUNIT::"Process Gen. Journal  Lines",
          GenJnlLineTemplate.FieldNo("Data Exch. Entry No."), GenJnlLineTemplate.FieldNo("Data Exch. Line No."),
          GenJnlLineTemplate.FieldNo("Posting Date"), GenJnlLineTemplate.FieldNo(Description), GenJnlLineTemplate.FieldNo(Amount), -1);

        // Setup Input Table
        GenerateAnyInputData(AnyLineCount, AnyDate, AnyText, AnyDecimal);
        TempBlobOEM.CreateOutStream(OutStream);
        for i := 1 to AnyLineCount do
            WriteLine(
              OutStream, StrSubstNo('%1,%2,%3', Format(AnyDate[i], 6, '<Day,2><Month,2><Year,2>'), AnyText[i], Format(AnyDecimal[i], 20, 9)));
        ConvertOEMToANSI(TempBlobOEM, TempBlobANSI);
        SetupSourceMock(DataExchDef.Code, TempBlobANSI);

        // Exercise
        CreateRecTemplate(GenJnlLineTemplate, DataExchDef.Code);
        AddFiltersToRecTemplate(GenJnlLineTemplate);
        GenJnlLineTemplate.Delete(true); // The template needs to removed to not skew when comparing testresults.
        GenJnlLineTemplate.ImportBankStatement;

        // Verify
        DataExch.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExch.FindFirst;
        GenJnlLineTemplate.FindSet;
        for i := 1 to AnyLineCount do begin
            Assert.AreEqual(AnyDate[i], GenJnlLineTemplate."Posting Date", 'Posting Date did not Match');
            Assert.AreEqual(AnyText[i], GenJnlLineTemplate.Description, 'Description did not Match');
            Assert.AreEqual(-AnyDecimal[i], GenJnlLineTemplate.Amount, 'Amount did not Match');
            Assert.AreEqual(i, GenJnlLineTemplate."Data Exch. Line No.", 'Line no. did not match.');
            Assert.AreEqual(DataExch."Entry No.", GenJnlLineTemplate."Data Exch. Entry No.", 'Wrong data entry no.');
            GenJnlLineTemplate.Next;
        end;

        GenJnlLineTemplate.FindFirst;
        for i := 1 to AnyLineCount - 1 do
            Assert.AreEqual(1, GenJnlLineTemplate.Next, StrSubstNo('Line %1 is missing', i));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportMultiRowMultiColumnsToGenJnlLineNoBank()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExch: Record "Data Exch.";
        GenJnlLineTemplate: Record "Gen. Journal Line";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobANSI: Codeunit "Temp Blob";
        OutStream: OutStream;
        AnyLineCount: Integer;
        AnyDate: array[1000] of Date;
        AnyText: array[1000] of Text;
        AnyDecimal: array[1000] of Decimal;
        i: Integer;
    begin
        // Pre-Setup
        Initialize;
        SetupFileDefinition(DataExchDef, DataExchLineDef);
        SetupFileMapping(DataExchDef.Code, DataExchLineDef.Code, DATABASE::"Gen. Journal Line", CODEUNIT::"Process Gen. Journal  Lines",
          GenJnlLineTemplate.FieldNo("Data Exch. Entry No."), GenJnlLineTemplate.FieldNo("Data Exch. Line No."),
          GenJnlLineTemplate.FieldNo("Posting Date"), GenJnlLineTemplate.FieldNo(Description), GenJnlLineTemplate.FieldNo(Amount), -1);

        // Setup Input Table
        GenerateAnyInputData(AnyLineCount, AnyDate, AnyText, AnyDecimal);
        TempBlobOEM.CreateOutStream(OutStream);
        for i := 1 to AnyLineCount do
            WriteLine(
              OutStream, StrSubstNo('%1,%2,%3', Format(AnyDate[i], 6, '<Day,2><Month,2><Year,2>'), AnyText[i], Format(AnyDecimal[i], 20, 9)));
        ConvertOEMToANSI(TempBlobOEM, TempBlobANSI);
        SetupSourceMock(DataExchDef.Code, TempBlobANSI);

        // Exercise
        CreateRecTemplateNoBank(GenJnlLineTemplate, DataExchDef.Code);
        AddFiltersToRecTemplate(GenJnlLineTemplate);
        GenJnlLineTemplate.Delete(true); // The template needs to removed to not skew when comparing testresults.
        GenJnlLineTemplate.ImportBankStatement;

        // Verify
        DataExch.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExch.FindFirst;
        GenJnlLineTemplate.FindSet;
        for i := 1 to AnyLineCount do begin
            Assert.AreEqual(AnyDate[i], GenJnlLineTemplate."Posting Date", 'Posting Date did not Match');
            Assert.AreEqual(AnyText[i], GenJnlLineTemplate.Description, 'Description did not Match');
            Assert.AreEqual(-AnyDecimal[i], GenJnlLineTemplate.Amount, 'Amount did not Match');
            Assert.AreEqual(i, GenJnlLineTemplate."Data Exch. Line No.", 'Line no. did not match.');
            Assert.AreEqual(DataExch."Entry No.", GenJnlLineTemplate."Data Exch. Entry No.", 'Wrong data entry no.');
            GenJnlLineTemplate.Next;
        end;

        GenJnlLineTemplate.FindFirst;
        for i := 1 to AnyLineCount - 1 do
            Assert.AreEqual(1, GenJnlLineTemplate.Next, StrSubstNo('Line %1 is missing', i));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImporGenJnlLineBlankBankAccError()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ProcessGenJournalLines: Codeunit "Process Gen. Journal  Lines";
    begin
        // Pre-Setup
        Initialize;
        CreateRecTemplateNoBank(GenJnlLine, '');
        GenJournalBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch."Bal. Account No." := '';
        GenJournalBatch.Modify;

        // Exercise
        asserterror ProcessGenJournalLines.ImportBankStatement(GenJnlLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImporGenJnlLineBlankBankStmtFormatError()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ProcessGenJournalLines: Codeunit "Process Gen. Journal  Lines";
    begin
        // Pre-Setup
        Initialize;
        CreateRecTemplateNoBank(GenJnlLine, '');
        GenJournalBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"G/L Account";
        GenJournalBatch."Bank Statement Import Format" := '';
        GenJournalBatch.Modify;

        // Exercise
        asserterror ProcessGenJournalLines.ImportBankStatement(GenJnlLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImporGenJnlLineBalAccTypeError()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ProcessGenJournalLines: Codeunit "Process Gen. Journal  Lines";
    begin
        // Pre-Setup
        Initialize;
        CreateRecTemplateNoBank(GenJnlLine, '');
        GenJournalBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::Vendor;
        GenJournalBatch.Modify;

        // Exercise
        asserterror ProcessGenJournalLines.ImportBankStatement(GenJnlLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportMultiRowMultiColumnsToBankRecLine()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExch: Record "Data Exch.";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobANSI: Codeunit "Temp Blob";
        OutStream: OutStream;
        AnyLineCount: Integer;
        AnyDate: array[1000] of Date;
        AnyText: array[1000] of Text;
        AnyDecimal: array[1000] of Decimal;
        i: Integer;
    begin
        // Pre-Setup
        Initialize;
        SetupFileDefinition(DataExchDef, DataExchLineDef);
        SetupFileMapping(DataExchDef.Code, DataExchLineDef.Code, DATABASE::"Bank Acc. Reconciliation Line",
          CODEUNIT::"Process Bank Acc. Rec Lines", BankAccReconciliationLine.FieldNo("Data Exch. Entry No."),
          BankAccReconciliationLine.FieldNo("Data Exch. Line No."), BankAccReconciliationLine.FieldNo("Transaction Date"),
          BankAccReconciliationLine.FieldNo(Description), BankAccReconciliationLine.FieldNo("Statement Amount"), 1);

        // Setup Input Table
        GenerateAnyInputData(AnyLineCount, AnyDate, AnyText, AnyDecimal);
        TempBlobOEM.CreateOutStream(OutStream);
        for i := 1 to AnyLineCount do
            WriteLine(
              OutStream, StrSubstNo('%1,%2,%3', Format(AnyDate[i], 6, '<Day,2><Month,2><Year,2>'), AnyText[i], Format(AnyDecimal[i], 20, 9)));
        ConvertOEMToANSI(TempBlobOEM, TempBlobANSI);
        AddTempBlobToArray(TempBlobANSI);

        // Exercise
        CreateBankAccRecLineTemplateWithFilter(BankAccReconciliation, BankAccReconciliationLine, DataExchDef.Code);
        BankAccReconciliationLine.Delete(true);
        BankAccReconciliation.ImportBankStatement;

        // Verify
        DataExch.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExch.FindFirst;
        BankAccReconciliationLine.FindSet;
        for i := 1 to AnyLineCount do begin
            Assert.AreEqual(AnyDate[i], BankAccReconciliationLine."Transaction Date", 'Date did not Match');
            Assert.AreEqual(AnyText[i], BankAccReconciliationLine.Description, 'Description did not Match');
            Assert.AreEqual(AnyDecimal[i], BankAccReconciliationLine."Statement Amount", 'Amount did not Match');
            Assert.AreEqual(i, BankAccReconciliationLine."Data Exch. Line No.", 'Line no. did not match.');
            Assert.AreEqual(DataExch."Entry No.", BankAccReconciliationLine."Data Exch. Entry No.", 'Wrong data entry no.');
            BankAccReconciliationLine.Next;
        end;

        BankAccReconciliationLine.FindFirst;
        for i := 1 to AnyLineCount - 1 do
            Assert.AreEqual(1, BankAccReconciliationLine.Next, StrSubstNo('Line %1 is missing', i));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportStatementToGenJnlLineDeleteRelatedInfo()
    var
        DataExchField: Record "Data Exch. Field";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        GenJnlLineTemplate: Record "Gen. Journal Line";
        TempBlobANSI: Codeunit "Temp Blob";
        LineCount: Integer;
    begin
        // Pre-Setup
        Initialize;
        SetupFileDefinition(DataExchDef, DataExchLineDef);
        SetupFileMapping(DataExchDef.Code, DataExchLineDef.Code, DATABASE::"Gen. Journal Line", CODEUNIT::"Process Gen. Journal  Lines",
          GenJnlLineTemplate.FieldNo("Data Exch. Entry No."), GenJnlLineTemplate.FieldNo("Data Exch. Line No."),
          GenJnlLineTemplate.FieldNo("Posting Date"), GenJnlLineTemplate.FieldNo(Description), GenJnlLineTemplate.FieldNo(Amount), -1);

        // Setup Input Table
        CreateImportBlob(TempBlobANSI);
        CreateRecTemplate(GenJnlLineTemplate, DataExchDef.Code);
        AddFiltersToRecTemplate(GenJnlLineTemplate);
        GenJnlLineTemplate.Delete(true); // The template needs to removed to not skew when comparing testresults.
        GenJnlLineTemplate.ImportBankStatement;

        LineCount := GenJnlLineTemplate.Count;
        GenJnlLineTemplate.Next(LibraryRandom.RandInt(LineCount));
        DataExchField.SetRange("Data Exch. No.", GenJnlLineTemplate."Data Exch. Entry No.");
        DataExchField.SetRange("Line No.", GenJnlLineTemplate."Data Exch. Line No.");

        // Exercise.
        GenJnlLineTemplate.Delete(true);

        // Verify.
        Assert.IsTrue(DataExchField.IsEmpty, 'Records not deleted.');
        DataExchField.SetFilter("Line No.", '<>%1', GenJnlLineTemplate."Data Exch. Line No.");
        if LineCount > 1 then
            Assert.IsFalse(DataExchField.IsEmpty, 'Too many records deleted.')
        else
            Assert.IsTrue(DataExchField.IsEmpty, 'Too few records deleted.')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportStatementToBankRecLineDeleteRelatedInfo()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        DataExchField: Record "Data Exch. Field";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        TempBlobANSI: Codeunit "Temp Blob";
        LineCount: Integer;
    begin
        // Pre-Setup
        Initialize;
        SetupFileDefinition(DataExchDef, DataExchLineDef);
        SetupFileMapping(DataExchDef.Code, DataExchLineDef.Code, DATABASE::"Bank Acc. Reconciliation Line",
          CODEUNIT::"Process Bank Acc. Rec Lines", BankAccReconciliationLine.FieldNo("Data Exch. Entry No."),
          BankAccReconciliationLine.FieldNo("Data Exch. Line No."), BankAccReconciliationLine.FieldNo("Transaction Date"),
          BankAccReconciliationLine.FieldNo(Description), BankAccReconciliationLine.FieldNo("Statement Amount"), 1);

        // Setup Input Table
        CreateImportBlob(TempBlobANSI);
        CreateBankAccRecLineTemplateWithFilter(BankAccReconciliation, BankAccReconciliationLine, DataExchDef.Code);
        BankAccReconciliationLine.Delete(true);
        BankAccReconciliation.ImportBankStatement;

        LineCount := BankAccReconciliationLine.Count;
        BankAccReconciliationLine.Next(LibraryRandom.RandInt(LineCount));
        DataExchField.SetRange("Data Exch. No.", BankAccReconciliationLine."Data Exch. Entry No.");
        DataExchField.SetRange("Line No.", BankAccReconciliationLine."Data Exch. Line No.");

        // Exercise.
        BankAccReconciliationLine.Delete(true);

        // Verify
        Assert.IsTrue(DataExchField.IsEmpty, 'Records not deleted.');
        DataExchField.SetFilter("Line No.", '<>%1', BankAccReconciliationLine."Data Exch. Line No.");
        if LineCount > 1 then
            Assert.IsFalse(DataExchField.IsEmpty, 'Too many records deleted.')
        else
            Assert.IsTrue(DataExchField.IsEmpty, 'Too few records deleted.')
    end;

    [Test]
    [HandlerFunctions('GenJnlLineTemplateListPageHandler')]
    [Scope('OnPrem')]
    procedure TestImportStatementToGenJnlLineShowDetails()
    var
        DataExchField: Record "Data Exch. Field";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        GenJnlLineTemplate: Record "Gen. Journal Line";
        TempBlobANSI: Codeunit "Temp Blob";
        GeneralJournal: TestPage "General Journal";
        BankStatementLineDetails: TestPage "Bank Statement Line Details";
    begin
        // Pre-Setup
        Initialize;
        SetupFileDefinition(DataExchDef, DataExchLineDef);
        SetupFileMapping(DataExchDef.Code, DataExchLineDef.Code, DATABASE::"Gen. Journal Line", CODEUNIT::"Process Gen. Journal  Lines",
          GenJnlLineTemplate.FieldNo("Data Exch. Entry No."), GenJnlLineTemplate.FieldNo("Data Exch. Line No."),
          GenJnlLineTemplate.FieldNo("Posting Date"), GenJnlLineTemplate.FieldNo(Description), GenJnlLineTemplate.FieldNo(Amount), -1);

        // Setup Input Table
        CreateImportBlob(TempBlobANSI);
        CreateRecTemplate(GenJnlLineTemplate, DataExchDef.Code);
        AddFiltersToRecTemplate(GenJnlLineTemplate);
        GenJnlLineTemplate.Delete(true); // The template needs to removed to not skew when comparing testresults.
        GenJnlLineTemplate.ImportBankStatement;
        GenJnlLineTemplate.Next(LibraryRandom.RandInt(GenJnlLineTemplate.Count));
        DataExchField.SetRange("Data Exch. No.", GenJnlLineTemplate."Data Exch. Entry No.");
        DataExchField.SetRange("Line No.", GenJnlLineTemplate."Data Exch. Line No.");

        // Exercise.
        LibraryVariableStorage.Enqueue(GenJnlLineTemplate."Journal Template Name");
        BankStatementLineDetails.Trap;
        GeneralJournal.OpenView;
        // Based on new changes General Journal page (PAG39) is always opened in simple mode which
        // displays one document number at a time. So, we need to filter simple page document number
        // to display this record on the view.
        GeneralJournal."<Document No. Simple Page>".SetValue(GenJnlLineTemplate."Document No.");
        GeneralJournal.GotoRecord(GenJnlLineTemplate);
        GeneralJournal.ShowStatementLineDetails.Invoke;

        // Verify.
        VerifyBankStatementDetailsPage(DataExchField, BankStatementLineDetails, DataExchDef.Code, DataExchLineDef.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportStatementToBankRecLineShowDetails()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        DataExchField: Record "Data Exch. Field";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        TempBlobANSI: Codeunit "Temp Blob";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        BankStatementLineDetails: TestPage "Bank Statement Line Details";
    begin
        // Pre-Setup
        Initialize;
        SetupFileDefinition(DataExchDef, DataExchLineDef);
        SetupFileMapping(DataExchDef.Code, DataExchLineDef.Code, DATABASE::"Bank Acc. Reconciliation Line",
          CODEUNIT::"Process Bank Acc. Rec Lines", BankAccReconciliationLine.FieldNo("Data Exch. Entry No."),
          BankAccReconciliationLine.FieldNo("Data Exch. Line No."), BankAccReconciliationLine.FieldNo("Transaction Date"),
          BankAccReconciliationLine.FieldNo(Description), BankAccReconciliationLine.FieldNo("Statement Amount"), 1);

        // Setup Input Table
        CreateImportBlob(TempBlobANSI);
        CreateBankAccRecLineTemplateWithFilter(BankAccReconciliation, BankAccReconciliationLine, DataExchDef.Code);
        BankAccReconciliationLine.Delete(true);
        BankAccReconciliation.ImportBankStatement;

        BankAccReconciliationLine.Next(LibraryRandom.RandInt(BankAccReconciliationLine.Count));
        DataExchField.SetRange("Data Exch. No.", BankAccReconciliationLine."Data Exch. Entry No.");
        DataExchField.SetRange("Line No.", BankAccReconciliationLine."Data Exch. Line No.");

        // Exercise.
        BankStatementLineDetails.Trap;
        BankAccReconciliationPage.OpenView;
        BankAccReconciliationPage.GotoRecord(BankAccReconciliation);
        BankAccReconciliationPage.StmtLine.FILTER.SetFilter("Statement Line No.", Format(BankAccReconciliationLine."Statement Line No."));
        BankAccReconciliationPage.StmtLine.ShowStatementLineDetails.Invoke;

        // Verify.
        VerifyBankStatementDetailsPage(DataExchField, BankStatementLineDetails, DataExchDef.Code, DataExchLineDef.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportStatementToGenJnlLineSetsFileNameAndContent()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        GenJnlLineTemplate: Record "Gen. Journal Line";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        // Pre-Setup
        Initialize;
        SetupFileDefinition(DataExchDef, DataExchLineDef);
        SetupFileMapping(DataExchDef.Code, DataExchLineDef.Code, DATABASE::"Gen. Journal Line", CODEUNIT::"Process Gen. Journal  Lines",
          GenJnlLineTemplate.FieldNo("Data Exch. Entry No."), GenJnlLineTemplate.FieldNo("Data Exch. Line No."),
          GenJnlLineTemplate.FieldNo("Posting Date"), GenJnlLineTemplate.FieldNo(Description), GenJnlLineTemplate.FieldNo(Amount), -1);

        // Setup Input Table
        TempBlob.CreateOutStream(OutStream);
        WriteLine(OutStream, StrSubstNo('%1,%2,%3', Format(WorkDate, 6, '<Day,2><Month,2><Year,2>'), 'AnyText', 100));
        SetupSourceMock(DataExchDef.Code, TempBlob);

        // Exercise
        CreateRecTemplate(GenJnlLineTemplate, DataExchDef.Code);
        GenJnlLineTemplate.ImportBankStatement;

        // Verify
        DataExch.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExch.FindLast;
        Assert.IsTrue(DataExch."File Content".HasValue, 'Blob is missing');
    end;

    [Test]
    [HandlerFunctions('GenJnlLineTemplateListPageHandler')]
    [Scope('OnPrem')]
    procedure TestNotImportedGenJnlLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
        BankStatementLineDetails: TestPage "Bank Statement Line Details";
    begin
        // Pre-Setup
        Initialize;

        // Setup Input Table
        CreateRecTemplate(GenJnlLine, '');

        // Exercise.
        LibraryVariableStorage.Enqueue(GenJnlLine."Journal Template Name");
        BankStatementLineDetails.Trap;
        GeneralJournal.OpenView;
        GeneralJournal.GotoRecord(GenJnlLine);
        GeneralJournal.ShowStatementLineDetails.Invoke;

        // Verify.
        VerifyEmptyBankStatementDetailsPage(BankStatementLineDetails);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNotImportedBankRecLine()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        BankStatementLineDetails: TestPage "Bank Statement Line Details";
    begin
        // Pre-Setup
        Initialize;

        // Setup Input Table
        CreateBankAccRecLineTemplateWithFilter(BankAccReconciliation, BankAccReconciliationLine, '');

        // Exercise.
        BankStatementLineDetails.Trap;
        BankAccReconciliationPage.OpenView;
        BankAccReconciliationPage.GotoRecord(BankAccReconciliation);
        BankAccReconciliationPage.StmtLine.FILTER.SetFilter("Statement Line No.", Format(BankAccReconciliationLine."Statement Line No."));
        BankAccReconciliationPage.StmtLine.ShowStatementLineDetails.Invoke;

        // Verify.
        VerifyEmptyBankStatementDetailsPage(BankStatementLineDetails);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNotImportedWrongFormatType()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        Vendor: Record Vendor;
    begin
        // Pre-Setup
        Initialize;
        SetupFileDefinition(DataExchDef, DataExchLineDef);
        SetupFileMapping(DataExchDef.Code, DataExchLineDef.Code, DATABASE::"Gen. Journal Line", CODEUNIT::"Process Gen. Journal  Lines",
          GenJnlLine.FieldNo("Data Exch. Entry No."), GenJnlLine.FieldNo("Data Exch. Line No."),
          GenJnlLine.FieldNo("Posting Date"), GenJnlLine.FieldNo(Description), GenJnlLine.FieldNo(Amount), -1);

        // Setup
        CreateGenJnlBatchWithBalBankAcc(GenJnlBatch, DataExchDef.Code);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name,
          GenJnlLine."Document Type"::Payment, GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(10000, 2));

        // Pre-Exercise
        DataExchDef.Type := DataExchDef.Type::"Payment Export";
        DataExchDef.Modify;

        // Exercise
        asserterror GenJnlLine.ImportBankStatement;

        // Verify
        Assert.ExpectedError(
          StrSubstNo(BalAccTypeErr, DataExchDef.FieldCaption(Type), DataExchDef.Type::"Bank Statement Import",
            DataExchDef.Code, DataExchDef.Type::"Payment Export"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGenJnlBatchFormatBalAccTypeBankErr()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        Initialize;

        // Setup
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");

        // Exercise
        asserterror GenJournalBatch.Validate("Bank Statement Import Format", CreateRandomBankExportImportSetup);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(BankStmtImpFormatBalAccErr, GenJournalBatch.FieldCaption("Bank Statement Import Format"),
            GenJournalBatch.FieldCaption("Bal. Account Type"), GenJournalBatch."Bal. Account Type",
            GenJournalBatch.TableCaption, GenJournalBatch.FieldCaption("Journal Template Name"),
            GenJournalBatch."Journal Template Name", GenJournalBatch.FieldCaption(Name), GenJournalBatch.Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGenJnlBatchFormatBalAccTypeCustErr()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        Initialize;

        // Setup
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::Customer);

        // Exercise
        asserterror GenJournalBatch.Validate("Bank Statement Import Format", CreateRandomBankExportImportSetup);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(BankStmtImpFormatBalAccErr, GenJournalBatch.FieldCaption("Bank Statement Import Format"),
            GenJournalBatch.FieldCaption("Bal. Account Type"), GenJournalBatch."Bal. Account Type"::"Bank Account",
            GenJournalBatch.TableCaption, GenJournalBatch.FieldCaption("Journal Template Name"),
            GenJournalBatch."Journal Template Name", GenJournalBatch.FieldCaption(Name), GenJournalBatch.Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGenJnlBatchFormatBalAccTypeGLAcc()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        Initialize;

        // Setup
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");

        // Exercise
        GenJournalBatch.Validate("Bank Statement Import Format", CreateRandomBankExportImportSetup);
        GenJournalBatch.Modify;

        // Verify
        GenJournalBatch.TestField("Bank Statement Import Format");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGenJnlBatchFormatBalAccTypeCustNoErr()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        Initialize;

        // Setup
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::Customer);

        // Exercise
        asserterror GenJournalBatch.Validate("Bank Statement Import Format", CreateRandomBankExportImportSetup);
        GenJournalBatch.Validate("Bank Statement Import Format", '');
        GenJournalBatch.Insert; // the error rolled back the previous insert so can do insert again.

        // Verify
        GenJournalBatch.TestField("Bank Statement Import Format", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateNewMappingWithDefaultMultiplierValue()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        TempDataExchMapping: Record "Data Exch. Mapping" temporary;
        TempDataExchFieldMapping: Record "Data Exch. Field Mapping" temporary;
    begin
        Initialize;

        // Pre-Setup
        DataExchDef.InsertRecForExport(LibraryUtility.GenerateGUID, '', DataExchDef.Type::"Bank Statement Import",
          XMLPORT::"Data Exch. Import - CSV", DataExchDef."File Type"::"Variable Text");
        DataExchLineDef.InsertRec(DataExchDef.Code, LibraryUtility.GenerateGUID, '', 0);
        DataExchColumnDef.InsertRec(DataExchDef.Code, DataExchLineDef.Code, 1, '',
          true, DataExchColumnDef."Data Type"::Decimal, '', '', '');

        // Setup
        TempDataExchMapping.InsertRecForExport(DataExchDef.Code, DataExchLineDef.Code,
          DATABASE::"Gen. Journal Line", '', CODEUNIT::"Payment Export Mgt");

        // Exercise
        with TempDataExchFieldMapping do begin
            "Data Exch. Def Code" := DataExchDef.Code;
            "Data Exch. Line Def Code" := DataExchLineDef.Code;
            "Table ID" := TempDataExchMapping."Table ID";
            "Column No." := DataExchColumnDef."Column No.";
            "Field ID" := 1;
            Optional := false;
            Insert(true);
        end;

        // Verify
        TempDataExchFieldMapping.TestField(Multiplier, 1);

        // Cleanup
        DataExchDef.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportBankAccRecWithNegativeSignAfterAmount()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        DataExchDef: Record "Data Exch. Def";
        DataExch: Record "Data Exch.";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobANSI: Codeunit "Temp Blob";
        OutStream: OutStream;
        AnyDate: array[3] of Date;
        AnyDecimal: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Bank Acc. Reconciliation] [Fixed File Import] [Data Line Tag] [Negative-Sign Identifier]
        // [SCENARIO 375088,375087] Fixed File should may be imported with empty Data Line Tag and Negative Sign before the Amount
        Initialize;

        // [GIVEN] Posting Exchange Definition Setup
        DefineDataExchDef(DataExchDef);
        // [GIVEN] 3 Lines imput file: sign (1 symbol), amount (1 symbol)
        GenerateAnyInputDataFixSize(3, AnyDate, AnyDecimal);
        TempBlobOEM.CreateOutStream(OutStream);
        // [GIVEN] Line 1 (1st negative amount): -1
        WriteLine(OutStream, StrSubstNo('%1%2', '-', Format(AnyDecimal[1])));
        AnyDecimal[1] := -AnyDecimal[1];
        // [GIVEN] Line 2 (positive amount): +2
        WriteLine(OutStream, StrSubstNo('%1%2', '+', Format(AnyDecimal[2])));
        // [GIVEN] Line 3 (2nd negative amount): -3
        WriteLine(OutStream, StrSubstNo('%1%2', '-', Format(AnyDecimal[3])));
        AnyDecimal[3] := -AnyDecimal[3];
        ConvertOEMToANSI(TempBlobOEM, TempBlobANSI);
        AddTempBlobToArray(TempBlobANSI);

        // [WHEN] Import Bank Acc. Reconciliation
        CreateBankAccRecLineTemplateWithFilter(BankAccReconciliation, BankAccReconciliationLine, DataExchDef.Code);
        BankAccReconciliationLine.Delete(true);
        BankAccReconciliation.ImportBankStatement;

        // [THEN] Date and Amount are imported correctly
        DataExch.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExch.FindFirst;
        BankAccReconciliationLine.FindSet;
        for i := 1 to 3 do begin
            Assert.AreEqual(AnyDecimal[i], BankAccReconciliationLine."Statement Amount", 'Amount did not Match');
            Assert.AreEqual(i, BankAccReconciliationLine."Data Exch. Line No.", 'Line no. did not match.');
            Assert.AreEqual(DataExch."Entry No.", BankAccReconciliationLine."Data Exch. Entry No.", 'Wrong post. entry no.');
            BankAccReconciliationLine.Next;
        end;

        // [THEN] All lines are imported
        Assert.AreEqual(3, BankAccReconciliationLine.Count, WrongNoOfLinesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportBankAccRecWithEmptyDataTag()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        DataExchDef: Record "Data Exch. Def";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobANSI: Codeunit "Temp Blob";
        OutStream: OutStream;
        AnyDate: array[2] of Date;
        AnyDecimal: array[2] of Decimal;
    begin
        // [FEATURE] [Bank Acc. Reconciliation] [Fixed File Import] [Data Line Tag]
        // [SCENARIO 137139] Fixed File can be imported if "Posting Exchange Definition" has empty "Data Line Tag" and a number of header lines

        Initialize;

        // [GIVEN] Data Exchange Definition Setup with 1 header line and empty data tag
        DefineDataExchDef(DataExchDef);
        DataExchDef.Validate("Header Lines", 1);
        DataExchDef.Modify;

        // [GIVEN] 3 Lines input file:
        GenerateAnyInputDataFixSize(ArrayLen(AnyDecimal), AnyDate, AnyDecimal);
        TempBlobOEM.CreateOutStream(OutStream);

        // [GIVEN] Line 1 (header)
        WriteLine(OutStream, LibraryUtility.GenerateGUID);
        // [GIVEN] Line 2 (positive amount): +1
        WriteLine(OutStream, StrSubstNo('%1%2', '+', Format(AnyDecimal[1])));
        // [GIVEN] Line 3 (negative amount): -2
        WriteLine(OutStream, StrSubstNo('%1%2', '-', Format(AnyDecimal[2])));
        AnyDecimal[2] := -AnyDecimal[2];
        ConvertOEMToANSI(TempBlobOEM, TempBlobANSI);
        AddTempBlobToArray(TempBlobANSI);

        // [WHEN] Import Bank Acc. Reconciliation
        CreateBankAccRecLineTemplateWithFilter(BankAccReconciliation, BankAccReconciliationLine, DataExchDef.Code);
        BankAccReconciliationLine.Delete(true);
        BankAccReconciliation.ImportBankStatement;

        // [THEN] Dates and Amounts are imported correctly
        VerifyImportedBankData(BankAccReconciliationLine, DataExchDef.Code, AnyDecimal, ArrayLen(AnyDecimal));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NegateNoAmountsUT()
    var
        GLEntry: Record "G/L Entry";
        TempInteger: Record "Integer" temporary;
        ProcessDataExch: Codeunit "Process Data Exch.";
        RecRef: RecordRef;
    begin
        // [SCENARIO 140216] If NegateAmounts function is called with empty list of fields to modify, no error should occur
        InsertRecord(GLEntry);
        RecRef.GetTable(GLEntry);

        ProcessDataExch.NegateAmounts(RecRef, TempInteger);

        RecRef.Modify;
        VerifyNegation(GLEntry, 100, 1000);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NegateOneAmountUT()
    var
        GLEntry: Record "G/L Entry";
        TempInteger: Record "Integer" temporary;
        ProcessDataExch: Codeunit "Process Data Exch.";
        RecRef: RecordRef;
    begin
        // [SCENARIO 140216] If NegateAmounts function is called with one field ID in list, this fields sign should be changed
        InsertRecord(GLEntry);
        RecRef.GetTable(GLEntry);

        TempInteger.Number := GLEntry.FieldNo(Amount);
        TempInteger.Insert;

        ProcessDataExch.NegateAmounts(RecRef, TempInteger);

        RecRef.Modify;
        VerifyNegation(GLEntry, -100, 1000);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NegateTwoAmountsUT()
    var
        GLEntry: Record "G/L Entry";
        TempInteger: Record "Integer" temporary;
        ProcessDataExch: Codeunit "Process Data Exch.";
        RecRef: RecordRef;
    begin
        // [SCENARIO 140216] If NegateAmounts function is called with several field IDs in list, all these fields' signs should be changed
        InsertRecord(GLEntry);
        RecRef.GetTable(GLEntry);

        TempInteger.Number := GLEntry.FieldNo(Amount);
        TempInteger.Insert;
        TempInteger.Number := GLEntry.FieldNo(Quantity);
        TempInteger.Insert;

        ProcessDataExch.NegateAmounts(RecRef, TempInteger);

        RecRef.Modify;
        VerifyNegation(GLEntry, -100, -1000);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    local procedure CreateImportBlob(var TempBlobANSI: Codeunit "Temp Blob")
    var
        TempBlobOEM: Codeunit "Temp Blob";
        OutStream: OutStream;
        AnyLineCount: Integer;
        AnyDate: array[1000] of Date;
        AnyText: array[1000] of Text;
        AnyDecimal: array[1000] of Decimal;
        i: Integer;
    begin
        GenerateAnyInputData(AnyLineCount, AnyDate, AnyText, AnyDecimal);
        TempBlobOEM.CreateOutStream(OutStream);
        for i := 1 to AnyLineCount do
            WriteLine(
              OutStream, StrSubstNo('%1,%2,%3', Format(AnyDate[i], 6, '<Day,2><Month,2><Year,2>'), AnyText[i], Format(AnyDecimal[i], 20, 9)));
        ConvertOEMToANSI(TempBlobOEM, TempBlobANSI);
        AddTempBlobToArray(TempBlobANSI);
    end;

    local procedure CreateRecTemplate(var GenJnlLineTemplate: Record "Gen. Journal Line"; DataExchDefCode: Code[20])
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
    begin
        CreateBankAccWithBankStatementSetup(BankAccount, DataExchDefCode);

        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        GenJnlBatch."Bal. Account Type" := GenJnlBatch."Bal. Account Type"::"Bank Account";
        GenJnlBatch."Bal. Account No." := BankAccount."No.";
        GenJnlBatch.Modify;

        LibraryERM.CreateGeneralJnlLine(GenJnlLineTemplate,
          GenJnlTemplate.Name, GenJnlBatch.Name, GenJnlLineTemplate."Document Type"::Payment,
          GenJnlLineTemplate."Account Type"::"Bank Account", '', 0);
    end;

    local procedure CreateRecTemplateNoBank(var GenJnlLineTemplate: Record "Gen. Journal Line"; DataExchDefCode: Code[20])
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
    begin
        CreateBankAccWithBankStatementSetup(BankAccount, DataExchDefCode);

        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);

        GenJnlBatch."Bal. Account Type" := GenJnlBatch."Bal. Account Type"::"G/L Account";
        GenJnlBatch."Bal. Account No." := '';
        GenJnlBatch."Bank Statement Import Format" := BankAccount."Bank Statement Import Format";
        GenJnlBatch.Modify;

        LibraryERM.CreateGeneralJnlLine(GenJnlLineTemplate,
          GenJnlTemplate.Name, GenJnlBatch.Name, GenJnlLineTemplate."Document Type"::Payment,
          GenJnlLineTemplate."Account Type"::"G/L Account", '', 0);
    end;

    local procedure AddFiltersToRecTemplate(var GenJnlLineTemplate: Record "Gen. Journal Line")
    begin
        GenJnlLineTemplate.SetRange("Journal Template Name", GenJnlLineTemplate."Journal Template Name");
        GenJnlLineTemplate.SetRange("Journal Batch Name", GenJnlLineTemplate."Journal Batch Name");
    end;

    local procedure CreateBankAccRecLineTemplateWithFilter(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; DataExchDefCode: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        CreateBankAccWithBankStatementSetup(BankAccount, DataExchDefCode);

        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.",
          BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.FilterBankRecLines(BankAccReconciliation);
    end;

    local procedure WriteLine(OutStream: OutStream; Text: Text)
    begin
        OutStream.WriteText(Text);
        OutStream.WriteText;
    end;

    local procedure GenerateAnyInputData(var Size: Integer; var DateArray: array[1000] of Date; var TextArray: array[1000] of Text; var DecimalArray: array[1000] of Decimal)
    var
        i: Integer;
    begin
        Size := LibraryRandom.RandInt(100);
        for i := 1 to Size do begin
            DateArray[i] := LibraryUtility.GenerateRandomDate(WorkDate - 1000, WorkDate + 1000);
            TextArray[i] := AnyASCIITextExceptCommaAndQuotes(30);
            DecimalArray[i] := LibraryRandom.RandDecInRange(-10000000, 10000000, 2);
        end
    end;

    local procedure GenerateAnyInputDataFixSize(Size: Integer; var DateArray: array[3] of Date; var DecimalArray: array[3] of Decimal)
    var
        i: Integer;
    begin
        for i := 1 to Size do begin
            DateArray[i] := LibraryUtility.GenerateRandomDate(WorkDate - 1000, WorkDate + 1000);
            DecimalArray[i] := LibraryRandom.RandIntInRange(1, 9);
        end
    end;

    local procedure AnyASCIITextExceptCommaAndQuotes(MaxSize: Integer) AnyText: Text
    var
        Size: Integer;
        Char: Char;
        i: Integer;
    begin
        Size := LibraryRandom.RandInt(MaxSize);
        for i := 1 to Size do begin
            Char := LibraryRandom.RandInt(126 - 32) + 32;
            if Char in ['"', ','] then
                Char += 1;
            AnyText := AnyText + Format(Char);
        end
    end;

    local procedure SetupFileDefinition(var DataExchDef: Record "Data Exch. Def"; var DataExchLineDef: Record "Data Exch. Line Def")
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        DataExchDef.InsertRec(
          LibraryUtility.GenerateRandomCode(1, DATABASE::"Data Exch. Def"), '', DataExchDef.Type::"Bank Statement Import",
          XMLPORT::"Data Exch. Import - CSV", 0, '', '');
        DataExchDef."Ext. Data Handling Codeunit" := CODEUNIT::"ERM PE Source Test Mock";
        DataExchDef."File Type" := DataExchDef."File Type"::"Variable Text";
        DataExchDef.Modify;

        CreateBankExportImportSetup(DataExchDef);
        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 0);
        DataExchColumnDef.InsertRec(DataExchDef.Code, DataExchLineDef.Code, 1, '1',
          true, DataExchColumnDef."Data Type"::Date, 'ddMMyy', 'da-DK', '');
        DataExchColumnDef.InsertRec(DataExchDef.Code, DataExchLineDef.Code, 2, '2',
          true, DataExchColumnDef."Data Type"::Text, '', '', '');
        DataExchColumnDef.InsertRec(DataExchDef.Code, DataExchLineDef.Code, 3, '3',
          true, DataExchColumnDef."Data Type"::Decimal, '', 'en-US', '');
    end;

    local procedure SetupFileMapping(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; TableId: Integer; CodeunitId: Integer; EntryNoFieldId: Integer; LineNoFieldId: Integer; FieldId1: Integer; FieldId2: Integer; FieldId3: Integer; Multiplier: Decimal)
    var
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExchMapping.InsertRec(DataExchDefCode, DataExchLineDefCode, TableId, '', CodeunitId, EntryNoFieldId, LineNoFieldId);
        DataExchFieldMapping.InsertRec(DataExchDefCode, DataExchLineDefCode, TableId, 1, FieldId1, false, 1);
        DataExchFieldMapping.InsertRec(DataExchDefCode, DataExchLineDefCode, TableId, 2, FieldId2, false, 1);
        DataExchFieldMapping.InsertRec(DataExchDefCode, DataExchLineDefCode, TableId, 3, FieldId3, false, Multiplier);
    end;

    local procedure ConvertOEMToANSI(TempBlobSource: Codeunit "Temp Blob"; var TempBlobDestination: Codeunit "Temp Blob")
    var
        Encoding: DotNet Encoding;
        Writer: DotNet StreamWriter;
        InStream: InStream;
        OutStream: OutStream;
        EncodedText: Text;
    begin
        TempBlobSource.CreateInStream(InStream);
        TempBlobDestination.CreateOutStream(OutStream);

        Writer := Writer.StreamWriter(OutStream, Encoding.Default);

        while 0 <> InStream.ReadText(EncodedText) do
            Writer.WriteLine(EncodedText);

        Writer.Close;
    end;

    local procedure VerifyImportedGenJnlLines(var GenJournalLine: Record "Gen. Journal Line"; var LineNo: Integer; var DocNo: Code[20]; LineCount: Integer)
    begin
        Assert.AreEqual(LineCount, GenJournalLine.Count, 'Wrong no of lines for the given import.');
        GenJournalLine.FindSet;
        repeat
            Assert.AreEqual(LineNo, GenJournalLine."Line No.", 'Line No not incremented as expected');
            Assert.AreEqual(DocNo, GenJournalLine."Document No.", 'Document No not incremented as expected');
            LineNo += 10000;
            DocNo := IncStr(DocNo);
        until GenJournalLine.Next = 0;
    end;

    local procedure VerifyImportedGenJnlLinesWithDataExchNo(var GenJournalLine: Record "Gen. Journal Line"; var LineNo: Integer; var DocNo: Code[20]; DataExchNo: Integer; LineCount: Integer)
    begin
        GenJournalLine.SetRange("Data Exch. Entry No.", DataExchNo);
        VerifyImportedGenJnlLines(GenJournalLine, LineNo, DocNo, LineCount);
    end;

    local procedure VerifyBankStatementDetailsPage(var DataExchField: Record "Data Exch. Field"; BankStatementLineDetails: TestPage "Bank Statement Line Details"; DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20])
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDefCode);
        repeat
            DataExchColumnDef.SetRange(Name, BankStatementLineDetails.Name.Value);
            DataExchColumnDef.FindFirst;
            DataExchField.SetRange("Column No.", DataExchColumnDef."Column No.");
            DataExchField.FindFirst;
            Assert.AreEqual(DataExchField.Value, Format(BankStatementLineDetails.Value), 'Wrong shown value.');
        until not BankStatementLineDetails.Next;
    end;

    local procedure VerifyEmptyBankStatementDetailsPage(BankStatementLineDetails: TestPage "Bank Statement Line Details")
    begin
        BankStatementLineDetails.First;
        Assert.AreEqual('', Format(BankStatementLineDetails.Name), 'There should be no data on the page.');
        Assert.AreEqual('', Format(BankStatementLineDetails.Value), 'There should be no data on the page.');
        Assert.IsFalse(BankStatementLineDetails.Next, 'There should be no data on the page.');
    end;

    local procedure VerifyImportedBankData(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; DataExchDefCode: Code[20]; ExpectedDecimal: array[3] of Decimal; LineCount: Integer)
    var
        DataExch: Record "Data Exch.";
        i: Integer;
    begin
        DataExch.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExch.FindFirst;

        with BankAccReconciliationLine do begin
            Assert.AreEqual(LineCount, Count, WrongNoOfLinesErr);
            FindSet;
            repeat
                i += 1;
                TestField("Statement Amount", ExpectedDecimal[i]);
                TestField("Data Exch. Line No.", i);
                TestField("Data Exch. Entry No.", DataExch."Entry No.");
            until Next = 0;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GenJnlLineTemplateListPageHandler(var GenJournalTemplateList: TestPage "General Journal Template List")
    var
        TemplateName: Variant;
    begin
        LibraryVariableStorage.Dequeue(TemplateName);
        GenJournalTemplateList.FILTER.SetFilter(Name, TemplateName);
        GenJournalTemplateList.OK.Invoke;
    end;

    local procedure CreateGenJnlBatchWithBalBankAcc(var GenJnlBatch: Record "Gen. Journal Batch"; DataExchDefCode: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        CreateBankAccWithImportFormat(BankAccount, DataExchDefCode);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, LibraryERM.SelectGenJnlTemplate);
        GenJnlBatch.Validate("Bal. Account Type", GenJnlBatch."Bal. Account Type"::"Bank Account");
        GenJnlBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJnlBatch.Modify(true);
    end;

    local procedure CreateBankAccWithImportFormat(var BankAccount: Record "Bank Account"; DataExchDefCode: Code[20])
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Bank Statement Import Format", DataExchDefCode);
        BankAccount.Modify(true);
    end;

    local procedure CreateBankExportImportSetup(DataExchDef: Record "Data Exch. Def")
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.Code := DataExchDef.Code;
        BankExportImportSetup."Processing Codeunit ID" := CODEUNIT::"Payment Export Mgt";
        BankExportImportSetup."Data Exch. Def. Code" := DataExchDef.Code;
        case DataExchDef.Type of
            DataExchDef.Type::"Bank Statement Import":
                BankExportImportSetup.Direction := BankExportImportSetup.Direction::Import;
            DataExchDef.Type::"Payment Export":
                BankExportImportSetup.Direction := BankExportImportSetup.Direction::Export;
        end;
        BankExportImportSetup.Insert;
    end;

    local procedure CreateRandomBankExportImportSetup(): Code[20]
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.Code :=
          LibraryUtility.GenerateRandomCode(BankExportImportSetup.FieldNo(Code), DATABASE::"Bank Export/Import Setup");
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::Import;
        BankExportImportSetup.Insert;
        exit(BankExportImportSetup.Code);
    end;

    local procedure CreateBankAccWithBankStatementSetup(var BankAccount: Record "Bank Account"; DataExchDefCode: Code[20])
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.Init;
        BankExportImportSetup.Code := CreateRandomBankExportImportSetup;
        if DataExchDefCode <> '' then
            BankExportImportSetup."Data Exch. Def. Code" := DataExchDefCode;
        BankExportImportSetup.Modify;

        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Last Statement No.",
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Last Statement No."), DATABASE::"Bank Account"));
        BankAccount."Bank Statement Import Format" := BankExportImportSetup.Code;
        BankAccount.Modify(true);
    end;

    local procedure SetupSourceMock(DataExchDefCode: Code[20]; TempBlob: Codeunit "Temp Blob")
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        AddTempBlobToArray(TempBlob);

        DataExchDef.Get(DataExchDefCode);
        DataExchDef."Ext. Data Handling Codeunit" := CODEUNIT::"ERM PE Source Test Mock";
        DataExchDef.Modify;
    end;

    local procedure DefineDataExchDef(var DataExchDef: Record "Data Exch. Def")
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        DataExchDef.InsertRec(
          LibraryUtility.GenerateRandomCode(1, DATABASE::"Data Exch. Def"), '', DataExchDef.Type::"Bank Statement Import",
          XMLPORT::"Data Exch. Import - CSV", 0, '', '');
        DataExchDef."Ext. Data Handling Codeunit" := CODEUNIT::"ERM PE Source Test Mock";
        DataExchDef."File Type" := DataExchDef."File Type"::"Fixed Text";
        DataExchDef."Reading/Writing Codeunit" := CODEUNIT::"Fixed File Import";
        DataExchDef.Modify;

        CreateBankExportImportSetup(DataExchDef);
        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 0);
        DataExchColumnDef.InsertRecForExport(
          DataExchDef.Code, DataExchLineDef.Code, 1, '1', DataExchColumnDef."Data Type"::Text, 'en-US', 1, '');
        DataExchColumnDef."Negative-Sign Identifier" := '-';
        DataExchColumnDef.Modify;
        DataExchColumnDef.InsertRecForExport(
          DataExchDef.Code, DataExchLineDef.Code, 2, '2', DataExchColumnDef."Data Type"::Text, 'en-US', 1, '');

        DataExchLineDef."Data Line Tag" := '';
        DataExchLineDef.Modify;

        DataExchMapping.InsertRec(
          DataExchDef.Code, DataExchLineDef.Code, DATABASE::"Bank Acc. Reconciliation Line", '',
          CODEUNIT::"Process Bank Acc. Rec Lines", BankAccReconciliationLine.FieldNo("Data Exch. Entry No."),
          BankAccReconciliationLine.FieldNo("Data Exch. Line No."));
        DataExchFieldMapping.InsertRec(
          DataExchDef.Code, DataExchLineDef.Code, DATABASE::"Bank Acc. Reconciliation Line",
          1, BankAccReconciliationLine.FieldNo("Statement Amount"), false, 1);
        DataExchFieldMapping.InsertRec(
          DataExchDef.Code, DataExchLineDef.Code, DATABASE::"Bank Acc. Reconciliation Line",
          2, BankAccReconciliationLine.FieldNo("Statement Amount"), false, 1);
    end;

    local procedure InsertRecord(var GLEntry: Record "G/L Entry")
    begin
        GLEntry.Init;
        GLEntry."Entry No." := 0;
        GLEntry.Amount := 100;
        GLEntry.Quantity := 1000;
        GLEntry.Insert;
    end;

    local procedure VerifyNegation(GLEntry: Record "G/L Entry"; Value1: Decimal; Value2: Decimal)
    begin
        GLEntry.Find;
        GLEntry.TestField(Amount, Value1);
        GLEntry.TestField(Quantity, Value2);
    end;

    local procedure AddTempBlobToArray(var TempBlob: Codeunit "Temp Blob")
    var
        ErmPeSourceTestMock: Codeunit "ERM PE Source Test Mock";
        TempBlobList: Codeunit "Temp Blob List";
    begin
        ErmPeSourceTestMock.GetTempBlobList(TempBlobList);
        TempBlobList.Add(TempBlob);
        ErmPeSourceTestMock.SetTempBlobList(TempBlobList);
    end;
}

