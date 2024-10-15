report 11782 "Balance Sheet"
{
    DefaultLayout = RDLC;
    RDLCLayout = './BalanceSheet.rdlc';
    AccessByPermission = TableData "G/L Account" = R;
    ApplicationArea = Basic, Suite;
    Caption = 'Balance Sheet (Obsolete)';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

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
                column(ShowAccSchedSetup; ShowAccSchedSetup)
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
                column(greCompanyInfo_Name; CompanyInfo.Name)
                {
                }
                column(gtcReportCaption; gtcReportCaptionLbl)
                {
                }
                dataitem(AccSchedLineSpec; "Acc. Schedule Line")
                {
                    DataItemLink = "Schedule Name" = FIELD(Name);
                    DataItemLinkReference = AccScheduleName;
                    DataItemTableView = SORTING("Schedule Name", "Line No.");
                    column(AccSchedLineSpec_Show; Show)
                    {
                    }
                    column(AccSchedLineSpec__Totaling_Type_; "Totaling Type")
                    {
                    }
                    column(AccSchedLineSpec_Totaling; Totaling)
                    {
                    }
                    column(AccSchedLineSpec_Description; Description)
                    {
                    }
                    column(AccSchedLineSpec__Row_No__; "Row No.")
                    {
                    }
                    column(AccSchedLineSpec__Row_Type_; "Row Type")
                    {
                    }
                    column(AccSchedLineSpec__Amount_Type_; "Amount Type")
                    {
                    }
                    column(Bold_format; Format(Bold))
                    {
                    }
                    column(Italic_format; Format(Italic))
                    {
                    }
                    column(Underline_format; Format(Underline))
                    {
                    }
                    column(ShowOppSign_format; Format("Show Opposite Sign"))
                    {
                    }
                    column(NewPage_format; Format("New Page"))
                    {
                    }
                    column(AnalysisView__Dimension_1_Code_; AnalysisView."Dimension 1 Code")
                    {
                    }
                    column(AccSchedLineSpec__Dimension_1_Totaling_; "Dimension 1 Totaling")
                    {
                    }
                    column(AnalysisView__Dimension_2_Code_; AnalysisView."Dimension 2 Code")
                    {
                    }
                    column(AccSchedLineSpec__Dimension_2_Totaling_; "Dimension 2 Totaling")
                    {
                    }
                    column(AnalysisView__Dimension_3_Code_; AnalysisView."Dimension 3 Code")
                    {
                    }
                    column(AccSchedLineSpec__Dimension_3_Totaling_; "Dimension 3 Totaling")
                    {
                    }
                    column(AnalysisView__Dimension_4_Code_; AnalysisView."Dimension 4 Code")
                    {
                    }
                    column(AccSchedLineSpec__Dimension_4_Totaling_; "Dimension 4 Totaling")
                    {
                    }
                    column(AccSchedLineSpec_Schedule_Name; "Schedule Name")
                    {
                    }
                    column(SetupLineShadowed; LineShadowed)
                    {
                    }
                    column(AccSchedLineSpec__Show_Opposite_Sign_Caption; AccSchedLineSpec__Show_Opposite_Sign_CaptionLbl)
                    {
                    }
                    column(AccSchedLineSpec_UnderlineCaption; AccSchedLineSpec_UnderlineCaptionLbl)
                    {
                    }
                    column(AccSchedLineSpec_ItalicCaption; AccSchedLineSpec_ItalicCaptionLbl)
                    {
                    }
                    column(AccSchedLineSpec_BoldCaption; AccSchedLineSpec_BoldCaptionLbl)
                    {
                    }
                    column(AccSchedLineSpec_ShowCaption; AccSchedLineSpec_ShowCaptionLbl)
                    {
                    }
                    column(AccSchedLineSpec__New_Page_Caption; AccSchedLineSpec__New_Page_CaptionLbl)
                    {
                    }
                    column(AccSchedLineSpec__Totaling_Type_Caption; AccSchedLineSpec__Totaling_Type_CaptionLbl)
                    {
                    }
                    column(AccSchedLineSpec_TotalingCaption; AccSchedLineSpec_TotalingCaptionLbl)
                    {
                    }
                    column(AnalysisView__Dimension_1_Code_Caption; AnalysisView__Dimension_1_Code_CaptionLbl)
                    {
                    }
                    column(AccSchedLineSpec__Row_Type_Caption; AccSchedLineSpec__Row_Type_CaptionLbl)
                    {
                    }
                    column(AccSchedLineSpec__Amount_Type_Caption; AccSchedLineSpec__Amount_Type_CaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if "Row No." <> '' then
                            LineShadowed := not LineShadowed
                        else
                            LineShadowed := false;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not ShowAccSchedSetup then
                            CurrReport.Break();

                        NextPageGroupNo += 1;
                    end;
                }
                dataitem(PageBreak; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));

                    trigger OnPreDataItem()
                    begin
                        if not ShowAccSchedSetup then
                            CurrReport.Break();
                    end;
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
                    column(Acc__Schedule_Line_Description; Description)
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
                    column(LineShadowed; LineShadowed)
                    {
                    }
                    dataitem(ColumnLayoutLoop; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 .. 4));
                        column(ColumnNo; TColLayoutTmp."Column No.")
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
                        column(LineSkipped; LineSkipped)
                        {
                        }
                        column(LineNo_ColumnLayout; Number)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            case Number of
                                1:
                                    if "Acc. Schedule Line"."Assets/Liabilities Type" = "Acc. Schedule Line"."Assets/Liabilities Type"::Assets then begin
                                        TColLayoutTmp.FindFirst;
                                        ColumnValuesDisplayed[Number] :=
                                          AccSchedManagement.CalcCell("Acc. Schedule Line", TColLayoutTmp, UseAmtsInAddCurr);
                                    end else begin
                                        TColLayoutTmp.FindFirst;
                                        ColumnValuesDisplayed[Number] :=
                                          AccSchedManagement.CalcCell("Acc. Schedule Line", TColLayoutTmp, UseAmtsInAddCurr);
                                    end;
                                2:
                                    if "Acc. Schedule Line"."Assets/Liabilities Type" = "Acc. Schedule Line"."Assets/Liabilities Type"::Assets then begin
                                        TColLayoutTmp.FindFirst;
                                        ColumnValuesDisplayed[Number] :=
                                          AccSchedManagement.CalcCorrectionCell("Acc. Schedule Line", TColLayoutTmp, UseAmtsInAddCurr);
                                    end else begin
                                        TColLayoutTmp.FindLast;
                                        ColumnValuesDisplayed[Number] :=
                                          AccSchedManagement.CalcCell("Acc. Schedule Line", TColLayoutTmp, UseAmtsInAddCurr);
                                    end;
                                3:
                                    if "Acc. Schedule Line"."Assets/Liabilities Type" = "Acc. Schedule Line"."Assets/Liabilities Type"::Assets then begin
                                        TColLayoutTmp.FindFirst;
                                        ColumnValuesDisplayed[Number] := ColumnValuesDisplayed[1] + ColumnValuesDisplayed[2];
                                    end else
                                        ColumnValuesDisplayed[Number] := 0;
                                4:
                                    if "Acc. Schedule Line"."Assets/Liabilities Type" = "Acc. Schedule Line"."Assets/Liabilities Type"::Assets then begin
                                        TColLayoutTmp.FindLast;
                                        ColumnValuesDisplayed[Number] :=
                                          AccSchedManagement.CalcCorrectionCell("Acc. Schedule Line", TColLayoutTmp, UseAmtsInAddCurr) +
                                          AccSchedManagement.CalcCell("Acc. Schedule Line", TColLayoutTmp, UseAmtsInAddCurr);
                                    end else
                                        ColumnValuesDisplayed[Number] := 0;
                            end;

                            if TColLayoutTmp.Show = TColLayoutTmp.Show::Never then
                                CurrReport.Skip();

                            RoundingHeader := '';

                            if TColLayoutTmp."Rounding Factor" in [TColLayoutTmp."Rounding Factor"::"1000", TColLayoutTmp."Rounding Factor"::"1000000"] then
                                case TColLayoutTmp."Rounding Factor" of
                                    TColLayoutTmp."Rounding Factor"::"1000":
                                        RoundingHeader := ThousandsTxt;
                                    TColLayoutTmp."Rounding Factor"::"1000000":
                                        RoundingHeader := MilionsTxt;
                                end;

                            if "Acc. Schedule Line"."Assets/Liabilities Type" = "Acc. Schedule Line"."Assets/Liabilities Type"::Assets then
                                case Number of
                                    1:
                                        Header := ActualAccPeriodBruttoTxt;
                                    2:
                                        Header := ActualAccPeriodCorrectionTxt;
                                    3:
                                        Header := ActualAccPeriodNettoTxt;
                                    4:
                                        Header := PreviousAccPeriodNettoTxt;
                                end
                            else
                                case Number of
                                    1:
                                        Header := ActualAccPeriodBalanceTxt;
                                    2:
                                        Header := PreviousAccPeriodBalanceTxt;
                                    3, 4:
                                        begin
                                            Header := '';
                                            RoundingHeader := '';
                                        end;
                                end;

                            ColumnValuesAsText := '';

                            if AccSchedManagement.GetDivisionError then begin
                                if ShowError in [ShowError::"Division by Zero", ShowError::Both] then
                                    ColumnValuesAsText := ErrorTxt;
                            end else
                                if AccSchedManagement.GetPeriodError then begin
                                    if ShowError in [ShowError::"Period Error", ShowError::Both] then
                                        ColumnValuesAsText := NotAvailTxt;
                                end else begin
                                    ColumnValuesAsText :=
                                      AccSchedManagement.FormatCellAsText(TColLayoutTmp, ColumnValuesDisplayed[Number], UseAmtsInAddCurr);

                                    if "Acc. Schedule Line"."Totaling Type" = "Acc. Schedule Line"."Totaling Type"::Formula then
                                        case "Acc. Schedule Line".Show of
                                            "Acc. Schedule Line".Show::"When Positive Balance":
                                                if ColumnValuesDisplayed[Number] < 0 then
                                                    ColumnValuesAsText := '';
                                            "Acc. Schedule Line".Show::"When Negative Balance":
                                                if ColumnValuesDisplayed[Number] > 0 then
                                                    ColumnValuesAsText := '';
                                            "Acc. Schedule Line".Show::"If Any Column Not Zero":
                                                if ColumnValuesDisplayed[Number] = 0 then
                                                    ColumnValuesAsText := '';
                                        end;
                                end;

                            if (ColumnValuesAsText <> '') or ("Acc. Schedule Line".Show = "Acc. Schedule Line".Show::Yes) then
                                LineSkipped := false;
                        end;

                        trigger OnPostDataItem()
                        begin
                            if LineSkipped then
                                LineShadowed := not LineShadowed;
                        end;

                        trigger OnPreDataItem()
                        var
                            i: Integer;
                        begin
                            for i := 1 to 4 do
                                ColumnValuesDisplayed[i] := 0;
                            LineSkipped := true;
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if (Show = Show::No) or not ShowLine(Bold, Italic) then
                            CurrReport.Skip();

                        if SkipEmptyLines then
                            if AccSchedManagement.EmptyLine("Acc. Schedule Line", ColumnLayoutName, UseAmtsInAddCurr) then
                                CurrReport.Skip();

                        Bold_control := Bold;
                        Italic_control := Italic;
                        Underline_control := Underline;
                        PageGroupNo := NextPageGroupNo;
                        if "New Page" then
                            NextPageGroupNo := PageGroupNo + 1;

                        if "Row No." <> '' then
                            LineShadowed := not LineShadowed
                        else
                            LineShadowed := false;
                    end;

                    trigger OnPreDataItem()
                    begin
                        PageGroupNo := NextPageGroupNo;

                        SetFilter("Date Filter", DateFilter);
                        SetFilter("G/L Budget Filter", GLBudgetFilter);
                        SetFilter("Cost Budget Filter", CostBudgetFilter);
                        SetFilter("Business Unit Filter", BusinessUnitFilter);
                        SetFilter("Cost Center Filter", CostCenterFilter);
                        SetFilter("Cost Object Filter", CostObjectFilter);
                        SetFilter("Cash Flow Forecast Filter", CashFlowFilter);
                        SetFilter("Dimension 1 Filter", Dim1Filter);
                        SetFilter("Dimension 2 Filter", Dim2Filter);
                        SetFilter("Dimension 3 Filter", Dim3Filter);
                        SetFilter("Dimension 4 Filter", Dim4Filter);
                    end;
                }
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
                    HeaderText := StrSubstNo(HeaderTextTxt, GLSetup."Additional Reporting Currency")
                else
                    if GLSetup."LCY Code" <> '' then
                        HeaderText := StrSubstNo(HeaderTextTxt, GLSetup."LCY Code")
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
                        field(AccSchedName; AccSchedName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Acc. Schedule Name';
                            Lookup = true;
                            TableRelation = "Acc. Schedule Name";
                            ToolTip = 'Specifies the name of the account schedule to be shown in the report.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                exit(AccSchedManagement.LookupName(AccSchedName, Text));
                            end;

                            trigger OnValidate()
                            begin
                                ValidateAccSchedName
                            end;
                        }
                        field(ColumnLayoutName; ColumnLayoutName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Column Layout Name';
                            Lookup = true;
                            TableRelation = "Column Layout Name".Name;
                            ToolTip = 'Specifies the name of the column layout that you want to use in the window.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                exit(AccSchedManagement.LookupColumnName(ColumnLayoutName, Text));
                            end;

                            trigger OnValidate()
                            begin
                                if ColumnLayoutName = '' then
                                    Error(ColLayoutNameErr);
                                AccSchedManagement.CheckColumnName(ColumnLayoutName);
                            end;
                        }
                    }
                    group(Filters)
                    {
                        Caption = 'Filters';
                        field(DateFilter; DateFilter)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Date Filter';
                            ToolTip = 'Specifies the date filter for G/L accounts entries.';

                            trigger OnValidate()
                            var
                                FilterTokens: Codeunit "Filter Tokens";
                            begin
                                FilterTokens.MakeDateFilter(DateFilter);
                                "Acc. Schedule Line".SetFilter("Date Filter", DateFilter);
                                DateFilter := "Acc. Schedule Line".GetFilter("Date Filter");
                            end;
                        }
                        field(GLBudgetFilter; GLBudgetFilter)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'G/L Budget Filter';
                            TableRelation = "G/L Budget Name".Name;
                            ToolTip = 'Specifies a general ledger budget filter for the report.';

                            trigger OnValidate()
                            begin
                                "Acc. Schedule Line".SetFilter("G/L Budget Filter", GLBudgetFilter);
                                GLBudgetFilter := "Acc. Schedule Line".GetFilter("G/L Budget Filter");
                            end;
                        }
                        field(CostBudgetFilter; CostBudgetFilter)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Budget Filter';
                            TableRelation = "Cost Budget Name".Name;
                            ToolTip = 'Specifies a cost budget filter for the report.';

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
                            LookupPageID = "Business Unit List";
                            TableRelation = "Business Unit";
                            ToolTip = 'Specifies a business unit filter for the report.';

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
                            ApplicationArea = Basic, Suite;
                            CaptionClass = FormGetCaptionClass(1);
                            Caption = 'Dimension 1 Filter';
                            Enabled = Dim1FilterEnable;
                            ToolTip = 'Specifies the filter for dimension 1.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                exit(FormLookUpDimFilter(AnalysisView."Dimension 1 Code", Text));
                            end;
                        }
                        field(Dim2Filter; Dim2Filter)
                        {
                            ApplicationArea = Basic, Suite;
                            CaptionClass = FormGetCaptionClass(2);
                            Caption = 'Dimension 2 Filter';
                            Enabled = Dim2FilterEnable;
                            ToolTip = 'Specifies the filter for dimension 2.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                exit(FormLookUpDimFilter(AnalysisView."Dimension 2 Code", Text));
                            end;
                        }
                        field(Dim3Filter; Dim3Filter)
                        {
                            ApplicationArea = Basic, Suite;
                            CaptionClass = FormGetCaptionClass(3);
                            Caption = 'Dimension 3 Filter';
                            Enabled = Dim3FilterEnable;
                            ToolTip = 'Specifies the filter for dimension 3.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                exit(FormLookUpDimFilter(AnalysisView."Dimension 3 Code", Text));
                            end;
                        }
                        field(Dim4Filter; Dim4Filter)
                        {
                            ApplicationArea = Basic, Suite;
                            CaptionClass = FormGetCaptionClass(4);
                            Caption = 'Dimension 4 Filter';
                            Enabled = Dim4FilterEnable;
                            ToolTip = 'Specifies the filter for dimension 4.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                exit(FormLookUpDimFilter(AnalysisView."Dimension 4 Code", Text));
                            end;
                        }
                        field(CostCenterFilter; CostCenterFilter)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Center Filter';
                            ToolTip = 'Specifies a cost center filter for the report.';

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
                            ToolTip = 'Specifies a cost object filter for the report.';

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
                            ToolTip = 'Specifies a cash flow filter for the report.';

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
                            OptionCaption = 'None,Division by Zero,Period Error,Both';
                            ToolTip = 'Specifies when the error is to be show';
                        }
                        field(UseAmtsInAddCurr; UseAmtsInAddCurr)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Show Amounts in Add. Reporting Currency';
                            MultiLine = true;
                            ToolTip = 'Specifies when the amounts in add. reporting currency is to be show';
                        }
                        field(ShowAccSchedSetup; ShowAccSchedSetup)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Show Account Schedule Setup';
                            MultiLine = true;
                            ToolTip = 'Specifies when the account schedule setup is to be show';
                        }
                        field(SkipEmptyLines; SkipEmptyLines)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Skip Empty Lines';
                            ToolTip = 'Specifies when the empty lines are to be skip';
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
        end;

        trigger OnOpenPage()
        begin
            TransferValues;
            UpdateFilters;

            GLSetup.Get();
            if AccSchedName <> '' then
                ValidateAccSchedName;
        end;
    }

    labels
    {
        AccSchedLineSpec_DescriptionCaptionLbl = 'Description';
        AccSchedLineSpec__Row_No__CaptionLbl = 'Row No.';
    }

    trigger OnPreReport()
    begin
        if AccSchedName = '' then begin
            if AccScheduleName.GetRangeMin(Name) <> AccScheduleName.GetRangeMax(Name) then
                Error(UniqueErr, AccScheduleName.TableCaption, AccScheduleName.FieldCaption(Name));
            AccSchedName := AccScheduleName.GetRangeMin(Name);
        end;

        InitAccSched;
        CompanyInfo.Get();
    end;

    var
        CompanyInfo: Record "Company Information";
        TColLayoutTmp: Record "Column Layout" temporary;
        AnalysisView: Record "Analysis View";
        GLSetup: Record "General Ledger Setup";
        AccSchedManagement: Codeunit AccSchedManagement;
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        AccSchedName: Code[10];
        AccSchedNameHidden: Code[10];
        ColumnLayoutName: Code[10];
        ColumnLayoutNameHidden: Code[10];
        EndDate: Date;
        ShowError: Option "None","Division by Zero","Period Error",Both;
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
        ColumnValuesDisplayed: array[4] of Decimal;
        ColumnValuesAsText: Text[30];
        PeriodText: Text;
        AccSchedLineFilter: Text;
        Header: Text[30];
        RoundingHeader: Text[30];
        UseAmtsInAddCurr: Boolean;
        ShowAccSchedSetup: Boolean;
        HeaderText: Text[100];
        Bold_control: Boolean;
        Italic_control: Boolean;
        Underline_control: Boolean;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        [InDataSet]
        Dim1FilterEnable: Boolean;
        [InDataSet]
        Dim2FilterEnable: Boolean;
        [InDataSet]
        Dim3FilterEnable: Boolean;
        [InDataSet]
        Dim4FilterEnable: Boolean;
        LineShadowed: Boolean;
        LineSkipped: Boolean;
        SkipEmptyLines: Boolean;
        ThousandsTxt: Label '(Thousands)';
        MilionsTxt: Label '(Millions)';
        ErrorTxt: Label '* ERROR *';
        HeaderTextTxt: Label 'All amounts are in %1.', Comment = '%1=Currency Code';
        NotAvailTxt: Label 'Not Available';
        ColLayoutNameErr: Label 'Enter the Column Layout Name.';
        UniqueErr: Label '%1 %2 must be unique.', Comment = '%1=Table caption of Acc. Schedule Name,%2=Field caption of Name';
        ColumnLayoutNameCaptionLbl: Label 'Column Layout';
        AccScheduleName_Name_CaptionLbl: Label 'Account Schedule';
        FiscalStartDateCaptionLbl: Label 'Fiscal Start Date';
        PeriodTextCaptionLbl: Label 'Period';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Account_ScheduleCaptionLbl: Label 'Account Schedule';
        AnalysisView_CodeCaptionLbl: Label 'Analysis View';
        AccSchedLineSpec__Show_Opposite_Sign_CaptionLbl: Label 'Show Opposite Sign';
        AccSchedLineSpec_UnderlineCaptionLbl: Label 'Underline';
        AccSchedLineSpec_ItalicCaptionLbl: Label 'Italic';
        AccSchedLineSpec_BoldCaptionLbl: Label 'Bold';
        AccSchedLineSpec_ShowCaptionLbl: Label 'Show';
        AccSchedLineSpec__New_Page_CaptionLbl: Label 'New Page';
        AccSchedLineSpec__Totaling_Type_CaptionLbl: Label 'Totaling Type';
        AccSchedLineSpec_TotalingCaptionLbl: Label 'Totaling';
        AnalysisView__Dimension_1_Code_CaptionLbl: Label 'Dimension Code';
        AccSchedLineSpec__Row_Type_CaptionLbl: Label 'Row Type';
        AccSchedLineSpec__Amount_Type_CaptionLbl: Label 'Amount Type';
        gtcReportCaptionLbl: Label 'Balance Sheet';
        ActualAccPeriodBruttoTxt: Label 'Actual Acc. Period Brutto';
        ActualAccPeriodCorrectionTxt: Label 'Actual Acc.Period Correction';
        ActualAccPeriodNettoTxt: Label 'Actual Acc.Period Netto';
        PreviousAccPeriodNettoTxt: Label 'Previous Acc.Period Netto';
        ActualAccPeriodBalanceTxt: Label 'Actual Acc.Period Balance';
        PreviousAccPeriodBalanceTxt: Label 'Previous Acc.Period Balance';

    [Scope('OnPrem')]
    procedure InitAccSched()
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

        EndDate := "Acc. Schedule Line".GetRangeMax("Date Filter");
        FiscalStartDate := AccountingPeriodMgt.FindFiscalYear(EndDate);

        AccSchedLineFilter := "Acc. Schedule Line".GetFilters;
        PeriodText := "Acc. Schedule Line".GetFilter("Date Filter");

        AccSchedManagement.CopyColumnsToTemp(ColumnLayoutName, TColLayoutTmp);
    end;

    [Scope('OnPrem')]
    procedure SetAccSchedName(NewAccSchedName: Code[10])
    begin
        AccSchedNameHidden := NewAccSchedName;
    end;

    [Scope('OnPrem')]
    procedure SetColumnLayoutName(ColLayoutName: Code[10])
    begin
        ColumnLayoutNameHidden := ColLayoutName;
    end;

    [Scope('OnPrem')]
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

    [Scope('OnPrem')]
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
        exit(AnalysisView.GetCaptionClass(DimNo));
    end;

    local procedure TransferValues()
    begin
        GLSetup.Get();
        if AccSchedNameHidden <> '' then
            AccSchedName := AccSchedNameHidden;
        if ColumnLayoutNameHidden <> '' then
            ColumnLayoutName := ColumnLayoutNameHidden;

        if AccSchedName <> '' then
            if not AccScheduleName.Get(AccSchedName) then
                AccSchedName := '';
        if AccSchedName = '' then
            if AccScheduleName.FindFirst then
                AccSchedName := AccScheduleName.Name;

        if AccScheduleName."Analysis View Name" <> '' then
            AnalysisView.Get(AccScheduleName."Analysis View Name")
        else begin
            AnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
            AnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
        end;
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
        end;

        if ColumnLayoutName = '' then
            if AccScheduleName.FindFirst then
                ColumnLayoutName := AccScheduleName."Default Column Layout";
    end;

    [Scope('OnPrem')]
    procedure ValidateAccSchedName()
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
    end;
}

