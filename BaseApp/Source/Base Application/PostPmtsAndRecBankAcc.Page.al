page 417 "Post Pmts and Rec. Bank Acc."
{
    PageType = StandardDialog;
    SourceTable = "Bank Acc. Reconciliation";
    Caption = 'Bank Account Reconciliation';

    layout
    {
        area(Content)
        {
            field("Balance Last Statement"; "Balance Last Statement")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Balance Last Statement';
                ToolTip = 'Specifies the ending balance shown on the last bank statement, which was used in the last posted bank reconciliation for this bank account.';
                trigger OnValidate()
                var
                    BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
                begin
                    Rec.Modify();
                    with BankAccReconciliationLine do begin
                        LinesExist(Rec);
                        CalcSums("Statement Amount", Difference);
                        TotalBalance := Rec."Balance Last Statement" + "Statement Amount";
                        CurrPage.Update();
                    end;
                end;
            }
            field("Statement Ending Balance"; "Statement Ending Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Statement Ending Balance';
                ToolTip = 'Specifies the ending balance shown on the bank''s statement that you want to reconcile with the bank account.';
                trigger OnValidate()
                begin
                    Rec.Modify();
                    CurrPage.Update();
                end;
            }
            field(TotalBalance; TotalBalance)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatExpression = GetCurrencyCode();
                AutoFormatType = 1;
                Editable = false;
                Caption = 'Total Balance';
                ToolTip = 'Specifies the accumulated balance of the bank reconciliation, which consists of the Balance Last Statement field, plus the balance in the Statement Amount field.';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        with BankAccReconciliationLine do begin
            LinesExist(Rec);
            CalcSums("Statement Amount", Difference);
            TotalBalance := Rec."Balance Last Statement" + "Statement Amount";
        end;
    end;

    var
        TotalBalance: Decimal;

    local procedure GetCurrencyCode(): Code[10]
    var
        BankAcc: Record "Bank Account";
    begin
        if Rec."Bank Account No." = BankAcc."No." then
            exit(BankAcc."Currency Code");

        if BankAcc.Get(Rec."Bank Account No.") then
            exit(BankAcc."Currency Code");

        exit('');
    end;
}