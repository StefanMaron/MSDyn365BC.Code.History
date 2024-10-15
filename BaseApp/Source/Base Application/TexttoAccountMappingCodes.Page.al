#if not CLEAN20
page 11705 "Text-to-Account Mapping Codes"
{
    Caption = 'Text-to-Account Mapping Codes';
    PageType = List;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '20.0';
#if not CLEAN19
    ApplicationArea = Basic, Suite;
    SourceTable = "Text-to-Account Mapping Code";
    UsageCategory = Administration;
#else
    SourceTable = Integer;
#endif

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
#if not CLEAN19
                RunObject = Page "Text-to-Account Mapping";
                RunPageLink = "Text-to-Account Mapping Code" = FIELD(Code);
#endif
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

#if CLEAN19
    var
        Code: Code[20];
        Description: Text;
#endif
}

#endif