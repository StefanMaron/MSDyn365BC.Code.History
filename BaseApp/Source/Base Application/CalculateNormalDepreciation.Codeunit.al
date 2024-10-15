codeunit 5611 "Calculate Normal Depreciation"
{
    Permissions = TableData "FA Ledger Entry" = r,
                  TableData "FA Posting Type Setup" = r;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Force No. of Days must only be specified if %1 %2 = %3.';
        Text001: Label '%2 must not be 100 for %1.';
        Text002: Label '%2 must be %3 if %4 %5 = %6 for %1.';
        Text003: Label '%2 must not be later than %3 for %1.';
        Text004: Label '%1 %2 must not be used together with the Half-Year Convention for %3.';
        FA: Record "Fixed Asset";
        FALedgEntry: Record "FA Ledger Entry";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        DepreciationCalc: Codeunit "Depreciation Calculation";
        TempFALedgEntry3: Record "FA Ledger Entry" temporary;
        DeprBookCode: Code[10];
        DaysInFiscalYear: Integer;
        EntryAmounts: array[4] of Decimal;
        MinusBookValue: Decimal;
        DateFromProjection: Date;
        SkipOnZero: Boolean;
        UntilDate: Date;
        Sign: Integer;
        FirstDeprDate: Date;
        NumberOfDays: Integer;
        NumberOfDays2: Integer;
        DaysInPeriod: Integer;
        UseDeprStartingDate: Boolean;
        BookValue: Decimal;
        BookValue2: Decimal;
        DeprBasis: Decimal;
        SalvageValue: Decimal;
        SalvageValue2: Decimal;
        AcquisitionDate: Date;
        DisposalDate: Date;
        DeprMethod: Option StraightLine,DB1,DB2,DB1SL,DB2SL,"User-Defined",Manual,BelowZero;
        DeprStartingDate: Date;
        FirstUserDefinedDeprDate: Date;
        SLPercent: Decimal;
        DBPercent: Decimal;
        FixedAmount: Decimal;
        DeprYears: Decimal;
        DeprTableCode: Code[10];
        FinalRoundingAmount: Decimal;
        EndingBookValue: Decimal;
        AmountBelowZero: Decimal;
        PercentBelowZero: Decimal;
        StartingDate: Date;
        EndingDate: Date;
        Factor: Decimal;
        UseHalfYearConvention: Boolean;
        NewYearDate: Date;
        DeprInTwoFiscalYears: Boolean;
        TempDeprAmount: Decimal;
        Text005: Label '%1 must not be used together with the Half-Year Convention for %2.';
        Text006: Label '%1 must be %2 or later for %3.';
        Text007: Label '%1 must not be used together with %2 for %3.';
        Text008: Label '%1 must not be used together with %2 = %3 for %4.';
        Year365Days: Boolean;
        ProjValue: Boolean;
        NoOfProjectedDays: Decimal;
        AccountingPeriodErr: Label 'ENU=Accounting Period for %1 is missing.\Tax Depreciation for Fixed Asset %2 cannot be calculated correctly.\Create Accounting Periods for all life cycle of Fixed Asset %2 for correct Tax Depreciation calculation.', Comment = '@@@="%1 = date; %2 = number of fixed asset"';

    procedure Calculate(var DeprAmount: Decimal; var NumberOfDays4: Integer; FANo: Code[20]; DeprBookCode2: Code[10]; UntilDate2: Date; EntryAmounts2: array[4] of Decimal; DateFromProjection2: Date; DaysInPeriod2: Integer)
    var
        i: Integer;
    begin
        // NAVCZ
        if ProjValue then begin
            ClearAll;
            ProjValue := true;
        end else
            // NAVCZ
            ClearAll;

        DeprAmount := 0;
        NumberOfDays4 := 0;
        DeprBookCode := DeprBookCode2;
        FA.Get(FANo);
        DeprBook.Get(DeprBookCode);
        if not FADeprBook.Get(FANo, DeprBookCode) then
            exit;
        UntilDate := UntilDate2;
        for i := 1 to 4 do
            EntryAmounts[i] := EntryAmounts2[i];
        DateFromProjection := DateFromProjection2;
        DaysInPeriod := DaysInPeriod2;

        FALedgEntry.LockTable;
        with DeprBook do
            if DaysInPeriod > 0 then
                if "Periodic Depr. Date Calc." <> "Periodic Depr. Date Calc."::"Last Entry" then begin
                    "Periodic Depr. Date Calc." := "Periodic Depr. Date Calc."::"Last Entry";
                    Error(
                      Text000,
                      TableCaption, FieldCaption("Periodic Depr. Date Calc."), "Periodic Depr. Date Calc.");
                end;
        TransferValues;
        if not SkipRecord then begin
            Sign := 1;
            if not FADeprBook."Use FA Ledger Check" then begin
                FADeprBook.TestField("Fixed Depr. Amount below Zero", 0);
                FADeprBook.TestField("Depr. below Zero %", 0);
                Sign := DepreciationCalc.GetSign(BookValue, DeprBasis, SalvageValue, MinusBookValue);
                if Sign = 0 then
                    exit;
                if Sign = -1 then
                    DepreciationCalc.GetNewSigns(BookValue, DeprBasis, SalvageValue, MinusBookValue);
            end;
            if (FADeprBook."Fixed Depr. Amount below Zero" > 0) or
               (FADeprBook."Depr. below Zero %" > 0)
            then
                FADeprBook.TestField("Use FA Ledger Check", true);

            if BookValue + SalvageValue <= 0 then
                SkipOnZero := true;
            if (SalvageValue >= 0) and (BookValue <= EndingBookValue) then
                SkipOnZero := true;

            if not
               (SkipOnZero and
                not DeprBook."Allow Depr. below Zero" and
                not FADeprBook."Use FA Ledger Check") // NAVCZ
            then begin
                if SkipOnZero then
                    DeprMethod := DeprMethod::BelowZero;
                DeprAmount := Sign * CalculateDeprAmount;
                if Sign * DeprAmount > 0 then
                    DeprAmount := 0;
                NumberOfDays4 := NumberOfDays2;
            end;
        end;
    end;

    local procedure SkipRecord(): Boolean
    begin
        exit(
          (DisposalDate > 0D) or
          (AcquisitionDate = 0D) or
          (DeprMethod = DeprMethod::Manual) or
          (AcquisitionDate > UntilDate) or
          FA.Inactive or
          FA.Blocked);
    end;

    local procedure CalculateDeprAmount(): Decimal
    var
        Amount: Decimal;
    begin
        with FA do begin
            if DateFromProjection > 0D then
                FirstDeprDate := DateFromProjection
            else begin
                FirstDeprDate := DepreciationCalc.GetFirstDeprDate("No.", DeprBookCode, Year365Days);
                if FirstDeprDate > UntilDate then
                    exit(0);
                UseDeprStartingDate := DepreciationCalc.UseDeprStartingDate("No.", DeprBookCode);
                if UseDeprStartingDate then
                    FirstDeprDate := DeprStartingDate;
            end;

            // NAVCZ
            if FADeprBook."Depr. FA Appreciation From" > FirstDeprDate then
                FirstDeprDate := FADeprBook."Depr. FA Appreciation From";
            // NAVCZ

            if FirstDeprDate < DeprStartingDate then
                FirstDeprDate := DeprStartingDate;
            NumberOfDays := DepreciationCalc.DeprDays(FirstDeprDate, UntilDate, Year365Days);
            Factor := 1;
            if NumberOfDays <= 0 then
                exit(0);
            if DaysInPeriod > 0 then begin
                Factor := DaysInPeriod / NumberOfDays;
                NumberOfDays := DaysInPeriod;
            end;
            UseHalfYearConvention := SetHalfYearConventionMethod;
            // Method Last Entry
            if UseDeprStartingDate or
               (DateFromProjection > 0D) or
               (DeprMethod = DeprMethod::BelowZero) or
               (DeprBook."Periodic Depr. Date Calc." = DeprBook."Periodic Depr. Date Calc."::"Last Entry")
            then begin
                NumberOfDays2 := NumberOfDays;
                // NAVCZ
                if (FADeprBook."Depreciation Group Code" <> '') or
                   (FADeprBook."Summarize Depr. Entries From" <> '')
                then
                    Amount := CalcTaxAmount
                else
                    // NAVCZ
                    if UseHalfYearConvention then
                        Amount := CalcHalfYearConventionDepr
                    else
                        case DeprMethod of
                            DeprMethod::StraightLine:
                                Amount := CalcSLAmount;
                            DeprMethod::DB1:
                                Amount := CalcDB1Amount;
                            DeprMethod::DB2:
                                Amount := CalcDB2Amount;
                            DeprMethod::DB1SL,
                          DeprMethod::DB2SL:
                                Amount := CalcDBSLAmount;
                            DeprMethod::Manual:
                                Amount := 0;
                            DeprMethod::"User-Defined":
                                Amount := CalcUserDefinedAmount(UntilDate);
                            DeprMethod::BelowZero:
                                Amount := DepreciationCalc.CalcRounding(DeprBookCode, CalcBelowZeroAmount);
                        end;
            end
            // Method Last Depreciation Entry
            else begin
                if UseHalfYearConvention then
                    DeprBook.TestField(
                      "Periodic Depr. Date Calc.", DeprBook."Periodic Depr. Date Calc."::"Last Entry");
                Amount := 0;
                StartingDate := 0D;
                EndingDate := 0D;
                DepreciationCalc.GetDeprPeriod(
                  "No.", DeprBookCode, UntilDate, StartingDate, EndingDate, NumberOfDays, Year365Days);
                FirstDeprDate := StartingDate;
                NumberOfDays2 := DepreciationCalc.DeprDays(FirstDeprDate, UntilDate, Year365Days);
                while NumberOfDays > 0 do begin
                    DepreciationCalc.CalculateDeprInPeriod(
                      "No.", DeprBookCode, EndingDate, Amount, Sign,
                      BookValue, DeprBasis, SalvageValue, MinusBookValue);
                    if DepreciationCalc.GetSign(
                         BookValue, DeprBasis, SalvageValue, MinusBookValue) <> 1
                    then
                        exit(0);
                    // NAVCZ
                    if (FADeprBook."Depreciation Group Code" <> '') or
                       (FADeprBook."Summarize Depr. Entries From" <> '')
                    then
                        Amount := Amount + CalcTaxAmount
                    else
                        // NAVCZ
                        case DeprMethod of
                            DeprMethod::StraightLine:
                                Amount := Amount + CalcSLAmount;
                            DeprMethod::DB1:
                                Amount := Amount + CalcDB1Amount;
                            DeprMethod::DB2:
                                Amount := Amount + CalcDB2Amount;
                            DeprMethod::Manual:
                                Amount := 0;
                            DeprMethod::"User-Defined":
                                Amount := Amount + CalcUserDefinedAmount(EndingDate);
                        end;
                    DepreciationCalc.GetDeprPeriod(
                      "No.", DeprBookCode, UntilDate, StartingDate, EndingDate, NumberOfDays, Year365Days);
                    FirstDeprDate := StartingDate;
                end;
            end;
        end;
        if Amount >= 0 then
            exit(0);
        if not SkipOnZero then
            DepreciationCalc.AdjustDepr(
              DeprBookCode, Amount, Abs(BookValue2), -Abs(SalvageValue2),
              EndingBookValue, FinalRoundingAmount);

        OnAfterCalculateDeprAmount(
          FA, SkipOnZero, DeprBookCode, Amount, Abs(BookValue2), -Abs(SalvageValue2), EndingBookValue, FinalRoundingAmount);

        exit(Round(Amount));
    end;

    local procedure CalcTempDeprAmount(var DeprAmount: Decimal): Boolean
    begin
        DeprAmount := 0;
        if FADeprBook."Temp. Ending Date" = 0D then
            exit(false);
        if (FirstDeprDate <= FADeprBook."Temp. Ending Date") and (UntilDate > FADeprBook."Temp. Ending Date") then
            Error(
              Text006,
              FADeprBook.FieldCaption("Temp. Ending Date"),
              UntilDate,
              FAName);
        if FADeprBook."Temp. Ending Date" >= UntilDate then begin
            if FADeprBook."Use Half-Year Convention" then
                Error(
                  Text005,
                  FADeprBook.FieldCaption("Temp. Ending Date"),
                  FAName);
            if FADeprBook."Use DB% First Fiscal Year" then
                Error(
                  Text007,
                  FADeprBook.FieldCaption("Temp. Ending Date"),
                  FADeprBook.FieldCaption("Use DB% First Fiscal Year"),
                  FAName);
            if FADeprBook."Depreciation Method" = FADeprBook."Depreciation Method"::"User-Defined" then
                Error(
                  Text008,
                  FADeprBook.FieldCaption("Temp. Ending Date"),
                  FADeprBook.FieldCaption("Depreciation Method"),
                  FADeprBook."Depreciation Method",
                  FAName);
            if DeprMethod = DeprMethod::BelowZero then
                Error(
                  Text007,
                  FADeprBook.FieldCaption("Temp. Ending Date"),
                  DeprBook.FieldCaption("Allow Depr. below Zero"),
                  FAName);
            DeprBook.TestField(
              "Periodic Depr. Date Calc.", DeprBook."Periodic Depr. Date Calc."::"Last Entry");
            DeprAmount := -(NumberOfDays / DaysInFiscalYear) * FADeprBook."Temp. Fixed Depr. Amount";
            exit(true)
        end;
        exit(false);
    end;

    local procedure CalcSLAmount(): Decimal
    var
        RemainingLife: Decimal;
        IsHandled: Boolean;
        Result: Decimal;
    begin
        if CalcTempDeprAmount(TempDeprAmount) then
            exit(TempDeprAmount);

        if SLPercent > 0 then
            exit((-SLPercent / 100) * (NumberOfDays / DaysInFiscalYear) * DeprBasis);

        if FixedAmount > 0 then
            exit(-FixedAmount * NumberOfDays / DaysInFiscalYear);

        if DeprYears > 0 then begin
            RemainingLife :=
              (DeprYears * DaysInFiscalYear) -
              DepreciationCalc.DeprDays(
                DeprStartingDate, DepreciationCalc.Yesterday(FirstDeprDate, Year365Days), Year365Days);
            // NAVCZ
            if not FADeprBook."Keep Depr. Ending Date" then
                RemainingLife += CalcDeprBreakDays(0D, 0D, true);
            // NAVCZ
            if RemainingLife < 1 then
                exit(-BookValue);

            IsHandled := false;
            OnAfterCalcSL(FA, FADeprBook, UntilDate, BookValue, DeprBasis, DeprYears, NumberOfDays, DaysInFiscalYear, Result, IsHandled);
            if IsHandled then
                exit(Result);

            exit(-(BookValue + SalvageValue - MinusBookValue) * NumberOfDays / RemainingLife);
        end;
        exit(0);
    end;

    local procedure CalcDB1Amount(): Decimal
    var
        DeprInFiscalYear: Decimal;
    begin
        if CalcTempDeprAmount(TempDeprAmount) then
            exit(TempDeprAmount);

        if DateFromProjection = 0D then
            DeprInFiscalYear := DepreciationCalc.DeprInFiscalYear(FA."No.", DeprBookCode, UntilDate)
        else
            DeprInFiscalYear := EntryAmounts[3];
        if DeprInTwoFiscalYears then
            DeprInFiscalYear := 0;
        exit(
          -(DBPercent / 100) * (NumberOfDays / DaysInFiscalYear) *
          (BookValue + SalvageValue - MinusBookValue - Sign * DeprInFiscalYear));
    end;

    local procedure CalcDB2Amount(): Decimal
    begin
        if CalcTempDeprAmount(TempDeprAmount) then
            exit(TempDeprAmount);

        exit(
          -(1 - Power(1 - DBPercent / 100, NumberOfDays / DaysInFiscalYear)) *
          (BookValue - MinusBookValue));
    end;

    local procedure CalcDBSLAmount(): Decimal
    var
        FADateCalc: Codeunit "FA Date Calculation";
        SLAmount: Decimal;
        DBAmount: Decimal;
    begin
        if DeprMethod = DeprMethod::DB1SL then
            DBAmount := CalcDB1Amount
        else
            DBAmount := CalcDB2Amount;
        if FADeprBook."Use DB% First Fiscal Year" then
            if FADateCalc.GetFiscalYear(DeprBookCode, UntilDate) =
               FADateCalc.GetFiscalYear(DeprBookCode, DeprStartingDate)
            then
                exit(DBAmount);
        SLAmount := CalcSLAmount;
        if SLAmount < DBAmount then
            exit(SLAmount);

        exit(DBAmount)
    end;

    local procedure CalcUserDefinedAmount(EndingDate: Date): Decimal
    var
        TableDeprCalc: Codeunit "Table Depr. Calculation";
    begin
        if CalcTempDeprAmount(TempDeprAmount) then
            Error('');

        exit(
          -TableDeprCalc.GetTablePercent(DeprBook.Code, DeprTableCode,
            FirstUserDefinedDeprDate, FirstDeprDate, EndingDate) *
          DeprBasis * Factor);
    end;

    local procedure CalcBelowZeroAmount(): Decimal
    begin
        if CalcTempDeprAmount(TempDeprAmount) then
            Error('');

        if PercentBelowZero > 0 then
            exit((-PercentBelowZero / 100) * (NumberOfDays / DaysInFiscalYear) * DeprBasis);
        if AmountBelowZero > 0 then
            exit(-AmountBelowZero * NumberOfDays / DaysInFiscalYear);
        exit(0);
    end;

    local procedure TransferValues()
    begin
        with FADeprBook do begin
            TestField("Depreciation Starting Date");
            if "Depreciation Method" = "Depreciation Method"::"User-Defined" then
                // NAVCZ
                if "Depreciation Group Code" = '' then begin
                    // NAVCZ
                    TestField("Depreciation Table Code");
                    TestField("First User-Defined Depr. Date");
                end;
            case "Depreciation Method" of
                "Depreciation Method"::"Declining-Balance 1",
              "Depreciation Method"::"Declining-Balance 2",
              "Depreciation Method"::"DB1/SL",
              "Depreciation Method"::"DB2/SL":
                    if "Declining-Balance %" >= 100 then
                        Error(Text001, FAName, FieldCaption("Declining-Balance %"));
            end;
            if (DeprBook."Periodic Depr. Date Calc." = DeprBook."Periodic Depr. Date Calc."::"Last Depr. Entry") and
               ("Depreciation Method" <> "Depreciation Method"::"Straight-Line") and
               // NAVCZ
               ("Depreciation Group Code" = '')
            // NAVCZ
            then begin
                "Depreciation Method" := "Depreciation Method"::"Straight-Line";
                Error(
                  Text002,
                  FAName,
                  FieldCaption("Depreciation Method"),
                  "Depreciation Method",
                  DeprBook.TableCaption,
                  DeprBook.FieldCaption("Periodic Depr. Date Calc."),
                  DeprBook."Periodic Depr. Date Calc.");
            end;

            if DateFromProjection = 0D then begin
                CalcFields("Book Value");
                BookValue := "Book Value";
            end else
                BookValue := EntryAmounts[1];
            MinusBookValue := DepreciationCalc.GetMinusBookValue(FA."No.", DeprBookCode, 0D, 0D);

            // NAVCZ
            if "Depr. FA Appreciation From" > "Depreciation Starting Date" then
                SetFilter("FA Posting Date Filter", '%1..', "Depr. FA Appreciation From");
            // NAVCZ

            CalcFields("Depreciable Basis", "Salvage Value");
            DeprBasis := "Depreciable Basis";
            SalvageValue := "Salvage Value";
            BookValue2 := BookValue;
            SalvageValue2 := SalvageValue;
            DeprMethod := "Depreciation Method";
            DeprStartingDate := "Depreciation Starting Date";
            DeprTableCode := "Depreciation Table Code";
            FirstUserDefinedDeprDate := "First User-Defined Depr. Date";
            if ("Depreciation Method" = "Depreciation Method"::"User-Defined") and
               (FirstUserDefinedDeprDate > DeprStartingDate)
            then
                Error(
                  Text003,
                  FAName, FieldCaption("First User-Defined Depr. Date"), FieldCaption("Depreciation Starting Date"));
            SLPercent := "Straight-Line %";
            DBPercent := "Declining-Balance %";
            DeprYears := "No. of Depreciation Years";
            if "Depreciation Ending Date" > 0D then begin
                if "Depreciation Starting Date" > "Depreciation Ending Date" then
                    Error(
                      Text003,
                      FAName, FieldCaption("Depreciation Starting Date"), FieldCaption("Depreciation Ending Date"));
                DeprYears :=
                  DepreciationCalc.DeprDays(
                    "Depreciation Starting Date", "Depreciation Ending Date", false) / 360;
            end;
            FixedAmount := "Fixed Depr. Amount";
            FinalRoundingAmount := "Final Rounding Amount";
            if FinalRoundingAmount = 0 then
                FinalRoundingAmount := DeprBook."Default Final Rounding Amount";
            EndingBookValue := "Ending Book Value";
            if not "Ignore Def. Ending Book Value" and (EndingBookValue = 0) then
                EndingBookValue := DeprBook."Default Ending Book Value";
            AcquisitionDate := "Acquisition Date";
            DisposalDate := "Disposal Date";
            PercentBelowZero := "Depr. below Zero %";
            AmountBelowZero := "Fixed Depr. Amount below Zero";
            DaysInFiscalYear := DeprBook."No. of Days in Fiscal Year";
            if DaysInFiscalYear = 0 then
                DaysInFiscalYear := 360;
            Year365Days := DeprBook."Fiscal Year 365 Days";
            if Year365Days then begin
                DaysInFiscalYear := 365;
                DeprYears :=
                  DepreciationCalc.DeprDays(
                    "Depreciation Starting Date", "Depreciation Ending Date", true) / DaysInFiscalYear;
            end;
        end;

        OnAfterTransferValues(FA, FADeprBook, Year365Days, DeprYears);
    end;

    local procedure FAName(): Text[200]
    var
        DepreciationCalc: Codeunit "Depreciation Calculation";
    begin
        exit(DepreciationCalc.FAName(FA, DeprBookCode));
    end;

    local procedure SetHalfYearConventionMethod(): Boolean
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if not FADeprBook."Use Half-Year Convention" then
            exit(false);
        if FADeprBook."Depreciation Method" = FADeprBook."Depreciation Method"::Manual then
            exit(false);
        if DeprMethod = DeprMethod::BelowZero then
            exit(false);
        if AccountingPeriod.IsEmpty then
            exit(false);

        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetFilter(
          "Starting Date", '>=%1',
          DepreciationCalc.ToMorrow(FADeprBook."Depreciation Starting Date", Year365Days));
        AccountingPeriod.FindFirst;
        NewYearDate := AccountingPeriod."Starting Date";
        if FirstDeprDate >= NewYearDate then
            exit(false);

        if DeprBook."No. of Days in Fiscal Year" <> 0 then
            DeprBook.TestField("No. of Days in Fiscal Year", 360);
        if DeprMethod in
           [DeprMethod::DB2,
            DeprMethod::DB2SL,
            DeprMethod::"User-Defined"]
        then
            Error(
              Text004,
              FADeprBook.FieldCaption("Depreciation Method"),
              FADeprBook."Depreciation Method",
              FAName);
        exit(true);
    end;

    local procedure CalcHalfYearConventionDepr(): Decimal
    var
        DeprAmount: Decimal;
        HalfYearPercent: Decimal;
        HalfYearFactor: Decimal;
        OriginalNumberOfDays: Integer;
        OriginalBookValue: Decimal;
        OriginalFirstDeprDate: Date;
    begin
        if CalcTempDeprAmount(TempDeprAmount) then
            Error('');

        if (DeprMethod = DeprMethod::DB1) or (DeprMethod = DeprMethod::DB1SL) then
            HalfYearPercent := DBPercent
        else
            if SLPercent > 0 then
                HalfYearPercent := SLPercent
            else
                if DeprYears > 0 then
                    HalfYearPercent :=
                      100 /
                      (DepreciationCalc.DeprDays(NewYearDate, FADeprBook."Depreciation Ending Date", Year365Days) +
                       DaysInFiscalYear / 2) * DaysInFiscalYear
                else
                    HalfYearPercent := 0;

        HalfYearFactor :=
          DaysInFiscalYear / 2 /
          DepreciationCalc.DeprDays(
            FADeprBook."Depreciation Starting Date",
            DepreciationCalc.Yesterday(NewYearDate, Year365Days),
            Year365Days);
        DeprInTwoFiscalYears := UntilDate >= NewYearDate;

        OriginalNumberOfDays := NumberOfDays;
        OriginalBookValue := BookValue;
        OriginalFirstDeprDate := FirstDeprDate;

        if DeprInTwoFiscalYears then
            NumberOfDays :=
              DepreciationCalc.DeprDays(
                FirstDeprDate, DepreciationCalc.Yesterday(NewYearDate, Year365Days), Year365Days);
        if FixedAmount > 0 then
            DeprAmount := -FixedAmount * NumberOfDays / DaysInFiscalYear * HalfYearFactor
        else
            DeprAmount :=
              (-HalfYearPercent / 100) * (NumberOfDays / DaysInFiscalYear) * DeprBasis * HalfYearFactor;
        if DeprInTwoFiscalYears then begin
            NumberOfDays := DepreciationCalc.DeprDays(NewYearDate, UntilDate, Year365Days);
            FirstDeprDate := NewYearDate;
            BookValue := BookValue + DeprAmount;
            case DeprMethod of
                DeprMethod::StraightLine:
                    DeprAmount := DeprAmount + CalcSLAmount;
                DeprMethod::DB1:
                    DeprAmount := DeprAmount + CalcDB1Amount;
                DeprMethod::DB1SL:
                    DeprAmount := DeprAmount + CalcDBSLAmount;
            end;
        end;
        NumberOfDays := OriginalNumberOfDays;
        BookValue := OriginalBookValue;
        FirstDeprDate := OriginalFirstDeprDate;
        DeprInTwoFiscalYears := false;
        exit(DeprAmount);
    end;

    [Scope('OnPrem')]
    procedure CalcTaxAmount(): Decimal
    var
        DepGroup: Record "Depreciation Group";
        TempFADepBook: Record "FA Depreciation Book";
        FALeEntry: Record "FA Ledger Entry";
        DateLastAppr: Date;
        DateLastDepr: Date;
        TaxDeprAmount: Decimal;
        TempNoDays: Integer;
        TempFaktor: Decimal;
        TempToDate: Date;
        TempFromDate: Date;
        TempDepBasis: Decimal;
        TempBookValue: Decimal;
        CounterDepr: Integer;
        RemainingLife: Decimal;
        DepreciatedDays: Decimal;
        Denominator: Decimal;
    begin
        // NAVCZ
        if BookValue = 0 then
            exit(0);
        DateLastAppr := AcquisitionDate;
        DateLastDepr := FADeprBook."Last Depreciation Date";
        if DateLastDepr = 0D then
            DateLastDepr := CalcDate('<-1Y>', CalcEndOfFiscalYear(AcquisitionDate));
        TempNoDays := NumberOfDays;
        TempToDate := DateLastDepr;

        if TempNoDays < DaysInFiscalYear then
            TempFaktor := TempNoDays / DaysInFiscalYear
        else
            TempFaktor := 1;

        TempFADepBook.Get(FADeprBook."FA No.", FADeprBook."Depreciation Book Code");

        FALeEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "FA Posting Date");
        FALeEntry.SetRange("FA Posting Category", FALeEntry."FA Posting Category"::" ");
        FALeEntry.SetRange("FA No.", FADeprBook."FA No.");
        FALeEntry.SetRange("Depreciation Book Code", FADeprBook."Depreciation Book Code");
        FALeEntry.SetRange("FA Posting Type", FALeEntry."FA Posting Type"::Appreciation);

        if DateFromProjection <> 0D then
            TempFromDate := DateFromProjection
        else
            TempFromDate := TempToDate + 1;
        if TempNoDays >= DaysInFiscalYear then begin
            TempToDate := CalcEndOfFiscalYear(TempFromDate);
        end else
            TempToDate := UntilDate;

        DepGroup.SetRange(Code, FADeprBook."Depreciation Group Code");
        DepGroup.SetRange("Starting Date", 0D, TempFromDate);
        if not DepGroup.FindLast then
            if FADeprBook."Summarize Depr. Entries From" = '' then
                exit(0);

        TempFADepBook.SetFilter("FA Posting Date Filter", '..%1', UntilDate);
        TempFADepBook.CalcFields("Depreciable Basis", "Book Value", "Salvage Value");
        if BookValue < TempFADepBook."Book Value" then
            TempFADepBook."Book Value" := BookValue;
        TempDepBasis := TempFADepBook."Depreciable Basis";
        TempBookValue := TempFADepBook."Book Value" - TaxDeprAmount + TempFADepBook."Salvage Value";
        if FADeprBook.Prorated then begin
            TempFADepBook.SetRange("FA Posting Date Filter", CalcStartOfFiscalYear(UntilDate), UntilDate);
            TempFADepBook.CalcFields(Depreciation);
            TempBookValue := TempBookValue - TempFADepBook.Depreciation;
        end;

        FALeEntry.SetFilter("FA Posting Date", '..%1', UntilDate);
        if FALeEntry.FindLast then
            DateLastAppr := FALeEntry."FA Posting Date";
        FALeEntry.SetRange("FA Posting Date", CalcEndOfFiscalYear(AcquisitionDate) + 1, UntilDate);
        if FALeEntry.FindFirst then;

        if FADeprBook."Summarize Depr. Entries From" <> '' then begin
            TaxDeprAmount :=
              CalcDepreciatedAmount(FADeprBook."FA No.", FADeprBook."Summarize Depr. Entries From", TempFromDate, UntilDate);
            NumberOfDays2 :=
              CalcDepreciatedDays(FADeprBook."FA No.", FADeprBook."Summarize Depr. Entries From", TempFromDate, UntilDate);
            exit(-Round(TaxDeprAmount, 1, '>'));
        end;
        with DepGroup do
            case "Depreciation Type" of
                "Depreciation Type"::"Straight-line":
                    if not IsNonZeroDeprecation(FADeprBook."FA No.", FADeprBook."Depreciation Book Code", TempFromDate) then
                        TaxDeprAmount := TaxDeprAmount + TempDepBasis * "Straight First Year" / 100
                    else begin
                        if CalcEndOfFiscalYear(DateLastAppr) = CalcEndOfFiscalYear(AcquisitionDate) then
                            TaxDeprAmount := TaxDeprAmount + TempDepBasis * "Straight Next Years" / 100
                        else
                            TaxDeprAmount := TaxDeprAmount + TempDepBasis * "Straight Appreciation" / 100;
                    end;
                "Depreciation Type"::"Declining-Balance":
                    begin
                        CounterDepr := CalcDepr(CalcEndOfFiscalYear(DateLastAppr), CalcEndOfFiscalYear(UntilDate), FALeEntry);
                        if not IsNonZeroDeprecation(FADeprBook."FA No.", FADeprBook."Depreciation Book Code", TempFromDate) then begin
                            TaxDeprAmount := TaxDeprAmount + TempDepBasis / "Declining First Year";
                            if "Declining Depr. Increase %" <> 0 then
                                TaxDeprAmount := TaxDeprAmount + (TempDepBasis * "Declining Depr. Increase %" / 100);
                        end else begin
                            TempFADepBook.CalcFields(Depreciation);
                            if ProjValue then
                                if CounterDepr <> 0 then begin
                                    CalculateProjectedValues(0D, CalcStartOfFiscalYear(UntilDate) - 1);
                                    TempBookValue := TempBookValue + TempFALedgEntry3.Amount;
                                end;
                            if CalcEndOfFiscalYear(DateLastAppr) = CalcEndOfFiscalYear(AcquisitionDate) then
                              // NAVCZ
                              begin
                                Denominator := "Declining Next Years" - CounterDepr;
                                if Denominator < 2 then
                                    Denominator := 2;
                                // NAVCZ
                                TaxDeprAmount :=
                                  // NAVCZ
                                  TaxDeprAmount + (2 * TempBookValue / Denominator)
                            end
                            // NAVCZ
                            else
                                if CounterDepr = 0 then
                                    TaxDeprAmount := TaxDeprAmount + 2 * TempBookValue / "Declining Appreciation"
                                else
                                  // NAVCZ
                                  begin
                                    Denominator := "Declining Appreciation" - CounterDepr;
                                    if Denominator < 2 then
                                        Denominator := 2;
                                    // NAVCZ
                                    TaxDeprAmount :=
                                      // NAVCZ
                                      TaxDeprAmount + (2 * TempBookValue / Denominator);
                                end;
                            // NAVCZ
                        end;
                    end;
                "Depreciation Type"::"Straight-line Intangible":
                    begin
                        RemainingLife := (DeprYears * DaysInFiscalYear) -
                          DepreciationCalc.DeprDays(DeprStartingDate, DepreciationCalc.Yesterday(FirstDeprDate, Year365Days), Year365Days) +
                          CalcDeprBreakDays(0D, 0D, true);
                        if DateLastAppr <> AcquisitionDate then begin
                            // NAVCZ
                            DepreciatedDays := CalcDeprBreakDays(CalcDate('<CM+1D>', DateLastAppr), UntilDate, false);
                            // NAVCZ
                            if RemainingLife + DepreciatedDays < "Min. Months After Appreciation" * 30 then begin
                                RemainingLife := "Min. Months After Appreciation" * 30 - DepreciatedDays;
                                if ProjValue then begin
                                    CalculateProjectedValues(0D, UntilDate);
                                    RemainingLife := RemainingLife - NoOfProjectedDays;
                                end;
                            end else begin
                                if ProjValue then
                                    CalculateProjectedValues(0D, UntilDate);
                            end;
                        end else begin
                            if ProjValue then
                                CalculateProjectedValues(0D, UntilDate);
                        end;
                        if ProjValue then
                            TempBookValue := TempBookValue + TempFALedgEntry3.Amount;
                        if RemainingLife <> 0 then
                            TaxDeprAmount := TempBookValue / RemainingLife * TempNoDays;
                    end;
            end;

        // NAVCZ
        if FADeprBook."Depr. FA Appreciation From" <> 0D then begin
            FADeprBook.SetRange("FA Posting Date Filter", FADeprBook."Depr. FA Appreciation From", UntilDate);
            FADeprBook.CalcFields("Depreciable Basis", "Book Value");
            TempDepBasis := FADeprBook."Depreciable Basis";
            TempBookValue := FADeprBook."Book Value";
            if DepGroup."Depreciation Type" = DepGroup."Depreciation Type"::"Straight-line" then begin
                TaxDeprAmount := TempDepBasis * DepGroup."Straight Appreciation" / 100;
            end else begin
                CounterDepr := CalcDepr(FADeprBook."Depr. FA Appreciation From", CalcEndOfFiscalYear(UntilDate), FALeEntry);
                if CounterDepr = DepGroup."Declining Appreciation" then
                    TaxDeprAmount := 0
                else
                    TaxDeprAmount := 2 * TempBookValue / (DepGroup."Declining Appreciation" - CounterDepr);
            end;
        end;
        // NAVCZ

        if DepGroup."Depreciation Type" <> DepGroup."Depreciation Type"::"Straight-line Intangible" then
            if FADeprBook.Prorated then begin
                if not ProjValue then begin
                    TaxDeprAmount := TaxDeprAmount *
                      DepreciationCalc.DeprDays(CalcStartOfFiscalYear(UntilDate), UntilDate, Year365Days) / 360 -
                      CalcDepreciatedAmount(FADeprBook."FA No.", FADeprBook."Depreciation Book Code", 0D, UntilDate);
                    NumberOfDays2 := DepreciationCalc.DeprDays(CalcStartOfFiscalYear(UntilDate), UntilDate, Year365Days) -
                      CalcDepreciatedDays(FADeprBook."FA No.", FADeprBook."Depreciation Book Code", 0D, UntilDate);
                end else begin
                    CalculateProjectedValues(CalcStartOfFiscalYear(UntilDate), UntilDate);
                    TaxDeprAmount := TaxDeprAmount *
                      DepreciationCalc.DeprDays(CalcStartOfFiscalYear(UntilDate), UntilDate, Year365Days) / 360 -
                      CalcDepreciatedAmount(FADeprBook."FA No.", FADeprBook."Depreciation Book Code", 0D, UntilDate) +
                      TempFALedgEntry3.Amount;
                    NumberOfDays2 :=
                      DepreciationCalc.DeprDays(CalcStartOfFiscalYear(UntilDate), UntilDate, Year365Days) -
                      NoOfProjectedDays;
                end;
            end else
                if TempFaktor < 1 then
                    TaxDeprAmount := TaxDeprAmount * TempFaktor;
        if DeprBook."Use Rounding in Periodic Depr." then
            TaxDeprAmount := Round(Round(TaxDeprAmount), 1, '>');

        exit(-TaxDeprAmount);
    end;

    [Scope('OnPrem')]
    procedure CalcEndOfFiscalYear(StartingDate: Date) EndFiscYear: Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        // NAVCZ
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetFilter("Starting Date", '>%1', StartingDate);
        if AccountingPeriod.FindFirst then
            EndFiscYear := CalcDate('<-1D>', AccountingPeriod."Starting Date")
        else
            EndFiscYear := CalcDate('<CY>', StartingDate);
    end;

    local procedure CalcDepr(LastAppr: Date; UntilDate: Date; var FALeEntry: Record "FA Ledger Entry"): Integer
    var
        TempFALeEntry: Record "FA Ledger Entry";
        Year: Record "Integer" temporary;
    begin
        // NAVCZ
        TempFALeEntry.CopyFilters(FALeEntry);
        TempFALeEntry.SetRange("FA Posting Type", TempFALeEntry."FA Posting Type"::Depreciation);
        TempFALeEntry.SetRange("FA Posting Date", LastAppr, UntilDate);
        TempFALeEntry.SetRange(Amount, 0);
        if TempFALeEntry.FindSet then
            repeat
                Year.Number := Date2DMY(TempFALeEntry."FA Posting Date", 3);
                if Year.Insert then;
            until TempFALeEntry.Next = 0;
        exit(FiscalYearCount(LastAppr, UntilDate, FALeEntry.GetFilter("FA No.")) - Year.Count); // NAVCZ
    end;

    [Scope('OnPrem')]
    procedure CalcDeprBreakDays(StartDate: Date; EndDate: Date; DeprBreak: Boolean) DeprBreakDays: Decimal
    var
        FALedgEntry2: Record "FA Ledger Entry";
    begin
        // NAVCZ
        Clear(DeprBreakDays);
        FALedgEntry2.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "FA Posting Date");
        FALedgEntry2.SetRange("FA Posting Category", FALedgEntry2."FA Posting Category"::" ");
        FALedgEntry2.SetRange("FA No.", FADeprBook."FA No.");
        FALedgEntry2.SetRange("Depreciation Book Code", FADeprBook."Depreciation Book Code");
        FALedgEntry2.SetRange("FA Posting Type", FALedgEntry2."FA Posting Type"::Depreciation);
        if (StartDate <> 0D) and (EndDate <> 0D) then
            FALedgEntry2.SetRange("FA Posting Date", StartDate + 1, EndDate);
        if DeprBreak then
            FALedgEntry2.SetRange(Amount, 0)
        else
            FALedgEntry2.SetFilter(Amount, '<>%1', 0);
        if FALedgEntry2.FindSet then
            repeat
                DeprBreakDays += FALedgEntry2."No. of Depreciation Days";
            until FALedgEntry2.Next = 0;
        exit(DeprBreakDays);
    end;

    [Scope('OnPrem')]
    procedure CalcStartOfFiscalYear(StartingDate: Date) StartFiscYear: Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        // NAVCZ
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetFilter("Starting Date", '>%1', StartingDate);
        if AccountingPeriod.FindFirst then
            StartFiscYear := CalcDate('<-1Y>', AccountingPeriod."Starting Date")
        else
            StartFiscYear := CalcDate('<-CY>', StartingDate);
    end;

    [Scope('OnPrem')]
    procedure CalcDepreciatedAmount(FANo: Code[20]; FADeprBookCode: Code[10]; StartDate: Date; EndDate: Date): Decimal
    var
        FADeprBook2: Record "FA Depreciation Book";
    begin
        // NAVCZ
        FADeprBook2.Get(FANo, FADeprBookCode);
        if StartDate <> 0D then
            FADeprBook2.SetRange("FA Posting Date Filter", StartDate, EndDate)
        else
            FADeprBook2.SetRange("FA Posting Date Filter", CalcStartOfFiscalYear(EndDate), EndDate);
        FADeprBook2.CalcFields(Depreciation);
        exit(-FADeprBook2.Depreciation);
    end;

    [Scope('OnPrem')]
    procedure ProjectedValue(ProjValue2: Boolean)
    begin
        ProjValue := ProjValue2;
    end;

    [Scope('OnPrem')]
    procedure CalcDepreciatedDays(FANo: Code[20]; FADeprBookCode: Code[10]; StartDate: Date; EndDate: Date): Integer
    var
        FALedgEntry2: Record "FA Ledger Entry";
        NoOfDepreciatedDays: Integer;
    begin
        Clear(NoOfDepreciatedDays);
        FALedgEntry2.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "FA Posting Date");
        FALedgEntry2.SetRange("FA Posting Category", FALedgEntry2."FA Posting Category"::" ");
        FALedgEntry2.SetRange("FA No.", FANo);
        FALedgEntry2.SetRange("Depreciation Book Code", FADeprBookCode);
        FALedgEntry2.SetRange("FA Posting Type", FALedgEntry2."FA Posting Type"::Depreciation);
        if StartDate <> 0D then
            FALedgEntry2.SetRange("FA Posting Date", StartDate, EndDate)
        else
            FALedgEntry2.SetRange("FA Posting Date", CalcStartOfFiscalYear(EndDate), EndDate);
        if FALedgEntry2.FindSet then
            repeat
                NoOfDepreciatedDays += FALedgEntry2."No. of Depreciation Days";
            until FALedgEntry2.Next = 0;
        exit(NoOfDepreciatedDays);
    end;

    [Scope('OnPrem')]
    procedure TransferProjectedValues(var FALedgEntry2: Record "FA Ledger Entry")
    begin
        TempFALedgEntry3.Reset;
        TempFALedgEntry3.DeleteAll;
        if FALedgEntry2.Find('-') then
            repeat
                TempFALedgEntry3.Init;
                TempFALedgEntry3.TransferFields(FALedgEntry2);
                TempFALedgEntry3.Insert;
            until FALedgEntry2.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure CalculateProjectedValues(StartDate: Date; EndDate: Date)
    begin
        NoOfProjectedDays := 0;
        TempFALedgEntry3.Reset;
        if StartDate <> 0D then
            TempFALedgEntry3.SetRange("FA Posting Date", StartDate, EndDate)
        else
            TempFALedgEntry3.SetFilter("FA Posting Date", '..%1', EndDate);
        if TempFALedgEntry3.Find('-') then
            repeat
                NoOfProjectedDays += TempFALedgEntry3."No. of Depreciation Days";
            until TempFALedgEntry3.Next = 0;
        TempFALedgEntry3.CalcSums(Amount);
    end;

    local procedure IsNonZeroDeprecation(FANo: Code[20]; DeprBookCode: Code[10]; TempFromDate: Date): Boolean
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // NAVCZ
        IF FADeprBook.Prorated THEN
            EXIT(TempFromDate >= CalcEndOfFiscalYear(AcquisitionDate));

        DepreciationCalc.SetFAFilter(FALedgerEntry, FANo, DeprBookCode, true);
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
        FALedgerEntry.SetFilter(Amount, '<>%1', 0);
        exit(not FALedgerEntry.IsEmpty);
    end;

    local procedure FiscalYearCount(LastAppr: Date; UntilDate: Date; FANo: Code[20]): Integer;
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        // NAVCZ
        AccountingPeriod.SetFilter("Starting Date", '%1..', UntilDate);
        IF AccountingPeriod.IsEmpty() THEN
            Error(AccountingPeriodErr, UntilDate, FANo);
        AccountingPeriod.SetFilter("Starting Date", '..%1', LastAppr);
        IF AccountingPeriod.IsEmpty() THEN
            Error(AccountingPeriodErr, LastAppr, FANo);

        AccountingPeriod.SetRange("Starting Date", LastAppr, UntilDate);
        AccountingPeriod.SetRange("New Fiscal Year", true);
        exit(AccountingPeriod.Count());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateDeprAmount(FixedAsset: Record "Fixed Asset"; SkipOnZero: Boolean; DeprBookCode: Code[20]; var Amount: Decimal; BookValue: Decimal; SalvageValue: Decimal; EndingBookValue: Decimal; FinalRoundingAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcSL(FixedAsset: Record "Fixed Asset"; FADepreciationBook: Record "FA Depreciation Book"; UntilDate: Date; BookValue: Decimal; DeprBasis: Decimal; DeprYears: Decimal; NumberOfDays: Integer; DaysInFiscalYear: Integer; var ExitValue: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferValues(FixedAsset: Record "Fixed Asset"; FADepreciationBook: Record "FA Depreciation Book"; Year365Days: Boolean; var DeprYears: Decimal)
    begin
    end;
}

