codeunit 394 "FinChrgMemo-Make"
{

    trigger OnRun()
    begin
    end;

    var
        Cust: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        FinChrgTerms: Record "Finance Charge Terms";
        FinChrgMemoHeaderReq: Record "Finance Charge Memo Header";
        FinChrgMemoHeader: Record "Finance Charge Memo Header";
        FinChrgMemoLine: Record "Finance Charge Memo Line";
        Currency: Record Currency temporary;
        TempCurrency: Record Currency temporary;
        CurrExchRate: Record "Currency Exchange Rate";
        NextLineNo: Integer;
        CustAmountLCY: Decimal;
        HeaderExists: Boolean;
        OverDue: Boolean;

    procedure "Code"(): Boolean
    begin
        with FinChrgMemoHeader do
            if "No." <> '' then begin
                HeaderExists := true;
                TestField("Customer No.");
                Cust.Get("Customer No.");
                TestField("Document Date");
                TestField("Fin. Charge Terms Code");
                FinChrgMemoHeaderReq := FinChrgMemoHeader;
                FinChrgMemoLine.SetRange("Finance Charge Memo No.", "No.");
                FinChrgMemoLine.DeleteAll();
            end;

        OverDue := false;

        with Cust do begin
            TestField("Fin. Charge Terms Code");
            if HeaderExists then
                FinChrgMemoCheck(FinChrgMemoHeader."Currency Code")
            else begin
                if Blocked = Blocked::All then
                    exit(false);
                Currency.DeleteAll();
                TempCurrency.DeleteAll();
                CustLedgEntry2.CopyFilters(CustLedgEntry);
                CustLedgEntry.SetCurrentKey("Customer No.");
                CustLedgEntry.SetRange("Customer No.", "No.");
                if CustLedgEntry.Find('-') then
                    repeat
                        if CustLedgEntry."On Hold" = '' then begin
                            Currency.Code := CustLedgEntry."Currency Code";
                            if Currency.Insert() then;
                        end;
                    until CustLedgEntry.Next = 0;
                CustLedgEntry.CopyFilters(CustLedgEntry2);
                if Currency.Find('-') then
                    repeat
                        FinChrgMemoCheck(Currency.Code);
                    until Currency.Next = 0;
            end;

            if ((CustAmountLCY = 0) or (CustAmountLCY < FinChrgTerms."Minimum Amount (LCY)")) and
               ((FinChrgTerms."Additional Fee (LCY)" = 0) or (not OverDue))
            then
                exit(true);
            FinChrgMemoLine.LockTable();
            FinChrgMemoHeader.LockTable();

            if HeaderExists then
                MakeFinChrgMemo(FinChrgMemoHeader."Currency Code")
            else
                if Currency.Find('-') then
                    repeat
                        if TempCurrency.Get(Currency.Code) then
                            MakeFinChrgMemo(Currency.Code);
                    until Currency.Next = 0;
        end;
        exit(true);
    end;

    procedure Set(Cust2: Record Customer; var CustLedgEntry2: Record "Cust. Ledger Entry"; FinChrgMemoHeaderReq2: Record "Finance Charge Memo Header")
    begin
        Cust := Cust2;
        CustLedgEntry.Copy(CustLedgEntry2);
        FinChrgMemoHeaderReq := FinChrgMemoHeaderReq2;
    end;

    procedure SuggestLines(FinChrgMemoHeader2: Record "Finance Charge Memo Header"; var CustLedgEntry2: Record "Cust. Ledger Entry")
    begin
        FinChrgMemoHeader := FinChrgMemoHeader2;
        CustLedgEntry.Copy(CustLedgEntry2);
    end;

    local procedure MakeFinChrgMemo(CurrencyCode: Code[10])
    begin
        if not HeaderExists then
            if not MakeHeader(CurrencyCode, false) then
                exit;
        NextLineNo := 0;
        MakeLines(CurrencyCode, false);
        FinChrgMemoHeader.InsertLines;
        FinChrgMemoHeader.Modify();
    end;

    local procedure FinChrgMemoCheck(CurrencyCode: Code[10])
    begin
        if not HeaderExists then
            MakeHeader(CurrencyCode, true);
        FinChrgTerms.Get(FinChrgMemoHeader."Fin. Charge Terms Code");
        MakeLines(CurrencyCode, true);
    end;

    local procedure MakeHeader(CurrencyCode: Code[10]; Checking: Boolean): Boolean
    begin
        with Cust do begin
            if not Checking then begin
                FinChrgMemoHeader.SetCurrentKey("Customer No.", "Currency Code");
                FinChrgMemoHeader.SetRange("Customer No.", "No.");
                FinChrgMemoHeader.SetRange("Currency Code", CurrencyCode);
                if FinChrgMemoHeader.FindFirst then
                    exit(false);
            end;
            FinChrgMemoHeader.Init();
            FinChrgMemoHeader."No." := '';
            FinChrgMemoHeader."Posting Date" := FinChrgMemoHeaderReq."Posting Date";
            if not Checking then
                FinChrgMemoHeader.Insert(true);
            FinChrgMemoHeader.Validate("Customer No.", "No.");
            FinChrgMemoHeader.Validate("Document Date", FinChrgMemoHeaderReq."Document Date");
            FinChrgMemoHeader.Validate("Currency Code", CurrencyCode);
            if not Checking then
                FinChrgMemoHeader.Modify();
            exit(true);
        end;
    end;

    local procedure MakeLines(CurrencyCode: Code[10]; Checking: Boolean)
    begin
        with Cust do begin
            if FinChrgTerms."Interest Calculation" in
               [FinChrgTerms."Interest Calculation"::"Open Entries",
                FinChrgTerms."Interest Calculation"::"All Entries"]
            then begin
                CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Due Date", "Currency Code");
                CustLedgEntry.SetRange("Customer No.", "No.");
                CustLedgEntry.SetRange(Open, true);
                CustLedgEntry.SetRange("On Hold", '');
                CustLedgEntry.SetRange(Positive, true);
                CustLedgEntry.SetRange("Currency Code", CurrencyCode);
                OnMakeLinesOnBeforeMakeLinesOpenEntries(CustLedgEntry, CurrencyCode, Checking);
                MakeLines2(CurrencyCode, Checking);
            end;
            if FinChrgTerms."Interest Calculation" in
               [FinChrgTerms."Interest Calculation"::"Closed Entries",
                FinChrgTerms."Interest Calculation"::"All Entries"]
            then begin
                if not CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Calculate Interest") then
                    CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Due Date", "Currency Code");
                CustLedgEntry.SetRange("Customer No.", "No.");
                CustLedgEntry.SetRange(Open, false);
                CustLedgEntry.SetRange("On Hold", '');
                CustLedgEntry.SetRange(Positive, true);
                CustLedgEntry.SetRange("Currency Code", CurrencyCode);
                CustLedgEntry.SetRange("Calculate Interest", true);
                OnMakeLinesOnBeforeMakeLinesClosedEntries(CustLedgEntry, CurrencyCode, Checking);
                MakeLines2(CurrencyCode, Checking);
                CustLedgEntry.SetRange("Calculate Interest");
            end;
        end;
    end;

    local procedure MakeLines2(CurrencyCode: Code[10]; Checking: Boolean)
    begin
        with Cust do
            if CustLedgEntry.Find('-') then
                repeat
                    Clear(FinChrgMemoLine);
                    NextLineNo := GetLastLineNo(FinChrgMemoHeader."No.") + 10000;
                    FinChrgMemoLine.Init();
                    FinChrgMemoLine."Finance Charge Memo No." := FinChrgMemoHeader."No.";
                    FinChrgMemoLine."Line No." := NextLineNo;
                    FinChrgMemoLine.SetFinChrgMemoHeader(FinChrgMemoHeader);
                    FinChrgMemoLine.Type := FinChrgMemoLine.Type::"Customer Ledger Entry";
                    FinChrgMemoLine.SetCheckingMode(Checking);
                    FinChrgMemoLine.Validate("Entry No.", CustLedgEntry."Entry No.");
                    if CurrencyCode <> '' then begin
                        CustAmountLCY :=
                          CustAmountLCY +
                          CurrExchRate.ExchangeAmtFCYToLCY(
                            FinChrgMemoHeader."Posting Date", CurrencyCode, FinChrgMemoLine.Amount,
                            CurrExchRate.ExchangeRate(
                              FinChrgMemoHeader."Posting Date", CurrencyCode))
                    end else
                        CustAmountLCY := CustAmountLCY + FinChrgMemoLine.Amount;
                    if (CustAmountLCY >= FinChrgTerms."Minimum Amount (LCY)") and
                       (FinChrgMemoHeader."Document Date" > CalcDate(FinChrgTerms."Grace Period", FinChrgMemoLine."Due Date"))
                    then
                        OverDue := true;
                    if FinChrgMemoLine.Amount <> 0 then
                        if not Checking then
                            FinChrgMemoLine.Insert
                        else begin
                            TempCurrency.Code := CurrencyCode;
                            if TempCurrency.Insert() then;
                        end;
                    OnAfterFinChrgMemoLineCreated(FinChrgMemoLine, Checking);
                until CustLedgEntry.Next = 0;
    end;

    local procedure GetLastLineNo(MemoNo: Code[20]): Integer
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
    begin
        FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", MemoNo);
        if FinanceChargeMemoLine.FindLast then;
        exit(FinanceChargeMemoLine."Line No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinChrgMemoLineCreated(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; Checking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeLinesOnBeforeMakeLinesClosedEntries(var CustLedgEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10]; Checking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeLinesOnBeforeMakeLinesOpenEntries(var CustLedgEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10]; Checking: Boolean)
    begin
    end;
}

