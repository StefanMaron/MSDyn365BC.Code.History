namespace Microsoft.Finance.ReceivablesPayables;

enum 109 "Net Cust/Vend Balances Order"
{
    Extensible = true;

    value(0; "Fin. Ch. Memo First") { Caption = 'Fin. Ch. Memo First'; }
    value(1; "Invoices First") { Caption = 'Invoices First'; }
    value(2; "By Entry No.") { Caption = 'By Entry No.'; }
}