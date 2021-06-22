page 1351 "Posted Purch. Invoice - Update"
{
    Caption = 'Posted Purch. Invoice - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Purch. Inv. Header";
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
                    ToolTip = 'Specifies the posted invoice number.';
                }
                field("Buy-from Vendor Name"; "Buy-from Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor';
                    Editable = false;
                    ToolTip = 'Specifies the name of the vendor who shipped the items.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date the purchase header was posted.';
                }
            }
            group("Invoice Details")
            {
                Caption = 'Invoice Details';
                field("Payment Reference"; "Payment Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the payment of the purchase invoice.';
                }
                field("Creditor No."; "Creditor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the number of the vendor.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ship-to Address Code';
                    Editable = true;
                    ToolTip = 'Specifies the address on purchase orders shipped with a drop shipment directly from the vendor to a customer.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        xPurchInvHeader := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged then
                CODEUNIT.Run(CODEUNIT::"Purch. Inv. Header - Edit", Rec);
    end;

    var
        xPurchInvHeader: Record "Purch. Inv. Header";

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged :=
            ("Payment Reference" <> xPurchInvHeader."Payment Reference") or
            ("Creditor No." <> xPurchInvHeader."Creditor No.") or
            ("Ship-to Code" <> xPurchInvHeader."Ship-to Code");

        OnAfterRecordChanged(Rec, xRec, IsChanged);
    end;

    [Scope('OnPrem')]
    procedure SetRec(PurchInvHeader: Record "Purch. Inv. Header")
    begin
        Rec := PurchInvHeader;
        Insert;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordChanged(var PurchInvHeader: Record "Purch. Inv. Header"; xPurchInvHeader: Record "Purch. Inv. Header"; var IsChanged: Boolean)
    begin
    end;
}

