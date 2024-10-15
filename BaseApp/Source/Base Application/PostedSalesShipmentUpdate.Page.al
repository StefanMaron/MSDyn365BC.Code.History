page 1350 "Posted Sales Shipment - Update"
{
    Caption = 'Posted Sales Shipment - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Sales Shipment Header";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the record.';
                }
                field("Sell-to Customer Name"; "Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Editable = false;
                    ToolTip = 'Specifies the name of customer at the sell-to address.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
                field("Promised Delivery Date"; "Promised Delivery Date")
                {
                    ApplicationArea = OrderPromising;
                    Editable = true;
                    ToolTip = 'Specifies the date that you have promised to deliver the order, as a result of the Order Promising function.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Shipping Agent Code"; "Shipping Agent Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Agent';
                    Editable = true;
                    ToolTip = 'Specifies which shipping agent is used to transport the items on the sales document to the customer.';
                }
                field("Shipping Agent Service Code"; "Shipping Agent Service Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Agent Service';
                    Editable = true;
                    ToolTip = 'Specifies which shipping agent service is used to transport the items on the sales document to the customer.';
                }
                field("Package Tracking No."; "Package Tracking No.")
                {
                    ApplicationArea = Suite;
                    Editable = true;
                    ToolTip = 'Specifies the shipping agent''s package number.';
                }
                field("Outbound Whse. Handling Time"; "Outbound Whse. Handling Time")
                {
                    ApplicationArea = Warehouse;
                    Editable = true;
                    ToolTip = 'Specifies a date formula for the time it takes to get items ready to ship from this location. The time element is used in the calculation of the delivery date as follows: Shipment Date + Outbound Warehouse Handling Time = Planned Shipment Date + Shipping Time = Planned Delivery Date.';
                }
                field("Shipping Time"; "Shipping Time")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies how long it takes from when the items are shipped from the warehouse to when they are delivered.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        xSalesShipmentHeader := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged then
                CODEUNIT.Run(CODEUNIT::"Shipment Header - Edit", Rec);
    end;

    var
        xSalesShipmentHeader: Record "Sales Shipment Header";

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged :=
          ("Shipping Agent Service Code" <> xSalesShipmentHeader."Shipping Agent Service Code") or
          ("Promised Delivery Date" <> xSalesShipmentHeader."Promised Delivery Date") or
          ("Package Tracking No." <> xSalesShipmentHeader."Package Tracking No.") or
          ("Outbound Whse. Handling Time" <> xSalesShipmentHeader."Outbound Whse. Handling Time") or
          ("Shipping Time" <> xSalesShipmentHeader."Shipping Time") or
          ("Shipping Agent Service Code" <> xSalesShipmentHeader."Shipping Agent Service Code");

        OnAfterRecordChanged(Rec, xSalesShipmentHeader, IsChanged);
    end;

    [Scope('OnPrem')]
    procedure SetRec(SalesShipmentHeader: Record "Sales Shipment Header")
    begin
        Rec := SalesShipmentHeader;
        Insert;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordChanged(var SalesShipmentHeader: Record "Sales Shipment Header"; xSalesShipmentHeader: Record "Sales Shipment Header"; var IsChanged: Boolean)
    begin
    end;
}

