page 12455 "Item Document Statistics"
{
    Caption = 'Item Document Statistics';
    Editable = false;
    PageType = Card;
    SourceTable = "Item Document Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(LineQty; LineQty)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many pieces of the item are processed.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total number of parcels in the document.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the net weight of the item. You may need the net weight to complete customs documents, waybills, and other forms.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the gross weight, including the weight of any packaging, of the catalog item.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total volume of the items in the document.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        ItemDocLine: Record "Item Document Line";
    begin
        ClearAll;

        ItemDocLine.SetRange("Document Type", "Document Type");
        ItemDocLine.SetRange("Document No.", "No.");
        if ItemDocLine.Find('-') then
            repeat
                LineQty := LineQty + ItemDocLine.Quantity;
                TotalNetWeight := TotalNetWeight + (ItemDocLine.Quantity * ItemDocLine."Net Weight");
                TotalGrossWeight := TotalGrossWeight + (ItemDocLine.Quantity * ItemDocLine."Gross Weight");
                TotalVolume := TotalVolume + (ItemDocLine.Quantity * ItemDocLine."Unit Volume");
                if ItemDocLine."Units per Parcel" > 0 then
                    TotalParcels := TotalParcels + Round(ItemDocLine.Quantity / ItemDocLine."Units per Parcel", 1, '>');
            until ItemDocLine.Next = 0;
    end;

    var
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;
}

