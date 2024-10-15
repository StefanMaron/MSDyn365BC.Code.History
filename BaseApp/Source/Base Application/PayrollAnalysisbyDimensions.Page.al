page 14970 "Payroll Analysis by Dimensions"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payroll Analysis by Dimensions';
    DataCaptionExpression = CurrPayrollAnalysisViewCode;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Dimension Code Buffer";
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(CurrPayrollAnalysisViewCode; CurrPayrollAnalysisViewCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Analysis View Code';
                    ToolTip = 'Specifies the code for the analysis view that the filter belongs to.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        PayrollAnalysisMgt.LookupPayrollAnalysisView(
                          CurrPayrollAnalysisViewCode, PayrollAnalysisView, PayrollStatisticsBuffer,
                          Dim1Filter, Dim2Filter, Dim3Filter, Dim4Filter);
                        PayrollAnalysisMgt.SetLineAndColDim(
                          PayrollAnalysisView, LineDimCode, LineDimOption, ColumnDimCode, ColumnDimOption);
                        UpdateFilterFields;
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        PayrollAnalysisMgt.CheckAnalysisView(CurrPayrollAnalysisViewCode, PayrollAnalysisView);
                        CurrPayrollAnalysisViewCodeOnA;
                    end;
                }
                field(LineDimCode; LineDimCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show as Lines';
                    ToolTip = 'Specifies which values you want to show as lines in the window. This allows you to see the same matrix window from various perspectives, especially when you use both the Show as Lines field and the Show as Columns field.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        NewCode: Text[30];
                    begin
                        NewCode := PayrollAnalysisMgt.GetDimSelection(LineDimCode, PayrollAnalysisView);
                        if NewCode <> LineDimCode then begin
                            Text := NewCode;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        if (UpperCase(LineDimCode) = UpperCase(ColumnDimCode)) and (LineDimCode <> '') then begin
                            ColumnDimCode := '';
                            PayrollAnalysisMgt.ValidateColumnDimCode(
                              PayrollAnalysisView, ColumnDimCode, ColumnDimOption, LineDimOption,
                              InternalDateFilter, DateFilter, PayrollStatisticsBuffer, PeriodInitialized);
                        end;
                        PayrollAnalysisMgt.ValidateLineDimCode(
                          PayrollAnalysisView, LineDimCode, LineDimOption, ColumnDimOption,
                          InternalDateFilter, DateFilter, PayrollStatisticsBuffer, PeriodInitialized);
                        if LineDimOption = LineDimOption::Period then
                            SetCurrentKey("Period Start")
                        else
                            SetCurrentKey(Code);
                        LineDimCodeOnAfterValidate;
                    end;
                }
                field(ColumnDimCode; ColumnDimCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show as Columns';
                    ToolTip = 'Specifies which values you want to show as columns in the window. This allows you to see the same matrix window from various perspectives, especially when you use both the Show as Lines field and the Show as Columns field.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        NewCode: Text[30];
                    begin
                        NewCode := PayrollAnalysisMgt.GetDimSelection(ColumnDimCode, PayrollAnalysisView);
                        if NewCode <> ColumnDimCode then begin
                            Text := NewCode;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        if (UpperCase(LineDimCode) = UpperCase(ColumnDimCode)) and (LineDimCode <> '') then begin
                            LineDimCode := '';
                            PayrollAnalysisMgt.ValidateLineDimCode(
                              PayrollAnalysisView, LineDimCode, LineDimOption, ColumnDimOption,
                              InternalDateFilter, DateFilter, PayrollStatisticsBuffer, PeriodInitialized);
                        end;
                        PayrollAnalysisMgt.ValidateColumnDimCode(
                          PayrollAnalysisView, ColumnDimCode, ColumnDimOption, LineDimOption,
                          InternalDateFilter, DateFilter, PayrollStatisticsBuffer, PeriodInitialized);
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                        ColumnDimCodeOnAfterValidate;
                    end;
                }
                field(ValueType; ValueType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Value As';
                    OptionCaption = 'Payroll Amount,Taxable Amount';
                }
            }
            group(Filters)
            {
                Caption = 'Filters';
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        PayrollStatisticsBuffer.SetFilter("Date Filter", DateFilter);
                        DateFilter := PayrollStatisticsBuffer.GetFilter("Date Filter");
                        InternalDateFilter := DateFilter;
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                        DateFilterOnAfterValidate;
                    end;
                }
                field(ElementTypeFilter; ElementTypeFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Element Type Filter';

                    trigger OnValidate()
                    begin
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                        PayrollStatisticsBuffer.SetFilter("Element Type Filter", ElementTypeFilter);
                        ElementTypeFilter := PayrollStatisticsBuffer.GetFilter("Element Type Filter");
                        ElementTypeFilterOnAfterValida;
                    end;
                }
                field(ElementFilter; ElementFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Element Filter';
                    TableRelation = "Payroll Element";

                    trigger OnValidate()
                    begin
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                        ElementFilterOnAfterValidate;
                    end;
                }
                field(ElementGroupFilter; ElementGroupFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Element Group Filter';
                    TableRelation = "Payroll Element Group";

                    trigger OnValidate()
                    begin
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                        ElementGroupFilterOnAfterValid;
                    end;
                }
                field(EmployeeFilter; EmployeeFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Employee Filter';
                    TableRelation = Employee;

                    trigger OnValidate()
                    begin
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                        EmployeeFilterOnAfterValidate;
                    end;
                }
                field(OrgUnitFilter; OrgUnitFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Org. Unit Filter';
                    TableRelation = "Organizational Unit";

                    trigger OnValidate()
                    begin
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                        OrgUnitFilterOnAfterValidate;
                    end;
                }
                field(UsePFAccumSystemFilter; UsePFAccumSystemFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Use PF Accum. System Filter';

                    trigger OnValidate()
                    begin
                        UsePFAccumSystemFilterOnAfterV;
                    end;
                }
                field(Dim1Filter; Dim1Filter)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = PayrollAnalysisMgt.GetCaptionClass(1, PayrollAnalysisView);
                    Caption = 'Dimension 1 Filter';
                    Enabled = Dim1FilterEnable;
                    ToolTip = 'Specifies a filter for dimensions by which data is included.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(PayrollAnalysisMgt.LookUpDimFilter(PayrollAnalysisView."Dimension 1 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                        Dim1FilterOnAfterValidate;
                    end;
                }
                field(Dim2Filter; Dim2Filter)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = PayrollAnalysisMgt.GetCaptionClass(2, PayrollAnalysisView);
                    Caption = 'Dimension 2 Filter';
                    Enabled = Dim2FilterEnable;
                    ToolTip = 'Specifies a filter for dimensions by which data is included.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(PayrollAnalysisMgt.LookUpDimFilter(PayrollAnalysisView."Dimension 2 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                        Dim2FilterOnAfterValidate;
                    end;
                }
                field(Dim3Filter; Dim3Filter)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = PayrollAnalysisMgt.GetCaptionClass(3, PayrollAnalysisView);
                    Caption = 'Dimension 3 Filter';
                    Enabled = Dim3FilterEnable;
                    ToolTip = 'Specifies a filter for dimensions by which data is included.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(PayrollAnalysisMgt.LookUpDimFilter(PayrollAnalysisView."Dimension 3 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                        Dim3FilterOnAfterValidate;
                    end;
                }
                field(Dim4Filter; Dim4Filter)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = PayrollAnalysisMgt.GetCaptionClass(3, PayrollAnalysisView);
                    Caption = 'Dimension 4 Filter';
                    Enabled = Dim4FilterEnable;
                    ToolTip = 'Specifies a filter for dimensions by which data is included.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(PayrollAnalysisMgt.LookUpDimFilter(PayrollAnalysisView."Dimension 3 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                        Dim4FilterOnAfterValidate;
                    end;
                }
            }
            group(Options)
            {
                Caption = 'Options';
                field(RoundingFactor; RoundingFactor)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rounding Factor';
                    OptionCaption = 'None,1,1000,1000000';
                    ToolTip = 'Specifies the factor that is used to round the amounts.';
                }
                field(ShowColumnName; ShowColumnName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Column Name';

                    trigger OnValidate()
                    begin
                        ShowColumnNameOnAfterValidate;
                    end;
                }
                field(ShowOppositeSign; ShowOppositeSign)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Opposite Sign';
                    MultiLine = true;
                }
            }
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(ViewBy; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View by';
                    OptionCaption = 'Day,Week,Month,Quarter,Year,Accounting Period';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                    end;
                }
                field(ColumnSet; MATRIX_CaptionRange)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Column Set';
                    Editable = false;
                    ToolTip = 'Specifies the range of values that are displayed in the matrix window, for example, the total period. To change the contents of the field, choose Next Set or Previous Set.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Actions")
            {
                Caption = '&Actions';
                Image = "Action";
                action("Reverse Lines and Columns")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reverse Lines and Columns';
                    Image = Undo;

                    trigger OnAction()
                    var
                        TempDimCode: Text[30];
                    begin
                        TempDimCode := ColumnDimCode;
                        ColumnDimCode := LineDimCode;
                        LineDimCode := TempDimCode;
                        PayrollAnalysisMgt.ValidateLineDimCode(
                          PayrollAnalysisView, LineDimCode, LineDimOption, ColumnDimOption,
                          InternalDateFilter, DateFilter, PayrollStatisticsBuffer, PeriodInitialized);
                        PayrollAnalysisMgt.ValidateColumnDimCode(
                          PayrollAnalysisView, ColumnDimCode, ColumnDimOption, LineDimOption,
                          InternalDateFilter, DateFilter, PayrollStatisticsBuffer, PeriodInitialized);
                        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Show Matrix")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    Clear(PayrollAnalysisByDimMatrix);
                    ShowMatrix;
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Set';
                Image = PreviousSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Previous Set';

                trigger OnAction()
                begin
                    MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Previous);
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Set';
                Image = NextSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Next Set';

                trigger OnAction()
                begin
                    MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Next);
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(
          PayrollAnalysisMgt.FindRec(
            PayrollAnalysisView, LineDimOption, Rec, Which,
            ElementFilter, ElementGroupFilter, EmployeeFilter, OrgUnitFilter,
            PeriodType, DateFilter, PeriodInitialized, InternalDateFilter,
            Dim1Filter, Dim2Filter, Dim3Filter, Dim4Filter));
    end;

    trigger OnInit()
    begin
        Dim4FilterEnable := true;
        Dim3FilterEnable := true;
        Dim2FilterEnable := true;
        Dim1FilterEnable := true;
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(
          PayrollAnalysisMgt.NextRec(
            PayrollAnalysisView, LineDimOption, Rec, Steps,
            ElementFilter, ElementGroupFilter, EmployeeFilter, OrgUnitFilter,
            PeriodType, DateFilter,
            Dim1Filter, Dim2Filter, Dim3Filter, Dim4Filter));
    end;

    trigger OnOpenPage()
    begin
        GLSetup.Get();

        PayrollAnalysisMgt.AnalysisViewSelection(
          CurrPayrollAnalysisViewCode, PayrollAnalysisView, PayrollStatisticsBuffer,
          Dim1Filter, Dim2Filter, Dim3Filter, Dim4Filter);

        if (NewPayrollAnalysisCode <> '') and (NewPayrollAnalysisCode <> CurrPayrollAnalysisViewCode) then begin
            CurrPayrollAnalysisViewCode := NewPayrollAnalysisCode;
            PayrollAnalysisMgt.CheckAnalysisView(CurrPayrollAnalysisViewCode, PayrollAnalysisView);
            PayrollAnalysisMgt.SetPayrollAnalysisView(
              CurrPayrollAnalysisViewCode, PayrollAnalysisView, PayrollStatisticsBuffer,
              Dim1Filter, Dim2Filter, Dim3Filter, Dim4Filter);
        end;

        PayrollAnalysisMgt.SetLineAndColDim(
          PayrollAnalysisView, LineDimCode, LineDimOption, ColumnDimCode, ColumnDimOption);
        UpdateFilterFields;

        FindPeriod('');

        NoOfColumns := 32;
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        PayrollAnalysisView: Record "Payroll Analysis View";
        PayrollStatisticsBuffer: Record "Payroll Statistics Buffer";
        DimCodeBufferColumn: Record "Dimension Code Buffer";
        MATRIX_PeriodRecords: array[32] of Record Date;
        PayrollAnalysisMgt: Codeunit "Payroll Analysis Management";
        MatrixMgt: Codeunit "Matrix Management";
        PayrollAnalysisByDimMatrix: Page "Payroll Analysis by Dim Matrix";
        CurrPayrollAnalysisViewCode: Code[10];
        ValueType: Option "Payroll Amount","Taxable Amount";
        RoundingFactor: Option "None","1","1000","1000000";
        LineDimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4";
        ColumnDimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        UsePFAccumSystemFilter: Option " ",Yes,No;
        LineDimCode: Text[30];
        ColumnDimCode: Text[30];
        InternalDateFilter: Text;
        MatrixColumnCaptions: array[32] of Text[80];
        PeriodInitialized: Boolean;
        ShowColumnName: Boolean;
        ShowOppositeSign: Boolean;
        ElementTypeFilter1: Text;
        ElementFilter1: Text;
        ElementGroupFilter1: Text;
        EmployeeFilter1: Text;
        OrgUnitFilter1: Text;
        Dim1Filter1: Text;
        Dim2Filter1: Text;
        Dim3Filter1: Text;
        Dim4Filter1: Text;
        DateFilter1: Text;
        ElementTypeFilter: Text;
        ElementFilter: Text;
        ElementGroupFilter: Text;
        EmployeeFilter: Text;
        OrgUnitFilter: Text;
        DateFilter: Text;
        Dim1Filter: Text;
        Dim2Filter: Text;
        Dim3Filter: Text;
        Dim4Filter: Text;
        FirstColumn: Text;
        LastColumn: Text;
        FirstColumnDate: Date;
        LastColumnDate: Date;
        NoOfColumns: Integer;
        MATRIX_PKFirstRecInCurrSet: Text;
        MATRIX_CurrSetLength: Integer;
        MATRIX_CaptionRange: Text;
        MATRIX_SetWanted: Option Initial,Previous,Same,Next;
        NewPayrollAnalysisCode: Code[10];
        [InDataSet]
        Dim1FilterEnable: Boolean;
        [InDataSet]
        Dim2FilterEnable: Boolean;
        [InDataSet]
        Dim3FilterEnable: Boolean;
        [InDataSet]
        Dim4FilterEnable: Boolean;

    local procedure FindPeriod(SearchText: Code[10])
    var
        Employee: Record Employee;
        Calendar: Record Date;
        PeriodFormMgt: Codeunit PeriodFormManagement;
    begin
        if DateFilter <> '' then begin
            Calendar.SetFilter("Period Start", DateFilter);
            if not PeriodFormMgt.FindDate('+', Calendar, PeriodType) then
                PeriodFormMgt.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;
        PeriodFormMgt.FindDate(SearchText, Calendar, PeriodType);
        Employee.SetRange("Date Filter", Calendar."Period Start", Calendar."Period End");
        if Employee.GetRangeMin("Date Filter") = Employee.GetRangeMax("Date Filter") then
            Employee.SetRange("Date Filter", Employee.GetRangeMin("Date Filter"));
        InternalDateFilter := Employee.GetFilter("Date Filter");
        if (LineDimOption <> LineDimOption::Period) and (ColumnDimOption <> ColumnDimOption::Period) then
            DateFilter := InternalDateFilter;
    end;

    local procedure UpdateFilterFields()
    var
        PayrollAnalysisViewFilter: Record "Payroll Analysis View Filter";
    begin
        ElementFilter := PayrollAnalysisView."Payroll Element Filter";
        EmployeeFilter := PayrollAnalysisView."Employee Filter";
        Dim1Filter := '';
        Dim2Filter := '';
        Dim3Filter := '';
        Dim4Filter := '';

        Dim1FilterEnable := PayrollAnalysisView."Dimension 1 Code" <> '';
        Dim2FilterEnable := PayrollAnalysisView."Dimension 2 Code" <> '';
        Dim3FilterEnable := PayrollAnalysisView."Dimension 3 Code" <> '';
        Dim4FilterEnable := PayrollAnalysisView."Dimension 4 Code" <> '';

        if Dim1FilterEnable then
            if PayrollAnalysisViewFilter.Get(
                 PayrollAnalysisView.Code, PayrollAnalysisView."Dimension 1 Code")
            then
                Dim1Filter := PayrollAnalysisViewFilter."Dimension Value Filter";

        if Dim2FilterEnable then
            if PayrollAnalysisViewFilter.Get(
                 PayrollAnalysisView.Code, PayrollAnalysisView."Dimension 2 Code")
            then
                Dim2Filter := PayrollAnalysisViewFilter."Dimension Value Filter";

        if Dim3FilterEnable then
            if PayrollAnalysisViewFilter.Get(
                 PayrollAnalysisView.Code, PayrollAnalysisView."Dimension 3 Code")
            then
                Dim3Filter := PayrollAnalysisViewFilter."Dimension Value Filter";

        if Dim4FilterEnable then
            if PayrollAnalysisViewFilter.Get(
                 PayrollAnalysisView.Code, PayrollAnalysisView."Dimension 4 Code")
            then
                Dim4Filter := PayrollAnalysisViewFilter."Dimension Value Filter";
    end;

    [Scope('OnPrem')]
    procedure MATRIX_GenerateColumnCaptions(SetWanted: Option Initial,Previous,Same,Next)
    begin
        case ColumnDimOption of
            ColumnDimOption::Element:
                SetPointsElement(SetWanted);
            ColumnDimOption::"Element Group":
                SetPointsElementGroup(SetWanted);
            ColumnDimOption::Employee:
                SetPointsEmployee(SetWanted);
            ColumnDimOption::"Org. Unit":
                SetPointsOrgUnit(SetWanted);
            ColumnDimOption::Period:
                begin
                    FirstColumn := '';
                    LastColumn := '';
                    MatrixMgt.GeneratePeriodMatrixData(SetWanted, NoOfColumns, ShowColumnName, PeriodType, DateFilter, MATRIX_PKFirstRecInCurrSet,
                      MatrixColumnCaptions, MATRIX_CaptionRange, MATRIX_CurrSetLength, MATRIX_PeriodRecords);
                    if MATRIX_CurrSetLength > 0 then begin
                        FirstColumnDate := MATRIX_PeriodRecords[1]."Period Start";
                        LastColumnDate := MATRIX_PeriodRecords[MATRIX_CurrSetLength]."Period Start";
                        FirstColumn := MatrixColumnCaptions[1];
                        LastColumn := Format(MATRIX_PeriodRecords[MATRIX_CurrSetLength]."Period End");
                    end;
                end;
            ColumnDimOption::"Dimension 1":
                SetPointsDim(PayrollAnalysisView."Dimension 1 Code", Dim1Filter, SetWanted);
            ColumnDimOption::"Dimension 2":
                SetPointsDim(PayrollAnalysisView."Dimension 2 Code", Dim2Filter, SetWanted);
            ColumnDimOption::"Dimension 3":
                SetPointsDim(PayrollAnalysisView."Dimension 3 Code", Dim3Filter, SetWanted);
            ColumnDimOption::"Dimension 4":
                SetPointsDim(PayrollAnalysisView."Dimension 4 Code", Dim4Filter, SetWanted);
        end;
    end;

    local procedure SetPointsElement(SetWanted: Option Initial,Previous,Same,Next)
    var
        PayrollElement: Record "Payroll Element";
        RecRef: RecordRef;
        CaptionFieldNo: Integer;
    begin
        Clear(MatrixColumnCaptions);
        FirstColumn := '';
        LastColumn := '';
        PayrollElement.SetFilter(Code, ElementFilter);
        RecRef.GetTable(PayrollElement);
        RecRef.SetTable(PayrollElement);
        if ShowColumnName then
            CaptionFieldNo := PayrollElement.FieldNo(Description)
        else
            CaptionFieldNo := PayrollElement.FieldNo(Code);

        MatrixMgt.GenerateMatrixData(RecRef, SetWanted, NoOfColumns, CaptionFieldNo, MATRIX_PKFirstRecInCurrSet, MatrixColumnCaptions,
          MATRIX_CaptionRange, MATRIX_CurrSetLength);

        if MATRIX_CurrSetLength > 0 then begin
            FirstColumn := MatrixColumnCaptions[1];
            LastColumn := MatrixColumnCaptions[MATRIX_CurrSetLength];
        end;
    end;

    local procedure SetPointsElementGroup(SetWanted: Option Initial,Previous,Same,Next)
    var
        PayrollElementGroup: Record "Payroll Element Group";
        RecRef: RecordRef;
        CaptionFieldNo: Integer;
    begin
        Clear(MatrixColumnCaptions);
        FirstColumn := '';
        LastColumn := '';
        PayrollElementGroup.SetFilter(Code, ElementGroupFilter);
        RecRef.GetTable(PayrollElementGroup);
        RecRef.SetTable(PayrollElementGroup);
        if ShowColumnName then
            CaptionFieldNo := PayrollElementGroup.FieldNo(Name)
        else
            CaptionFieldNo := PayrollElementGroup.FieldNo(Code);

        MatrixMgt.GenerateMatrixData(RecRef, SetWanted, NoOfColumns, CaptionFieldNo, MATRIX_PKFirstRecInCurrSet, MatrixColumnCaptions,
          MATRIX_CaptionRange, MATRIX_CurrSetLength);

        if MATRIX_CurrSetLength > 0 then begin
            FirstColumn := MatrixColumnCaptions[1];
            LastColumn := MatrixColumnCaptions[MATRIX_CurrSetLength];
        end;
    end;

    local procedure SetPointsEmployee(SetWanted: Option Initial,Previous,Same,Next)
    var
        Employee: Record Employee;
        RecRef: RecordRef;
        CaptionFieldNo: Integer;
    begin
        Clear(MatrixColumnCaptions);
        FirstColumn := '';
        LastColumn := '';
        Employee.SetFilter("No.", EmployeeFilter);
        RecRef.GetTable(Employee);
        RecRef.SetTable(Employee);
        if ShowColumnName then
            CaptionFieldNo := Employee.FieldNo("Short Name")
        else
            CaptionFieldNo := Employee.FieldNo("No.");

        MatrixMgt.GenerateMatrixData(RecRef, SetWanted, NoOfColumns, CaptionFieldNo, MATRIX_PKFirstRecInCurrSet, MatrixColumnCaptions,
          MATRIX_CaptionRange, MATRIX_CurrSetLength);

        if MATRIX_CurrSetLength > 0 then begin
            FirstColumn := MatrixColumnCaptions[1];
            LastColumn := MatrixColumnCaptions[MATRIX_CurrSetLength];
        end;
    end;

    local procedure SetPointsOrgUnit(SetWanted: Option Initial,Previous,Same,Next)
    var
        OrgUnit: Record "Organizational Unit";
        RecRef: RecordRef;
        CaptionFieldNo: Integer;
    begin
        Clear(MatrixColumnCaptions);
        FirstColumn := '';
        LastColumn := '';
        OrgUnit.SetFilter(Code, OrgUnitFilter);
        RecRef.GetTable(OrgUnit);
        RecRef.SetTable(OrgUnit);
        if ShowColumnName then
            CaptionFieldNo := OrgUnit.FieldNo(Name)
        else
            CaptionFieldNo := OrgUnit.FieldNo(Code);

        MatrixMgt.GenerateMatrixData(RecRef, SetWanted, NoOfColumns, CaptionFieldNo, MATRIX_PKFirstRecInCurrSet, MatrixColumnCaptions,
          MATRIX_CaptionRange, MATRIX_CurrSetLength);

        if MATRIX_CurrSetLength > 0 then begin
            FirstColumn := MatrixColumnCaptions[1];
            LastColumn := MatrixColumnCaptions[MATRIX_CurrSetLength];
        end;
    end;

    local procedure SetPointsDim(DimensionCode: Code[20]; DimFilter: Text; SetWanted: Option Initial,Previous,Same,Next)
    var
        DimVal: Record "Dimension Value";
        MatrixMgt: Codeunit "Matrix Management";
        RecRef: RecordRef;
        CaptionFieldNo: Integer;
    begin
        Clear(MatrixColumnCaptions);
        FirstColumn := '';
        LastColumn := '';
        DimVal.SetRange("Dimension Code", DimensionCode);
        if DimFilter <> '' then
            DimVal.SetFilter(Code, DimFilter);
        RecRef.GetTable(DimVal);
        RecRef.SetTable(DimVal);

        if ShowColumnName then
            CaptionFieldNo := DimVal.FieldNo(Name)
        else
            CaptionFieldNo := DimVal.FieldNo(Code);

        MatrixMgt.GenerateMatrixData(RecRef, SetWanted, NoOfColumns, CaptionFieldNo, MATRIX_PKFirstRecInCurrSet, MatrixColumnCaptions,
          MATRIX_CaptionRange, MATRIX_CurrSetLength);

        if MATRIX_CurrSetLength > 0 then begin
            FirstColumn := MatrixColumnCaptions[1];
            LastColumn := MatrixColumnCaptions[MATRIX_CurrSetLength];
        end;
    end;

    [Scope('OnPrem')]
    procedure ShowMatrix()
    begin
        ApplyColumnFilter;
        if ColumnDimOption = ColumnDimOption::Period then begin
            FirstColumn := Format(FirstColumnDate);
            LastColumn := Format(LastColumnDate);
        end;

        PayrollAnalysisByDimMatrix.LoadVariables(PayrollAnalysisView,
          LineDimOption, ColumnDimOption, PeriodType, ValueType,
          RoundingFactor, MatrixColumnCaptions,
          ShowOppositeSign, PeriodInitialized, FirstColumn, LastColumn, MATRIX_CurrSetLength);

        PayrollAnalysisByDimMatrix.LoadFilters(
          ElementTypeFilter, ElementFilter, ElementGroupFilter, EmployeeFilter, OrgUnitFilter, UsePFAccumSystemFilter,
          Dim1Filter, Dim2Filter, Dim3Filter, Dim4Filter,
          DateFilter, InternalDateFilter);

        PayrollAnalysisByDimMatrix.RunModal;
    end;

    [Scope('OnPrem')]
    procedure ApplyColumnFilter()
    begin
        Clear(ElementTypeFilter1);
        Clear(ElementFilter1);
        Clear(ElementGroupFilter1);
        Clear(EmployeeFilter1);
        Clear(OrgUnitFilter1);
        Clear(DateFilter1);
        Clear(Dim1Filter1);
        Clear(Dim2Filter1);
        Clear(Dim3Filter1);
        Clear(Dim4Filter1);

        case ColumnDimOption of
            ColumnDimOption::Element:
                ApplyElementFilter;
            ColumnDimOption::"Element Group":
                ApplyElementGroupFilter;
            ColumnDimOption::Employee:
                ApplyEmployeeFilter;
            ColumnDimOption::"Org. Unit":
                ApplyOrgUnitFilter;
            ColumnDimOption::Period:
                ApplyPeriodFilter;
            ColumnDimOption::"Dimension 1":
                ApplyDim1Filter;
            ColumnDimOption::"Dimension 2":
                ApplyDim2Filter;
            ColumnDimOption::"Dimension 3":
                ApplyDim3Filter;
            ColumnDimOption::"Dimension 4":
                ApplyDim4Filter;
        end;
    end;

    local procedure ApplyElementFilter()
    begin
        ElementTypeFilter1 := ElementTypeFilter;
        if ElementFilter <> '' then
            ElementFilter1 := ElementFilter + '&';
        ElementFilter1 := ElementFilter1 + Format(FirstColumn) + '..' + Format(LastColumn);
        ElementGroupFilter1 := ElementGroupFilter;
        EmployeeFilter1 := EmployeeFilter;
        OrgUnitFilter1 := OrgUnitFilter;
        DateFilter1 := DateFilter;
        AssignDimFilters;
    end;

    local procedure ApplyElementGroupFilter()
    begin
        ElementTypeFilter1 := ElementTypeFilter;
        ElementFilter1 := ElementFilter;
        if ElementGroupFilter <> '' then
            ElementGroupFilter1 := ElementGroupFilter + '&';
        ElementGroupFilter1 := ElementGroupFilter1 + Format(FirstColumn) + '..' + Format(LastColumn);
        EmployeeFilter1 := EmployeeFilter;
        OrgUnitFilter1 := OrgUnitFilter;
        DateFilter1 := DateFilter;
        AssignDimFilters;
    end;

    local procedure ApplyEmployeeFilter()
    begin
        ElementTypeFilter1 := ElementTypeFilter;
        ElementFilter1 := ElementFilter;
        ElementGroupFilter1 := ElementGroupFilter;
        if EmployeeFilter <> '' then
            EmployeeFilter1 := EmployeeFilter + '&';
        EmployeeFilter1 := EmployeeFilter1 + Format(FirstColumn) + '..' + Format(LastColumn);
        OrgUnitFilter1 := OrgUnitFilter;
        DateFilter1 := DateFilter;
        AssignDimFilters;
    end;

    local procedure ApplyOrgUnitFilter()
    begin
        ElementTypeFilter1 := ElementTypeFilter;
        ElementFilter1 := ElementFilter;
        ElementGroupFilter1 := ElementGroupFilter;
        EmployeeFilter1 := EmployeeFilter;
        if OrgUnitFilter <> '' then
            OrgUnitFilter1 := OrgUnitFilter + '&';
        OrgUnitFilter1 := OrgUnitFilter1 + Format(FirstColumn) + '..' + Format(LastColumn);
        DateFilter1 := DateFilter;
        AssignDimFilters;
    end;

    local procedure ApplyPeriodFilter()
    begin
        ElementTypeFilter1 := ElementTypeFilter;
        ElementFilter1 := ElementFilter;
        ElementGroupFilter1 := ElementGroupFilter;
        EmployeeFilter1 := EmployeeFilter;
        OrgUnitFilter1 := OrgUnitFilter;
        if DateFilter <> '' then
            DateFilter1 := DateFilter
        else
            DateFilter1 := Format(FirstColumn) + '..' + Format(LastColumn);
        AssignDimFilters;
    end;

    local procedure ApplyDim1Filter()
    begin
        AssignNonDimFilters;
        if Dim1Filter <> '' then
            Dim1Filter1 := Dim1Filter + '&';
        Dim1Filter1 := Dim1Filter1 + Format(FirstColumn) + '..' + Format(LastColumn);
        Dim2Filter1 := Dim2Filter;
        Dim3Filter1 := Dim3Filter;
        Dim4Filter1 := Dim4Filter;
    end;

    local procedure ApplyDim2Filter()
    begin
        AssignNonDimFilters;
        Dim1Filter1 := Dim1Filter;
        if Dim2Filter <> '' then
            Dim2Filter1 := Dim2Filter + '&';
        Dim2Filter1 := Dim2Filter1 + Format(FirstColumn) + '..' + Format(LastColumn);
        Dim3Filter1 := Dim3Filter;
        Dim4Filter1 := Dim4Filter;
    end;

    local procedure ApplyDim3Filter()
    begin
        AssignNonDimFilters;
        Dim1Filter1 := Dim1Filter;
        Dim2Filter1 := Dim2Filter;
        if Dim3Filter <> '' then
            Dim3Filter1 := Dim3Filter + '&';
        Dim3Filter1 := Dim3Filter1 + Format(FirstColumn) + '..' + Format(LastColumn);
        Dim4Filter1 := Dim4Filter;
    end;

    local procedure ApplyDim4Filter()
    begin
        AssignNonDimFilters;
        Dim1Filter1 := Dim1Filter;
        Dim2Filter1 := Dim2Filter;
        Dim3Filter1 := Dim3Filter;
        if Dim4Filter <> '' then
            Dim4Filter1 := Dim4Filter + '&';
        Dim4Filter1 := Dim4Filter1 + Format(FirstColumn) + '..' + Format(LastColumn);
    end;

    [Scope('OnPrem')]
    procedure AssignDimFilters()
    begin
        Dim1Filter1 := Dim1Filter;
        Dim2Filter1 := Dim2Filter;
        Dim3Filter1 := Dim3Filter;
        Dim4Filter1 := Dim4Filter;
    end;

    [Scope('OnPrem')]
    procedure AssignNonDimFilters()
    begin
        ElementTypeFilter1 := ElementTypeFilter;
        ElementFilter1 := ElementFilter;
        ElementGroupFilter1 := ElementGroupFilter;
        EmployeeFilter1 := EmployeeFilter;
        OrgUnitFilter1 := OrgUnitFilter;
        DateFilter1 := DateFilter;
    end;

    [Scope('OnPrem')]
    procedure ClearPoints()
    begin
        Clear(FirstColumn);
        Clear(LastColumn);
    end;

    local procedure CurrPayrollAnalysisViewCodeOnA()
    begin
        PayrollAnalysisMgt.SetPayrollAnalysisView(
          CurrPayrollAnalysisViewCode, PayrollAnalysisView, PayrollStatisticsBuffer,
          Dim1Filter, Dim2Filter, Dim3Filter, Dim4Filter);
        PayrollAnalysisMgt.SetLineAndColDim(
          PayrollAnalysisView, LineDimCode, LineDimOption, ColumnDimCode, ColumnDimOption);
        UpdateFilterFields;
        CurrPage.Update(false);
    end;

    local procedure LineDimCodeOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure ColumnDimCodeOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure Dim2FilterOnAfterValidate()
    begin
        CurrPage.Update;
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
    end;

    local procedure Dim1FilterOnAfterValidate()
    begin
        CurrPage.Update;
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
    end;

    local procedure Dim3FilterOnAfterValidate()
    begin
        CurrPage.Update;
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
    end;

    local procedure ElementTypeFilterOnAfterValida()
    begin
        PayrollStatisticsBuffer.SetFilter("Element Type Filter", ElementTypeFilter);
        CurrPage.Update(false);
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
    end;

    local procedure DateFilterOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure Dim4FilterOnAfterValidate()
    begin
        CurrPage.Update;
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
    end;

    local procedure ElementFilterOnAfterValidate()
    begin
        PayrollStatisticsBuffer.SetFilter("Element Filter", ElementFilter);
        CurrPage.Update(false);
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
    end;

    local procedure ElementGroupFilterOnAfterValid()
    begin
        PayrollStatisticsBuffer.SetFilter("Element Group Filter", ElementGroupFilter);
        CurrPage.Update(false);
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
    end;

    local procedure OrgUnitFilterOnAfterValidate()
    begin
        PayrollStatisticsBuffer.SetFilter("Org. Unit Filter", OrgUnitFilter);
        CurrPage.Update(false);
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
    end;

    local procedure EmployeeFilterOnAfterValidate()
    begin
        PayrollStatisticsBuffer.SetFilter("Employee Filter", EmployeeFilter);
        CurrPage.Update(false);
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Initial);
    end;

    local procedure UsePFAccumSystemFilterOnAfterV()
    begin
        case UsePFAccumSystemFilter of
            UsePFAccumSystemFilter::" ":
                PayrollStatisticsBuffer.SetRange("Use PF Accum. System Filter");
            UsePFAccumSystemFilter::Yes:
                PayrollStatisticsBuffer.SetRange("Use PF Accum. System Filter", true);
            UsePFAccumSystemFilter::No:
                PayrollStatisticsBuffer.SetRange("Use PF Accum. System Filter", false);
        end;
        CurrPage.Update(false);
    end;

    local procedure ShowColumnNameOnAfterValidate()
    begin
        MATRIX_GenerateColumnCaptions(MATRIX_SetWanted::Same);
    end;
}

