#if not CLEAN19
page 31090 "Acc. Schedule Result History"
{
    Caption = 'Acc. Schedule Result History (Obsolete)';
    Editable = false;
    PageType = List;
    SourceTable = "Acc. Schedule Result History";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            repeater(Control1220005)
            {
                ShowCaption = false;
                field("Variant No."; Rec."Variant No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the no. of the variant';
                }
                field("New Value"; Rec."New Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies new code for the fixed asset location.';
                }
                field("Old Value"; Rec."Old Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the old value of the acc. schedule result';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user associated with the entry.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field("Modified DateTime"; Rec."Modified DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies modified date time';
                }
            }
        }
    }

    actions
    {
    }
}
#endif
