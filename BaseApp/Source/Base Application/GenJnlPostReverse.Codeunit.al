codeunit 17 "Gen. Jnl.-Post Reverse"
{
    Permissions = TableData "G/L Entry" = m,
                  TableData "Cust. Ledger Entry" = imd,
                  TableData "Vendor Ledger Entry" = imd,
                  TableData "G/L Register" = rm,
                  TableData "G/L Entry - VAT Entry Link" = rimd,
                  TableData "VAT Entry" = imd,
                  TableData "Bank Account Ledger Entry" = imd,
                  TableData "Check Ledger Entry" = imd,
                  TableData "Detailed Cust. Ledg. Entry" = imd,
                  TableData "Detailed Vendor Ledg. Entry" = imd,
                  TableData "Employee Payroll Entry" = rimd;
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
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
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        TempBankAccLedgEntry: Record "Bank Account Ledger Entry" temporary;
        VATEntry: Record "VAT Entry";
        FALedgEntry: Record "FA Ledger Entry";
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        TempRevertTransactionNo: Record "Integer" temporary;
        ValueEntry: Record "Value Entry";
        TempValueEntry: Record "Value Entry" temporary;
        GLEntry3: Record "G/L Entry";
        TaxDiffLedgEntry: Record "Tax Diff. Ledger Entry";
        TempTaxDiffLedgEntry: Record "Tax Diff. Ledger Entry" temporary;
        FAInsertLedgEntry: Codeunit "FA Insert Ledger Entry";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        NextDtldCustLedgEntryEntryNo: Integer;
        NextDtldVendLedgEntryEntryNo: Integer;
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
          GLEntry2, CustLedgEntry, VendLedgEntry, BankAccLedgEntry, VATEntry, FALedgEntry, MaintenanceLedgEntry, TaxDiffLedgEntry, ValueEntry);

        if ReversalEntry2."Reversal Type" = ReversalEntry2."Reversal Type"::Transaction then begin
            GLReg2."No." := GetRegisterNoForTransactionReversal(ReversalEntry2);
            if ReversalEntry2.FindSet(false, false) then
                repeat
                    TempRevertTransactionNo.Number := ReversalEntry2."Transaction No.";
                    if TempRevertTransactionNo.Insert() then;
                until ReversalEntry2.Next = 0;
        end;

        TransactionKey := GetTransactionKey;
        SaveReversalEntries(ReversalEntry2, TransactionKey);

        GenJnlLine.Init();
        GenJnlLine."Source Code" := SourceCodeSetup.Reversal;

        OnReverseOnBeforeStartPosting(GenJnlLine, ReversalEntry2, GLEntry2);

        if GenJnlPostLine.GetNextEntryNo = 0 then
            GenJnlPostLine.StartPosting(GenJnlLine)
        else
            GenJnlPostLine.ContinuePosting(GenJnlLine);

        OnAfterPostReverse(GenJnlLine);

        GenJnlPostLine.SetGLRegReverse(GLReg);

        CopyCustLedgEntry(CustLedgEntry, TempCustLedgEntry);
        CopyVendLedgEntry(VendLedgEntry, TempVendLedgEntry);
        CopyBankAccLedgEntry(BankAccLedgEntry, TempBankAccLedgEntry);
        GLSetup.Get();
        if GLSetup."Enable Russian Tax Accounting" then
            CopyTaxDiffLedgEntry(TaxDiffLedgEntry, TempTaxDiffLedgEntry);
        if GLSetup."Enable Russian Accounting" then
            CopyValueEntry(ValueEntry, TempValueEntry);

        if TempRevertTransactionNo.FindSet then;
        repeat
            if ReversalEntry2."Reversal Type" = ReversalEntry2."Reversal Type"::Transaction then
                GLEntry2.SetRange("Transaction No.", TempRevertTransactionNo.Number);
            ReverseGLEntry(
              GLEntry2, GenJnlLine, TempCustLedgEntry,
              TempVendLedgEntry, TempBankAccLedgEntry, NextDtldCustLedgEntryEntryNo, NextDtldVendLedgEntryEntryNo,
              FAInsertLedgEntry,
              ReversalEntry, TempTaxDiffLedgEntry, ReversalEntry2, GLReg);
        until TempRevertTransactionNo.Next = 0;

        if FALedgEntry.FindSet then
            repeat
                FAInsertLedgEntry.CheckFAReverseEntry(FALedgEntry)
            until FALedgEntry.Next = 0;

        if MaintenanceLedgEntry.FindFirst then
            repeat
                FAInsertLedgEntry.CheckMaintReverseEntry(MaintenanceLedgEntry)
            until FALedgEntry.Next = 0;

        FAInsertLedgEntry.FinishFAReverseEntry(GLReg);

        if not TempCustLedgEntry.IsEmpty then
            Error(ReversalMismatchErr, CustLedgEntry.TableCaption);
        if not TempVendLedgEntry.IsEmpty then
            Error(ReversalMismatchErr, VendLedgEntry.TableCaption);
        if not TempBankAccLedgEntry.IsEmpty then
            Error(ReversalMismatchErr, BankAccLedgEntry.TableCaption);
        if not TempTaxDiffLedgEntry.IsEmpty then
            Error(ReversalMismatchErr, TaxDiffLedgEntry.TableCaption);

        OnReverseOnBeforeFinishPosting(ReversalEntry, ReversalEntry2, GenJnlPostLine, GLReg);

        GenJnlPostLine.FinishPosting(GenJnlLine);

        if GLReg2."No." <> 0 then
            if GLReg2.Find then begin
                GLReg2.Reversed := true;
                GLReg2.Modify();
            end;

        DeleteReversalEntries(TransactionKey);

        UpdateAnalysisView.UpdateAll(0, true);

        OnAfterReverse(GLReg);
    end;

    local procedure ReverseGLEntry(var GLEntry2: Record "G/L Entry"; var GenJnlLine: Record "Gen. Journal Line"; var TempCustLedgEntry: Record "Cust. Ledger Entry" temporary; var TempVendLedgEntry: Record "Vendor Ledger Entry" temporary; var TempBankAccLedgEntry: Record "Bank Account Ledger Entry" temporary; var NextDtldCustLedgEntryEntryNo: Integer; var NextDtldVendLedgEntryEntryNo: Integer; FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry"; var ReversalEntry: Record "Reversal Entry"; var TempTaxDiffLedgerEntry: Record "Tax Diff. Ledger Entry" temporary; var ReversalEntry2: Record "Reversal Entry"; GLReg: Record "G/L Register")
    var
        GLEntry: Record "G/L Entry";
        ReversedGLEntry: Record "G/L Entry";
        TaxDiffRegister: Record "Tax Diff. Register";
        GLItemLedgerRelation: Record "G/L - Item Ledger Relation";
        ValueEntry: Record "Value Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VATAllocationPost: Codeunit "VAT Allocation-Post";
    begin
        with GLEntry2 do
            if Find('+') then
                repeat
                    OnReverseGLEntryOnBeforeLoop(GLEntry2, GenJnlLine, GenJnlPostLine);
                    if "Reversed by Entry No." <> 0 then
                        Error(CannotReverseErr);
                    CheckDimComb("Entry No.", "Dimension Set ID", DATABASE::"G/L Account", "G/L Account No.", 0, '');
                    GLEntry := GLEntry2;
                    if ("FA Entry No." <> 0) and GLSetup."Enable Russian Tax Accounting" then
                        InsertReverseTaxEntry(FAInsertLedgerEntry, "Entry No.", GenJnlPostLine.GetNextEntryNo, "FA Entry Type",
                          "FA Entry No.", GLEntry."FA Entry No.", GenJnlPostLine.GetNextTransactionNo);
                    if "FA Entry No." <> 0 then
                        FAInsertLedgerEntry.InsertReverseEntry(
                          GenJnlPostLine.GetNextEntryNo, "FA Entry Type", "FA Entry No.", GLEntry."FA Entry No.",
                          GenJnlPostLine.GetNextTransactionNo);
                    GLEntry.Amount := -Amount;
                    GLEntry.Quantity := -Quantity;
                    GLEntry."VAT Amount" := -"VAT Amount";
                    GLEntry."Debit Amount" := -"Debit Amount";
                    GLEntry."Credit Amount" := -"Credit Amount";
                    GLEntry."Additional-Currency Amount" := -"Additional-Currency Amount";
                    GLEntry."Add.-Currency Debit Amount" := -"Add.-Currency Debit Amount";
                    GLEntry."Add.-Currency Credit Amount" := -"Add.-Currency Credit Amount";
                    GLEntry."Entry No." := GenJnlPostLine.GetNextEntryNo;
                    GLEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo;
                    GLEntry."User ID" := UserId;
                    GenJnlLine.Correction :=
                      (GLEntry."Debit Amount" < 0) or (GLEntry."Credit Amount" < 0) or
                      (GLEntry."Add.-Currency Debit Amount" < 0) or (GLEntry."Add.-Currency Credit Amount" < 0);
                    GLEntry."Journal Batch Name" := '';
                    GLEntry."Source Code" := GenJnlLine."Source Code";
                    SetReversalDescription(GLEntry2, GLEntry.Description);
                    GLEntry."Reversed Entry No." := "Entry No.";
                    GLEntry.Reversed := true;
                    if ReversalEntry."Corrected Period Date" <> 0D then
                        GLEntry."Posting Date" := ReversalEntry."Posting Date";
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
                    Modify;
                    OnReverseGLEntryOnBeforeInsertGLEntry(GLEntry, GenJnlLine, GLEntry2);
                    GenJnlPostLine.InsertGLEntry(GenJnlLine, GLEntry, false);

                    if GLSetup."Enable Russian Accounting" and (GLEntry.Amount <> 0) then begin
                        GLItemLedgerRelation.Reset();
                        GLItemLedgerRelation.SetRange("G/L Entry No.", "Entry No.");
                        if GLItemLedgerRelation.FindFirst then
                            if ValueEntry.Get(GLItemLedgerRelation."Value Entry No.") then begin
                                GLItemLedgerRelation."G/L Entry No." := GLEntry."Entry No.";
                                GLItemLedgerRelation."Value Entry No." :=
                                  VATAllocationPost.InsertItemReverseEntry(ValueEntry."Entry No.", ReversalEntry2);
                                GLItemLedgerRelation."G/L Register No." := GLReg."No.";
                                GLItemLedgerRelation.Insert();
                            end;
                    end;

                    if GLSetup."Enable Russian Tax Accounting" then begin
                        DetailedCustLedgEntry.SetRange("Tax Diff. Transaction No.", "Transaction No.");
                        if DetailedCustLedgEntry.FindFirst then begin
                            DetailedCustLedgEntry."Tax Diff. Transaction No." := 0;
                            DetailedCustLedgEntry.Modify();
                        end;
                        DetailedVendorLedgEntry.SetRange("Tax Diff. Transaction No.", "Transaction No.");
                        if DetailedVendorLedgEntry.FindFirst then begin
                            DetailedVendorLedgEntry."Tax Diff. Transaction No." := 0;
                            DetailedVendorLedgEntry.Modify();
                        end;
                        TempTaxDiffLedgerEntry.SetRange("Transaction No.", "Transaction No.");
                    end;

                    case true of
                        TempCustLedgEntry.Get("Entry No."):
                            begin
                                CheckDimComb("Entry No.", "Dimension Set ID",
                                  DATABASE::Customer, TempCustLedgEntry."Customer No.",
                                  DATABASE::"Salesperson/Purchaser", TempCustLedgEntry."Salesperson Code");
                                ReverseCustLedgEntry(
                                  TempCustLedgEntry, GLEntry."Entry No.", GenJnlLine.Correction, GenJnlLine."Source Code",
                                  NextDtldCustLedgEntryEntryNo);
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
                                TempVendLedgEntry.Delete();
                            end;
                        TempBankAccLedgEntry.Get("Entry No."):
                            begin
                                CheckDimComb("Entry No.", "Dimension Set ID",
                                  DATABASE::"Bank Account", TempBankAccLedgEntry."Bank Account No.", 0, '');
                                ReverseBankAccLedgEntry(TempBankAccLedgEntry, GLEntry."Entry No.", GenJnlLine."Source Code");
                                TempBankAccLedgEntry.Delete();
                            end;
                        TempTaxDiffLedgerEntry.Find('-'):
                            begin
                                GLSetup.TestField("Enable Russian Tax Accounting");
                                ReverseTaxDiffLedgEntries(TempTaxDiffLedgerEntry, TaxDiffRegister);
                            end;
                    end;

                    if GLSetup."Enable Russian Accounting" then
                        ReverseVATRU(ReversalEntry, GLEntry, GenJnlLine."Source Code")
                    else
                        ReverseVAT(GLEntry, GenJnlLine."Source Code");
                until Next(-1) = 0;

        OnAfterReverseGLEntry(GLEntry);
    end;

    local procedure ReverseCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry"; NewEntryNo: Integer; Correction: Boolean; SourceCode: Code[10]; var NextDtldCustLedgEntryEntryNo: Integer)
    var
        NewCustLedgEntry: Record "Cust. Ledger Entry";
        ReversedCustLedgEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        NewDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        with NewCustLedgEntry do begin
            NewCustLedgEntry := CustLedgEntry;
            "Sales (LCY)" := -"Sales (LCY)";
            "Profit (LCY)" := -"Profit (LCY)";
            "Inv. Discount (LCY)" := -"Inv. Discount (LCY)";
            "Original Pmt. Disc. Possible" := -"Original Pmt. Disc. Possible";
            "Pmt. Disc. Given (LCY)" := -"Pmt. Disc. Given (LCY)";
            Positive := not Positive;
            if not GLSetup."Enable Russian Accounting" then begin
                "Adjusted Currency Factor" := "Adjusted Currency Factor";
                "Original Currency Factor" := "Original Currency Factor";
            end;
            "Remaining Pmt. Disc. Possible" := -"Remaining Pmt. Disc. Possible";
            "Max. Payment Tolerance" := -"Max. Payment Tolerance";
            "Accepted Payment Tolerance" := -"Accepted Payment Tolerance";
            "Pmt. Tolerance (LCY)" := -"Pmt. Tolerance (LCY)";
            "User ID" := UserId;
            "Entry No." := NewEntryNo;
            "Transaction No." := GenJnlPostLine.GetNextTransactionNo;
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
            Insert;

            if NextDtldCustLedgEntryEntryNo = 0 then begin
                DtldCustLedgEntry.FindLast;
                NextDtldCustLedgEntryEntryNo := DtldCustLedgEntry."Entry No." + 1;
            end;
            DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
            DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
            DtldCustLedgEntry.SetRange(Unapplied, false);
            DtldCustLedgEntry.FindSet;
            repeat
                DtldCustLedgEntry.TestField("Entry Type", DtldCustLedgEntry."Entry Type"::"Initial Entry");
                NewDtldCustLedgEntry := DtldCustLedgEntry;
                NewDtldCustLedgEntry.Amount := -NewDtldCustLedgEntry.Amount;
                NewDtldCustLedgEntry."Amount (LCY)" := -NewDtldCustLedgEntry."Amount (LCY)";
                NewDtldCustLedgEntry.UpdateDebitCredit(Correction);
                NewDtldCustLedgEntry."Cust. Ledger Entry No." := NewEntryNo;
                NewDtldCustLedgEntry."User ID" := UserId;
                NewDtldCustLedgEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo;
                NewDtldCustLedgEntry."Entry No." := NextDtldCustLedgEntryEntryNo;
                NextDtldCustLedgEntryEntryNo := NextDtldCustLedgEntryEntryNo + 1;
                OnReverseCustLedgEntryOnBeforeInsertDtldCustLedgEntry(NewDtldCustLedgEntry, DtldCustLedgEntry);
                NewDtldCustLedgEntry.Insert(true);
            until DtldCustLedgEntry.Next = 0;

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
    begin
        with NewVendLedgEntry do begin
            NewVendLedgEntry := VendLedgEntry;
            "Purchase (LCY)" := -"Purchase (LCY)";
            "Inv. Discount (LCY)" := -"Inv. Discount (LCY)";
            "Original Pmt. Disc. Possible" := -"Original Pmt. Disc. Possible";
            "Pmt. Disc. Rcd.(LCY)" := -"Pmt. Disc. Rcd.(LCY)";
            Positive := not Positive;
            if not GLSetup."Enable Russian Accounting" then begin
                "Adjusted Currency Factor" := "Adjusted Currency Factor";
                "Original Currency Factor" := "Original Currency Factor";
            end;
            "Remaining Pmt. Disc. Possible" := -"Remaining Pmt. Disc. Possible";
            "Max. Payment Tolerance" := -"Max. Payment Tolerance";
            "Accepted Payment Tolerance" := -"Accepted Payment Tolerance";
            "Pmt. Tolerance (LCY)" := -"Pmt. Tolerance (LCY)";
            "User ID" := UserId;
            "Entry No." := NewEntryNo;
            "Transaction No." := GenJnlPostLine.GetNextTransactionNo;
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
            Insert;

            if NextDtldVendLedgEntryEntryNo = 0 then begin
                DtldVendLedgEntry.FindLast;
                NextDtldVendLedgEntryEntryNo := DtldVendLedgEntry."Entry No." + 1;
            end;
            DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.");
            DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
            DtldVendLedgEntry.SetRange(Unapplied, false);
            DtldVendLedgEntry.FindSet;
            repeat
                DtldVendLedgEntry.TestField("Entry Type", DtldVendLedgEntry."Entry Type"::"Initial Entry");
                NewDtldVendLedgEntry := DtldVendLedgEntry;
                NewDtldVendLedgEntry.Amount := -NewDtldVendLedgEntry.Amount;
                NewDtldVendLedgEntry."Amount (LCY)" := -NewDtldVendLedgEntry."Amount (LCY)";
                NewDtldVendLedgEntry.UpdateDebitCredit(Correction);
                NewDtldVendLedgEntry."Vendor Ledger Entry No." := NewEntryNo;
                NewDtldVendLedgEntry."User ID" := UserId;
                NewDtldVendLedgEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo;
                NewDtldVendLedgEntry."Entry No." := NextDtldVendLedgEntryEntryNo;
                NextDtldVendLedgEntryEntryNo := NextDtldVendLedgEntryEntryNo + 1;
                OnReverseVendLedgEntryOnBeforeInsertDtldVendLedgEntry(NewDtldVendLedgEntry, DtldVendLedgEntry);
                NewDtldVendLedgEntry.Insert(true);
            until DtldVendLedgEntry.Next = 0;

            ApplyVendLedgEntryByReversal(
              VendLedgEntry, NewVendLedgEntry, NewDtldVendLedgEntry, "Entry No.", NextDtldVendLedgEntryEntryNo);
            ApplyVendLedgEntryByReversal(
              NewVendLedgEntry, VendLedgEntry, DtldVendLedgEntry, "Entry No.", NextDtldVendLedgEntryEntryNo);
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
            "User ID" := UserId;
            "Entry No." := NewEntryNo;
            "Transaction No." := GenJnlPostLine.GetNextTransactionNo;
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
            OnReverseBankAccLedgEntryOnBeforeInsert(NewBankAccLedgEntry, BankAccLedgEntry);
            Insert;
        end;
    end;

    local procedure ReverseVAT(GLEntry: Record "G/L Entry"; SourceCode: Code[10])
    var
        VATEntry: Record "VAT Entry";
        NewVATEntry: Record "VAT Entry";
        ReversedVATEntry: Record "VAT Entry";
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
    begin
        GLEntryVATEntryLink.SetRange("G/L Entry No.", GLEntry."Reversed Entry No.");
        if GLEntryVATEntryLink.FindSet then
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
                    "Transaction No." := GenJnlPostLine.GetNextTransactionNo;
                    "Source Code" := SourceCode;
                    Positive := Amount > 0;
                    "User ID" := UserId;
                    "Entry No." := GenJnlPostLine.GetNextVATEntryNo;
                    "Reversed Entry No." := VATEntry."Entry No.";
                    Reversed := true;
                    // Reversal of Reversal
                    if VATEntry."Reversed Entry No." <> 0 then begin
                        ReversedVATEntry.Get(VATEntry."Reversed Entry No.");
                        ReversedVATEntry."Reversed by Entry No." := 0;
                        ReversedVATEntry.Reversed := false;
                        ReversedVATEntry.Modify();
                        VATEntry."Reversed Entry No." := "Entry No.";
                        "Reversed by Entry No." := VATEntry."Entry No.";
                    end;
                    VATEntry."Reversed by Entry No." := "Entry No.";
                    VATEntry.Reversed := true;
                    VATEntry.Modify();
                    OnReverseVATEntryOnBeforeInsert(NewVATEntry, VATEntry);
                    Insert;
                    GLEntryVATEntryLink.InsertLink(GLEntry."Entry No.", "Entry No.");
                    GenJnlPostLine.IncrNextVATEntryNo;
                end;
            until GLEntryVATEntryLink.Next = 0;
    end;

    local procedure ApplyCustLedgEntryByReversal(CustLedgEntry: Record "Cust. Ledger Entry"; CustLedgEntry2: Record "Cust. Ledger Entry"; DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; AppliedEntryNo: Integer; var NextDtldCustLedgEntryEntryNo: Integer)
    var
        NewDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
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

        NewDtldCustLedgEntry := DtldCustLedgEntry2;
        NewDtldCustLedgEntry."Cust. Ledger Entry No." := CustLedgEntry."Entry No.";
        NewDtldCustLedgEntry."Entry Type" := NewDtldCustLedgEntry."Entry Type"::Application;
        NewDtldCustLedgEntry."Applied Cust. Ledger Entry No." := AppliedEntryNo;
        NewDtldCustLedgEntry."User ID" := UserId;
        NewDtldCustLedgEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo;
        NewDtldCustLedgEntry."Entry No." := NextDtldCustLedgEntryEntryNo;
        NextDtldCustLedgEntryEntryNo := NextDtldCustLedgEntryEntryNo + 1;
        OnApplyCustLedgEntryByReversalOnBeforeInsertDtldCustLedgEntry(NewDtldCustLedgEntry, DtldCustLedgEntry2);
        NewDtldCustLedgEntry.Insert(true);
    end;

    local procedure ApplyVendLedgEntryByReversal(VendLedgEntry: Record "Vendor Ledger Entry"; VendLedgEntry2: Record "Vendor Ledger Entry"; DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry"; AppliedEntryNo: Integer; var NextDtldVendLedgEntryEntryNo: Integer)
    var
        NewDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
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

        NewDtldVendLedgEntry := DtldVendLedgEntry2;
        NewDtldVendLedgEntry."Vendor Ledger Entry No." := VendLedgEntry."Entry No.";
        NewDtldVendLedgEntry."Entry Type" := NewDtldVendLedgEntry."Entry Type"::Application;
        NewDtldVendLedgEntry."Applied Vend. Ledger Entry No." := AppliedEntryNo;
        NewDtldVendLedgEntry."User ID" := UserId;
        NewDtldVendLedgEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo;
        NewDtldVendLedgEntry."Entry No." := NextDtldVendLedgEntryEntryNo;
        NextDtldVendLedgEntryEntryNo := NextDtldVendLedgEntryEntryNo + 1;
        OnApplyVendLedgEntryByReversalOnBeforeInsertDtldVendLedgEntry(NewDtldVendLedgEntry, DtldVendLedgEntry2);
        NewDtldVendLedgEntry.Insert(true);
    end;

    local procedure CheckDimComb(EntryNo: Integer; DimSetID: Integer; TableID1: Integer; AccNo1: Code[20]; TableID2: Integer; AccNo2: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        AccNo: array[10] of Code[20];
    begin
        if not DimMgt.CheckDimIDComb(DimSetID) then
            Error(DimCombBlockedErr, EntryNo, DimMgt.GetDimCombErr);
        Clear(TableID);
        Clear(AccNo);
        TableID[1] := TableID1;
        AccNo[1] := AccNo1;
        TableID[2] := TableID2;
        AccNo[2] := AccNo2;
        if not DimMgt.CheckDimValuePosting(TableID, AccNo, DimSetID) then
            Error(DimMgt.GetDimValuePostingErr);
    end;

    local procedure CopyCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; var TempCustLedgEntry: Record "Cust. Ledger Entry" temporary)
    begin
        if CustLedgEntry.FindSet then
            repeat
                if CustLedgEntry."Reversed by Entry No." <> 0 then
                    Error(CannotReverseErr);
                TempCustLedgEntry := CustLedgEntry;
                TempCustLedgEntry.Insert();
            until CustLedgEntry.Next = 0;
    end;

    local procedure CopyVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; var TempVendLedgEntry: Record "Vendor Ledger Entry" temporary)
    begin
        if VendLedgEntry.FindSet then
            repeat
                if VendLedgEntry."Reversed by Entry No." <> 0 then
                    Error(CannotReverseErr);
                TempVendLedgEntry := VendLedgEntry;
                TempVendLedgEntry.Insert();
            until VendLedgEntry.Next = 0;
    end;

    local procedure CopyBankAccLedgEntry(var BankAccLedgEntry: Record "Bank Account Ledger Entry"; var TempBankAccLedgEntry: Record "Bank Account Ledger Entry" temporary)
    begin
        if BankAccLedgEntry.FindSet then
            repeat
                if BankAccLedgEntry."Reversed by Entry No." <> 0 then
                    Error(CannotReverseErr);
                TempBankAccLedgEntry := BankAccLedgEntry;
                TempBankAccLedgEntry.Insert();
            until BankAccLedgEntry.Next = 0;
    end;

    procedure SetReversalDescription(RecVar: Variant; var Description: Text[100])
    var
        ReversalEntry: Record "Reversal Entry";
    begin
        FilterReversalEntry(ReversalEntry, RecVar);
        if ReversalEntry.FindFirst then
            Description := ReversalEntry.Description;
    end;

    local procedure GetTransactionKey(): Integer
    var
        ReversalEntry: Record "Reversal Entry";
    begin
        ReversalEntry.SetCurrentKey("Transaction No.");
        ReversalEntry.SetFilter("Transaction No.", '<%1', 0);
        if ReversalEntry.FindFirst then;
        exit(ReversalEntry."Transaction No." - 1);
    end;

    local procedure GetRegisterNoForTransactionReversal(var ReversalEntry: Record "Reversal Entry"): Integer
    var
        GLRegister: Record "G/L Register";
    begin
        GLRegister.SetCurrentKey("To Entry No.");
        GLRegister.SetRange("To Entry No.", ReversalEntry."Entry No.");
        if GLRegister.FindFirst then;
        exit(GLRegister."No.");
    end;

    local procedure FilterReversalEntry(var ReversalEntry: Record "Reversal Entry"; RecVar: Variant)
    var
        GLEntry: Record "G/L Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
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
    begin
        if TempReversalEntry.FindSet then
            repeat
                ReversalEntry := TempReversalEntry;
                ReversalEntry."Transaction No." := TransactionKey;
                ReversalEntry.Insert();
            until TempReversalEntry.Next = 0;
    end;

    local procedure DeleteReversalEntries(TransactionKey: Integer)
    var
        ReversalEntry: Record "Reversal Entry";
    begin
        ReversalEntry.SetRange("Transaction No.", TransactionKey);
        ReversalEntry.DeleteAll();
    end;

    local procedure CopyValueEntry(var ValueEntry: Record "Value Entry"; var TempValueEntry: Record "Value Entry" temporary)
    begin
        if ValueEntry.Find('-') then
            repeat
                if ValueEntry.Reversed then
                    Error(CannotReverseErr);
                TempValueEntry := ValueEntry;
                TempValueEntry.Insert();
            until ValueEntry.Next(1) = 0;
    end;

    local procedure CopyTaxDiffLedgEntry(var TaxDiffLedgEntry: Record "Tax Diff. Ledger Entry"; var TempTaxDiffLedgEntry: Record "Tax Diff. Ledger Entry" temporary)
    begin
        if TaxDiffLedgEntry.FindSet then
            repeat
                if TaxDiffLedgEntry.Reversed then
                    Error(CannotReverseErr);
                TempTaxDiffLedgEntry := TaxDiffLedgEntry;
                TempTaxDiffLedgEntry.Insert();
            until TaxDiffLedgEntry.Next(1) = 0;
    end;

    local procedure ReverseVATRU(ReversalEntry: Record "Reversal Entry"; GLEntry: Record "G/L Entry"; SourceCode: Code[10])
    var
        VATEntry: Record "VAT Entry";
        NewVATEntry: Record "VAT Entry";
        ReversedVATEntry: Record "VAT Entry";
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry" temporary;
        VATEntry2: Record "VAT Entry" temporary;
        CustLedgEntry: Record "Cust. Ledger Entry";
        SalesInvLine: Record "Sales Invoice Line";
    begin
        DtldCustLedgEntry2.Reset();
        DtldCustLedgEntry2.DeleteAll();
        VATEntry2.Reset();
        VATEntry2.DeleteAll();
        GLEntryVATEntryLink.SetRange("G/L Entry No.", GLEntry."Reversed Entry No.");
        if GLEntryVATEntryLink.FindSet then
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
                    "Transaction No." := GenJnlPostLine.GetNextTransactionNo;
                    "Source Code" := SourceCode;
                    Positive := Amount > 0;
                    "User ID" := UserId;
                    "Entry No." := GenJnlPostLine.GetNextVATEntryNo;
                    "Reversed Entry No." := VATEntry."Entry No.";
                    Reversed := true;
                    // Reversal of Reversal
                    if VATEntry."Reversed Entry No." <> 0 then begin
                        ReversedVATEntry.Get(VATEntry."Reversed Entry No.");
                        ReversedVATEntry."Reversed by Entry No." := 0;
                        ReversedVATEntry.Reversed := false;
                        ReversedVATEntry.Modify();
                        VATEntry."Reversed Entry No." := "Entry No.";
                        "Reversed by Entry No." := VATEntry."Entry No.";
                    end;
                    VATEntry."Reversed by Entry No." := "Entry No.";
                    VATEntry.Reversed := true;
                    VATEntry.Modify();
                    if ReversalEntry."Corrected Period Date" <> 0D then begin
                        "Corrected Document Date" := ReversalEntry."Corrected Period Date";
                        "Additional VAT Ledger Sheet" := true;
                        "Posting Date" := ReversalEntry."Posting Date";
                    end;
                    Insert;
                    GLEntryVATEntryLink.InsertLink(GLEntry."Entry No.", "Entry No.");
                    GenJnlPostLine.IncrNextVATEntryNo;
                    if VATEntry."Unrealized VAT Entry No." <> 0 then begin
                        Get(VATEntry."Unrealized VAT Entry No.");
                        "Remaining Unrealized Amount" := "Remaining Unrealized Amount" + VATEntry.Amount;
                        "Remaining Unrealized Base" := "Remaining Unrealized Base" + VATEntry.Base;
                        "Add.-Curr. Rem. Unreal. Amount" := "Add.-Curr. Rem. Unreal. Amount" + VATEntry."Additional-Currency Amount";
                        "Add.-Curr. Rem. Unreal. Base" := "Add.-Curr. Rem. Unreal. Base" + VATEntry."Additional-Currency Base";
                        "VAT Settlement Part" := VATSettlementMgt.GetPart(VATEntry."Unrealized VAT Entry No.");
                        Modify;
                    end;
                end;
            until GLEntryVATEntryLink.Next = 0;
    end;

    local procedure ReverseTaxDiffLedgEntries(var TmpTaxDiffLedgEntry: Record "Tax Diff. Ledger Entry"; var TaxDiffRegister: Record "Tax Diff. Register")
    var
        TaxDiffLedgEntry: Record "Tax Diff. Ledger Entry";
        NewTaxDiffLedgEntry: Record "Tax Diff. Ledger Entry";
    begin
        with TaxDiffLedgEntry do
            repeat
                Get(TmpTaxDiffLedgEntry."Entry No.");
                NewTaxDiffLedgEntry.Reset();
                if not NewTaxDiffLedgEntry.Find('+') then
                    NewTaxDiffLedgEntry."Entry No." := 0;
                NewTaxDiffLedgEntry."Entry No." += 1;

                NewTaxDiffLedgEntry.TransferFields(TaxDiffLedgEntry, false);
                ReverseDeprBonusRecover;

                Reversed := true;
                "Reversed by Entry No." := NewTaxDiffLedgEntry."Entry No.";
                Modify;

                with TaxDiffRegister do begin
                    if "No." = 0 then begin
                        LockTable();
                        if Find('+') then
                            "No." := "No." + 1;
                        Init;
                        "From Entry No." := NewTaxDiffLedgEntry."Entry No.";
                        "Creation Date" := Today;
                        "Journal Batch Name" := NewTaxDiffLedgEntry."Journal Batch Name";
                        "User ID" := UserId;
                        Insert;
                    end;
                    "To Entry No." := NewTaxDiffLedgEntry."Entry No.";
                    Modify;
                end;

                NewTaxDiffLedgEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo;
                NewTaxDiffLedgEntry."Amount (Base)" := -"Amount (Base)";
                NewTaxDiffLedgEntry."Amount (Tax)" := -"Amount (Tax)";
                NewTaxDiffLedgEntry.Difference := -Difference;
                NewTaxDiffLedgEntry."Tax Amount" := -"Tax Amount";
                NewTaxDiffLedgEntry."Asset Tax Amount" := -"Asset Tax Amount";
                NewTaxDiffLedgEntry."Liability Tax Amount" := -"Liability Tax Amount";
                NewTaxDiffLedgEntry."Disposal Tax Amount" := -"Disposal Tax Amount";
                if NewTaxDiffLedgEntry."Partial Disposal" then begin
                    NewTaxDiffLedgEntry."DTA Ending Balance" := -"DTA Ending Balance";
                    NewTaxDiffLedgEntry."DTL Ending Balance" := -"DTL Ending Balance";
                end else begin
                    NewTaxDiffLedgEntry."DTA Starting Balance" := "DTA Ending Balance";
                    NewTaxDiffLedgEntry."DTL Starting Balance" := "DTL Ending Balance";
                    NewTaxDiffLedgEntry."DTA Ending Balance" := "DTA Starting Balance";
                    NewTaxDiffLedgEntry."DTL Ending Balance" := "DTL Starting Balance";
                end;
                NewTaxDiffLedgEntry."YTD Amount (Base)" := -"YTD Amount (Base)";
                NewTaxDiffLedgEntry."YTD Amount (Tax)" := -"YTD Amount (Tax)";
                NewTaxDiffLedgEntry."YTD Difference" := -"YTD Difference";

                NewTaxDiffLedgEntry.Reversed := true;
                NewTaxDiffLedgEntry."Reversed Entry No." := "Entry No.";
                NewTaxDiffLedgEntry.Insert();
                TmpTaxDiffLedgEntry.Delete();
            until TmpTaxDiffLedgEntry.Next(1) = 0;
    end;

    local procedure InsertReverseTaxEntry(var FAInsertLedgEntry: Codeunit "FA Insert Ledger Entry"; GLEntryNo: Integer; NewGLEntryNo: Integer; FAEntryType: Option; FAEntryNo: Integer; var NewFAEntryNo: Integer; TransactionNo: Integer)
    var
        FALedgEntryLoc: Record "FA Ledger Entry";
        TaxRegSetup: Record "Tax Register Setup";
    begin
        TaxRegSetup.Get();
        with FALedgEntryLoc do begin
            SetCurrentKey("G/L Entry No.");
            SetRange("G/L Entry No.", GLEntryNo);
            if Find('-') then
                repeat
                    if ("Entry No." <> FAEntryNo) and ("Depreciation Book Code" = TaxRegSetup."Tax Depreciation Book") then
                        FAInsertLedgEntry.InsertReverseEntry(NewGLEntryNo, FAEntryType, "Entry No.", NewFAEntryNo, TransactionNo);
                until Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure PostVATSettlementReverse(GenJnlLine: Record "Gen. Journal Line")
    var
        GLEntry: Record "G/L Entry";
        ReversalEntry: Record "Reversal Entry" temporary;
        UnrealizedVATEntry: Record "VAT Entry";
        SettledVATEntry: Record "VAT Entry";
        NextLineNo: Integer;
        FirstEntryNo: Integer;
        LastEntryNo: Integer;
        RecordFound: Boolean;
    begin
        GenJnlLine.TestField("Unrealized VAT Entry No.");

        UnrealizedVATEntry.Get(GenJnlLine."Unrealized VAT Entry No.");

        GLEntry.SetCurrentKey("Transaction No.");
        GLEntry.SetRange("Transaction No.", GenJnlLine."VAT Transaction No.");
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice, GLEntry."Document Type"::"Credit Memo");

        FirstEntryNo := -1;
        LastEntryNo := -1;

        SettledVATEntry.SetCurrentKey("Transaction No.");
        SettledVATEntry.SetRange("Transaction No.", GenJnlLine."VAT Transaction No.");
        if SettledVATEntry.Find('-') then
            repeat
                if (SettledVATEntry.Base <> 0) and (SettledVATEntry.Amount <> 0) then begin
                    if GLEntry."Entry No." = 0 then
                        RecordFound := GLEntry.FindFirst
                    else
                        RecordFound := GLEntry.Next <> 0;

                    if RecordFound then
                        if (GLEntry.Amount = 0) and (GLEntry."Additional-Currency Amount" = 0) then
                            RecordFound := GLEntry.Next <> 0;

                    if RecordFound then
                        if SettledVATEntry."Entry No." = UnrealizedVATEntry."Entry No." then
                            if (GLEntry."Entry No." <> 0) and (not GLEntry.Reversed) then
                                FirstEntryNo := GLEntry."Entry No.";

                    if (GLEntry.Amount <> 0) or (GLEntry."Additional-Currency Amount" <> 0) then begin
                        RecordFound := GLEntry.Next <> 0;
                        if RecordFound then
                            if SettledVATEntry."Entry No." = UnrealizedVATEntry."Entry No." then
                                if (GLEntry."Entry No." <> 0) and (not GLEntry.Reversed) then
                                    LastEntryNo := GLEntry."Entry No.";
                    end;
                end;
            until SettledVATEntry.Next = 0;

        ReversalEntry."Corrected Period Date" := GenJnlLine."Corrected Document Date";
        ReversalEntry."Posting Date" := GenJnlLine."Posting Date";
        ReversalEntry.SetVATSettlReverseFilters(UnrealizedVATEntry."Entry No.", FirstEntryNo, LastEntryNo);
        Reverse(ReversalEntry, ReversalEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterReversalEntry(var ReversalEntry: Record "Reversal Entry"; RecVar: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostReverse(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReverse(GLRegister: Record "G/L Register")
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
    local procedure OnReverseGLEntryOnBeforeInsertGLEntry(var GLEntry: Record "G/L Entry"; GenJnlLine: Record "Gen. Journal Line"; GLEntry2: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseGLEntryOnBeforeLoop(var GLEntry: Record "G/L Entry"; var GenJournalLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseCustLedgEntryOnBeforeInsertCustLedgEntry(var NewCustLedgerEntry: Record "Cust. Ledger Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseVendLedgEntryOnBeforeInsertVendLedgEntry(var NewVendLedgEntry: Record "Vendor Ledger Entry"; VendLedgEntry: Record "Vendor Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseBankAccLedgEntryOnBeforeInsert(var NewBankAccLedgEntry: Record "Bank Account Ledger Entry"; BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseCustLedgEntryOnBeforeInsertDtldCustLedgEntry(var NewDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseVendLedgEntryOnBeforeInsertDtldVendLedgEntry(var NewDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseVATEntryOnBeforeInsert(var NewVATEntry: Record "VAT Entry"; VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseOnBeforeFinishPosting(var ReversalEntry: Record "Reversal Entry"; var ReversalEntry2: Record "Reversal Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var GLRegister: Record "G/L Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseOnBeforeStartPosting(var GenJournalLine: Record "Gen. Journal Line"; var ReversalEntry: Record "Reversal Entry"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgEntryByReversalOnBeforeInsertDtldCustLedgEntry(var NewDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendLedgEntryByReversalOnBeforeInsertDtldVendLedgEntry(var NewDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
    end;
}

