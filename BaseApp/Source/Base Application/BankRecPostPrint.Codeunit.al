#pragma warning disable AS0074
#if not CLEAN21
codeunit 10122 "Bank Rec.-Post + Print"
{
    TableNo = "Bank Rec. Header";
    ObsoleteReason = 'Deprecated in favor of W1 Bank Reconciliation';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';


    trigger OnRun()
    begin
        BankRecHeader.Copy(Rec);

        if not Confirm(Text000, false) then
            exit;

        BankRecPost.Run(BankRecHeader);
        Rec := BankRecHeader;
        Commit();

        if PostedBankRecHeader.Get("Bank Account No.", "Statement No.") then
            DocPrint.PrintBankRecStmt(PostedBankRecHeader);
    end;

    var
        BankRecHeader: Record "Bank Rec. Header";
        PostedBankRecHeader: Record "Posted Bank Rec. Header";
        BankRecPost: Codeunit "Bank Rec.-Post";
        Text000: Label 'Do you want to post and print the Bank Reconcilation?';
        DocPrint: Codeunit "Document-Print";
}

#endif
#pragma warning restore AS0074