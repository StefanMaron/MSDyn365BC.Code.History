#if not CLEAN18
codeunit 5610 "Calculate Depreciation"
{

    trigger OnRun()
    begin
    end;

    var
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        TempFALedgEntry: Record "FA Ledger Entry" temporary;
        CalculateNormalDepr: Codeunit "Calculate Normal Depreciation";
        CalculateCustom1Depr: Codeunit "Calculate Custom 1 Depr.";
        ProjValue: Boolean;

    procedure Calculate(var DeprAmount: Decimal; var Custom1Amount: Decimal; var NumberOfDays: Integer; var Custom1NumberOfDays: Integer; FANo: Code[20]; DeprBookCode: Code[10]; UntilDate: Date; EntryAmounts: array[4] of Decimal; DateFromProjection: Date; DaysInPeriod: Integer)
    var
        AccPeriod: Record "Accounting Period";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculate(DeprAmount, Custom1Amount, NumberOfDays, Custom1NumberOfDays, FANo, DeprBookCode, UntilDate, EntryAmounts, DateFromProjection, DaysInPeriod, IsHandled);
        if IsHandled then
            exit;

        DeprAmount := 0;
        Custom1Amount := 0;
        NumberOfDays := 0;
        Custom1NumberOfDays := 0;
        if not DeprBook.Get(DeprBookCode) then
            exit;
        if not FADeprBook.Get(FANo, DeprBookCode) then
            exit;

        // NAVCZ
        AccPeriod.SetFilter("Starting Date", '<%1', UntilDate);
        AccPeriod.SetRange("New Fiscal Year", true);
        if AccPeriod.FindLast() then;
        // NAVCZ

        CheckDeprDaysInFiscalYear(FADeprBook, DateFromProjection = 0D, UntilDate);

        if DeprBook."Use Custom 1 Depreciation" and
           (FADeprBook."Depr. Ending Date (Custom 1)" > 0D)
        then
            CalculateCustom1Depr.Calculate(
              DeprAmount, Custom1Amount, NumberOfDays,
              Custom1NumberOfDays, FANo, DeprBookCode, UntilDate,
              EntryAmounts, DateFromProjection, DaysInPeriod)
        else begin
            // NAVCZ
            CalculateNormalDepr.ProjectedValue(ProjValue);
            CalculateNormalDepr.TransferProjectedValues(TempFALedgEntry);
            // NAVCZ
            CalculateNormalDepr.Calculate(
              DeprAmount, NumberOfDays, FANo, DeprBookCode, UntilDate,
              EntryAmounts, DateFromProjection, DaysInPeriod);
        end;
        OnAfterCalcDeprYearCalculateAdditionalDepr2ndYear(DeprAmount, FANo, DeprBookCode);
    end;

    local procedure CheckDeprDaysInFiscalYear(FADeprBook: Record "FA Depreciation Book"; CheckDeprDays: Boolean; UntilDate: Date)
    var
        DepreciationCalc: Codeunit "Depreciation Calculation";
        FADateCalc: Codeunit "FA Date Calculation";
        FiscalYearBegin: Date;
        NoOfDeprDays: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDeprDaysInFiscalYear(FADeprBook, CheckDeprDays, UntilDate, IsHandled);
        if IsHandled then
            exit;

        if DeprBook."Allow more than 360/365 Days" or not CheckDeprDays then
            exit;
        if (FADeprBook."Depreciation Method" = FADeprBook."Depreciation Method"::"Declining-Balance 1") or
           (FADeprBook."Depreciation Method" = FADeprBook."Depreciation Method"::"DB1/SL")
        then
            FiscalYearBegin := FADateCalc.GetFiscalYear(DeprBook.Code, UntilDate);
        if DeprBook."Fiscal Year 365 Days" then
            NoOfDeprDays := 365
        else
            NoOfDeprDays := 360;
        if DepreciationCalc.DeprDays(
             FiscalYearBegin, UntilDate, DeprBook."Fiscal Year 365 Days") > NoOfDeprDays
        then
            DeprBook.TestField("Allow more than 360/365 Days");
    end;

    [Obsolete('Moved to Fixed Asset Localization for Czech.', '18.0')]
    [Scope('OnPrem')]
    procedure ProjectedValue(ProjValue2: Boolean)
    begin
        // NAVCZ
        ProjValue := ProjValue2;
    end;

    [Obsolete('Moved to Fixed Asset Localization for Czech.', '18.0')]
    [Scope('OnPrem')]
    procedure TransferProjectedValues(var FALedgEntry2: Record "FA Ledger Entry")
    begin
        // NAVCZ
        TempFALedgEntry.DeleteAll();
        if FALedgEntry2.Find('-') then
            repeat
                TempFALedgEntry.Init();
                TempFALedgEntry.TransferFields(FALedgEntry2);
                TempFALedgEntry.Insert();
            until FALedgEntry2.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculate(var DeprAmount: Decimal; var Custom1Amount: Decimal; var NumberOfDays: Integer; var Custom1NumberOfDays: Integer; FANo: Code[20]; DeprBookCode: Code[10]; UntilDate: Date; EntryAmounts: array[4] of Decimal; DateFromProjection: Date; DaysInPeriod: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDeprDaysInFiscalYear(FADeprBook: Record "FA Depreciation Book"; CheckDeprDays: Boolean; UntilDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcDeprYearCalculateAdditionalDepr2ndYear(var DeprAmount: Decimal; FANo: code[20]; DepreBookCode: code[10])
    begin
    end;
}

#endif