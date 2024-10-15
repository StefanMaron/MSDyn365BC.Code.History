#if not CLEAN18
page 11796 "User Setup Lines List"
{
    Caption = 'User Setup Lines List (Obsolete)';
    PageType = List;
    SourceTable = "User Setup Line";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    layout
    {
        area(content)
        {
            repeater(Control1220003)
            {
                ShowCaption = false;
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user associated with the entry.';
                    Visible = false;
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of payment order';
                }
                field("Code / Name"; "Code / Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code/name for related row type.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220005; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220004; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
    }
}
#endif
