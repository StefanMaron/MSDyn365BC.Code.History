namespace Microsoft.Sales.History;

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
            group("Invoice Details")
            {
                Caption = 'Invoice Details';
                field("Posting Description"; Rec."Posting Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies any text that is entered to accompany the posting, for example for information to auditors.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the date on which the invoice is due for payment.';
                }
                field("Promised Pay Date"; Rec."Promised Pay Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the date on which the customer have promised to pay this invoice.';
                }
                field("Dispute Status"; Rec."Dispute Status")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Importance = Promoted;
                    Tooltip = 'Specifies if there is an ongoing dispute for this Invoice';
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
            group("Electronic Document")
            {
                Caption = 'Electronic Document';
                field("CFDI Cancellation Reason Code"; Rec."CFDI Cancellation Reason Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the reason for the cancellation as a code.';
                }
                field("Substitution Document No."; Rec."Substitution Document No.")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the document number that replaces the canceled one. It is required when the cancellation reason is 01.';
                }
                field("Fiscal Invoice Number PAC"; Rec."Fiscal Invoice Number PAC")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the official invoice number for the related electronic document. When you generate an electronic document, Business Central sends it to a an authorized service provider, PAC, for processing. When the PAC returns the electronic document with the digital stamp, the electronic document includes a fiscal invoice number that uniquely identifies the document.';
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
        IsChanged := (Rec."Payment Method Code" <> xSalesInvoiceHeader."Payment Method Code") or
          (Rec."Payment Reference" <> xSalesInvoiceHeader."Payment Reference") or
          (Rec."Company Bank Account Code" <> xSalesInvoiceHeader."Company Bank Account Code") or
          (Rec."CFDI Cancellation Reason Code" <> xSalesInvoiceHeader."CFDI Cancellation Reason Code") or
          (Rec."Substitution Document No." <> xSalesInvoiceHeader."Substitution Document No.") or
          (Rec."Posting Description" <> xSalesInvoiceHeader."Posting Description") or
          (Rec."Fiscal Invoice Number PAC" <> xSalesInvoiceHeader."Fiscal Invoice Number PAC") or
          (Rec."Posting Description" <> xSalesInvoiceHeader."Posting Description") or
          (Rec."Promised Pay Date" <> xSalesInvoiceHeader."Promised Pay Date") or
          (Rec."Dispute Status" <> xSalesInvoiceHeader."Dispute Status");

        OnAfterRecordChanged(Rec, xSalesInvoiceHeader, IsChanged);
    end;

    procedure SetRec(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        Rec := SalesInvoiceHeader;
        Rec.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordChanged(var SalesInvoiceHeader: Record "Sales Invoice Header"; xSalesInvoiceHeader: Record "Sales Invoice Header"; var IsChanged: Boolean)
    begin
    end;
}

