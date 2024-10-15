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
                field("Additional Information"; "Additional Information")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies additional declaration information that is needed for this shipment.';
                }
                field("Additional Notes"; "Additional Notes")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies additional notes that are needed for this shipment.';
                }
                field("Additional Instructions"; "Additional Instructions")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies additional instructions that are needed for this shipment.';
                }
                field("TDD Prepared By"; "TDD Prepared By")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the user ID of the transport delivery document (TDD) for the posted sales shipment.';
                }
                field("3rd Party Loader Type"; "3rd Party Loader Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the type of third party that is responsible for loading the items for this document.';
                }
                field("3rd Party Loader No."; "3rd Party Loader No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the ID of the vendor or contact who is responsible for loading the items for this document.';
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

    local procedure RecordChanged() IsChanged : Boolean
    begin
        IsChanged :=
          ("Shipping Agent Code" <> xSalesShipmentHeader."Shipping Agent Code") or
          ("Package Tracking No." <> xSalesShipmentHeader."Package Tracking No.") or
          ("Shipping Agent Service Code" <> xSalesShipmentHeader."Shipping Agent Service Code") or
          ("Additional Information" <> xSalesShipmentHeader."Additional Information") or
          ("Additional Notes" <> xSalesShipmentHeader."Additional Notes") or
          ("Additional Instructions" <> xSalesShipmentHeader."Additional Instructions") or
          ("TDD Prepared By" <> xSalesShipmentHeader."TDD Prepared By") or
          ("3rd Party Loader Type" <> xSalesShipmentHeader."3rd Party Loader Type") or
          ("3rd Party Loader No." <> xSalesShipmentHeader."3rd Party Loader No.");

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

