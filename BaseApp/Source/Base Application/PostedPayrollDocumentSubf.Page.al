page 17418 "Posted Payroll Document Subf."
{
    AutoSplitKey = true;
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Posted Payroll Document Line";

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
                field(Calculate; Calculate)
                {
                    Visible = false;
                }
                field("Posting Group"; "Posting Group")
                {
                    ApplicationArea = Basic, Suite;
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
                field("AE Total Days"; "AE Total Days")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
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
            group("L&ine")
            {
                Caption = 'L&ine';
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
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
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
    procedure GetSelectedLine(var PostedPayrollDocLine: Record "Posted Payroll Document Line")
    begin
        PostedPayrollDocLine.Copy(Rec);
        CurrPage.SetSelectionFilter(PostedPayrollDocLine);
    end;
}

