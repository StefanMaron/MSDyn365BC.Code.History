codeunit 5632 "FA Jnl.-Post Line"
{
    Permissions = TableData "FA Ledger Entry" = r,
                  TableData "FA Register" = rm,
                  TableData "Maintenance Ledger Entry" = r,
                  TableData "Ins. Coverage Ledger Entry" = r;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label '%2 must not be %3 in %4 %5 = %6 for %1.';
        Text001: Label '%2 = %3 must be canceled first for %1.';
        Text002: Label '%1 is not a %2.';
        FA: Record "Fixed Asset";
        FA2: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FALedgEntry: Record "FA Ledger Entry";
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        FAInsertLedgEntry: Codeunit "FA Insert Ledger Entry";
        FAJnlCheckLine: Codeunit "FA Jnl.-Check Line";
        DuplicateDeprBook: Codeunit "Duplicate Depr. Book";
        CalculateDisposal: Codeunit "Calculate Disposal";
        CalculateDepr: Codeunit "Calculate Depreciation";
        CalculateAcqCostDepr: Codeunit "Calculate Acq. Cost Depr.";
        MakeFALedgEntry: Codeunit "Make FA Ledger Entry";
        MakeMaintenanceLedgEntry: Codeunit "Make Maintenance Ledger Entry";
        FANo: Code[20];
        BudgetNo: Code[20];
        DeprBookCode: Code[10];
        FAPostingType: Enum "FA Journal Line FA Posting Type";
        FAPostingDate: Date;
        Amount2: Decimal;
        SalvageValue: Decimal;
        DeprUntilDate: Boolean;
        DeprAcqCost: Boolean;
        ErrorEntryNo: Integer;
        ResultOnDisposal: Integer;
        Text003: Label '%1 = %2 already exists for %5 (%3 = %4).';

    procedure FAJnlPostLine(FAJnlLine: Record "FA Journal Line"; CheckLine: Boolean)
    begin
        OnBeforeFAJnlPostLine(FAJnlLine);

        FAInsertLedgEntry.SetGLRegisterNo(0);
        with FAJnlLine do begin
            if "FA No." = '' then
                exit;
            if "Posting Date" = 0D then
                "Posting Date" := "FA Posting Date";
            if CheckLine then
                FAJnlCheckLine.CheckFAJnlLine(FAJnlLine);
            DuplicateDeprBook.DuplicateFAJnlLine(FAJnlLine);
            FANo := "FA No.";
            BudgetNo := "Budgeted FA No.";
            DeprBookCode := "Depreciation Book Code";
            FAPostingType := "FA Posting Type";
            FAPostingDate := "FA Posting Date";
            Amount2 := Amount;
            SalvageValue := "Salvage Value";
            DeprUntilDate := "Depr. until FA Posting Date";
            DeprAcqCost := "Depr. Acquisition Cost";
            ErrorEntryNo := "FA Error Entry No.";
            if "FA Posting Type" = "FA Posting Type"::Maintenance then begin
                MakeMaintenanceLedgEntry.CopyFromFAJnlLine(MaintenanceLedgEntry, FAJnlLine);
                PostMaintenance;
            end else begin
                MakeFALedgEntry.CopyFromFAJnlLine(FALedgEntry, FAJnlLine);
                PostFixedAsset;
            end;
        end;

        OnAfterFAJnlPostLine(FAJnlLine);
    end;

    procedure GenJnlPostLine(GenJnlLine: Record "Gen. Journal Line"; FAAmount: Decimal; VATAmount: Decimal; NextTransactionNo: Integer; NextGLEntryNo: Integer; GLRegisterNo: Integer)
    begin
        OnBeforeGenJnlPostLine(GenJnlLine);

        FAInsertLedgEntry.SetGLRegisterNo(GLRegisterNo);
        FAInsertLedgEntry.DeleteAllGLAcc;
        with GenJnlLine do begin
            if "Account No." = '' then
                exit;
            if "FA Posting Date" = 0D then
                "FA Posting Date" := "Posting Date";
            if "Journal Template Name" = '' then
                Quantity := 0;
            DuplicateDeprBook.DuplicateGenJnlLine(GenJnlLine, FAAmount);
            FANo := "Account No.";
            BudgetNo := "Budgeted FA No.";
            DeprBookCode := "Depreciation Book Code";
            FAPostingType := "FA Posting Type" - 1;
            FAPostingDate := "FA Posting Date";
            Amount2 := FAAmount;
            SalvageValue := ConvertAmtFCYToLCYForSourceCurrency("Salvage Value");
            DeprUntilDate := "Depr. until FA Posting Date";
            DeprAcqCost := "Depr. Acquisition Cost";
            ErrorEntryNo := "FA Error Entry No.";
            if "FA Posting Type" = "FA Posting Type"::Maintenance then begin
                MakeMaintenanceLedgEntry.CopyFromGenJnlLine(MaintenanceLedgEntry, GenJnlLine);
                MaintenanceLedgEntry.Amount := FAAmount;
                MaintenanceLedgEntry."VAT Amount" := VATAmount;
                MaintenanceLedgEntry."Transaction No." := NextTransactionNo;
                MaintenanceLedgEntry."G/L Entry No." := NextGLEntryNo;
                PostMaintenance;
            end else begin
                MakeFALedgEntry.CopyFromGenJnlLine(FALedgEntry, GenJnlLine);
                FALedgEntry.Amount := FAAmount;
                FALedgEntry."VAT Amount" := VATAmount;
                FALedgEntry."Transaction No." := NextTransactionNo;
                FALedgEntry."G/L Entry No." := NextGLEntryNo;
                OnBeforePostFixedAssetFromGenJnlLine(GenJnlLine, FALedgEntry, FAAmount, VATAmount);
                PostFixedAsset;
            end;
        end;

        OnAfterGenJnlPostLine(GenJnlLine);
    end;

    local procedure PostFixedAsset()
    begin
        FA.LockTable();
        DeprBook.Get(DeprBookCode);
        FA.Get(FANo);
        FA.TestField(Blocked, false);
        FA.TestField(Inactive, false);
        FADeprBook.Get(FANo, DeprBookCode);
        MakeFALedgEntry.CopyFromFACard(FALedgEntry, FA, FADeprBook);
        FAInsertLedgEntry.SetLastEntryNo(true);
        if (FALedgEntry."FA Posting Group" = '') and (FALedgEntry."G/L Entry No." > 0) then begin
            FADeprBook.TestField("FA Posting Group");
            FALedgEntry."FA Posting Group" := FADeprBook."FA Posting Group";
        end;
        if DeprUntilDate then
            PostDeprUntilDate(FALedgEntry, 0);
        if FAPostingType = FAPostingType::Disposal then
            PostDisposalEntry(FALedgEntry)
        else begin
            if PostBudget then
                SetBudgetAssetNo;
            if not DeprLine then begin
                FAInsertLedgEntry.SetOrgGenJnlLine(true);
                FAInsertLedgEntry.InsertFA(FALedgEntry);
                FAInsertLedgEntry.SetOrgGenJnlLine(false);
            end;
            PostSalvageValue(FALedgEntry);
        end;
        if DeprAcqCost then
            PostDeprUntilDate(FALedgEntry, 1);
        FAInsertLedgEntry.SetLastEntryNo(false);
        if PostBudget then
            PostBudgetAsset;
    end;

    local procedure PostMaintenance()
    begin
        FA.LockTable();
        DeprBook.Get(DeprBookCode);
        FA.Get(FANo);
        FADeprBook.Get(FANo, DeprBookCode);
        MakeMaintenanceLedgEntry.CopyFromFACard(MaintenanceLedgEntry, FA, FADeprBook);
        if not DeprBook."Allow Identical Document No." and (MaintenanceLedgEntry."Journal Batch Name" <> '') then
            CheckMaintDocNo(MaintenanceLedgEntry);
        with MaintenanceLedgEntry do
            if ("FA Posting Group" = '') and ("G/L Entry No." > 0) then begin
                FADeprBook.TestField("FA Posting Group");
                "FA Posting Group" := FADeprBook."FA Posting Group";
            end;
        if PostBudget then
            SetBudgetAssetNo;
        FAInsertLedgEntry.SetOrgGenJnlLine(true);
        FAInsertLedgEntry.InsertMaintenance(MaintenanceLedgEntry);
        FAInsertLedgEntry.SetOrgGenJnlLine(false);
        if PostBudget then
            PostBudgetAsset;
    end;

    local procedure PostDisposalEntry(var FALedgEntry: Record "FA Ledger Entry")
    var
        MaxDisposalNo: Integer;
        SalesEntryNo: Integer;
        DisposalType: Option FirstDisposal,SecondDisposal,ErrorDisposal,LastErrorDisposal;
        OldDisposalMethod: Option " ",Net,Gross;
        EntryAmounts: array[14] of Decimal;
        EntryNumbers: array[14] of Integer;
        i: Integer;
        j: Integer;
    begin
        with FALedgEntry do begin
            "Disposal Calculation Method" := DeprBook."Disposal Calculation Method" + 1;
            CalculateDisposal.GetDisposalType(
              FANo, DeprBookCode, ErrorEntryNo, DisposalType,
              OldDisposalMethod, MaxDisposalNo, SalesEntryNo);
            if (MaxDisposalNo > 0) and
               ("Disposal Calculation Method" <> OldDisposalMethod)
            then
                Error(
                  Text000,
                  FAName, DeprBook.FieldCaption("Disposal Calculation Method"), "Disposal Calculation Method",
                  DeprBook.TableCaption, DeprBook.FieldCaption(Code), DeprBook.Code);
            if ErrorEntryNo = 0 then
                "Disposal Entry No." := MaxDisposalNo + 1
            else
                if SalesEntryNo <> ErrorEntryNo then
                    Error(Text001,
                      FAName, FieldCaption("Disposal Entry No."), MaxDisposalNo);
            if DisposalType = DisposalType::FirstDisposal then
                PostReverseType(FALedgEntry);
            if DeprBook."Disposal Calculation Method" = DeprBook."Disposal Calculation Method"::Gross then
                FAInsertLedgEntry.SetOrgGenJnlLine(true);
            FAInsertLedgEntry.InsertFA(FALedgEntry);
            FAInsertLedgEntry.SetOrgGenJnlLine(false);
            "Automatic Entry" := true;
            FAInsertLedgEntry.SetNetdisposal(false);
            if (DeprBook."Disposal Calculation Method" =
                DeprBook."Disposal Calculation Method"::Net) and
               DeprBook."VAT on Net Disposal Entries"
            then
                FAInsertLedgEntry.SetNetdisposal(true);

            if DisposalType = DisposalType::FirstDisposal then begin
                CalculateDisposal.CalcGainLoss(FANo, DeprBookCode, EntryAmounts);
                for i := 1 to 14 do
                    if EntryAmounts[i] <> 0 then begin
                        "FA Posting Category" := CalculateDisposal.SetFAPostingCategory(i);
                        "FA Posting Type" := CalculateDisposal.SetFAPostingType(i);
                        Amount := EntryAmounts[i];
                        if i = 1 then
                            "Result on Disposal" := "Result on Disposal"::Gain;
                        if i = 2 then
                            "Result on Disposal" := "Result on Disposal"::Loss;
                        if i > 2 then
                            "Result on Disposal" := "Result on Disposal"::" ";
                        if i = 10 then
                            SetResultOnDisposal(FALedgEntry);
                        FAInsertLedgEntry.InsertFA(FALedgEntry);
                        PostAllocation(FALedgEntry);
                    end;
            end;
            if DisposalType = DisposalType::SecondDisposal then begin
                CalculateDisposal.CalcSecondGainLoss(FANo, DeprBookCode, Amount, EntryAmounts);
                for i := 1 to 2 do
                    if EntryAmounts[i] <> 0 then begin
                        "FA Posting Category" := CalculateDisposal.SetFAPostingCategory(i);
                        "FA Posting Type" := CalculateDisposal.SetFAPostingType(i);
                        Amount := EntryAmounts[i];
                        if i = 1 then
                            "Result on Disposal" := "Result on Disposal"::Gain;
                        if i = 2 then
                            "Result on Disposal" := "Result on Disposal"::Loss;
                        FAInsertLedgEntry.InsertFA(FALedgEntry);
                        PostAllocation(FALedgEntry);
                    end;
            end;
            if DisposalType in
               [DisposalType::ErrorDisposal, DisposalType::LastErrorDisposal]
            then begin
                CalculateDisposal.GetErrorDisposal(
                  FANo, DeprBookCode, DisposalType = DisposalType::ErrorDisposal, MaxDisposalNo,
                  EntryAmounts, EntryNumbers);
                if DisposalType = DisposalType::ErrorDisposal then
                    j := 2
                else begin
                    j := 14;
                    ResultOnDisposal := CalcResultOnDisposal(FANo, DeprBookCode);
                end;
                for i := 1 to j do
                    if EntryNumbers[i] <> 0 then begin
                        Amount := EntryAmounts[i];
                        "Entry No." := EntryNumbers[i];
                        "FA Posting Category" := CalculateDisposal.SetFAPostingCategory(i);
                        "FA Posting Type" := CalculateDisposal.SetFAPostingType(i);
                        if i = 1 then
                            "Result on Disposal" := "Result on Disposal"::Gain;
                        if i = 2 then
                            "Result on Disposal" := "Result on Disposal"::Loss;
                        if i > 2 then
                            "Result on Disposal" := "Result on Disposal"::" ";
                        if i = 10 then
                            "Result on Disposal" := ResultOnDisposal;
                        FAInsertLedgEntry.InsertFA(FALedgEntry);
                        PostAllocation(FALedgEntry);
                    end;
            end;
            FAInsertLedgEntry.CorrectEntries;
            FAInsertLedgEntry.SetNetdisposal(false);
        end;
    end;

    local procedure PostDeprUntilDate(FALedgEntry: Record "FA Ledger Entry"; Type: Option UntilDate,AcqCost)
    var
        DepreciationAmount: Decimal;
        Custom1Amount: Decimal;
        NumberOfDays: Integer;
        Custom1NumberOfDays: Integer;
        DummyEntryAmounts: array[4] of Decimal;
    begin
        with FALedgEntry do begin
            "Automatic Entry" := true;
            "FA No./Budgeted FA No." := '';
            "FA Posting Category" := "FA Posting Category"::" ";
            "No. of Depreciation Days" := 0;
            if Type = Type::UntilDate then
                CalculateDepr.Calculate(
                  DepreciationAmount, Custom1Amount, NumberOfDays, Custom1NumberOfDays,
                  FANo, DeprBookCode, FAPostingDate, DummyEntryAmounts, 0D, 0)
            else
                CalculateAcqCostDepr.DeprCalc(
                  DepreciationAmount, Custom1Amount, FANo, DeprBookCode,
                  Amount2 + SalvageValue, Amount2);
            if Custom1Amount <> 0 then begin
                "FA Posting Type" := "FA Posting Type"::"Custom 1";
                Amount := Custom1Amount;
                "No. of Depreciation Days" := Custom1NumberOfDays;
                FAInsertLedgEntry.InsertFA(FALedgEntry);
                if "G/L Entry No." > 0 then
                    FAInsertLedgEntry.InsertBalAcc(FALedgEntry);
            end;
            if DepreciationAmount <> 0 then begin
                "FA Posting Type" := "FA Posting Type"::Depreciation;
                Amount := DepreciationAmount;
                "No. of Depreciation Days" := NumberOfDays;
                FAInsertLedgEntry.InsertFA(FALedgEntry);
                if "G/L Entry No." > 0 then
                    FAInsertLedgEntry.InsertBalAcc(FALedgEntry);
            end;
        end;
    end;

    local procedure PostSalvageValue(FALedgEntry: Record "FA Ledger Entry")
    begin
        if (SalvageValue = 0) or (FAPostingType <> FAPostingType::"Acquisition Cost") then
            exit;
        with FALedgEntry do begin
            "Entry No." := 0;
            "Automatic Entry" := true;
            Amount := SalvageValue;
            "FA Posting Type" := "FA Posting Type"::"Salvage Value";
            FAInsertLedgEntry.InsertFA(FALedgEntry);
        end;
    end;

    local procedure PostBudget(): Boolean
    begin
        exit(BudgetNo <> '');
    end;

    local procedure SetBudgetAssetNo()
    begin
        FA2.Get(BudgetNo);
        if not FA2."Budgeted Asset" then begin
            FA."No." := FA2."No.";
            DeprBookCode := '';
            Error(Text002, FAName, FA.FieldCaption("Budgeted Asset"));
        end;
        if FAPostingType = FAPostingType::Maintenance then
            MaintenanceLedgEntry."FA No./Budgeted FA No." := BudgetNo
        else
            FALedgEntry."FA No./Budgeted FA No." := BudgetNo;
    end;

    local procedure PostBudgetAsset()
    var
        FA2: Record "Fixed Asset";
        FAPostingType2: Integer;
    begin
        FA2.Get(BudgetNo);
        FA2.TestField(Blocked, false);
        FA2.TestField(Inactive, false);
        if FAPostingType = FAPostingType::Maintenance then begin
            with MaintenanceLedgEntry do begin
                "Automatic Entry" := true;
                "G/L Entry No." := 0;
                "FA No./Budgeted FA No." := "FA No.";
                "FA No." := BudgetNo;
                Amount := -Amount2;
                FAInsertLedgEntry.InsertMaintenance(MaintenanceLedgEntry);
            end;
        end else
            with FALedgEntry do begin
                "Automatic Entry" := true;
                "G/L Entry No." := 0;
                "FA No./Budgeted FA No." := "FA No.";
                "FA No." := BudgetNo;
                if SalvageValue <> 0 then begin
                    Amount := -SalvageValue;
                    FAPostingType2 := "FA Posting Type";
                    "FA Posting Type" := "FA Posting Type"::"Salvage Value";
                    FAInsertLedgEntry.InsertFA(FALedgEntry);
                    "FA Posting Type" := FAPostingType2;
                end;
                Amount := -Amount2;
                FAInsertLedgEntry.InsertFA(FALedgEntry);
            end;
    end;

    local procedure PostReverseType(FALedgEntry: Record "FA Ledger Entry")
    var
        EntryAmounts: array[4] of Decimal;
        i: Integer;
    begin
        CalculateDisposal.CalcReverseAmounts(FANo, DeprBookCode, EntryAmounts);
        FALedgEntry."FA Posting Category" := FALedgEntry."FA Posting Category"::" ";
        FALedgEntry."Automatic Entry" := true;
        for i := 1 to 4 do
            if EntryAmounts[i] <> 0 then begin
                FALedgEntry.Amount := EntryAmounts[i];
                FALedgEntry."FA Posting Type" := CalculateDisposal.SetReverseType(i);
                FAInsertLedgEntry.InsertFA(FALedgEntry);
                if FALedgEntry."G/L Entry No." > 0 then
                    FAInsertLedgEntry.InsertBalAcc(FALedgEntry);
            end;
    end;

    local procedure PostGLBalAcc(FALedgEntry: Record "FA Ledger Entry"; AllocatedPct: Decimal)
    begin
        if AllocatedPct > 0 then begin
            FALedgEntry."Entry No." := 0;
            FALedgEntry."Automatic Entry" := true;
            FALedgEntry.Amount := -FALedgEntry.Amount;
            FALedgEntry.Correction := not FALedgEntry.Correction;
            FAInsertLedgEntry.InsertBalDisposalAcc(FALedgEntry);
            FALedgEntry.Correction := not FALedgEntry.Correction;
            FAInsertLedgEntry.InsertBalAcc(FALedgEntry);
        end;
    end;

    local procedure PostAllocation(var FALedgEntry: Record "FA Ledger Entry")
    var
        FAPostingGr: Record "FA Posting Group";
    begin
        with FALedgEntry do begin
            if "G/L Entry No." = 0 then
                exit;
            case "FA Posting Type" of
                "FA Posting Type"::"Gain/Loss":
                    if DeprBook."Disposal Calculation Method" = DeprBook."Disposal Calculation Method"::Net then begin
                        FAPostingGr.Get("FA Posting Group");
                        FAPostingGr.CalcFields("Allocated Gain %", "Allocated Loss %");
                        if "Result on Disposal" = "Result on Disposal"::Gain then
                            PostGLBalAcc(FALedgEntry, FAPostingGr."Allocated Gain %")
                        else
                            PostGLBalAcc(FALedgEntry, FAPostingGr."Allocated Loss %");
                    end;
                "FA Posting Type"::"Book Value on Disposal":
                    begin
                        FAPostingGr.Get("FA Posting Group");
                        FAPostingGr.CalcFields("Allocated Book Value % (Gain)", "Allocated Book Value % (Loss)");
                        if "Result on Disposal" = "Result on Disposal"::Gain then
                            PostGLBalAcc(FALedgEntry, FAPostingGr."Allocated Book Value % (Gain)")
                        else
                            PostGLBalAcc(FALedgEntry, FAPostingGr."Allocated Book Value % (Loss)");
                    end;
            end;
        end;
    end;

    local procedure DeprLine(): Boolean
    begin
        exit((Amount2 = 0) and (FAPostingType = FAPostingType::Depreciation) and DeprUntilDate);
    end;

    procedure FindFirstGLAcc(var FAGLPostBuf: Record "FA G/L Posting Buffer"): Boolean
    begin
        exit(FAInsertLedgEntry.FindFirstGLAcc(FAGLPostBuf));
    end;

    procedure GetNextGLAcc(var FAGLPostBuf: Record "FA G/L Posting Buffer"): Integer
    begin
        exit(FAInsertLedgEntry.GetNextGLAcc(FAGLPostBuf));
    end;

    local procedure FAName(): Text[200]
    var
        DepreciationCalc: Codeunit "Depreciation Calculation";
    begin
        exit(DepreciationCalc.FAName(FA, DeprBookCode));
    end;

    local procedure SetResultOnDisposal(var FALedgEntry: Record "FA Ledger Entry")
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        FADeprBook."FA No." := FALedgEntry."FA No.";
        FADeprBook."Depreciation Book Code" := FALedgEntry."Depreciation Book Code";
        FADeprBook.CalcFields("Gain/Loss");
        if FADeprBook."Gain/Loss" <= 0 then
            FALedgEntry."Result on Disposal" := FALedgEntry."Result on Disposal"::Gain
        else
            FALedgEntry."Result on Disposal" := FALedgEntry."Result on Disposal"::Loss;
    end;

    local procedure CalcResultOnDisposal(FANo: Code[20]; DeprBookCode: Code[10]): Integer
    var
        FADeprBook: Record "FA Depreciation Book";
        FALedgEntry: Record "FA Ledger Entry";
    begin
        FADeprBook."FA No." := FANo;
        FADeprBook."Depreciation Book Code" := DeprBookCode;
        FADeprBook.CalcFields("Gain/Loss");
        if FADeprBook."Gain/Loss" <= 0 then
            exit(FALedgEntry."Result on Disposal"::Gain);

        exit(FALedgEntry."Result on Disposal"::Loss);
    end;

    local procedure CheckMaintDocNo(MaintenanceLedgEntry: Record "Maintenance Ledger Entry")
    var
        OldMaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        FAJnlLine2: Record "FA Journal Line";
    begin
        OldMaintenanceLedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "Document No.");
        OldMaintenanceLedgEntry.SetRange("FA No.", MaintenanceLedgEntry."FA No.");
        OldMaintenanceLedgEntry.SetRange("Depreciation Book Code", MaintenanceLedgEntry."Depreciation Book Code");
        OldMaintenanceLedgEntry.SetRange("Document No.", MaintenanceLedgEntry."Document No.");
        if OldMaintenanceLedgEntry.FindFirst then begin
            FAJnlLine2."FA Posting Type" := FAJnlLine2."FA Posting Type"::Maintenance;
            Error(
              Text003,
              OldMaintenanceLedgEntry.FieldCaption("Document No."),
              OldMaintenanceLedgEntry."Document No.",
              FAJnlLine2.FieldCaption("FA Posting Type"),
              FAJnlLine2."FA Posting Type",
              FAName);
        end;
    end;

    procedure UpdateRegNo(GLRegNo: Integer)
    var
        FAReg: Record "FA Register";
    begin
        if FAReg.FindLast then begin
            FAReg."G/L Register No." := GLRegNo;
            FAReg.Modify();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFAJnlPostLine(var FAJournalLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFAJnlPostLine(var FAJournalLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostFixedAssetFromGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var FALedgerEntry: Record "FA Ledger Entry"; FAAmount: Decimal; VATAmount: Decimal)
    begin
    end;
}

