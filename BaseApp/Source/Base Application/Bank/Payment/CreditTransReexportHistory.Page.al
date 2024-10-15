namespace Microsoft.Bank.Payment;

page 1209 "Credit Trans Re-export History"
{
    Caption = 'Credit Trans Re-export History';
    Editable = false;
    PageType = List;
    SourceTable = "Credit Trans Re-export History";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Re-export Date"; Rec."Re-export Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the payment file was re-exported.';
                }
                field("Re-exported By"; Rec."Re-exported By")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user who re-exported the payment file.';
                }
            }
        }
    }

    actions
    {
    }
}

