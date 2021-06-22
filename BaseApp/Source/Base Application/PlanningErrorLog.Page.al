page 5430 "Planning Error Log"
{
    Caption = 'Planning Error Log';
    DataCaptionExpression = Caption;
    Editable = false;
    PageType = List;
    SourceTable = "Planning Error Log";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the item number associated with this entry.';
                }
                field("Error Description"; "Error Description")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the description to the error in this entry.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Show")
            {
                ApplicationArea = Planning;
                Caption = '&Show';
                Image = View;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'View the log details.';

                trigger OnAction()
                begin
                    ShowError;
                end;
            }
        }
    }
}

