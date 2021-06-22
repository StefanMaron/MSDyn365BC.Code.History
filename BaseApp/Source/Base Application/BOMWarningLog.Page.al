page 5874 "BOM Warning Log"
{
    Caption = 'BOM Warning Log';
    Editable = false;
    PageType = List;
    SourceTable = "BOM Warning Log";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Warning Description"; "Warning Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the warning associated with the entry.';
                }
                field("Table ID"; "Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the table ID associated with the entry.';
                    Visible = false;
                }
                field("Table Position"; "Table Position")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the table position associated with the entry.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Show")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Show';
                Image = View;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'View the log details.';

                trigger OnAction()
                begin
                    ShowWarning;
                end;
            }
        }
    }
}

