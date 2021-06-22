page 6015 "Resource Locations"
{
    Caption = 'Resource Locations';
    DataCaptionFields = "Location Code", "Location Name";
    DelayedInsert = true;
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Resource Location";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Resource No."; "Resource No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the resource in the location.';
                    Visible = false;
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the date when the resource becomes available in this location.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the location code of the resource.';
                }
                field("Resource Name"; "Resource Name")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of the resource.';
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

