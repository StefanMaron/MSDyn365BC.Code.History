page 5058 "Alt. Addr. Date Ranges"
{
    Caption = 'Alt. Addr. Date Ranges';
    DataCaptionFields = "Contact Alt. Address Code";
    DelayedInsert = true;
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Contact Alt. Addr. Date Range";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date from which the alternate address is valid. There are certain rules for how dates should be entered.';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day on which the alternate address is valid. There are certain rules for how dates should be entered.';
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
    }
}

