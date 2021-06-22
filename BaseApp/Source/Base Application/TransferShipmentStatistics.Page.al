page 5756 "Transfer Shipment Statistics"
{
    Caption = 'Transfer Shipment Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Transfer Shipment Header";

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
                    ToolTip = 'Specifies the quantity of items in this transfer order.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = Location;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of items in parcels.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = Location;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the net weight of the item. You may need the net weight to complete customs documents, waybills, and other forms.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = Location;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the gross weight of the item. You may need the gross weight to complete customs documents, waybills, and other forms.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = Location;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the volume of one unit of the item. You may need to know the item''s unit volume to complete customs documents, waybills, and so on.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        TransShptLine: Record "Transfer Shipment Line";
    begin
        ClearAll;

        TransShptLine.SetRange("Document No.", "No.");

        if TransShptLine.Find('-') then
            repeat
                LineQty := LineQty + TransShptLine.Quantity;
                TotalNetWeight :=
                  TotalNetWeight + (TransShptLine.Quantity * TransShptLine."Net Weight");
                TotalGrossWeight :=
                  TotalGrossWeight + (TransShptLine.Quantity * TransShptLine."Gross Weight");
                TotalVolume :=
                  TotalVolume + (TransShptLine.Quantity * TransShptLine."Unit Volume");
                if TransShptLine."Units per Parcel" > 0 then
                    TotalParcels :=
                      TotalParcels +
                      Round(TransShptLine.Quantity / TransShptLine."Units per Parcel", 1, '>');
            until TransShptLine.Next = 0;
    end;

    var
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;
}

