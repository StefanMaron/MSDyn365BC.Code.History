namespace Microsoft.CRM.Outlook;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;

table 1606 "Office Invoice"
{
    Caption = 'Office Invoice', Comment = 'This table is used to keep track of invoices that have been created from the context of an Office add-in.';

    fields
    {
        field(1; "Item ID"; Text[250])
        {
            Caption = 'Item ID';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(3; Posted; Boolean)
        {
            Caption = 'Posted';
        }
    }

    keys
    {
        key(Key1; "Item ID", "Document No.", Posted)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure ShowInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if Posted then begin
            SalesInvoiceHeader.Get("Document No.");
            PAGE.Run(PAGE::"Posted Sales Invoice", SalesInvoiceHeader);
        end else begin
            SalesHeader.Get(SalesHeader."Document Type"::Invoice, "Document No.");
            PAGE.Run(PAGE::"Sales Invoice", SalesHeader);
        end;
    end;

    procedure UnlinkDocument(DocumentNo: Code[20]; IsPosted: Boolean)
    var
        OfficeInvoice: Record "Office Invoice";
    begin
        OfficeInvoice.SetRange("Document No.", DocumentNo);
        OfficeInvoice.SetRange(Posted, IsPosted);
        OfficeInvoice.DeleteAll();
    end;
}

