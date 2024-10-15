page 17479 "Payroll Status"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payroll Status';
    PageType = Card;
    SourceTable = "Payroll Status";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                Editable = false;
                ShowCaption = false;
                field("Period Code"; "Period Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field("Payroll Status"; "Payroll Status")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Advance Status"; "Advance Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if advance payments exist.';
                }
                field(Wages; Wages)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Bonuses; Bonuses)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Deductions; Deductions)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Tax Deductions"; "Tax Deductions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Income Tax Base"; "Income Tax Base")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Income Tax Amount"; "Income Tax Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("FSS Contributions"; "FSS Contributions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("FSS Injury Contributions"; "FSS Injury Contributions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Territorial FMI Contributions"; "Territorial FMI Contributions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Federal FMI Contributions"; "Federal FMI Contributions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("PF Accum. Part Contributions"; "PF Accum. Part Contributions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("PF Insur. Part Contributions"; "PF Insur. Part Contributions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posted Wages"; "Posted Wages")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posted Bonuses"; "Posted Bonuses")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posted Deductions"; "Posted Deductions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posted Tax Deductions"; "Posted Tax Deductions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posted Income Tax Base"; "Posted Income Tax Base")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posted Income Tax Amount"; "Posted Income Tax Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posted FSS Contributions"; "Posted FSS Contributions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posted FSS Injury Contrib."; "Posted FSS Injury Contrib.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posted Territ. FMI Contrib."; "Posted Territ. FMI Contrib.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posted Federal FMI Contrib."; "Posted Federal FMI Contrib.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posted PF Accum. Part Contrib."; "Posted PF Accum. Part Contrib.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posted PF Insur. Part Contrib."; "Posted PF Insur. Part Contrib.")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("E&mployee")
            {
                Caption = 'E&mployee';
                Image = Employee;
                action("Timesheet Status")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Timesheet Status';
                    Image = Timesheet;
                    RunObject = Page "Timesheet Status";
                    RunPageLink = "Period Code" = FIELD("Period Code"),
                                  "Employee No." = FIELD("Employee No.");
                    ShortCutKey = 'Ctrl+F7';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Calculate Payroll")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate Payroll';
                    Image = Calculate;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Report "Suggest Payroll Documents";
                }
                action("Update Status")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update Status';
                    Image = Refresh;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(PayrollStatus);
                        with PayrollStatus do begin
                            if FindSet then
                                repeat
                                    UpdateCalculated(PayrollStatus);
                                    UpdatePosted(PayrollStatus);
                                    Modify;
                                until Next() = 0;
                        end;
                    end;
                }
            }
        }
    }

    var
        PayrollStatus: Record "Payroll Status";
}

