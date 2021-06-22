page 399 "Purchase Receipt Statistics"
{
    Caption = 'Purchase Receipt Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Purch. Rcpt. Header";

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
                    ToolTip = 'Specifies the total quantity of items received from the purchase document.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total number of parcels received from the purchase document.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total net weight of the items received from the purchase document.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total gross weight of the items received from the purchase document.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total volume of the items received from the purchase document.';
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

        PurchRcptLine.SetRange("Document No.", "No.");

        if PurchRcptLine.Find('-') then
            repeat
                LineQty := LineQty + PurchRcptLine.Quantity;
                TotalNetWeight := TotalNetWeight + (PurchRcptLine.Quantity * PurchRcptLine."Net Weight");
                TotalGrossWeight := TotalGrossWeight + (PurchRcptLine.Quantity * PurchRcptLine."Gross Weight");
                TotalVolume := TotalVolume + (PurchRcptLine.Quantity * PurchRcptLine."Unit Volume");
                if PurchRcptLine."Units per Parcel" > 0 then
                    TotalParcels := TotalParcels + Round(PurchRcptLine.Quantity / PurchRcptLine."Units per Parcel", 1, '>');
            until PurchRcptLine.Next = 0;
    end;

    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;
}

