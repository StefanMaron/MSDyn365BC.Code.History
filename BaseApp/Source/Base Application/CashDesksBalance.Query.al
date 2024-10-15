#if not CLEAN18
query 11750 "Cash Desks Balance"
{
    Caption = 'Cash Desks Balance';
    ObsoleteState = Pending;
    ObsoleteReason = 'Removed because chart Q11750-01 will not be used.';
    ObsoleteTag = '18.0';

    elements
    {
        dataitem(Bank_Account; "Bank Account")
        {
            filter(Account_Type; "Account Type")
            {
                ColumnFilter = Account_Type = FILTER("Cash Desk");
            }
            column(No; "No.")
            {
            }
            column(Name; Name)
            {
            }
            column(Balance_LCY; "Balance (LCY)")
            {
            }
        }
    }
#endif
#if not CLEAN17

    trigger OnBeforeOpen()
    var
        CashDeskManagement: Codeunit CashDeskManagement;
        CashDeskFilter: Text;
    begin
        CashDeskFilter := CashDeskManagement.GetCashDesksFilter;
        if CashDeskFilter <> '' then
            SetFilter(No, CashDeskFilter)
        else
            SetRange(No, '');
    end;
#endif
#if not CLEAN18    
}
#endif