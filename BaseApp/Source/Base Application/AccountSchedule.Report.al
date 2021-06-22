report 25 "Account Schedule"
{
    DefaultLayout = RDLC;
    RDLCLayout = './AccountSchedule.rdlc';
    AdditionalSearchTerms = 'financial reporting,income statement,balance sheet';
    ApplicationArea = Basic, Suite;
    Caption = 'Account Schedule';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(AccScheduleName; "Acc. Schedule Name")
        {
            DataItemTableView = SORTING(Name);
            column(AccScheduleName_Name; Name)
            {
            }
            dataitem(Heading; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                column(TodayFormatted; TypeHelper.GetFormattedCurrentDateTimeInUserTimeZone('d'))
                {
                }
                column(ColumnLayoutName; ColumnLayoutName)
                {
                }
                column(FiscalStartDate; Format(FiscalStartDate))
                {
                }
                column(PeriodText; PeriodText)
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
                {
                }
                column(AccScheduleName_Description; AccScheduleName.Description)
                {
                }
                column(AnalysisView_Code; AnalysisView.Code)
                {
                }
                column(AnalysisView_Name; AnalysisView.Name)
                {
                }
                column(HeaderText; HeaderText)
                {
                }
                column(AccScheduleLineTABLECAPTION_AccSchedLineFilter; "Acc. Schedule Line".TableCaption + ': ' + AccSchedLineFilter)
                {
                }
                column(AccSchedLineFilter; AccSchedLineFilter)
                {
                }
                column(ColumnLayoutNameCaption; ColumnLayoutNameCaptionLbl)
                {
                }
                column(AccScheduleName_Name_Caption; AccScheduleName_Name_CaptionLbl)
                {
                }
                column(FiscalStartDateCaption; FiscalStartDateCaptionLbl)
                {
                }
                column(PeriodTextCaption; PeriodTextCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Account_ScheduleCaption; Account_ScheduleCaptionLbl)
                {
                }
                column(AnalysisView_CodeCaption; AnalysisView_CodeCaptionLbl)
                {
                }
                column(RowNoCaption; RowNoCaption)
                {
                }
                column(ShowRowNo; ShowRowNo)
                {
                }
                column(ShowRoundingHeader; ShowRoundingHeader)
                {
                }
                column(ColumnHeader1; ColumnHeaderArrayText[1])
                {
                }
                column(ColumnHeader2; ColumnHeaderArrayText[2])
                {
                }
                column(ColumnHeader3; ColumnHeaderArrayText[3])
                {
                }
                column(ColumnHeader4; ColumnHeaderArrayText[4])
                {
                }
                column(ColumnHeader5; ColumnHeaderArrayText[5])
                {
                }
                dataitem("Acc. Schedule Line"; "Acc. Schedule Line")
                {
                    DataItemLink = "Schedule Name" = FIELD(Name);
                    DataItemLinkReference = AccScheduleName;
                    DataItemTableView = SORTING("Schedule Name", "Line No.");
                    PrintOnlyIfDetail = true;
                    column(NextPageGroupNo; NextPageGroupNo)
                    {
                    }
                    column(Acc__Schedule_Line_Description; PadStr('', Indentation * 2, PadString) + Description)
                    {
                    }
                    column(Acc__Schedule_Line__Row_No; "Row No.")
                    {
                    }
                    column(Acc__Schedule_Line_Line_No; "Line No.")
                    {
                    }
                    column(Bold_control; Bold_control)
                    {
                    }
                    column(Italic_control; Italic_control)
                    {
                    }
                    column(Underline_control; Underline_control)
                    {
                    }
                    column(DoubleUnderline_control; DoubleUnderline_control)
                    {
                    }
                    column(LineShadowed; LineShadowed)
                    {
                    }
                    column(LineSkipped; LineSkipped)
                    {
                    }
                    dataitem("Column Layout"; "Column Layout")
                    {
                        DataItemTableView = SORTING("Column Layout Name", "Line No.");
                        column(ColumnNo; "Column No.")
                        {
                        }
                        column(Header; Header)
                        {
                        }
                        column(RoundingHeader; RoundingHeader)
                        {
                            AutoCalcField = false;
                        }
                        column(ColumnValuesAsText; ColumnValuesAsText)
                        {
                            AutoCalcField = false;
                        }
                        column(LineNo_ColumnLayout; "Line No.")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Show = Show::Never then
                                CurrReport.Skip();

                            Header := "Column Header";
                            RoundingHeader := '';

                            if "Rounding Factor" in ["Rounding Factor"::"1000", "Rounding Factor"::"1000000"] then
                                case "Rounding Factor" of
                                    "Rounding Factor"::"1000":
                                        RoundingHeader := Text000;
                                    "Rounding Factor"::"1000000":
                                        RoundingHeader := Text001;
                                end;

                            ColumnValuesAsText := CalcColumnValueAsText("Acc. Schedule Line", "Column Layout");

                            ColumnValuesArrayIndex += 1;
                            if ColumnValuesArrayIndex <= ArrayLen(ColumnValuesArrayText) then
                                ColumnValuesArrayText[ColumnValuesArrayIndex] := ColumnValuesAsText;

                            if (ColumnValuesAsText <> '') or (("Acc. Schedule Line".Show = "Acc. Schedule Line".Show::Yes) and not SkipEmptyLines) then
                                LineSkipped := false;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange("Column Layout Name", ColumnLayoutName);
                            LineSkipped := true;
                            ColumnValuesArrayIndex := 0;
                        end;
                    }
                    dataitem(FixedColumns; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                        column(ColumnValue1; ColumnValuesArrayText[1])
                        {
                        }
                        column(ColumnValue2; ColumnValuesArrayText[2])
                        {
                        }
                        column(ColumnValue3; ColumnValuesArrayText[3])
                        {
                        }
                        column(ColumnValue4; ColumnValuesArrayText[4])
                        {
                        }
                        column(ColumnValue5; ColumnValuesArrayText[5])
                        {
                        }
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if (Show = Show::No) or not ShowLine(Bold, Italic) then
                            CurrReport.Skip();

                        PadChar := 160; // whitespace
                        PadString[1] := PadChar;
                        Bold_control := Bold;
                        Italic_control := Italic;
                        Underline_control := Underline;
                        DoubleUnderline_control := "Double Underline";
                        PageGroupNo := NextPageGroupNo;
                        if "New Page" then
                            NextPageGroupNo := PageGroupNo + 1;

                        LineShadowed := ShowAlternatingShading and not LineShadowed;

                        if not ShowRowNo then
                            "Row No." := '';
                    end;

                    trigger OnPreDataItem()
                    var
                        DimensionMgt: Codeunit DimensionManagement;
                    begin
                        PageGroupNo := NextPageGroupNo;

                        SetFilter("Date Filter", DateFilter);
                        SetFilter("G/L Budget Filter", GLBudgetFilter);
                        SetFilter("Cost Budget Filter", CostBudgetFilter);
                        SetFilter("Business Unit Filter", BusinessUnitFilter);

                        DimensionMgt.ResolveDimValueFilter(Dim1Filter, AnalysisView."Dimension 1 Code");
                        DimensionMgt.ResolveDimValueFilter(Dim2Filter, AnalysisView."Dimension 2 Code");
                        DimensionMgt.ResolveDimValueFilter(Dim3Filter, AnalysisView."Dimension 3 Code");
                        DimensionMgt.ResolveDimValueFilter(Dim4Filter, AnalysisView."Dimension 4 Code");
                        SetFilter("Dimension 1 Filter", Dim1Filter);
                        SetFilter("Dimension 2 Filter", Dim2Filter);
                        SetFilter("Dimension 3 Filter", Dim3Filter);
                        SetFilter("Dimension 4 Filter", Dim4Filter);

                        SetFilter("Cost Center Filter", CostCenterFilter);
                        SetFilter("Cost Object Filter", CostObjectFilter);
                        SetFilter("Cash Flow Forecast Filter", CashFlowFilter);
                    end;
                }

                trigger OnPreDataItem()
                var
                    ColumnLayout: Record "Column Layout";
                    i: Integer;
                begin
                    ColumnLayout.SetRange("Column Layout Name", ColumnLayoutName);
                    if ColumnLayout.FindSet then
                        repeat
                            i += 1;
                            ColumnHeaderArrayText[i] := ColumnLayout."Column Header";
                        until (ColumnLayout.Next = 0) or (i = ArrayLen(ColumnHeaderArrayText));
                end;
            }

            trigger OnAfterGetRecord()
            begin
                GLSetup.Get();
                if "Analysis View Name" <> '' then begin
                    AnalysisView.Get("Analysis View Name");
                end else begin
                    AnalysisView.Init();
                    AnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                    AnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
                end;

                if UseAmtsInAddCurr then
                    HeaderText := StrSubstNo(Text003, GLSetup."Additional Reporting Currency")
                else
                    if GLSetup."LCY Code" <> '' then
                        HeaderText := StrSubstNo(Text003, GLSetup."LCY Code")
                    else
                        HeaderText := '';
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Name, AccSchedName);

                PageGroupNo := 1;
                NextPageGroupNo := 1;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Layout")
                    {
                        Caption = 'Layout';
                        Visible = AccSchedNameEditable;
                        field(AccSchedNam; AccSchedName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Acc. Schedule Name';
                            Editable = AccSchedNameEditable;
                            Importance = Promoted;
                            Lookup = true;
                            ShowMandatory = true;
                            TableRelation = "Acc. Schedule Name";
                            ToolTip = 'Specifies the name of the account schedule.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                exit(AccSchedManagement.LookupName(AccSchedName, Text));
                            end;

                            trigger OnValidate()
                            begin
                                ValidateAccSchedName;
                                AccSchedNameHidden := '';
                                SetBudgetFilterEnable;
                                RequestOptionsPage.Update(false);
                            end;
                        }
                        field(ColumnLayoutNames; ColumnLayoutName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Column Layout Name';
                            Editable = AccSchedNameEditable;
                            Importance = Promoted;
                            Lookup = true;
                            ShowMandatory = true;
                            TableRelation = "Column Layout Name".Name;
                            ToolTip = 'Specifies the name of the column layout that is used for the report.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                if not AccSchedManagement.LookupColumnName(ColumnLayoutName, Text) then
                                    exit(false);
                                ColumnLayoutName := CopyStr(Text, 1, MaxStrLen(ColumnLayoutName));
                                SetBudgetFilterEnable;
                                ColumnLayoutNameHidden := '';
                                RequestOptionsPage.Update;
                                exit(true);
                            end;

                            trigger OnValidate()
                            begin
                                if ColumnLayoutName = '' then
                                    Error(Text006);
                                AccSchedManagement.CheckColumnName(ColumnLayoutName);
                                SetBudgetFilterEnable;
                                ColumnLayoutNameHidden := '';
                                RequestOptionsPage.Update;
                            end;
                        }
                    }
                    group(Filters)
                    {
                        Caption = 'Filters';
                        field(StartDate; StartDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Starting Date';
                            Enabled = StartDateEnabled;
                            ShowMandatory = true;
                            ToolTip = 'Specifies the date from which the report or batch job processes information.';

                            trigger OnValidate()
                            begin
                                ValidateStartEndDate;
                            end;
                        }
                        field(EndDate; EndDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Ending Date';
                            ShowMandatory = true;
                            ToolTip = 'Specifies the date to which the report or batch job processes information.';

                            trigger OnValidate()
                            begin
                                ValidateStartEndDate;
                            end;
                        }
                        field(GLBudgetFilter; GLBudgetName)
                        {
                            ApplicationArea = Suite;
                            Caption = 'G/L Budget';
                            Enabled = BudgetFilterEnable;
                            ShowMandatory = BudgetFilterEnable;
                            TableRelation = "G/L Budget Name".Name;
                            ToolTip = 'Specifies a general ledger budget filter for the report.';
                            Width = 10;

                            trigger OnValidate()
                            begin
                                GLBudgetFilter := GLBudgetName;
                                "Acc. Schedule Line".SetRange("G/L Budget Filter", GLBudgetFilter);
                                GLBudgetFilter := "Acc. Schedule Line".GetFilter("G/L Budget Filter");
                            end;
                        }
                        field(CostBudgetFilter; CostBudgetFilter)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Budget Filter';
                            Enabled = BudgetFilterEnable;
                            Importance = Additional;
                            TableRelation = "Cost Budget Name".Name;
                            ToolTip = 'Specifies a code for a cost budget that the account schedule line will be filtered on.';

                            trigger OnValidate()
                            begin
                                "Acc. Schedule Line".SetFilter("Cost Budget Filter", CostBudgetFilter);
                                CostBudgetFilter := "Acc. Schedule Line".GetFilter("Cost Budget Filter");
                            end;
                        }
                        field(BusinessUnitFilter; BusinessUnitFilter)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Business Unit Filter';
                            Importance = Additional;
                            LookupPageID = "Business Unit List";
                            TableRelation = "Business Unit";
                            ToolTip = 'Specifies the business unit filter for the account schedule.';
                            Visible = BusinessUnitFilterVisible;

                            trigger OnValidate()
                            begin
                                "Acc. Schedule Line".SetFilter("Business Unit Filter", BusinessUnitFilter);
                                BusinessUnitFilter := "Acc. Schedule Line".GetFilter("Business Unit Filter");
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
                            Importance = Additional;
                            ToolTip = 'Specifies a filter for dimension values within a dimension. The filter uses the dimension you have defined as dimension 1 for the analysis view selected in the Analysis View Code field.';
                            Visible = Dim1FilterEnable;

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                exit(FormLookUpDimFilter(AnalysisView."Dimension 1 Code", Text));
                            end;
                        }
                        field(Dim2Filter; Dim2Filter)
                        {
                            ApplicationArea = Dimensions;
                            CaptionClass = FormGetCaptionClass(2);
                            Caption = 'Dimension 2 Filter';
                            Importance = Additional;
                            ToolTip = 'Specifies a filter for dimension values within a dimension. The filter uses the dimension you have defined as dimension 2 for the analysis view selected in the Analysis View Code field.';
                            Visible = Dim2FilterEnable;

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                exit(FormLookUpDimFilter(AnalysisView."Dimension 2 Code", Text));
                            end;
                        }
                        field(Dim3Filter; Dim3Filter)
                        {
                            ApplicationArea = Dimensions;
                            CaptionClass = FormGetCaptionClass(3);
                            Caption = 'Dimension 3 Filter';
                            Importance = Additional;
                            ToolTip = 'Specifies a filter for dimension values within a dimension. The filter uses the dimension you have defined as dimension 3 for the analysis view selected in the Analysis View Code field.';
                            Visible = Dim3FilterEnable;

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                exit(FormLookUpDimFilter(AnalysisView."Dimension 3 Code", Text));
                            end;
                        }
                        field(Dim4Filter; Dim4Filter)
                        {
                            ApplicationArea = Dimensions;
                            CaptionClass = FormGetCaptionClass(4);
                            Caption = 'Dimension 4 Filter';
                            Importance = Additional;
                            ToolTip = 'Specifies a filter for dimension values within a dimension. The filter uses the dimension you have defined as dimension 4 for the analysis view selected in the Analysis View Code field.';
                            Visible = Dim4FilterEnable;

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                exit(FormLookUpDimFilter(AnalysisView."Dimension 4 Code", Text));
                            end;
                        }
                        field(CostCenterFilter; CostCenterFilter)
                        {
                            ApplicationArea = Dimensions;
                            Caption = 'Cost Center Filter';
                            Importance = Additional;
                            ToolTip = 'Specifies a cost center filter for dimension values within a dimension. The filter uses the dimension you have defined as Dimension 1 for the Analysis View selected in the Analysis View Code field. If you have not defined a Dimension 1 for an analysis view, this field will be disabled. ';

                            trigger OnLookup(var Text: Text): Boolean
                            var
                                CostCenter: Record "Cost Center";
                            begin
                                exit(CostCenter.LookupCostCenterFilter(Text));
                            end;
                        }
                        field(CostObjectFilter; CostObjectFilter)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Object Filter';
                            Importance = Additional;
                            ToolTip = 'Specifies the cost object filter that applies.';

                            trigger OnLookup(var Text: Text): Boolean
                            var
                                CostObject: Record "Cost Object";
                            begin
                                exit(CostObject.LookupCostObjectFilter(Text));
                            end;
                        }
                        field(CashFlowFilter; CashFlowFilter)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Cash Flow Filter';
                            Importance = Additional;
                            ToolTip = 'Specifies a cash flow filter for the schedule.';

                            trigger OnLookup(var Text: Text): Boolean
                            var
                                CashFlowForecast: Record "Cash Flow Forecast";
                            begin
                                exit(CashFlowForecast.LookupCashFlowFilter(Text));
                            end;
                        }
                    }
                    group(Show)
                    {
                        Caption = 'Show';
                        field(ShowError; ShowError)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Show Error';
                            Importance = Additional;
                            OptionCaption = 'None,Division by Zero,Period Error,Both';
                            ToolTip = 'Specifies if the report shows error information.';
                        }
                        field(UseAmtsInAddCurr; UseAmtsInAddCurr)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Show Amounts in Add. Reporting Currency';
                            Importance = Additional;
                            MultiLine = true;
                            ToolTip = 'Specifies if the reported amounts are shown in the additional reporting currency.';
                            Visible = UseAmtsInAddCurrVisible;
                        }
                        field(ShowRowNo; ShowRowNo)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Show Row No.';
                            Importance = Additional;
                            ToolTip = 'Specifies if the report shows row numbers.';
                        }
                        field(ShowAlternatingShading; ShowAlternatingShading)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Print Alternating Shading';
                            Importance = Additional;
                            ToolTip = 'Specifies if you want every second row in the report to be shaded.';
                        }
                        field(SkipEmptyLines; SkipEmptyLines)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Skip Zero Balance Lines';
                            Importance = Additional;
                            ToolTip = 'Specifies if you want the report to skip lines that have a balance equal to zero.';
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            Dim4FilterEnable := true;
            Dim3FilterEnable := true;
            Dim2FilterEnable := true;
            Dim1FilterEnable := true;
            AccSchedNameEditable := true;
        end;

        trigger OnOpenPage()
        begin
            GLSetup.Get();
            TransferValues;
            if AccSchedName <> '' then
                if (ColumnLayoutName = '') or not AccSchedNameEditable then
                    ValidateAccSchedName;
            SetBudgetFilterEnable;
        end;
    }

    labels
    {
        AccSchedLineSpec_DescriptionCaptionLbl = 'Description';
    }

    trigger OnPreReport()
    begin
        TransferValues;
        UpdateFilters;
        InitAccSched;
    end;

    var
        Text000: Label '(Thousands)';
        Text001: Label '(Millions)';
        Text002: Label '* ERROR *';
        Text003: Label 'All amounts are in %1.';
        AnalysisView: Record "Analysis View";
        GLSetup: Record "General Ledger Setup";
        AccSchedManagement: Codeunit AccSchedManagement;
        TypeHelper: Codeunit "Type Helper";
        AccSchedName: Code[10];
        AccSchedNameHidden: Code[10];
        ColumnLayoutName: Code[10];
        ColumnLayoutNameHidden: Code[10];
        GLBudgetName: Code[10];
        [InDataSet]
        StartDateEnabled: Boolean;
        StartDate: Date;
        EndDate: Date;
        ShowError: Option "None","Division by Zero","Period Error",Both;
        ShowAlternatingShading: Boolean;
        ShowRoundingHeader: Boolean;
        DateFilter: Text;
        UseHiddenFilters: Boolean;
        DateFilterHidden: Text;
        GLBudgetFilter: Text;
        GLBudgetFilterHidden: Text;
        CostBudgetFilter: Text;
        CostBudgetFilterHidden: Text;
        BusinessUnitFilter: Text;
        BusinessUnitFilterHidden: Text;
        Dim1Filter: Text;
        Dim1FilterHidden: Text;
        Dim2Filter: Text;
        Dim2FilterHidden: Text;
        Dim3Filter: Text;
        Dim3FilterHidden: Text;
        Dim4Filter: Text;
        Dim4FilterHidden: Text;
        CostCenterFilter: Text;
        CostObjectFilter: Text;
        CashFlowFilter: Text;
        FiscalStartDate: Date;
        ColumnHeaderArrayText: array[5] of Text[30];
        ColumnValuesArrayText: array[5] of Text[30];
        ColumnValuesArrayIndex: Integer;
        ColumnValuesDisplayed: Decimal;
        ColumnValuesAsText: Text[30];
        PeriodText: Text;
        AccSchedLineFilter: Text;
        Header: Text[50];
        RoundingHeader: Text[30];
        [InDataSet]
        BusinessUnitFilterVisible: Boolean;
        [InDataSet]
        BudgetFilterEnable: Boolean;
        [InDataSet]
        UseAmtsInAddCurrVisible: Boolean;
        UseAmtsInAddCurr: Boolean;
        ShowRowNo: Boolean;
        RowNoCaption: Text;
        HeaderText: Text[100];
        Text004: Label 'Not Available';
        Text005: Label '1,6,,Dimension %1 Filter';
        Bold_control: Boolean;
        Italic_control: Boolean;
        Underline_control: Boolean;
        DoubleUnderline_control: Boolean;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        Text006: Label 'Enter the Column Layout Name.';
        [InDataSet]
        Dim1FilterEnable: Boolean;
        [InDataSet]
        Dim2FilterEnable: Boolean;
        [InDataSet]
        Dim3FilterEnable: Boolean;
        [InDataSet]
        Dim4FilterEnable: Boolean;
        [InDataSet]
        AccSchedNameEditable: Boolean;
        LineShadowed: Boolean;
        LineSkipped: Boolean;
        SkipEmptyLines: Boolean;
        ColumnLayoutNameCaptionLbl: Label 'Column Layout';
        AccScheduleName_Name_CaptionLbl: Label 'Account Schedule';
        FiscalStartDateCaptionLbl: Label 'Fiscal Start Date';
        PeriodTextCaptionLbl: Label 'Period';
        PeriodEndingTextCaptionLbl: Label 'Period Ending';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Account_ScheduleCaptionLbl: Label 'Account Schedule';
        AnalysisView_CodeCaptionLbl: Label 'Analysis View';
        PadChar: Char;
        PadString: Text;

    local procedure CalcColumnValueAsText(var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"): Text[30]
    var
        ColumnValuesAsText: Text[30];
    begin
        ColumnValuesAsText := '';

        ColumnValuesDisplayed := AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, UseAmtsInAddCurr);
        if AccSchedManagement.GetDivisionError then begin
            if ShowError in [ShowError::"Division by Zero", ShowError::Both] then
                ColumnValuesAsText := Text002;
        end else
            if AccSchedManagement.GetPeriodError then begin
                if ShowError in [ShowError::"Period Error", ShowError::Both] then
                    ColumnValuesAsText := Text004;
            end else begin
                ColumnValuesAsText :=
                  AccSchedManagement.FormatCellAsText(ColumnLayout, ColumnValuesDisplayed, UseAmtsInAddCurr);

                if AccScheduleLine."Totaling Type" = AccScheduleLine."Totaling Type"::Formula then
                    case AccScheduleLine.Show of
                        AccScheduleLine.Show::"When Positive Balance":
                            if ColumnValuesDisplayed < 0 then
                                ColumnValuesAsText := '';
                        AccScheduleLine.Show::"When Negative Balance":
                            if ColumnValuesDisplayed > 0 then
                                ColumnValuesAsText := '';
                        AccScheduleLine.Show::"If Any Column Not Zero":
                            if ColumnValuesDisplayed = 0 then
                                ColumnValuesAsText := '';
                    end;
            end;
        exit(ColumnValuesAsText);
    end;

    procedure InitAccSched()
    var
        ColumnLayout: Record "Column Layout";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
    begin
        AccScheduleName.SetRange(Name, AccSchedName);
        "Acc. Schedule Line".SetFilter("Date Filter", DateFilter);
        "Acc. Schedule Line".SetFilter("G/L Budget Filter", GLBudgetFilter);
        "Acc. Schedule Line".SetFilter("Cost Budget Filter", CostBudgetFilter);
        "Acc. Schedule Line".SetFilter("Business Unit Filter", BusinessUnitFilter);
        "Acc. Schedule Line".SetFilter("Dimension 1 Filter", Dim1Filter);
        "Acc. Schedule Line".SetFilter("Dimension 2 Filter", Dim2Filter);
        "Acc. Schedule Line".SetFilter("Dimension 3 Filter", Dim3Filter);
        "Acc. Schedule Line".SetFilter("Dimension 4 Filter", Dim4Filter);
        "Acc. Schedule Line".SetFilter("Cost Center Filter", CostCenterFilter);
        "Acc. Schedule Line".SetFilter("Cost Object Filter", CostObjectFilter);
        "Acc. Schedule Line".SetFilter("Cash Flow Forecast Filter", CashFlowFilter);

        if "Acc. Schedule Line".GetFilter("Date Filter") <> '' then
            EndDate := "Acc. Schedule Line".GetRangeMax("Date Filter");
        FiscalStartDate := AccountingPeriodMgt.FindFiscalYear(EndDate);

        AccScheduleLine.CopyFilters("Acc. Schedule Line");
        AccScheduleLine.SetRange("Date Filter");
        AccSchedLineFilter := AccScheduleLine.GetFilters;

        if StartDateEnabled then
            PeriodText := PeriodTextCaptionLbl + ': ' + "Acc. Schedule Line".GetFilter("Date Filter")
        else
            PeriodText := PeriodEndingTextCaptionLbl + ' ' + Format(EndDate);

        if ShowRowNo then
            RowNoCaption := "Acc. Schedule Line".FieldCaption("Row No.");

        ColumnLayout.SetRange("Column Layout Name", ColumnLayoutName);
        ColumnLayout.SetFilter("Rounding Factor", '<>%1&<>%2', ColumnLayout."Rounding Factor"::None, ColumnLayout."Rounding Factor"::"1");
        ShowRoundingHeader := not ColumnLayout.IsEmpty;
    end;

    procedure SetAccSchedName(NewAccSchedName: Code[10])
    begin
        AccSchedNameHidden := NewAccSchedName;
        AccSchedNameEditable := true;
    end;

    procedure SetAccSchedNameNonEditable(NewAccSchedName: Code[10])
    begin
        SetAccSchedName(NewAccSchedName);
        AccSchedNameEditable := false;
    end;

    procedure SetColumnLayoutName(ColLayoutName: Code[10])
    begin
        ColumnLayoutNameHidden := ColLayoutName;
    end;

    procedure SetFilters(NewDateFilter: Text; NewBudgetFilter: Text; NewCostBudgetFilter: Text; NewBusUnitFilter: Text; NewDim1Filter: Text; NewDim2Filter: Text; NewDim3Filter: Text; NewDim4Filter: Text)
    begin
        DateFilterHidden := NewDateFilter;
        GLBudgetFilterHidden := NewBudgetFilter;
        CostBudgetFilterHidden := NewCostBudgetFilter;
        BusinessUnitFilterHidden := NewBusUnitFilter;
        Dim1FilterHidden := NewDim1Filter;
        Dim2FilterHidden := NewDim2Filter;
        Dim3FilterHidden := NewDim3Filter;
        Dim4FilterHidden := NewDim4Filter;
        UseHiddenFilters := true;
    end;

    procedure ShowLine(Bold: Boolean; Italic: Boolean): Boolean
    begin
        if "Acc. Schedule Line"."Totaling Type" = "Acc. Schedule Line"."Totaling Type"::"Set Base For Percent" then
            exit(false);
        if "Acc. Schedule Line".Show = "Acc. Schedule Line".Show::No then
            exit(false);
        if "Acc. Schedule Line".Bold <> Bold then
            exit(false);
        if "Acc. Schedule Line".Italic <> Italic then
            exit(false);

        exit(true);
    end;

    local procedure FormLookUpDimFilter(Dim: Code[20]; var Text: Text[1024]): Boolean
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
        exit(false)
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
        end;
    end;

    local procedure TransferValues()
    var
        ColumnLayoutName2: Record "Column Layout Name";
        BusinessUnit: Record "Business Unit";
    begin
        if GLBudgetName <> '' then
            GLBudgetFilter := GLBudgetName;
        GLSetup.Get();
        UseAmtsInAddCurrVisible := GLSetup."Additional Reporting Currency" <> '';
        BusinessUnitFilterVisible := not BusinessUnit.IsEmpty;
        if not UseAmtsInAddCurrVisible then
            UseAmtsInAddCurr := false;
        if AccSchedNameHidden <> '' then
            AccSchedName := AccSchedNameHidden;
        if ColumnLayoutNameHidden <> '' then
            ColumnLayoutName := ColumnLayoutNameHidden;
        if DateFilterHidden <> '' then
            DateFilter := DateFilterHidden;
        if GLBudgetFilterHidden <> '' then
            GLBudgetFilter := GLBudgetFilterHidden;
        if CostBudgetFilterHidden <> '' then
            CostBudgetFilter := CostBudgetFilterHidden;
        if BusinessUnitFilterHidden <> '' then
            BusinessUnitFilter := BusinessUnitFilterHidden;
        if Dim1FilterHidden <> '' then
            Dim1Filter := Dim1FilterHidden;
        if Dim2FilterHidden <> '' then
            Dim2Filter := Dim2FilterHidden;
        if Dim3FilterHidden <> '' then
            Dim3Filter := Dim3FilterHidden;
        if Dim4FilterHidden <> '' then
            Dim4Filter := Dim4FilterHidden;

        if AccSchedName <> '' then
            if not AccScheduleName.Get(AccSchedName) then
                AccSchedName := '';
        if AccSchedName = '' then
            if AccScheduleName.FindFirst then
                AccSchedName := AccScheduleName.Name;

        if not ColumnLayoutName2.Get(ColumnLayoutName) then
            ColumnLayoutName := AccScheduleName."Default Column Layout";

        if AccScheduleName."Analysis View Name" <> '' then
            AnalysisView.Get(AccScheduleName."Analysis View Name")
        else begin
            AnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
            AnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
        end;

        OnAfterTransferValues(StartDate, EndDate, DateFilterHidden);
    end;

    local procedure UpdateFilters()
    begin
        if UseHiddenFilters then begin
            DateFilter := DateFilterHidden;
            GLBudgetFilter := GLBudgetFilterHidden;
            CostBudgetFilter := CostBudgetFilterHidden;
            BusinessUnitFilter := BusinessUnitFilterHidden;
            Dim1Filter := Dim1FilterHidden;
            Dim2Filter := Dim2FilterHidden;
            Dim3Filter := Dim3FilterHidden;
            Dim4Filter := Dim4FilterHidden;
        end else begin
            if EndDate = 0D then
                EndDate := WorkDate;
            if StartDate = 0D then
                StartDate := CalcDate('<-CM>', EndDate);
            ValidateStartEndDate;
        end;

        if ColumnLayoutName = '' then
            if AccScheduleName.Get(AccSchedName) then
                ColumnLayoutName := AccScheduleName."Default Column Layout";
    end;

    local procedure SetBudgetFilterEnable()
    var
        ColumnLayout: Record "Column Layout";
    begin
        BudgetFilterEnable := true;
        StartDateEnabled := true;
        if ColumnLayoutName = '' then
            exit;
        ColumnLayout.SetRange("Column Layout Name", ColumnLayoutName);
        ColumnLayout.SetRange("Ledger Entry Type", ColumnLayout."Ledger Entry Type"::"Budget Entries");
        BudgetFilterEnable := not ColumnLayout.IsEmpty;
        if not BudgetFilterEnable then
            GLBudgetFilter := '';
        GLBudgetName := CopyStr(GLBudgetFilter, 1, MaxStrLen(GLBudgetName));
        ColumnLayout.SetRange("Ledger Entry Type");
        ColumnLayout.SetFilter("Column Type", '<>%1', ColumnLayout."Column Type"::"Balance at Date");
        StartDateEnabled := not ColumnLayout.IsEmpty;
        if not StartDateEnabled then
            StartDate := 0D;
    end;

    local procedure ValidateStartEndDate()
    begin
        if (StartDate = 0D) and (EndDate = 0D) then
            ValidateDateFilter('')
        else
            ValidateDateFilter(StrSubstNo('%1..%2', StartDate, EndDate));
    end;

    local procedure ValidateDateFilter(NewDateFilter: Text[30])
    var
        FilterTokens: Codeunit "Filter Tokens";
    begin
        FilterTokens.MakeDateFilter(NewDateFilter);
        "Acc. Schedule Line".SetFilter("Date Filter", NewDateFilter);
        DateFilter := CopyStr("Acc. Schedule Line".GetFilter("Date Filter"), 1, MaxStrLen(DateFilter));
    end;

    local procedure ValidateAccSchedName()
    begin
        AccSchedManagement.CheckName(AccSchedName);
        AccScheduleName.Get(AccSchedName);
        if AccScheduleName."Default Column Layout" <> '' then
            ColumnLayoutName := AccScheduleName."Default Column Layout";
        if AccScheduleName."Analysis View Name" <> '' then
            AnalysisView.Get(AccScheduleName."Analysis View Name")
        else begin
            Clear(AnalysisView);
            AnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
            AnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
        end;
        Dim1FilterEnable := AnalysisView."Dimension 1 Code" <> '';
        Dim2FilterEnable := AnalysisView."Dimension 2 Code" <> '';
        Dim3FilterEnable := AnalysisView."Dimension 3 Code" <> '';
        Dim4FilterEnable := AnalysisView."Dimension 4 Code" <> '';
        RequestOptionsPage.Caption := AccScheduleName.Description;
        RequestOptionsPage.Update(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferValues(var StartDate: Date; var EndDate: Date; var DateFilterHidden: Text);
    begin
    end;
}

