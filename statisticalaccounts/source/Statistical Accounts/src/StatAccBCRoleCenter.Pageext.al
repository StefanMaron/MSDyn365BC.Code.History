pageextension 2620 "Stat. Acc. BC Role Center" extends "Business Manager Role Center"
{
    actions
    {
        addafter(Dimensions)
        {
            action(StatisticalAccounts)
            {
                ApplicationArea = All;
                Caption = 'Statistical account';
                Image = Ledger;
                RunObject = page "Statistical Account List";
                ToolTip = 'Define statistical accounts for tracking non-transactional data.';
            }
        }
    }
}