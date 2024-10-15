page 7367 "Bin Templates"
{
    ApplicationArea = Warehouse;
    Caption = 'Bin Templates';
    DataCaptionFields = "Code", Description;
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Bin Template";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a code for the bin template.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description for the bin creation template.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location code that will apply to all the bins set up with this bin template.';
                }
                field("Zone Code"; "Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the zone where the bins created by this template are located.';
                    Visible = false;
                }
                field("Bin Description"; "Bin Description")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description of the bins that are set up using the bin template.';
                }
                field("Bin Type Code"; "Bin Type Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a bin type code that will be copied to all bins created using the template.';
                    Visible = false;
                }
                field("Warehouse Class Code"; "Warehouse Class Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a warehouse class code that will be copied to all bins created using the template.';
                    Visible = false;
                }
                field("Block Movement"; "Block Movement")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how the movement of a particular item, or bin content, into or out of this bin, is blocked.';
                    Visible = false;
                }
                field("Special Equipment Code"; "Special Equipment Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a special equipment code that will be copied to all bins created using the template.';
                    Visible = false;
                }
                field("Bin Ranking"; "Bin Ranking")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin ranking that will be copied to all bins created using the template.';
                    Visible = false;
                }
                field("Maximum Cubage"; "Maximum Cubage")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the maximum cubage that will be copied to all bins that are created using the template.';
                    Visible = false;
                }
                field("Maximum Weight"; "Maximum Weight")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the maximum weight that will be copied to all bins that are created using the template.';
                    Visible = false;
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

