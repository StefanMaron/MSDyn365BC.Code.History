codeunit 18900 "Pay-TCS"
{
    procedure PayTCS(var GenJnlLine: Record "Gen. Journal Line")
    var
        TCSEntry: Record "TCS Entry";
        TCSEntryPage: Page "Pay TCS";
        TCSEntriesErr: Label 'There are no TCS entries for Account No. %1.', Comment = '%1=Account No.';
    begin
        GenJnlLine.TestField("Document No.");
        GenJnlLine.TestField("Account No.");
        GenJnlLine.TestField("T.C.A.N. No.");
        GenJnlLine."Pay TCS" := True;
        GenJnlLine.Modify();

        Clear(TCSEntryPage);
        TCSEntry.SetRange("Account No.", GenJnlLine."Account No.");
        TCSEntry.SetRange("T.C.A.N. No.", GenJnlLine."T.C.A.N. No.");
        TCSEntry.SetFilter("Total TCS Including SHE CESS", '<>%1', 0);
        TCSEntry.SetRange("TCS Paid", False);
        TCSEntry.SetRange(Reversed, False);
        If not TCSEntry.FindFirst() Then
            Error(TCSEntriesErr, GenJnlLine."Account No.");

        TCSEntryPage.SetProperties(GenJnlLine."Journal Batch Name", GenJnlLine."Journal Template Name", GenJnlLine."Line No.");
        TCSEntryPage.SetTableView(TCSEntry);
        TCSEntryPage.Run();
    end;
}