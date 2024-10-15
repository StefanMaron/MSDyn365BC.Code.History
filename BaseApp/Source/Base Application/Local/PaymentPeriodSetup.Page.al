#if not CLEAN23
page 10883 "Payment Period Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Period Setup';
    DelayedInsert = true;

    ObsoleteState = Pending;
    ObsoleteReason = 'This page is obsolete. Replaced by W1 extension "Payment Practices".';
    ObsoleteTag = '23.0';

    PageType = List;
    SourceTable = "Payment Period Setup";
    UsageCategory = Administration;

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
