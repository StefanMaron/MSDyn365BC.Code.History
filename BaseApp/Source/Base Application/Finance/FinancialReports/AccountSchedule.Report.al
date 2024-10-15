namespace Microsoft.Finance.FinancialReports;

using Microsoft.CashFlow.Forecast;
using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Budget;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using System.Text;
using System.Utilities;

report 25 "Account Schedule"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/FinancialReports/AccountSchedule.rdlc';
    AdditionalSearchTerms = 'financial reporting,income statement,balance sheet';
    ApplicationArea = Basic, Suite;
    Caption = 'Run Financial Report';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    AllowScheduling = false;

    dataset
    {
        dataitem(AccScheduleName; "Acc. Schedule Name")
        {
            DataItemTableView = sorting(Name);
            column(AccScheduleName_Name; Name)
            {
            }
            dataitem(Heading; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(TodayFormatted; Format(Today()))
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
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(AccScheduleName_Description; FinancialReportDescription)
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
                    DataItemLink = "Schedule Name" = field(Name);
                    DataItemLinkReference = AccScheduleName;
                    DataItemTableView = sorting("Schedule Name", "Line No.");
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
                        DataItemTableView = sorting("Column Layout Name", "Line No.");
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
                        var
                            ValueIsEmpty: Boolean;
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

                            ColumnValuesAsText := CalcColumnValueAsText("Acc. Schedule Line", "Column Layout", ValueIsEmpty);

                            ColumnValuesArrayIndex += 1;
                            if ColumnValuesArrayIndex <= ArrayLen(ColumnValuesArrayText) then
                                ColumnValuesArrayText[ColumnValuesArrayIndex] := ColumnValuesAsText;

                            if (not ValueIsEmpty) or (("Acc. Schedule Line".Show = "Acc. Schedule Line".Show::Yes) and not SkipEmptyLines) or
                                (("Acc. Schedule Line".Totaling = '') and ("Acc. Schedule Line".Show = "Acc. Schedule Line".Show::Yes))
                            then
                                LineSkipped := false;

                            OnAfterGetColumnLayoutOnAfteCheckIsLineSkipped("Acc. Schedule Line", ValueIsEmpty, LineSkipped);
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
                        DataItemTableView = sorting(Number) where(Number = const(1));
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
                    if ColumnLayout.FindSet() then
                        repeat
                            i += 1;
                            ColumnHeaderArrayText[i] := ColumnLayout."Column Header";
                        until (ColumnLayout.Next() = 0) or (i = ArrayLen(ColumnHeaderArrayText));
                end;
            }

            trigger OnAfterGetRecord()
            begin
                GLSetup.Get();
                if "Analysis View Name" <> '' then
                    AnalysisView.Get("Analysis View Name")
                else begin
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
        AboutTitle = 'Run Financial Report';
        AboutText = 'Specify the Financial Report you want to run (to get a pdf or to print) and the date range for the data to be included. You can also Specifies additional display options and filters for dimensions and budgets (choose "Show more" in the Options pane to see all options).';
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

                        field(FinancialReport; FinancialReportName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Financial Report';
                            Editable = AccSchedNameEditable;
                            Importance = Promoted;
                            Lookup = true;
                            ShowMandatory = true;
                            TableRelation = "Financial Report";
                            ToolTip = 'Specifies the name (code) of the financial report.';

                            trigger OnLookup(var Text: Text): Boolean
                            var
                                LookupText: Text[10];
                                Result: Boolean;
                            begin
                                LookupText := CopyStr(Text, 1, 10);
                                Result := FinancialReportMgt.LookupName(FinancialReportName, LookupText);
                                Text := LookupText;
                                exit(Result);
                            end;

                            trigger OnValidate()
                            var
                                FinancialReport: Record "Financial Report";
                            begin
                                FinancialReport.Get(FinancialReportName);
                                AccSchedName := FinancialReport."Financial Report Row Group";
                                if FinancialReport."Financial Report Column Group" <> '' then
                                    ColumnLayoutName := FinancialReport."Financial Report Column Group"
                                else
                                    ColumnLayoutName := '';
                                FinancialReportDescription := FinancialReport.Description;
                                ValidateAccSchedName(FinancialReport);
                                AccSchedNameHidden := '';
                                SetBudgetFilterEnable();
                                RequestOptionsPage.Update(false);
                            end;
                        }

                        field(AccSchedNam; AccSchedName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Row Definition';
                            Editable = AccSchedNameEditable;
                            Importance = Additional;
                            Lookup = true;
                            ShowMandatory = true;
                            TableRelation = "Acc. Schedule Name";
                            ToolTip = 'Specifies the name (code) of the row definition to be used (default is the one used in the report definition, but you can override this here).';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                exit(AccSchedManagement.LookupName(AccSchedName, Text));
                            end;

                            trigger OnValidate()
                            begin
                                ValidateAccSchedName();
                                AccSchedNameHidden := '';
                                SetBudgetFilterEnable();
                                RequestOptionsPage.Update(false);
                            end;
                        }
                        field(ColumnLayoutNames; ColumnLayoutName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Column Definition';
                            Editable = AccSchedNameEditable;
                            Importance = Additional;
                            Lookup = true;
                            ShowMandatory = true;
                            TableRelation = "Column Layout Name".Name;
                            ToolTip = 'Specifies the name (code) of the column definition to be used for the report (default is the one used in the report definition, but you can override this here).';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                if not AccSchedManagement.LookupColumnName(ColumnLayoutName, Text) then
                                    exit(false);
                                ColumnLayoutName := CopyStr(Text, 1, MaxStrLen(ColumnLayoutName));
                                SetBudgetFilterEnable();
                                ColumnLayoutNameHidden := '';
                                RequestOptionsPage.Update();
                                exit(true);
                            end;

                            trigger OnValidate()
                            begin
                                if ColumnLayoutName = '' then
                                    Error(Text006);
                                AccSchedManagement.CheckColumnName(ColumnLayoutName);
                                SetBudgetFilterEnable();
                                ColumnLayoutNameHidden := '';
                                RequestOptionsPage.Update();
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
                            ClosingDates = true;
                            Enabled = StartDateEnabled;
                            ShowMandatory = true;
                            ToolTip = 'Specifies the start date from which data in the report should be included.';

                            trigger OnValidate()
                            begin
                                UseHiddenFilters := false;
                                ValidateStartEndDate();
                            end;
                        }
                        field(EndDate; EndDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Ending Date';
                            ClosingDates = true;
                            ShowMandatory = true;
                            ToolTip = 'Specifies the end date for which data in the report should be included.';

                            trigger OnValidate()
                            begin
                                UseHiddenFilters := false;
                                ValidateStartEndDate();
                            end;
                        }
                        field(GLBudgetFilter; GLBudgetName)
                        {
                            ApplicationArea = Suite;
                            Caption = 'G/L Budget';
                            Enabled = BudgetFilterEnable;
                            TableRelation = "G/L Budget Name".Name;
                            ToolTip = 'Specifies a general ledger budget filter for the report.';
                            Width = 10;

                            trigger OnValidate()
                            begin
                                UseHiddenFilters := false;
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
                            ToolTip = 'Specifies a code for a cost budget that the report will be filtered on.';

                            trigger OnValidate()
                            begin
                                UseHiddenFilters := false;
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
                            ToolTip = 'Specifies a business unit filter for the report.';
                            Visible = BusinessUnitFilterVisible;

                            trigger OnValidate()
                            begin
                                UseHiddenFilters := false;
                                "Acc. Schedule Line".SetFilter("Business Unit Filter", BusinessUnitFilter);
                                BusinessUnitFilter := "Acc. Schedule Line".GetFilter("Business Unit Filter");
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
                            ToolTip = 'Specifies if the report should show row numbers.';
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
                        field(ShowCurrencySymbolCtrl; ShowCurrencySymbol)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Show Currency Symbol';
                            Importance = Additional;
                            ToolTip = 'Specifies if the report should show currency symbols for amounts.';
                        }
                        field(ShowEmptyAmountTypeCtrl; ShowEmptyAmountType)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Show Empty Amounts As';
                            Importance = Additional;
                            ToolTip = 'Specifies how to show amounts for empty accounts.';
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

                            trigger OnValidate()
                            begin
                                UseHiddenFilters := false;
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

                            trigger OnValidate()
                            begin
                                UseHiddenFilters := false;
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

                            trigger OnValidate()
                            begin
                                UseHiddenFilters := false;
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

                            trigger OnValidate()
                            begin
                                UseHiddenFilters := false;
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

                            trigger OnValidate()
                            begin
                                UseHiddenFilters := false;
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

                            trigger OnValidate()
                            begin
                                UseHiddenFilters := false;
                            end;
                        }
                        field(CashFlowFilter; CashFlowFilter)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Cash Flow Filter';
                            Importance = Additional;
                            ToolTip = 'Specifies a cash flow filter for the report.';

                            trigger OnLookup(var Text: Text): Boolean
                            var
                                CashFlowForecast: Record "Cash Flow Forecast";
                            begin
                                exit(CashFlowForecast.LookupCashFlowFilter(Text));
                            end;

                            trigger OnValidate()
                            begin
                                UseHiddenFilters := false;
                            end;
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
        var
            FinancialReportMgt: Codeunit "Financial Report Mgt.";
        begin
            FinancialReportMgt.Initialize();
            GLSetup.Get();
            AccSchedName := '';
            ColumnLayoutName := '';
            TransferValues();
            ContextInitialized := true;
            if AccSchedName <> '' then
                if (ColumnLayoutName = '') or not AccSchedNameEditable then
                    ValidateAccSchedName();
            SetBudgetFilterEnable();
        end;
    }

    labels
    {
        AccSchedLineSpec_DescriptionCaptionLbl = 'Description';
    }

    trigger OnPreReport()
    var
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
    begin
        FinancialReportMgt.Initialize();
        TransferValues();
        UpdateFilters();
        InitAccSched();
    end;

    var
        AnalysisView: Record "Analysis View";
        GLSetup: Record "General Ledger Setup";
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
        AccSchedNameHidden: Code[10];
        FinancialReportDescription: Text;
        ColumnLayoutNameHidden: Code[10];
        GLBudgetName: Code[10];
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
        CashFlowFilterHidden: Text;
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
        BusinessUnitFilterVisible: Boolean;
        BudgetFilterEnable: Boolean;
        UseAmtsInAddCurrVisible: Boolean;
        ShowRowNo: Boolean;
        RowNoCaption: Text;
        HeaderText: Text[100];
        Bold_control: Boolean;
        Italic_control: Boolean;
        Underline_control: Boolean;
        DoubleUnderline_control: Boolean;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        Dim1FilterEnable: Boolean;
        Dim2FilterEnable: Boolean;
        Dim3FilterEnable: Boolean;
        Dim4FilterEnable: Boolean;
        AccSchedNameEditable: Boolean;
        LineShadowed: Boolean;
        SkipEmptyLines: Boolean;
        ShowCurrencySymbol: Boolean;
        ShowEmptyAmountType: Enum "Show Empty Amount Type";
        PadChar: Char;
        PadString: Text;

#pragma warning disable AA0074
        Text000: Label '(Thousands)';
        Text001: Label '(Millions)';
        Text002: Label '* ERROR *';
#pragma warning disable AA0470
        Text003: Label 'All amounts are in %1.';
#pragma warning restore AA0470
        Text004: Label 'Not Available';
#pragma warning disable AA0470
        Text005: Label '1,6,,Dimension %1 Filter';
#pragma warning restore AA0470
        Text006: Label 'Enter the Column Definition Name.';
#pragma warning restore AA0074
        ColumnLayoutNameCaptionLbl: Label 'Column Definition';
        AccScheduleName_Name_CaptionLbl: Label 'Financial Report';
        FiscalStartDateCaptionLbl: Label 'Fiscal Start Date';
        PeriodTextCaptionLbl: Label 'Period';
        PeriodEndingTextCaptionLbl: Label 'Period Ending';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Account_ScheduleCaptionLbl: Label 'Financial Report';
        AnalysisView_CodeCaptionLbl: Label 'Analysis View';
        ContextInitialized: Boolean;

    protected var
        AccSchedManagement: Codeunit AccSchedManagement;
        AccSchedName: Code[10];
        ColumnLayoutName: Code[10];
        FinancialReportName: Code[10];
        LineSkipped: Boolean;
        UseAmtsInAddCurr: Boolean;

    local procedure CalcColumnValueAsText(var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; var ValueIsEmpty: Boolean): Text[30]
    var
        ColumnValuesAsText2: Text[30];
    begin
        ColumnValuesAsText2 := '';

        ColumnValuesDisplayed := AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, UseAmtsInAddCurr);
        if AccSchedManagement.GetDivisionError() then begin
            if ShowError in [ShowError::"Division by Zero", ShowError::Both] then
                ColumnValuesAsText2 := Text002
            else
                ValueIsEmpty := true;
        end else
            if AccSchedManagement.GetPeriodError() then begin
                if ShowError in [ShowError::"Period Error", ShowError::Both] then
                    ColumnValuesAsText2 := Text004
                else
                    ValueIsEmpty := true;
            end else begin
                if ColumnValuesDisplayed = 0 then
                    ValueIsEmpty := true;

                if AccScheduleLine."Totaling Type" = AccScheduleLine."Totaling Type"::Formula then
                    case AccScheduleLine.Show of
                        AccScheduleLine.Show::"When Positive Balance":
                            if ColumnValuesDisplayed < 0 then
                                ValueIsEmpty := true;
                        AccScheduleLine.Show::"When Negative Balance":
                            if ColumnValuesDisplayed > 0 then
                                ValueIsEmpty := true;
                        AccScheduleLine.Show::"If Any Column Not Zero":
                            if ColumnValuesDisplayed = 0 then
                                ValueIsEmpty := true;
                    end;

                if ValueIsEmpty then
                    ColumnValuesAsText2 := FormatZeroAmount(AccScheduleLine, ColumnLayout)
                else
                    ColumnValuesAsText2 :=
                        AccSchedManagement.FormatCellAsText(ColumnLayout, ColumnValuesDisplayed, UseAmtsInAddCurr);

                FormatCurrencySymbol(AccScheduleLine, ColumnLayout, ColumnValuesAsText2);
            end;
        exit(ColumnValuesAsText2);
    end;

    local procedure GetCurrencySymbol(): Text[10]
    var
        Currency: Record Currency;
    begin
        if UseAmtsInAddCurr then begin
            Currency.Get(GLSetup."Additional Reporting Currency");
            exit(Currency.Symbol);
        end else
            exit(GLSetup."Local Currency Symbol");
    end;

    local procedure FormatZeroAmount(var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout") Result: Text[30]
    var
        MatrixMgt: Codeunit "Matrix Management";
        ZeroDecimal: Decimal;
    begin
        if (AccScheduleLine.Totaling = '') and (AccScheduleLine.Show = AccScheduleLine.Show::Yes) then
            exit('');

        ZeroDecimal := 0;
        case ShowEmptyAmountType of
            ShowEmptyAmountType::Blank:
                exit('');
            ShowEmptyAmountType::Zero:
                exit(
                    CopyStr(
                        Format(ZeroDecimal, 0, MatrixMgt.FormatRoundingFactor(ColumnLayout."Rounding Factor", UseAmtsInAddCurr)),
                        1,
                        MaxStrLen(Result)));
            ShowEmptyAmountType::Dash:
                exit('-');
        end;

        OnAfterFormatZeroAmount(AccScheduleLine, ColumnLayout, Result);
    end;

    local procedure FormatCurrencySymbol(var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; var ColumnValuesAsText: Text[30])
    begin
        if not ShowCurrencySymbol then
            exit;

        if ColumnValuesAsText = '' then
            exit;

        if (ColumnValuesAsText = '-') and (ShowEmptyAmountType = ShowEmptyAmountType::Dash) then
            exit;

        if AccScheduleLine."Hide Currency Symbol" or ColumnLayout."Hide Currency Symbol" then
            exit;

        ColumnValuesAsText :=
            CopyStr(
                GetCurrencySymbol() + ColumnValuesAsText,
                1,
                MaxStrLen(ColumnValuesAsText));
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
        AccSchedLineFilter := AccScheduleLine.GetFilters();

        if StartDateEnabled then
            PeriodText := PeriodTextCaptionLbl + ': ' + "Acc. Schedule Line".GetFilter("Date Filter")
        else
            PeriodText := PeriodEndingTextCaptionLbl + ' ' + Format(EndDate);

        if ShowRowNo then
            RowNoCaption := "Acc. Schedule Line".FieldCaption("Row No.");

        ColumnLayout.SetRange("Column Layout Name", ColumnLayoutName);
        ColumnLayout.SetFilter("Rounding Factor", '<>%1&<>%2', ColumnLayout."Rounding Factor"::None, ColumnLayout."Rounding Factor"::"1");
        ShowRoundingHeader := not ColumnLayout.IsEmpty();
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

    procedure SetFinancialReportNameNonEditable(NewAccSchedName: Code[10])
    begin
        SetFinancialReportName(NewAccSchedName);
        AccSchedNameEditable := false;
    end;

    procedure SetFinancialReportName(NewFinancialReportName: Code[10])
    var
        FinancialReportLocal: Record "Financial Report";
    begin
        FinancialReportName := NewFinancialReportName;
        if FinancialReportLocal.Get(FinancialReportName) then begin
            AccSchedNameHidden := FinancialReportLocal."Financial Report Row Group";
            AccSchedNameEditable := false;
        end;
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
        ContextInitialized := false;
        OnAfterSetFilters(AccScheduleName, CostCenterFilter, CostObjectFilter, CashFlowFilter, CurrReport.UseRequestPage());
    end;

    procedure SetFilters(NewDateFilter: Text; NewBudgetFilter: Text; NewCostBudgetFilter: Text; NewBusUnitFilter: Text; NewDim1Filter: Text; NewDim2Filter: Text; NewDim3Filter: Text; NewDim4Filter: Text; CashFlowFilter: Text)
    begin
        DateFilterHidden := NewDateFilter;
        if DateFilterHidden <> '' then begin
            "Acc. Schedule Line".SetFilter("Date Filter", DateFilterHidden);
            StartDate := "Acc. Schedule Line".GetRangeMin("Date Filter");
            EndDate := "Acc. Schedule Line".GetRangeMax("Date Filter");
        end;
        GLBudgetFilterHidden := NewBudgetFilter;
        CostBudgetFilterHidden := NewCostBudgetFilter;
        BusinessUnitFilterHidden := NewBusUnitFilter;
        Dim1FilterHidden := NewDim1Filter;
        Dim2FilterHidden := NewDim2Filter;
        Dim3FilterHidden := NewDim3Filter;
        Dim4FilterHidden := NewDim4Filter;
        CashFlowFilterHidden := CashFlowFilter;
        UseHiddenFilters := true;
        OnAfterSetFilters(AccScheduleName, CostCenterFilter, CostObjectFilter, CashFlowFilter, CurrReport.UseRequestPage());
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
        if DimValList.RunModal() = ACTION::LookupOK then begin
            DimValList.GetRecord(DimVal);
            Text := DimValList.GetSelectionFilter();
            UseHiddenFilters := false;
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
        FinancialReportLocal: Record "Financial Report";
    begin
        if GLBudgetName <> '' then
            GLBudgetFilter := GLBudgetName;
        GLSetup.Get();
        UseAmtsInAddCurrVisible := GLSetup."Additional Reporting Currency" <> '';
        BusinessUnitFilterVisible := not BusinessUnit.IsEmpty();
        if not UseAmtsInAddCurrVisible then
            UseAmtsInAddCurr := false;
        if not ContextInitialized then begin
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
            if CashFlowFilterHidden <> '' then
                CashFlowFilter := CashFlowFilterHidden;
        end;

        if FinancialReportName <> '' then
            if not FinancialReportLocal.Get(FinancialReportName) then
                FinancialReportName := '';

        if AccSchedName = '' then
            AccSchedName := FinancialReportLocal."Financial Report Row Group";
        if ColumnLayoutName = '' then
            ColumnLayoutName := FinancialReportLocal."Financial Report Column Group";

        if AccSchedName <> '' then
            if not AccScheduleName.Get(AccSchedName) then
                AccSchedName := '';
        if AccSchedName = '' then
            if AccScheduleName.FindFirst() then
                AccSchedName := AccScheduleName.Name;

        if FinancialReportLocal.Name <> '' then
            FinancialReportDescription := FinancialReportLocal.Description
        else
            FinancialReportDescription := AccScheduleName.Description;

        if not ColumnLayoutName2.Get(ColumnLayoutName) then
            if ColumnLayoutName2.FindFirst() then
                ColumnLayoutName := ColumnLayoutName2.Name;

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
            CashFlowFilter := CashFlowFilterHidden;
        end else begin
            if EndDate = 0D then
                EndDate := WorkDate();
            if StartDate = 0D then
                StartDate := CalcDate('<-CM>', EndDate);
            ValidateStartEndDate();
        end;
    end;

    local procedure SetBudgetFilterEnable()
    var
        ColumnLayout: Record "Column Layout";
    begin
        BudgetFilterEnable := true;
        StartDateEnabled := true;
        if ColumnLayoutName = '' then
            exit;
        if not AccSchedNameEditable then
            exit;
        ColumnLayout.SetRange("Column Layout Name", ColumnLayoutName);
        ColumnLayout.SetRange("Ledger Entry Type", ColumnLayout."Ledger Entry Type"::"Budget Entries");
        BudgetFilterEnable := not ColumnLayout.IsEmpty();
        if not BudgetFilterEnable then
            GLBudgetFilter := '';
        GLBudgetName := CopyStr(GLBudgetFilter, 1, MaxStrLen(GLBudgetName));
        ColumnLayout.SetRange("Ledger Entry Type");
        ColumnLayout.SetFilter("Column Type", '<>%1', ColumnLayout."Column Type"::"Balance at Date");
        StartDateEnabled := not ColumnLayout.IsEmpty();
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
    var
        FinancialReportToValidate: Record "Financial Report";
    begin
        if FinancialReportName <> '' then
            FinancialReportToValidate.Get(FinancialReportName);
        ValidateAccSchedName(FinancialReportToValidate);
    end;

    local procedure ValidateAccSchedName(var FinancialReport: Record "Financial Report")
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        AccSchedManagement.CheckName(AccSchedName);
        AccScheduleName.Get(AccSchedName);

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
        if FinancialReport.Name <> '' then
            RequestOptionsPage.Caption := FinancialReport.Description;
        RequestOptionsPage.Update(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferValues(var StartDate: Date; var EndDate: Date; var DateFilterHidden: Text);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFormatZeroAmount(var AccScheduleLine: Record "Acc. Schedule Line"; var ColumnLayout: Record "Column Layout"; var Result: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilters(var AccScheduleName: Record "Acc. Schedule Name"; CostCenterFilter: Text; CostObjectFilter: Text; CashFlowFilter: Text; UseReqPage: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetColumnLayoutOnAfteCheckIsLineSkipped(var AccScheduleLine: Record "Acc. Schedule Line"; var ValueIsEmpty: Boolean; var IsLineSkipped: Boolean)
    begin
    end;
}

