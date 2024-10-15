page 1355 "Posted Sales Inv. - Update"
{
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Sales Invoice Header";
    SourceTableTemporary = true;
    Caption = 'Posted Sales Inv. - Update';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the record.';
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Editable = false;
                    ToolTip = 'Specifies the name of customer at the sell-to address.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the posting date for the document.';
                }
            }
            group(Payment)
            {
                Caption = 'Payment';
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Method Code';
                    ToolTip = 'Specifies how the customer must pay for products on the sales document, such as with bank transfer, cash, or check.';
                }
                field("Payment Reference"; Rec."Payment Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Reference';
                    ToolTip = 'Specifies the payment of the sales invoice.';
                }
                field("Company Bank Account Code"; Rec."Company Bank Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company Bank Account Code';
                    ToolTip = 'Specifies the bank account to use for bank information when the document is printed.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        xSalesInvoiceHeader := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                CODEUNIT.Run(CODEUNIT::"Sales Inv. Header - Edit", Rec);
    end;

    var
        xSalesInvoiceHeader: Record "Sales Invoice Header";

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged := ("Payment Method Code" <> xSalesInvoiceHeader."Payment Method Code") or
          ("Payment Reference" <> xSalesInvoiceHeader."Payment Reference") or
          ("Company Bank Account Code" <> xSalesInvoiceHeader."Company Bank Account Code");

        OnAfterRecordChanged(Rec, xSalesInvoiceHeader, IsChanged);
    end;

    [Scope('OnPrem')]
    procedure SetRec(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        Rec := SalesInvoiceHeader;
        Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordChanged(var SalesInvoiceHeader: Record "Sales Invoice Header"; xSalesInvoiceHeader: Record "Sales Invoice Header"; var IsChanged: Boolean)
    begin
    end;
}

