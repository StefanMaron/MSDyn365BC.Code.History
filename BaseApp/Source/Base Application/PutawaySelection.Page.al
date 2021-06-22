page 7334 "Put-away Selection"
{
    Caption = 'Put-away Selection';
    Editable = false;
    PageType = List;
    SourceTable = "Whse. Put-away Request";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of document that created the warehouse put-away request.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the warehouse document that should be put away.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location in which the request is occurring.';
                }
                field("Zone Code"; "Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone code where the bin on the request is located.';
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                }
                field("Completely Put Away"; "Completely Put Away")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that all the items on the warehouse source document have been put away.';
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

    procedure GetResult(var WhsePutAwayRqst: Record "Whse. Put-away Request")
    begin
        CurrPage.SetSelectionFilter(WhsePutAwayRqst);
    end;
}

