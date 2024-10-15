page 17415 "Payroll Document Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    Permissions = TableData "Payroll Period AE" = rimd;
    SourceTable = "Payroll Document Line";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Priority; Priority)
                {
                    Visible = false;
                }
                field("Calc Type Code"; "Calc Type Code")
                {
                    Visible = false;
                }
                field("Element Type"; "Element Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related payroll element for tax registration purposes.';
                }
                field("Element Code"; "Element Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the related payroll element for tax registration purposes.';
                }
                field("Directory Code"; "Directory Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Planned Days"; "Planned Days")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Planned Hours"; "Planned Hours")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Actual Days"; "Actual Days")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies how many of the employee''s planned work days the employee actually worked. ';
                }
                field("Actual Hours"; "Actual Hours")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies how many hours the employee worked.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the amount.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the record are processed.';
                }
                field("Payroll Amount"; "Payroll Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Taxable Amount"; "Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Corr. Amount"; "Corr. Amount")
                {
                    Visible = false;
                }
                field("Corr. Amount 2"; "Corr. Amount 2")
                {
                    Visible = false;
                }
                field(Calculate; Calculate)
                {
                    Visible = false;
                }
                field("Posting Group"; "Posting Group")
                {
                    Visible = false;
                }
                field("Print Priority"; "Print Priority")
                {
                    Visible = false;
                }
                field("Action Starting Date"; "Action Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity that the expense represents.';
                }
                field("Action Ending Date"; "Action Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the activity that the expense represents.';
                }
                field("Wage Period From"; "Wage Period From")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Wage Period To"; "Wage Period To")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("AE Period From"; "AE Period From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the average-earnings period. The period length is typically one year. ';
                }
                field("AE Period To"; "AE Period To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the average-earnings period. The period length is typically one year. ';
                }
                field("AE Total Earnings Indexed"; "AE Total Earnings Indexed")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the total average earnings, shown according to an index value. ';

                    trigger OnDrillDown()
                    begin
                        ShowAEEntries;
                    end;
                }
                field("AE Total FSI Earnings"; "AE Total FSI Earnings")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    DrillDown = false;
                    ToolTip = 'Specifies the total average earnings that is related to the Federal Social Insurance fund.';
                }
                field("AE Total Days"; "AE Total Days")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    DrillDown = false;
                    ToolTip = 'Specifies the total number of days that are based the average-earnings setup. ';
                }
                field("AE Daily Earnings"; "AE Daily Earnings")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the daily salary expressed as average earnings.';
                }
                field("Posting Type"; "Posting Type")
                {
                    Visible = false;
                }
                field("Excluded Days"; "Excluded Days")
                {
                    Visible = false;
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
                action("Recalculate line")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Recalculate line';
                    Image = CalculateRegenerativePlan;
                    ShortCutKey = 'Ctrl+F9';

                    trigger OnAction()
                    begin
                        Recalculate;
                    end;
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Calculation)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculation';
                    Image = Calculate;

                    trigger OnAction()
                    begin
                        ShowCalculation;
                    end;
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';

                    trigger OnAction()
                    begin
                        ShowComments;
                    end;
                }
                separator(Action1210012)
                {
                }
                action("AE Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'AE Entries';
                    Image = Entries;

                    trigger OnAction()
                    begin
                        ShowAEEntries;
                    end;
                }
                action("AE Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'AE Periods';
                    Image = Period;

                    trigger OnAction()
                    begin
                        ShowAEPeriods;
                    end;
                }
            }
        }
    }

    [Scope('OnPrem')]
    procedure Recalculate()
    var
        PayrollDocLineAE: Record "Payroll Document Line AE";
        PayrollPeriodAE: Record "Payroll Period AE";
    begin
        PayrollDocLineAE.Reset();
        PayrollDocLineAE.SetRange("Document No.", "Document No.");
        PayrollDocLineAE.SetRange("Document Line No.", "Line No.");
        PayrollDocLineAE.DeleteAll();

        PayrollPeriodAE.Reset();
        PayrollPeriodAE.SetRange("Document No.", "Document No.");
        PayrollPeriodAE.SetRange("Line No.", "Line No.");
        PayrollPeriodAE.DeleteAll();

        CODEUNIT.Run(CODEUNIT::"Payroll Document - Calculate", Rec);
        Modify;
    end;
}

