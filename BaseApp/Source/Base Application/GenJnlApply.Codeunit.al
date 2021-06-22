codeunit 225 "Gen. Jnl.-Apply"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        GenJnlLine.Copy(Rec);

        IsHandled := false;
        OnBeforeRun(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        with GenJnlLine do begin
            GetCurrency;
            if "Bal. Account Type" in
               ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::Employee]
            then begin
                AccType := "Bal. Account Type";
                AccNo := "Bal. Account No.";
            end else begin
                AccType := "Account Type";
                AccNo := "Account No.";
            end;
            case AccType of
                AccType::Customer:
                    ApplyCustomerLedgerEntry(GenJnlLine);
                AccType::Vendor:
                    ApplyVendorLedgerEntry(GenJnlLine);
                AccType::Employee:
                    ApplyEmployeeLedgerEntry(GenJnlLine);
                else
                    Error(
                      Text005,
                      FieldCaption("Account Type"), FieldCaption("Bal. Account Type"));
            end;
        end;
        OnAfterRun(GenJnlLine);

        Rec := GenJnlLine;
    end;

    var
        Text000: Label 'You must specify %1 or %2.';
        ConfirmChangeQst: Label 'CurrencyCode in the %1 will be changed from %2 to %3.\Do you wish to continue?', Comment = '%1 = Table Name, %2 and %3 = Currency Code';
        UpdateInterruptedErr: Label 'The update has been interrupted to respect the warning.';
        Text005: Label 'The %1 or %2 must be Customer or Vendor.';
        Text006: Label 'All entries in one application must be in the same currency.';
        Text007: Label 'All entries in one application must be in the same currency or one or more of the EMU currencies. ';
        GenJnlLine: Record "Gen. Journal Line";
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
        AccNo: Code[20];
        CurrencyCode2: Code[10];
        EntrySelected: Boolean;
        AccType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner",Employee;

    local procedure SelectCustLedgEntry(var GenJnlLine: Record "Gen. Journal Line") Selected: Boolean
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        ApplyCustEntries: Page "Apply Customer Entries";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectCustLedgEntry(GenJnlLine, AccNo, Selected, IsHandled);
        if IsHandled then
            exit(Selected);

        with GenJnlLine do begin
            CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
            CustLedgEntry.SetRange("Customer No.", AccNo);
            CustLedgEntry.SetRange(Open, true);
            OnSelectCustLedgEntryOnAfterSetFilters(CustLedgEntry, GenJnlLine);
            if "Applies-to ID" = '' then
                "Applies-to ID" := "Document No.";
            if "Applies-to ID" = '' then
                Error(
                  Text000,
                  FieldCaption("Document No."), FieldCaption("Applies-to ID"));
            ApplyCustEntries.SetGenJnlLine(GenJnlLine, FieldNo("Applies-to ID"));
            ApplyCustEntries.SetRecord(CustLedgEntry);
            ApplyCustEntries.SetTableView(CustLedgEntry);
            ApplyCustEntries.LookupMode(true);
            Selected := ApplyCustEntries.RunModal = ACTION::LookupOK;
            Clear(ApplyCustEntries);
        end;

        OnAfterSelectCustLedgEntry(GenJnlLine, AccNo, Selected);
    end;

    local procedure SelectVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line") Selected: Boolean
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        ApplyVendEntries: Page "Apply Vendor Entries";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectVendLedgEntry(GenJnlLine, AccNo, Selected, IsHandled);
        if IsHandled then
            exit(Selected);

        with GenJnlLine do begin
            VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive);
            VendLedgEntry.SetRange("Vendor No.", AccNo);
            VendLedgEntry.SetRange(Open, true);
            OnSelectVendLedgEntryOnAfterSetFilters(VendLedgEntry, GenJnlLine);
            if "Applies-to ID" = '' then
                "Applies-to ID" := "Document No.";
            if "Applies-to ID" = '' then
                Error(
                  Text000,
                  FieldCaption("Document No."), FieldCaption("Applies-to ID"));
            ApplyVendEntries.SetGenJnlLine(GenJnlLine, FieldNo("Applies-to ID"));
            ApplyVendEntries.SetRecord(VendLedgEntry);
            ApplyVendEntries.SetTableView(VendLedgEntry);
            ApplyVendEntries.LookupMode(true);
            Selected := ApplyVendEntries.RunModal = ACTION::LookupOK;
            Clear(ApplyVendEntries);
        end;

        OnAfterSelectVendLedgEntry(GenJnlLine, AccNo, Selected);
    end;

    local procedure SelectEmplLedgEntry(var GenJnlLine: Record "Gen. Journal Line") Selected: Boolean
    var
        EmplLedgEntry: Record "Employee Ledger Entry";
        ApplyEmplEntries: Page "Apply Employee Entries";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectEmplLedgEntry(GenJnlLine, AccNo, Selected, IsHandled);
        if IsHandled then
            exit(Selected);

        with GenJnlLine do begin
            EmplLedgEntry.SetCurrentKey("Employee No.", Open, Positive);
            EmplLedgEntry.SetRange("Employee No.", AccNo);
            EmplLedgEntry.SetRange(Open, true);
            OnSelectEmplLedgEntryOnAfterSetFilters(EmplLedgEntry, GenJnlLine);
            if "Applies-to ID" = '' then
                "Applies-to ID" := "Document No.";
            if "Applies-to ID" = '' then
                Error(
                  Text000,
                  FieldCaption("Document No."), FieldCaption("Applies-to ID"));
            ApplyEmplEntries.SetGenJnlLine(GenJnlLine, FieldNo("Applies-to ID"));
            ApplyEmplEntries.SetRecord(EmplLedgEntry);
            ApplyEmplEntries.SetTableView(EmplLedgEntry);
            ApplyEmplEntries.LookupMode(true);
            Selected := ApplyEmplEntries.RunModal = ACTION::LookupOK;
            Clear(ApplyEmplEntries);
        end;

        OnAfterSelectEmplLedgEntry(GenJnlLine, AccNo, Selected);
    end;

    local procedure UpdateCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        with GenJnlLine do begin
            CustLedgEntry.CalcFields("Remaining Amount");
            CustLedgEntry."Remaining Amount" :=
              CurrExchRate.ExchangeAmount(
                CustLedgEntry."Remaining Amount", CustLedgEntry."Currency Code", "Currency Code", "Posting Date");
            CustLedgEntry."Remaining Amount" :=
              Round(CustLedgEntry."Remaining Amount", Currency."Amount Rounding Precision");
            CustLedgEntry."Remaining Pmt. Disc. Possible" :=
              CurrExchRate.ExchangeAmount(
                CustLedgEntry."Remaining Pmt. Disc. Possible", CustLedgEntry."Currency Code", "Currency Code", "Posting Date");
            CustLedgEntry."Remaining Pmt. Disc. Possible" :=
              Round(CustLedgEntry."Remaining Pmt. Disc. Possible", Currency."Amount Rounding Precision");
            CustLedgEntry."Amount to Apply" :=
              CurrExchRate.ExchangeAmount(
                CustLedgEntry."Amount to Apply", CustLedgEntry."Currency Code", "Currency Code", "Posting Date");
            CustLedgEntry."Amount to Apply" :=
              Round(CustLedgEntry."Amount to Apply", Currency."Amount Rounding Precision");
        end;
    end;

    local procedure UpdateVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        with GenJnlLine do begin
            VendLedgEntry.CalcFields("Remaining Amount");
            VendLedgEntry."Remaining Amount" :=
              CurrExchRate.ExchangeAmount(
                VendLedgEntry."Remaining Amount", VendLedgEntry."Currency Code", "Currency Code", "Posting Date");
            VendLedgEntry."Remaining Amount" :=
              Round(VendLedgEntry."Remaining Amount", Currency."Amount Rounding Precision");
            VendLedgEntry."Remaining Pmt. Disc. Possible" :=
              CurrExchRate.ExchangeAmount(
                VendLedgEntry."Remaining Pmt. Disc. Possible", VendLedgEntry."Currency Code", "Currency Code", "Posting Date");
            VendLedgEntry."Remaining Pmt. Disc. Possible" :=
              Round(VendLedgEntry."Remaining Pmt. Disc. Possible", Currency."Amount Rounding Precision");
            VendLedgEntry."Amount to Apply" :=
              CurrExchRate.ExchangeAmount(
                VendLedgEntry."Amount to Apply", VendLedgEntry."Currency Code", "Currency Code", "Posting Date");
            VendLedgEntry."Amount to Apply" :=
              Round(VendLedgEntry."Amount to Apply", Currency."Amount Rounding Precision");
        end;
    end;

    procedure CheckAgainstApplnCurrency(ApplnCurrencyCode: Code[10]; CompareCurrencyCode: Code[10]; AccType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset"; Message: Boolean): Boolean
    var
        Currency: Record Currency;
        Currency2: Record Currency;
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        CurrencyAppln: Option No,EMU,All;
    begin
        if ApplnCurrencyCode = CompareCurrencyCode then
            exit(true);

        case AccType of
            AccType::Customer:
                begin
                    SalesSetup.Get();
                    CurrencyAppln := SalesSetup."Appln. between Currencies";
                    case CurrencyAppln of
                        CurrencyAppln::No:
                            begin
                                if ApplnCurrencyCode <> CompareCurrencyCode then
                                    if Message then
                                        Error(Text006)
                                    else
                                        exit(false);
                            end;
                        CurrencyAppln::EMU:
                            begin
                                GLSetup.Get();
                                if not Currency.Get(ApplnCurrencyCode) then
                                    Currency."EMU Currency" := GLSetup."EMU Currency";
                                if not Currency2.Get(CompareCurrencyCode) then
                                    Currency2."EMU Currency" := GLSetup."EMU Currency";
                                if not Currency."EMU Currency" or not Currency2."EMU Currency" then
                                    if Message then
                                        Error(Text007)
                                    else
                                        exit(false);
                            end;
                    end;
                end;
            AccType::Vendor:
                begin
                    PurchSetup.Get();
                    CurrencyAppln := PurchSetup."Appln. between Currencies";
                    case CurrencyAppln of
                        CurrencyAppln::No:
                            begin
                                if ApplnCurrencyCode <> CompareCurrencyCode then
                                    if Message then
                                        Error(Text006)
                                    else
                                        exit(false);
                            end;
                        CurrencyAppln::EMU:
                            begin
                                GLSetup.Get();
                                if not Currency.Get(ApplnCurrencyCode) then
                                    Currency."EMU Currency" := GLSetup."EMU Currency";
                                if not Currency2.Get(CompareCurrencyCode) then
                                    Currency2."EMU Currency" := GLSetup."EMU Currency";
                                if not Currency."EMU Currency" or not Currency2."EMU Currency" then
                                    if Message then
                                        Error(Text007)
                                    else
                                        exit(false);
                            end;
                    end;
                end;
        end;

        exit(true);
    end;

    local procedure GetCurrency()
    begin
        with GenJnlLine do
            if "Currency Code" = '' then
                Currency.InitRoundingPrecision
            else begin
                Currency.Get("Currency Code");
                Currency.TestField("Amount Rounding Precision");
            end;
    end;

    local procedure ApplyCustomerLedgerEntry(var GenJnlLine: Record "Gen. Journal Line")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        IsHandled: Boolean;
    begin
        with GenJnlLine do begin
            EntrySelected := SelectCustLedgEntry(GenJnlLine);
            if not EntrySelected then
                exit;

            CustLedgEntry.Reset();
            CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
            CustLedgEntry.SetRange("Customer No.", AccNo);
            CustLedgEntry.SetRange(Open, true);
            CustLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
            OnAfterCustLedgEntrySetFilters(CustLedgEntry, GenJnlLine, AccNo);
            if CustLedgEntry.Find('-') then begin
                CurrencyCode2 := CustLedgEntry."Currency Code";
                if Amount = 0 then begin
                    repeat
                        PaymentToleranceMgt.DelPmtTolApllnDocNo(GenJnlLine, CustLedgEntry."Document No.");
                        OnApplyCustomerLedgerEntryOnBeforeCheckAgainstApplnCurrency(GenJnlLine, CustLedgEntry);
                        CheckAgainstApplnCurrency(CurrencyCode2, CustLedgEntry."Currency Code", AccType::Customer, true);
                        UpdateCustLedgEntry(CustLedgEntry);
                        IsHandled := false;
                        OnBeforeFindCustApply(GenJnlLine, CustLedgEntry, Amount, IsHandled);
                        if not IsHandled then
                            if PaymentToleranceMgt.CheckCalcPmtDiscGenJnlCust(GenJnlLine, CustLedgEntry, 0, false) and
                               (Abs(CustLedgEntry."Amount to Apply") >=
                                Abs(CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible"))
                            then
                                Amount := Amount - (CustLedgEntry."Amount to Apply" - CustLedgEntry."Remaining Pmt. Disc. Possible")
                            else
                                Amount := Amount - CustLedgEntry."Amount to Apply";
                    until CustLedgEntry.Next = 0;
                    if ("Bal. Account Type" = "Bal. Account Type"::Customer) or ("Bal. Account Type" = "Bal. Account Type"::Vendor) then
                        Amount := -Amount;
                    Validate(Amount);
                end else
                    repeat
                        CheckAgainstApplnCurrency(CurrencyCode2, CustLedgEntry."Currency Code", AccType::Customer, true);
                    until CustLedgEntry.Next = 0;
                if "Currency Code" <> CurrencyCode2 then
                    if Amount = 0 then begin
                        ConfirmCurrencyUpdate(GenJnlLine, CustLedgEntry."Currency Code");
                        "Currency Code" := CustLedgEntry."Currency Code"
                    end else
                        CheckAgainstApplnCurrency("Currency Code", CustLedgEntry."Currency Code", AccType::Customer, true);
                "Applies-to Doc. Type" := 0;
                "Applies-to Doc. No." := '';
            end else
                "Applies-to ID" := '';

            SetJournalLineFieldsFromApplication;

            if Modify then;
            if Amount <> 0 then
                if not PaymentToleranceMgt.PmtTolGenJnl(GenJnlLine) then
                    exit;
        end;
    end;

    local procedure ApplyVendorLedgerEntry(var GenJnlLine: Record "Gen. Journal Line")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        IsHandled: Boolean;
    begin
        with GenJnlLine do begin
            EntrySelected := SelectVendLedgEntry(GenJnlLine);
            if not EntrySelected then
                exit;

            VendLedgEntry.Reset();
            VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive);
            VendLedgEntry.SetRange("Vendor No.", AccNo);
            VendLedgEntry.SetRange(Open, true);
            VendLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
            OnAfterVendLedgEntrySetFilters(VendLedgEntry, GenJnlLine, AccNo);
            if VendLedgEntry.Find('-') then begin
                CurrencyCode2 := VendLedgEntry."Currency Code";
                if Amount = 0 then begin
                    repeat
                        PaymentToleranceMgt.DelPmtTolApllnDocNo(GenJnlLine, VendLedgEntry."Document No.");
                        OnApplyVendorLedgerEntryOnBeforeCheckAgainstApplnCurrency(GenJnlLine, VendLedgEntry);
                        CheckAgainstApplnCurrency(CurrencyCode2, VendLedgEntry."Currency Code", AccType::Vendor, true);
                        UpdateVendLedgEntry(VendLedgEntry);
                        IsHandled := false;
                        OnBeforeFindVendApply(GenJnlLine, VendLedgEntry, Amount, IsHandled);
                        if not IsHandled then
                            if PaymentToleranceMgt.CheckCalcPmtDiscGenJnlVend(GenJnlLine, VendLedgEntry, 0, false) and
                               (Abs(VendLedgEntry."Amount to Apply") >=
                                Abs(VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible"))
                            then
                                Amount := Amount - (VendLedgEntry."Amount to Apply" - VendLedgEntry."Remaining Pmt. Disc. Possible")
                            else
                                Amount := Amount - VendLedgEntry."Amount to Apply";
                    until VendLedgEntry.Next = 0;
                    if ("Bal. Account Type" = "Bal. Account Type"::Customer) or ("Bal. Account Type" = "Bal. Account Type"::Vendor) then
                        Amount := -Amount;
                    Validate(Amount);
                end else
                    repeat
                        CheckAgainstApplnCurrency(CurrencyCode2, VendLedgEntry."Currency Code", AccType::Vendor, true);
                    until VendLedgEntry.Next = 0;
                if "Currency Code" <> CurrencyCode2 then
                    if Amount = 0 then begin
                        ConfirmCurrencyUpdate(GenJnlLine, VendLedgEntry."Currency Code");
                        "Currency Code" := VendLedgEntry."Currency Code"
                    end else
                        CheckAgainstApplnCurrency("Currency Code", VendLedgEntry."Currency Code", AccType::Vendor, true);
                "Applies-to Doc. Type" := 0;
                "Applies-to Doc. No." := '';
            end else
                "Applies-to ID" := '';

            SetJournalLineFieldsFromApplication;

            if Modify then;
            if Amount <> 0 then
                if not PaymentToleranceMgt.PmtTolGenJnl(GenJnlLine) then
                    exit;
        end;
    end;

    local procedure ApplyEmployeeLedgerEntry(var GenJnlLine: Record "Gen. Journal Line")
    var
        EmplLedgEntry: Record "Employee Ledger Entry";
    begin
        with GenJnlLine do begin
            EntrySelected := SelectEmplLedgEntry(GenJnlLine);
            if not EntrySelected then
                exit;

            EmplLedgEntry.Reset();
            EmplLedgEntry.SetCurrentKey("Employee No.", Open, Positive);
            EmplLedgEntry.SetRange("Employee No.", AccNo);
            EmplLedgEntry.SetRange(Open, true);
            EmplLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
            if EmplLedgEntry.Find('-') then begin
                if Amount = 0 then begin
                    repeat
                        OnApplyEmployeeLedgerEntryOnBeforeUpdateAmount(GenJnlLine, EmplLedgEntry);
                        Amount := Amount - EmplLedgEntry."Amount to Apply";
                    until EmplLedgEntry.Next = 0;
                    if ("Bal. Account Type" = "Bal. Account Type"::Customer) or
                       ("Bal. Account Type" = "Bal. Account Type"::Vendor) or
                       ("Bal. Account Type" = "Bal. Account Type"::Employee)
                    then
                        Amount := -Amount;
                    Validate(Amount);
                end;
                "Applies-to Doc. Type" := 0;
                "Applies-to Doc. No." := '';
            end else
                "Applies-to ID" := '';

            SetJournalLineFieldsFromApplication;

            if Modify then;
        end;

        OnAfterApplyEmployeeLedgerEntry(GenJnlLine, EmplLedgEntry);
    end;

    local procedure ConfirmCurrencyUpdate(GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10])
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ConfirmManagement.GetResponseOrDefault(
             StrSubstNo(
               ConfirmChangeQst, GenJournalLine.TableCaption, GenJournalLine."Currency Code",
               CurrencyCode), true)
        then
            Error(UpdateInterruptedErr);
    end;

    [Scope('OnPrem')]
    procedure GetEntrySelected(): Boolean
    begin
        exit(EntrySelected);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCustLedgEntrySetFilters(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterVendLedgEntrySetFilters(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyEmployeeLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSelectCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var AccNo: Code[20]; var Selected: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSelectEmplLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var AccNo: Code[20]; var Selected: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSelectVendLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var AccNo: Code[20]; var Selected: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustomerLedgerEntryOnBeforeCheckAgainstApplnCurrency(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendorLedgerEntryOnBeforeCheckAgainstApplnCurrency(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyEmployeeLedgerEntryOnBeforeUpdateAmount(var GenJournalLine: Record "Gen. Journal Line"; EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindCustApply(GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry"; var Amount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindVendApply(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; var Amount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var AccNo: Code[20]; var Selected: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectEmplLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var AccNo: Code[20]; var Selected: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectVendLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var AccNo: Code[20]; var Selected: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectCustLedgEntryOnAfterSetFilters(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectEmplLedgEntryOnAfterSetFilters(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectVendLedgEntryOnAfterSetFilters(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

