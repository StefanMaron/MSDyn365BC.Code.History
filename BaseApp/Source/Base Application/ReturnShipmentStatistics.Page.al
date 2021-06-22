page 6655 "Return Shipment Statistics"
{
    Caption = 'Return Shipment Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Return Shipment Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(LineQty; LineQty)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that corresponds to the posted return shipment.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total number of parcels returned in the shipment to your vendor.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total net weight of the posted return shipment.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total gross weight of the items in the return shipment.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the volume of the items in the posted return shipment.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        ClearAll;

        ReturnShptLine.SetRange("Document No.", "No.");

        if ReturnShptLine.Find('-') then
            repeat
                LineQty := LineQty + ReturnShptLine.Quantity;
                TotalNetWeight := TotalNetWeight + (ReturnShptLine.Quantity * ReturnShptLine."Net Weight");
                TotalGrossWeight := TotalGrossWeight + (ReturnShptLine.Quantity * ReturnShptLine."Gross Weight");
                TotalVolume := TotalVolume + (ReturnShptLine.Quantity * ReturnShptLine."Unit Volume");
                if ReturnShptLine."Units per Parcel" > 0 then
                    TotalParcels := TotalParcels + Round(ReturnShptLine.Quantity / ReturnShptLine."Units per Parcel", 1, '>');
            until ReturnShptLine.Next = 0;
    end;

    var
        ReturnShptLine: Record "Return Shipment Line";
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;
}

