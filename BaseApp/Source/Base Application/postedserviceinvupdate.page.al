page 1356 "Posted Service Inv. - Update"
{
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Service Invoice Header";
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
                field("Bill-to Name"; "Bill-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Editable = false;
                    ToolTip = 'Specifies the name of customer.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the posting date for the document.';
                }
            }
            group(Payment)
            {
                Caption = 'Payment';
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the customer must pay for products on the service document, such as with bank transfer, cash, or check.';
                }
                field("Payment Reference"; "Payment Reference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment of the service invoice.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        xServiceInvoiceHeader := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                CODEUNIT.Run(CODEUNIT::"Service Inv. Header - Edit", Rec);
    end;

    var
        xServiceInvoiceHeader: Record "Service Invoice Header";

    local procedure RecordChanged(): Boolean
    begin
        exit(
          ("Payment Method Code" <> xServiceInvoiceHeader."Payment Method Code") or
          ("Payment Reference" <> xServiceInvoiceHeader."Payment Reference"));
    end;

    [Scope('OnPrem')]
    procedure SetRec(ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
        Rec := ServiceInvoiceHeader;
        Insert();
    end;
}

