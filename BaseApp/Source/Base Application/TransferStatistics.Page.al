page 5755 "Transfer Statistics"
{
    Caption = 'Transfer Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Transfer Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(LineQty; LineQty)
                {
                    ApplicationArea = Location;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of items for this transfer order.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = Location;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of items in parcels for this transfer order.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = Location;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the net weight of items for this transfer order.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = Location;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the gross weight of items for this transfer order.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = Location;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the volume of items for this transfer order.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        TransLine: Record "Transfer Line";
    begin
        ClearAll;

        TransLine.SetRange("Document No.", "No.");
        TransLine.SetRange("Derived From Line No.", 0);
        if TransLine.Find('-') then
            repeat
                LineQty := LineQty + TransLine.Quantity;
                TotalNetWeight := TotalNetWeight + (TransLine.Quantity * TransLine."Net Weight");
                TotalGrossWeight := TotalGrossWeight + (TransLine.Quantity * TransLine."Gross Weight");
                TotalVolume := TotalVolume + (TransLine.Quantity * TransLine."Unit Volume");
                if TransLine."Units per Parcel" > 0 then
                    TotalParcels := TotalParcels + Round(TransLine.Quantity / TransLine."Units per Parcel", 1, '>');
            until TransLine.Next = 0;
    end;

    var
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;
}

