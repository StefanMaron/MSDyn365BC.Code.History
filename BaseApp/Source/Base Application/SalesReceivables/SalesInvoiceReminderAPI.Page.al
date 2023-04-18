#if not CLEAN21
page 2201 "Sales Invoice Reminder API"
{
    Caption = 'Sales Invoice Reminder API';
    DeleteAllowed = false;
    ModifyAllowed = false;
    SourceTable = "O365 Sales Invoice Document";
    SourceTableTemporary = true;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            field(InvoiceId; InvoiceId)
            {
                ApplicationArea = Invoicing, Basic, Suite;
            }
            field(Message; Message)
            {
                ApplicationArea = Invoicing, Basic, Suite;
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

        SalesInvoiceHeader.GetBySystemId(InvoiceId);

        SalesInvoiceHeader.EmailRecords(false);

        exit(true);
    end;

    trigger OnOpenPage()
    begin
        SelectLatestVersion();
    end;
}
#endif