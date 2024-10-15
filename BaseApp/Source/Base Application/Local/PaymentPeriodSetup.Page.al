page 10556 "Payment Period Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Period Setup';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Payment Period Setup";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Days From"; Rec."Days From")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Days To"; Rec."Days To")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }
}

