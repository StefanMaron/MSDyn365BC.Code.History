codeunit 12404 "G/L Corresp. Management"
{
    Permissions = TableData "G/L Entry" = rimd,
                  TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd,
                  TableData "Item Ledger Entry" = rimd,
                  TableData "Job Ledger Entry" = rimd,
                  TableData "Res. Ledger Entry" = rimd,
                  TableData "VAT Entry" = rimd,
                  TableData "Bank Account Ledger Entry" = rimd,
                  TableData "Check Ledger Entry" = rimd,
                  TableData "FA Ledger Entry" = rimd,
                  TableData "Value Entry" = rimd,
                  TableData "Service Ledger Entry" = rimd,
                  TableData "Warranty Ledger Entry" = rimd,
                  TableData "G/L Correspondence Entry" = rimd,
                  TableData "VAT Ledger" = rimd,
                  TableData "VAT Ledger Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'Transaction No. #1#######';
        TempGLEntry: Record "G/L Entry" temporary;

    [Scope('OnPrem')]
    procedure CreateCorrespEntries(var GLEntry: Record "G/L Entry")
    var
        UpdateGLCorrAnalysisView: Codeunit "Update G/L Corr. Analysis View";
        WindowDialog: Dialog;
        TransNo: Integer;
        ShowDialog: Boolean;
    begin
        ShowDialog := GLEntry.GetFilter("Entry No.") = '';
        if ShowDialog then
            WindowDialog.Open(Text001);
        TransNo := 0;

        GLEntry.LockTable;
        if GLEntry.FindSet then begin
            repeat
                if TransNo <> GLEntry."Transaction No." then begin
                    ClearBuffer(GLEntry."Transaction No.");
                    if ShowDialog then
                        WindowDialog.Update(1, GLEntry."Transaction No.");
                    if TransNo > 0 then
                        ProcessTransaction;
                    TempGLEntry.Reset;
                    TempGLEntry.DeleteAll;
                    TransNo := GLEntry."Transaction No.";
                end;
                TempGLEntry.TransferFields(GLEntry);
                TempGLEntry."Used in Correspondence" := false;
                TempGLEntry.Insert;
            until GLEntry.Next = 0;
            ClearBuffer(TransNo);
            ProcessTransaction;
            UpdateGLCorrAnalysisView.UpdateAll(true);
        end;
        if ShowDialog then
            WindowDialog.Close;
    end;

    local procedure ProcessTransaction()
    var
        CurrentTempGLEntry: Record "G/L Entry" temporary;
        Level: Integer;
        MaxLevel: Integer;
        FoundEntry: Boolean;
    begin
        MaxLevel := 3;

        if IsReversedGLReg(TempGLEntry) then
            TempGLEntry.Ascending(false);

        with TempGLEntry do begin
            for Level := 1 to MaxLevel do
                if Find('-') then
                    repeat
                        if (Amount = 0) and ("Additional-Currency Amount" = 0) then
                            Delete
                        else begin
                            CurrentTempGLEntry := TempGLEntry;
                            FoundEntry := false;
                            SetFilter("Entry No.", '<>%1', CurrentTempGLEntry."Entry No.");
                            if Find('-') then
                                repeat
                                    if (not CurrentTempGLEntry."Used in Correspondence") or
                                       (not "Used in Correspondence")
                                    then
                                        if ValidateEntries(CurrentTempGLEntry, TempGLEntry, Level) then begin
                                            FoundEntry := true;
                                            InsertCorrespEntry(CurrentTempGLEntry, TempGLEntry);
                                            if (Amount = 0) and ("Additional-Currency Amount" = 0) then
                                                Delete
                                            else
                                                Modify;
                                        end;
                                until FoundEntry or (Next = 0);
                            if FoundEntry and (Level = MaxLevel) then
                                Level -= 1;
                            TempGLEntry := CurrentTempGLEntry;
                            if (Amount = 0) and ("Additional-Currency Amount" = 0) then
                                Delete
                            else
                                Modify;
                        end;
                    until Next = 0;

            Reset;
            if Find('-') then
                repeat
                    UpdateBuffer("Entry No.", Amount);
                until Next = 0;
        end;
    end;

    local procedure InsertCorrespEntry(var GLEntry1: Record "G/L Entry" temporary; var GLEntry2: Record "G/L Entry" temporary)
    var
        GLAcc: Record "G/L Account";
        GLCorresp: Record "G/L Correspondence";
        DebitEntry: Record "G/L Entry";
        CreditEntry: Record "G/L Entry";
        GLCorrespEntry: Record "G/L Correspondence Entry";
        CorrAmount: Decimal;
        AmountACY: Decimal;
        Sign: Integer;
        GLCorrespEntryNo: Integer;
    begin
        Sign := SignEntry(GLEntry1, true);
        AmountACY := Sign * Min(Abs(GLEntry1."Additional-Currency Amount"), Abs(GLEntry2."Additional-Currency Amount"));
        Sign := SignEntry(GLEntry1, false);
        CorrAmount := Sign * Min(Abs(GLEntry1.Amount), Abs(GLEntry2.Amount));

        if Debit(GLEntry1) then begin
            DebitEntry.TransferFields(GLEntry1);
            CreditEntry.TransferFields(GLEntry2);
            GLEntry1.Amount := GLEntry1.Amount - CorrAmount;
            GLEntry1."Additional-Currency Amount" := GLEntry1."Additional-Currency Amount" - AmountACY;
            GLEntry2.Amount := GLEntry2.Amount + CorrAmount;
            GLEntry2."Additional-Currency Amount" := GLEntry2."Additional-Currency Amount" + AmountACY;
        end else begin
            DebitEntry.TransferFields(GLEntry2);
            CreditEntry.TransferFields(GLEntry1);
            GLEntry1.Amount := GLEntry1.Amount + CorrAmount;
            GLEntry1."Additional-Currency Amount" := GLEntry1."Additional-Currency Amount" + AmountACY;
            GLEntry2.Amount := GLEntry2.Amount - CorrAmount;
            GLEntry2."Additional-Currency Amount" := GLEntry2."Additional-Currency Amount" - AmountACY;
        end;

        if (not GLEntry1."Used in Correspondence") and (not GLEntry2."Used in Correspondence") then
            if Abs(GLEntry1.Amount) < Abs(GLEntry2.Amount) then begin
                GLEntry1."Used in Correspondence" := true;
                GLCorrespEntryNo := GLEntry1."Entry No.";
            end else begin
                GLEntry2."Used in Correspondence" := true;
                GLCorrespEntryNo := GLEntry2."Entry No.";
            end
        else
            if not GLEntry1."Used in Correspondence" then begin
                GLEntry1."Used in Correspondence" := true;
                GLCorrespEntryNo := GLEntry1."Entry No.";
            end else begin
                GLEntry2."Used in Correspondence" := true;
                GLCorrespEntryNo := GLEntry2."Entry No.";
            end;

        if not GLCorresp.Get(DebitEntry."G/L Account No.", CreditEntry."G/L Account No.") then begin
            GLCorresp.Init;
            GLCorresp."Debit Account No." := DebitEntry."G/L Account No.";
            GLAcc.Get(DebitEntry."G/L Account No.");
            GLCorresp."Debit Account Name" := GLAcc.Name;
            GLCorresp."Credit Account No." := CreditEntry."G/L Account No.";
            GLAcc.Get(CreditEntry."G/L Account No.");
            GLCorresp."Credit Account Name" := GLAcc.Name;
            GLCorresp.Insert;
        end;

        with GLCorrespEntry do begin
            Init;
            "Entry No." := GLCorrespEntryNo;
            "Document No." := GLEntry1."Document No.";
            "Posting Date" := GLEntry1."Posting Date";
            "Debit Account No." := DebitEntry."G/L Account No.";
            "Credit Account No." := CreditEntry."G/L Account No.";
            Amount := CorrAmount;
            "Amount (ACY)" := AmountACY;
            "User ID" := DebitEntry."User ID";
            "Transaction No." := GLEntry1."Transaction No.";
            "Business Unit Code" := GLEntry1."Business Unit Code";
            "Debit Global Dimension 1 Code" := DebitEntry."Global Dimension 1 Code";
            "Debit Global Dimension 2 Code" := DebitEntry."Global Dimension 2 Code";
            "Debit Dimension Set ID" := DebitEntry."Dimension Set ID";
            "Debit Source Type" := DebitEntry."Source Type";
            "Debit Source No." := DebitEntry."Source No.";
            "Credit Global Dimension 1 Code" := CreditEntry."Global Dimension 1 Code";
            "Credit Global Dimension 2 Code" := CreditEntry."Global Dimension 2 Code";
            "Credit Dimension Set ID" := CreditEntry."Dimension Set ID";
            "Credit Source Type" := CreditEntry."Source Type";
            "Credit Source No." := CreditEntry."Source No.";
            Positive := Sign = 1;
            "Creation Date" := Today;
            "Debit Entry No." := DebitEntry."Entry No.";
            "Credit Entry No." := CreditEntry."Entry No.";
            Insert(true);
        end;
    end;

    local procedure ValidateEntries(var GLEntry1: Record "G/L Entry"; var GLEntry2: Record "G/L Entry"; CurrentAttempt: Integer): Boolean
    var
        SameDebit: Boolean;
        SameSign: Boolean;
    begin
        SameDebit := Debit(GLEntry1) = Debit(GLEntry2);
        SameSign := SignEntry(GLEntry1, false) = SignEntry(GLEntry2, false);
        if SameDebit = SameSign then
            exit(false);

        case CurrentAttempt of
            1:
                begin
                    if Reverse(GLEntry1) <> Reverse(GLEntry2) then
                        exit(false);
                    if (GLEntry1."Bal. Account Type" <> GLEntry1."Bal. Account Type"::"G/L Account") or
                       (GLEntry2."Bal. Account Type" <> GLEntry2."Bal. Account Type"::"G/L Account")
                    then
                        exit(false);
                    if (GLEntry1."Bal. Account No." = '') or (GLEntry1."Bal. Account No." <> GLEntry2."G/L Account No.") or
                       (GLEntry2."Bal. Account No." = '') or (GLEntry2."Bal. Account No." <> GLEntry1."G/L Account No.")
                    then
                        exit(false);
                end;
            2:
                if (GLEntry1."Bal. Account No." = '') and (GLEntry2."Bal. Account No." = '') and
                   (GLEntry1."G/L Account No." = GLEntry2."G/L Account No.")
                then
                    exit(false);
        end;

        exit(true);
    end;

    local procedure SignEntry(GLentry: Record "G/L Entry"; ACY: Boolean): Integer
    begin
        case ACY of
            false:
                if (GLentry."Debit Amount" > 0) or (GLentry."Credit Amount" > 0) then
                    exit(1);
            true:
                if (GLentry."Add.-Currency Debit Amount" > 0) or (GLentry."Add.-Currency Credit Amount" > 0) then
                    exit(1);
        end;
        exit(-1);
    end;

    local procedure Reverse(GLEntry: Record "G/L Entry"): Boolean
    begin
        exit((GLEntry."Debit Amount" < 0) or (GLEntry."Credit Amount" < 0) or
          (GLEntry."Add.-Currency Debit Amount" < 0) or (GLEntry."Add.-Currency Credit Amount" < 0));
    end;

    local procedure Debit(GLEntry: Record "G/L Entry"): Boolean
    begin
        if GLEntry.Amount <> 0 then
            exit(GLEntry."Debit Amount" <> 0);
        exit(GLEntry."Add.-Currency Debit Amount" <> 0);
    end;

    local procedure "Min"(Value1: Decimal; Value2: Decimal): Decimal
    begin
        if Value1 < Value2 then
            exit(Value1);

        exit(Value2);
    end;

    local procedure UpdateBuffer(EntryNo: Integer; CorAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        DoubleEntryBuffer: Record "G/L Corresp. Posting Buffer";
    begin
        with DoubleEntryBuffer do begin
            Init;
            GLEntry.Get(EntryNo);
            if Get(GLEntry."Transaction No.", GLEntry."G/L Account No.") then begin
                "G/L Amount" += GLEntry.Amount;
                "G/L Corresp. Amount" += CorAmount;
                if "G/L Corresp. Amount" = 0 then
                    Delete
                else
                    Modify;
            end else begin
                "Transaction No." := GLEntry."Transaction No.";
                "G/L Account No." := GLEntry."G/L Account No.";
                "G/L Amount" := GLEntry.Amount;
                "G/L Corresp. Amount" := CorAmount;
                if "G/L Corresp. Amount" <> 0 then
                    Insert;
            end;
        end;
    end;

    local procedure ClearBuffer(TransactionNo: Integer)
    var
        DoubleEntryBuffer: Record "G/L Corresp. Posting Buffer";
    begin
        DoubleEntryBuffer.Reset;
        DoubleEntryBuffer.SetRange("Transaction No.", TransactionNo);
        DoubleEntryBuffer.DeleteAll;
    end;

    [Scope('OnPrem')]
    procedure SetTransactionNo(GLEntry: Record "G/L Entry")
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldCustLedgEntry.Reset;
        DtldCustLedgEntry.SetCurrentKey(
          "Customer No.", "Posting Date", "Entry Type");
        DtldCustLedgEntry.SetRange("Customer No.", GLEntry."Source No.");
        DtldCustLedgEntry.SetRange("Document No.", GLEntry."Document No.");
        DtldCustLedgEntry.SetRange("Posting Date", GLEntry."Posting Date");
        DtldCustLedgEntry.SetRange("Source Code", GLEntry."Source Code");
        DtldCustLedgEntry.SetRange(
          "Entry Type",
          DtldCustLedgEntry."Entry Type"::"Unrealized Loss",
          DtldCustLedgEntry."Entry Type"::"Unrealized Gain");
        DtldCustLedgEntry.SetRange("Transaction No.", 0);
        DtldCustLedgEntry.ModifyAll("Transaction No.", GLEntry."Transaction No.");

        DtldVendLedgEntry.Reset;
        DtldVendLedgEntry.SetCurrentKey(
          "Vendor No.", "Posting Date", "Entry Type");
        DtldVendLedgEntry.SetRange("Vendor No.", GLEntry."Source No.");
        DtldVendLedgEntry.SetRange("Document No.", GLEntry."Document No.");
        DtldVendLedgEntry.SetRange("Posting Date", GLEntry."Posting Date");
        DtldVendLedgEntry.SetRange("Source Code", GLEntry."Source Code");
        DtldVendLedgEntry.SetRange(
          "Entry Type",
          DtldVendLedgEntry."Entry Type"::"Unrealized Loss",
          DtldVendLedgEntry."Entry Type"::"Unrealized Gain");
        DtldVendLedgEntry.SetRange("Transaction No.", 0);
        DtldVendLedgEntry.ModifyAll("Transaction No.", GLEntry."Transaction No.");
    end;

    local procedure IsReversedGLReg(GLEntry: Record "G/L Entry"): Boolean
    var
        GLRegister: Record "G/L Register";
    begin
        GLRegister.SetFilter("From Entry No.", '..%1', GLEntry."Entry No.");
        GLRegister.SetFilter("To Entry No.", '%1..', GLEntry."Entry No.");
        GLRegister.SetRange(Reversed, true);
        exit(not GLRegister.IsEmpty);
    end;
}

