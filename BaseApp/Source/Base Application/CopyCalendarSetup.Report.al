report 17429 "Copy Calendar Setup"
{
    Caption = 'Copy Calendar Setup';
    ProcessingOnly = true;

    dataset
    {
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
                    field(CalendarCode; CalendarCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'From Calendar Code';
                        TableRelation = "Payroll Calendar";
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        FromPayrollCalendar.Get(CalendarCode);

        FromPayrollCalSetup.Reset();
        FromPayrollCalSetup.SetRange("Calendar Code", CalendarCode);
        if FromPayrollCalSetup.FindSet then
            repeat
                ToPayrollCalSetup.Init();
                ToPayrollCalSetup := FromPayrollCalSetup;
                ToPayrollCalSetup."Calendar Code" := ToPayrollCalendar.Code;
                ToPayrollCalSetup.Insert();
            until FromPayrollCalSetup.Next() = 0;
    end;

    var
        FromPayrollCalendar: Record "Payroll Calendar";
        FromPayrollCalSetup: Record "Payroll Calendar Setup";
        ToPayrollCalendar: Record "Payroll Calendar";
        ToPayrollCalSetup: Record "Payroll Calendar Setup";
        CalendarCode: Code[10];

    [Scope('OnPrem')]
    procedure Set(var NewCalendar: Record "Payroll Calendar")
    begin
        ToPayrollCalendar := NewCalendar;
    end;
}

