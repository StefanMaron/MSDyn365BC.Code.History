query 11750 "Cash Desks Balance"
{
    Caption = 'Cash Desks Balance';

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
}

