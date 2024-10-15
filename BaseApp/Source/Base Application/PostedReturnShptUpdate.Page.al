page 1352 "Posted Return Shpt. - Update"
{
    Caption = 'Posted Return Shpt. - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Return Shipment Header";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("No."; "No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Buy-from Vendor Name"; "Buy-from Vendor Name")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Vendor';
                    Editable = false;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to County"; "Ship-to County")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Ship-to County';
                    Editable = true;
                }
                field("Ship-to Country/Region Code"; "Ship-to Country/Region Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Ship-to Country/Region';
                    Editable = true;
                }
                field("Additional Information"; "Additional Information")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = true;
                    ToolTip = 'Specifies additional declaration information that is needed for this shipment.';
                }
                field("Additional Notes"; "Additional Notes")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = true;
                    ToolTip = 'Specifies additional notes that are needed for this shipment.';
                }
                field("Additional Instructions"; "Additional Instructions")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = true;
                    ToolTip = 'Specifies additional instructions that are needed for this shipment.';
                }
                field("TDD Prepared By"; "TDD Prepared By")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = true;
                    ToolTip = 'Specifies the user ID of the transport delivery document (TDD) for the posted return shipment.';
                }
                field("Shipment Method Code"; "Shipment Method Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = true;
                    ToolTip = 'Specifies the shipment method.';
                }
                field("Shipping Agent Code"; "Shipping Agent Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = true;
                    ToolTip = 'Specifies the code of the shipping agent for the posted return shipment.';
                }
                field("3rd Party Loader Type"; "3rd Party Loader Type")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = true;
                    ToolTip = 'Specifies the type of third party that is responsible for loading the items for this document.';
                }
                field("3rd Party Loader No."; "3rd Party Loader No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = true;
                    ToolTip = 'Specifies the ID of the vendor or contact that is responsible for loading the items for this document.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        xReturnShipmentHeader := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged then
                CODEUNIT.Run(CODEUNIT::"Return Shipment Header - Edit", Rec);
    end;

    var
        xReturnShipmentHeader: Record "Return Shipment Header";

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged :=
            ("Ship-to County" <> xReturnShipmentHeader."Ship-to County") or
            ("Ship-to Country/Region Code" <> xReturnShipmentHeader."Ship-to Country/Region Code") or
            ("Additional Information" <> xReturnShipmentHeader."Additional Information") or
            ("Additional Notes" <> xReturnShipmentHeader."Additional Notes") or
            ("Additional Instructions" <> xReturnShipmentHeader."Additional Instructions") or
            ("TDD Prepared By" <> xReturnShipmentHeader."TDD Prepared By") or
            ("Shipment Method Code" <> xReturnShipmentHeader."Shipment Method Code") or
            ("Shipping Agent Code" <> xReturnShipmentHeader."Shipping Agent Code") or
            ("3rd Party Loader Type" <> xReturnShipmentHeader."3rd Party Loader Type") or
            ("3rd Party Loader No." <> xReturnShipmentHeader."3rd Party Loader No.");

        OnAfterRecordChanged(Rec, xRec, IsChanged);
    end;

    [Scope('OnPrem')]
    procedure SetRec(ReturnShipmentHeader: Record "Return Shipment Header")
    begin
        Rec := ReturnShipmentHeader;
        Insert;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordChanged(var ReturnShipmentHeader: Record "Return Shipment Header"; xReturnShipmentHeader: Record "Return Shipment Header"; var IsChanged: Boolean);
    begin
    end;
}