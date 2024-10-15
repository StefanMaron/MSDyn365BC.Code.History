namespace Microsoft.Finance.GeneralLedger.Journal;

enum 6 "Gen. Journal Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Payment") { Caption = 'Payment'; }
    value(2; "Invoice") { Caption = 'Invoice'; }
    value(3; "Credit Memo") { Caption = 'Credit Memo'; }
    value(4; "Finance Charge Memo") { Caption = 'Finance Charge Memo'; }
    value(5; "Reminder") { Caption = 'Reminder'; }
    value(6; "Refund") { Caption = 'Refund'; }
    value(21; "Bill") { Caption = 'Bill'; }
}