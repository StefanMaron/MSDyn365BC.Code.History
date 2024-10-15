page 14985 "Direct Transfer Statistics"
{
    Caption = 'Direct Transfer Statistics';
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
        DirectTransLine: Record "Direct Transfer Line";
    begin
        ClearAll;

        DirectTransLine.SetRange("Document No.", "No.");

        if DirectTransLine.Find('-') then
            repeat
                LineQty := LineQty + DirectTransLine.Quantity;
                TotalNetWeight :=
                  TotalNetWeight + (DirectTransLine.Quantity * DirectTransLine."Net Weight");
                TotalGrossWeight :=
                  TotalGrossWeight + (DirectTransLine.Quantity * DirectTransLine."Gross Weight");
                TotalVolume :=
                  TotalVolume + (DirectTransLine.Quantity * DirectTransLine."Unit Volume");
                if DirectTransLine."Units per Parcel" > 0 then
                    TotalParcels :=
                      TotalParcels +
                      Round(DirectTransLine.Quantity / DirectTransLine."Units per Parcel", 1, '>');
            until DirectTransLine.Next = 0;
    end;

    var
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;
}

