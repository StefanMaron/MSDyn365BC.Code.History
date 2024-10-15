#pragma warning disable AS0074
#if not CLEAN21
codeunit 10141 "Deposit-Post (Yes/No)"
{
    TableNo = "Deposit Header";
    ObsoleteReason = 'Replaced by new Bank Deposits extension';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    trigger OnRun()
    begin
        DepositHeader.Copy(Rec);

        if not Confirm(Text000, false) then
            exit;

        DepositPost.Run(DepositHeader);
        Rec := DepositHeader;
    end;

    var
        DepositHeader: Record "Deposit Header";
        DepositPost: Codeunit "Deposit-Post";
        Text000: Label 'Do you want to post the Deposit?';
}

#endif
#pragma warning restore AS0074