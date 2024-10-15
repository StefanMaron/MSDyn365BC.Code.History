namespace Microsoft.Sales.Posting;

using Microsoft.Finance.ReceivablesPayables;

enum 815 "Sales Invoice Posting" implements "Invoice Posting"
{
    Extensible = true;

    value(0; "Invoice Posting (Default)")
    {
        Caption = 'Invoice Posting (Default)';
        Implementation = "Invoice Posting" = "Undefined Post Invoice";
    }
    value(815; "Invoice Posting (v.19)")
    {
        Caption = 'Invoice Posting (v.19)';
        Implementation = "Invoice Posting" = "Sales Post Invoice";
    }
}