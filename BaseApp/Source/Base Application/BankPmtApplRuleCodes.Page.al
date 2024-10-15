#if not CLEAN19
page 11704 "Bank Pmt. Appl. Rule Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Payment Application Rules (Obsolete)';
    PageType = List;
    SourceTable = "Bank Pmt. Appl. Rule Code";
    UsageCategory = Administration;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for a payment title.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description for a payment title.';
                }
                field("Match Related Party Only"; Rec."Match Related Party Only")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the match related party only.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Rules)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Rules';
                Image = MapAccounts;
                RunObject = Page "Payment Application Rules";
                RunPageLink = "Bank Pmt. Appl. Rule Code" = FIELD(Code);
                ToolTip = 'Specifies rules';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Rules_Promoted; Rules)
                {
                }
            }
        }
    }
}

#endif