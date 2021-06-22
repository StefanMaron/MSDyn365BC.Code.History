page 6665 "Return Receipt Statistics"
{
    Caption = 'Return Receipt Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Return Receipt Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(LineQty; LineQty)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that corresponds to the posted return shipment.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total number of parcels returned by the customer.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total net weight in the posted return order.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total gross weight of the items in the return receipt shipment.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the volume of the items in the posted return order.';
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

        ReturnRcptLine.SetRange("Document No.", "No.");

        if ReturnRcptLine.Find('-') then
            repeat
                LineQty := LineQty + ReturnRcptLine.Quantity;
                TotalNetWeight := TotalNetWeight + (ReturnRcptLine.Quantity * ReturnRcptLine."Net Weight");
                TotalGrossWeight := TotalGrossWeight + (ReturnRcptLine.Quantity * ReturnRcptLine."Gross Weight");
                TotalVolume := TotalVolume + (ReturnRcptLine.Quantity * ReturnRcptLine."Unit Volume");
                if ReturnRcptLine."Units per Parcel" > 0 then
                    TotalParcels := TotalParcels + Round(ReturnRcptLine.Quantity / ReturnRcptLine."Units per Parcel", 1, '>');
            until ReturnRcptLine.Next = 0;
    end;

    var
        ReturnRcptLine: Record "Return Receipt Line";
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;
}

