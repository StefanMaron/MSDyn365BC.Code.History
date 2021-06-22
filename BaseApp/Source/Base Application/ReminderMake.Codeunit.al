codeunit 392 "Reminder-Make"
{

    trigger OnRun()
    begin
    end;

    var
        Currency: Record Currency temporary;
        Cust: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        ReminderTerms: Record "Reminder Terms";
        ReminderHeaderReq: Record "Reminder Header";
        ReminderHeader: Record "Reminder Header";
        ReminderEntry: Record "Reminder/Fin. Charge Entry";
        Text0000: Label 'Open Entries Not Due';
        CustLedgEntryOnHoldTEMP: Record "Cust. Ledger Entry" temporary;
        CustLedgEntryLineFeeFilters: Record "Cust. Ledger Entry";
        AmountsNotDueLineInserted: Boolean;
        OverdueEntriesOnly: Boolean;
        HeaderExists: Boolean;
        IncludeEntriesOnHold: Boolean;
        Text0001: Label 'Open Entries On Hold';
        CustLedgEntryLastIssuedReminderLevelFilter: Text;

    procedure "Code"() RetVal: Boolean
    var
        ReminderLine: Record "Reminder Line";
    begin
        CustLedgEntryLastIssuedReminderLevelFilter := CustLedgEntry.GetFilter("Last Issued Reminder Level");
        with ReminderHeader do
            if "No." <> '' then begin
                HeaderExists := true;
                TestField("Customer No.");
                Cust.Get("Customer No.");
                TestField("Document Date");
                TestField("Reminder Terms Code");
                ReminderHeaderReq := ReminderHeader;
                ReminderLine.SetRange("Reminder No.", "No.");
                ReminderLine.DeleteAll();
            end;

        Cust.TestField("Reminder Terms Code");
        if ReminderHeader."Reminder Terms Code" <> '' then
            ReminderTerms.Get(ReminderHeader."Reminder Terms Code")
        else
            ReminderTerms.Get(Cust."Reminder Terms Code");
        if HeaderExists then
            RetVal := MakeReminder(ReminderHeader."Currency Code")
        else begin
            Currency.DeleteAll();
            CustLedgEntry2.CopyFilters(CustLedgEntry);
            CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
            CustLedgEntry.SetRange("Customer No.", Cust."No.");
            CustLedgEntry.SetRange(Open, true);
            CustLedgEntry.SetRange(Positive, true);
            OnBeforeCustLedgerEntryFind(CustLedgEntry, ReminderHeaderReq, Cust);
            if CustLedgEntry.FindSet then
                repeat
                    if CustLedgEntry."On Hold" = '' then begin
                        Currency.Code := CustLedgEntry."Currency Code";
                        if Currency.Insert() then;
                    end;
                until CustLedgEntry.Next = 0;
            CustLedgEntry.CopyFilters(CustLedgEntry2);
            RetVal := true;
            if Currency.FindSet then
                repeat
                    if not MakeReminder(Currency.Code) then
                        RetVal := false;
                until Currency.Next = 0;
        end;
    end;

    procedure Set(Cust2: Record Customer; var CustLedgEntry2: Record "Cust. Ledger Entry"; ReminderHeaderReq2: Record "Reminder Header"; OverdueEntriesOnly2: Boolean; IncludeEntriesOnHold2: Boolean; var CustLedgEntryLinefeeOn: Record "Cust. Ledger Entry")
    begin
        Cust := Cust2;
        CustLedgEntry.Copy(CustLedgEntry2);
        ReminderHeaderReq := ReminderHeaderReq2;
        OverdueEntriesOnly := OverdueEntriesOnly2;
        IncludeEntriesOnHold := IncludeEntriesOnHold2;
        CustLedgEntryLineFeeFilters.CopyFilters(CustLedgEntryLinefeeOn);

        OnAfterSet(Cust, CustLedgEntry, ReminderHeaderReq, OverdueEntriesOnly, IncludeEntriesOnHold, CustLedgEntryLinefeeOn);
    end;

    procedure SuggestLines(ReminderHeader2: Record "Reminder Header"; var CustLedgEntry2: Record "Cust. Ledger Entry"; OverdueEntriesOnly2: Boolean; IncludeEntriesOnHold2: Boolean; var CustLedgEntryLinefeeOn: Record "Cust. Ledger Entry")
    begin
        ReminderHeader := ReminderHeader2;
        CustLedgEntry.Copy(CustLedgEntry2);
        OverdueEntriesOnly := OverdueEntriesOnly2;
        IncludeEntriesOnHold := IncludeEntriesOnHold2;
        CustLedgEntryLineFeeFilters.CopyFilters(CustLedgEntryLinefeeOn);
    end;

    local procedure MakeReminder(CurrencyCode: Code[10]): Boolean
    var
        ReminderLevel: Record "Reminder Level";
        ReminderLine: Record "Reminder Line";
        MakeDoc: Boolean;
        StartLineInserted: Boolean;
        NextLineNo: Integer;
        LineLevel: Integer;
        MaxLineLevel: Integer;
        MaxReminderLevel: Integer;
        CustAmount: Decimal;
        ReminderDueDate: Date;
        OpenEntriesNotDueTranslated: Text[100];
        OpenEntriesOnHoldTranslated: Text[100];
    begin
        with Cust do begin
            FilterCustLedgEntryReminderLevel(CustLedgEntry, ReminderLevel, CurrencyCode);
            if not ReminderLevel.FindLast then
                exit(false);
            CustLedgEntryOnHoldTEMP.DeleteAll();

            FindAndMarkReminderCandidates(CustLedgEntry, ReminderLevel, CustAmount, MakeDoc, MaxReminderLevel, MaxLineLevel);

            ReminderLevel.SetRange("Reminder Terms Code", ReminderTerms.Code);
            ReminderLevel.SetRange("No.", 1, MaxLineLevel);
            if not ReminderLevel.FindLast then
                ReminderLevel.Init();
            if MakeDoc and (CustAmount > 0) and (CustAmountLCY(CurrencyCode, CustAmount) >= ReminderTerms."Minimum Amount (LCY)") then begin
                if Blocked = Blocked::All then
                    exit(false);
                ReminderLine.LockTable();
                ReminderHeader.LockTable();
                if not HeaderExists then begin
                    ReminderHeader.SetCurrentKey("Customer No.", "Currency Code");
                    ReminderHeader.SetRange("Customer No.", "No.");
                    ReminderHeader.SetRange("Currency Code", CurrencyCode);
                    OnBeforeReminderHeaderFind(ReminderHeader, ReminderHeaderReq, ReminderTerms, Cust);
                    if ReminderHeader.FindFirst then
                        exit(false);
                    ReminderHeader.Init();
                    ReminderHeader."No." := '';
                    ReminderHeader."Posting Date" := ReminderHeaderReq."Posting Date";
                    OnBeforeReminderHeaderInsert(ReminderHeader, ReminderHeaderReq, ReminderTerms, Cust);
                    ReminderHeader.Insert(true);
                    ReminderHeader.Validate("Customer No.", "No.");
                    ReminderHeader.Validate("Currency Code", CurrencyCode);
                    ReminderHeader."Document Date" := ReminderHeaderReq."Document Date";
                    ReminderHeader."Use Header Level" := ReminderHeaderReq."Use Header Level";
                end;
                ReminderHeader."Reminder Level" := ReminderLevel."No.";
                OnBeforeReminderHeaderModify(ReminderHeader, ReminderHeaderReq, HeaderExists, ReminderTerms, Cust, ReminderLevel);
                ReminderHeader.Modify();
                NextLineNo := 0;
                ReminderLevel.MarkedOnly(true);
                CustLedgEntry.MarkedOnly(true);
                ReminderLevel.FindLast;

                repeat
                    StartLineInserted := false;
                    FilterCustLedgEntries(ReminderLevel);
                    AmountsNotDueLineInserted := false;
                    if CustLedgEntry.FindSet then begin
                        repeat
                            SetReminderLine(LineLevel, ReminderDueDate);
                            if ReminderDueDate < ReminderHeaderReq."Document Date" then begin
                                if (NextLineNo > 0) and not StartLineInserted then
                                    InsertReminderLine(
                                      ReminderHeader."No.", ReminderLine."Line Type"::"Reminder Line", '', NextLineNo);
                                InitReminderLine(
                                  ReminderLine, ReminderHeader."No.", ReminderLine."Line Type"::"Reminder Line", '', NextLineNo);
                                ReminderLine.Type := ReminderLine.Type::"Customer Ledger Entry";
                                ReminderLine.Validate("Entry No.", CustLedgEntry."Entry No.");
                                SetReminderLevel(ReminderHeader, ReminderLine, ReminderLevel."No.");
                                OnBeforeReminderLineInsert(ReminderLine, ReminderHeader, ReminderLevel, CustLedgEntry);
                                ReminderLine.Insert();
                                StartLineInserted := true;

                                AddLineFeeForCustLedgEntry(CustLedgEntry, ReminderLevel, NextLineNo);
                            end;
                        until CustLedgEntry.Next = 0;
                    end
                until ReminderLevel.Next(-1) = 0;
                ReminderHeader."Reminder Level" := MaxReminderLevel;
                ReminderHeader.Validate("Reminder Level");
                ReminderHeader.InsertLines;
                ReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
                ReminderLine.FindLast;
                NextLineNo := ReminderLine."Line No.";
                GetOpenEntriesNotDueOnHoldTranslated("Language Code", OpenEntriesNotDueTranslated, OpenEntriesOnHoldTranslated);
                CustLedgEntry.SetRange("Last Issued Reminder Level");
                if CustLedgEntry.FindSet then
                    repeat
                        if (not OverdueEntriesOnly) or
                           (CustLedgEntry."Document Type" in [CustLedgEntry."Document Type"::Payment, CustLedgEntry."Document Type"::Refund])
                        then begin
                            SetReminderLine(LineLevel, ReminderDueDate);
                            if (CalcDate(ReminderLevel."Grace Period", ReminderDueDate) >= ReminderHeaderReq."Document Date") and
                               (LineLevel = 1)
                            then begin
                                if not AmountsNotDueLineInserted then begin
                                    InsertReminderLine(ReminderHeader."No.", ReminderLine."Line Type"::"Not Due", '', NextLineNo);
                                    InsertReminderLine(
                                      ReminderHeader."No.", ReminderLine."Line Type"::"Not Due", OpenEntriesNotDueTranslated, NextLineNo);
                                    AmountsNotDueLineInserted := true;
                                end;
                                InitReminderLine(
                                  ReminderLine, ReminderHeader."No.", ReminderLine."Line Type"::"Not Due", '', NextLineNo);
                                ReminderLine.Type := ReminderLine.Type::"Customer Ledger Entry";
                                ReminderLine.Validate("Entry No.", CustLedgEntry."Entry No.");
                                ReminderLine."No. of Reminders" := 0;
                                ReminderLine.Insert();
                                AmountsNotDueLineInserted := true;
                                RemoveNotDueLinesInSectionReminderLine(ReminderLine);
                            end;
                        end;
                    until CustLedgEntry.Next = 0;

                if IncludeEntriesOnHold then
                    if CustLedgEntryOnHoldTEMP.FindSet then begin
                        InsertReminderLine(
                          ReminderHeader."No.", ReminderLine."Line Type"::"On Hold", '', NextLineNo);
                        InsertReminderLine(
                          ReminderHeader."No.", ReminderLine."Line Type"::"On Hold", OpenEntriesOnHoldTranslated, NextLineNo);
                        repeat
                            InitReminderLine(
                              ReminderLine, ReminderHeader."No.", ReminderLine."Line Type"::"On Hold", '', NextLineNo);
                            ReminderLine.Type := ReminderLine.Type::"Customer Ledger Entry";
                            ReminderLine.Validate("Entry No.", CustLedgEntryOnHoldTEMP."Entry No.");
                            ReminderLine."No. of Reminders" := 0;
                            ReminderLine.Insert();
                        until CustLedgEntryOnHoldTEMP.Next = 0;
                    end;
                ReminderHeader.Modify();
            end;
        end;

        RemoveLinesOfNegativeReminder(ReminderHeader);

        ReminderLevel.Reset();
        CustLedgEntry.Reset();

        OnAfterMakeReminder(ReminderHeader, ReminderLine);

        exit(true);
    end;

    local procedure FindAndMarkReminderCandidates(var CustLedgEntry: Record "Cust. Ledger Entry"; var ReminderLevel: Record "Reminder Level"; var CustAmount: Decimal; var MakeDoc: Boolean; var MaxReminderLevel: Integer; var MaxLineLevel: Integer)
    var
        ReminderDueDate: Date;
        LineLevel: Integer;
        MarkEntry: Boolean;
    begin
        repeat
            FilterCustLedgEntries(ReminderLevel);
            if CustLedgEntry.FindSet then
                repeat
                    if CustLedgEntry."On Hold" = '' then begin
                        SetReminderLine(LineLevel, ReminderDueDate);
                        MarkEntry := false;
                        if (CalcDate(ReminderLevel."Grace Period", ReminderDueDate) < ReminderHeaderReq."Document Date") and
                           ((LineLevel <= ReminderTerms."Max. No. of Reminders") or (ReminderTerms."Max. No. of Reminders" = 0))
                        then begin
                            MarkEntry := true;
                            CustLedgEntry.CalcFields("Remaining Amount");
                            CustAmount += CustLedgEntry."Remaining Amount";
                            if CustLedgEntry.Positive and
                               (CalcDate(ReminderLevel."Grace Period", ReminderDueDate) < ReminderHeaderReq."Document Date")
                            then
                                MakeDoc := true;
                        end else
                            if (CalcDate(ReminderLevel."Grace Period", ReminderDueDate) >= ReminderHeaderReq."Document Date") and
                               (not OverdueEntriesOnly or
                                (CustLedgEntry."Document Type" in [CustLedgEntry."Document Type"::Payment, CustLedgEntry."Document Type"::Refund]))
                            then
                                MarkEntry := true;

                        if MarkEntry then begin
                            CustLedgEntry.Mark(true);
                            ReminderLevel.Mark(true);
                            if (ReminderLevel."No." > MaxReminderLevel) and
                               (CustLedgEntry."Document Type" <> CustLedgEntry."Document Type"::"Credit Memo") and
                               (CalcDate(ReminderLevel."Grace Period", ReminderDueDate) < ReminderHeaderReq."Document Date")
                            then
                                MaxReminderLevel := ReminderLevel."No.";
                            if MaxLineLevel < LineLevel then
                                MaxLineLevel := LineLevel;
                        end;
                    end else // The customer ledger entry is on hold
                        if IncludeEntriesOnHold then begin
                            CustLedgEntryOnHoldTEMP := CustLedgEntry;
                            CustLedgEntryOnHoldTEMP.Insert();
                        end;
                until CustLedgEntry.Next = 0;
        until ReminderLevel.Next(-1) = 0;
    end;

    local procedure InsertReminderLine(ReminderNo: Code[20]; LineType: Integer; Description: Text[100]; var NextLineNo: Integer)
    var
        ReminderLine: Record "Reminder Line";
    begin
        InitReminderLine(ReminderLine, ReminderNo, LineType, Description, NextLineNo);
        ReminderLine.Insert();
    end;

    local procedure InitReminderLine(var ReminderLine: Record "Reminder Line"; ReminderNo: Code[20]; LineType: Integer; Description: Text[100]; var NextLineNo: Integer)
    begin
        NextLineNo := GetLastLineNo(ReminderHeader."No.") + 10000;

        ReminderLine.Init();
        ReminderLine."Reminder No." := ReminderNo;
        ReminderLine."Line No." := NextLineNo;
        ReminderLine."Line Type" := LineType;
        ReminderLine.Description := Description;
    end;

    local procedure CustAmountLCY(CurrencyCode: Code[10]; Amount: Decimal): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if CurrencyCode <> '' then
            exit(
              CurrExchRate.ExchangeAmtFCYToLCY(
                ReminderHeaderReq."Posting Date", CurrencyCode, Amount,
                CurrExchRate.ExchangeRate(ReminderHeaderReq."Posting Date", CurrencyCode)));
        exit(Amount);
    end;

    local procedure FilterCustLedgEntries(var ReminderLevel2: Record "Reminder Level")
    var
        ReminderLevel3: Record "Reminder Level";
        LastLevel: Boolean;
    begin
        if SkipCurrentReminderLevel(ReminderLevel2."No.") then begin
            CustLedgEntry.SetRange("Last Issued Reminder Level", -1);
            exit;
        end;
        ReminderLevel3 := ReminderLevel2;
        ReminderLevel3.CopyFilters(ReminderLevel2);
        if ReminderLevel3.Next = 0 then
            LastLevel := true
        else
            LastLevel := false;
        if ReminderTerms."Max. No. of Reminders" > 0 then
            if ReminderLevel2."No." <= ReminderTerms."Max. No. of Reminders" then
                if LastLevel then
                    CustLedgEntry.SetRange("Last Issued Reminder Level", ReminderLevel2."No." - 1, ReminderTerms."Max. No. of Reminders" - 1)
                else
                    CustLedgEntry.SetRange("Last Issued Reminder Level", ReminderLevel2."No." - 1)
            else
                CustLedgEntry.SetRange("Last Issued Reminder Level", -1)
        else
            if LastLevel then
                CustLedgEntry.SetFilter("Last Issued Reminder Level", '%1..', ReminderLevel2."No." - 1)
            else
                CustLedgEntry.SetRange("Last Issued Reminder Level", ReminderLevel2."No." - 1);
    end;

    local procedure SkipCurrentReminderLevel(ReminderLevelNo: Integer): Boolean
    var
        "Integer": Record "Integer";
    begin
        if CustLedgEntryLastIssuedReminderLevelFilter = '' then
            exit(false);

        Integer.SetFilter(Number, CustLedgEntryLastIssuedReminderLevelFilter);
        Integer.FindSet;
        if Integer.Number > ReminderLevelNo - 1 then
            exit(true);
        repeat
            if Integer.Number = ReminderLevelNo - 1 then
                exit(false)
        until Integer.Next = 0;
        exit(true);
    end;

    local procedure FilterCustLedgEntryReminderLevel(var CustLedgEntry: Record "Cust. Ledger Entry"; var ReminderLevel: Record "Reminder Level"; CurrencyCode: Code[10])
    begin
        with Cust do begin
            CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Due Date", "Currency Code");
            CustLedgEntry.SetRange(Open, true);
            CustLedgEntry.SetRange("Customer No.", "No.");
            CustLedgEntry.SetRange("Due Date");
            CustLedgEntry.SetRange("Currency Code", CurrencyCode);
            ReminderLevel.SetRange("Reminder Terms Code", ReminderTerms.Code);
        end;

        OnAfterFilterCustLedgEntryReminderLevel(CustLedgEntry, ReminderLevel, ReminderTerms, Cust);
    end;

    local procedure SetReminderLine(var LineLevel2: Integer; var ReminderDueDate2: Date)
    begin
        if CustLedgEntry."Last Issued Reminder Level" > 0 then begin
            ReminderEntry.SetCurrentKey("Customer Entry No.", Type);
            ReminderEntry.SetRange("Customer Entry No.", CustLedgEntry."Entry No.");
            ReminderEntry.SetRange(Type, ReminderEntry.Type::Reminder);
            ReminderEntry.SetRange("Reminder Level", CustLedgEntry."Last Issued Reminder Level");
            if ReminderEntry.FindLast then begin
                ReminderDueDate2 := ReminderEntry."Due Date";
                LineLevel2 := ReminderEntry."Reminder Level" + 1;
                exit;
            end
        end;
        ReminderDueDate2 := CustLedgEntry."Due Date";
        LineLevel2 := 1;
    end;

    procedure AddLineFeeForCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; var ReminderLevel: Record "Reminder Level"; NextLineNo: Integer)
    var
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        ReminderLine: Record "Reminder Line";
        IssuedReminderLine: Record "Issued Reminder Line";
        CustPostingGr: Record "Customer Posting Group";
        LineFeeAmount: Decimal;
    begin
        TempCustLedgEntry := CustLedgEntry;
        TempCustLedgEntry.Insert();
        TempCustLedgEntry.Reset();
        TempCustLedgEntry.CopyFilters(CustLedgEntryLineFeeFilters);
        if not TempCustLedgEntry.FindFirst then
            exit;

        CustLedgEntry.CalcFields("Remaining Amount");
        LineFeeAmount := ReminderLevel.GetAdditionalFee(CustLedgEntry."Remaining Amount",
            ReminderHeader."Currency Code", true, ReminderHeader."Posting Date");
        if LineFeeAmount = 0 then
            exit;

        IssuedReminderLine.SetRange(Type, IssuedReminderLine.Type::"Line Fee");
        IssuedReminderLine.SetRange("Applies-To Document Type", CustLedgEntry."Document Type");
        IssuedReminderLine.SetRange("Applies-To Document No.", CustLedgEntry."Document No.");
        IssuedReminderLine.SetRange("No. of Reminders", ReminderLevel."No.");
        IssuedReminderLine.SetRange(Canceled, false);
        if not IssuedReminderLine.IsEmpty then
            exit;

        CustPostingGr.Get(ReminderHeader."Customer Posting Group");

        NextLineNo := NextLineNo + 100;
        ReminderLine.Init();
        ReminderLine.Validate("Reminder No.", ReminderHeader."No.");
        ReminderLine.Validate("Line No.", NextLineNo);
        ReminderLine.Validate(Type, ReminderLine.Type::"Line Fee");
        ReminderLine.Validate("No.", CustPostingGr.GetAddFeePerLineAccount);
        ReminderLine.Validate("No. of Reminders", ReminderLevel."No.");
        ReminderLine.Validate("Applies-to Document Type", CustLedgEntry."Document Type");
        ReminderLine.Validate("Applies-to Document No.", CustLedgEntry."Document No.");
        ReminderLine.Validate("Due Date", CalcDate(ReminderLevel."Due Date Calculation", ReminderHeader."Document Date"));
        ReminderLine.Insert(true);
    end;

    local procedure GetLastLineNo(ReminderNo: Code[20]): Integer
    var
        ReminderLineExtra: Record "Reminder Line";
    begin
        ReminderLineExtra.SetRange("Reminder No.", ReminderNo);
        if ReminderLineExtra.FindLast then;
        exit(ReminderLineExtra."Line No.");
    end;

    local procedure SetReminderLevel(ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line"; LineLevel: Integer)
    begin
        if ReminderHeader."Use Header Level" then
            ReminderLine."No. of Reminders" := ReminderHeader."Reminder Level"
        else
            ReminderLine."No. of Reminders" := LineLevel;
    end;

    local procedure RemoveLinesOfNegativeReminder(var ReminderHeader: Record "Reminder Header")
    var
        ReminderTotal: Decimal;
    begin
        ReminderHeader.CalcFields(
          "Remaining Amount", "Interest Amount", "Additional Fee", "VAT Amount");

        ReminderTotal := ReminderHeader."Remaining Amount" + ReminderHeader."Interest Amount" +
          ReminderHeader."Additional Fee" + ReminderHeader."VAT Amount";

        if ReminderTotal < 0 then
            ReminderHeader.Delete(true);
    end;

    local procedure GetOpenEntriesNotDueOnHoldTranslated(CustomerLanguageCode: Code[10]; var OpenEntriesNotDueTranslated: Text[100]; var OpenEntriesOnHoldTranslated: Text[100])
    var
        Language: Codeunit Language;
        CurrentLanguageCode: Integer;
    begin
        if CustomerLanguageCode <> '' then begin
            CurrentLanguageCode := GlobalLanguage;
            GlobalLanguage(Language.GetLanguageIdOrDefault(CustomerLanguageCode));
            OpenEntriesNotDueTranslated := Text0000;
            OpenEntriesOnHoldTranslated := Text0001;
            GlobalLanguage(CurrentLanguageCode);
        end else begin
            OpenEntriesNotDueTranslated := Text0000;
            OpenEntriesOnHoldTranslated := Text0001;
        end;
    end;

    local procedure RemoveNotDueLinesInSectionReminderLine(ReminderLine: Record "Reminder Line")
    var
        ReminderLineToDelete: Record "Reminder Line";
    begin
        with ReminderLineToDelete do begin
            SetRange("Reminder No.", ReminderLine."Reminder No.");
            SetRange(Type, ReminderLine.Type);
            SetRange("Entry No.", ReminderLine."Entry No.");
            SetRange("Document Type", ReminderLine."Document Type");
            SetRange("Document No.", ReminderLine."Document No.");
            SetFilter("Line Type", '<>%1', ReminderLine."Line Type");
            if FindFirst then
                Delete(true);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterCustLedgEntryReminderLevel(var CustLedgerEntry: Record "Cust. Ledger Entry"; var ReminderLevel: Record "Reminder Level"; ReminderTerms: Record "Reminder Terms"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMakeReminder(var ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSet(var Cust: Record Customer; var CustLedgEntry: Record "Cust. Ledger Entry"; var ReminderHeaderReq: Record "Reminder Header"; var OverdueEntriesOnly: Boolean; var IncludeEntriesOnHold: Boolean; var CustLedgEntryLinefeeOn: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustLedgerEntryFind(var CustLedgerEntry: Record "Cust. Ledger Entry"; ReminderHeader: Record "Reminder Header"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReminderHeaderFind(var ReminderHeader: Record "Reminder Header"; ReminderHeaderReq: Record "Reminder Header"; ReminderTerms: Record "Reminder Terms"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReminderHeaderInsert(var ReminderHeader: Record "Reminder Header"; ReminderHeaderReq: Record "Reminder Header"; ReminderTerms: Record "Reminder Terms"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReminderHeaderModify(var ReminderHeader: Record "Reminder Header"; var ReminderHeaderReq: Record "Reminder Header"; HeaderExists: Boolean; ReminderTerms: Record "Reminder Terms"; Customer: Record Customer; ReminderLevel: Record "Reminder Level")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReminderLineInsert(var ReminderLine: Record "Reminder Line"; ReminderHeader: Record "Reminder Header"; ReminderLevel: Record "Reminder Level"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;
}

