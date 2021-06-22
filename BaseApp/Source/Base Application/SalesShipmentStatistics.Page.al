page 396 "Sales Shipment Statistics"
{
    Caption = 'Sales Shipment Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Sales Shipment Header";

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
                    ToolTip = 'Specifies the total quantity of G/L account entries, items and/or resources in the sales document that were shipped.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total number of parcels shipped from the sales document.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total net weight of the items shipped from the sales document.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total gross weight of the items shipped from the sales document.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total volume of the items shipped from the sales document.';
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

        SalesShptLine.SetRange("Document No.", "No.");

        if SalesShptLine.Find('-') then
            repeat
                LineQty := LineQty + SalesShptLine.Quantity;
                TotalNetWeight := TotalNetWeight + (SalesShptLine.Quantity * SalesShptLine."Net Weight");
                TotalGrossWeight := TotalGrossWeight + (SalesShptLine.Quantity * SalesShptLine."Gross Weight");
                TotalVolume := TotalVolume + (SalesShptLine.Quantity * SalesShptLine."Unit Volume");
                if SalesShptLine."Units per Parcel" > 0 then
                    TotalParcels := TotalParcels + Round(SalesShptLine.Quantity / SalesShptLine."Units per Parcel", 1, '>');
            until SalesShptLine.Next = 0;
    end;

    var
        SalesShptLine: Record "Sales Shipment Line";
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;
}

