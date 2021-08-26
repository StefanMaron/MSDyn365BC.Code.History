page 490 "Acc. Schedule Overview"
{
    Caption = 'Acc. Schedule Overview';
    DataCaptionExpression = CurrentSchedName + ' - ' + CurrentColumnName;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Column,Period';
    SaveValues = true;
    ShowFilter = false;
    SourceTable = "Acc. Schedule Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(CurrentSchedName; CurrentSchedName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Schedule Name';
                    Importance = Promoted;
                    Lookup = true;
                    LookupPageID = "Account Schedule Names";
                    ToolTip = 'Specifies the name of the account schedule to be shown in the window.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Result: Boolean;
                    begin
                        Result := AccSchedManagement.LookupName(CurrentSchedName, Text);
                        CurrentSchedName := Text;
                        CurrentSchedNameOnAfterValidate;
                        exit(Result);
                    end;

                    trigger OnValidate()
                    begin
                        AccSchedManagement.CheckName(CurrentSchedName);
                        CurrentSchedNameOnAfterValidate;
                    end;
                }
                field(CurrentColumnName; CurrentColumnName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Column Layout Name';
                    Lookup = true;
                    TableRelation = "Column Layout Name".Name;
                    ToolTip = 'Specifies the name of the column layout that you want to use in the window.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Result: Boolean;
                    begin
                        Result := AccSchedManagement.LookupColumnName(CurrentColumnName, Text);
                        CurrentColumnName := Text;
                        CurrentColumnNameOnAfterValidate;
                        exit(Result);
                    end;

                    trigger OnValidate()
                    begin
                        AccSchedManagement.CheckColumnName(CurrentColumnName);
                        CurrentColumnNameOnAfterValidate;
                    end;
                }
                field(UseAmtsInAddCurr; UseAmtsInAddCurr)
                {
                    ApplicationArea = Suite;
                    Caption = 'Show Amounts in Add. Reporting Currency';
                    MultiLine = true;
                    ToolTip = 'Specifies if the reported amounts are shown in the additional reporting currency.';
                    Visible = UseAmtsInAddCurrVisible;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View by';
                    Importance = Promoted;
                    OptionCaption = 'Day,Week,Month,Quarter,Year,Accounting Period';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        AccSchedManagement.FindPeriod(Rec, '', PeriodType);
                        DateFilter := GetFilter("Date Filter");
                        CurrPage.Update();
                    end;
                }
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter';
                    Importance = Promoted;
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        SetFilter("Date Filter", DateFilter);
                        DateFilter := GetFilter("Date Filter");
                        CurrPage.Update();
                    end;
                }
            }
            group("Dimension Filters")
            {
                Caption = 'Dimension Filters';
                field(Dim1Filter; Dim1Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = FormGetCaptionClass(1);
                    Caption = 'Dimension 1 Filter';
                    Enabled = Dim1FilterEnable;
                    Importance = Promoted;
                    ToolTip = 'Specifies a filter for the Dimension 1 for which entries will be shown in the matrix window.';
                    Visible = Dim1FilterEnable;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimValue: Record "Dimension Value";
                    begin
                        exit(DimValue.LookUpDimFilter(AnalysisView."Dimension 1 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        SetDimFilters(1, Dim1Filter);
                    end;
                }
                field(Dim2Filter; Dim2Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = FormGetCaptionClass(2);
                    Caption = 'Dimension 2 Filter';
                    Enabled = Dim2FilterEnable;
                    Importance = Promoted;
                    ToolTip = 'Specifies a filter for the Dimension 2 for which entries will be shown in the matrix window.';
                    Visible = Dim2FilterEnable;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimValue: Record "Dimension Value";
                    begin
                        exit(DimValue.LookUpDimFilter(AnalysisView."Dimension 2 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        SetDimFilters(2, Dim2Filter);
                    end;
                }
                field(Dim3Filter; Dim3Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = FormGetCaptionClass(3);
                    Caption = 'Dimension 3 Filter';
                    Enabled = Dim3FilterEnable;
                    Importance = Promoted;
                    ToolTip = 'Specifies a filter for the Dimension 3 for which entries will be shown in the matrix window.';
                    Visible = Dim3FilterEnable;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimValue: Record "Dimension Value";
                    begin
                        exit(DimValue.LookUpDimFilter(AnalysisView."Dimension 3 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        SetDimFilters(3, Dim3Filter);
                    end;
                }
                field(Dim4Filter; Dim4Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = FormGetCaptionClass(4);
                    Caption = 'Dimension 4 Filter';
                    Enabled = Dim4FilterEnable;
                    Importance = Promoted;
                    ToolTip = 'Specifies a filter for the Dimension 4 for which entries will be shown in the matrix window.';
                    Visible = Dim4FilterEnable;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimValue: Record "Dimension Value";
                    begin
                        exit(DimValue.LookUpDimFilter(AnalysisView."Dimension 4 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        SetDimFilters(4, Dim4Filter);
                    end;
                }
                field(CostCenterFilter; CostCenterFilter)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Center Filter';
                    Importance = Additional;
                    ToolTip = 'Specifies a cost center for which you want to view account amounts.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CostCenter: Record "Cost Center";
                    begin
                        exit(CostCenter.LookupCostCenterFilter(Text));
                    end;

                    trigger OnValidate()
                    begin
                        if CostCenterFilter = '' then
                            SetRange("Cost Center Filter")
                        else
                            SetFilter("Cost Center Filter", CostCenterFilter);

                        OnAfterValidateCostCenterFilter(Rec, CostCenterFilter, Dim1Filter);
                        CurrPage.Update();
                    end;
                }
                field(CostObjectFilter; CostObjectFilter)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Object Filter';
                    Importance = Additional;
                    ToolTip = 'Specifies a cost object for which you want to view account amounts.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CostObject: Record "Cost Object";
                    begin
                        exit(CostObject.LookupCostObjectFilter(Text));
                    end;

                    trigger OnValidate()
                    begin
                        if CostObjectFilter = '' then
                            SetRange("Cost Object Filter")
                        else
                            SetFilter("Cost Object Filter", CostObjectFilter);

                        OnAfterValidateCostObjectFilter(Rec, CostObjectFilter, Dim2Filter);
                        CurrPage.Update();
                    end;
                }
                field(CashFlowFilter; CashFlowFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Cash Flow Filter';
                    Importance = Additional;
                    ToolTip = 'Specifies a dimension filter for the cash flow, for which you want to view account amounts.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CashFlowForecast: Record "Cash Flow Forecast";
                    begin
                        exit(CashFlowForecast.LookupCashFlowFilter(Text));
                    end;

                    trigger OnValidate()
                    begin
                        if CashFlowFilter = '' then
                            SetRange("Cash Flow Forecast Filter")
                        else
                            SetFilter("Cash Flow Forecast Filter", CashFlowFilter);
                        CurrPage.Update();
                    end;
                }
                field("G/LBudgetFilter"; GLBudgetFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'G/L Budget Filter';
                    Importance = Promoted;
                    ToolTip = 'Specifies a code for a general ledger budget that the account schedule line will be filtered on.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Result: Boolean;
                    begin
                        Result := LookupGLBudgetFilter(Text);
                        if Result then begin
                            SetFilter("G/L Budget Filter", Text);
                            Text := GetFilter("G/L Budget Filter");
                        end;
                        exit(Result);
                    end;

                    trigger OnValidate()
                    begin
                        if GLBudgetFilter = '' then
                            SetRange("G/L Budget Filter")
                        else
                            SetFilter("G/L Budget Filter", GLBudgetFilter);
                        CurrPage.Update();
                    end;
                }
                field(CostBudgetFilter; CostBudgetFilter)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Budget Filter';
                    Importance = Additional;
                    ToolTip = 'Specifies a code for a cost budget that the account schedule line will be filtered on.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Result: Boolean;
                    begin
                        Result := LookupCostBudgetFilter(Text);
                        if Result then begin
                            SetFilter("Cost Budget Filter", Text);
                            Text := GetFilter("Cost Budget Filter");
                        end;
                        exit(Result);
                    end;

                    trigger OnValidate()
                    begin
                        if CostBudgetFilter = '' then
                            SetRange("Cost Budget Filter")
                        else
                            SetFilter("Cost Budget Filter", CostBudgetFilter);
                        CurrPage.Update();
                    end;
                }
            }
            repeater(Control48)
            {
                Editable = false;
                IndentationColumn = Indentation;
                IndentationControls = Description;
                ShowCaption = false;
                field("Row No."; "Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that identifies the line.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = Bold;
                    ToolTip = 'Specifies text that will appear on the account schedule line.';
                }
                field(ColumnValues1; ColumnValues[1])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(1);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[1];
                    StyleExpr = ColumnStyle1;

                    trigger OnDrillDown()
                    begin
                        DrillDown(1);
                    end;
                }
                field(ColumnValues2; ColumnValues[2])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(2);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[2];
                    StyleExpr = ColumnStyle2;
                    Visible = NoOfColumns >= 2;

                    trigger OnDrillDown()
                    begin
                        DrillDown(2);
                    end;
                }
                field(ColumnValues3; ColumnValues[3])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(3);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[3];
                    StyleExpr = ColumnStyle3;
                    Visible = NoOfColumns >= 3;

                    trigger OnDrillDown()
                    begin
                        DrillDown(3);
                    end;
                }
                field(ColumnValues4; ColumnValues[4])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(4);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[4];
                    StyleExpr = ColumnStyle4;
                    Visible = NoOfColumns >= 4;

                    trigger OnDrillDown()
                    begin
                        DrillDown(4);
                    end;
                }
                field(ColumnValues5; ColumnValues[5])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(5);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[5];
                    StyleExpr = ColumnStyle5;
                    Visible = NoOfColumns >= 5;

                    trigger OnDrillDown()
                    begin
                        DrillDown(5);
                    end;
                }
                field(ColumnValues6; ColumnValues[6])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(6);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[6];
                    StyleExpr = ColumnStyle6;
                    Visible = NoOfColumns >= 6;

                    trigger OnDrillDown()
                    begin
                        DrillDown(6);
                    end;
                }
                field(ColumnValues7; ColumnValues[7])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(7);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[7];
                    StyleExpr = ColumnStyle7;
                    Visible = NoOfColumns >= 7;

                    trigger OnDrillDown()
                    begin
                        DrillDown(7);
                    end;
                }
                field(ColumnValues8; ColumnValues[8])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(8);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[8];
                    StyleExpr = ColumnStyle8;
                    Visible = NoOfColumns >= 8;

                    trigger OnDrillDown()
                    begin
                        DrillDown(8);
                    end;
                }
                field(ColumnValues9; ColumnValues[9])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(9);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[9];
                    StyleExpr = ColumnStyle9;
                    Visible = NoOfColumns >= 9;

                    trigger OnDrillDown()
                    begin
                        DrillDown(9);
                    end;
                }
                field(ColumnValues10; ColumnValues[10])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(10);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[10];
                    StyleExpr = ColumnStyle10;
                    Visible = NoOfColumns >= 10;

                    trigger OnDrillDown()
                    begin
                        DrillDown(10);
                    end;
                }
                field(ColumnValues11; ColumnValues[11])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(11);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[11];
                    StyleExpr = ColumnStyle11;
                    Visible = NoOfColumns >= 11;

                    trigger OnDrillDown()
                    begin
                        DrillDown(11);
                    end;
                }
                field(ColumnValues12; ColumnValues[12])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(12);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[12];
                    StyleExpr = ColumnStyle12;
                    Visible = NoOfColumns >= 12;

                    trigger OnDrillDown()
                    begin
                        DrillDown(12);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
            }
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Print the information in the window. A print request window opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    AccSched: Report "Account Schedule";
                    DateFilter2: Text;
                    GLBudgetFilter2: Text;
                    BusUnitFilter: Text;
                    CostBudgetFilter2: Text;
                    IsHandled: Boolean;
                begin
                    IsHandled := false;
                    OnBeforePrint(Rec, CurrentColumnName, IsHandled);
                    if IsHandled then
                        exit;

                    AccSched.SetAccSchedName(CurrentSchedName);
                    AccSched.SetColumnLayoutName(CurrentColumnName);
                    DateFilter2 := GetFilter("Date Filter");
                    GLBudgetFilter2 := GetFilter("G/L Budget Filter");
                    CostBudgetFilter2 := GetFilter("Cost Budget Filter");
                    BusUnitFilter := GetFilter("Business Unit Filter");
                    AccSched.SetFilters(DateFilter2, GLBudgetFilter2, CostBudgetFilter2, BusUnitFilter, Dim1Filter, Dim2Filter, Dim3Filter, Dim4Filter);
                    AccSched.Run;
                end;
            }
            action(PreviousColumn)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Column';
                Image = PreviousRecord;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Go to the previous column.';

                trigger OnAction()
                begin
                    AdjustColumnOffset(-1);
                end;
            }
            action(NextPeriod)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Period';
                Image = NextRecord;
                Promoted = true;
                PromotedCategory = Category5;
                PromotedOnly = true;
                ToolTip = 'Show the information based on the next period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    AccSchedManagement.FindPeriod(Rec, '>=', PeriodType);
                    DateFilter := GetFilter("Date Filter");
                end;
            }
            action(PreviousPeriod)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Period';
                Image = PreviousRecord;
                Promoted = true;
                PromotedCategory = Category5;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Show the information based on the previous period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    AccSchedManagement.FindPeriod(Rec, '<=', PeriodType);
                    DateFilter := GetFilter("Date Filter");
                end;
            }
            action(NextColumn)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Column';
                Image = NextRecord;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedOnly = true;
                ToolTip = 'Go to the next column.';

                trigger OnAction()
                begin
                    AdjustColumnOffset(1);
                end;
            }
            action(Recalculate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Recalculate';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Update the account schedule overview based on recent changes.';

                trigger OnAction()
                begin
                    AccSchedManagement.ForceRecalculate(true);
                end;
            }
            group(Excel)
            {
                Caption = 'Excel';
                group("Export to Excel")
                {
                    Caption = 'Export to Excel';
                    Image = ExportToExcel;
                    action("Create New Document")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create New Document';
                        Image = ExportToExcel;
                        ToolTip = 'Open the account schedule overview in a new Excel workbook. This creates an Excel workbook on your device.';

                        trigger OnAction()
                        var
                            ExportAccSchedToExcel: Report "Export Acc. Sched. to Excel";
                        begin
                            ExportAccSchedToExcel.SetOptions(Rec, CurrentColumnName, UseAmtsInAddCurr);
                            ExportAccSchedToExcel.Run;
                        end;
                    }
                    action("Update Existing Document")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Update Copy Of Existing Document';
                        Image = ExportToExcel;
                        ToolTip = 'Refresh the data in the copy of the existing Excel workbook, and download it to your device. You must specify the workbook that you want to update.';

                        trigger OnAction()
                        var
                            ExportAccSchedToExcel: Report "Export Acc. Sched. to Excel";
                        begin
                            ExportAccSchedToExcel.SetOptions(Rec, CurrentColumnName, UseAmtsInAddCurr);
                            ExportAccSchedToExcel.SetUpdateExistingWorksheet(true);
                            ExportAccSchedToExcel.Run;
                        end;
                    }
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        ColumnNo: Integer;
    begin
        Clear(ColumnValues);

        if (Totaling = '') or (not TempColumnLayout.FindSet) then
            exit;

        repeat
            ColumnNo := ColumnNo + 1;
            if (ColumnNo > ColumnOffset) and (ColumnNo - ColumnOffset <= ArrayLen(ColumnValues)) then begin
                ColumnValues[ColumnNo - ColumnOffset] :=
                  RoundNone(
                    MatrixMgt.RoundValue(
                      AccSchedManagement.CalcCell(Rec, TempColumnLayout, UseAmtsInAddCurr),
                      TempColumnLayout."Rounding Factor"),
                    TempColumnLayout."Rounding Factor");
                ColumnLayoutArr[ColumnNo - ColumnOffset] := TempColumnLayout;
                GetStyle(ColumnNo - ColumnOffset, "Line No.", TempColumnLayout."Line No.");
            end;
        until TempColumnLayout.Next() = 0;
        AccSchedManagement.ForceRecalculate(false);
    end;

    trigger OnInit()
    begin
        Dim4FilterEnable := true;
        Dim3FilterEnable := true;
        Dim2FilterEnable := true;
        Dim1FilterEnable := true;
    end;

    trigger OnOpenPage()
    begin
        UseAmtsInAddCurr := false;
        GLSetup.Get();
        UseAmtsInAddCurrVisible := GLSetup."Additional Reporting Currency" <> '';
        if NewCurrentSchedName <> '' then
            CurrentSchedName := NewCurrentSchedName;
        if CurrentSchedName = '' then
            CurrentSchedName := Text000;
        if NewCurrentColumnName <> '' then
            CurrentColumnName := NewCurrentColumnName;
        if CurrentColumnName = '' then
            CurrentColumnName := Text000;
        if NewPeriodTypeSet then
            PeriodType := ModifiedPeriodType;

        AccSchedManagement.CopyColumnsToTemp(CurrentColumnName, TempColumnLayout);
        AccSchedManagement.OpenSchedule(CurrentSchedName, Rec);
        AccSchedManagement.OpenColumns(CurrentColumnName, TempColumnLayout);
        AccSchedManagement.CheckAnalysisView(CurrentSchedName, CurrentColumnName, true);
        UpdateColumnCaptions;
        if AccSchedName.Get(CurrentSchedName) then
            if AccSchedName."Analysis View Name" <> '' then
                AnalysisView.Get(AccSchedName."Analysis View Name")
            else begin
                Clear(AnalysisView);
                AnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                AnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
            end;

        AccSchedManagement.FindPeriod(Rec, '', PeriodType);
        SetFilter(Show, '<>%1', Show::No);
        SetRange("Dimension 1 Filter");
        SetRange("Dimension 2 Filter");
        SetRange("Dimension 3 Filter");
        SetRange("Dimension 4 Filter");
        SetRange("Cost Center Filter");
        SetRange("Cost Object Filter");
        SetRange("Cash Flow Forecast Filter");
        SetRange("Cost Budget Filter");
        SetRange("G/L Budget Filter");
        UpdateDimFilterControls;
        DateFilter := GetFilter("Date Filter");

        OnBeforeCurrentColumnNameOnAfterValidate(CurrentColumnName);
    end;

    var
        Text000: Label 'DEFAULT';
        Text005: Label '1,6,,Dimension %1 Filter';
        TempColumnLayout: Record "Column Layout" temporary;
        ColumnLayoutArr: array[12] of Record "Column Layout";
        AccSchedName: Record "Acc. Schedule Name";
        AnalysisView: Record "Analysis View";
        GLSetup: Record "General Ledger Setup";
        AccSchedManagement: Codeunit AccSchedManagement;
        MatrixMgt: Codeunit "Matrix Management";
        DimensionManagement: Codeunit DimensionManagement;
        CurrentSchedName: Code[10];
        NewCurrentSchedName: Code[10];
        NewCurrentColumnName: Code[10];
        ColumnValues: array[12] of Decimal;
        ColumnCaptions: array[12] of Text[80];
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        UseAmtsInAddCurrVisible: Boolean;
        UseAmtsInAddCurr: Boolean;
        Dim1Filter: Text;
        Dim2Filter: Text;
        Dim3Filter: Text;
        Dim4Filter: Text;
        CostCenterFilter: Text;
        CostObjectFilter: Text;
        CashFlowFilter: Text;
        NoOfColumns: Integer;
        ColumnOffset: Integer;
        [InDataSet]
        Dim1FilterEnable: Boolean;
        [InDataSet]
        Dim2FilterEnable: Boolean;
        [InDataSet]
        Dim3FilterEnable: Boolean;
        [InDataSet]
        Dim4FilterEnable: Boolean;
        GLBudgetFilter: Text;
        CostBudgetFilter: Text;
        DateFilter: Text;
        ModifiedPeriodType: Option;
        NewPeriodTypeSet: Boolean;
        [InDataSet]
        ColumnStyle1: Text;
        [InDataSet]
        ColumnStyle2: Text;
        [InDataSet]
        ColumnStyle3: Text;
        [InDataSet]
        ColumnStyle4: Text;
        [InDataSet]
        ColumnStyle5: Text;
        [InDataSet]
        ColumnStyle6: Text;
        [InDataSet]
        ColumnStyle7: Text;
        [InDataSet]
        ColumnStyle8: Text;
        [InDataSet]
        ColumnStyle9: Text;
        [InDataSet]
        ColumnStyle10: Text;
        [InDataSet]
        ColumnStyle11: Text;
        [InDataSet]
        ColumnStyle12: Text;

    protected var
        CurrentColumnName: Code[10];

    procedure SetAccSchedName(NewAccSchedName: Code[10])
    var
        AccSchedName: Record "Acc. Schedule Name";
    begin
        NewCurrentSchedName := NewAccSchedName;
        if AccSchedName.Get(NewCurrentSchedName) then
            if AccSchedName."Default Column Layout" <> '' then
                NewCurrentColumnName := AccSchedName."Default Column Layout";
    end;

    procedure SetPeriodType(NewPeriodType: Option)
    begin
        ModifiedPeriodType := NewPeriodType;
        NewPeriodTypeSet := true;
    end;

    local procedure SetDimFilters(DimNo: Integer; DimValueFilter: Text)
    begin
        case DimNo of
            1:
                if DimValueFilter = '' then
                    SetRange("Dimension 1 Filter")
                else begin
                    DimensionManagement.ResolveDimValueFilter(DimValueFilter, AnalysisView."Dimension 1 Code");
                    SetFilter("Dimension 1 Filter", DimValueFilter);
                end;
            2:
                if DimValueFilter = '' then
                    SetRange("Dimension 2 Filter")
                else begin
                    DimensionManagement.ResolveDimValueFilter(DimValueFilter, AnalysisView."Dimension 2 Code");
                    SetFilter("Dimension 2 Filter", DimValueFilter);
                end;
            3:
                if DimValueFilter = '' then
                    SetRange("Dimension 3 Filter")
                else begin
                    DimensionManagement.ResolveDimValueFilter(DimValueFilter, AnalysisView."Dimension 3 Code");
                    SetFilter("Dimension 3 Filter", DimValueFilter);
                end;
            4:
                if DimValueFilter = '' then
                    SetRange("Dimension 4 Filter")
                else begin
                    DimensionManagement.ResolveDimValueFilter(DimValueFilter, AnalysisView."Dimension 4 Code");
                    SetFilter("Dimension 4 Filter", DimValueFilter);
                end;
        end;

        OnAfterSetDimFilters(Rec, DimNo, DimValueFilter, CostCenterFilter, CostObjectFilter);
        CurrPage.Update();
    end;

    local procedure FormGetCaptionClass(DimNo: Integer): Text[250]
    begin
        case DimNo of
            1:
                begin
                    if AnalysisView."Dimension 1 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 1 Code");

                    exit(StrSubstNo(Text005, DimNo));
                end;
            2:
                begin
                    if AnalysisView."Dimension 2 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 2 Code");

                    exit(StrSubstNo(Text005, DimNo));
                end;
            3:
                begin
                    if AnalysisView."Dimension 3 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 3 Code");

                    exit(StrSubstNo(Text005, DimNo));
                end;
            4:
                begin
                    if AnalysisView."Dimension 4 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 4 Code");

                    exit(StrSubstNo(Text005, DimNo));
                end;
            5:
                exit(FieldCaption("Date Filter"));
            6:
                exit(FieldCaption("Cash Flow Forecast Filter"));
        end;
    end;

    local procedure DrillDown(ColumnNo: Integer)
    begin
        TempColumnLayout := ColumnLayoutArr[ColumnNo];
        AccSchedManagement.DrillDownFromOverviewPage(TempColumnLayout, Rec, PeriodType);
    end;

    local procedure UpdateColumnCaptions()
    var
        ColumnNo: Integer;
        i: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateColumnCaptions(ColumnCaptions, ColumnOffset, TempColumnLayout, NoOfColumns, IsHandled);
        if IsHandled then
            exit;

        Clear(ColumnCaptions);
        if TempColumnLayout.FindSet then
            repeat
                ColumnNo := ColumnNo + 1;
                if (ColumnNo > ColumnOffset) and (ColumnNo - ColumnOffset <= ArrayLen(ColumnCaptions)) then
                    ColumnCaptions[ColumnNo - ColumnOffset] := TempColumnLayout."Column Header";
            until (ColumnNo - ColumnOffset = ArrayLen(ColumnCaptions)) or (TempColumnLayout.Next() = 0);
        // Set unused columns to blank to prevent RTC to display control ID as caption
        for i := ColumnNo - ColumnOffset + 1 to ArrayLen(ColumnCaptions) do
            ColumnCaptions[i] := ' ';
        NoOfColumns := ColumnNo;
    end;

    local procedure AdjustColumnOffset(Delta: Integer)
    var
        OldColumnOffset: Integer;
    begin
        OldColumnOffset := ColumnOffset;
        ColumnOffset := ColumnOffset + Delta;
        if ColumnOffset + 12 > TempColumnLayout.Count then
            ColumnOffset := TempColumnLayout.Count - 12;
        if ColumnOffset < 0 then
            ColumnOffset := 0;
        if ColumnOffset <> OldColumnOffset then begin
            UpdateColumnCaptions;
            CurrPage.Update(false);
        end;
    end;

    local procedure UpdateDimFilterControls()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDimFilterControls(Rec, AnalysisView, IsHandled);
        if IsHandled then
            exit;

        Dim1Filter := GetFilter("Dimension 1 Filter");
        Dim2Filter := GetFilter("Dimension 2 Filter");
        Dim3Filter := GetFilter("Dimension 3 Filter");
        Dim4Filter := GetFilter("Dimension 4 Filter");
        CostCenterFilter := '';
        CostObjectFilter := '';
        CashFlowFilter := '';
        Dim1FilterEnable := AnalysisView."Dimension 1 Code" <> '';
        Dim2FilterEnable := AnalysisView."Dimension 2 Code" <> '';
        Dim3FilterEnable := AnalysisView."Dimension 3 Code" <> '';
        Dim4FilterEnable := AnalysisView."Dimension 4 Code" <> '';
        GLBudgetFilter := '';
        CostBudgetFilter := '';

        OnAfterUpdateDimFilterControls();
    end;

    local procedure CurrentSchedNameOnAfterValidate()
    var
        AccSchedName: Record "Acc. Schedule Name";
        PrevAnalysisView: Record "Analysis View";
    begin
        CurrPage.SaveRecord;
        AccSchedManagement.SetName(CurrentSchedName, Rec);
        if AccSchedName.Get(CurrentSchedName) then begin
            if (AccSchedName."Default Column Layout" <> '') and
               (CurrentColumnName <> AccSchedName."Default Column Layout")
            then begin
                CurrentColumnName := AccSchedName."Default Column Layout";
                CurrentColumnNameOnAfterValidate;
            end else
                AccSchedManagement.CheckAnalysisView(CurrentSchedName, CurrentColumnName, true);
        end else
            AccSchedManagement.CheckAnalysisView(CurrentSchedName, CurrentColumnName, true);

        if AccSchedName."Analysis View Name" <> AnalysisView.Code then begin
            PrevAnalysisView := AnalysisView;
            if AccSchedName."Analysis View Name" <> '' then
                AnalysisView.Get(AccSchedName."Analysis View Name")
            else begin
                Clear(AnalysisView);
                AnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                AnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
            end;
            if PrevAnalysisView."Dimension 1 Code" <> AnalysisView."Dimension 1 Code" then
                SetRange("Dimension 1 Filter");
            if PrevAnalysisView."Dimension 2 Code" <> AnalysisView."Dimension 2 Code" then
                SetRange("Dimension 2 Filter");
            if PrevAnalysisView."Dimension 3 Code" <> AnalysisView."Dimension 3 Code" then
                SetRange("Dimension 3 Filter");
            if PrevAnalysisView."Dimension 4 Code" <> AnalysisView."Dimension 4 Code" then
                SetRange("Dimension 4 Filter");
        end;
        UpdateDimFilterControls;

        CurrPage.Update(false);
    end;

    local procedure CurrentColumnNameOnAfterValidate()
    begin
        OnBeforeCurrentColumnNameOnAfterValidate(CurrentColumnName);

        AccSchedManagement.CopyColumnsToTemp(CurrentColumnName, TempColumnLayout);
        AccSchedManagement.SetColumnName(CurrentColumnName, TempColumnLayout);
        AccSchedManagement.CheckAnalysisView(CurrentSchedName, CurrentColumnName, true);
        ColumnOffset := 0;
        UpdateColumnCaptions;
        CurrPage.Update(false);
    end;

    procedure FormatStr(ColumnNo: Integer): Text
    begin
        exit(MatrixMgt.GetFormatString(ColumnLayoutArr[ColumnNo]."Rounding Factor", UseAmtsInAddCurr));
    end;

    procedure RoundNone(Value: Decimal; RoundingFactor: Option "None","1","1000","1000000"): Decimal
    begin
        if RoundingFactor <> RoundingFactor::None then
            exit(Value);

        exit(Round(Value));
    end;

    local procedure GetStyle(ColumnNo: Integer; RowLineNo: Integer; ColumnLineNo: Integer)
    var
        ColumnStyle: Text;
        ErrorType: Option "None","Division by Zero","Period Error",Both;
    begin
        AccSchedManagement.CalcFieldError(ErrorType, RowLineNo, ColumnLineNo);
        if ErrorType > ErrorType::None then
            ColumnStyle := 'Unfavorable'
        else
            if Bold then
                ColumnStyle := 'Strong'
            else
                ColumnStyle := 'Standard';

        OnGetStyleOnBeforeAssignColumnStyle(Rec, ColumnNo, RowLineNo, ColumnLineNo, ColumnStyle);

        case ColumnNo of
            1:
                ColumnStyle1 := ColumnStyle;
            2:
                ColumnStyle2 := ColumnStyle;
            3:
                ColumnStyle3 := ColumnStyle;
            4:
                ColumnStyle4 := ColumnStyle;
            5:
                ColumnStyle5 := ColumnStyle;
            6:
                ColumnStyle6 := ColumnStyle;
            7:
                ColumnStyle7 := ColumnStyle;
            8:
                ColumnStyle8 := ColumnStyle;
            9:
                ColumnStyle9 := ColumnStyle;
            10:
                ColumnStyle10 := ColumnStyle;
            11:
                ColumnStyle11 := ColumnStyle;
            12:
                ColumnStyle12 := ColumnStyle;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDimFilters(var AccScheduleLine: Record "Acc. Schedule Line"; var DimNo: Integer; var DimValueFilter: Text; var CostCenterFilter: Text; var CostObjectFilter: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateCostCenterFilter(var AccScheduleLine: Record "Acc. Schedule Line"; var CostCenterFilter: Text; var Dim1Filter: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateCostObjectFilter(var AccScheduleLine: Record "Acc. Schedule Line"; var CostObjectFilter: Text; var Dim2Filter: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateDimFilterControls()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrint(var AccScheduleLine: Record "Acc. Schedule Line"; ColumnLayoutName: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCurrentColumnNameOnAfterValidate(var CurrentColumnName: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateColumnCaptions(var ColumnCaptions: array[12] of Text[80]; ColumnOffset: Integer; var TempColumnLayout: Record "Column Layout" temporary; NoOfColumns: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDimFilterControls(var AccScheduleLine: Record "Acc. Schedule Line"; AnalysisView: Record "Analysis View"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetStyleOnBeforeAssignColumnStyle(AccScheduleLine: Record "Acc. Schedule Line"; ColumnNo: Integer; RowLineNo: Integer; ColumnLineNo: Integer; var ColumnStyle: Text);
    begin
    end;
}

