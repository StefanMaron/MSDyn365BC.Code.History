page 7300 Zones
{
    Caption = 'Zones';
    DataCaptionFields = "Location Code";
    PageType = List;
    SourceTable = Zone;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location code of the zone.';
                    Visible = false;
                }
                field("Code"; Code)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the zone.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description of the zone.';
                }
                field("Bin Type Code"; "Bin Type Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin type code for the zone. The bin type determines the inbound and outbound flow of items.';
                }
                field("Warehouse Class Code"; "Warehouse Class Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the warehouse class code of the zone. You can store items with the same warehouse class code in this zone.';
                }
                field("Special Equipment Code"; "Special Equipment Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the special equipment to be used when you work in this zone.';
                }
                field("Zone Ranking"; "Zone Ranking")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Zone Ranking';
                    ToolTip = 'Specifies the ranking of the zone, which is copied to all bins created within the zone.';
                }
                field("Cross-Dock Bin Zone"; "Cross-Dock Bin Zone")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if this is a cross-dock zone.';
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
        area(navigation)
        {
            group("&Zone")
            {
                Caption = '&Zone';
                Image = Zones;
                action("&Bins")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Bins';
                    Image = Bins;
                    RunObject = Page Bins;
                    RunPageLink = "Location Code" = FIELD("Location Code"),
                                  "Zone Code" = FIELD(Code);
                    ToolTip = 'View or edit information about zones that you use in your warehouse to hold items.';
                }
            }
        }
    }
}

