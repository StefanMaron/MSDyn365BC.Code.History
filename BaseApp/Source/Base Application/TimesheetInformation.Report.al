report 17440 "Timesheet Information"
{
    DefaultLayout = RDLC;
    RDLCLayout = './TimesheetInformation.rdlc';
    Caption = 'Timesheet Information';

    dataset
    {
        dataitem("Timesheet Status"; "Timesheet Status")
        {
            DataItemTableView = SORTING("Period Code", "Employee No.");
            RequestFilterFields = "Period Code", "Employee No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(USERID; UserId)
            {
            }
            column(Timesheet_Status__Employee_No__; "Employee No.")
            {
            }
            column(Timesheet_Status_Status; Status)
            {
            }
            column(Timesheet_Status__Calendar_Days_; "Calendar Days")
            {
            }
            column(Timesheet_Status__Planned_Work_Days_; "Planned Work Days")
            {
            }
            column(Timesheet_Status__Actual_Work_Days_; "Actual Work Days")
            {
            }
            column(Timesheet_Status__Absence_Calendar_Days_; "Absence Calendar Days")
            {
            }
            column(Timesheet_Status__Absence_Work_Days_; "Absence Work Days")
            {
            }
            column(Timesheet_Status__Holiday_Work_Days_; "Holiday Work Days")
            {
            }
            column(Timesheet_Status__Planned_Work_Hours_; "Planned Work Hours")
            {
            }
            column(Timesheet_Status__Actual_Work_Hours_; "Actual Work Hours")
            {
            }
            column(Timesheet_Status__Absence_Hours_; "Absence Hours")
            {
            }
            column(Timesheet_Status__Overtime_Hours_; "Overtime Hours")
            {
            }
            column(Timesheet_Status__Holiday_Work_Hours_; "Holiday Work Hours")
            {
            }
            column(Employee__Short_Name_; Employee."Short Name")
            {
            }
            column(Timesheet_StatusCaption; Timesheet_StatusCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Timesheet_Status__Employee_No__Caption; FieldCaption("Employee No."))
            {
            }
            column(Timesheet_Status_StatusCaption; FieldCaption(Status))
            {
            }
            column(Timesheet_Status__Calendar_Days_Caption; FieldCaption("Calendar Days"))
            {
            }
            column(Timesheet_Status__Planned_Work_Days_Caption; FieldCaption("Planned Work Days"))
            {
            }
            column(Timesheet_Status__Actual_Work_Days_Caption; FieldCaption("Actual Work Days"))
            {
            }
            column(Timesheet_Status__Absence_Calendar_Days_Caption; FieldCaption("Absence Calendar Days"))
            {
            }
            column(Timesheet_Status__Absence_Work_Days_Caption; FieldCaption("Absence Work Days"))
            {
            }
            column(Timesheet_Status__Holiday_Work_Days_Caption; FieldCaption("Holiday Work Days"))
            {
            }
            column(Timesheet_Status__Planned_Work_Hours_Caption; FieldCaption("Planned Work Hours"))
            {
            }
            column(Timesheet_Status__Actual_Work_Hours_Caption; FieldCaption("Actual Work Hours"))
            {
            }
            column(Timesheet_Status__Absence_Hours_Caption; FieldCaption("Absence Hours"))
            {
            }
            column(Timesheet_Status__Overtime_Hours_Caption; FieldCaption("Overtime Hours"))
            {
            }
            column(Timesheet_Status__Holiday_Work_Hours_Caption; FieldCaption("Holiday Work Hours"))
            {
            }
            column(Employee__Short_Name_Caption; Employee__Short_Name_CaptionLbl)
            {
            }
            column(Timesheet_Status_Period_Code; "Period Code")
            {
            }

            trigger OnAfterGetRecord()
            begin
                Employee.Get("Employee No.");
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        Employee: Record Employee;
        Timesheet_StatusCaptionLbl: Label 'Timesheet Status';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Employee__Short_Name_CaptionLbl: Label 'Short Name';
}

