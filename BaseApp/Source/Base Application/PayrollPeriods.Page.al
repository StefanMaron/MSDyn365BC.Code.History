page 17425 "Payroll Periods"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payroll Periods';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Payroll Period";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the related record.';
                }
                field("Period Duration"; "Period Duration")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the last day of the activity in question. ';
                }
                field("Advance Date"; "Advance Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the salary is paid out. ';
                }
                field(Employees; Employees)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("New Payroll Year"; "New Payroll Year")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field(Closed; Closed)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
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
                action("&Create Year")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Create Year';
                    Ellipsis = true;
                    Image = CreateYear;
                    RunObject = Report "Create Payroll Year";
                    ToolTip = 'Create a new payroll year, including payroll periods.';
                }
                separator(Action1210026)
                {
                }
                action("C&lose Period")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&lose Period';
                    Image = ClosePeriod;
                    RunObject = Codeunit "Payroll Period-Close";
                }
                action("&Open Period")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Open Period';
                    Image = ReopenPeriod;
                    ToolTip = 'Open a payroll period that has been closed.';

                    trigger OnAction()
                    begin
                        PayrollPeriodClose.Reopen(Rec);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.Editable := not CurrPage.LookupMode;
    end;

    var
        PayrollPeriodClose: Codeunit "Payroll Period-Close";
}

