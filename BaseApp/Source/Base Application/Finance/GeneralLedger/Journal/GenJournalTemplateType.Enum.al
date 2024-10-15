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
    value(11; Cash)
    {
        Caption = 'Cash';
    }
    value(12; Bank)
    {
        Caption = 'Bank';
    }
}