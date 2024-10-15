#if not CLEAN23
page 10556 "Payment Period Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Period Setup';
    DelayedInsert = true;
    PageType = List;
    ObsoleteState = Pending;
    ObsoleteReason = 'This page is obsolete. Replaced by W1 extension "Payment Practices".';
    ObsoleteTag = '23.0';
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
#endif
