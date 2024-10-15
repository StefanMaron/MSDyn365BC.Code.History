namespace Microsoft.Sales.History;

page 1353 "Posted Return Receipt - Update"
{
    Caption = 'Posted Return Receipt - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Return Receipt Header";
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
                    ApplicationArea = SalesReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Customer';
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = SalesReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Editable = true;
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Agent';
                    Editable = true;
                    ToolTip = 'Specifies which shipping agent is used to transport the items on the sales document to the customer.';
                }
                field("Package Tracking No."; Rec."Package Tracking No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Editable = true;
                    ToolTip = 'Specifies the shipping agent''s package number.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        xReturnReceiptHeader := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                CODEUNIT.Run(CODEUNIT::"Return Receipt Header - Edit", Rec);
    end;

    var
        xReturnReceiptHeader: Record "Return Receipt Header";

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged :=
            (Rec."Bill-to County" <> xReturnReceiptHeader."Bill-to County") or
            (Rec."Bill-to Country/Region Code" <> xReturnReceiptHeader."Bill-to Country/Region Code") or
            (Rec."Shipping Agent Code" <> xReturnReceiptHeader."Shipping Agent Code") or
            (Rec."Package Tracking No." <> xReturnReceiptHeader."Package Tracking No.");

        OnAfterRecordChanged(Rec, xRec, IsChanged, xReturnReceiptHeader);
    end;

    procedure SetRec(ReturnReceiptHeader: Record "Return Receipt Header")
    begin
        Rec := ReturnReceiptHeader;
        Rec.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordChanged(var ReturnReceiptHeader: Record "Return Receipt Header"; xReturnReceiptHeader: Record "Return Receipt Header"; var IsChanged: Boolean; xReturnReceiptHeaderGlobal: Record "Return Receipt Header");
    begin
    end;
}

