codeunit 17 "Gen. Jnl.-Post Reverse"
{
    Permissions = TableData "G/L Entry" = rm,
                  TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd,
                  TableData "G/L Register" = rm,
                  TableData "G/L Entry - VAT Entry Link" = rimd,
                  TableData "VAT Entry" = rimd,
                  TableData "Bank Account Ledger Entry" = rimd,
                  TableData "Check Ledger Entry" = rimd,
                  TableData "Detailed Cust. Ledg. Entry" = rimd,
                  TableData "Detailed Vendor Ledg. Entry" = rimd,
                  TableData "Employee Ledger Entry" = rimd,
                  TableData "Detailed Employee Ledger Entry" = ri;
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
    end;

    var
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
        ReversalMismatchErr: Label 'Reversal found a %1 without a matching general ledger entry.';
        CannotReverseErr: Label 'You cannot reverse the transaction, because it has already been reversed.';
        DimCombBlockedErr: Label 'The combination of dimensions used in general ledger entry %1 is blocked. %2.';

    procedure Reverse(var ReversalEntry: Record "Reversal Entry"; var ReversalEntry2: Record "Reversal Entry")
    var
        SourceCodeSetup: Record "Source Code Setup";
        GLEntry2: Record "G/L Entry";
        GLReg: Record "G/L Register";
        GLReg2: Record "G/L Register";
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        VendLedgEntry: Record "Vendor Ledger Entry";
        TempVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        TempEmployeeLedgerEntry: Record "Employee Ledger Entry" temporary;
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        TempBankAccLedgEntry: Record "Bank Account Ledger Entry" temporary;
        VATEntry: Record "VAT Entry";
        FALedgEntry: Record "FA Ledger Entry";
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        TempRevertTransactionNo: Record "Integer" temporary;
        FAInsertLedgEntry: Codeunit "FA Insert Ledger Entry";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        NextDtldCustLedgEntryEntryNo: Integer;
        NextDtldVendLedgEntryEntryNo: Integer;
        NextDtldEmplLedgEntryNo: Integer;
        TransactionKey: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReverse(ReversalEntry, ReversalEntry2, IsHandled);
        if IsHandled then
            exit;

        SourceCodeSetup.Get();
        if ReversalEntry2."Reversal Type" = ReversalEntry2."Reversal Type"::Register then
            GLReg2."No." := ReversalEntry2."G/L Register No.";

        ReversalEntry.CopyReverseFilters(
          GLEntry2, CustLedgEntry, VendLedgEntry, BankAccLedgEntry, VATEntry, FALedgEntry, MaintenanceLedgEntry, EmployeeLedgerEntry);

        if ReversalEntry2."Reversal Type" = ReversalEntry2."Reversal Type"::Transaction then begin
            GLReg2."No." := GetRegisterNoForTransactionReversal(ReversalEntry2);
            if ReversalEntry2.FindSet(false, false) then
                repeat
                    TempRevertTransactionNo.Number := ReversalEntry2."Transaction No.";
                    if TempRevertTransactionNo.Insert() then;
                until ReversalEntry2.Next() = 0;
        end;

        OnReverseOnBeforeGetTransactionKey(ReversalEntry2, TempRevertTransactionNo);
        TransactionKey := GetTransactionKey();
        SaveReversalEntries(ReversalEntry2, TransactionKey);

        GenJnlLine.Init();
        GenJnlLine."Source Code" := SourceCodeSetup.Reversal;
        GenJnlLine."Journal Template Name" := GLEntry2."Journal Templ. Name";

        OnReverseOnBeforeStartPosting(GenJnlLine, ReversalEntry2, GLEntry2, GenJnlPostLine);

        if GenJnlPostLine.GetNextEntryNo() = 0 then
            GenJnlPostLine.StartPosting(GenJnlLine)
        else
            GenJnlPostLine.ContinuePosting(GenJnlLine);

#if not CLEAN23
        OnAfterPostReverse(GenJnlLine);
#endif
        OnReverseOnAfterStartPosting(GenJnlLine, GenJnlPostLine, GLReg, GLReg2);

        GenJnlPostLine.SetGLRegReverse(GLReg);

        CopyCustLedgEntry(CustLedgEntry, TempCustLedgEntry);
        CopyVendLedgEntry(VendLedgEntry, TempVendLedgEntry);
        CopyEmplLedgEntry(EmployeeLedgerEntry, TempEmployeeLedgerEntry);
        CopyBankAccLedgEntry(BankAccLedgEntry, TempBankAccLedgEntry);

        if TempRevertTransactionNo.FindSet() then;
        repeat
            if ReversalEntry2."Reversal Type" = ReversalEntry2."Reversal Type"::Transaction then
                GLEntry2.SetRange("Transaction No.", TempRevertTransactionNo.Number);
            OnReverseOnBeforeReverseGLEntry(ReversalEntry2, GenJnlPostLine, GenJnlLine, TempRevertTransactionNo, GLEntry2, GLReg);
            ReverseGLEntry(
              GLEntry2, GenJnlLine, TempCustLedgEntry,
              TempVendLedgEntry, TempEmployeeLedgerEntry, TempBankAccLedgEntry, NextDtldCustLedgEntryEntryNo, NextDtldVendLedgEntryEntryNo,
              NextDtldEmplLedgEntryNo, FAInsertLedgEntry);
        until TempRevertTransactionNo.Next() = 0;

        IsHandled := false;
        OnReverseOnBeforeCheckFAReverseEntry(FALedgEntry, FAInsertLedgEntry, ReversalEntry2, GenJnlPostLine, IsHandled);
        if not IsHandled then
            if FALedgEntry.FindSet() then
                repeat
                    FAInsertLedgEntry.CheckFAReverseEntry(FALedgEntry)
                until FALedgEntry.Next() = 0;

        if MaintenanceLedgEntry.FindFirst() then
            repeat
                FAInsertLedgEntry.CheckMaintReverseEntry(MaintenanceLedgEntry)
            until FALedgEntry.Next() = 0;

        FAInsertLedgEntry.FinishFAReverseEntry(GLReg);

        if not TempCustLedgEntry.IsEmpty() then
            Error(ReversalMismatchErr, CustLedgEntry.TableCaption());
        if not TempVendLedgEntry.IsEmpty() then
            Error(ReversalMismatchErr, VendLedgEntry.TableCaption());
        if not TempEmployeeLedgerEntry.IsEmpty() then
            Error(ReversalMismatchErr, EmployeeLedgerEntry.TableCaption());
        if not TempBankAccLedgEntry.IsEmpty() then
            Error(ReversalMismatchErr, BankAccLedgEntry.TableCaption());

        OnReverseOnBeforeFinishPosting(ReversalEntry, ReversalEntry2, GenJnlPostLine, GLReg);

        GenJnlPostLine.FinishPosting(GenJnlLine);

        OnReverseOnAfterFinishPosting(ReversalEntry2, GenJnlPostLine, GLReg, GLReg2);

        if GLReg2."No." <> 0 then
            if GLReg2.Find() then begin
                GLReg2.Reversed := true;
                GLReg2.Modify();
            end;

        DeleteReversalEntries(TransactionKey);

        IsHandled := false;
        OnReverseOnBeforeUpdateAnalysisView(IsHandled);
        if not IsHandled then
            UpdateAnalysisView.UpdateAll(0, true);

        OnAfterReverse(GLReg, GLReg2);
    end;

    local procedure ReverseGLEntry(var GLEntry2: Record "G/L Entry"; var GenJnlLine: Record "Gen. Journal Line"; var TempCustLedgEntry: Record "Cust. Ledger Entry" temporary; var TempVendLedgEntry: Record "Vendor Ledger Entry" temporary; var TempEmployeeLedgerEntry: Record "Employee Ledger Entry" temporary; var TempBankAccLedgEntry: Record "Bank Account Ledger Entry" temporary; var NextDtldCustLedgEntryEntryNo: Integer; var NextDtldVendLedgEntryEntryNo: Integer; var NextDtldEmplLedgEntryNo: Integer; FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry")
    var
        GLEntry: Record "G/L Entry";
        ReversedGLEntry: Record "G/L Entry";
    begin
        with GLEntry2 do
            if Find('+') then
                repeat
                    OnReverseGLEntryOnBeforeLoop(GLEntry2, GenJnlLine, GenJnlPostLine);
                    if "Reversed by Entry No." <> 0 then
                        Error(CannotReverseErr);
                    CheckDimComb("Entry No.", "Dimension Set ID", DATABASE::"G/L Account", "G/L Account No.", 0, '');
                    GLEntry := GLEntry2;
                    if "FA Entry No." <> 0 then
                        FAInsertLedgerEntry.InsertReverseEntry(
                          GenJnlPostLine.GetNextEntryNo(), "FA Entry Type", "FA Entry No.", GLEntry."FA Entry No.",
                          GenJnlPostLine.GetNextTransactionNo());
                    GLEntry.Amount := -Amount;
                    GLEntry.Quantity := -Quantity;
                    GLEntry."VAT Amount" := -"VAT Amount";
                    NonDeductibleVAT.Reverse(GLEntry, GLEntry2);
                    GLEntry."Debit Amount" := -"Debit Amount";
                    GLEntry."Credit Amount" := -"Credit Amount";
                    GLEntry."Additional-Currency Amount" := -"Additional-Currency Amount";
                    GLEntry."Add.-Currency Debit Amount" := -"Add.-Currency Debit Amount";
                    GLEntry."Add.-Currency Credit Amount" := -"Add.-Currency Credit Amount";
                    GLEntry."Entry No." := GenJnlPostLine.GetNextEntryNo();
                    GLEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo();
                    GLEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
                    GenJnlLine.Correction :=
                      (GLEntry."Debit Amount" < 0) or (GLEntry."Credit Amount" < 0) or
                      (GLEntry."Add.-Currency Debit Amount" < 0) or (GLEntry."Add.-Currency Credit Amount" < 0);
                    GLEntry."Journal Batch Name" := '';
                    GLEntry."Source Code" := GenJnlLine."Source Code";
                    SetReversalDescription(GLEntry2, GLEntry.Description);
                    GLEntry."Reversed Entry No." := "Entry No.";
                    GLEntry.Reversed := true;
                    // Reversal of Reversal
                    if "Reversed Entry No." <> 0 then begin
                        ReversedGLEntry.Get("Reversed Entry No.");
                        ReversedGLEntry."Reversed by Entry No." := 0;
                        ReversedGLEntry.Reversed := false;
                        ReversedGLEntry.Modify();
                        "Reversed Entry No." := GLEntry."Entry No.";
                        GLEntry."Reversed by Entry No." := "Entry No.";
                    end;
                    "Reversed by Entry No." := GLEntry."Entry No.";
                    Reversed := true;
                    Modify();
                    OnReverseGLEntryOnBeforeInsertGLEntry(GLEntry, GenJnlLine, GLEntry2, GenJnlPostLine);
                    GenJnlPostLine.InsertGLEntry(GenJnlLine, GLEntry, false);
                    OnReverseGLEntryOnAfterInsertGLEntry(GLEntry, GenJnlLine, GLEntry2, GenJnlPostLine);

                    case true of
                        TempCustLedgEntry.Get("Entry No."):
                            begin
                                CheckDimComb("Entry No.", "Dimension Set ID",
                                  DATABASE::Customer, TempCustLedgEntry."Customer No.",
                                  DATABASE::"Salesperson/Purchaser", TempCustLedgEntry."Salesperson Code");
                                ReverseCustLedgEntry(
                                  TempCustLedgEntry, GLEntry."Entry No.", GenJnlLine.Correction, GenJnlLine."Source Code",
                                  NextDtldCustLedgEntryEntryNo);
                                OnReverseGLEntryOnAfterReverseCustLedgEntry(TempCustLedgEntry, GLEntry, GLEntry2);
                                TempCustLedgEntry.Delete();
                            end;
                        TempVendLedgEntry.Get("Entry No."):
                            begin
                                CheckDimComb("Entry No.", "Dimension Set ID",
                                  DATABASE::Vendor, TempVendLedgEntry."Vendor No.",
                                  DATABASE::"Salesperson/Purchaser", TempVendLedgEntry."Purchaser Code");
                                ReverseVendLedgEntry(
                                  TempVendLedgEntry, GLEntry."Entry No.", GenJnlLine.Correction, GenJnlLine."Source Code",
                                  NextDtldVendLedgEntryEntryNo);
                                OnReverseGLEntryOnAfterReverseVendLedgEntry(TempVendLedgEntry, GLEntry, GLEntry2);
                                TempVendLedgEntry.Delete();
                            end;
                        TempEmployeeLedgerEntry.Get("Entry No."):
                            begin
                                CheckDimComb(
                                  "Entry No.", "Dimension Set ID", DATABASE::Employee, TempEmployeeLedgerEntry."Employee No.", 0, '');
                                ReverseEmplLedgEntry(
                                  TempEmployeeLedgerEntry, GLEntry."Entry No.", GenJnlLine.Correction, GenJnlLine."Source Code",
                                  NextDtldEmplLedgEntryNo);
                                TempEmployeeLedgerEntry.Delete();
                            end;
                        TempBankAccLedgEntry.Get("Entry No."):
                            begin
                                CheckDimComb("Entry No.", "Dimension Set ID",
                                  DATABASE::"Bank Account", TempBankAccLedgEntry."Bank Account No.", 0, '');
                                ReverseBankAccLedgEntry(TempBankAccLedgEntry, GLEntry."Entry No.", GenJnlLine."Source Code");
                                TempBankAccLedgEntry.Delete();
                            end;
                        else
                            OnReverseGLEntryOnCaseElse(GLEntry2, GLEntry, GenJnlLine, GenJnlPostLine, TempBankAccLedgEntry);
                    end;

                    ReverseVAT(GLEntry, GenJnlLine."Source Code");
                    OnReverseGLEntryOnAfterReverseVAT(GLEntry2, GLEntry, GenJnlPostLine);
                until Next(-1) = 0;

        OnAfterReverseGLEntry(GLEntry);
    end;

    local procedure ReverseCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry"; NewEntryNo: Integer; Correction: Boolean; SourceCode: Code[10]; var NextDtldCustLedgEntryEntryNo: Integer)
    var
        NewCustLedgEntry: Record "Cust. Ledger Entry";
        ReversedCustLedgEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        NewDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        IsHandled: Boolean;
    begin
        with NewCustLedgEntry do begin
            NewCustLedgEntry := CustLedgEntry;
            "Sales (LCY)" := -"Sales (LCY)";
            "Profit (LCY)" := -"Profit (LCY)";
            "Inv. Discount (LCY)" := -"Inv. Discount (LCY)";
            "Original Pmt. Disc. Possible" := -"Original Pmt. Disc. Possible";
            "Pmt. Disc. Given (LCY)" := -"Pmt. Disc. Given (LCY)";
            Positive := not Positive;
            "Adjusted Currency Factor" := "Adjusted Currency Factor";
            "Original Currency Factor" := "Original Currency Factor";
            "Remaining Pmt. Disc. Possible" := -"Remaining Pmt. Disc. Possible";
            "Max. Payment Tolerance" := -"Max. Payment Tolerance";
            "Accepted Payment Tolerance" := -"Accepted Payment Tolerance";
            "Pmt. Tolerance (LCY)" := -"Pmt. Tolerance (LCY)";
            "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
            "Entry No." := NewEntryNo;
            "Transaction No." := GenJnlPostLine.GetNextTransactionNo();
            "Journal Batch Name" := '';
            "Source Code" := SourceCode;
            SetReversalDescription(CustLedgEntry, Description);
            "Reversed Entry No." := CustLedgEntry."Entry No.";
            Reversed := true;
            "Applies-to ID" := '';
            // Reversal of Reversal
            if CustLedgEntry."Reversed Entry No." <> 0 then begin
                ReversedCustLedgEntry.Get(CustLedgEntry."Reversed Entry No.");
                ReversedCustLedgEntry."Reversed by Entry No." := 0;
                ReversedCustLedgEntry.Reversed := false;
                ReversedCustLedgEntry.Modify();
                CustLedgEntry."Reversed Entry No." := "Entry No.";
                "Reversed by Entry No." := CustLedgEntry."Entry No.";
            end;
            CustLedgEntry."Applies-to ID" := '';
            CustLedgEntry."Reversed by Entry No." := "Entry No.";
            CustLedgEntry.Reversed := true;
            CustLedgEntry.Modify();
            OnReverseCustLedgEntryOnBeforeInsertCustLedgEntry(NewCustLedgEntry, CustLedgEntry, GenJnlPostLine);
            Insert();
            OnReverseCustLedgEntryOnAfterInsertCustLedgEntry(NewCustLedgEntry, CustLedgEntry, GenJnlPostLine);

            if NextDtldCustLedgEntryEntryNo = 0 then begin
                DtldCustLedgEntry.FindLast();
                NextDtldCustLedgEntryEntryNo := DtldCustLedgEntry."Entry No." + 1;
            end;
            DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
            DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
            DtldCustLedgEntry.SetRange(Unapplied, false);
            OnReverseCustLedgEntryOnAfterDtldCustLedgEntrySetFilters(DtldCustLedgEntry, NextDtldCustLedgEntryEntryNo);
            DtldCustLedgEntry.FindSet();
            repeat
                DtldCustLedgEntry.TestField("Entry Type", DtldCustLedgEntry."Entry Type"::"Initial Entry");
                NewDtldCustLedgEntry := DtldCustLedgEntry;
                NewDtldCustLedgEntry.Amount := -NewDtldCustLedgEntry.Amount;
                NewDtldCustLedgEntry."Amount (LCY)" := -NewDtldCustLedgEntry."Amount (LCY)";
                NewDtldCustLedgEntry.UpdateDebitCredit(Correction);
                NewDtldCustLedgEntry."Cust. Ledger Entry No." := NewEntryNo;
                NewDtldCustLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
                NewDtldCustLedgEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo();
                NewDtldCustLedgEntry."Entry No." := NextDtldCustLedgEntryEntryNo;
                NextDtldCustLedgEntryEntryNo := NextDtldCustLedgEntryEntryNo + 1;
                IsHandled := false;
                OnReverseCustLedgEntryOnBeforeInsertDtldCustLedgEntry(NewDtldCustLedgEntry, DtldCustLedgEntry, IsHandled, NewCustLedgEntry);
                if not IsHandled then
                    NewDtldCustLedgEntry.Insert(true);
                OnReverseCustLedgEntryOnAfterInsertDtldCustLedgEntry(NewDtldCustLedgEntry);
            until DtldCustLedgEntry.Next() = 0;

            ApplyCustLedgEntryByReversal(
              CustLedgEntry, NewCustLedgEntry, NewDtldCustLedgEntry, "Entry No.", NextDtldCustLedgEntryEntryNo);
            ApplyCustLedgEntryByReversal(
              NewCustLedgEntry, CustLedgEntry, DtldCustLedgEntry, "Entry No.", NextDtldCustLedgEntryEntryNo);
        end;
    end;

    local procedure ReverseVendLedgEntry(VendLedgEntry: Record "Vendor Ledger Entry"; NewEntryNo: Integer; Correction: Boolean; SourceCode: Code[10]; var NextDtldVendLedgEntryEntryNo: Integer)
    var
        NewVendLedgEntry: Record "Vendor Ledger Entry";
        ReversedVendLedgEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        NewDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        IsHandled: Boolean;
    begin
        with NewVendLedgEntry do begin
            NewVendLedgEntry := VendLedgEntry;
            "Purchase (LCY)" := -"Purchase (LCY)";
            "Inv. Discount (LCY)" := -"Inv. Discount (LCY)";
            "Original Pmt. Disc. Possible" := -"Original Pmt. Disc. Possible";
            "Pmt. Disc. Rcd.(LCY)" := -"Pmt. Disc. Rcd.(LCY)";
            Positive := not Positive;
            "Adjusted Currency Factor" := "Adjusted Currency Factor";
            "Original Currency Factor" := "Original Currency Factor";
            "Remaining Pmt. Disc. Possible" := -"Remaining Pmt. Disc. Possible";
            "Max. Payment Tolerance" := -"Max. Payment Tolerance";
            "Accepted Payment Tolerance" := -"Accepted Payment Tolerance";
            "Pmt. Tolerance (LCY)" := -"Pmt. Tolerance (LCY)";
            "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
            "Entry No." := NewEntryNo;
            "Transaction No." := GenJnlPostLine.GetNextTransactionNo();
            "Journal Batch Name" := '';
            "Source Code" := SourceCode;
            SetReversalDescription(VendLedgEntry, Description);
            "Reversed Entry No." := VendLedgEntry."Entry No.";
            Reversed := true;
            "Applies-to ID" := '';
            // Reversal of Reversal
            if VendLedgEntry."Reversed Entry No." <> 0 then begin
                ReversedVendLedgEntry.Get(VendLedgEntry."Reversed Entry No.");
                ReversedVendLedgEntry."Reversed by Entry No." := 0;
                ReversedVendLedgEntry.Reversed := false;
                ReversedVendLedgEntry.Modify();
                VendLedgEntry."Reversed Entry No." := "Entry No.";
                "Reversed by Entry No." := VendLedgEntry."Entry No.";
            end;
            VendLedgEntry."Applies-to ID" := '';
            VendLedgEntry."Reversed by Entry No." := "Entry No.";
            VendLedgEntry.Reversed := true;
            VendLedgEntry.Modify();
            OnReverseVendLedgEntryOnBeforeInsertVendLedgEntry(NewVendLedgEntry, VendLedgEntry, GenJnlPostLine);
            Insert();
            OnReverseVendLedgEntryOnAfterInsertVendLedgEntry(NewVendLedgEntry);

            if NextDtldVendLedgEntryEntryNo = 0 then begin
                DtldVendLedgEntry.FindLast();
                NextDtldVendLedgEntryEntryNo := DtldVendLedgEntry."Entry No." + 1;
            end;
            DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.");
            DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
            DtldVendLedgEntry.SetRange(Unapplied, false);
            OnReverseVendLedgEntryOnAfterDtldVendLedgEntrySetFilters(DtldVendLedgEntry, NextDtldVendLedgEntryEntryNo);
            DtldVendLedgEntry.FindSet();
            repeat
                DtldVendLedgEntry.TestField("Entry Type", DtldVendLedgEntry."Entry Type"::"Initial Entry");
                NewDtldVendLedgEntry := DtldVendLedgEntry;
                NewDtldVendLedgEntry.Amount := -NewDtldVendLedgEntry.Amount;
                NewDtldVendLedgEntry."Amount (LCY)" := -NewDtldVendLedgEntry."Amount (LCY)";
                NewDtldVendLedgEntry.UpdateDebitCredit(Correction);
                NewDtldVendLedgEntry."Vendor Ledger Entry No." := NewEntryNo;
                NewDtldVendLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
                NewDtldVendLedgEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo();
                NewDtldVendLedgEntry."Entry No." := NextDtldVendLedgEntryEntryNo;
                NextDtldVendLedgEntryEntryNo := NextDtldVendLedgEntryEntryNo + 1;
                IsHandled := false;
                OnReverseVendLedgEntryOnBeforeInsertDtldVendLedgEntry(NewDtldVendLedgEntry, DtldVendLedgEntry, IsHandled, NewVendLedgEntry);
                if not IsHandled then
                    NewDtldVendLedgEntry.Insert(true);
                OnReverseVendLedgEntryOnAfterInsertDtldVendLedgEntry(NewDtldVendLedgEntry, DtldVendLedgEntry);
            until DtldVendLedgEntry.Next() = 0;

            ApplyVendLedgEntryByReversal(
              VendLedgEntry, NewVendLedgEntry, NewDtldVendLedgEntry, "Entry No.", NextDtldVendLedgEntryEntryNo);
            ApplyVendLedgEntryByReversal(
              NewVendLedgEntry, VendLedgEntry, DtldVendLedgEntry, "Entry No.", NextDtldVendLedgEntryEntryNo);
        end;
    end;

    local procedure ReverseEmplLedgEntry(EmployeeLedgerEntry: Record "Employee Ledger Entry"; NewEntryNo: Integer; Correction: Boolean; SourceCode: Code[10]; var NextDtldEmplLedgEntryNo: Integer)
    var
        NewEmployeeLedgerEntry: Record "Employee Ledger Entry";
        ReversedEmployeeLedgerEntry: Record "Employee Ledger Entry";
        DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
        NewDetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
    begin
        with NewEmployeeLedgerEntry do begin
            NewEmployeeLedgerEntry := EmployeeLedgerEntry;
            Positive := not Positive;
            "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
            "Entry No." := NewEntryNo;
            "Transaction No." := GenJnlPostLine.GetNextTransactionNo();
            "Journal Batch Name" := '';
            "Source Code" := SourceCode;
            SetReversalDescription(EmployeeLedgerEntry, Description);
            "Reversed Entry No." := EmployeeLedgerEntry."Entry No.";
            Reversed := true;
            "Applies-to ID" := '';
            // Reversal of Reversal
            if EmployeeLedgerEntry."Reversed Entry No." <> 0 then begin
                ReversedEmployeeLedgerEntry.Get(EmployeeLedgerEntry."Reversed Entry No.");
                ReversedEmployeeLedgerEntry."Reversed by Entry No." := 0;
                ReversedEmployeeLedgerEntry.Reversed := false;
                ReversedEmployeeLedgerEntry.Modify();
                EmployeeLedgerEntry."Reversed Entry No." := "Entry No.";
                "Reversed by Entry No." := EmployeeLedgerEntry."Entry No.";
            end;
            EmployeeLedgerEntry."Applies-to ID" := '';
            EmployeeLedgerEntry."Reversed by Entry No." := "Entry No.";
            EmployeeLedgerEntry.Reversed := true;
            EmployeeLedgerEntry.Modify();
            OnReverseEmplLedgEntryOnBeforeInsertEmplLedgEntry(NewEmployeeLedgerEntry, EmployeeLedgerEntry);
            Insert();

            if NextDtldEmplLedgEntryNo = 0 then begin
                DetailedEmployeeLedgerEntry.FindLast();
                NextDtldEmplLedgEntryNo := DetailedEmployeeLedgerEntry."Entry No." + 1;
            end;
            DetailedEmployeeLedgerEntry.SetCurrentKey("Employee Ledger Entry No.");
            DetailedEmployeeLedgerEntry.SetRange("Employee Ledger Entry No.", EmployeeLedgerEntry."Entry No.");
            DetailedEmployeeLedgerEntry.SetRange(Unapplied, false);
            DetailedEmployeeLedgerEntry.FindSet();
            repeat
                DetailedEmployeeLedgerEntry.TestField("Entry Type", DetailedEmployeeLedgerEntry."Entry Type"::"Initial Entry");
                NewDetailedEmployeeLedgerEntry := DetailedEmployeeLedgerEntry;
                NewDetailedEmployeeLedgerEntry.Amount := -DetailedEmployeeLedgerEntry.Amount;
                NewDetailedEmployeeLedgerEntry."Amount (LCY)" := -DetailedEmployeeLedgerEntry."Amount (LCY)";
                NewDetailedEmployeeLedgerEntry.UpdateDebitCredit(Correction);
                NewDetailedEmployeeLedgerEntry."Employee Ledger Entry No." := NewEntryNo;
                NewDetailedEmployeeLedgerEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
                NewDetailedEmployeeLedgerEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo();
                NewDetailedEmployeeLedgerEntry."Entry No." := NextDtldEmplLedgEntryNo;
                NextDtldEmplLedgEntryNo += 1;
                OnReverseEmplLedgEntryOnBeforeInsertDtldEmplLedgEntry(NewDetailedEmployeeLedgerEntry, DetailedEmployeeLedgerEntry);
                NewDetailedEmployeeLedgerEntry.Insert(true);
            until DetailedEmployeeLedgerEntry.Next() = 0;

            ApplyEmplLedgEntryByReversal(
              EmployeeLedgerEntry, NewEmployeeLedgerEntry, NewDetailedEmployeeLedgerEntry, "Entry No.", NextDtldEmplLedgEntryNo);
            ApplyEmplLedgEntryByReversal(
              NewEmployeeLedgerEntry, EmployeeLedgerEntry, DetailedEmployeeLedgerEntry, "Entry No.", NextDtldEmplLedgEntryNo);
        end;
    end;

    local procedure ReverseBankAccLedgEntry(BankAccLedgEntry: Record "Bank Account Ledger Entry"; NewEntryNo: Integer; SourceCode: Code[10])
    var
        NewBankAccLedgEntry: Record "Bank Account Ledger Entry";
        ReversedBankAccLedgEntry: Record "Bank Account Ledger Entry";
    begin
        with NewBankAccLedgEntry do begin
            NewBankAccLedgEntry := BankAccLedgEntry;
            Amount := -Amount;
            "Remaining Amount" := -"Remaining Amount";
            "Amount (LCY)" := -"Amount (LCY)";
            "Debit Amount" := -"Debit Amount";
            "Credit Amount" := -"Credit Amount";
            "Debit Amount (LCY)" := -"Debit Amount (LCY)";
            "Credit Amount (LCY)" := -"Credit Amount (LCY)";
            Positive := not Positive;
            "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
            "Entry No." := NewEntryNo;
            "Transaction No." := GenJnlPostLine.GetNextTransactionNo();
            "Journal Batch Name" := '';
            "Source Code" := SourceCode;
            SetReversalDescription(BankAccLedgEntry, Description);
            "Reversed Entry No." := BankAccLedgEntry."Entry No.";
            Reversed := true;
            // Reversal of Reversal
            if BankAccLedgEntry."Reversed Entry No." <> 0 then begin
                ReversedBankAccLedgEntry.Get(BankAccLedgEntry."Reversed Entry No.");
                ReversedBankAccLedgEntry."Reversed by Entry No." := 0;
                ReversedBankAccLedgEntry.Reversed := false;
                ReversedBankAccLedgEntry.Modify();
                BankAccLedgEntry."Reversed Entry No." := "Entry No.";
                "Reversed by Entry No." := BankAccLedgEntry."Entry No.";
            end;
            BankAccLedgEntry."Reversed by Entry No." := "Entry No.";
            BankAccLedgEntry.Reversed := true;
            BankAccLedgEntry.Modify();
            OnReverseBankAccLedgEntryOnBeforeInsert(NewBankAccLedgEntry, BankAccLedgEntry, GenJnlPostLine);
            Insert();
        end;
    end;

    procedure ReverseVAT(GLEntry: Record "G/L Entry"; SourceCode: Code[10])
    var
        VATEntry: Record "VAT Entry";
        NewVATEntry: Record "VAT Entry";
        ReversedVATEntry: Record "VAT Entry";
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
    begin
        GLEntryVATEntryLink.SetRange("G/L Entry No.", GLEntry."Reversed Entry No.");
        if GLEntryVATEntryLink.FindSet() then
            repeat
                VATEntry.Get(GLEntryVATEntryLink."VAT Entry No.");
                if VATEntry."Reversed by Entry No." <> 0 then
                    Error(CannotReverseErr);
                with NewVATEntry do begin
                    NewVATEntry := VATEntry;
                    Base := -Base;
                    Amount := -Amount;
                    "Unrealized Amount" := -"Unrealized Amount";
                    "Unrealized Base" := -"Unrealized Base";
                    "Remaining Unrealized Amount" := -"Remaining Unrealized Amount";
                    "Remaining Unrealized Base" := -"Remaining Unrealized Base";
                    "Additional-Currency Amount" := -"Additional-Currency Amount";
                    "Additional-Currency Base" := -"Additional-Currency Base";
                    "Add.-Currency Unrealized Amt." := -"Add.-Currency Unrealized Amt.";
                    "Add.-Curr. Rem. Unreal. Amount" := -"Add.-Curr. Rem. Unreal. Amount";
                    "Add.-Curr. Rem. Unreal. Base" := -"Add.-Curr. Rem. Unreal. Base";
                    "VAT Difference" := -"VAT Difference";
                    "Add.-Curr. VAT Difference" := -"Add.-Curr. VAT Difference";
                    NonDeductibleVAT.Reverse(NewVATEntry);
                    "Transaction No." := GenJnlPostLine.GetNextTransactionNo();
                    "Source Code" := SourceCode;
                    "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
                    "Entry No." := GenJnlPostLine.GetNextVATEntryNo();
                    "Reversed Entry No." := VATEntry."Entry No.";
                    Reversed := true;
                    // Reversal of Reversal
                    if VATEntry."Reversed Entry No." <> 0 then begin
                        ReversedVATEntry.Get(VATEntry."Reversed Entry No.");
                        ReversedVATEntry."Reversed by Entry No." := 0;
                        ReversedVATEntry.Reversed := false;
                        OnReverseVATOnBeforeReversedVATEntryModify(ReversedVATEntry, VATEntry);
                        ReversedVATEntry.Modify();
                        VATEntry."Reversed Entry No." := "Entry No.";
                        "Reversed by Entry No." := VATEntry."Entry No.";
                    end;
                    VATEntry."Reversed by Entry No." := "Entry No.";
                    VATEntry.Reversed := true;
                    OnReverseVATOnBeforeVATEntryModify(VATEntry);
                    VATEntry.Modify();
                    OnReverseVATEntryOnBeforeInsert(NewVATEntry, VATEntry, GenJnlPostLine);
                    Insert();
                    GLEntryVATEntryLink.InsertLink(GLEntry."Entry No.", "Entry No.");
                    GenJnlPostLine.IncrNextVATEntryNo();
                end;
            until GLEntryVATEntryLink.Next() = 0;
    end;

    local procedure ApplyCustLedgEntryByReversal(CustLedgEntry: Record "Cust. Ledger Entry"; CustLedgEntry2: Record "Cust. Ledger Entry"; DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; AppliedEntryNo: Integer; var NextDtldCustLedgEntryEntryNo: Integer)
    var
        NewDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        IsHandled: Boolean;
    begin
        CustLedgEntry2.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        CustLedgEntry."Closed by Entry No." := CustLedgEntry2."Entry No.";
        CustLedgEntry."Closed at Date" := CustLedgEntry2."Posting Date";
        CustLedgEntry."Closed by Amount" := -CustLedgEntry2."Remaining Amount";
        CustLedgEntry."Closed by Amount (LCY)" := -CustLedgEntry2."Remaining Amt. (LCY)";
        CustLedgEntry."Closed by Currency Code" := CustLedgEntry2."Currency Code";
        CustLedgEntry."Closed by Currency Amount" := -CustLedgEntry2."Remaining Amount";
        CustLedgEntry.Open := false;
        CustLedgEntry.Modify();
        OnApplyCustLedgEntryByReversalOnAfterCustLedgEntryModify(CustLedgEntry);

        NewDtldCustLedgEntry := DtldCustLedgEntry2;
        NewDtldCustLedgEntry."Cust. Ledger Entry No." := CustLedgEntry."Entry No.";
        NewDtldCustLedgEntry."Entry Type" := NewDtldCustLedgEntry."Entry Type"::Application;
        NewDtldCustLedgEntry."Applied Cust. Ledger Entry No." := AppliedEntryNo;
        NewDtldCustLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(NewDtldCustLedgEntry."User ID"));
        NewDtldCustLedgEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo();
        NewDtldCustLedgEntry."Entry No." := NextDtldCustLedgEntryEntryNo;
        NextDtldCustLedgEntryEntryNo := NextDtldCustLedgEntryEntryNo + 1;
        IsHandled := false;
        OnApplyCustLedgEntryByReversalOnBeforeInsertDtldCustLedgEntry(NewDtldCustLedgEntry, DtldCustLedgEntry2, IsHandled, GenJnlPostLine);
        if not IsHandled then
            NewDtldCustLedgEntry.Insert(true);

        OnApplyCustLedgEntryByReversalOnAfterInsertDtldCustLedgEntry(NewDtldCustLedgEntry, CustLedgEntry2);
    end;

    local procedure ApplyVendLedgEntryByReversal(VendLedgEntry: Record "Vendor Ledger Entry"; VendLedgEntry2: Record "Vendor Ledger Entry"; DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry"; AppliedEntryNo: Integer; var NextDtldVendLedgEntryEntryNo: Integer)
    var
        NewDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        IsHandled: Boolean;
    begin
        VendLedgEntry2.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        VendLedgEntry."Closed by Entry No." := VendLedgEntry2."Entry No.";
        VendLedgEntry."Closed at Date" := VendLedgEntry2."Posting Date";
        VendLedgEntry."Closed by Amount" := -VendLedgEntry2."Remaining Amount";
        VendLedgEntry."Closed by Amount (LCY)" := -VendLedgEntry2."Remaining Amt. (LCY)";
        VendLedgEntry."Closed by Currency Code" := VendLedgEntry2."Currency Code";
        VendLedgEntry."Closed by Currency Amount" := -VendLedgEntry2."Remaining Amount";
        VendLedgEntry.Open := false;
        VendLedgEntry.Modify();
        OnApplyVendLedgEntryByReversalOnAfterVendLedgEntryModify(VendLedgEntry);

        NewDtldVendLedgEntry := DtldVendLedgEntry2;
        NewDtldVendLedgEntry."Vendor Ledger Entry No." := VendLedgEntry."Entry No.";
        NewDtldVendLedgEntry."Entry Type" := NewDtldVendLedgEntry."Entry Type"::Application;
        NewDtldVendLedgEntry."Applied Vend. Ledger Entry No." := AppliedEntryNo;
        NewDtldVendLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(NewDtldVendLedgEntry."User ID"));
        NewDtldVendLedgEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo();
        NewDtldVendLedgEntry."Entry No." := NextDtldVendLedgEntryEntryNo;
        NextDtldVendLedgEntryEntryNo := NextDtldVendLedgEntryEntryNo + 1;
        IsHandled := false;
        OnApplyVendLedgEntryByReversalOnBeforeInsertDtldVendLedgEntry(NewDtldVendLedgEntry, DtldVendLedgEntry2, IsHandled, GenJnlPostLine);
        if not IsHandled then
            NewDtldVendLedgEntry.Insert(true);
        OnApplyVendLedgEntryByReversalOnAfterInsertDtldVendLedgEntry(NewDtldVendLedgEntry, VendLedgEntry2);
    end;

    local procedure ApplyEmplLedgEntryByReversal(EmployeeLedgerEntry: Record "Employee Ledger Entry"; EmployeeLedgerEntry2: Record "Employee Ledger Entry"; DetailedEmployeeLedgerEntry2: Record "Detailed Employee Ledger Entry"; AppliedEntryNo: Integer; var NextDtldEmplLedgEntryNo: Integer)
    var
        NewDetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
    begin
        EmployeeLedgerEntry2.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        EmployeeLedgerEntry."Closed by Entry No." := EmployeeLedgerEntry2."Entry No.";
        EmployeeLedgerEntry."Closed at Date" := EmployeeLedgerEntry2."Posting Date";
        EmployeeLedgerEntry."Closed by Amount" := -EmployeeLedgerEntry2."Remaining Amount";
        EmployeeLedgerEntry."Closed by Amount (LCY)" := -EmployeeLedgerEntry2."Remaining Amt. (LCY)";
        EmployeeLedgerEntry.Open := false;
        EmployeeLedgerEntry.Modify();

        NewDetailedEmployeeLedgerEntry := DetailedEmployeeLedgerEntry2;
        NewDetailedEmployeeLedgerEntry."Employee Ledger Entry No." := EmployeeLedgerEntry."Entry No.";
        NewDetailedEmployeeLedgerEntry."Entry Type" := NewDetailedEmployeeLedgerEntry."Entry Type"::Application;
        NewDetailedEmployeeLedgerEntry."Applied Empl. Ledger Entry No." := AppliedEntryNo;
        NewDetailedEmployeeLedgerEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(NewDetailedEmployeeLedgerEntry."User ID"));
        NewDetailedEmployeeLedgerEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo();
        NewDetailedEmployeeLedgerEntry."Entry No." := NextDtldEmplLedgEntryNo;
        NextDtldEmplLedgEntryNo += 1;
        OnApplyEmplLedgEntryByReversalOnBeforeInsertDtldEmplLedgEntry(NewDetailedEmployeeLedgerEntry, DetailedEmployeeLedgerEntry2);
        NewDetailedEmployeeLedgerEntry.Insert(true);
    end;

    procedure CheckDimComb(EntryNo: Integer; DimSetID: Integer; TableID1: Integer; AccNo1: Code[20]; TableID2: Integer; AccNo2: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        AccNo: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDimComb(EntryNo, DimSetID, TableID1, AccNo1, TableID2, AccNo2, IsHandled, DimMgt);
        if not IsHandled then begin
            if not DimMgt.CheckDimIDComb(DimSetID) then
                Error(DimCombBlockedErr, EntryNo, DimMgt.GetDimCombErr());
            Clear(TableID);
            Clear(AccNo);
            TableID[1] := TableID1;
            AccNo[1] := AccNo1;
            TableID[2] := TableID2;
            AccNo[2] := AccNo2;
            if not DimMgt.CheckDimValuePosting(TableID, AccNo, DimSetID) then
                Error(DimMgt.GetDimValuePostingErr());
        end;

        OnAfterCheckDimComb(DimMgt);
    end;

    local procedure CopyCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; var TempCustLedgEntry: Record "Cust. Ledger Entry" temporary)
    begin
        if CustLedgEntry.FindSet() then
            repeat
                if CustLedgEntry."Reversed by Entry No." <> 0 then
                    Error(CannotReverseErr);
                TempCustLedgEntry := CustLedgEntry;
                TempCustLedgEntry.Insert();
            until CustLedgEntry.Next() = 0;
    end;

    local procedure CopyVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; var TempVendLedgEntry: Record "Vendor Ledger Entry" temporary)
    begin
        if VendLedgEntry.FindSet() then
            repeat
                if VendLedgEntry."Reversed by Entry No." <> 0 then
                    Error(CannotReverseErr);
                TempVendLedgEntry := VendLedgEntry;
                TempVendLedgEntry.Insert();
            until VendLedgEntry.Next() = 0;
    end;

    local procedure CopyEmplLedgEntry(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; var TempEmployeeLedgerEntry: Record "Employee Ledger Entry" temporary)
    begin
        if EmployeeLedgerEntry.FindSet() then
            repeat
                if EmployeeLedgerEntry."Reversed by Entry No." <> 0 then
                    Error(CannotReverseErr);
                TempEmployeeLedgerEntry := EmployeeLedgerEntry;
                TempEmployeeLedgerEntry.Insert();
            until EmployeeLedgerEntry.Next() = 0;
    end;

    local procedure CopyBankAccLedgEntry(var BankAccLedgEntry: Record "Bank Account Ledger Entry"; var TempBankAccLedgEntry: Record "Bank Account Ledger Entry" temporary)
    begin
        if BankAccLedgEntry.FindSet() then
            repeat
                if BankAccLedgEntry."Reversed by Entry No." <> 0 then
                    Error(CannotReverseErr);
                TempBankAccLedgEntry := BankAccLedgEntry;
                TempBankAccLedgEntry.Insert();
            until BankAccLedgEntry.Next() = 0;
    end;

    procedure SetReversalDescription(RecVar: Variant; var Description: Text[100])
    var
        ReversalEntry: Record "Reversal Entry";
    begin
        FilterReversalEntry(ReversalEntry, RecVar);
        if ReversalEntry.FindFirst() then
            Description := ReversalEntry.Description;
    end;

    local procedure GetTransactionKey(): Integer
    var
        ReversalEntry: Record "Reversal Entry";
    begin
        ReversalEntry.SetCurrentKey("Transaction No.");
        ReversalEntry.SetFilter("Transaction No.", '<%1', 0);
        if ReversalEntry.FindFirst() then;
        exit(ReversalEntry."Transaction No." - 1);
    end;

    local procedure GetRegisterNoForTransactionReversal(var ReversalEntry: Record "Reversal Entry"): Integer
    var
        GLRegister: Record "G/L Register";
    begin
        GLRegister.SetCurrentKey("To Entry No.");
        GLRegister.SetRange("To Entry No.", ReversalEntry."Entry No.");
        if GLRegister.FindFirst() then;
        exit(GLRegister."No.");
    end;

    local procedure FilterReversalEntry(var ReversalEntry: Record "Reversal Entry"; RecVar: Variant)
    var
        GLEntry: Record "G/L Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        FALedgerEntry: Record "FA Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        case RecRef.Number of
            DATABASE::"G/L Entry":
                begin
                    ReversalEntry.SetRange("Entry Type", ReversalEntry."Entry Type"::"G/L Account");
                    GLEntry := RecVar;
                    ReversalEntry.SetRange("Entry No.", GLEntry."Entry No.");
                end;
            DATABASE::"Cust. Ledger Entry":
                begin
                    ReversalEntry.SetRange("Entry Type", ReversalEntry."Entry Type"::Customer);
                    CustLedgerEntry := RecVar;
                    ReversalEntry.SetRange("Entry No.", CustLedgerEntry."Entry No.");
                end;
            DATABASE::"Vendor Ledger Entry":
                begin
                    ReversalEntry.SetRange("Entry Type", ReversalEntry."Entry Type"::Vendor);
                    VendorLedgerEntry := RecVar;
                    ReversalEntry.SetRange("Entry No.", VendorLedgerEntry."Entry No.");
                end;
            DATABASE::"Employee Ledger Entry":
                begin
                    ReversalEntry.SetRange("Entry Type", ReversalEntry."Entry Type"::Employee);
                    EmployeeLedgerEntry := RecVar;
                    ReversalEntry.SetRange("Entry No.", EmployeeLedgerEntry."Entry No.");
                end;
            DATABASE::"Bank Account Ledger Entry":
                begin
                    ReversalEntry.SetRange("Entry Type", ReversalEntry."Entry Type"::"Bank Account");
                    BankAccountLedgerEntry := RecVar;
                    ReversalEntry.SetRange("Entry No.", BankAccountLedgerEntry."Entry No.");
                end;
            DATABASE::"FA Ledger Entry":
                begin
                    ReversalEntry.SetRange("Entry Type", ReversalEntry."Entry Type"::"Fixed Asset");
                    FALedgerEntry := RecVar;
                    ReversalEntry.SetRange("Entry No.", FALedgerEntry."Entry No.");
                end;
            DATABASE::"Maintenance Ledger Entry":
                begin
                    ReversalEntry.SetRange("Entry Type", ReversalEntry."Entry Type"::Maintenance);
                    MaintenanceLedgerEntry := RecVar;
                    ReversalEntry.SetRange("Entry No.", MaintenanceLedgerEntry."Entry No.");
                end;
            else
                OnAfterFilterReversalEntry(ReversalEntry, RecVar);
        end;
    end;

    local procedure SaveReversalEntries(var TempReversalEntry: Record "Reversal Entry" temporary; TransactionKey: Integer)
    var
        ReversalEntry: Record "Reversal Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSaveReversalEntries(IsHandled);
        if IsHandled then
            exit;

        if TempReversalEntry.FindSet() then
            repeat
                ReversalEntry := TempReversalEntry;
                ReversalEntry."Transaction No." := TransactionKey;
                ReversalEntry.Insert();
            until TempReversalEntry.Next() = 0;
    end;

    local procedure DeleteReversalEntries(TransactionKey: Integer)
    var
        ReversalEntry: Record "Reversal Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteReversalEntries(IsHandled);
        if IsHandled then
            exit;
        ReversalEntry.SetRange("Transaction No.", TransactionKey);
        ReversalEntry.DeleteAll();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterReversalEntry(var ReversalEntry: Record "Reversal Entry"; RecVar: Variant)
    begin
    end;

#if not CLEAN23
    [Obsolete('Replaced by event OnReverseOnAfterStartPosting', '23.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostReverse(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
#endif

    [IntegrationEvent(true, false)]
    local procedure OnReverseOnAfterStartPosting(var GenJournalLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var GLRegister: Record "G/L Register"; var GLRegister2: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReverse(GLRegister: Record "G/L Register"; var GLRegister2: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReverseGLEntry(var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReverse(var ReversalEntry: Record "Reversal Entry"; var ReversalEntry2: Record "Reversal Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimComb(EntryNo: Integer; DimSetID: Integer; TableID1: Integer; AccNo1: Code[20]; TableID2: Integer; AccNo2: Code[20]; var IsHandled: Boolean; var DimensionManagement: Codeunit DimensionManagement)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseGLEntryOnAfterInsertGLEntry(var GLEntry: Record "G/L Entry"; GenJnlLine: Record "Gen. Journal Line"; GLEntry2: Record "G/L Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseGLEntryOnBeforeInsertGLEntry(var GLEntry: Record "G/L Entry"; GenJnlLine: Record "Gen. Journal Line"; GLEntry2: Record "G/L Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseGLEntryOnBeforeLoop(var GLEntry: Record "G/L Entry"; var GenJournalLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseGLEntryOnCaseElse(GLEntry2: Record "G/L Entry"; GLEntry: Record "G/L Entry"; GenJournalLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseCustLedgEntryOnAfterDtldCustLedgEntrySetFilters(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; NextDtldCustLedgEntryEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseCustLedgEntryOnAfterInsertCustLedgEntry(var NewCustLedgerEntry: Record "Cust. Ledger Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseCustLedgEntryOnBeforeInsertCustLedgEntry(var NewCustLedgerEntry: Record "Cust. Ledger Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseVATOnBeforeVATEntryModify(var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseVATOnBeforeReversedVATEntryModify(var ReversedVATEntry: Record "VAT Entry"; var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseVendLedgEntryOnAfterDtldVendLedgEntrySetFilters(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; NextDtldVendLedgEntryEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseVendLedgEntryOnBeforeInsertVendLedgEntry(var NewVendLedgEntry: Record "Vendor Ledger Entry"; VendLedgEntry: Record "Vendor Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseVendLedgEntryOnAfterInsertVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseEmplLedgEntryOnBeforeInsertEmplLedgEntry(var NewEmployeeLedgerEntry: Record "Employee Ledger Entry"; EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseBankAccLedgEntryOnBeforeInsert(var NewBankAccLedgEntry: Record "Bank Account Ledger Entry"; BankAccLedgEntry: Record "Bank Account Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseCustLedgEntryOnBeforeInsertDtldCustLedgEntry(var NewDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var IsHandled: Boolean; NewCustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseVendLedgEntryOnBeforeInsertDtldVendLedgEntry(var NewDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var IsHandled: Boolean; NewVendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseEmplLedgEntryOnBeforeInsertDtldEmplLedgEntry(var NewDetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry"; DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseVATEntryOnBeforeInsert(var NewVATEntry: Record "VAT Entry"; VATEntry: Record "VAT Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseOnBeforeFinishPosting(var ReversalEntry: Record "Reversal Entry"; var ReversalEntry2: Record "Reversal Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var GLRegister: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseOnBeforeStartPosting(var GenJournalLine: Record "Gen. Journal Line"; var ReversalEntry: Record "Reversal Entry"; var GLEntry: Record "G/L Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseOnBeforeReverseGLEntry(var ReversalEntry2: Record "Reversal Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var GenJournalLine: Record "Gen. Journal Line"; TempRevertTransactionNo: record "Integer"; var GLEntry2: Record "G/L Entry"; GLRegister: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgEntryByReversalOnBeforeInsertDtldCustLedgEntry(var NewDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var IsHandled: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgEntryByReversalOnAfterCustLedgEntryModify(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendLedgEntryByReversalOnBeforeInsertDtldVendLedgEntry(var NewDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var IsHandled: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendLedgEntryByReversalOnAfterVendLedgEntryModify(VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyEmplLedgEntryByReversalOnBeforeInsertDtldEmplLedgEntry(var NewDetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry"; DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseOnAfterFinishPosting(var ReversalEntry2: Record "Reversal Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var GLRegister: Record "G/L Register"; GLRegister2: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseOnBeforeCheckFAReverseEntry(var FALedgerEntry: Record "FA Ledger Entry"; var FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry"; var ReversalEntry2: Record "Reversal Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseVendLedgEntryOnAfterInsertDtldVendLedgEntry(var NewDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseOnBeforeGetTransactionKey(var ReversalEntry2: Record "Reversal Entry"; var TempIntegerAsRevertTransactionNo: Record "Integer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseGLEntryOnAfterReverseVendLedgEntry(var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; var GLEntry: Record "G/L Entry"; GLEntry2: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseOnBeforeUpdateAnalysisView(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseGLEntryOnAfterReverseVAT(GLEntry2: Record "G/L Entry"; GLEntry: Record "G/L Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseGLEntryOnAfterReverseCustLedgEntry(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; var GLEntry: Record "G/L Entry"; GLEntry2: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseCustLedgEntryOnAfterInsertDtldCustLedgEntry(var NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgEntryByReversalOnAfterInsertDtldCustLedgEntry(var NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustLedgerEntry2: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckDimComb(var DimensionManagement: Codeunit DimensionManagement)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveReversalEntries(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteReversalEntries(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendLedgEntryByReversalOnAfterInsertDtldVendLedgEntry(var NewDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; VendorLedgerEntry2: Record "Vendor Ledger Entry")
    begin
    end;
}

