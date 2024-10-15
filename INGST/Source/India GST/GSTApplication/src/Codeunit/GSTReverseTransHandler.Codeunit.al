codeunit 18436 "GST Reverse Trans. Handler"
{
    var
        ReverseDGSTErr: Label 'You cannot reverse the Transaction as GST Adjustment Type is Credit Reversal/Permanent Reversal.';

    local procedure ReverseGST(var GSTLedgerEntry: Record "GST Ledger Entry"; NextTransactionNo: Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
        GSTLedgerEntry2: Record "GST Ledger Entry";
        NewGSTLedgerEntry: Record "GST Ledger Entry";
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        SourceCodeSetup.Get();

        if GSTLedgerEntry.FindSet() then begin
            DetailedGSTLedgerEntry.SetCurrentKey("Transaction No.");
            DetailedGSTLedgerEntry.SetRange("Transaction No.", GSTLedgerEntry."Transaction No.");
            ReverseDetailedGST(DetailedGSTLedgerEntry, NextTransactionNo);
            repeat
                NewGSTLedgerEntry.Init();
                NewGSTLedgerEntry.TransferFields(GSTLedgerEntry);
                NewGSTLedgerEntry."Reversed Entry No." := GSTLedgerEntry."Entry No.";
                NewGSTLedgerEntry."Transaction No." := NextTransactionNo;
                NewGSTLedgerEntry."GST Base Amount" := -NewGSTLedgerEntry."GST Base Amount";
                NewGSTLedgerEntry."GST Amount" := -NewGSTLedgerEntry."GST Amount";
                NewGSTLedgerEntry."Source Code" := SourceCodeSetup.Reversal;
                NewGSTLedgerEntry.Reversed := true;
                NewGSTLedgerEntry.Insert();

                GSTLedgerEntry2.Reset();
                GSTLedgerEntry2.SetRange("Entry No.", GSTLedgerEntry."Entry No.");
                GSTLedgerEntry2.FindFirst();
                GSTLedgerEntry2."Reversed by Entry No." := NewGSTLedgerEntry."Entry No.";
                GSTLedgerEntry2.Reversed := true;
                GSTLedgerEntry2.Modify();
            until GSTLedgerEntry.Next() = 0;
        end;
    end;

    local procedure ReverseDetailedGST(
        var DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        NextTransactionNo: Integer)
    var
        DetailedGSTLedgerEntry2: Record "Detailed GST Ledger Entry";
        NewDetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
    begin
        if DetailedGSTLedgerEntry.FindSet() then
            repeat
                DetailedGSTLedgerEntry.TestField(Paid, false);
                if DetailedGSTLedgerEntry."Credit Adjustment Type" in [
                    DetailedGSTLedgerEntry."Credit Adjustment Type"::"Credit Reversal",
                    DetailedGSTLedgerEntry."Credit Adjustment Type"::"Permanent Reversal"]
                then
                    Error(ReverseDGSTErr);
                DetailedGSTLedgerEntry.TestField("Adv. Pmt. Adjustment", false);

                NewDetailedGSTLedgerEntry.Init();
                NewDetailedGSTLedgerEntry.TransferFields(DetailedGSTLedgerEntry);
                NewDetailedGSTLedgerEntry."Reversed Entry No." := DetailedGSTLedgerEntry."Entry No.";
                NewDetailedGSTLedgerEntry."Transaction No." := NextTransactionNo;
                NewDetailedGSTLedgerEntry."Entry Type" := NewDetailedGSTLedgerEntry."Entry Type"::Application;
                NewDetailedGSTLedgerEntry."GST Base Amount" := -NewDetailedGSTLedgerEntry."GST Base Amount";
                NewDetailedGSTLedgerEntry."GST Amount" := -NewDetailedGSTLedgerEntry."GST Amount";
                NewDetailedGSTLedgerEntry."Remaining Base Amount" := -NewDetailedGSTLedgerEntry."Remaining Base Amount";
                NewDetailedGSTLedgerEntry."Remaining GST Amount" := -NewDetailedGSTLedgerEntry."Remaining GST Amount";
                NewDetailedGSTLedgerEntry."Amount Loaded on Item" := -NewDetailedGSTLedgerEntry."Amount Loaded on Item";
                NewDetailedGSTLedgerEntry.Quantity := -NewDetailedGSTLedgerEntry.Quantity;
                NewDetailedGSTLedgerEntry.Reversed := true;
                if NewDetailedGSTLedgerEntry.Positive then
                    NewDetailedGSTLedgerEntry.Positive := false
                else
                    NewDetailedGSTLedgerEntry.Positive := true;
                NewDetailedGSTLedgerEntry.Insert();

                DetailedGSTLedgerEntry2.Reset();
                DetailedGSTLedgerEntry2.SetRange("Entry No.", DetailedGSTLedgerEntry."Entry No.");
                DetailedGSTLedgerEntry2.FindFirst();
                DetailedGSTLedgerEntry2."Reversed by Entry No." := NewDetailedGSTLedgerEntry."Entry No.";
                DetailedGSTLedgerEntry2.Reversed := true;
                DetailedGSTLedgerEntry2.Modify();
            until DetailedGSTLedgerEntry.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Reverse", 'OnReverseOnBeforeStartPosting', '', false, false)]
    local procedure GenJnlPostReverseOnReverseOnBeforeStartPosting(
        var GenJournalLine: Record "Gen. Journal Line";
        var ReversalEntry: Record "Reversal Entry");
    var
        GSTReverseTransSessionMgt: Codeunit "GST Reverse Trans. Session Mgt";
    begin
        GSTReverseTransSessionMgt.SetReversalEntry(ReversalEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Reverse", 'OnAfterPostReverse', '', false, false)]
    local procedure GenJnlPostReverseOnAfterPostReverse(var GenJournalLine: Record "Gen. Journal Line")
    var
        TempReversalEntry: Record "Reversal Entry" temporary;
        GSTLedgerEntry: Record "GST Ledger Entry";
        GSTReverseTransSessionMgt: Codeunit "GST Reverse Trans. Session Mgt";
        NextTransactionNo: Integer;
    begin
        GSTReverseTransSessionMgt.GetReversalEntry(TempReversalEntry, NextTransactionNo);
        TempReversalEntry.Reset();
        if TempReversalEntry.FindSet() then
            repeat
                if TempReversalEntry."Reversal Type" = TempReversalEntry."Reversal Type"::Transaction then begin
                    GSTLedgerEntry.Reset();
                    GSTLedgerEntry.SetRange("Transaction No.", TempReversalEntry."Transaction No.");
                    if GSTLedgerEntry.FindSet() then
                        ReverseGST(GSTLedgerEntry, NextTransactionNo);
                end;
            until TempReversalEntry.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnContinuePostingOnBeforeCalculateCurrentBalance', '', false, false)]
    local procedure OnContinuePostingOnBeforeCalculateCurrentBalance(
        var GenJournalLine: Record "Gen. Journal Line";
        var NextTransactionNo: Integer)
    var
        GSTReverseTransSessionMgt: Codeunit "GST Reverse Trans. Session Mgt";
    begin
        GSTReverseTransSessionMgt.SetReversalNextTransactionNo(NextTransactionNo);
    end;
}