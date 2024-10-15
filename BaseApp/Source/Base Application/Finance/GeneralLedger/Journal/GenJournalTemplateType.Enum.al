namespace Microsoft.Finance.GeneralLedger.Journal;

enum 89 "Gen. Journal Template Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; General)
    {
        Caption = 'General';
    }
    value(1; Sales)
    {
        Caption = 'Sales';
    }
    value(2; Purchases)
    {
        Caption = 'Purchases';
    }
    value(3; "Cash Receipts")
    {
        Caption = 'Cash Receipts';
    }
    value(4; Payments)
    {
        Caption = 'Payments';
    }
    value(5; Assets)
    {
        Caption = 'Assets';
    }
    value(6; Intercompany)
    {
        Caption = 'Intercompany';
    }
    value(7; Jobs)
    {
        Caption = 'Projects';
    }
    value(8; "VAT Settlement")
    {
        Caption = 'VAT Settlement';
    }
    value(9; "Bank Payments")
    {
        Caption = 'Bank Payments';
    }
    value(10; "Cash Order Payments")
    {
        Caption = 'Cash Order Payments';
    }
    value(13; "Future Expenses")
    {
        Caption = 'Future Expenses';
    }
    value(14; "VAT Reinstatement")
    {
        Caption = 'VAT Reinstatement';
    }
}