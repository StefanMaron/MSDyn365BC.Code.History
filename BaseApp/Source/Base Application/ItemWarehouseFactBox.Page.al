page 9109 "Item Warehouse FactBox"
{
    Caption = 'Item Details - Warehouse';
    PageType = CardPart;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            field("No."; "No.")
            {
                ApplicationArea = Suite;
                Caption = 'Item No.';
                ToolTip = 'Specifies the number of the item.';

                trigger OnDrillDown()
                begin
                    ShowDetails;
                end;
            }
            field("Identifier Code"; "Identifier Code")
            {
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies a unique code for the item in terms that are useful for automatic data capture.';
            }
            field("Base Unit of Measure"; "Base Unit of Measure")
            {
                ApplicationArea = Suite;
                ToolTip = 'Specifies the unit in which the item is held in inventory.';
            }
            field("Put-away Unit of Measure Code"; "Put-away Unit of Measure Code")
            {
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies the code of the item unit of measure in which the program will put the item away.';
            }
            field("Purch. Unit of Measure"; "Purch. Unit of Measure")
            {
                ApplicationArea = Suite;
                ToolTip = 'Specifies the unit of measure code used when you purchase the item.';
            }
            field("Item Tracking Code"; "Item Tracking Code")
            {
                ApplicationArea = ItemTracking;
                ToolTip = 'Specifies how serial or lot numbers assigned to the item are tracked in the supply chain.';

                trigger OnDrillDown()
                var
                    ItemTrackCode: Record "Item Tracking Code";
                begin
                    ItemTrackCode.SetFilter(Code, "Item Tracking Code");

                    PAGE.Run(PAGE::"Item Tracking Code Card", ItemTrackCode);
                end;
            }
            field("Special Equipment Code"; "Special Equipment Code")
            {
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies the code of the equipment that warehouse employees must use when handling the item.';
            }
            field("Last Phys. Invt. Date"; "Last Phys. Invt. Date")
            {
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies the date on which you last posted the results of a physical inventory for the item to the item ledger.';
            }
            field(NetWeight; GetNetWeight)
            {
                ApplicationArea = Suite;
                Caption = 'Net Weight';
                ToolTip = 'Specifies the total net weight of the items that should be shipped.';
            }
            field("Warehouse Class Code"; "Warehouse Class Code")
            {
                ApplicationArea = Warehouse;
                Caption = 'Warehouse Class Code';
                ToolTip = 'Specifies the warehouse class code that defines the item.';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        GetNetWeight;
    end;

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Item Card", Rec);
    end;

    local procedure GetNetWeight(): Decimal
    var
        ItemBaseUOM: Record "Item Unit of Measure";
    begin
        if ItemBaseUOM.Get("No.", "Base Unit of Measure") then
            exit(ItemBaseUOM.Weight);

        exit(0);
    end;
}

