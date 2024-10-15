#if not CLEAN19
page 11705 "Text-to-Account Mapping Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Text-to-Account Mapping Codes';
    PageType = List;
    SourceTable = "Text-to-Account Mapping Code";
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
                    ToolTip = 'Specifies code of mapping line';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description of mapping line';
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
                RunObject = Page "Text-to-Account Mapping";
                RunPageLink = "Text-to-Account Mapping Code" = FIELD(Code);
                ToolTip = 'Specifies rules';
            }
        }
    }
}

#endif