page 7305 "Bin Contents List"
{
    Caption = 'Bin Contents List';
    DataCaptionExpression = GetCaption;
    Editable = false;
    PageType = List;
    SourceTable = "Bin Content";

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
                    ToolTip = 'Specifies the location code of the bin.';
                }
                field("Zone Code"; "Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone code of the bin.';
                    Visible = false;
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the item that will be stored in the bin.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Bin Type Code"; "Bin Type Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the bin type that was selected for this bin.';
                    Visible = false;
                }
                field("Block Movement"; "Block Movement")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how the movement of a particular item, or bin content, into or out of this bin, is blocked.';
                    Visible = false;
                }
                field("Bin Ranking"; "Bin Ranking")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin ranking.';
                    Visible = false;
                }
                field(Default; Default)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if the bin is the default bin for the associated item.';
                }
                field("Fixed"; Fixed)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that the item (bin content) has been associated with this bin, and that the bin should normally contain the item.';
                }
                field(Dedicated; Dedicated)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if the bin is used as a dedicated bin, which means that its bin content is available only to certain resources.';
                }
                field("Warehouse Class Code"; "Warehouse Class Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the warehouse class code. Only items with the same warehouse class can be stored in this bin.';
                    Visible = false;
                }
                field(CalcQtyUOM; CalcQtyUOM)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item in the bin that corresponds to the line.';
                }
                field("Quantity (Base)"; "Quantity (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many units of the item, in the base unit of measure, are stored in the bin.';
                }
                field(CalcQtyAvailToTakeUOM; CalcQtyAvailToTakeUOM)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Available Qty. to Take';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that is available in the bin.';
                    Visible = false;
                }
                field("Min. Qty."; "Min. Qty.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the minimum number of units of the item that you want to have in the bin at all times.';
                    Visible = false;
                }
                field("Max. Qty."; "Max. Qty.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the maximum number of units of the item that you want to have in the bin.';
                    Visible = false;
                }
                field("Qty. per Unit of Measure"; "Qty. per Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of base units of measure that are in the unit of measure specified for the item in the bin.';
                    Visible = false;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                    Visible = false;
                }
                field("Cross-Dock Bin"; "Cross-Dock Bin")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if the bin content is in a cross-dock bin.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(Control3; "Lot Numbers by Bin FactBox")
            {
                ApplicationArea = ItemTracking;
                SubPageLink = "Item No." = FIELD("Item No."),
                              "Variant Code" = FIELD("Variant Code"),
                              "Location Code" = FIELD("Location Code");
                Visible = false;
            }
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

    trigger OnOpenPage()
    begin
        if Initialized then begin
            FilterGroup(2);
            SetRange("Location Code", LocationCode);
            FilterGroup(0);
        end;
    end;

    var
        LocationCode: Code[10];
        Initialized: Boolean;

    procedure Initialize(LocationCode2: Code[10])
    begin
        LocationCode := LocationCode2;
        Initialized := true;
    end;
}

