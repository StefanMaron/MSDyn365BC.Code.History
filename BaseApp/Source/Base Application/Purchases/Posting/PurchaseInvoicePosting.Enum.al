namespace Microsoft.Purchases.Posting;

using Microsoft.Finance.ReceivablesPayables;

enum 816 "Purchase Invoice Posting" implements "Invoice Posting"
{
    Extensible = true;

    value(0; "Invoice Posting (Default)")
    {
        Caption = 'Invoice Posting (Default)';
        Implementation = "Invoice Posting" = "Undefined Post Invoice";
    }
    value(816; "Invoice Posting (v.19)")
    {
        Caption = 'Invoice Posting (v.19)';
        Implementation = "Invoice Posting" = "Purch. Post Invoice";
    }
}