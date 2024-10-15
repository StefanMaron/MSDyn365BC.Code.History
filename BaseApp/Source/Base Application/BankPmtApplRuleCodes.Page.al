page 11704 "Bank Pmt. Appl. Rule Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Payment Application Rules';
    PageType = List;
    SourceTable = "Bank Pmt. Appl. Rule Code";
    UsageCategory = Administration;

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
                field("Match Related Party Only"; "Match Related Party Only")
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
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Payment Application Rules";
                RunPageLink = "Bank Pmt. Appl. Rule Code" = FIELD(Code);
                ToolTip = 'Specifies rules';
            }
        }
    }
}

