page 17454 "Sick Leave Order Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Absence Line";
    SourceTableView = WHERE("Document Type" = CONST("Sick Leave"));

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
                field("Treatment Type"; "Treatment Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Sick Leave Type"; "Sick Leave Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Relative Person No."; "Relative Person No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Previous Document No."; "Previous Document No.")
                {
                    ApplicationArea = Basic, Suite;
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
                field("Days Paid by Employer"; "Days Paid by Employer")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payment Days"; "Payment Days")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payment Percent"; "Payment Percent")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Special Payment Days"; "Special Payment Days")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Special Payment Percent"; "Special Payment Percent")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Days Not Paid"; "Days Not Paid")
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
            group("L&ines")
            {
                Caption = 'L&ines';
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
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
            }
        }
    }
}

