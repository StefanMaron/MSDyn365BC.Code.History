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
        DeprMethod: Enum "FA Depr. Method Internal";
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
#if not CLEAN18
        ProjValue: Boolean;
        NoOfProjectedDays: Decimal;
        AccountingPeriodErr: Label 'ENU=Accounting Period for %1 is missing.\Tax Depreciation for Fixed Asset %2 cannot be calculated correctly.\Create Accounting Periods for all life cycle of Fixed Asset %2 for correct Tax Depreciation calculation.', Comment = '@@@="%1 = date; %2 = number of fixed asset"';
#endif

    procedure Calculate(var DeprAmount: Decimal; var NumberOfDays4: Integer; FANo: Code[20]; DeprBookCode2: Code[10]; UntilDate2: Date; EntryAmounts2: array[4] of Decimal; DateFromProjection2: Date; DaysInPeriod2: Integer)
    var
        i: Integer;
        IsHandled: Boolean;
        StorageDecimal: Dictionary of [Text, Decimal];
        StorageInteger: Dictionary of [Text, Integer];
        StorageDate: Dictionary of [Text, Date];
        StorageCode: Dictionary of [Text, Code[10]];
    begin
        IsHandled := false;
        OnBeforeCalculate(DeprAmount, NumberOfDays4, FANo, DeprBookCode2, UntilDate2, EntryAmounts2, DateFromProjection2, DaysInPeriod2, IsHandled);
        if IsHandled then
            exit;

#if not CLEAN18
        // NAVCZ
        if ProjValue then begin
            ClearAll;
            ProjValue := true;
        end else
            // NAVCZ
#endif
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

        FALedgEntry.LockTable();
        with DeprBook do
            if DaysInPeriod > 0 then
                if "Periodic Depr. Date Calc." <> "Periodic Depr. Date Calc."::"Last Entry" then begin
                    "Periodic Depr. Date Calc." := "Periodic Depr. Date Calc."::"Last Entry";
                    Error(
                      Text000,
                      TableCaption, FieldCaption("Periodic Depr. Date Calc."), "Periodic Depr. Date Calc.");
                end;
        OnBeforeCalcTransferValueSetVariables(FirstDeprDate, Year365Days, UseDeprStartingDate, NumberOfDays2, UseHalfYearConvention);

        AssignVariablesToStorage(StorageDecimal, StorageInteger, StorageDate, StorageCode, DeprBookCode2, DateFromProjection2, UntilDate2, DaysInPeriod2, NumberOfDays4, DeprAmount);
        IsHandled := false;
#if not CLEAN19
        OnBeforeCalculateTransferValue(FANo, StorageDecimal, StorageInteger, StorageDate, StorageCode, EntryAmounts2, EntryAmounts, DeprMethod, Year365Days, IsHandled);
#endif
        OnCalculateOnBeforeTransferValue(FANo, StorageDecimal, StorageInteger, StorageDate, StorageCode, EntryAmounts2, EntryAmounts, DeprMethod, Year365Days, IsHandled);
        if IsHandled then
            AssignStorageToVariables(StorageDecimal, StorageInteger, StorageDate, StorageCode, DeprBookCode2, DateFromProjection2, UntilDate2, DaysInPeriod2, NumberOfDays4, DeprAmount)
        else
            TransferValues();

        if not SkipRecord() then begin
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
                IsHandled := false;
                OnAfterSkipOnZeroValue(DeprBook, SkipOnZero, IsHandled);
                if not IsHandled then
                    if SkipOnZero then
                        DeprMethod := DeprMethod::"Below Zero";

                DeprAmount := Sign * CalculateDeprAmount;

                IsHandled := false;
                OnAfterCalcFinalDeprAmount(FANo, FADeprBook, DeprBook, Sign, BookValue, DeprAmount, IsHandled);
                if not IsHandled then
                    if Sign * DeprAmount > 0 then
                        DeprAmount := 0;

                NumberOfDays4 := NumberOfDays2;
            end;
        end;
    end;

    local procedure SkipRecord(): Boolean
    var
        IsHandled: Boolean;
        ExitValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeSkipRecord(
            FA,
            DeprBook,
            DisposalDate,
            AcquisitionDate,
            UntilDate,
            DeprMethod,
            BookValue,
            DeprBasis,
            SalvageValue,
            MinusBookValue,
            ExitValue,
            IsHandled);

        if IsHandled then
            exit(ExitValue);

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
        IsHandled: Boolean;
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
            if FirstDeprDate < DeprStartingDate then
                FirstDeprDate := DeprStartingDate;

            IsHandled := false;
            OnBeforeNumberofDayCalculateNumberofDays(FA, DeprBook, NumberofDays, FirstDeprDate, UntilDate, Year365Days, IsHandled);
            if not IsHandled then
                NumberOfDays := DepreciationCalc.DeprDays(FirstDeprDate, UntilDate, Year365Days);

            Factor := 1;
            if NumberOfDays <= 0 then
                exit(0);
            if DaysInPeriod > 0 then begin
                Factor := DaysInPeriod / NumberOfDays;
                NumberOfDays := DaysInPeriod;
            end;
            UseHalfYearConvention := SetHalfYearConventionMethod();

            UpdateDaysInFiscalYear(FA, DeprBook, NumberOfDays, DaysInFiscalYear, IsHandled);

            // Method Last Entry
            if UseDeprStartingDate or
               (DateFromProjection > 0D) or
               (DeprMethod = DeprMethod::"Below Zero") or
               (DeprBook."Periodic Depr. Date Calc." = DeprBook."Periodic Depr. Date Calc."::"Last Entry")
            then begin
                NumberOfDays2 := NumberOfDays;
#if not CLEAN18
                // NAVCZ
                if (FADeprBook."Depreciation Group Code" <> '') or
                   (FADeprBook."Summarize Depr. Entries From" <> '')
                then
                    Amount := CalcTaxAmount
                else
                    // NAVCZ
#endif
                if UseHalfYearConvention then
                    Amount := CalcHalfYearConventionDepr()
                else
                    case DeprMethod of
                        DeprMethod::"Straight-Line":
                            Amount := CalcSLAmount;
                        DeprMethod::"Declining-Balance 1":
                            Amount := CalcDB1Amount;
                        DeprMethod::"Declining-Balance 2":
                            Amount := CalcDB2Amount;
                        DeprMethod::"DB1/SL",
                        DeprMethod::"DB2/SL":
                            Amount := CalcDBSLAmount;
                        DeprMethod::Manual:
                            Amount := 0;
                        DeprMethod::"User-Defined":
                            Amount := CalcUserDefinedAmount(UntilDate);
                        DeprMethod::"Below Zero":
                            Amount := DepreciationCalc.CalcRounding(DeprBookCode, CalcBelowZeroAmount());
                        DeprMethod::"Country Specific":
                            ; // Reserved for implementation of country specific methods
                        else
                            OnCalculateDeprAmountOnDeprMethodCaseLastEntry(
                                FADeprBook, BookValue, DeprBasis, DeprYears, DaysInFiscalYear, NumberOfDays, Amount, DateFromProjection, UntilDate);
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
#if not CLEAN18
                    // NAVCZ
                    if (FADeprBook."Depreciation Group Code" <> '') or
                       (FADeprBook."Summarize Depr. Entries From" <> '')
                    then
                        Amount := Amount + CalcTaxAmount
                    else
                        // NAVCZ
#endif
                    case DeprMethod of
                        DeprMethod::"Straight-Line":
                            Amount := Amount + CalcSLAmount();
                        DeprMethod::"Declining-Balance 1":
                            Amount := Amount + CalcDB1Amount();
                        DeprMethod::"Declining-Balance 2":
                            Amount := Amount + CalcDB2Amount();
                        DeprMethod::Manual:
                            Amount := 0;
                        DeprMethod::"User-Defined":
                            Amount := Amount + CalcUserDefinedAmount(EndingDate);
                        DeprMethod::"Country Specific":
                            ; // Reserved for implementation of country specific
                        else
                            OnCalculateDeprAmountOnDeprMethodCaseLastDeprEntry(
                                FADeprBook, BookValue, DeprBasis, DeprYears, DaysInFiscalYear, NumberOfDays, Amount, DateFromProjection, UntilDate);
                    end;
                    DepreciationCalc.GetDeprPeriod(
                      "No.", DeprBookCode, UntilDate, StartingDate, EndingDate, NumberOfDays, Year365Days);
                    FirstDeprDate := StartingDate;
                end;
            end;
        end;

        IsHandled := false;
        OnAfterCalculateFinalAmount(DeprBook, Amount, IsHandled);
        if not IsHandled then
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
              GetFAName());
        if FADeprBook."Temp. Ending Date" >= UntilDate then begin
            if FADeprBook."Use Half-Year Convention" then
                Error(
                  Text005,
                  FADeprBook.FieldCaption("Temp. Ending Date"),
                  GetFAName());
            if FADeprBook."Use DB% First Fiscal Year" then
                Error(
                  Text007,
                  FADeprBook.FieldCaption("Temp. Ending Date"),
                  FADeprBook.FieldCaption("Use DB% First Fiscal Year"),
                  GetFAName());
            if FADeprBook."Depreciation Method" = FADeprBook."Depreciation Method"::"User-Defined" then
                Error(
                  Text008,
                  FADeprBook.FieldCaption("Temp. Ending Date"),
                  FADeprBook.FieldCaption("Depreciation Method"),
                  FADeprBook."Depreciation Method",
                  GetFAName());
            if DeprMethod = DeprMethod::"Below Zero" then
                Error(
                  Text007,
                  FADeprBook.FieldCaption("Temp. Ending Date"),
                  DeprBook.FieldCaption("Allow Depr. below Zero"),
                  GetFAName());
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

        if SLPercent > 0 then begin
            Result := (-SLPercent / 100) * (NumberOfDays / DaysInFiscalYear) * DeprBasis;
            OnCalcSLAmountOnAfterCalcFromSLPercent(FA, FADeprBook, BookValue, DeprBasis, DaysInFiscalYear, NumberOfDays, SLPercent, Result);
            exit(Result);
        end;

        if FixedAmount > 0 then
            exit(-FixedAmount * NumberOfDays / DaysInFiscalYear);

        if DeprYears > 0 then begin
            RemainingLife :=
              (DeprYears * DaysInFiscalYear) -
              DepreciationCalc.DeprDays(
                DeprStartingDate, DepreciationCalc.Yesterday(FirstDeprDate, Year365Days), Year365Days);
#if not CLEAN18
            // NAVCZ
            if not FADeprBook."Keep Depr. Ending Date" then
                RemainingLife += CalcDeprBreakDays(0D, 0D, true);
            // NAVCZ
#endif
            if RemainingLife < 1 then begin
                Result := -BookValue;
                OnCalcSLAmountOnAfterCalcResultForRemainingLifeExpired(FA, FADeprBook, BookValue, Result);
                exit(Result);
            end;

            IsHandled := false;
            OnAfterCalcSL(FA, FADeprBook, UntilDate, BookValue, DeprBasis, DeprYears, NumberOfDays, DaysInFiscalYear, Result, IsHandled, RemainingLife, FirstDeprDate);
            if IsHandled then
                exit(Result);

            exit(-(BookValue + SalvageValue - MinusBookValue) * NumberOfDays / RemainingLife);
        end;
        exit(0);
    end;

    local procedure CalcDB1Amount() Result: Decimal
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

        result := -(DBPercent / 100) * (NumberOfDays / DaysInFiscalYear) *
          (BookValue + SalvageValue - MinusBookValue - Sign * DeprInFiscalYear);

        OnAfterCalcDB1Amount(DBPercent, NumberOfDays, DaysInFiscalYear, BookValue, SalvageValue, MinusBookValue, Sign, DeprInFiscalYear, Result);
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
        if DeprMethod = DeprMethod::"DB1/SL" then
            DBAmount := CalcDB1Amount
        else
            DBAmount := CalcDB2Amount();
        if FADeprBook."Use DB% First Fiscal Year" then
            if FADateCalc.GetFiscalYear(DeprBookCode, UntilDate) =
               FADateCalc.GetFiscalYear(DeprBookCode, DeprStartingDate)
            then
                exit(DBAmount);
        SLAmount := CalcSLAmount();
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
    var
        IsHandled: Boolean;
    begin
        with FADeprBook do begin
            TestField("Depreciation Starting Date");
            if "Depreciation Method" = "Depreciation Method"::"User-Defined" then
#if not CLEAN18
                // NAVCZ
                if "Depreciation Group Code" = '' then begin
                    // NAVCZ
#endif
                    TestField("Depreciation Table Code");
                    TestField("First User-Defined Depr. Date");
#if not CLEAN18
                end;
#endif
            case "Depreciation Method" of
                "Depreciation Method"::"Declining-Balance 1",
              "Depreciation Method"::"Declining-Balance 2",
              "Depreciation Method"::"DB1/SL",
              "Depreciation Method"::"DB2/SL":
                    if "Declining-Balance %" >= 100 then
                        Error(Text001, GetFAName(), FieldCaption("Declining-Balance %"));
            end;
            if (DeprBook."Periodic Depr. Date Calc." = DeprBook."Periodic Depr. Date Calc."::"Last Depr. Entry") and
#if CLEAN18
               ("Depreciation Method" <> "Depreciation Method"::"Straight-Line")
#else
               ("Depreciation Method" <> "Depreciation Method"::"Straight-Line") and
               // NAVCZ
               ("Depreciation Group Code" = '')
            // NAVCZ
#endif
            then begin
                "Depreciation Method" := "Depreciation Method"::"Straight-Line";
                Error(
                  Text002,
                  GetFAName(),
                  FieldCaption("Depreciation Method"),
                  "Depreciation Method",
                  DeprBook.TableCaption,
                  DeprBook.FieldCaption("Periodic Depr. Date Calc."),
                  DeprBook."Periodic Depr. Date Calc.");
            end;

            SetDeprMethod(FADeprBook);

            if DateFromProjection = 0D then begin
                CalcFields("Book Value");
                BookValue := "Book Value";
            end else
                BookValue := EntryAmounts[1];
            MinusBookValue := DepreciationCalc.GetMinusBookValue(FA."No.", DeprBookCode, 0D, 0D);
            CalcFields("Depreciable Basis", "Salvage Value");
            DeprBasis := "Depreciable Basis";
            SalvageValue := "Salvage Value";

            OnAfterBookValueRecalculateBookValue(FA, DeprBook, FALedgEntry, DeprBasis, BookValue, EndingDate, FADeprBook."Disposal Date");

            BookValue2 := BookValue;
            SalvageValue2 := SalvageValue;
            DeprStartingDate := "Depreciation Starting Date";
            DeprTableCode := "Depreciation Table Code";
            FirstUserDefinedDeprDate := "First User-Defined Depr. Date";
            if ("Depreciation Method" = "Depreciation Method"::"User-Defined") and
               (FirstUserDefinedDeprDate > DeprStartingDate)
            then
                Error(
                  Text003,
                  GetFAName(), FieldCaption("First User-Defined Depr. Date"), FieldCaption("Depreciation Starting Date"));

            SLPercent := "Straight-Line %";
            DBPercent := "Declining-Balance %";

            OnAfterBookValueCheckAddedDeprApplicable(FADeprBook, DeprBook, FALedgEntry, UntilDate, DBPercent, SLPercent);

            DeprYears := "No. of Depreciation Years";
            if "Depreciation Ending Date" > 0D then begin
                if "Depreciation Starting Date" > "Depreciation Ending Date" then
                    Error(
                      Text003,
                      GetFAName(), FieldCaption("Depreciation Starting Date"), FieldCaption("Depreciation Ending Date"));
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

            IsHandled := false;
            OnAfterDaysinFYRecalculateDaysInFiscalYear(FADeprBook, DeprBook, UntilDate, DaysInFiscalYear, Year365Days, IsHandled);

            if Year365Days then begin
                if not IsHandled then
                    DaysInFiscalYear := 365;

                DeprYears :=
                  DepreciationCalc.DeprDays(
                    "Depreciation Starting Date", "Depreciation Ending Date", true) / DaysInFiscalYear;
            end;
        end;
#if not CLEAN19
        OnAfterTransferValuesCalculation(FA, FADeprBook, Year365Days, DeprYears, DeprBasis, BookValue, DeprMethod);
        OnAfterTransferValues(FA, FADeprBook, Year365Days, DeprYears, DeprMethod);
#endif

        OnAfterTransferValues2(FA, FADeprBook, Year365Days, DeprYears, DeprMethod, DeprBasis, BookValue);
    end;

    local procedure GetFAName(): Text[200]
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
        if DeprMethod = DeprMethod::"Below Zero" then
            exit(false);
        if AccountingPeriod.IsEmpty() then
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
           [DeprMethod::"Declining-Balance 2",
            DeprMethod::"DB2/SL",
            DeprMethod::"User-Defined"]
        then
            Error(
              Text004,
              FADeprBook.FieldCaption("Depreciation Method"),
              FADeprBook."Depreciation Method",
              GetFAName());
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

        if (DeprMethod = DeprMethod::"Declining-Balance 1") or (DeprMethod = DeprMethod::"DB1/SL") then
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
                DeprMethod::"Straight-Line":
                    DeprAmount := DeprAmount + CalcSLAmount;
                DeprMethod::"Declining-Balance 1":
                    DeprAmount := DeprAmount + CalcDB1Amount;
                DeprMethod::"DB1/SL":
                    DeprAmount := DeprAmount + CalcDBSLAmount;
                DeprMethod::"Country Specific":
                    ; // Reserved for implementation of country specific
            end;
        end;
        NumberOfDays := OriginalNumberOfDays;
        BookValue := OriginalBookValue;
        FirstDeprDate := OriginalFirstDeprDate;
        DeprInTwoFiscalYears := false;
        exit(DeprAmount);
    end;

    local procedure SetDeprMethod(FADeprBook: Record "FA Depreciation Book")
    begin
        DeprMethod := FADeprBook."Depreciation Method";
    end;

#if not CLEAN18
    [Obsolete('Moved to Fixed Asset Localization for Czech.', '18.0')]
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

        if DepGroup."Depreciation Type" <> DepGroup."Depreciation Type"::"Straight-line Intangible" then
            if FADeprBook.Prorated then begin
                if DateFromProjection = 0D then begin
                    TaxDeprAmount := TaxDeprAmount * DepreciationCalc.DeprDays(CalcStartOfFiscalYear(UntilDate), UntilDate, Year365Days) / 360 -
                        CalcDepreciatedAmount(FADeprBook."FA No.", FADeprBook."Depreciation Book Code", 0D, UntilDate);
                    NumberOfDays2 := DepreciationCalc.DeprDays(CalcStartOfFiscalYear(UntilDate), UntilDate, Year365Days) -
                        CalcDepreciatedDays(FADeprBook."FA No.", FADeprBook."Depreciation Book Code", 0D, UntilDate);
                end else begin
                    TaxDeprAmount := TaxDeprAmount * DepreciationCalc.DeprDays(DateFromProjection, UntilDate, Year365Days) / 360;
                    NumberOfDays2 := DepreciationCalc.DeprDays(DateFromProjection, UntilDate, Year365Days);
                end;
            end else
                if TempFaktor < 1 then
                    TaxDeprAmount := TaxDeprAmount * TempFaktor;
        if DeprBook."Use Rounding in Periodic Depr." then
            TaxDeprAmount := Round(Round(TaxDeprAmount), 1, '>');

        exit(-TaxDeprAmount);
    end;

    [Obsolete('Moved to Fixed Asset Localization for Czech.', '18.0')]
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

    [Obsolete('Moved to Fixed Asset Localization for Czech.', '18.0')]
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
                if Year.Insert() then;
            until TempFALeEntry.Next() = 0;
        exit(FiscalYearCount(LastAppr, UntilDate, FALeEntry.GetFilter("FA No.")) - Year.Count); // NAVCZ
    end;

    [Obsolete('Moved to Fixed Asset Localization for Czech.', '18.0')]
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
            until FALedgEntry2.Next() = 0;
        exit(DeprBreakDays);
    end;

    [Obsolete('Moved to Fixed Asset Localization for Czech.', '18.0')]
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

    [Obsolete('Moved to Fixed Asset Localization for Czech.', '18.0')]
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

    [Obsolete('Moved to Fixed Asset Localization for Czech.', '18.0')]
    [Scope('OnPrem')]
    procedure ProjectedValue(ProjValue2: Boolean)
    begin
        ProjValue := ProjValue2;
    end;

    [Obsolete('Moved to Fixed Asset Localization for Czech.', '18.0')]
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
            until FALedgEntry2.Next() = 0;
        exit(NoOfDepreciatedDays);
    end;

    [Obsolete('Moved to Fixed Asset Localization for Czech.', '18.0')]
    [Scope('OnPrem')]
    procedure TransferProjectedValues(var FALedgEntry2: Record "FA Ledger Entry")
    begin
        TempFALedgEntry3.Reset();
        TempFALedgEntry3.DeleteAll();
        if FALedgEntry2.Find('-') then
            repeat
                TempFALedgEntry3.Init();
                TempFALedgEntry3.TransferFields(FALedgEntry2);
                TempFALedgEntry3.Insert();
            until FALedgEntry2.Next() = 0;
    end;

    [Obsolete('Moved to Fixed Asset Localization for Czech.', '18.0')]
    [Scope('OnPrem')]
    procedure CalculateProjectedValues(StartDate: Date; EndDate: Date)
    begin
        NoOfProjectedDays := 0;
        TempFALedgEntry3.Reset();
        if StartDate <> 0D then
            TempFALedgEntry3.SetRange("FA Posting Date", StartDate, EndDate)
        else
            TempFALedgEntry3.SetFilter("FA Posting Date", '..%1', EndDate);
        if TempFALedgEntry3.Find('-') then
            repeat
                NoOfProjectedDays += TempFALedgEntry3."No. of Depreciation Days";
            until TempFALedgEntry3.Next() = 0;
        TempFALedgEntry3.CalcSums(Amount);
    end;

    [Obsolete('Moved to Fixed Asset Localization for Czech.', '18.0')]
    local procedure IsNonZeroDeprecation(FANo: Code[20]; DeprBookCode: Code[10]; TempFromDate: Date): Boolean
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // NAVCZ
        if (DateFromProjection <> 0D) or FADeprBook.Prorated then
            exit(TempFromDate >= CalcEndOfFiscalYear(AcquisitionDate));

        DepreciationCalc.SetFAFilter(FALedgerEntry, FANo, DeprBookCode, true);
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
        FALedgerEntry.SetFilter(Amount, '<>%1', 0);
        exit(not FALedgerEntry.IsEmpty);
    end;

    [Obsolete('Moved to Fixed Asset Localization for Czech.', '18.0')]
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
#endif

    local procedure AssignVariablesToStorage(
        var StorageDecimal: Dictionary of [Text, Decimal];
        var StorageInteger: Dictionary of [Text, Integer];
        var StorageDate: Dictionary of [Text, Date];
        var StorageCode: Dictionary of [Text, Code[10]];
        DeprBookCode2: Code[10];
        DateFromProjection2: Date;
        UntilDate2: Date;
        DaysInPeriod2: Integer;
        NumberOfDays4: Integer;
        DeprAmount: Decimal)
    var
        DeprBookCodeLbl: label 'DeprBookCode';
        DeprTableCodeLbl: Label 'DeprTableCode';
        DateFromProjectionLbl: Label 'DateFromProjection';
        EndDateDateLbl: Label 'EndDate';
        DeprStartingDateLbl: Label 'DeprStartingDate';
        FirstUserDefinedDeprDateLbl: Label 'FirstUserDefinedDeprDate';
        AcquisitionDateLbl: Label 'AcquisitionDate';
        DisposalDateLbl: Label 'DisposalDate';
        DaysInPeriodLbl: Label 'DaysInPeriod';
        NumberOfDays4Lbl: Label 'NumberOfDays4';
        DaysInFiscalYearLbl: Label 'DaysInFiscalYear';
        DeprAmountLbl: Label 'DeprAmount';
        BookValueLbl: Label 'BookValue';
        MinusBookValueLbl: Label 'MinusBookValue';
        DeprBasisLbl: Label 'DeprBasis';
        SalvageValueLbl: Label 'SalvageValue';
        CopyBookValueLbl: Label 'CopyBookValue';
        SLPercentLbl: Label 'SLPercent';
        DBPercentLbl: Label 'DBPercent';
        DeprYearsLbl: Label 'DeprYears';
        FixedAmountLbl: Label 'FixedAmount';
        FinalRoundingAmountLbl: Label 'FinalRoundingAmount';
        EndingBookValueLbl: Label 'EndingBookValue';
        PercentBelowZeroLbl: Label 'PercentBelowZero';
        AmountBelowZeroLbl: Label 'AmountBelowZero';
    begin
        Clear(StorageCode);
        Clear(StorageDate);
        Clear(StorageDecimal);
        Clear(StorageInteger);

        StorageCode.Set(DeprBookCodeLbl, DeprBookCode2);
        StorageCode.Set(DeprTableCodeLbl, DeprTableCode);

        StorageDate.Set(DateFromProjectionLbl, DateFromProjection2);
        StorageDate.Set(EndDateDateLbl, UntilDate2);
        StorageDate.Set(DeprStartingDateLbl, DeprStartingDate);
        StorageDate.Set(FirstUserDefinedDeprDateLbl, FirstUserDefinedDeprDate);
        StorageDate.Set(AcquisitionDateLbl, AcquisitionDate);
        StorageDate.Set(DisposalDateLbl, DisposalDate);

        StorageInteger.Set(DaysInPeriodLbl, DaysInPeriod2);
        StorageInteger.Set(NumberOfDays4Lbl, NumberOfDays4);
        StorageInteger.Set(DaysInFiscalYearLbl, DaysInFiscalYear);

        StorageDecimal.Set(DeprAmountLbl, DeprAmount);
        StorageDecimal.Set(BookValueLbl, BookValue);
        StorageDecimal.Set(MinusBookValueLbl, MinusBookValue);
        StorageDecimal.Set(DeprBasisLbl, DeprBasis);
        StorageDecimal.Set(SalvageValueLbl, SalvageValue);
        StorageDecimal.set(CopyBookValueLbl, BookValue2);
        StorageDecimal.set(SLPercentLbl, SLPercent);
        StorageDecimal.Set(DBPercentLbl, DBPercent);
        StorageDecimal.Set(DeprYearsLbl, DeprYears);
        StorageDecimal.Set(FixedAmountLbl, FixedAmount);
        StorageDecimal.Set(FinalRoundingAmountLbl, FinalRoundingAmount);
        StorageDecimal.Set(EndingBookValueLbl, EndingBookValue);
        StorageDecimal.Set(PercentBelowZeroLbl, PercentBelowZero);
        StorageDecimal.Set(AmountBelowZeroLbl, AmountBelowZero);
    end;

    local procedure AssignStorageToVariables(
        var StorageDecimal: Dictionary of [Text, Decimal];
        var StorageInteger: Dictionary of [Text, Integer];
        var StorageDate: Dictionary of [Text, Date];
        var StorageCode: Dictionary of [Text, Code[10]];
        var DeprBookCode2: Code[10];
        var DateFromProjection2: Date;
        var UntilDate2: Date;
        var DaysInPeriod2: Integer;
        var NumberOfDays4: Integer;
        var DeprAmount: Decimal)
    var
        DeprBookCodeLbl: label 'DeprBookCode';
        DeprTableCodeLbl: Label 'DeprTableCode';
        DateFromProjectionLbl: Label 'DateFromProjection';
        EndDateLbl: Label 'EndDate';
        DeprStartingDateLbl: Label 'DeprStartingDate';
        FirstUserDefinedDeprDateLbl: Label 'FirstUserDefinedDeprDate';
        AcquisitionDateLbl: Label 'AcquisitionDate';
        DisposalDateLbl: Label 'DisposalDate';
        DaysInPeriodLbl: Label 'DaysInPeriod';
        NumberOfDays4Lbl: Label 'NumberOfDays4';
        DaysInFiscalYearLbl: Label 'DaysInFiscalYear';
        DeprAmountLbl: Label 'DeprAmount';
        BookValueLbl: Label 'BookValue';
        MinusBookValueLbl: Label 'MinusBookValue';
        DeprBasisLbl: Label 'DeprBasis';
        SalvageValueLbl: Label 'SalvageValue';
        CopyBookValueLbl: Label 'CopyBookValue';
        SLPercentLbl: Label 'SLPercent';
        DBPercentLbl: Label 'DBPercent';
        DeprYearsLbl: Label 'DeprYears';
        FixedAmountLbl: Label 'FixedAmount';
        FinalRoundingAmountLbl: Label 'FinalRoundingAmount';
        EndingBookValueLbl: Label 'EndingBookValue';
        PercentBelowZeroLbl: Label 'PercentBelowZero';
        AmountBelowZeroLbl: Label 'AmountBelowZero';
    begin
        DeprBookCode2 := StorageCode.Get(DeprBookCodeLbl);
        DeprTableCode := StorageCode.Get(DeprTableCodeLbl);

        DateFromProjection2 := StorageDate.Get(DateFromProjectionLbl);
        UntilDate2 := StorageDate.Get(EndDateLbl);
        DeprStartingDate := StorageDate.Get(DeprStartingDateLbl);
        FirstUserDefinedDeprDate := StorageDate.Get(FirstUserDefinedDeprDateLbl);
        AcquisitionDate := StorageDate.Get(AcquisitionDateLbl);
        DisposalDate := StorageDate.Get(DisposalDateLbl);

        DaysInPeriod2 := StorageInteger.Get(DaysInPeriodLbl);
        NumberOfDays4 := StorageInteger.Get(NumberOfDays4Lbl);
        DaysInFiscalYear := StorageInteger.Get(DaysInFiscalYearLbl);

        DeprAmount := StorageDecimal.Get(DeprAmountLbl);
        BookValue := StorageDecimal.Get(BookValueLbl);
        MinusBookValue := StorageDecimal.Get(MinusBookValueLbl);
        DeprBasis := StorageDecimal.Get(DeprBasisLbl);
        SalvageValue := StorageDecimal.Get(SalvageValueLbl);
        BookValue2 := StorageDecimal.Get(CopyBookValueLbl);
        SLPercent := StorageDecimal.Get(SLPercentLbl);
        DBPercent := StorageDecimal.Get(DBPercentLbl);
        DeprYears := StorageDecimal.Get(DeprYearsLbl);
        FixedAmount := StorageDecimal.Get(FixedAmountLbl);
        FinalRoundingAmount := StorageDecimal.Get(FinalRoundingAmountLbl);
        EndingBookValue := StorageDecimal.Get(EndingBookValueLbl);
        PercentBelowZero := StorageDecimal.Get(PercentBelowZeroLbl);
        AmountBelowZero := StorageDecimal.Get(AmountBelowZeroLbl);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculate(var DeprAmount: Decimal; var NumberOfDays4: Integer; FANo: Code[20]; DeprBookCode2: Code[10]; UntilDate2: Date; EntryAmounts2: array[4] of Decimal; DateFromProjection2: Date; DaysInPeriod2: Integer; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN19
    [Obsolete('Replaced by event OnCalculateOnBeforeTransferValue().', '19.0')]
    [IntegrationEvent(true, true)]
    local procedure OnBeforeCalculateTransferValue(
        FANo: Code[20];
        var StorageDecimal: Dictionary of [Text, Decimal];
        var StorageInteger: Dictionary of [Text, Integer];
        var StorageDate: Dictionary of [Text, Date];
        var StorageCode: Dictionary of [Text, Code[10]];
        var EntryAmounts2: array[4] of Decimal;
        var EntryAmounts: array[4] of Decimal;
        var DeprMethod: Option StraightLine,DB1,DB2,DB1SL,DB2SL,"User-Defined",Manual,BelowZero;
        var Year365Days: Boolean;
        var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(true, false)]
    local procedure OnCalculateOnBeforeTransferValue(
        FANo: Code[20];
        var StorageDecimal: Dictionary of [Text, Decimal];
        var StorageInterger: Dictionary of [Text, Integer];
        var StorageDate: Dictionary of [Text, Date];
        var StorageCode: Dictionary of [Text, Code[10]];
        var EntryAmounts2: array[4] of Decimal;
        var EntryAmounts: array[4] of Decimal;
        var DeprMethod: Enum "FA Depr. Method Internal";
        var Year365Days: Boolean;
        var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSkipRecord(
        FixedAsset: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        DisposalDate: date;
        AcquisitionDate: date;
        UntilDate: Date;
        FADeprMethod: Enum "FA Depreciation Method";
        BookValue: Decimal;
        DeprBasis: Decimal;
        SalvageValue: Decimal;
        MinusBookValue: Decimal;
        var ReturnValue: Boolean;
        var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcTransferValueSetVariables(
        var FirstDate: date;
        var Year365Days: Boolean;
        var UseDeprStartingDate: Boolean;
        var NumberOfDays2: integer;
        var UseHalfYearConvention: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNumberofDayCalculateNumberofDays(
        FixedAsset: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        var NumberofDays: Integer;
        FirstDeprDate: date;
        UntilDate: Date;
        Year365Days: Boolean;
        var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure UpdateDaysInFiscalYear(
        FixedAsset: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        var NumberofDays: Integer;
        var DaysInFiscalYear: Integer;
        var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBookValueRecalculateBookValue(
        FixedAsset: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        FAledgEntry2: Record "FA Ledger Entry";
        var DeprBasis: Decimal;
        var BookValue: Decimal;
        var DeprEndingDate: Date;
        DisposalDate: date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBookValueCheckAddedDeprApplicable(
        FADepBook: Record "FA Depreciation Book";
        DeprBook: Record "Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        UntilDate: Date;
        var DBPercent: Decimal;
        var SlPercent: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDaysinFYRecalculateDaysInFiscalYear(
        FADepBook: Record "FA Depreciation Book";
        DeprBook: Record "Depreciation Book";
        UntilDate: Date;
        var DaysInFiscalYear: Integer;
        Year365Days: Boolean;
        var IsHandled: Boolean)
    begin
    end;

#if not CLEAN19
    [Obsolete('Replaced by OnAfterTransferValues2()', '19.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferValuesCalculation(
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        var Year365Days: Boolean;
        var DeprYears: Decimal;
        var DeprBasis: Decimal;
        var BookValue: Decimal;
        var DeprMethod: Option)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateFinalAmount(DepreBook: Record "Depreciation Book"; var Amount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSkipOnZeroValue(DepreBook: Record "Depreciation Book"; var SkipOnZero: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcFinalDeprAmount(
        FANo: Code[20];
        FADeprBook: Record "FA Depreciation Book";
        DepreBook: Record "Depreciation Book";
        Sign: Integer;
        BookValue: Decimal;
        var DeprAmount: Decimal;
        var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateDeprAmount(FixedAsset: Record "Fixed Asset"; SkipOnZero: Boolean; DeprBookCode: Code[20]; var Amount: Decimal; BookValue: Decimal; SalvageValue: Decimal; EndingBookValue: Decimal; FinalRoundingAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcSL(FixedAsset: Record "Fixed Asset"; FADepreciationBook: Record "FA Depreciation Book"; UntilDate: Date; BookValue: Decimal; DeprBasis: Decimal; DeprYears: Decimal; NumberOfDays: Integer; DaysInFiscalYear: Integer; var ExitValue: Decimal; var IsHandled: Boolean; var RemainingLife: Decimal; var FirstDeprDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcDB1Amount(DBPercent: Decimal; NumberOfDays: Integer; DaysInFiscalYear: Integer; BookValue: Decimal; SalvageValue: Decimal; MinusBookValue: Decimal; Sign: Integer; DeprInFiscalYear: Decimal; var Result: Decimal)
    begin
    end;

#if not CLEAN19
    [Obsolete('Replaced by OnAfterTransferValues2()', '19.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferValues(FixedAsset: Record "Fixed Asset"; FADepreciationBook: Record "FA Depreciation Book"; Year365Days: Boolean; var DeprYears: Decimal; var DeprMethod: Option)
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferValues2(FixedAsset: Record "Fixed Asset"; FADepreciationBook: Record "FA Depreciation Book"; Year365Days: Boolean; var DeprYears: Decimal; var DeprMethod: Enum "FA Depr. Method Internal"; var DeprBasis: Decimal; var BookValue: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcSLAmountOnAfterCalcFromSLPercent(FixedAsset: Record "Fixed Asset"; FADepreciationBook: Record "FA Depreciation Book"; BookValue: Decimal; DeprBasis: Decimal; DaysInFiscalYear: Integer; NumberOfDays: Integer; SLPercent: Decimal; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcSLAmountOnAfterCalcResultForRemainingLifeExpired(FixedAsset: Record "Fixed Asset"; FADepreciationBook: Record "FA Depreciation Book"; BookValue: Decimal; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateDeprAmountOnDeprMethodCaseLastEntry(FADepreciationBook: Record "FA Depreciation Book"; BookValue: Decimal; DeprBasis: Decimal; DeprYears: Decimal; DaysInFiscalYear: Integer; NumberOfDays: Integer; var Amount: Decimal; DateFromProjection: Date; UntilDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateDeprAmountOnDeprMethodCaseLastDeprEntry(FADepreciationBook: Record "FA Depreciation Book"; BookValue: Decimal; DeprBasis: Decimal; DeprYears: Decimal; DaysInFiscalYear: Integer; NumberOfDays: Integer; var Amount: Decimal; DateFromProjection: Date; UntilDate: Date)
    begin
    end;
}

