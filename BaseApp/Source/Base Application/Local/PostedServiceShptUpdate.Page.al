page 12166 "Posted Service Shpt. - Update"
{
    Caption = 'Posted Service Shpt. - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Service Shipment Header";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Additional Information"; Rec."Additional Information")
                {
                    ApplicationArea = Service;
                    Editable = true;
                    ToolTip = 'Specifies additional declaration information that is needed for the shipment.';
                }
                field("Additional Notes"; Rec."Additional Notes")
                {
                    ApplicationArea = Service;
                    Editable = true;
                    ToolTip = 'Specifies additional notes that are needed for the shipment.';
                }
                field("Additional Instructions"; Rec."Additional Instructions")
                {
                    ApplicationArea = Service;
                    Editable = true;
                    ToolTip = 'Specifies additional instructions that are needed for the shipment.';
                }
                field("TDD Prepared By"; Rec."TDD Prepared By")
                {
                    ApplicationArea = Service;
                    Editable = true;
                    ToolTip = 'Specifies the user ID of the transport delivery document (TDD) for the posted service shipment.';
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Service;
                    Editable = true;
                    ToolTip = 'Specifies the code for the shipment method that is associated with the posted service shipment.';
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Service;
                    Editable = true;
                    ToolTip = 'Specifies the code of the shipping agent for the posted service shipment.';
                }
                field("3rd Party Loader Type"; Rec."3rd Party Loader Type")
                {
                    ApplicationArea = Service;
                    Editable = true;
                    ToolTip = 'Specifies the type of third party that is responsible for loading the items for this document.';
                }
                field("3rd Party Loader No."; Rec."3rd Party Loader No.")
                {
                    ApplicationArea = Service;
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
        xServiceShptHeader := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ShptHeaderEdit: Codeunit "Shipment Header - Edit";
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                ShptHeaderEdit.ModifyServiceShipment(Rec);
    end;

    var
        xServiceShptHeader: Record "Service Shipment Header";

    local procedure RecordChanged(): Boolean
    begin
        exit(
          ("Additional Information" <> xServiceShptHeader."Additional Information") or
          ("Additional Notes" <> xServiceShptHeader."Additional Notes") or
          ("Additional Instructions" <> xServiceShptHeader."Additional Instructions") or
          ("TDD Prepared By" <> xServiceShptHeader."TDD Prepared By") or
          ("Shipment Method Code" <> xServiceShptHeader."Shipment Method Code") or
          ("Shipping Agent Code" <> xServiceShptHeader."Shipping Agent Code") or
          ("3rd Party Loader Type" <> xServiceShptHeader."3rd Party Loader Type") or
          ("3rd Party Loader No." <> xServiceShptHeader."3rd Party Loader No."));
    end;

    [Scope('OnPrem')]
    procedure SetRec(ServiceShptHeader: Record "Service Shipment Header")
    begin
        Rec := ServiceShptHeader;
        Insert();
    end;
}

