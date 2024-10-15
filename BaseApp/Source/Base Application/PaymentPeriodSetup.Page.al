page 10883 "Payment Period Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Period Setup';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Payment Period Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Days From"; "Days From")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Days To"; "Days To")
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

