page 17457 "Travel Order Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Absence Line";
    SourceTableView = WHERE("Document Type" = CONST(Travel));

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
                field("Working Days"; "Working Days")
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
            }
        }
    }
}

