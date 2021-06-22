page 6032 "Service Shipment Statistics"
{
    Caption = 'Service Shipment Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Service Shipment Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(LineQty; LineQty)
                {
                    ApplicationArea = Service;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of all G/L account entries, costs, items and/or resource hours in the service document that were shipped.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = Service;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total quantity of parcels shipped from the service document.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = Service;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total net weight of the items shipped from the service document.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = Service;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total gross weight of the items shipped from the service document.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = Service;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total volume of the items shipped from the service document.';
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

        ServShptLine.SetRange("Document No.", "No.");

        if ServShptLine.Find('-') then
            repeat
                LineQty := LineQty + ServShptLine.Quantity;
                TotalNetWeight := TotalNetWeight + (ServShptLine.Quantity * ServShptLine."Net Weight");
                TotalGrossWeight := TotalGrossWeight + (ServShptLine.Quantity * ServShptLine."Gross Weight");
                TotalVolume := TotalVolume + (ServShptLine.Quantity * ServShptLine."Unit Volume");
                if ServShptLine."Units per Parcel" > 0 then
                    TotalParcels := TotalParcels + Round(ServShptLine.Quantity / ServShptLine."Units per Parcel", 1, '>');
            until ServShptLine.Next = 0;
    end;

    var
        ServShptLine: Record "Service Shipment Line";
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;
}

