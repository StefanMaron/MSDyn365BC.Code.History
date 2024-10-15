page 31090 "Acc. Schedule Result History"
{
    Caption = 'Acc. Schedule Result History';
    Editable = false;
    PageType = List;
    SourceTable = "Acc. Schedule Result History";

    layout
    {
        area(content)
        {
            repeater(Control1220005)
            {
                ShowCaption = false;
                field("Variant No."; "Variant No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the no. of the variant';
                }
                field("New Value"; "New Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies new code for the fixed asset location.';
                }
                field("Old Value"; "Old Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the old value of the acc. schedule result';
                }
                field("User ID"; "User ID")
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
                field("Modified DateTime"; "Modified DateTime")
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

