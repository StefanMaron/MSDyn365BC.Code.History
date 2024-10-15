pageextension 1703 BankAccountListExt extends "Bank Account List"
{
    Caption = 'Bank Accounts';

    actions
    {
        addafter(Statements)
        {
            action("Bank Deposits")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Deposits';
                Image = DepositSlip;
                RunObject = Page "Posted Bank Deposit List";
                RunPageLink = "Bank Account No." = FIELD("No.");
                RunPageView = SORTING("Bank Account No.");
                ToolTip = 'View the list of posted bank deposits for the bank account.';
                Visible = ShouldSeePostedBankDeposits;
            }
        }
    }

    trigger OnOpenPage()
    var
        FeatureBankDeposits: Codeunit "Feature Bank Deposits";
    begin
        ShouldSeePostedBankDeposits := FeatureBankDeposits.ShouldSeePostedBankDeposits()
    end;

    var
        ShouldSeePostedBankDeposits: Boolean;
}