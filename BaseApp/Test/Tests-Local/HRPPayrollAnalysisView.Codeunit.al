codeunit 144207 "HRP Payroll Analysis View"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;
    Permissions = tabledata "Payroll Ledger Entry" = i;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        IncorrectValueErr: Label 'Incorrect Value of %1';
        IncorrectEntryCountErr: Label 'Incorrect count of entries';

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePayrollViewEntries()
    var
        PayrollAnalysisView: Record "Payroll Analysis View";
    begin
        // Verify Last Entry No updated with Update Payroll Analysis View
        InitPayrollAnalysisView(PayrollAnalysisView, '');

        Assert.AreNotEqual(
          0, PayrollAnalysisView."Last Entry No.",
          StrSubstNo(IncorrectValueErr, PayrollAnalysisView.FieldCaption("Last Entry No.")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdatePayrollViewEntriesForElementCode()
    var
        PayrollAnalysisView: Record "Payroll Analysis View";
        PayrollAnalysisViewEntry: Record "Payroll Analysis View Entry";
        EntryCount: Integer;
    begin
        // Check PayrollAnalysisViewEntry descreased after filtering by Payroll Element
        InitPayrollAnalysisView(PayrollAnalysisView, '');
        EntryCount := GetInitialViewEntryCount(PayrollAnalysisViewEntry, PayrollAnalysisView.Code);

        UpdateViewWithPayrollElement(PayrollAnalysisView);
        Assert.IsTrue(PayrollAnalysisViewEntry.Count < EntryCount, IncorrectEntryCountErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdatePayrollViewEntriesForEmployee()
    var
        PayrollAnalysisView: Record "Payroll Analysis View";
        PayrollAnalysisViewEntry: Record "Payroll Analysis View Entry";
        EntryCount: Integer;
    begin
        // Check PayrollAnalysisViewEntry descreased after filtering by Employee
        InitPayrollAnalysisView(PayrollAnalysisView, '');
        EntryCount := GetInitialViewEntryCount(PayrollAnalysisViewEntry, PayrollAnalysisView.Code);

        UpdateViewWithEmployee(PayrollAnalysisView);
        Assert.IsTrue(PayrollAnalysisViewEntry.Count < EntryCount, IncorrectEntryCountErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdatePayrollViewEntriesForDmiension()
    var
        PayrollAnalysisView: Record "Payroll Analysis View";
        PayrollAnalysisViewEntry: Record "Payroll Analysis View Entry";
        Dimension: Record Dimension;
        EntryCount: Integer;
    begin
        // Check PayrollAnalysisViewEntry descreased after filtering by Dimension
        InitPayrollAnalysisView(PayrollAnalysisView, '');
        EntryCount := GetInitialViewEntryCount(PayrollAnalysisViewEntry, PayrollAnalysisView.Code);

        LibraryDimension.FindDimension(Dimension);
        UpdateViewWithDimension(PayrollAnalysisView, Dimension.Code);
        Assert.IsTrue(PayrollAnalysisViewEntry.Count < EntryCount, IncorrectEntryCountErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdatePayrollViewEntriesClearForDimensionCode()
    var
        PayrollAnalysisView: Record "Payroll Analysis View";
        PayrollAnalysisViewEntry: Record "Payroll Analysis View Entry";
        DimValue: Record "Dimension Value";
    begin
        // Check that removing of "Dimension 1 Code" clears Dimension in PayrollAnalysisViewEntry
        InitPayrollAnalysisView(PayrollAnalysisView, CreatePayrolLedgerEntryWithDim);

        LibraryDimension.FindDimensionValue(DimValue, PayrollAnalysisView."Dimension 1 Code");
        PayrollAnalysisViewEntry.SetRange("Analysis View Code", PayrollAnalysisView.Code);
        PayrollAnalysisViewEntry.SetFilter("Dimension 1 Value Code", DimValue.Code);
        Assert.IsFalse(PayrollAnalysisViewEntry.IsEmpty, IncorrectEntryCountErr);

        UpdateViewWithDimension(PayrollAnalysisView, '');

        Assert.IsTrue(PayrollAnalysisViewEntry.IsEmpty, IncorrectEntryCountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyExportPayrollReportFSI4T2()
    var
        PayrollAnalysisReportName: Record "Payroll Analysis Report Name";
    begin
        Initialize;

        if PayrollAnalysisReportName.Get('FSI-4 T2') then
            ExportPayrollAnalisysReport(PayrollAnalysisReportName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyExportPayrollReportFSI4T3()
    var
        PayrollAnalysisReportName: Record "Payroll Analysis Report Name";
    begin
        Initialize;

        if PayrollAnalysisReportName.Get('FSI-4 T3') then
            ExportPayrollAnalisysReport(PayrollAnalysisReportName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyExportPayrollReportFSI4T9()
    var
        PayrollAnalysisReportName: Record "Payroll Analysis Report Name";
    begin
        Initialize;

        if PayrollAnalysisReportName.Get('FSI-4 T9') then
            ExportPayrollAnalisysReport(PayrollAnalysisReportName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyExportPayrollReportINVCARD()
    var
        PayrollAnalysisReportName: Record "Payroll Analysis Report Name";
    begin
        Initialize;

        if PayrollAnalysisReportName.Get('INV CARD') then
            ExportPayrollAnalisysReport(PayrollAnalysisReportName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyExportPayrollReportRSV1R2()
    var
        PayrollAnalysisReportName: Record "Payroll Analysis Report Name";
    begin
        Initialize;

        if PayrollAnalysisReportName.Get('RSV_1 R2') then
            ExportPayrollAnalisysReport(PayrollAnalysisReportName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAnalysisViewSelection()
    var
        PayrollAnalysisView: Record "Payroll Analysis View";
        PayrollStatisticsBuffer: Record "Payroll Statistics Buffer";
        PayrollAnalysisMgt: Codeunit "Payroll Analysis Management";
        CurrentPayrollAnalysisViewCode: Code[10];
        FirstViewCode: Code[10];
        Dim1Filter: Text;
        Dim2Filter: Text;
        Dim3Filter: Text;
        Dim4Filter: Text;
    begin
        // Verify Analysis View Selection for some records
        CreatePayrollAnalysisView(PayrollAnalysisView, '');
        CreatePayrollAnalysisView(PayrollAnalysisView, '');
        PayrollAnalysisView.FindFirst;
        FirstViewCode := PayrollAnalysisView.Code;
        Clear(PayrollAnalysisView);

        PayrollAnalysisMgt.AnalysisViewSelection(
          CurrentPayrollAnalysisViewCode, PayrollAnalysisView, PayrollStatisticsBuffer,
          Dim1Filter, Dim2Filter, Dim3Filter, Dim4Filter);

        Assert.AreEqual(
          FirstViewCode, PayrollAnalysisView.Code,
          StrSubstNo(IncorrectValueErr, PayrollAnalysisView.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDimCodeBufferForElement()
    var
        PayrollAnalysisView: Record "Payroll Analysis View";
        PayrollElement: Record "Payroll Element";
        DimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4";
    begin
        // Verify DimCodeBuffer is filled correctly with FindRec for Payroll Element option
        CreatePayrollAnalysisView(PayrollAnalysisView, '');
        PayrollElement.FindFirst;

        RunVerifyFindRecForDimOption(
          PayrollAnalysisView, DimOption::Element, 0, '', false,
          PayrollElement.Code, PayrollElement.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDimCodeBufferForEmployee()
    var
        PayrollAnalysisView: Record "Payroll Analysis View";
        Employee: Record Employee;
        DimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4";
    begin
        // Verify DimCodeBuffer is filled correctly with FindRec for Employee option
        CreatePayrollAnalysisView(PayrollAnalysisView, '');
        Employee.FindFirst;

        RunVerifyFindRecForDimOption(
          PayrollAnalysisView, DimOption::Employee, 0, '', false,
          Employee."No.", Employee."Short Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDimCodeBufferForPeriod()
    var
        PayrollAnalysisView: Record "Payroll Analysis View";
        Period: Record Date;
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        DateFilter: Text[30];
        DimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4";
    begin
        // Verify DimCodeBuffer is filled correctly with FindRec for Period option
        CreatePayrollAnalysisView(PayrollAnalysisView, '');

        DateFilter := StrSubstNo('%1..%2', WorkDate, CalcDate('<+1Y>', WorkDate));
        Period.SetRange("Period Type", Period."Period Type"::Month);
        Period.SetFilter("Period Start", DateFilter);
        Period.FindFirst;

        RunVerifyFindRecForDimOption(
          PayrollAnalysisView, DimOption::Period, PeriodType::Month, DateFilter, true,
          Format(Period."Period Start"), Period."Period Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDimCodeBufferForDimension()
    var
        PayrollAnalysisView: Record "Payroll Analysis View";
        Dimension: Record Dimension;
        DimValue: Record "Dimension Value";
        DimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4";
    begin
        // Verify DimCodeBuffer is filled correctly with FindRec for Dimension option
        CreatePayrollAnalysisView(PayrollAnalysisView, '');
        LibraryDimension.FindDimension(Dimension);
        UpdateViewWithDimension(PayrollAnalysisView, Dimension.Code);
        DimValue.SetRange("Dimension Code", PayrollAnalysisView."Dimension 1 Code");
        DimValue.FindFirst;

        RunVerifyFindRecForDimOption(
          PayrollAnalysisView, DimOption::"Dimension 1", 0, '', false,
          DimValue.Code, DimValue.Name);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    local procedure CreatePayrollAnalysisView(var PayrollAnalysisView: Record "Payroll Analysis View"; DimensionCode: Code[20])
    begin
        with PayrollAnalysisView do begin
            Init;
            Code := LibraryUtility.GenerateGUID;
            "Dimension 1 Code" := DimensionCode;
            Insert;
        end;
    end;

    local procedure InitPayrollAnalysisView(var PayrollAnalysisView: Record "Payroll Analysis View"; DimensionCode: Code[20])
    begin
        Initialize;

        CreatePayrollAnalysisView(PayrollAnalysisView, DimensionCode);
        CODEUNIT.Run(CODEUNIT::"Update Payroll Analysis View", PayrollAnalysisView);
        PayrollAnalysisView.Find;
    end;

    local procedure ExportPayrollAnalisysReport(PayrollAnalysisReportName: Record "Payroll Analysis Report Name")
    var
        PayrollAnalysisLine: Record "Payroll Analysis Line";
        ExportPayrAnRepToExcel: Report "Export Payr. An. Rep. to Excel";
        FileName: Text;
    begin
        LibraryReportValidation.SetFileName(PayrollAnalysisReportName.Name);
        FileName := LibraryReportValidation.GetFileName;

        // Execute
        PayrollAnalysisLine.SetRange("Analysis Line Template Name", PayrollAnalysisReportName."Analysis Line Template Name");
        PayrollAnalysisLine.SetRange("Date Filter", CalcDate('<-1Y-CY>', WorkDate), CalcDate('<-1Y+CY>', WorkDate));
        PayrollAnalysisLine.FindFirst;
        ExportPayrAnRepToExcel.SetFileNameSilent(FileName);
        ExportPayrAnRepToExcel.SetOptions(
          PayrollAnalysisLine,
          PayrollAnalysisReportName."Analysis Column Template Name", PayrollAnalysisReportName."Analysis Line Template Name");
        ExportPayrAnRepToExcel.SetTestMode(true);
        ExportPayrAnRepToExcel.UseRequestPage(false);
        ExportPayrAnRepToExcel.Run;
        Clear(ExportPayrAnRepToExcel);
    end;

    local procedure GetInitialViewEntryCount(var PayrollAnalysisViewEntry: Record "Payroll Analysis View Entry"; ViewCode: Code[10]): Integer
    begin
        PayrollAnalysisViewEntry.SetRange("Analysis View Code", ViewCode);
        exit(PayrollAnalysisViewEntry.Count);
    end;

    local procedure UpdateViewWithPayrollElement(var PayrollAnalysisView: Record "Payroll Analysis View")
    var
        PayrollLedgerEntry: Record "Payroll Ledger Entry";
    begin
        PayrollLedgerEntry.FindFirst;
        PayrollAnalysisView.Validate("Payroll Element Filter", PayrollLedgerEntry."Element Code");
        PayrollAnalysisView.Modify(true);
    end;

    local procedure UpdateViewWithEmployee(var PayrollAnalysisView: Record "Payroll Analysis View")
    var
        PayrollLedgerEntry: Record "Payroll Ledger Entry";
    begin
        PayrollLedgerEntry.FindFirst;
        PayrollAnalysisView.Validate("Employee Filter", PayrollLedgerEntry."Employee No.");
        PayrollAnalysisView.Modify(true);
    end;

    local procedure UpdateViewWithDimension(var PayrollAnalysisView: Record "Payroll Analysis View"; DimensionCode: Code[20])
    begin
        PayrollAnalysisView.Validate("Dimension 1 Code", DimensionCode);
        PayrollAnalysisView.Modify(true);
    end;

    local procedure CreatePayrolLedgerEntryWithDim(): Code[20]
    var
        Employee: Record Employee;
        PayrollElement: Record "Payroll Element";
        Dimension: Record Dimension;
        DimValue: Record "Dimension Value";
        PayrollLedgerEntry: Record "Payroll Ledger Entry";
        RecRef: RecordRef;
    begin
        Employee.FindFirst;
        PayrollElement.FindFirst;
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimValue, Dimension.Code);
        with PayrollLedgerEntry do begin
            Init;
            RecRef.GetTable(PayrollLedgerEntry);
            "Entry No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Entry No."));
            "Employee No." := Employee."No.";
            "Posting Date" := WorkDate;
            "Element Code" := PayrollElement.Code;
            "Dimension Set ID" := LibraryDimension.CreateDimSet(0, Dimension.Code, DimValue.Code);
            Insert;
        end;
        exit(Dimension.Code);
    end;

    local procedure RunVerifyFindRecForDimOption(PayrollAnalysisView: Record "Payroll Analysis View"; DimOption: Option; PeriodType: Option; DateFilter: Text[30]; PeriodInitialized: Boolean; ExpectedCode: Code[20]; ExpectedName: Text[50])
    var
        DimCodeBuf: Record "Dimension Code Buffer";
        PayrollAnalysisMgt: Codeunit "Payroll Analysis Management";
        ElementFilter: Code[250];
        ElementGroupFilter: Code[250];
        EmployeeFilter: Code[250];
        OrgUnitFilter: Code[250];
        InternalDateFilter: Text[30];
        Dim1Filter: Text;
        Dim2Filter: Text;
        Dim3Filter: Text;
        Dim4Filter: Text;
    begin
        PayrollAnalysisMgt.FindRec(PayrollAnalysisView, DimOption, DimCodeBuf, '-',
          ElementFilter, ElementGroupFilter, EmployeeFilter, OrgUnitFilter,
          PeriodType, DateFilter, PeriodInitialized, InternalDateFilter,
          Dim1Filter, Dim2Filter, Dim3Filter, Dim4Filter);

        VerifyDimCodeBuffer(DimCodeBuf, ExpectedCode, ExpectedName);
    end;

    local procedure VerifyDimCodeBuffer(DimCodeBuf: Record "Dimension Code Buffer"; ExpectedCode: Code[20]; ExpectedName: Text[50])
    begin
        with DimCodeBuf do begin
            Assert.AreEqual(ExpectedCode, Code, StrSubstNo(IncorrectValueErr, Code));
            Assert.AreEqual(ExpectedName, Name, StrSubstNo(IncorrectValueErr, Name));
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Text: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

