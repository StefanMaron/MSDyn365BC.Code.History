page 9124 "Service Line FactBox"
{
    Caption = 'Service Line Details';
    PageType = CardPart;
    SourceTable = "Service Line";

    layout
    {
        area(content)
        {
            field("No."; "No.")
            {
                ApplicationArea = Service;
                Caption = 'Item No.';
                Lookup = false;
                ToolTip = 'Specifies the number of an item, general ledger account, resource code, cost, or standard text.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            field("STRSUBSTNO('%1',ServInfoPaneMgt.CalcAvailability(Rec))"; StrSubstNo('%1', ServInfoPaneMgt.CalcAvailability(Rec)))
            {
                ApplicationArea = Planning;
                Caption = 'Availability';
                DrillDown = true;
                Editable = true;
                ToolTip = 'Specifies how many units of the item are available.';

                trigger OnDrillDown()
                begin
                    ItemAvailFormsMgt.ShowItemAvailFromServLine(Rec, ItemAvailFormsMgt.ByEvent);
                end;
            }
            field("STRSUBSTNO('%1',ServInfoPaneMgt.CalcNoOfSubstitutions(Rec))"; StrSubstNo('%1', ServInfoPaneMgt.CalcNoOfSubstitutions(Rec)))
            {
                ApplicationArea = Service;
                Caption = 'Substitutions';
                DrillDown = true;
                Editable = true;
                ToolTip = 'Specifies the available items or catalog items that may be used as substitutes for the selected item on the service line.';

                trigger OnDrillDown()
                begin
                    ShowItemSub();
                    CurrPage.Update();
                end;
            }
            field("STRSUBSTNO('%1',ServInfoPaneMgt.CalcNoOfSalesPrices(Rec))"; StrSubstNo('%1', ServInfoPaneMgt.CalcNoOfSalesPrices(Rec)))
            {
                ApplicationArea = Service;
                Caption = 'Sales Prices';
                DrillDown = true;
                Editable = true;
                ToolTip = 'Specifies how many special prices you grant for the service line. Choose the value to see the special sales prices.';

                trigger OnDrillDown()
                begin
                    PickPrice();
                    CurrPage.Update();
                end;
            }
            field("STRSUBSTNO('%1',ServInfoPaneMgt.CalcNoOfSalesLineDisc(Rec))"; StrSubstNo('%1', ServInfoPaneMgt.CalcNoOfSalesLineDisc(Rec)))
            {
                ApplicationArea = Service;
                Caption = 'Sales Line Discounts';
                DrillDown = true;
                Editable = true;
                ToolTip = 'Specifies how many special discounts you grant for the service line. Choose the value to see the sales line discounts.';

                trigger OnDrillDown()
                begin
                    PickDiscount();
                    CurrPage.Update();
                end;
            }
        }
    }

    actions
    {
    }

    var
        ServInfoPaneMgt: Codeunit "Service Info-Pane Management";
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";

    local procedure ShowDetails()
    var
        Item: Record Item;
    begin
        if Type = Type::Item then begin
            Item.Get("No.");
            PAGE.Run(PAGE::"Item Card", Item);
        end;
    end;
}

