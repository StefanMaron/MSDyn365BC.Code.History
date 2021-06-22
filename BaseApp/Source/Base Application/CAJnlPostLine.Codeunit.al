codeunit 1102 "CA Jnl.-Post Line"
{
    Permissions = TableData "Cost Entry" = imd,
                  TableData "Cost Register" = imd;
    TableNo = "Cost Journal Line";

    trigger OnRun()
    begin
        CostAccSetup.Get();
        RunWithCheck(Rec);
    end;

    var
        CostAccSetup: Record "Cost Accounting Setup";
        CostEntry: Record "Cost Entry";
        GlEntry: Record "G/L Entry";
        CostJnlLine: Record "Cost Journal Line";
        CostRegister: Record "Cost Register";
        CostBudgetRegister: Record "Cost Budget Register";
        CostAllocationSource: Record "Cost Allocation Source";
        CostBudgetEntry: Record "Cost Budget Entry";
        GLSetup: Record "General Ledger Setup";
        CAJnlCheckLine: Codeunit "CA Jnl.-Check Line";
        PostBudget: Boolean;
        TotalDebit: Decimal;
        TotalCredit: Decimal;
        TotalBudgetAmount: Decimal;
        NextCostEntryNo: Integer;
        NextCostBudgetEntryNo: Integer;

    procedure RunWithCheck(var CostJnlLine2: Record "Cost Journal Line")
    begin
        CostJnlLine.Copy(CostJnlLine2);
        Code;
        CostJnlLine2 := CostJnlLine;

        OnAfterRunWithCheck(CostJnlLine2);
    end;

    local procedure "Code"()
    var
        IsHandled: Boolean;
    begin
        IsHandled := FALSE;
        OnBeforeCode(CostJnlLine, IsHandled);
        if IsHandled then
            exit;

        with CostJnlLine do begin
            if EmptyLine then
                exit;

            CAJnlCheckLine.RunCheck(CostJnlLine);
            if "Budget Name" <> '' then
                PostBudget := true;

            if PostBudget then begin
                if NextCostBudgetEntryNo = 0 then begin
                    CostBudgetEntry.LockTable();
                    NextCostBudgetEntryNo := CostBudgetEntry.GetLastEntryNo() + 1;
                end;
            end else
                if NextCostEntryNo = 0 then begin
                    CostEntry.LockTable();
                    NextCostEntryNo := CostEntry.GetLastEntryNo() + 1;
                end;
        end;
        PostLine;
    end;

    local procedure PostLine()
    begin
        with CostJnlLine do
            if PostBudget then begin
                if "Cost Type No." <> '' then
                    InsertBudgetEntries("Cost Type No.", "Cost Center Code", "Cost Object Code", Amount);

                if "Bal. Cost Type No." <> '' then
                    InsertBudgetEntries("Bal. Cost Type No.", "Bal. Cost Center Code", "Bal. Cost Object Code", -Amount);
            end else begin
                if "Cost Type No." <> '' then
                    InsertCostEntries("Cost Type No.", "Cost Center Code", "Cost Object Code", Amount);

                if "Bal. Cost Type No." <> '' then
                    InsertCostEntries("Bal. Cost Type No.", "Bal. Cost Center Code", "Bal. Cost Object Code", -Amount);
            end;
    end;

    local procedure CreateCostRegister()
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        if CostRegister."No." = 0 then begin
            CostRegister.LockTable();
            if (not CostRegister.FindLast) or (CostRegister."To Cost Entry No." <> 0) then
                with CostJnlLine do begin
                    CostRegister.Init();
                    CostRegister."Journal Batch Name" := "Journal Batch Name";
                    CostRegister."No." := CostRegister."No." + 1;
                    CostRegister."From Cost Entry No." := NextCostEntryNo;
                    CostRegister."To Cost Entry No." := NextCostEntryNo;
                    CostRegister."No. of Entries" := 1;
                    CostRegister."Debit Amount" := TotalDebit;
                    CostRegister."Credit Amount" := TotalCredit;
                    CostRegister."Posting Date" := "Posting Date";  // from last journal line
                    CostRegister."User ID" := UserId;
                    CostRegister."Processed Date" := Today;

                    case "Source Code" of
                        SourceCodeSetup."Cost Allocation":
                            begin
                                CostRegister.Source := CostRegister.Source::Allocation;
                                CostAllocationSource.Get("Allocation ID");
                                CostRegister.Level := CostAllocationSource.Level;
                            end;
                        SourceCodeSetup."G/L Entry to CA":
                            begin
                                CostRegister.Source := CostRegister.Source::"Transfer from G/L";
                                CostRegister."From G/L Entry No." := "G/L Entry No.";
                                CostRegister."To G/L Entry No." := "G/L Entry No.";
                            end;
                        SourceCodeSetup."Transfer Budget to Actual":
                            CostRegister.Source := CostRegister.Source::"Transfer from Budget";
                        else
                            CostRegister.Source := CostRegister.Source::"Cost Journal";
                    end;
                    OnCreateCostRegisterOnBeforeInsert(CostRegister, CostJnlLine, SourceCodeSetup);
                    CostRegister.Insert();
                end;
        end else begin
            CostRegister."Debit Amount" := TotalDebit;
            CostRegister."Credit Amount" := TotalCredit;
            CostRegister."To G/L Entry No." := CostJnlLine."G/L Entry No.";
            CostRegister."To Cost Entry No." := NextCostEntryNo;
            CostRegister."No. of Entries" := CostRegister."To Cost Entry No." - CostRegister."From Cost Entry No." + 1;
            OnCreateCostRegisterOnBeforeModify(CostRegister, CostJnlLine, SourceCodeSetup);
            CostRegister.Modify();
        end;
    end;

    local procedure CreateCostBudgetRegister()
    begin
        if CostBudgetRegister."No." = 0 then begin
            CostBudgetRegister.LockTable();
            if (not CostBudgetRegister.FindLast) or (CostBudgetRegister."To Cost Budget Entry No." <> 0) then
                with CostJnlLine do begin
                    CostBudgetRegister.Init();
                    CostBudgetRegister."Journal Batch Name" := "Journal Batch Name";
                    CostBudgetRegister."Cost Budget Name" := "Budget Name";
                    CostBudgetRegister."No." := CostBudgetRegister."No." + 1;
                    CostBudgetRegister."From Cost Budget Entry No." := NextCostBudgetEntryNo;
                    CostBudgetRegister."To Cost Budget Entry No." := NextCostBudgetEntryNo;
                    CostBudgetRegister."No. of Entries" := 1;
                    CostBudgetRegister.Amount := TotalBudgetAmount;
                    CostBudgetRegister."Posting Date" := "Posting Date";  // from last journal line
                    CostBudgetRegister."User ID" := UserId;
                    CostBudgetRegister."Processed Date" := Today;
                    CostAccSetup.Get();
                    if "Allocation ID" <> '' then
                        CostBudgetRegister.Source := CostBudgetRegister.Source::Allocation
                    else
                        CostBudgetRegister.Source := CostBudgetRegister.Source::"Cost Journal";

                    if "Allocation ID" <> '' then begin
                        CostAllocationSource.Get("Allocation ID");
                        CostBudgetRegister.Level := CostAllocationSource.Level;
                    end;
                    CostBudgetRegister.Insert();
                end;
        end;
        CostBudgetRegister."To Cost Budget Entry No." := NextCostBudgetEntryNo;
        CostBudgetRegister."No. of Entries" := CostBudgetRegister."To Cost Budget Entry No." -
          CostBudgetRegister."From Cost Budget Entry No." + 1;
        CostBudgetRegister.Modify();
    end;

    local procedure InsertCostEntries(CT: Code[20]; CC: Code[20]; CO: Code[20]; Amt: Decimal)
    begin
        GLSetup.Get();
        with CostJnlLine do begin
            CostEntry.Init();
            CostEntry."Entry No." := NextCostEntryNo;
            CostEntry."Cost Type No." := CT;
            CostEntry."Posting Date" := "Posting Date";
            CostEntry."Document No." := "Document No.";
            CostEntry.Description := Description;
            CostEntry."Cost Center Code" := CC;
            CostEntry."Cost Object Code" := CO;

            if "System-Created Entry" then begin
                CostEntry."Additional-Currency Amount" := "Additional-Currency Amount";
                CostEntry."Add.-Currency Debit Amount" := "Add.-Currency Debit Amount";
                CostEntry."Add.-Currency Credit Amount" := "Add.-Currency Credit Amount";
            end;

            CostEntry.Amount := Amt;
            if Amt > 0 then begin
                CostEntry."Debit Amount" := Amt;
                if GLSetup."Additional Reporting Currency" <> '' then begin
                    CostEntry."Additional-Currency Amount" := CalcAddCurrAmount(Amt);
                    CostEntry."Add.-Currency Debit Amount" := CostEntry."Additional-Currency Amount";
                end;
            end else begin
                CostEntry."Credit Amount" := -Amt;
                if GLSetup."Additional Reporting Currency" <> '' then begin
                    CostEntry."Additional-Currency Amount" := CalcAddCurrAmount(Amt);
                    CostEntry."Add.-Currency Credit Amount" := -CostEntry."Additional-Currency Amount";
                end;
            end;

            CostEntry."Reason Code" := "Reason Code";
            if GlEntry.Get("G/L Entry No.") then
                CostEntry."G/L Account" := GlEntry."G/L Account No.";
            CostEntry."G/L Entry No." := "G/L Entry No.";
            CostEntry."Source Code" := "Source Code";
            CostEntry."System-Created Entry" := "System-Created Entry";
            CostEntry.Allocated := Allocated;
            CostEntry."User ID" := UserId;
            CostEntry."Batch Name" := "Journal Batch Name";
            CostEntry."Allocation Description" := "Allocation Description";
            CostEntry."Allocation ID" := "Allocation ID";
            OnBeforeCostEntryInsert(CostEntry, CostJnlLine);
            CostEntry.Insert();
            OnAfterCostEntryInsert(CostEntry, CostJnlLine);
        end;
        TotalCredit := TotalCredit + CostEntry."Credit Amount";
        TotalDebit := TotalDebit + CostEntry."Debit Amount";
        CreateCostRegister;
        NextCostEntryNo := NextCostEntryNo + 1;
    end;

    local procedure InsertBudgetEntries(CT: Code[20]; CC: Code[20]; CO: Code[20]; Amt: Decimal)
    begin
        with CostJnlLine do begin
            CostBudgetEntry.Init();
            CostBudgetEntry."Entry No." := NextCostBudgetEntryNo;
            CostBudgetEntry."Budget Name" := "Budget Name";
            CostBudgetEntry."Cost Type No." := CT;
            CostBudgetEntry.Date := "Posting Date";
            CostBudgetEntry."Document No." := "Document No.";
            CostBudgetEntry.Description := Description;
            CostBudgetEntry."Cost Center Code" := CC;
            CostBudgetEntry."Cost Object Code" := CO;
            CostBudgetEntry.Amount := Amt;
            CostBudgetEntry."Source Code" := "Source Code";
            CostBudgetEntry."System-Created Entry" := "System-Created Entry";
            CostBudgetEntry.Allocated := Allocated;
            CostBudgetEntry."Last Modified By User" := UserId;
            CostBudgetEntry."Allocation Description" := "Allocation Description";
            CostBudgetEntry."Allocation ID" := "Allocation ID";
            CostBudgetEntry.Insert();
        end;
        CreateCostBudgetRegister;
        NextCostBudgetEntryNo := NextCostBudgetEntryNo + 1;

        TotalBudgetAmount := TotalBudgetAmount + Amt
    end;

    local procedure CalcAddCurrAmount(Amount: Decimal): Decimal
    var
        AddCurrency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        GetAddCurrency(AddCurrency);
        exit(
          Round(
            CurrExchRate.ExchangeAmtLCYToFCY(CostJnlLine."Posting Date", GLSetup."Additional Reporting Currency", Amount,
              CurrExchRate.ExchangeRate(CostJnlLine."Posting Date", GLSetup."Additional Reporting Currency")),
            AddCurrency."Amount Rounding Precision"));
    end;

    local procedure GetAddCurrency(var AddCurrency: Record Currency)
    begin
        if GLSetup."Additional Reporting Currency" <> '' then
            if GLSetup."Additional Reporting Currency" <> AddCurrency.Code then begin
                AddCurrency.Get(GLSetup."Additional Reporting Currency");
                AddCurrency.TestField("Amount Rounding Precision");
                AddCurrency.TestField("Residual Gains Account");
                AddCurrency.TestField("Residual Losses Account");
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCostEntryInsert(var CostEntry: Record "Cost Entry"; CostJournalLine: Record "Cost Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRunWithCheck(var CostJournalLine: Record "Cost Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var CostJournalLine: Record "Cost Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCostEntryInsert(var CostEntry: Record "Cost Entry"; CostJournalLine: Record "Cost Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCostRegisterOnBeforeInsert(var CostRegister: Record "Cost Register"; CostJournalLine: Record "Cost Journal Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCostRegisterOnBeforeModify(var CostRegister: Record "Cost Register"; CostJournalLine: Record "Cost Journal Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;
}

