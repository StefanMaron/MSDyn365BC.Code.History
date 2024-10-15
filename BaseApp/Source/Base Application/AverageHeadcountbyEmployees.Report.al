report 17374 "Average Headcount by Employees"
{
    DefaultLayout = RDLC;
    RDLCLayout = './AverageHeadcountbyEmployees.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Average Headcount by Employees';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Employee; Employee)
        {
            DataItemTableView = SORTING("No.") WHERE("Skip for Avg. HC Calculation" = CONST(false));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(FORMAT_StartDate____________FORMAT_EndDate_; Format(StartDate) + ' - ' + Format(EndDate))
            {
            }
            column(Employee__No__; "No.")
            {
            }
            column(Last_Name___________First_Name_; "Last Name" + ' ' + "First Name")
            {
            }
            column(Employee_Gender; Gender)
            {
            }
            column(Employee__Skip_for_Avg__HC_Calculation_; "Skip for Avg. HC Calculation")
            {
            }
            column(Person__Single_Parent_; Person."Single Parent")
            {
            }
            column(Employee__Calendar_Code_; "Calendar Code")
            {
            }
            column(AvgAmt; AvgAmt)
            {
            }
            column(TotalAvgAmt; TotalAvgAmt)
            {
            }
            column(Employee__No__Caption; FieldCaption("No."))
            {
            }
            column(Last_Name___________First_Name_Caption; Last_Name___________First_Name_CaptionLbl)
            {
            }
            column(Employee_GenderCaption; FieldCaption(Gender))
            {
            }
            column(Employee__Skip_for_Avg__HC_Calculation_Caption; FieldCaption("Skip for Avg. HC Calculation"))
            {
            }
            column(Person__Single_Parent_Caption; Person__Single_Parent_CaptionLbl)
            {
            }
            column(Detailed_information_for_average_headcount_calculationCaption; Detailed_information_for_average_headcount_calculationCaptionLbl)
            {
            }
            column(Employee_Job_Entry__Work_Mode_Caption; "Employee Job Entry".FieldCaption("Work Mode"))
            {
            }
            column(Employee__Calendar_Code_Caption; FieldCaption("Calendar Code"))
            {
            }
            column(AvgAmtCaption; AvgAmtCaptionLbl)
            {
            }
            column(Data_from_personal_cardCaption; Data_from_personal_cardCaptionLbl)
            {
            }
            column(Data_from_employee_qualificationCaption; Data_from_employee_qualificationCaptionLbl)
            {
            }
            column(PeriodCaption; PeriodCaptionLbl)
            {
            }
            column(RateCaption; RateCaptionLbl)
            {
            }
            column(Position_typeCaption; Position_typeCaptionLbl)
            {
            }
            dataitem("Employee Job Entry"; "Employee Job Entry")
            {
                DataItemLink = "Employee No." = FIELD("No.");
                DataItemTableView = SORTING("Employee No.", "Starting Date", "Ending Date");
                column(Employee_Job_Entry__Starting_Date_; "Starting Date")
                {
                }
                column(Employee_Job_Entry__Ending_Date_; "Ending Date")
                {
                }
                column(Position__Base_Salary_; Position."Base Salary")
                {
                }
                column(Employee_Job_Entry__Kind_of_Work_; "Kind of Work")
                {
                }
                column(Employee_Job_Entry__Work_Mode_; "Work Mode")
                {
                }
                column(Employee_Job_Entry_Entry_No_; "Entry No.")
                {
                }
                column(Employee_Job_Entry_Employee_No_; "Employee No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Position.Get("Position No.");
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter("Starting Date", '<=%1', EndDate);
                    SetFilter("Ending Date", '%1|>=%2', 0D, StartDate);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Person.Get("Person No.");
                AvgAmt := AverageHeadcountCalculation.CalcAvgCount("No.", StartDate);
                TotalAvgAmt += AvgAmt;
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
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Starting Date';

                        trigger OnValidate()
                        begin
                            StartDateOnAfterValidate;
                        end;
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Ending Date';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            StartDate := CalcDate('<-CM>', WorkDate);
            EndDate := CalcDate('<CM>', StartDate);
        end;
    }

    labels
    {
    }

    var
        Person: Record Person;
        Position: Record Position;
        AverageHeadcountCalculation: Codeunit "Average Headcount Calculation";
        StartDate: Date;
        EndDate: Date;
        AvgAmt: Decimal;
        TotalAvgAmt: Decimal;
        Last_Name___________First_Name_CaptionLbl: Label 'FIO';
        Person__Single_Parent_CaptionLbl: Label 'Label1470013';
        Detailed_information_for_average_headcount_calculationCaptionLbl: Label 'Detailed information for average headcount calculation';
        AvgAmtCaptionLbl: Label 'Avg. Amount';
        Data_from_personal_cardCaptionLbl: Label 'Data from personal card';
        Data_from_employee_qualificationCaptionLbl: Label 'Data from employee qualification';
        PeriodCaptionLbl: Label 'Period';
        RateCaptionLbl: Label 'Rate';
        Position_typeCaptionLbl: Label 'Position type';

    local procedure StartDateOnAfterValidate()
    begin
        EndDate := CalcDate('<CM>', StartDate);
    end;
}

