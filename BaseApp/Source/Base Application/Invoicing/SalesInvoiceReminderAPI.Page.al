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
            field(InvoiceId; Rec.InvoiceId)
            {
                ApplicationArea = Invoicing, Basic, Suite;
            }
            field(Message; Rec.Message)
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
        if IsNullGuid(Rec.InvoiceId) then
            Error('');

        SalesInvoiceHeader.GetBySystemId(Rec.InvoiceId);

        SalesInvoiceHeader.EmailRecords(false);

        exit(true);
    end;

    trigger OnOpenPage()
    begin
        SelectLatestVersion();
    end;
}
#endif