page 12165 "Posted Transfer Shpt. - Update"
{
    Caption = 'Posted Transfer Shpt. - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Transfer Shipment Header";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("No."; "No.")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Transfer-from Code"; "Transfer-from Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the code of the location that items are transferred from.';
                }
                field("Transfer-to Code"; "Transfer-to Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the code of the location that the items are transferred to.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the posting date for this document.';
                }
            }
            group(Reporting)
            {
                Caption = 'Reporting';
                field("Transport Reason Code"; "Transport Reason Code")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the transport reason codes in the Transfer Shipment Header table.';
                }
                field("Goods Appearance"; "Goods Appearance")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies a goods appearance code.';
                }
                field("Gross Weight"; "Gross Weight")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the gross weight of an item in the Transfer Shipment Header table.';
                }
                field("Net Weight"; "Net Weight")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the net weight of the item.';
                }
                field("Parcel Units"; "Parcel Units")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the number of packages on a subcontractor transfer shipment order.';
                }
                field(Volume; Volume)
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the volume of one unit of the item.';
                }
                field("Shipping Notes"; "Shipping Notes")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the product''s shipping notes on a subcontractor transfer order.';
                }
                field("3rd Party Loader Type"; "3rd Party Loader Type")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the type of third party that is responsible for loading the items for this document.';
                }
                field("3rd Party Loader No."; "3rd Party Loader No.")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the ID of the vendor or contact that is responsible for loading the items for this document.';
                }
                field("Shipping Starting Date"; "Shipping Starting Date")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the date that the transfer shipment order is expected to ship.';
                }
                field("Shipping Starting Time"; "Shipping Starting Time")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the time that the transfer shipment order is expected to ship.';
                }
                field("Package Tracking No."; "Package Tracking No.")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the tracking number of a package on a subcontractor order.';
                }
                field("Additional Information"; "Additional Information")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies additional declaration information that is needed for the shipment.';
                }
                field("Additional Notes"; "Additional Notes")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies additional notes that are needed for the shipment.';
                }
                field("Additional Instructions"; "Additional Instructions")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies additional instructions that are needed for the shipment.';
                }
                field("TDD Prepared By"; "TDD Prepared By")
                {
                    ApplicationArea = Location;
                    Editable = true;
                    ToolTip = 'Specifies the user ID of the transport delivery document (TDD) for the transfer shipment.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        xTransferShptHeader := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ShptHeaderEdit: Codeunit "Shipment Header - Edit";
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged then
                ShptHeaderEdit.ModifyTransferShipment(Rec);
    end;

    var
        xTransferShptHeader: Record "Transfer Shipment Header";

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged :=
          ("Transport Reason Code" <> xTransferShptHeader."Transport Reason Code") or
          ("Goods Appearance" <> xTransferShptHeader."Goods Appearance") or
          ("Gross Weight" <> xTransferShptHeader."Gross Weight") or
          ("Net Weight" <> xTransferShptHeader."Net Weight") or
          ("Parcel Units" <> xTransferShptHeader."Parcel Units") or
          (Volume <> xTransferShptHeader.Volume) or
          ("Shipping Notes" <> xTransferShptHeader."Shipping Notes") or
          ("3rd Party Loader Type" <> xTransferShptHeader."3rd Party Loader Type") or
          ("3rd Party Loader No." <> xTransferShptHeader."3rd Party Loader No.") or
          ("Shipping Starting Date" <> xTransferShptHeader."Shipping Starting Date") or
          ("Shipping Starting Time" <> xTransferShptHeader."Shipping Starting Time") or
          ("Package Tracking No." <> xTransferShptHeader."Package Tracking No.") or
          ("Additional Information" <> xTransferShptHeader."Additional Information") or
          ("Additional Notes" <> xTransferShptHeader."Additional Notes") or
          ("Additional Instructions" <> xTransferShptHeader."Additional Instructions") or
          ("TDD Prepared By" <> xTransferShptHeader."TDD Prepared By");

        OnAfterRecordChanged(Rec, xTransferShptHeader, IsChanged);
    end;

    [Scope('OnPrem')]
    procedure SetRec(TransferShptHeader: Record "Transfer Shipment Header")
    begin
        Rec := TransferShptHeader;
        Insert;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordChanged(var TransferShptHeader: Record "Transfer Shipment Header"; xTransferShptHeader: Record "Transfer Shipment Header"; var IsChanged: Boolean)
    begin
    end;
}

