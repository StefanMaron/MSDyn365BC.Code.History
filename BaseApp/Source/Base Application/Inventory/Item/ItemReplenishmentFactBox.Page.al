namespace Microsoft.Inventory.Item;

using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Purchases.Vendor;

page 9090 "Item Replenishment FactBox"
{
    Caption = 'Item Details - Replenishment';
    PageType = CardPart;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = Planning;
                Caption = 'Item No.';
                ToolTip = 'Specifies the number of the item.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            field("Replenishment System"; Rec."Replenishment System")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies the type of supply order that is created by the planning system when the item needs to be replenished.';
            }
            group(Purchase)
            {
                Caption = 'Purchase';
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Planning;
                    Lookup = false;
                    ToolTip = 'Specifies the code of the vendor from whom this item is supplied by default.';

                    trigger OnDrillDown()
                    var
                        Vendor: Record Vendor;
                    begin
                        Vendor.SetFilter("No.", Rec."Vendor No.");

                        PAGE.Run(PAGE::"Vendor Card", Vendor);
                    end;
                }
                field("Vendor Item No."; Rec."Vendor Item No.")
                {
                    ApplicationArea = Planning;
                    Lookup = false;
                    ToolTip = 'Specifies the number that the vendor uses for this item.';
                }
            }
            group(Production)
            {
                Caption = 'Production';
                field("Manufacturing Policy"; Rec."Manufacturing Policy")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies if additional orders for any related components are calculated.';
                }
                field("Routing No."; Rec."Routing No.")
                {
                    ApplicationArea = Manufacturing;
                    Lookup = false;
                    ToolTip = 'Specifies the number of the routing.';

                    trigger OnDrillDown()
                    var
                        RoutingHeader: Record "Routing Header";
                    begin
                        RoutingHeader.SetFilter("No.", Rec."Routing No.");

                        PAGE.Run(PAGE::Routing, RoutingHeader);
                    end;
                }
                field("Production BOM No."; Rec."Production BOM No.")
                {
                    ApplicationArea = Manufacturing;
                    Lookup = false;
                    ToolTip = 'Specifies the number of the production BOM that the item represents.';

                    trigger OnDrillDown()
                    var
                        ProdBomHeader: Record "Production BOM Header";
                    begin
                        ProdBomHeader.SetFilter("No.", Rec."Production BOM No.");

                        PAGE.Run(PAGE::"Production BOM", ProdBomHeader);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Item Card", Rec);
    end;
}

