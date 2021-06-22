page 2201 "Sales Invoice Reminder API"
{
    Caption = 'Sales Invoice Reminder API';
    DeleteAllowed = false;
    ModifyAllowed = false;
    SourceTable = "O365 Sales Invoice Document";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            field(InvoiceId; InvoiceId)
            {
                ApplicationArea = Basic, Suite, Invoicing;
            }
            field(Message; Message)
            {
                ApplicationArea = Basic, Suite, Invoicing;
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if IsNullGuid(InvoiceId) then
            Error('');

        SalesInvoiceHeader.SetRange(Id, InvoiceId);
        SalesInvoiceHeader.FindFirst;

        SalesInvoiceHeader.EmailRecords(false);

        exit(true);
    end;

    trigger OnOpenPage()
    begin
        SelectLatestVersion;
    end;
}

