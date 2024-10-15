page 17463 "Posted Vacation Order Subf"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Posted Absence Line";
    SourceTableView = WHERE("Document Type" = CONST(Vacation));

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Time Activity Code"; "Time Activity Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Element Code"; "Element Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the related payroll element for tax registration purposes.';
                }
                field("Vacation Type"; "Vacation Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the activity in question. ';
                }
                field("Calendar Days"; "Calendar Days")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of calendar days.';
                }
                field("Working Days"; "Working Days")
                {
                    Visible = false;
                }
                field("Days Paid by Employer"; "Days Paid by Employer")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Change Reason"; "Change Reason")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("AE Period From"; "AE Period From")
                {
                    ToolTip = 'Specifies the first day of the average-earnings period. The period length is typically one year. ';
                    Visible = false;
                }
                field("AE Period To"; "AE Period To")
                {
                    ToolTip = 'Specifies the last day of the average-earnings period. The period length is typically one year. ';
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
                    Image = LedgerEntries;

                    trigger OnAction()
                    begin
                        ShowAEEntries;
                    end;
                }
                action("AE Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'AE Periods';
                    Image = PeriodEntries;

                    trigger OnAction()
                    begin
                        ShowAEPeriods;
                    end;
                }
            }
        }
    }
}

