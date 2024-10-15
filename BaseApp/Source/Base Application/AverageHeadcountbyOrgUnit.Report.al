report 17375 "Average Headcount by Org. Unit"
{
    DefaultLayout = RDLC;
    RDLCLayout = './AverageHeadcountbyOrgUnit.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Average Headcount by Org. Unit';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Organizational Unit"; "Organizational Unit")
        {
            DataItemTableView = SORTING(Code);
            RequestFilterFields = "Code", Purpose;
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(CurrReport_PAGENO; CurrReport.PageNo)
            {
            }
            column(USERID; UserId)
            {
            }
            column(AccountPeriod; AccountPeriod)
            {
            }
            column(Month1; Month1)
            {
            }
            column(Month2; Month2)
            {
            }
            column(Month3; Month3)
            {
            }
            column(Quarter; Quarter)
            {
            }
            column(CurrReport_PAGENO_Control34; CurrReport.PageNo)
            {
            }
            column(Month1_Control42; Month1)
            {
            }
            column(Month2_Control47; Month2)
            {
            }
            column(Month3_Control48; Month3)
            {
            }
            column(Quarter_Control50; Quarter)
            {
            }
            column(Organizational_Unit_Name; Name)
            {
            }
            column(Organizational_Unit_Code; Code)
            {
            }
            column(AccrualPrint_1_; AccrualPrint[1])
            {
            }
            column(AccrualPrint_2_; AccrualPrint[2])
            {
            }
            column(AccrualPrint_3_; AccrualPrint[3])
            {
            }
            column(AccrualPrint_4_; AccrualPrint[4])
            {
            }
            column(AccrualPrint_1__Control27; AccrualPrint[1])
            {
            }
            column(AccrualPrint_2__Control29; AccrualPrint[2])
            {
            }
            column(AccrualPrint_3__Control31; AccrualPrint[3])
            {
            }
            column(AccrualPrint_4__Control38; AccrualPrint[4])
            {
            }
            column(Average_employee_headcountCaption; Average_employee_headcountCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(forCaption; forCaptionLbl)
            {
            }
            column(Org__Unit_CodeCaption; Org__Unit_CodeCaptionLbl)
            {
            }
            column(Organizational_Unit_NameCaption; FieldCaption(Name))
            {
            }
            column(CurrReport_PAGENO_Control34Caption; CurrReport_PAGENO_Control34CaptionLbl)
            {
            }
            column(Org__Unit_CodeCaption_Control78; Org__Unit_CodeCaption_Control78Lbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(Engineer_for_labour_organization_and_normingCaption; Engineer_for_labour_organization_and_normingCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                for J := 1 to 3 do
                    AccrualPrint[J] := 0;

                StartDate := StartDateInital;
                EndDate := EndDateInital;

                for J := 1 to 3 do begin
                    Employee.Reset;
                    Employee.SetRange("Org. Unit Code", Code);
                    if EmplCategory <> '' then
                        Employee.SetRange("Statistics Group Code", EmplCategory);
                    Employee.SetRange("Skip for Avg. HC Calculation", false);
                    if Employee.FindSet then
                        repeat
                            AccrualPrint[J] += Round(AverageHeadcountCalculation.CalcAvgCount(Employee."No.", StartDate));
                        until Employee.Next = 0;

                    StartDate := CalcDate('<1M>', StartDate);
                    EndDate := CalcDate('<CM>', StartDate);
                end;

                AccrualPrint[4] := Round((AccrualPrint[1] + AccrualPrint[2] + AccrualPrint[3]) / 3);
            end;

            trigger OnPreDataItem()
            begin
                Month1 := LocMgt.GetMonthName(StartDate, false);
                Month2 := LocMgt.GetMonthName(CalcDate('<+1M>', StartDate), false);
                Month3 := LocMgt.GetMonthName(CalcDate('<+2M>', StartDate), false);

                Quarter := Text14702 + Format(DatePeriod."Period No.") + Text14703;

                if StartDate = 0D then
                    Error(Text14704);
                if EndDate = 0D then
                    Error(Text14705);

                EndDate := CalcDate('<CM>', StartDate);

                StartDateInital := StartDate;
                EndDateInital := EndDate;

                JournalFilter := "Organizational Unit".GetFilters;
                if EmplCategory <> '' then
                    JournalFilter := JournalFilter + Text14706 + EmplCategory;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AccountingPeriodTextBox; AccountPeriod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Accounting Period';
                        ToolTip = 'Specifies the accounting period to include data for.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            PeriodReportManagement.SelectPeriod(Text, CalendarPeriod, false);
                            DatePeriod.Copy(CalendarPeriod);
                            PeriodReportManagement.PeriodSetup(DatePeriod, false);
                            StartDate := DatePeriod."Period Start";
                            EndDate := DatePeriod."Period End";
                            RequestOptionsPage.Update(false);
                            exit(true);
                        end;

                        trigger OnValidate()
                        begin
                            DatePeriod.Copy(CalendarPeriod);
                            PeriodReportManagement.PeriodSetup(DatePeriod, false);
                            StartDate := DatePeriod."Period Start";
                            EndDate := DatePeriod."Period End";
                        end;
                    }
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Starting Date';
                        Editable = false;
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Ending Date';
                        Editable = false;
                    }
                    field(EmplCategory; EmplCategory)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Employee Category';
                        TableRelation = "Employee Statistics Group";
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            DatePeriod.SetRange("Period Type", 3);
            DatePeriod.SetRange("Period Start", 0D, WorkDate);
            if DatePeriod.FindLast then;

            CalendarPeriod.Copy(DatePeriod);

            PeriodReportManagement.PeriodSetup(DatePeriod, false);
            PeriodReportManagement.SetCaptionPeriodYear(AccountPeriod, CalendarPeriod, false);
            StartDate := DatePeriod."Period Start";
            EndDate := DatePeriod."Period End";
        end;
    }

    labels
    {
    }

    var
        Employee: Record Employee;
        CalendarPeriod: Record Date;
        DatePeriod: Record Date;
        LocMgt: Codeunit "Localisation Management";
        AverageHeadcountCalculation: Codeunit "Average Headcount Calculation";
        PeriodReportManagement: Codeunit PeriodReportManagement;
        J: Integer;
        StartDate: Date;
        EndDate: Date;
        StartDateInital: Date;
        EndDateInital: Date;
        Month1: Text[30];
        Month2: Text[30];
        Month3: Text[30];
        Quarter: Text[30];
        JournalFilter: Text[200];
        AccountPeriod: Text[30];
        AccrualPrint: array[4] of Decimal;
        EmplCategory: Code[10];
        Text14702: Label 'Total for ';
        Text14703: Label ' quarter';
        Text14704: Label 'Please enter Period Start Date';
        Text14705: Label 'Please enter Period End Date';
        Text14706: Label ', Employee Category - ';
        Average_employee_headcountCaptionLbl: Label 'Average employee headcount';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        forCaptionLbl: Label 'for';
        Org__Unit_CodeCaptionLbl: Label 'Org. Unit Code';
        CurrReport_PAGENO_Control34CaptionLbl: Label 'Page';
        Org__Unit_CodeCaption_Control78Lbl: Label 'Org. Unit Code';
        NameCaptionLbl: Label 'Name';
        TotalCaptionLbl: Label 'Total';
        Engineer_for_labour_organization_and_normingCaptionLbl: Label 'Engineer for labour organization and norming';
}

