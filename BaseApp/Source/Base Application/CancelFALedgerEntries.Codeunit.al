codeunit 5624 "Cancel FA Ledger Entries"
{

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'must be the same in all canceled ledger entries';
        Text002: Label '%1 = %2 has already been canceled.';
        Text003: Label 'The ledger entries have been transferred to the journal.';
        Text004: Label '%1 = %2 cannot be canceled. Use %3 = %4.';
        FAJnlSetup: Record "FA Journal Setup";
        DeprBook: Record "Depreciation Book";
        GenJnlLine: Record "Gen. Journal Line";
        FAJnlLine: Record "FA Journal Line";
        FA: Record "Fixed Asset";
        GLIntegration: array[9] of Boolean;
        FAJnlNextLineNo: Integer;
        GenJnlNextLineNo: Integer;
        DeprBookCode: Code[10];
        GenJnlUsedOnce: Boolean;
        FAJnlUsedOnce: Boolean;
        FAJnlDocumentNo: Code[20];
        GenJnlDocumentNo: Code[20];

    procedure TransferLine(var FALedgEntry: Record "FA Ledger Entry"; BalAccount: Boolean; NewPostingDate: Date)
    begin
        ClearAll;
        with FALedgEntry do begin
            if Find('+') then
                repeat
                    if DeprBookCode = '' then
                        DeprBookCode := "Depreciation Book Code";
                    if DeprBookCode <> "Depreciation Book Code" then
                        FieldError("Depreciation Book Code", Text001);
                    if "FA No." = '' then
                        Error(Text002, FieldCaption("Entry No."), "Entry No.");
                    FA.Get("FA No.");
                    DeprBook.Get("Depreciation Book Code");
                    DeprBook.IndexGLIntegration(GLIntegration);
                    CheckType(FALedgEntry);
                    if NewPostingDate > 0D then begin
                        "Posting Date" := NewPostingDate;
                        DeprBook.TestField("Use Same FA+G/L Posting Dates", false);
                    end;
                    if GLIntegration[ConvertPostingType + 1] and not FA."Budgeted Asset" then
                        InsertGenJnlLine(FALedgEntry, BalAccount)
                    else
                        InsertFAJnlLine(FALedgEntry);
                until Next(-1) = 0;
        end;
        Message(Text003);
    end;

    local procedure CheckType(var FALedgEntry: Record "FA Ledger Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckType(FALedgEntry, IsHandled);
        if IsHandled then
            exit;

        with FALedgEntry do
            if ("FA Posting Type" > "FA Posting Type"::"Salvage Value") or
               ("FA Posting Category" <> "FA Posting Category"::" ")
            then begin
                "FA Posting Type" := "FA Posting Type"::"Proceeds on Disposal";
                Error(
                  Text004,
                  FieldCaption("Entry No."), "Entry No.", FieldCaption("FA Posting Type"), "FA Posting Type");
            end;
    end;

    local procedure InsertFAJnlLine(var FALedgEntry: Record "FA Ledger Entry")
    begin
        if not FAJnlUsedOnce then begin
            ;
            FAJnlLine.LockTable();
            FAJnlSetup.FAJnlName(DeprBook, FAJnlLine, FAJnlNextLineNo);
            FAJnlUsedOnce := true;
            FAJnlDocumentNo :=
              FAJnlSetup.GetFAJnlDocumentNo(FAJnlLine, FALedgEntry."FA Posting Date", false);
        end;

        FALedgEntry.MoveToFAJnl(FAJnlLine);
        with FAJnlLine do begin
            "Document No." := FAJnlDocumentNo;
            "Document Type" := "Document Type"::" ";
            "External Document No." := '';
            "Shortcut Dimension 1 Code" := FALedgEntry."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := FALedgEntry."Global Dimension 2 Code";
            "Dimension Set ID" := FALedgEntry."Dimension Set ID";
            "FA Error Entry No." := FALedgEntry."Entry No.";
            "Posting No. Series" := FAJnlSetup.GetFANoSeries(FAJnlLine);
            Validate(Amount, -Amount);
            Validate(Correction, DeprBook."Mark Errors as Corrections");
            "Line No." := "Line No." + 10000;
            OnBeforeFAJnlLineInsert(FAJnlLine, FALedgEntry);
            Insert(true);
        end;

        OnAfterInsertFAJnlLine(FAJnlLine, FALedgEntry);
    end;

    local procedure InsertGenJnlLine(var FALedgEntry: Record "FA Ledger Entry"; BalAccount: Boolean)
    var
        FAInsertGLAcc: Codeunit "FA Insert G/L Account";
    begin
        if not GenJnlUsedOnce then begin
            ;
            GenJnlLine.LockTable();
            FAJnlSetup.GenJnlName(DeprBook, GenJnlLine, GenJnlNextLineNo);
            GenJnlUsedOnce := true;
            GenJnlDocumentNo :=
              FAJnlSetup.GetGenJnlDocumentNo(GenJnlLine, FALedgEntry."FA Posting Date", false);
        end;

        FALedgEntry.MoveToGenJnl(GenJnlLine);
        with GenJnlLine do begin
            "Document No." := GenJnlDocumentNo;
            "Document Type" := "Document Type"::" ";
            "External Document No." := '';
            "Shortcut Dimension 1 Code" := FALedgEntry."Global Dimension 1 Code";
            "Shortcut Dimension 2 Code" := FALedgEntry."Global Dimension 2 Code";
            "Dimension Set ID" := FALedgEntry."Dimension Set ID";
            "FA Error Entry No." := FALedgEntry."Entry No.";
            Validate(Amount, -Amount);
            Validate(Correction, DeprBook."Mark Errors as Corrections");
            "Posting No. Series" := FAJnlSetup.GetGenNoSeries(GenJnlLine);
            "Line No." := "Line No." + 10000;
            // NAVCZ
            "Reason Code" := FALedgEntry."Reason Code";
            // NAVCZ
            OnBeforeGenJnlLineInsert(GenJnlLine, FALedgEntry, BalAccount);
            Insert(true);
            if BalAccount then
                FAInsertGLAcc.GetBalAcc(GenJnlLine);
        end;

        OnAfterInsertGenJnlLine(GenJnlLine, FALedgEntry, BalAccount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertFAJnlLine(var FAJournalLine: Record "FA Journal Line"; var FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var FALedgerEntry: Record "FA Ledger Entry"; BalAccount: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckType(FALedgerEntry: Record "FA Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFAJnlLineInsert(var FAJournalLine: Record "FA Journal Line"; FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line"; FALedgerEntry: Record "FA Ledger Entry"; BalAccount: Boolean)
    begin
    end;
}

