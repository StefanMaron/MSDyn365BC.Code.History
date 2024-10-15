codeunit 10141 "Deposit-Post (Yes/No)"
{
    TableNo = "Deposit Header";

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

