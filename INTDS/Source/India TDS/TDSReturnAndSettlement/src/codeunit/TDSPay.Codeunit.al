codeunit 18746 "TDS Pay"
{
    procedure PayTDS(var GenJnlLine: Record "Gen. Journal Line")
    var
        TDSEntry: Record "TDS Entry";
        TDSEntryPage: Page "Pay TDS";
        AccountNoErr: Label 'There are no TDS entries for Account No. %1.', Comment = '%1 = G/L Account No.';
    begin
        GenJnlLine.TestField("Document No.");
        GenJnlLine.TestField("Account No.");
        GenJnlLine.TestField("T.A.N. No.");

        GenJnlLine."Pay TDS" := true;
        GenJnlLine.Modify();

        CLEAR(TDSEntryPage);
        TDSEntry.RESET();
        TDSEntry.SETRANGE("Account No.", GenJnlLine."Account No.");
        TDSEntry.SETRANGE("T.A.N. No.", GenJnlLine."T.A.N. No.");
        TDSEntry.SETFILTER("Total TDS Including SHE CESS", '<>%1', 0);
        TDSEntry.SETRANGE("TDS Paid", FALSE);
        TDSEntry.SETRANGE(Reversed, FALSE);
        if TDSEntry.FINDFIRST() then begin
            TDSEntryPage.SetProperties(GenJnlLine."Journal Batch Name", GenJnlLine."Journal Template Name", GenJnlLine."Line No.");
            TDSEntryPage.SETTABLEVIEW(TDSEntry);
            TDSEntryPage.RUN();
        END ELSE
            ERROR(AccountNoErr, GenJnlLine."Account No.");
    END;

    procedure PayWorkTax(var GenJnlLine: Record "Gen. Journal Line")
    var
        TDSEntry: Record "TDS Entry";
        WorkTaxEntryPage: Page "Pay WorkTax";
        AccountNoErr: Label 'There are no work tax entries for Account No. %1.', Comment = '%1 = Account No.';
    begin
        GenJnlLine.TESTFIELD("Document No.");
        GenJnlLine.TESTFIELD("Account No.");
        GenJnlLine."Pay Work Tax" := true;
        GenJnlLine.MODIFY();

        CLEAR(WorkTaxEntryPage);
        TDSEntry.RESET();
        TDSEntry.SETRANGE("Work Tax Account", GenJnlLine."Account No.");
        TDSEntry.SETRANGE("Work Tax Paid", FALSE);
        TDSEntry.SETRANGE(Reversed, FALSE);
        if TDSEntry.FINDFIRST() then begin
            WorkTaxEntryPage.SetProperties(GenJnlLine."Journal Batch Name", GenJnlLine."Journal Template Name", GenJnlLine."Line No.");
            WorkTaxEntryPage.SETTABLEVIEW(TDSEntry);
            WorkTaxEntryPage.RUN();
        END ELSE
            ERROR(AccountNoErr, GenJnlLine."Account No.");
    END;

    [EventSubscriber(ObjectType::Table, database::"Reversal Entry", 'OnBeforeReverseEntries', '', false, false)]
    local procedure OnBeforeReverseEntries(Number: Integer; RevType: Integer; var IsHandled: Boolean)
    var
        TDSEntry: Record "TDS Entry";
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
        TransactionNo: Integer;
        ClosedErr: Label 'You cannot reverse %1 No. %2 because the entry is closed.', Comment = '%1= Table Caption, %2= Entry No.';
        AlreadyReversedErr: Label 'You cannot reverse %1 No. %2 because the entry has already been involved in a reversal.', Comment = '%1 = TDS Entry Table Caption, %2 = Entry No.';
    begin
        if GLRegister.Get(Number) then begin
            GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
            if not GLEntry.FindFirst() then
                exit
            else
                TransactionNo := GLEntry."Transaction No.";
        end;

        TDSEntry.SetRange("Transaction No.", TransactionNo);
        if not TDSEntry.FindFirst() then
            exit;

        CheckPostingDate(
          TDSEntry."Posting Date", TDSEntry.TABLECAPTION, TDSEntry."Entry No.");

        IF TDSEntry."TDS Paid" THEN
            ERROR(
              ClosedErr, TDSEntry.TABLECAPTION, TDSEntry."Entry No.");

        IF TDSEntry.Reversed THEN
            ERROR(AlreadyReversedErr, TDSEntry.TABLECAPTION, TDSEntry."Entry No.");
    end;

    local procedure CheckPostingDate(PostingDate: Date; Caption: Text; EntryNo: Integer)
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        PostingDateErr: Label 'You cannot reverse %1 No. %2 because the posting date is not within the allowed posting period.', Comment = '%1= Table Caption, %2= Entry No.';
    begin
        IF GenJnlCheckLine.DateNotAllowed(PostingDate) THEN
            ERROR(PostingDateErr, Caption, EntryNo);
    end;

    [EventSubscriber(ObjectType::Table, database::"Reversal Entry", 'OnAfterInsertReversalEntry', '', false, false)]
    local procedure InsertFromTDSEntry(var TempRevertTransactionNo: Record Integer; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer; var TempReversalEntry: Record "Reversal Entry")
    var
        TDSEntry: Record "TDS Entry";
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
        TransactionNo: Integer;
    begin
        TempRevertTransactionNo.FINDSET();
        REPEAT
            if GLRegister.Get(TempRevertTransactionNo.Number) then begin
                GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
                if not GLEntry.FindFirst() then
                    exit
                else
                    TransactionNo := GLEntry."Transaction No.";
            end;

            IF RevType <> RevType::Transaction THEN
                exit;

            TDSEntry.SETRANGE("Transaction No.", TransactionNo);
            IF TDSEntry.FINDSET() THEN
                REPEAT
                    CLEAR(TempReversalEntry);
                    IF RevType = RevType::Register THEN
                        TempReversalEntry."G/L Register No." := Number;
                    TempReversalEntry."Reversal Type" := RevType;
                    TempReversalEntry."Posting Date" := TDSEntry."Posting Date";
                    TempReversalEntry."Source Code" := TDSEntry."Source Code";
                    TempReversalEntry."Transaction No." := TDSEntry."Transaction No.";
                    TempReversalEntry.Amount := TDSEntry."Total TDS Including SHE CESS";
                    TempReversalEntry."Amount (LCY)" := TDSEntry."Total TDS Including SHE CESS";
                    TempReversalEntry."Document Type" := TDSEntry."Document Type";
                    TempReversalEntry."Document No." := TDSEntry."Document No.";
                    TempReversalEntry."Entry No." := TDSEntry."Entry No.";
                    TempReversalEntry.Description := copystr(TDSEntry.TableCaption, 1, 50);
                    TempReversalEntry."Line No." := NextLineNo;
                    NextLineNo := NextLineNo + 1;
                    TempReversalEntry.INSERT();
                UNTIL TDSEntry.NEXT() = 0;
        UNTIL TempRevertTransactionNo.NEXT() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Reverse", 'OnReverseOnBeforeStartPosting', '', false, false)]
    local procedure ReverseTDS(var ReversalEntry: Record "Reversal Entry")
    var
        TDSEntry: Record "TDS Entry";
        NewTDSEntry: Record "TDS Entry";
        ReversedTDSEntry: Record "TDS Entry";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        CannotReverseErr: Label 'You cannot reverse the transaction, because it has already been reversed.';
    begin
        TDSEntry.SetRange("Transaction No.", ReversalEntry."Transaction No.");
        if TDSEntry.FindSet() then
            repeat
                if TDSEntry."Reversed by Entry No." <> 0 then
                    Error(CannotReverseErr);

                NewTDSEntry := TDSEntry;
                NewTDSEntry."TDS Base Amount" := -NewTDSEntry."TDS Base Amount";
                NewTDSEntry."TDS Amount" := -NewTDSEntry."TDS Amount";
                NewTDSEntry."Surcharge Base Amount" := -NewTDSEntry."Surcharge Base Amount";
                NewTDSEntry."Surcharge Amount" := -NewTDSEntry."Surcharge Amount";
                NewTDSEntry."TDS Amount Including Surcharge" := -NewTDSEntry."TDS Amount Including Surcharge";
                NewTDSEntry."eCESS Amount" := -NewTDSEntry."eCESS Amount";
                NewTDSEntry."SHE Cess Amount" := -NewTDSEntry."SHE Cess Amount";
                NewTDSEntry."Total TDS Including SHE CESS" := -NewTDSEntry."Total TDS Including SHE CESS";
                NewTDSEntry."Bal. TDS Including SHE CESS" := -NewTDSEntry."Bal. TDS Including SHE CESS";
                NewTDSEntry."Invoice Amount" := -NewTDSEntry."Invoice Amount";
                NewTDSEntry."Remaining TDS Amount" := -NewTDSEntry."Remaining TDS Amount";
                NewTDSEntry."Remaining Surcharge Amount" := -NewTDSEntry."Remaining Surcharge Amount";
                NewTDSEntry."TDS Line Amount" := -NewTDSEntry."TDS Line Amount";
                NewTDSEntry."Work Tax Base Amount" := -NewTDSEntry."Work Tax Base Amount";
                NewTDSEntry."Work Tax Amount" := -NewTDSEntry."Work Tax Amount";
                NewTDSEntry."Balance Work Tax Amount" := -NewTDSEntry."Balance Work Tax Amount";
                NewTDSEntry."Entry No." := GetNextTDSEntryNo();
                NewTDSEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo();
                NewTDSEntry."Source Code" := NewTDSEntry."Source Code";
                NewTDSEntry."User ID" := Copystr(UserId, 1, 50);
                NewTDSEntry."Reversed Entry No." := TDSEntry."Entry No.";
                NewTDSEntry.Reversed := TRUE;
                if TDSEntry."Reversed Entry No." <> 0 then begin
                    ReversedTDSEntry.GET(TDSEntry."Reversed Entry No.");
                    ReversedTDSEntry."Reversed by Entry No." := 0;
                    ReversedTDSEntry.Reversed := FALSE;
                    ReversedTDSEntry.Modify();
                    TDSEntry."Reversed Entry No." := NewTDSEntry."Entry No.";
                    NewTDSEntry."Reversed by Entry No." := TDSEntry."Entry No.";
                end;
                TDSEntry."Reversed by Entry No." := NewTDSEntry."Entry No.";
                TDSEntry.Reversed := TRUE;
                TDSEntry.Modify();
                NewTDSEntry.Insert();
            until TDSEntry.Next() = 0;
    end;

    local procedure GetNextTDSEntryNo(): Integer
    var
        TDSEntry: Record "TDS Entry";
        LineNo: Integer;
    begin
        if TDSEntry.FindLast() then
            LineNo := TDSEntry."Entry No." + 1
        else
            LineNo := 1;
        exit(LineNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Check Line", 'OnAfterCheckGenJnlLine', '', false, false)]
    local procedure PayTDSEntry(var GenJournalLine: Record "Gen. Journal Line")
    var
        TDSEntry: Record "TDS Entry";
    begin
        IF GenJournalLine."Pay TDS" THEN BEGIN
            TDSEntry.SETCURRENTKEY("Pay TDS Document No.");
            TDSEntry.SETRANGE("Pay TDS Document No.", GenJournalLine."Document No.");
            IF TDSEntry.FindSet() THEN
                REPEAT
                    TDSEntry."TDS Payment Date" := GenJournalLine."Posting Date";
                    TDSEntry."TDS Paid" := TRUE;
                    TDSEntry.MODIFY();
                UNTIL TDSEntry.NEXT() = 0;
        END ELSE
            IF GenJournalLine."Pay Work Tax" THEN begin
                TDSEntry.SETCURRENTKEY("Pay Work Tax Document No.");
                TDSEntry.SETRANGE("Pay Work Tax Document No.", GenJournalLine."Document No.");
                IF TDSEntry.FindSet() THEN
                    REPEAT
                        TDSEntry."Work Tax Paid" := TRUE;
                        TDSEntry.MODIFY();
                    UNTIL TDSEntry.NEXT() = 0;
            end;
    end;
}