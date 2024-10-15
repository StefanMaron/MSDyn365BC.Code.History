#if not CLEAN20
codeunit 10121 "Bank Rec.-Post (Yes/No)"
{
    TableNo = "Bank Rec. Header";
    ObsoleteReason = 'Deprecated in favor of W1 Bank Reconciliation';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';

    trigger OnRun()
    begin
        BankRecHeader.Copy(Rec);
        Code;
        Rec := BankRecHeader;
    end;

    var
        Text001: Label 'Do you want to post bank rec. statement %1 for bank account %2?';
        BankRecHeader: Record "Bank Rec. Header";
        BankRecPost: Codeunit "Bank Rec.-Post";
        PostedSuccessfullyMsg: Label 'Statement successfully posted.';

    local procedure "Code"()
    begin
        if Confirm(Text001, false,
             BankRecHeader."Statement No.",
             BankRecHeader."Bank Account No.")
        then begin
            BankRecPost.Run(BankRecHeader);
            Commit();
            Message(PostedSuccessfullyMsg);
        end;
    end;
}

#endif