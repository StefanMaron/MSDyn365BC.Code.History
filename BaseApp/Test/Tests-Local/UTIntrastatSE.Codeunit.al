#if not CLEAN22
codeunit 144022 "UT Intrastat SE"
{
    // [FEATURE] [Intrastat] [UT]
    // 
    // 1 - 12. Purpose of the test to validate OnAfterGetRecord - Intrastat Jnl. Line trigger of Report ID - 593 "Intrastat - Make Disk Tax Auth".
    // 
    // WI - 350887
    // ------------------------------------------------------------------------------------------------------------------------------------------------------
    // Test Case Name                                                                                                                         TFS ID
    // ------------------------------------------------------------------------------------------------------------------------------------------------------
    // OnAfterGetRecordMakeDisketteBlankCountryCodeError,OnAfterGetRecordMakeDisketteBlankTransacTypeError
    // OnAfterGetRecordMakeDisketteZeroNetWeightError,OnAfterGetRecordMakeDisketteZeroQuantityError
    // OnAfterGetRecordMakeDisketteZeroAmountError,OnAfterGetRecordMakeDisketteBlankTrariffNoError                                          153912
    // OnAfterGetRecordMakeDisketteBlankTypeFilterError,OnAfterGetRecordMakeDisketteMultipleTypeFilterError                                 153914
    // OnAfterGetRecordMakeDisketteTotalWeightLengthError,OnAfterGetRecordMakeDisketteQuantityLengthError
    // OnAfterGetRecordMakeDisketteStasticalValueLengthError                                                                                153915
    // OnAfterGetRecordMakeDisketteRoundingNetWeightError                                                                                   230464

    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        TestFieldErr: Label 'TestField';
        DialogErr: Label 'Dialog';
        TypeFilterTxt: Label '%1|%2';
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";

    [Test]
    [HandlerFunctions('CreateFileMessageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordMakeDisketteBlankCountryCodeError()
    var
        IntrastatLineValues: Decimal;
    begin
        // Purpose of the test to validate  OnAfterGetRecord - Intrastat Jnl. Line trigger of Report ID - 593 "Intrastat - Make Disk Tax Auth".
        // Actual error Country/Region Code must have a value in Intrastat Jnl. Line: Journal Template Name=XXXXX, Journal Batch Name=XXXXX, Line No.=XXXX. It cannot be zero or empty.
        Initialize();
        IntrastatLineValues := LibraryRandom.RandDec(100, 2);  // IntrastatLineValues used for Quantity, Net Weight and Amount.
        MakeDisketteWithEmptyFieldsOnIntrastatJournal(
          '', GetTransactionType, IntrastatLineValues, IntrastatLineValues, IntrastatLineValues, GetTariffNo);  // Using blank for Country Code.
    end;

    [Test]
    [HandlerFunctions('CreateFileMessageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordMakeDisketteBlankTransacTypeError()
    var
        IntrastatLineValues: Decimal;
    begin
        // Purpose of the test to validate  OnAfterGetRecord - Intrastat Jnl. Line trigger of Report ID - 593 "Intrastat - Make Disk Tax Auth".
        // Actual error Transaction Type must have a value in Intrastat Jnl. Line: Journal Template Name=XXXXX, Journal Batch Name=XXXXX, Line No.=XXXX. It cannot be zero or empty.
        Initialize();
        IntrastatLineValues := LibraryRandom.RandDec(100, 2);  // IntrastatLineValues used for Quantity, Net Weight and Amount.
        MakeDisketteWithEmptyFieldsOnIntrastatJournal(
          GetCountryCode, '', IntrastatLineValues, IntrastatLineValues, IntrastatLineValues, GetTariffNo);  // Using blank for Transaction Type.
    end;

    [Test]
    [HandlerFunctions('CreateFileMessageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordMakeDisketteZeroQuantityError()
    var
        IntrastatLineValues: Decimal;
    begin
        // Purpose of the test to validate  OnAfterGetRecord - Intrastat Jnl. Line trigger of Report ID - 593 "Intrastat - Make Disk Tax Auth".
        // Actual error Total Weight must have a value in Intrastat Jnl. Line: Journal Template Name=XXXXX, Journal Batch Name=XXXXX, Line No.=XXXX. It cannot be zero or empty.
        Initialize();
        IntrastatLineValues := LibraryRandom.RandDec(100, 2);  // IntrastatLineValues used for Net Weight and Amount.
        MakeDisketteWithEmptyFieldsOnIntrastatJournal(
          GetCountryCode, GetTransactionType, IntrastatLineValues, 0, IntrastatLineValues, GetTariffNo);  // Using 0 for Quantity.
    end;

    [Test]
    [HandlerFunctions('IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordMakeDisketteZeroAmountError()
    var
        IntrastatLineValues: Decimal;
    begin
        // Purpose of the test to validate  OnAfterGetRecord - Intrastat Jnl. Line trigger of Report ID - 593 "Intrastat - Make Disk Tax Auth".
        // Actual error Stastical Value must have a value in Intrastat Jnl. Line: Journal Template Name=XXXXX, Journal Batch Name=XXXXX, Line No.=XXXX. It cannot be zero or empty.
        Initialize();
        IntrastatLineValues := LibraryRandom.RandDec(100, 2);  // IntrastatLineValues used for Net Weight and Quantity.
        MakeDisketteWithEmptyFieldsOnIntrastatJournalError
        (
          GetCountryCode, GetTransactionType, IntrastatLineValues, IntrastatLineValues, 0, GetTariffNo);  // Using 0 for Amount.
    end;

    [Test]
    [HandlerFunctions('CreateFileMessageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordMakeDisketteBlankTrariffNoError()
    var
        IntrastatLineValues: Decimal;
    begin
        // Purpose of the test to validate  OnAfterGetRecord - Intrastat Jnl. Line trigger of Report ID - 593 "Intrastat - Make Disk Tax Auth".
        // Actual error Tariff No. must have a value in Intrastat Jnl. Line: Journal Template Name=XXXXX, Journal Batch Name=XXXXX, Line No.=XXXX. It cannot be zero or empty.
        Initialize();
        IntrastatLineValues := LibraryRandom.RandDec(100, 2);  // IntrastatLineValues used for Quantity, Net Weight and Amount.
        MakeDisketteWithEmptyFieldsOnIntrastatJournal(
          GetCountryCode, GetTransactionType, IntrastatLineValues, IntrastatLineValues, IntrastatLineValues, '');  // Using blank for Tariff No.
    end;

    local procedure MakeDisketteWithEmptyFieldsOnIntrastatJournal(CountryRegionCode: Code[10]; TransactionType: Code[10]; NetWeight: Decimal; Quantity: Decimal; Amount: Decimal; TariffNo: Code[20])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        // Setup: Create Intrastat Journal Line.
        IntrastatJournal.OpenEdit;
        CreateIntrastatJournalLine(IntrastatJnlLine, CountryRegionCode, TransactionType, NetWeight, Quantity, Amount, TariffNo);
        LibraryVariableStorage.Enqueue(Format(IntrastatJnlLine.Type));  // Enqueue values for IntrastatMakeDiskTaxAuthRequestPageHandler.
        Commit();  // Commit is explicitly called in Codeunit - 350 IntraJnlManagement for Template Selection.

        // Exercise.
        MakeDisketteFromIntrastatJournal(IntrastatJournal, IntrastatJnlLine."Journal Batch Name");

        // Verify: Verify errors with different empty fields on Intrastat Journal after run Make Diskette batch job.
        // Handler will verify message
    end;

    local procedure MakeDisketteWithEmptyFieldsOnIntrastatJournalError(CountryRegionCode: Code[10]; TransactionType: Code[10]; NetWeight: Decimal; Quantity: Decimal; Amount: Decimal; TariffNo: Code[20])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        // Setup: Create Intrastat Journal Line.
        IntrastatJournal.OpenEdit;
        CreateIntrastatJournalLine(IntrastatJnlLine, CountryRegionCode, TransactionType, NetWeight, Quantity, Amount, TariffNo);
        LibraryVariableStorage.Enqueue(Format(IntrastatJnlLine.Type));  // Enqueue values for IntrastatMakeDiskTaxAuthRequestPageHandler.
        Commit();  // Commit is explicitly called in Codeunit - 350 IntraJnlManagement for Template Selection.

        // Exercise.
        asserterror MakeDisketteFromIntrastatJournal(IntrastatJournal, IntrastatJnlLine."Journal Batch Name");

        // Verify: Verify errors with different empty fields on Intrastat Journal after run Make Diskette batch job.
        Assert.ExpectedErrorCode(TestFieldErr);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CreateFileMessageHandler(Message: Text)
    begin
        Assert.AreEqual('One or more errors were found. You must resolve all the errors before you can proceed.', Message, '');
    end;

    [Test]
    [HandlerFunctions('IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordMakeDisketteBlankTypeFilterError()
    var
        IntrastatLineValues: Decimal;
    begin
        // Purpose of the test to validate  OnAfterGetRecord - Intrastat Jnl. Line trigger of Report ID - 593 "Intrastat - Make Disk Tax Auth".
        // Actual error Please enter either Receipt or Shipment for the Type field.
        Initialize();
        IntrastatLineValues := LibraryRandom.RandDec(100, 2);  // IntrastatLineValues used for Quantity, Net Weight and Amount.
        MakeDisketteWithInvalidValues(IntrastatLineValues, IntrastatLineValues, IntrastatLineValues, '');  // Using blank for Type.
    end;

    [Test]
    [HandlerFunctions('IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordMakeDisketteMultipleTypeFilterError()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatLineValues: Decimal;
    begin
        // Purpose of the test to validate  OnAfterGetRecord - Intrastat Jnl. Line trigger of Report ID - 593 "Intrastat - Make Disk Tax Auth".
        // Actual error Please enter either Receipt or Shipment for the Type field.
        Initialize();
        IntrastatLineValues := LibraryRandom.RandDec(100, 2);  // IntrastatLineValues used for Quantity, Net Weight and Amount.
        MakeDisketteWithInvalidValues(
          IntrastatLineValues, IntrastatLineValues, IntrastatLineValues,
          StrSubstNo(TypeFilterTxt, IntrastatJnlLine.Type::Receipt, IntrastatJnlLine.Type::Shipment));
    end;

    [Test]
    [HandlerFunctions('IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordMakeDisketteTotalWeightLengthError()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatLineValues: Decimal;
    begin
        // Purpose of the test to validate  OnAfterGetRecord - Intrastat Jnl. Line trigger of Report ID - 593 "Intrastat - Make Disk Tax Auth".
        // Actual error Total Weight exceeds the maximum value to be imported into IDEP.
        Initialize();
        IntrastatLineValues := LibraryRandom.RandDec(100, 2);  // IntrastatLineValues used for Quantity and Amount.
        MakeDisketteWithInvalidValues(
          Power(LibraryRandom.RandDecInRange(15, 20, 4), 10), IntrastatLineValues, IntrastatLineValues,
          Format(IntrastatJnlLine.Type::Receipt));  // Using Random with Power to generate large value.
    end;

    [Test]
    [HandlerFunctions('IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordMakeDisketteQuantityLengthError()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatLineValues: Decimal;
    begin
        // Purpose of the test to validate  OnAfterGetRecord - Intrastat Jnl. Line trigger of Report ID - 593 "Intrastat - Make Disk Tax Auth".
        // Actual error Quantity exceeds the maximum value to be imported into IDEP.
        Initialize();
        IntrastatLineValues := LibraryRandom.RandDec(100, 2);  // IntrastatLineValues used for Net Weight and Amount.
        MakeDisketteWithInvalidValues(
          IntrastatLineValues, Power(LibraryRandom.RandDecInRange(15, 20, 4), 10), IntrastatLineValues,
          Format(IntrastatJnlLine.Type::Receipt));  // Using Random with Power to generate large value.
    end;

    [Test]
    [HandlerFunctions('IntrastatMakeDiskTaxAuthRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordMakeDisketteStasticalValueLengthError()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatLineValues: Decimal;
    begin
        // Purpose of the test to validate  OnAfterGetRecord - Intrastat Jnl. Line trigger of Report ID - 593 "Intrastat - Make Disk Tax Auth".
        // Actual error Statistical Value exceeds the maximum value to be imported into IDEP.
        Initialize();
        IntrastatLineValues := LibraryRandom.RandDec(100, 2);  // IntrastatLineValues used for Quantity and Net Weight.
        MakeDisketteWithInvalidValues(
          IntrastatLineValues, IntrastatLineValues, Power(LibraryRandom.RandDecInRange(15, 20, 4), 10),
          Format(IntrastatJnlLine.Type::Receipt));  // Using Random with Power to generate large value.
    end;

    local procedure MakeDisketteWithInvalidValues(NetWeight: Decimal; Quantity: Decimal; Amount: Decimal; Type: Text)
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        // Setup: Create Intrastat Journal Line.
        IntrastatJournal.OpenEdit;
        CreateIntrastatJournalLine(
          IntrastatJnlLine, GetCountryCode, GetTransactionType, NetWeight, Quantity, Amount, GetTariffNo);
        LibraryVariableStorage.Enqueue(Type);  // Enqueue values for IntrastatMakeDiskTaxAuthRequestPageHandler.
        Commit();  // Commit is explicitly called in Codeunit - 350 IntraJnlManagement for Template Selection.

        // Exercise.
        asserterror MakeDisketteFromIntrastatJournal(IntrastatJournal, IntrastatJnlLine."Journal Batch Name");

        // Verify: Verify errors with invalid values on Intrastat Journal line after run Make Diskette batch job.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('IntrastatCheckList_RPH')]
    [Scope('OnPrem')]
    procedure TransportMethodIsNotMandatoryOnIntrastatChecklistReport()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Report] [Intrastat - Checklist]
        // [SCENARIO 378015] "Transport Method" is not mandatory on Intrastat Journal Line when run "Intrastat - Checklist" report
        Initialize();

        // [GIVEN] Intrastat journal line with "Transport Method" = '' and filled other mandatory fields
        CreateIntrastatJournalLine(
          IntrastatJnlLine, GetCountryCode, GetTransactionType, LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2), GetTariffNo);
        IntrastatJnlLine.Validate("Transport Method", '');
        IntrastatJnlLine.Modify(true);

        // [WHEN] Run "Intrastat - Checklist" report
        RunIntrastatChecklistReport(IntrastatJnlLine);

        // [THEN] No error is occurred and intrastat journal line is printed
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.MoveToRow(1);
        LibraryReportDataset.AssertCurrentRowValueEquals('IntrastatJnlLinJnlTemName', IntrastatJnlLine."Journal Template Name");
        LibraryReportDataset.AssertCurrentRowValueEquals('IntrastatJnlLinJnlBatName', IntrastatJnlLine."Journal Batch Name");
        LibraryReportDataset.AssertCurrentRowValueEquals('IntrastatJnlLineLineNo', IntrastatJnlLine."Line No.");
    end;

    local procedure Initialize()
    var
        IntrastatSetup: Record "Intrastat Setup";
    begin
        LibraryVariableStorage.Clear();
        IntrastatSetup.DeleteAll();
    end;

    local procedure CreateIntrastatBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        if not IntrastatJnlTemplate.FindFirst() then
            LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);

        IntrastatJnlBatch."Journal Template Name" := IntrastatJnlTemplate.Name;
        IntrastatJnlBatch.Name := LibraryUTUtility.GetNewCode10;
        IntrastatJnlBatch."Statistics Period" := Format(WorkDate(), 0, LibraryFiscalYear.GetStatisticsPeriod());
        IntrastatJnlBatch.Reported := false;
        IntrastatJnlBatch.Insert();
    end;

    local procedure CreateIntrastatJournalLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; CountryRegionCode: Code[10]; TransactionType: Code[10]; NetWeight: Decimal; Quantity: Decimal; Amount: Decimal; TariffNo: Code[20])
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        CreateIntrastatBatch(IntrastatJnlBatch);
        IntrastatJnlLine."Journal Template Name" := IntrastatJnlBatch."Journal Template Name";
        IntrastatJnlLine."Journal Batch Name" := IntrastatJnlBatch.Name;
        IntrastatJnlLine."Line No." := LibraryRandom.RandInt(10);
        IntrastatJnlLine.Type := IntrastatJnlLine.Type::Receipt;
        IntrastatJnlLine."Country/Region Code" := CountryRegionCode;
        IntrastatJnlLine."Transaction Type" := TransactionType;
        IntrastatJnlLine."Tariff No." := TariffNo;

        // Validate required for verified results in manual.
        IntrastatJnlLine.Validate(Quantity, Quantity);
        IntrastatJnlLine.Validate("Net Weight", NetWeight);
        IntrastatJnlLine.Validate(Amount, Amount);
        IntrastatJnlLine.Insert();
    end;

    local procedure GetCountryCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.SetFilter("Intrastat Code", '<>%1', '');
        CountryRegion.FindFirst();
        exit(CountryRegion.Code);
    end;

    local procedure GetTariffNo(): Code[20]
    var
        TariffNumber: Record "Tariff Number";
    begin
        TariffNumber.FindFirst();
        exit(TariffNumber."No.");
    end;

    local procedure GetTransactionType(): Code[10]
    var
        TransactionType: Record "Transaction Type";
    begin
        TransactionType.FindFirst();
        exit(TransactionType.Code);
    end;

    local procedure RunIntrastatChecklistReport(IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatChecklist: Report "Intrastat - Checklist";
    begin
        IntrastatJnlBatch.SetRange("Journal Template Name", IntrastatJnlLine."Journal Template Name");
        IntrastatJnlBatch.SetRange(Name, IntrastatJnlLine."Journal Batch Name");
        IntrastatChecklist.SetTableView(IntrastatJnlBatch);
        IntrastatChecklist.UseRequestPage(true);
        Commit();
        IntrastatChecklist.RunModal();
    end;

    local procedure MakeDisketteFromIntrastatJournal(IntrastatJournal: TestPage "Intrastat Journal"; CurrentJnlBatchName: Code[10])
    begin
        IntrastatJournal.CurrentJnlBatchName.SetValue(CurrentJnlBatchName);
        IntrastatJournal.CreateFile.Invoke;  // Call IntrastatMakeDiskTaxAuthRequestPageHandler.
        IntrastatJournal.Close();
    end;

    local procedure VerifyExportedTotalWeight(FileName: Text; ExpectedWeight: Decimal)
    var
        File: File;
        InStream: InStream;
        LineText: Text;
        ActualWeight: Decimal;
        i: Integer;
    begin
        File.Open(FileName);
        File.CreateInStream(InStream);
        InStream.ReadText(LineText);
        File.Close();

        for i := 1 to 4 do
            LineText := CopyStr(LineText, StrPos(LineText, ';') + 1);
        LineText := CopyStr(LineText, 1, StrPos(LineText, ';') - 1);

        Assert.IsTrue(Evaluate(ActualWeight, LineText), 'Cannot evaluate text to decimal');
        Assert.AreEqual(ExpectedWeight, ActualWeight, 'wrong total weight');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatMakeDiskTaxAuthRequestPageHandler(var IntrastatMakeDiskTaxAuth: TestRequestPage "Intrastat - Make Disk Tax Auth")
    var
        Type: Variant;
    begin
        LibraryVariableStorage.Dequeue(Type);
        IntrastatMakeDiskTaxAuth.IntrastatJnlLine.SetFilter(Type, Type);
        IntrastatMakeDiskTaxAuth.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatCheckList_RPH(var IntrastatChecklist: TestRequestPage "Intrastat - Checklist")
    begin
        IntrastatChecklist.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}
#endif