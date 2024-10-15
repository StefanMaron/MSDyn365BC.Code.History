report 17400 "Payroll Calculation - Setup"
{
    DefaultLayout = RDLC;
    RDLCLayout = './PayrollCalculationSetup.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Payroll Calculation - Setup';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Payroll Element"; "Payroll Element")
        {
            DataItemTableView = WHERE(Calculate = CONST(true));
            RequestFilterFields = "Code", Type, "Include into Calculation by";
            column(CompanyInfo_Name; CompanyInfo.Name)
            {
            }
            column(SubTitle; SubTitle)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(USERID; UserId)
            {
            }
            column(TIME; Time)
            {
            }
            column(CurrReport_PAGENO; CurrReport.PageNo)
            {
            }
            column(FilterLine; FilterLine)
            {
            }
            column(Payroll_Element_Code; Code)
            {
            }
            column(Payroll_Element_Type; Type)
            {
            }
            column(Payroll_Element__Element_Group_; "Element Group")
            {
            }
            column(Payroll_Element_Description; Description)
            {
            }
            column(Payroll_Element__Posting_Type_; "Posting Type")
            {
            }
            column(Payroll_Element__Bonus_Type_; "Bonus Type")
            {
            }
            column(Payroll_Element__FSI_Base_; "FSI Base")
            {
            }
            column(Payroll_Element__Federal_FMI_Base_; "Federal FMI Base")
            {
            }
            column(Payroll_Element__Territorial_FMI_Base_; "Territorial FMI Base")
            {
            }
            column(Payroll_Element__Income_Tax_Base_; "Income Tax Base")
            {
            }
            column(Payroll_Element__PF_Base_; "PF Base")
            {
            }
            column(Payroll_Element__FSI_Injury_Base_; "FSI Injury Base")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Payroll_Calculation_SetupCaption; Payroll_Calculation_SetupCaptionLbl)
            {
            }
            column(Payroll_Element_CodeCaption; FieldCaption(Code))
            {
            }
            column(Payroll_Element_TypeCaption; FieldCaption(Type))
            {
            }
            column(Payroll_Element__Element_Group_Caption; FieldCaption("Element Group"))
            {
            }
            column(Payroll_Element_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Payroll_Element__Posting_Type_Caption; FieldCaption("Posting Type"))
            {
            }
            column(Payroll_Element__Bonus_Type_Caption; FieldCaption("Bonus Type"))
            {
            }
            column(Payroll_Element__FSI_Base_Caption; FieldCaption("FSI Base"))
            {
            }
            column(Payroll_Element__Federal_FMI_Base_Caption; FieldCaption("Federal FMI Base"))
            {
            }
            column(Payroll_Element__Territorial_FMI_Base_Caption; FieldCaption("Territorial FMI Base"))
            {
            }
            column(Payroll_Element__Income_Tax_Base_Caption; FieldCaption("Income Tax Base"))
            {
            }
            column(Payroll_Element__PF_Base_Caption; FieldCaption("PF Base"))
            {
            }
            column(Payroll_Element__FSI_Injury_Base_Caption; FieldCaption("FSI Injury Base"))
            {
            }
            dataitem("Payroll Calculation"; "Payroll Calculation")
            {
                DataItemLink = "Element Code" = FIELD(Code);
                DataItemTableView = SORTING("Element Code", "Period Code");
                PrintOnlyIfDetail = true;
                column(PayrollCalculation2_TABLECAPTION; PayrollCalculation2.TableCaption)
                {
                }
                column(Payroll_Calculation__Period_Code_; "Period Code")
                {
                }
                column(Payroll_Calculation_Description; Description)
                {
                }
                column(Payroll_Calculation__Period_Code_Caption; FieldCaption("Period Code"))
                {
                }
                column(Payroll_Calculation_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(Payroll_Calculation_Element_Code; "Element Code")
                {
                }
                dataitem("Payroll Calculation Line"; "Payroll Calculation Line")
                {
                    DataItemLink = "Element Code" = FIELD("Element Code"), "Period Code" = FIELD("Period Code");
                    DataItemTableView = SORTING("Element Code", "Period Code", "Line No.");
                    column(Payroll_Calculation_Line__Function_Code_; "Function Code")
                    {
                    }
                    column(FORMAT_PayrollCalcFunction__Range_Type__; Format(PayrollCalcFunction."Range Type"))
                    {
                    }
                    column(Payroll_Calculation_Line__Range_Code_; "Range Code")
                    {
                    }
                    column(Payroll_Calculation_Line__Base_Amount_Code_; "Base Amount Code")
                    {
                    }
                    column(Payroll_Calculation_Line__Time_Activity_Group_; "Time Activity Group")
                    {
                    }
                    column(ShowCodeLine; ShowCodeLine)
                    {
                    }
                    column(Payroll_Calculation_Line__Function_Code_Caption; FieldCaption("Function Code"))
                    {
                    }
                    column(ShowCodeLineCaption; ShowCodeLineCaptionLbl)
                    {
                    }
                    column(FORMAT_PayrollCalcFunction__Range_Type__Caption; FORMAT_PayrollCalcFunction__Range_Type__CaptionLbl)
                    {
                    }
                    column(Payroll_Calculation_Line__Range_Code_Caption; FieldCaption("Range Code"))
                    {
                    }
                    column(Payroll_Calculation_Line__Base_Amount_Code_Caption; FieldCaption("Base Amount Code"))
                    {
                    }
                    column(Payroll_Calculation_Line__Time_Activity_Group_Caption; FieldCaption("Time Activity Group"))
                    {
                    }
                    column(Payroll_Calculation_Line_Element_Code; "Element Code")
                    {
                    }
                    column(Payroll_Calculation_Line_Period_Code; "Period Code")
                    {
                    }
                    column(Payroll_Calculation_Line_Line_No_; "Line No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if not PayrollCalcFunction.Get("Function Code") then
                            PayrollCalcFunction.Description := '';
                    end;
                }

                trigger OnPreDataItem()
                begin
                    SetRange("Period Code", LatestPeriodCode, PeriodTo);
                end;
            }
            dataitem("Payroll Base Amount"; "Payroll Base Amount")
            {
                DataItemLink = "Element Code" = FIELD(Code);
                DataItemTableView = SORTING("Element Code", Code);
                column(Payroll_Base_Amount__Element_Type_Filter_; "Element Type Filter")
                {
                }
                column(Payroll_Base_Amount__Element_Group_Filter_; "Element Group Filter")
                {
                }
                column(Payroll_Base_Amount__Element_Code_Filter_; "Element Code Filter")
                {
                }
                column(Payroll_Base_Amount__Posting_Type_Filter_; "Posting Type Filter")
                {
                }
                column(Payroll_Base_Amount__Income_Tax_Base_Filter_; "Income Tax Base Filter")
                {
                }
                column(Payroll_Base_Amount__PF_Base_Filter_; "PF Base Filter")
                {
                }
                column(Payroll_Base_Amount__FSI_Base_Filter_; "FSI Base Filter")
                {
                }
                column(Payroll_Base_Amount__Federal_FMI_Base_Filter_; "Federal FMI Base Filter")
                {
                }
                column(Payroll_Base_Amount__Territorial_FMI_Base_Filter_; "Territorial FMI Base Filter")
                {
                }
                column(Payroll_Base_Amount__FSI_Injury_Base_Filter_; "FSI Injury Base Filter")
                {
                }
                column(Base_FiltersCaption; Base_FiltersCaptionLbl)
                {
                }
                column(Payroll_Base_Amount__Element_Type_Filter_Caption; FieldCaption("Element Type Filter"))
                {
                }
                column(Payroll_Base_Amount__Element_Group_Filter_Caption; FieldCaption("Element Group Filter"))
                {
                }
                column(Payroll_Base_Amount__Element_Code_Filter_Caption; FieldCaption("Element Code Filter"))
                {
                }
                column(Payroll_Base_Amount__Posting_Type_Filter_Caption; FieldCaption("Posting Type Filter"))
                {
                }
                column(Payroll_Base_Amount__Income_Tax_Base_Filter_Caption; FieldCaption("Income Tax Base Filter"))
                {
                }
                column(Payroll_Base_Amount__PF_Base_Filter_Caption; FieldCaption("PF Base Filter"))
                {
                }
                column(Payroll_Base_Amount__FSI_Base_Filter_Caption; FieldCaption("FSI Base Filter"))
                {
                }
                column(Payroll_Base_Amount__Federal_FMI_Base_Filter_Caption; FieldCaption("Federal FMI Base Filter"))
                {
                }
                column(Payroll_Base_Amount__Territorial_FMI_Base_Filter_Caption; FieldCaption("Territorial FMI Base Filter"))
                {
                }
                column(Payroll_Base_Amount__FSI_Injury_Base_Filter_Caption; FieldCaption("FSI Injury Base Filter"))
                {
                }
                column(Payroll_Base_Amount_Element_Code; "Element Code")
                {
                }
                column(Payroll_Base_Amount_Code; Code)
                {
                }
                dataitem("Payroll Element 2"; "Payroll Element")
                {
                    DataItemTableView = SORTING(Code);
                    column(Payroll_Element_2_Type; Type)
                    {
                    }
                    column(Payroll_Element_2_Code; Code)
                    {
                    }
                    column(Payroll_Element_2__Element_Group_; "Element Group")
                    {
                    }
                    column(Payroll_Element_2_Description; Description)
                    {
                    }
                    column(Base_ElementsCaption; Base_ElementsCaptionLbl)
                    {
                    }
                    column(Payroll_Element_2_TypeCaption; FieldCaption(Type))
                    {
                    }
                    column(Payroll_Element_2_CodeCaption; FieldCaption(Code))
                    {
                    }
                    column(Payroll_Element_2__Element_Group_Caption; FieldCaption("Element Group"))
                    {
                    }
                    column(Payroll_Element_2_DescriptionCaption; FieldCaption(Description))
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        SetFilter(Code, "Payroll Base Amount"."Element Code Filter");
                        SetFilter(Type, "Payroll Base Amount"."Element Type Filter");
                        SetFilter("Element Group", "Payroll Base Amount"."Element Group Filter");
                        SetFilter("Posting Type", "Payroll Base Amount"."Posting Type Filter");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if ("Element Code Filter" = '') and
                       ("Element Type Filter" = '') and
                       ("Element Group Filter" = '') and
                       ("Posting Type Filter" = '')
                    then
                        CurrReport.Skip;

                    // IF NOT BaseAmountFound THEN
                    // BaseAmountFound := TRUE;
                end;
            }
            dataitem("Payroll Range Header"; "Payroll Range Header")
            {
                DataItemLink = "Element Code" = FIELD(Code);
                DataItemTableView = SORTING("Element Code", Code, "Period Code");
                PrintOnlyIfDetail = true;
                column(RangeHeader_TABLECAPTION; RangeHeader.TableCaption)
                {
                }
                column(Payroll_Range_Header_Description; Description)
                {
                }
                column(Payroll_Range_Header_Description_Control1210078; Description)
                {
                }
                column(Payroll_Range_Header__Range_Type_; "Range Type")
                {
                }
                column(Payroll_Range_Header__Period_Code_; "Period Code")
                {
                }
                column(Payroll_Range_Header__Range_Type_Caption; FieldCaption("Range Type"))
                {
                }
                column(Payroll_Range_Header__Period_Code_Caption; FieldCaption("Period Code"))
                {
                }
                column(Payroll_Range_Header_Element_Code; "Element Code")
                {
                }
                column(Payroll_Range_Header_Code; Code)
                {
                }
                dataitem("Payroll Range Line"; "Payroll Range Line")
                {
                    DataItemLink = "Range Code" = FIELD(Code), "Element Code" = FIELD("Element Code"), "Period Code" = FIELD("Period Code");
                    DataItemTableView = SORTING("Element Code", "Range Code", "Period Code", "Line No.");
                    column(Payroll_Range_Line__Over_Amount_; "Over Amount")
                    {
                    }
                    column(Payroll_Range_Line_Limit; Limit)
                    {
                    }
                    column(Payroll_Range_Line__Tax___; "Tax %")
                    {
                    }
                    column(Payroll_Range_Line_Percent; Percent)
                    {
                    }
                    column(Payroll_Range_Line_Quantity; Quantity)
                    {
                    }
                    column(Payroll_Range_Line__Tax_Amount_; "Tax Amount")
                    {
                    }
                    column(Payroll_Range_Line_Amount; Amount)
                    {
                    }
                    column(Payroll_Range_Line__Increase_Wage_; "Increase Wage")
                    {
                    }
                    column(Payroll_Range_Line__Max_Deduction_; "Max Deduction")
                    {
                    }
                    column(Payroll_Range_Line__Min_Amount_; "Min Amount")
                    {
                    }
                    column(Payroll_Range_Line__Max_Amount_; "Max Amount")
                    {
                    }
                    column(Payroll_Range_Line__On_Allowance_; "On Allowance")
                    {
                    }
                    column(Payroll_Range_Line__From_Allowance_; "From Allowance")
                    {
                    }
                    column(Payroll_Range_Line__Max___; "Max %")
                    {
                    }
                    column(Payroll_Range_Line__Directory_Code_; "Directory Code")
                    {
                    }
                    column(Payroll_Range_Line__Employee_Gender_; "Employee Gender")
                    {
                    }
                    column(Payroll_Range_Line__From_Birthday_and_Younger_; "From Birthday and Younger")
                    {
                    }
                    column(Payroll_Range_Line_Age; Age)
                    {
                    }
                    column(Payroll_Range_Line__Disabled_Person_; "Disabled Person")
                    {
                    }
                    column(Payroll_Range_Line_Student; Student)
                    {
                    }
                    column(Payroll_Range_Line__Over_Amount_Caption; FieldCaption("Over Amount"))
                    {
                    }
                    column(Payroll_Range_Line_LimitCaption; FieldCaption(Limit))
                    {
                    }
                    column(Payroll_Range_Line__Tax___Caption; FieldCaption("Tax %"))
                    {
                    }
                    column(Payroll_Range_Line_PercentCaption; FieldCaption(Percent))
                    {
                    }
                    column(Payroll_Range_Line_QuantityCaption; FieldCaption(Quantity))
                    {
                    }
                    column(Payroll_Range_Line__Tax_Amount_Caption; FieldCaption("Tax Amount"))
                    {
                    }
                    column(Payroll_Range_Line_AmountCaption; FieldCaption(Amount))
                    {
                    }
                    column(Payroll_Range_Line__Increase_Wage_Caption; FieldCaption("Increase Wage"))
                    {
                    }
                    column(Payroll_Range_Line__Max_Deduction_Caption; FieldCaption("Max Deduction"))
                    {
                    }
                    column(Payroll_Range_Line__Min_Amount_Caption; FieldCaption("Min Amount"))
                    {
                    }
                    column(Payroll_Range_Line__Max_Amount_Caption; FieldCaption("Max Amount"))
                    {
                    }
                    column(Payroll_Range_Line__Max___Caption; FieldCaption("Max %"))
                    {
                    }
                    column(Payroll_Range_Line__On_Allowance_Caption; FieldCaption("On Allowance"))
                    {
                    }
                    column(Payroll_Range_Line__From_Allowance_Caption; FieldCaption("From Allowance"))
                    {
                    }
                    column(Payroll_Range_Line__Directory_Code_Caption; FieldCaption("Directory Code"))
                    {
                    }
                    column(Payroll_Range_Line__From_Birthday_and_Younger_Caption; FieldCaption("From Birthday and Younger"))
                    {
                    }
                    column(Payroll_Range_Line__Employee_Gender_Caption; FieldCaption("Employee Gender"))
                    {
                    }
                    column(Payroll_Range_Line_AgeCaption; FieldCaption(Age))
                    {
                    }
                    column(Payroll_Range_Line__Disabled_Person_Caption; FieldCaption("Disabled Person"))
                    {
                    }
                    column(Payroll_Range_Line_StudentCaption; FieldCaption(Student))
                    {
                    }
                    column(Payroll_Range_Line_Element_Code; "Element Code")
                    {
                    }
                    column(Payroll_Range_Line_Range_Code; "Range Code")
                    {
                    }
                    column(Payroll_Range_Line_Period_Code; "Period Code")
                    {
                    }
                    column(Payroll_Range_Line_Line_No_; "Line No.")
                    {
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if "Period Code" < PeriodFrom then begin
                        RangeHeader.SetRange("Element Code", "Element Code");
                        RangeHeader.SetRange(Code, Code);
                        RangeHeader.SetRange("Period Code", "Period Code", PeriodFrom);
                        if RangeHeader.FindLast then
                            if RangeHeader."Period Code" > "Period Code" then
                                CurrReport.Skip;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Period Code", '', PeriodTo);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                PayrollCalculation2.Reset;
                PayrollCalculation2.SetRange("Element Code", Code);
                PayrollCalculation2.SetRange("Period Code", '', PeriodTo);
                if PayrollCalculation2.FindLast then
                    LatestPeriodCode := PayrollCalculation2."Period Code"
                else
                    LatestPeriodCode := '';
            end;

            trigger OnPreDataItem()
            begin
                if PeriodTo = '' then
                    Error(Text001);
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
                    field(PeriodFrom; PeriodFrom)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period From';
                        TableRelation = "Payroll Period";
                    }
                    field(PeriodTo; PeriodTo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period To';
                        TableRelation = "Payroll Period";
                    }
                    field(NewPageperElement; NewPageperElement)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Element';
                    }
                    field(PrintBaseAmounts; PrintBaseAmounts)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Base Filters';
                    }
                    field(PrintBaseElements; PrintBaseElements)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Base Elements';
                    }
                    field(PrintCalculations; PrintCalculations)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Calculation';
                    }
                    field(PrintRanges; PrintRanges)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Ranges';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            PeriodTo :=
              PayrollPeriod.PeriodByDate(WorkDate);
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CompanyInfo.Get;

        FilterLine := CopyStr("Payroll Element".GetFilters, 1, MaxStrLen(FilterLine));

        RangeHeader.SetCurrentKey("Element Code", Code, "Period Code");
    end;

    var
        CompanyInfo: Record "Company Information";
        PayrollCalculation2: Record "Payroll Calculation";
        PayrollCalcFunction: Record "Payroll Calculation Function";
        RangeHeader: Record "Payroll Range Header";
        PayrollPeriod: Record "Payroll Period";
        SubTitle: Text[250];
        LatestPeriodCode: Code[10];
        PrintBaseAmounts: Boolean;
        PrintBaseElements: Boolean;
        PrintRanges: Boolean;
        PrintCalculations: Boolean;
        FilterLine: Text[126];
        NewPageperElement: Boolean;
        PeriodFrom: Code[10];
        PeriodTo: Code[10];
        Text001: Label 'Please enter Period To.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Payroll_Calculation_SetupCaptionLbl: Label 'Payroll Calculation Setup';
        ShowCodeLineCaptionLbl: Label 'Expression';
        FORMAT_PayrollCalcFunction__Range_Type__CaptionLbl: Label 'Range Type';
        Base_FiltersCaptionLbl: Label 'Base Filters';
        Base_ElementsCaptionLbl: Label 'Base Elements';
}

