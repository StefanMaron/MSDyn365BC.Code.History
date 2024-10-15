page 17352 "Person Name History"
{
    Caption = 'Person Name History';
    DelayedInsert = true;
    Editable = false;
    PageType = List;
    SourceTable = "Person Name History";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("First Name"; "First Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Middle Name"; "Middle Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Last Name"; "Last Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Order No."; "Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related order was created.';
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related order was created.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
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
                action("Cancel Changes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel Changes';
                    Image = Cancel;

                    trigger OnAction()
                    begin
                        ChangePersonName.CancelChanges(Rec);
                    end;
                }
            }
        }
    }

    var
        ChangePersonName: Codeunit "Change Person Name";
}

