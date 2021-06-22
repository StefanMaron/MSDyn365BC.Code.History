codeunit 179 "Reversal-Post"
{
    TableNo = "Reversal Entry";

    trigger OnRun()
    var
        GLReg: Record "G/L Register";
        GenJnlTemplate: Record "Gen. Journal Template";
        PostedDeferralHeader: Record "Posted Deferral Header";
        DeferralUtilities: Codeunit "Deferral Utilities";
        GenJnlPostReverse: Codeunit "Gen. Jnl.-Post Reverse";
        Txt: Text[1024];
        WarningText: Text[250];
        Number: Integer;
        Handled: Boolean;
    begin
        Reset;
        SetRange("Entry Type", "Entry Type"::"Fixed Asset");
        if FindFirst then
            WarningText := Text007;
        SetRange("Entry Type");
        if PrintRegister then
            Txt := Text004 + WarningText + '\' + Text005
        else
            Txt := Text004 + WarningText + '\' + Text002;
        if not FindFirst then
            Error(Text006);

        if not HideDialog then
            if not Confirm(Txt, false) then
                exit;

        ReversalEntry := Rec;
        if "Reversal Type" = "Reversal Type"::Transaction then
            ReversalEntry.SetReverseFilter("Transaction No.", "Reversal Type")
        else
            ReversalEntry.SetReverseFilter("G/L Register No.", "Reversal Type");
        ReversalEntry.CheckEntries;
        Get(1);
        if "Reversal Type" = "Reversal Type"::Register then
            Number := "G/L Register No."
        else
            Number := "Transaction No.";
        if not ReversalEntry.VerifyReversalEntries(Rec, Number, "Reversal Type") then
            Error(Text008);
        GenJnlPostReverse.Reverse(ReversalEntry, Rec);
        if PrintRegister then begin
            GenJnlTemplate.Validate(Type);
            if GenJnlTemplate."Posting Report ID" <> 0 then
                if GLReg.FindLast then begin
                    GLReg.SetRecFilter;
                    OnBeforeGLRegPostingReportPrint(GenJnlTemplate."Posting Report ID", false, false, GLReg, Handled);
                    if not Handled then
                        REPORT.Run(GenJnlTemplate."Posting Report ID", false, false, GLReg);
                end;
        end;
        DeleteAll();
        PostedDeferralHeader.DeleteForDoc(DeferralUtilities.GetGLDeferralDocType, ReversalEntry."Document No.", '', 0, '');
        if not HideDialog then
            Message(Text003);
    end;

    var
        Text002: Label 'Do you want to reverse the entries?';
        Text003: Label 'The entries were successfully reversed.';
        Text004: Label 'To reverse these entries, correcting entries will be posted.';
        Text005: Label 'Do you want to reverse the entries and print the report?';
        Text006: Label 'There is nothing to reverse.';
        Text007: Label '\There are one or more FA Ledger Entries. You should consider using the fixed asset function Cancel Entries.';
        Text008: Label 'Changes have been made to posted entries after the window was opened.\Close and reopen the window to continue.';
        ReversalEntry: Record "Reversal Entry";
        PrintRegister: Boolean;
        HideDialog: Boolean;

    procedure SetPrint(NewPrintRegister: Boolean)
    begin
        PrintRegister := NewPrintRegister;
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGLRegPostingReportPrint(var ReportID: Integer; ReqWindow: Boolean; SystemPrinter: Boolean; var GLRegister: Record "G/L Register"; var Handled: Boolean)
    begin
    end;
}

