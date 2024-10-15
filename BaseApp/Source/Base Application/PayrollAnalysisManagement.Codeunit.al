codeunit 14964 "Payroll Analysis Management"
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Period';
        Text001: Label '<Sign><Integer Thousand><Decimals,2>', Locked = true;
        Text003: Label '%1 is not a valid line definition.';
        Text004: Label '%1 is not a valid column definition.';
        Text005: Label '1,6,,Dimension 1 Filter';
        Text006: Label '1,6,,Dimension 2 Filter';
        Text007: Label '1,6,,Dimension 3 Filter';
        Text008: Label '1,6,,Dimension 4 Filter';
        Text009: Label 'DEFAULT';
        Text010: Label 'Default analysis view';
        PrevPayrollAnalysisView: Record "Payroll Analysis View";
        CurrentPayrollAnalysisViewCode: Code[10];
        CurrLineDimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4";
        CurrLineDimCodeBuf: Record "Dimension Code Buffer";
        CurrColDimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4";
        CurrColDimCodeBuf: Record "Dimension Code Buffer";

    local procedure DimCodeNotAllowed(DimCode: Text[30]; PayrollAnalysisView: Record "Payroll Analysis View"): Boolean
    var
        PayrollElement: Record "Payroll Element";
        PayrollElementGroup: Record "Payroll Element Group";
        Employee: Record Employee;
        OrgUnit: Record "Organizational Unit";
    begin
        exit(
          not (UpperCase(DimCode) in
               [UpperCase(PayrollElement.TableCaption),
                UpperCase(PayrollElementGroup.TableCaption),
                UpperCase(Employee.TableCaption),
                UpperCase(OrgUnit.TableCaption),
                UpperCase(Text000),
                PayrollAnalysisView."Dimension 1 Code",
                PayrollAnalysisView."Dimension 2 Code",
                PayrollAnalysisView."Dimension 3 Code",
                PayrollAnalysisView."Dimension 4 Code",
                '']));
    end;

    local procedure DimCodeToOption(DimCode: Text[30]; PayrollAnalysisView: Record "Payroll Analysis View"): Integer
    var
        PayrollElement: Record "Payroll Element";
        PayrollElementGroup: Record "Payroll Element Group";
        Employee: Record Employee;
        OrgUnit: Record "Organizational Unit";
    begin
        case DimCode of
            PayrollElement.TableCaption:
                exit(0);
            PayrollElementGroup.TableCaption:
                exit(1);
            Employee.TableCaption:
                exit(2);
            OrgUnit.TableCaption:
                exit(3);
            Text000:
                exit(4);
            PayrollAnalysisView."Dimension 1 Code":
                exit(5);
            PayrollAnalysisView."Dimension 2 Code":
                exit(6);
            PayrollAnalysisView."Dimension 3 Code":
                exit(7);
            PayrollAnalysisView."Dimension 4 Code":
                exit(8);
            else
                exit(-1);
        end;
    end;

    local procedure CopyElementToBuf(var PayrollElement: Record "Payroll Element"; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
        with DimCodeBuf do begin
            Init;
            Code := PayrollElement.Code;
            Name := PayrollElement.Description;
        end;
    end;

    local procedure CopyElementGroupToBuf(var PayrollElementGroup: Record "Payroll Element Group"; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
        with DimCodeBuf do begin
            Init;
            Code := PayrollElementGroup.Code;
            Name := PayrollElementGroup.Name;
        end;
    end;

    local procedure CopyPeriodToBuf(var Period: Record Date; var DimCodeBuf: Record "Dimension Code Buffer"; DateFilter: Text[30])
    var
        Period2: Record Date;
    begin
        with DimCodeBuf do begin
            Init;
            Code := Format(Period."Period Start");
            "Period Start" := Period."Period Start";
            "Period End" := Period."Period End";
            if DateFilter <> '' then begin
                Period2.SetFilter("Period End", DateFilter);
                if Period2.GetRangeMax("Period End") < "Period End" then
                    "Period End" := Period2.GetRangeMax("Period End");
            end;
            Name := Period."Period Name";
        end;
    end;

    local procedure CopyEmployeeToBuf(var Employee: Record Employee; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
        with DimCodeBuf do begin
            Init;
            Code := Employee."No.";
            Name := Employee."Short Name";
        end;
    end;

    local procedure CopyOrgUnitToBuf(var OrgUnit: Record "Organizational Unit"; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
        with DimCodeBuf do begin
            Init;
            Code := OrgUnit.Code;
            Name := OrgUnit.Name;
        end;
    end;

    local procedure CopyDimValueToBuf(var DimVal: Record "Dimension Value"; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
        with DimCodeBuf do begin
            Init;
            Code := DimVal.Code;
            Name := DimVal.Name;
            Totaling := DimVal.Totaling;
            Indentation := DimVal.Indentation;
            "Show in Bold" :=
              DimVal."Dimension Value Type" <> DimVal."Dimension Value Type"::Standard;
        end;
    end;

    local procedure FilterPayrollAnalyViewEntry(var PayrollStatisticsBuffer: Record "Payroll Statistics Buffer"; var PayrollAnalysisViewEntry: Record "Payroll Analysis View Entry")
    begin
        with PayrollStatisticsBuffer do begin
            CopyFilter("Analysis View Filter", PayrollAnalysisViewEntry."Analysis View Code");

            if GetFilter("Element Type Filter") <> '' then
                CopyFilter("Element Type Filter", PayrollAnalysisViewEntry."Payroll Element Type");

            if GetFilter("Element Filter") <> '' then
                CopyFilter("Element Filter", PayrollAnalysisViewEntry."Element Code");

            if GetFilter("Element Group Filter") <> '' then
                CopyFilter("Element Group Filter", PayrollAnalysisViewEntry."Element Group");

            if GetFilter("Employee Filter") <> '' then
                CopyFilter("Employee Filter", PayrollAnalysisViewEntry."Employee No.");

            if GetFilter("Org. Unit Filter") <> '' then
                CopyFilter("Org. Unit Filter", PayrollAnalysisViewEntry."Org. Unit Code");

            if GetFilter("Use PF Accum. System Filter") <> '' then
                CopyFilter("Use PF Accum. System Filter", PayrollAnalysisViewEntry."Use PF Accum. System");

            if GetFilter("Date Filter") <> '' then
                CopyFilter("Date Filter", PayrollAnalysisViewEntry."Posting Date");

            if GetFilter("Dimension 1 Filter") <> '' then
                CopyFilter("Dimension 1 Filter", PayrollAnalysisViewEntry."Dimension 1 Value Code");

            if GetFilter("Dimension 2 Filter") <> '' then
                CopyFilter("Dimension 2 Filter", PayrollAnalysisViewEntry."Dimension 2 Value Code");

            if GetFilter("Dimension 3 Filter") <> '' then
                CopyFilter("Dimension 3 Filter", PayrollAnalysisViewEntry."Dimension 3 Value Code");

            if GetFilter("Dimension 4 Filter") <> '' then
                CopyFilter("Dimension 4 Filter", PayrollAnalysisViewEntry."Dimension 4 Value Code");
        end;
    end;

    local procedure SetDimFilters(var PayrollStatisticsBuffer: Record "Payroll Statistics Buffer"; DimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4"; DimCodeBuf: Record "Dimension Code Buffer")
    begin
        with PayrollStatisticsBuffer do
            case DimOption of
                DimOption::Element:
                    SetRange("Element Filter", DimCodeBuf.Code);
                DimOption::Period:
                    SetRange("Date Filter", DimCodeBuf."Period Start", DimCodeBuf."Period End");
                DimOption::"Element Group":
                    SetRange("Element Group Filter", DimCodeBuf.Code);
                DimOption::Employee:
                    SetRange("Employee Filter", DimCodeBuf.Code);
                DimOption::"Org. Unit":
                    SetRange("Org. Unit Filter", DimCodeBuf.Code);
                DimOption::"Dimension 1":
                    if DimCodeBuf.Totaling <> '' then
                        SetFilter("Dimension 1 Filter", DimCodeBuf.Totaling)
                    else
                        SetRange("Dimension 1 Filter", DimCodeBuf.Code);
                DimOption::"Dimension 2":
                    if DimCodeBuf.Totaling <> '' then
                        SetFilter("Dimension 2 Filter", DimCodeBuf.Totaling)
                    else
                        SetRange("Dimension 2 Filter", DimCodeBuf.Code);
                DimOption::"Dimension 3":
                    if DimCodeBuf.Totaling <> '' then
                        SetFilter("Dimension 3 Filter", DimCodeBuf.Totaling)
                    else
                        SetRange("Dimension 3 Filter", DimCodeBuf.Code);
                DimOption::"Dimension 4":
                    if DimCodeBuf.Totaling <> '' then
                        SetFilter("Dimension 4 Filter", DimCodeBuf.Totaling)
                    else
                        SetRange("Dimension 4 Filter", DimCodeBuf.Code);
            end;
    end;

    [Scope('OnPrem')]
    procedure SetCommonFilters(var PayrollStatisticsBuffer: Record "Payroll Statistics Buffer"; CurrentAnalysisViewCode: Code[10]; ElementTypeFilter: Code[250]; ElementFilter: Code[250]; ElementGroupFilter: Code[250]; EmployeeFilter: Code[250]; OrgUnitFilter: Code[250]; UsePFAccumSystemFilter: Option " ",Yes,No; DateFilter: Text[30]; Dim1Filter: Code[250]; Dim2Filter: Code[250]; Dim3Filter: Code[250]; Dim4Filter: Code[250])
    begin
        with PayrollStatisticsBuffer do begin
            Reset;
            SetRange("Analysis View Filter", CurrentAnalysisViewCode);

            if ElementTypeFilter <> '' then
                SetFilter("Element Type Filter", ElementTypeFilter);
            if ElementFilter <> '' then
                SetFilter("Element Filter", ElementFilter);
            if ElementGroupFilter <> '' then
                SetFilter("Element Group Filter", ElementGroupFilter);
            if EmployeeFilter <> '' then
                SetFilter("Employee Filter", EmployeeFilter);
            if OrgUnitFilter <> '' then
                SetFilter("Org. Unit Filter", OrgUnitFilter);
            case UsePFAccumSystemFilter of
                1:
                    SetRange("Use PF Accum. System Filter", true);
                2:
                    SetRange("Use PF Accum. System Filter", false);
            end;
            if DateFilter <> '' then
                SetFilter("Date Filter", DateFilter);
            if Dim1Filter <> '' then
                SetFilter("Dimension 1 Filter", Dim1Filter);
            if Dim2Filter <> '' then
                SetFilter("Dimension 2 Filter", Dim2Filter);
            if Dim3Filter <> '' then
                SetFilter("Dimension 3 Filter", Dim3Filter);
            if Dim4Filter <> '' then
                SetFilter("Dimension 4 Filter", Dim4Filter);
        end;
    end;

    [Scope('OnPrem')]
    procedure AnalysisViewSelection(var CurrentPayrollAnalysisViewCode: Code[10]; var PayrollAnalysisView: Record "Payroll Analysis View"; var PayrollStatisticsBuffer: Record "Payroll Statistics Buffer"; var Dim1Filter: Text; var Dim2Filter: Text; var Dim3Filter: Text; var Dim4Filter: Text)
    begin
        if not PayrollAnalysisView.Get(CurrentPayrollAnalysisViewCode) then begin
            if not PayrollAnalysisView.Find('-') then begin
                PayrollAnalysisView.Init();
                PayrollAnalysisView.Code := Text009;
                PayrollAnalysisView.Name := Text010;
                PayrollAnalysisView.Insert(true);
            end;
            CurrentPayrollAnalysisViewCode := PayrollAnalysisView.Code;
        end;

        SetPayrollAnalysisView(
          CurrentPayrollAnalysisViewCode, PayrollAnalysisView, PayrollStatisticsBuffer,
          Dim1Filter, Dim2Filter, Dim3Filter, Dim4Filter);
    end;

    [Scope('OnPrem')]
    procedure CheckAnalysisView(CurrentPayrollAnalysisViewCode: Code[10]; var PayrollAnalysisView: Record "Payroll Analysis View")
    begin
        PayrollAnalysisView.Get(CurrentPayrollAnalysisViewCode);
    end;

    [Scope('OnPrem')]
    procedure SetPayrollAnalysisView(CurrentPayrollAnalysisViewCode: Code[10]; var PayrollAnalysisView: Record "Payroll Analysis View"; var PayrollStatisticsBuffer: Record "Payroll Statistics Buffer"; var Dim1Filter: Text; var Dim2Filter: Text; var Dim3Filter: Text; var Dim4Filter: Text)
    begin
        PayrollStatisticsBuffer.SetRange("Analysis View Filter", CurrentPayrollAnalysisViewCode);

        if PrevPayrollAnalysisView.Code <> '' then begin
            if PayrollAnalysisView."Dimension 1 Code" <> PrevPayrollAnalysisView."Dimension 1 Code" then
                Dim1Filter := '';
            if PayrollAnalysisView."Dimension 2 Code" <> PrevPayrollAnalysisView."Dimension 2 Code" then
                Dim2Filter := '';
            if PayrollAnalysisView."Dimension 3 Code" <> PrevPayrollAnalysisView."Dimension 3 Code" then
                Dim3Filter := '';
            if PayrollAnalysisView."Dimension 4 Code" <> PrevPayrollAnalysisView."Dimension 4 Code" then
                Dim4Filter := '';
        end;
        PayrollStatisticsBuffer.SetFilter("Dimension 1 Filter", Dim1Filter);
        PayrollStatisticsBuffer.SetFilter("Dimension 2 Filter", Dim2Filter);
        PayrollStatisticsBuffer.SetFilter("Dimension 3 Filter", Dim3Filter);
        PayrollStatisticsBuffer.SetFilter("Dimension 4 Filter", Dim4Filter);

        PrevPayrollAnalysisView := PayrollAnalysisView;
    end;

    [Scope('OnPrem')]
    procedure LookupPayrollAnalysisView(var CurrentPayrollAnalysisViewCode: Code[10]; var PayrollAnalysisView: Record "Payroll Analysis View"; var PayrollStatisticsBuffer: Record "Payroll Statistics Buffer"; var Dim1Filter: Text; var Dim2Filter: Text; var Dim3Filter: Text; var Dim4Filter: Text)
    var
        PayrollAnalysisView2: Record "Payroll Analysis View";
    begin
        PayrollAnalysisView2.Copy(PayrollAnalysisView);
        if PAGE.RunModal(0, PayrollAnalysisView2) = ACTION::LookupOK then begin
            PayrollAnalysisView := PayrollAnalysisView2;
            CurrentPayrollAnalysisViewCode := PayrollAnalysisView.Code;
            SetPayrollAnalysisView(
              CurrentPayrollAnalysisViewCode, PayrollAnalysisView, PayrollStatisticsBuffer,
              Dim1Filter, Dim2Filter, Dim3Filter, Dim4Filter);
        end else
            AnalysisViewSelection(
              CurrentPayrollAnalysisViewCode, PayrollAnalysisView, PayrollStatisticsBuffer,
              Dim1Filter, Dim2Filter, Dim3Filter, Dim4Filter);
    end;

    [Scope('OnPrem')]
    procedure LookUpCode(DimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4"; DimCode: Text[30]; "Code": Text[30])
    var
        PayrollElement: Record "Payroll Element";
        PayrollElementGroup: Record "Payroll Element Group";
        Employee: Record Employee;
        OrgUnit: Record "Organizational Unit";
        DimVal: Record "Dimension Value";
        DimValList: Page "Dimension Value List";
    begin
        case DimOption of
            DimOption::Element:
                begin
                    PayrollElement.Get(Code);
                    PAGE.RunModal(0, PayrollElement);
                end;
            DimOption::"Element Group":
                begin
                    PayrollElementGroup.Get(Code);
                    PAGE.RunModal(0, PayrollElementGroup);
                end;
            DimOption::Employee:
                begin
                    Employee.Get(Code);
                    PAGE.RunModal(0, Employee);
                end;
            DimOption::"Org. Unit":
                begin
                    OrgUnit.Get(Code);
                    PAGE.RunModal(0, OrgUnit);
                end;
            DimOption::Period:
                ;
            DimOption::"Dimension 1",
            DimOption::"Dimension 2",
            DimOption::"Dimension 3",
            DimOption::"Dimension 4":
                begin
                    DimVal.SetRange("Dimension Code", DimCode);
                    DimVal.Get(DimCode, Code);
                    DimValList.SetTableView(DimVal);
                    DimValList.SetRecord(DimVal);
                    DimValList.RunModal;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure LookUpDimFilter(Dim: Code[20]; var Text: Text[250]): Boolean
    var
        DimVal: Record "Dimension Value";
        DimValList: Page "Dimension Value List";
    begin
        if Dim = '' then
            exit(false);
        DimValList.LookupMode(true);
        DimVal.SetRange("Dimension Code", Dim);
        DimValList.SetTableView(DimVal);
        if DimValList.RunModal = ACTION::LookupOK then begin
            DimValList.GetRecord(DimVal);
            Text := DimValList.GetSelectionFilter;
            exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure DrillDown(PayrollStatisticsBuffer: Record "Payroll Statistics Buffer"; CurrentPayrollAnalysisViewCode: Code[10]; ElementTypeFilter: Code[250]; ElementFilter: Code[250]; ElementGroupFilter: Code[250]; EmployeeFilter: Code[250]; OrgUnitFilter: Code[250]; UsePFAccumSystemFilter: Option " ",Yes,No; DateFilter: Text[30]; Dim1Filter: Code[250]; Dim2Filter: Code[250]; Dim3Filter: Code[250]; Dim4Filter: Code[250]; LineDimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4"; LineDimCodeBuf: Record "Dimension Code Buffer"; ColDimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4"; ColDimCodeBuf: Record "Dimension Code Buffer"; SetColumnFilter: Boolean; ValueType: Option "Payroll Amount","Taxable Amount")
    var
        PayrollAnalysisViewEntry: Record "Payroll Analysis View Entry";
    begin
        SetCommonFilters(
          PayrollStatisticsBuffer,
          CurrentPayrollAnalysisViewCode,
          ElementTypeFilter,
          ElementFilter,
          ElementGroupFilter,
          EmployeeFilter,
          OrgUnitFilter,
          UsePFAccumSystemFilter,
          DateFilter,
          Dim1Filter,
          Dim2Filter,
          Dim3Filter,
          Dim4Filter);
        SetDimFilters(PayrollStatisticsBuffer, LineDimOption, LineDimCodeBuf);
        if SetColumnFilter then
            SetDimFilters(PayrollStatisticsBuffer, ColDimOption, ColDimCodeBuf);

        FilterPayrollAnalyViewEntry(PayrollStatisticsBuffer, PayrollAnalysisViewEntry);
        case ValueType of
            ValueType::"Payroll Amount":
                PAGE.Run(0, PayrollAnalysisViewEntry, PayrollAnalysisViewEntry."Payroll Amount");
            ValueType::"Taxable Amount":
                PAGE.Run(0, PayrollAnalysisViewEntry, PayrollAnalysisViewEntry."Taxable Amount");
        end;
    end;

    [Scope('OnPrem')]
    procedure SetLineAndColDim(PayrollAnalysisView: Record "Payroll Analysis View"; var LineDimCode: Text[30]; var LineDimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4"; var ColumnDimCode: Text[30]; var ColumnDimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4")
    var
        PayrollElement: Record "Payroll Element";
    begin
        if (LineDimCode = '') and (ColumnDimCode = '') then begin
            LineDimCode := PayrollElement.TableCaption;
            ColumnDimCode := Text000;
        end;
        LineDimOption := DimCodeToOption(LineDimCode, PayrollAnalysisView);
        ColumnDimOption := DimCodeToOption(ColumnDimCode, PayrollAnalysisView);
    end;

    [Scope('OnPrem')]
    procedure GetDimSelection(OldDimSelCode: Text[30]; var PayrollAnalysisView: Record "Payroll Analysis View"): Text[30]
    var
        PayrollElement: Record "Payroll Element";
        PayrollElementGroup: Record "Payroll Element Group";
        Employee: Record Employee;
        OrgUnit: Record "Organizational Unit";
        DimSelection: Page "Dimension Selection";
    begin
        DimSelection.InsertDimSelBuf(false, PayrollElement.TableCaption, PayrollElement.TableCaption);
        DimSelection.InsertDimSelBuf(false, PayrollElementGroup.TableCaption, PayrollElementGroup.TableCaption);
        DimSelection.InsertDimSelBuf(false, Employee.TableCaption, Employee.TableCaption);
        DimSelection.InsertDimSelBuf(false, OrgUnit.TableCaption, OrgUnit.TableCaption);
        DimSelection.InsertDimSelBuf(false, Text000, Text000);
        if PayrollAnalysisView."Dimension 1 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, PayrollAnalysisView."Dimension 1 Code", '');
        if PayrollAnalysisView."Dimension 2 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, PayrollAnalysisView."Dimension 2 Code", '');
        if PayrollAnalysisView."Dimension 3 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, PayrollAnalysisView."Dimension 3 Code", '');
        if PayrollAnalysisView."Dimension 4 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, PayrollAnalysisView."Dimension 4 Code", '');

        DimSelection.LookupMode := true;
        if DimSelection.RunModal = ACTION::LookupOK then
            exit(DimSelection.GetDimSelCode);
        exit(OldDimSelCode);
    end;

    [Scope('OnPrem')]
    procedure ValidateLineDimCode(PayrollAnalysisView: Record "Payroll Analysis View"; var LineDimCode: Text[30]; var LineDimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4"; ColumnDimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4"; var InternalDateFilter: Text; var DateFilter: Text; var PayrollStatisticsBuffer: Record "Payroll Statistics Buffer"; var PeriodInitialized: Boolean)
    begin
        if DimCodeNotAllowed(LineDimCode, PayrollAnalysisView) then begin
            Message(Text003, LineDimCode);
            LineDimCode := '';
        end;
        LineDimOption := DimCodeToOption(LineDimCode, PayrollAnalysisView);
        InternalDateFilter := PayrollStatisticsBuffer.GetFilter("Date Filter");
        if (LineDimOption <> LineDimOption::Period) and (ColumnDimOption <> ColumnDimOption::Period) then begin
            DateFilter := InternalDateFilter;
            if StrPos(DateFilter, '&') > 1 then
                DateFilter := CopyStr(DateFilter, 1, StrPos(DateFilter, '&') - 1);
        end else
            PeriodInitialized := false;
    end;

    [Scope('OnPrem')]
    procedure ValidateColumnDimCode(PayrollAnalysisView: Record "Payroll Analysis View"; var ColumnDimCode: Text[30]; var ColumnDimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4"; LineDimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4"; var InternalDateFilter: Text; var DateFilter: Text; var PayrollStatisticsBuffer: Record "Payroll Statistics Buffer"; var PeriodInitialized: Boolean)
    begin
        if DimCodeNotAllowed(ColumnDimCode, PayrollAnalysisView) then begin
            Message(Text004, ColumnDimCode);
            ColumnDimCode := '';
        end;
        ColumnDimOption := DimCodeToOption(ColumnDimCode, PayrollAnalysisView);
        InternalDateFilter := PayrollStatisticsBuffer.GetFilter("Date Filter");
        if (ColumnDimOption <> ColumnDimOption::Period) and (LineDimOption <> LineDimOption::Period) then begin
            DateFilter := InternalDateFilter;
            if StrPos(DateFilter, '&') > 1 then
                DateFilter := CopyStr(DateFilter, 1, StrPos(DateFilter, '&') - 1);
        end else
            PeriodInitialized := false;
    end;

    [Scope('OnPrem')]
    procedure FormatAmount(var Text: Text[250]; RoundingFactor: Option "None","1","1000","1000000")
    var
        Amount: Decimal;
    begin
        if (Text = '') or (RoundingFactor = RoundingFactor::None) then
            exit;
        Evaluate(Amount, Text);
        case RoundingFactor of
            RoundingFactor::"1":
                Amount := Round(Amount, 1);
            RoundingFactor::"1000":
                Amount := Round(Amount / 1000, 0.1);
            RoundingFactor::"1000000":
                Amount := Round(Amount / 1000000, 0.1);
        end;
        if Amount = 0 then
            Text := ''
        else
            case RoundingFactor of
                RoundingFactor::"1":
                    Text := Format(Amount);
                RoundingFactor::"1000", RoundingFactor::"1000000":
                    Text := Format(Amount, 0, Text001);
            end;
    end;

    [Scope('OnPrem')]
    procedure FindRec(PayrollAnalysisView: Record "Payroll Analysis View"; DimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4"; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]; ElementFilter: Code[250]; ElementGroupFilter: Code[250]; EmployeeFilter: Code[250]; OrgUnitFilter: Code[250]; PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period"; var DateFilter: Text[30]; var PeriodInitialized: Boolean; InternalDateFilter: Text[30]; Dim1Filter: Code[250]; Dim2Filter: Code[250]; Dim3Filter: Code[250]; Dim4Filter: Code[250]): Boolean
    var
        PayrollElement: Record "Payroll Element";
        PayrollElementGroup: Record "Payroll Element Group";
        Employee: Record Employee;
        OrgUnit: Record "Organizational Unit";
        Period: Record Date;
        DimVal: Record "Dimension Value";
        PeriodFormMgt: Codeunit PeriodFormManagement;
        Found: Boolean;
    begin
        case DimOption of
            DimOption::Element:
                begin
                    PayrollElement.Code := DimCodeBuf.Code;
                    if ElementFilter <> '' then
                        PayrollElement.SetFilter(Code, ElementFilter);
                    Found := PayrollElement.Find(Which);
                    if Found then
                        CopyElementToBuf(PayrollElement, DimCodeBuf);
                end;
            DimOption::"Element Group":
                begin
                    PayrollElementGroup.Code := DimCodeBuf.Code;
                    if ElementGroupFilter <> '' then
                        PayrollElementGroup.SetFilter(Code, ElementGroupFilter);
                    Found := PayrollElementGroup.Find(Which);
                    if Found then
                        CopyElementGroupToBuf(PayrollElementGroup, DimCodeBuf);
                end;
            DimOption::Employee:
                begin
                    Employee."No." := DimCodeBuf.Code;
                    if EmployeeFilter <> '' then
                        Employee.SetFilter("No.", EmployeeFilter);
                    Found := Employee.Find(Which);
                    if Found then
                        CopyEmployeeToBuf(Employee, DimCodeBuf);
                end;
            DimOption::"Org. Unit":
                begin
                    OrgUnit.Code := CopyStr(DimCodeBuf.Code, 1, MaxStrLen(OrgUnit.Code));
                    if OrgUnitFilter <> '' then
                        OrgUnit.SetFilter(Code, OrgUnitFilter);
                    Found := OrgUnit.Find(Which);
                    if Found then
                        CopyOrgUnitToBuf(OrgUnit, DimCodeBuf);
                end;
            DimOption::Period:
                begin
                    if not PeriodInitialized then
                        DateFilter := '';
                    PeriodInitialized := true;
                    Period."Period Start" := DimCodeBuf."Period Start";
                    if DateFilter <> '' then
                        Period.SetFilter("Period Start", DateFilter)
                    else
                        if not PeriodInitialized and (InternalDateFilter <> '') then
                            Period.SetFilter("Period Start", InternalDateFilter);
                    Found := PeriodFormMgt.FindDate(Which, Period, PeriodType);
                    if Found then
                        CopyPeriodToBuf(Period, DimCodeBuf, DateFilter);
                end;
            DimOption::"Dimension 1":
                begin
                    if Dim1Filter <> '' then
                        DimVal.SetFilter(Code, Dim1Filter);
                    DimVal."Dimension Code" := PayrollAnalysisView."Dimension 1 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 2":
                begin
                    if Dim2Filter <> '' then
                        DimVal.SetFilter(Code, Dim2Filter);
                    DimVal."Dimension Code" := PayrollAnalysisView."Dimension 2 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 3":
                begin
                    if Dim3Filter <> '' then
                        DimVal.SetFilter(Code, Dim3Filter);
                    DimVal."Dimension Code" := PayrollAnalysisView."Dimension 3 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 4":
                begin
                    if Dim4Filter <> '' then
                        DimVal.SetFilter(Code, Dim4Filter);
                    DimVal."Dimension Code" := PayrollAnalysisView."Dimension 4 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
        end;
        exit(Found);
    end;

    [Scope('OnPrem')]
    procedure NextRec(PayrollAnalysisView: Record "Payroll Analysis View"; DimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4"; var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer; ElementFilter: Code[250]; ElementGroupFilter: Code[250]; EmployeeFilter: Code[250]; OrgUnitFilter: Code[250]; PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period"; DateFilter: Text[30]; Dim1Filter: Code[250]; Dim2Filter: Code[250]; Dim3Filter: Code[250]; Dim4Filter: Code[250]): Integer
    var
        PayrollElement: Record "Payroll Element";
        PayrollElementGroup: Record "Payroll Element Group";
        Employee: Record Employee;
        OrgUnit: Record "Organizational Unit";
        Period: Record Date;
        DimVal: Record "Dimension Value";
        PeriodFormMgt: Codeunit PeriodFormManagement;
        ResultSteps: Integer;
    begin
        case DimOption of
            DimOption::Element:
                begin
                    PayrollElement.Code := DimCodeBuf.Code;
                    if ElementFilter <> '' then
                        PayrollElement.SetFilter(Code, ElementFilter);
                    ResultSteps := PayrollElement.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyElementToBuf(PayrollElement, DimCodeBuf);
                end;
            DimOption::"Element Group":
                begin
                    PayrollElementGroup.Code := DimCodeBuf.Code;
                    if ElementGroupFilter <> '' then
                        PayrollElementGroup.SetFilter(Code, ElementGroupFilter);
                    ResultSteps := PayrollElementGroup.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyElementGroupToBuf(PayrollElementGroup, DimCodeBuf);
                end;
            DimOption::Employee:
                begin
                    Employee."No." := DimCodeBuf.Code;
                    if EmployeeFilter <> '' then
                        Employee.SetFilter("No.", EmployeeFilter);
                    ResultSteps := Employee.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyEmployeeToBuf(Employee, DimCodeBuf);
                end;
            DimOption::"Org. Unit":
                begin
                    OrgUnit.Code := DimCodeBuf.Code;
                    if OrgUnitFilter <> '' then
                        OrgUnit.SetFilter(Code, OrgUnitFilter);
                    ResultSteps := OrgUnit.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyOrgUnitToBuf(OrgUnit, DimCodeBuf);
                end;
            DimOption::Period:
                begin
                    if DateFilter <> '' then
                        Period.SetFilter("Period Start", DateFilter);
                    Period."Period Start" := DimCodeBuf."Period Start";
                    ResultSteps := PeriodFormMgt.NextDate(Steps, Period, PeriodType);
                    if ResultSteps <> 0 then
                        CopyPeriodToBuf(Period, DimCodeBuf, DateFilter);
                end;
            DimOption::"Dimension 1":
                begin
                    if Dim1Filter <> '' then
                        DimVal.SetFilter(Code, Dim1Filter);
                    DimVal."Dimension Code" := PayrollAnalysisView."Dimension 1 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 2":
                begin
                    if Dim2Filter <> '' then
                        DimVal.SetFilter(Code, Dim2Filter);
                    DimVal."Dimension Code" := PayrollAnalysisView."Dimension 2 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 3":
                begin
                    if Dim3Filter <> '' then
                        DimVal.SetFilter(Code, Dim3Filter);
                    DimVal."Dimension Code" := PayrollAnalysisView."Dimension 3 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimOption::"Dimension 4":
                begin
                    if Dim4Filter <> '' then
                        DimVal.SetFilter(Code, Dim4Filter);
                    DimVal."Dimension Code" := PayrollAnalysisView."Dimension 4 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
        end;
        exit(ResultSteps);
    end;

    [Scope('OnPrem')]
    procedure GetCaptionClass(AnalysisViewDimType: Integer; PayrollAnalysisView: Record "Payroll Analysis View"): Text[250]
    begin
        case AnalysisViewDimType of
            1:
                begin
                    if PayrollAnalysisView."Dimension 1 Code" <> '' then
                        exit('1,6,' + PayrollAnalysisView."Dimension 1 Code");
                    exit(Text005);
                end;
            2:
                begin
                    if PayrollAnalysisView."Dimension 2 Code" <> '' then
                        exit('1,6,' + PayrollAnalysisView."Dimension 2 Code");
                    exit(Text006);
                end;
            3:
                begin
                    if PayrollAnalysisView."Dimension 3 Code" <> '' then
                        exit('1,6,' + PayrollAnalysisView."Dimension 3 Code");
                    exit(Text007);
                end;
            4:
                begin
                    if PayrollAnalysisView."Dimension 4 Code" <> '' then
                        exit('1,6,' + PayrollAnalysisView."Dimension 4 Code");
                    exit(Text008);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetCalcAmountParameters(PayrollAnalysisViewCode: Code[10]; LineDimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4"; LineDimCodeBuf: Record "Dimension Code Buffer"; ColDimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4"; ColDimCodeBuf: Record "Dimension Code Buffer")
    begin
        CurrentPayrollAnalysisViewCode := PayrollAnalysisViewCode;
        CurrLineDimOption := LineDimOption;
        CurrLineDimCodeBuf := LineDimCodeBuf;
        CurrColDimOption := ColDimOption;
        CurrColDimCodeBuf := ColDimCodeBuf;
    end;

    [Scope('OnPrem')]
    procedure CalcAmount(SetColumnFilter: Boolean; ValueType: Option "Payroll Amount","Taxable Amount"; var PayrollStatisticsBuffer: Record "Payroll Statistics Buffer"; ElementTypeFilter: Text[250]; ElementFilter: Code[250]; ElementGroupFilter: Code[250]; EmployeeFilter: Code[250]; OrgUnitFilter: Code[250]; UsePFAccumSystemFilter: Option " ",Yes,No; DateFilter: Text[20]; Dim1Filter: Code[250]; Dim2Filter: Code[250]; Dim3Filter: Code[250]; Dim4Filter: Code[250]): Decimal
    var
        Amount: Decimal;
    begin
        SetCommonFilters(
          PayrollStatisticsBuffer,
          CurrentPayrollAnalysisViewCode,
          ElementTypeFilter,
          ElementFilter,
          ElementGroupFilter,
          EmployeeFilter,
          OrgUnitFilter,
          UsePFAccumSystemFilter,
          DateFilter,
          Dim1Filter,
          Dim2Filter,
          Dim3Filter,
          Dim4Filter
          );

        SetDimFilters(PayrollStatisticsBuffer, CurrLineDimOption, CurrLineDimCodeBuf);
        if SetColumnFilter then
            SetDimFilters(PayrollStatisticsBuffer, CurrColDimOption, CurrColDimCodeBuf);

        case ValueType of
            ValueType::"Payroll Amount":
                begin
                    PayrollStatisticsBuffer.CalcFields("Analysis - Payroll Amount");
                    Amount := PayrollStatisticsBuffer."Analysis - Payroll Amount";
                end;
            ValueType::"Taxable Amount":
                begin
                    PayrollStatisticsBuffer.CalcFields("Analysis - Taxable Amount");
                    Amount := PayrollStatisticsBuffer."Analysis - Taxable Amount";
                end;
        end;

        exit(Amount);
    end;
}

