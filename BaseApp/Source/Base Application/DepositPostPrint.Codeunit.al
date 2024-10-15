codeunit 10142 "Deposit-Post + Print"
{
    TableNo = "Deposit Header";

    trigger OnRun()
    begin
        DepositHeader.Copy(Rec);

        if not Confirm(Text000, false) then
            exit;

        DepositPost.Run(DepositHeader);
        Rec := DepositHeader;
        Commit();

        if PostedDepositHeader.Get("No.") then begin
            PostedDepositHeader.SetRecFilter;
            REPORT.Run(REPORT::Deposit, false, false, PostedDepositHeader);
        end;
    end;

    var
        DepositHeader: Record "Deposit Header";
        PostedDepositHeader: Record "Posted Deposit Header";
        DepositPost: Codeunit "Deposit-Post";
        Text000: Label 'Do you want to post and print the Deposit?';
}

