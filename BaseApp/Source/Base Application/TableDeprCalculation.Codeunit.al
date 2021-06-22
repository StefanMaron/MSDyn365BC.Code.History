codeunit 5618 "Table Depr. Calculation"
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'There are no lines defined for %1 %2 = %3.';
        Text001: Label '%1 = %2 and %3 %4 = %5 must not be different.';
        Text002: Label 'must be an unbroken sequence';
        Text003: Label 'Period must be specified in %1.';
        Text004: Label 'The number of days in an accounting period must not be less than 5.';
        AccountingPeriod: Record "Accounting Period";
        DeprBook: Record "Depreciation Book";
        DeprTableHeader: Record "Depreciation Table Header";
        DeprTableBufferTmp: Record "Depreciation Table Buffer" temporary;
        DeprTableLine: Record "Depreciation Table Line";
        DepreciationCalc: Codeunit "Depreciation Calculation";
        DaysInFiscalYear: Integer;
        StartingLimit: Integer;
        EndingLimit: Integer;
        FirstPointer: Integer;
        LastPointer: Integer;
        NumberOfDays: Integer;
        Percentage: Decimal;
        Year365Days: Boolean;
        Text005: Label 'cannot be %1 when %2 is %3 in %4 %5';

    procedure GetTablePercent(DeprBookCode: Code[10]; DeprTableCode: Code[10]; FirstUserDefinedDeprDate: Date; StartingDate: Date; EndingDate: Date): Decimal
    begin
        ClearAll;
        if (StartingDate = 0D) or (EndingDate = 0D) then
            exit(0);
        if (StartingDate > EndingDate) or (FirstUserDefinedDeprDate > StartingDate) then
            exit(0);
        DeprBook.Get(DeprBookCode);
        DaysInFiscalYear := DeprBook."No. of Days in Fiscal Year";
        if DaysInFiscalYear = 0 then
            DaysInFiscalYear := 360;
        DeprTableHeader.Get(DeprTableCode);
        Year365Days := DeprBook."Fiscal Year 365 Days";
        if Year365Days then begin
            if (DeprTableHeader."Period Length" = DeprTableHeader."Period Length"::Month) or
               (DeprTableHeader."Period Length" = DeprTableHeader."Period Length"::Quarter)
            then
                DeprTableHeader.FieldError(
                  "Period Length",
                  StrSubstNo(
                    Text005,
                    DeprTableHeader."Period Length",
                    DeprBook.FieldCaption("Fiscal Year 365 Days"),
                    DeprBook."Fiscal Year 365 Days",
                    DeprBook.TableCaption, DeprBook.Code));
            DaysInFiscalYear := 365;
        end;
        StartingLimit := DepreciationCalc.DeprDays(FirstUserDefinedDeprDate, StartingDate, Year365Days);
        EndingLimit := DepreciationCalc.DeprDays(FirstUserDefinedDeprDate, EndingDate, Year365Days);
        if not Year365Days then begin
            if Date2DMY(StartingDate, 2) = 2 then
                if Date2DMY(StartingDate + 1, 1) = 1 then
                    StartingLimit := StartingLimit - (30 - Date2DMY(StartingDate, 1));
        end;
        CreateTableBuffer(FirstUserDefinedDeprDate);
        exit(CalculatePercent);
    end;

    local procedure CalculatePercent(): Decimal
    begin
        DeprTableBufferTmp.Find('-');
        LastPointer := 0;
        Percentage := 0;

        repeat
            FirstPointer := LastPointer + 1;
            LastPointer := FirstPointer + DeprTableBufferTmp."No. of Days in Period" - 1;
            NumberOfDays := 0;
            if not ((StartingLimit > LastPointer) or (EndingLimit < FirstPointer)) then begin
                if (StartingLimit < FirstPointer) and (EndingLimit <= LastPointer) then
                    NumberOfDays := EndingLimit - FirstPointer + 1;
                if (StartingLimit < FirstPointer) and (EndingLimit > LastPointer) then
                    NumberOfDays := DeprTableBufferTmp."No. of Days in Period";
                if (StartingLimit >= FirstPointer) and (EndingLimit <= LastPointer) then
                    NumberOfDays := EndingLimit - StartingLimit + 1;
                if (StartingLimit >= FirstPointer) and (EndingLimit > LastPointer) then
                    NumberOfDays := LastPointer - StartingLimit + 1;
                Percentage :=
                  Percentage + DeprTableBufferTmp."Period Depreciation %" * NumberOfDays /
                  DeprTableBufferTmp."No. of Days in Period";
            end;
        until DeprTableBufferTmp.Next = 0;
        exit(Percentage / 100);
    end;

    local procedure CreateTableBuffer(FirstUserDefinedDeprDate: Date)
    var
        FADeprBook: Record "FA Depreciation Book";
        DepreciationCalc: Codeunit "Depreciation Calculation";
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        DaysInPeriod: Integer;
        TotalNoOfDays: Integer;
        PeriodNo: Integer;
    begin
        DeprTableLine.SetRange("Depreciation Table Code", DeprTableHeader.Code);
        if not DeprTableLine.Find('-') then
            Error(
              Text000,
              DeprTableHeader.TableCaption, DeprTableHeader.FieldCaption(Code), DeprTableHeader.Code);

        if DeprTableHeader."Period Length" = DeprTableHeader."Period Length"::Period then
            if AccountingPeriod.IsEmpty then
                AccountingPeriodMgt.InitDefaultAccountingPeriod(AccountingPeriod, FirstUserDefinedDeprDate)
            else begin
                AccountingPeriod.SetFilter("Starting Date", '>=%1', FirstUserDefinedDeprDate);
                if AccountingPeriod.Find('-') then;
                if AccountingPeriod."Starting Date" <> FirstUserDefinedDeprDate then
                    Error(
                      Text001,
                      FADeprBook.FieldCaption("First User-Defined Depr. Date"), FirstUserDefinedDeprDate,
                      AccountingPeriod.TableCaption, AccountingPeriod.FieldCaption("Starting Date"),
                      AccountingPeriod."Starting Date");
            end;
        case DeprTableHeader."Period Length" of
            DeprTableHeader."Period Length"::Period:
                DaysInPeriod := 0;
            DeprTableHeader."Period Length"::Month:
                DaysInPeriod := 30;
            DeprTableHeader."Period Length"::Quarter:
                DaysInPeriod := 90;
            DeprTableHeader."Period Length"::Year:
                DaysInPeriod := DaysInFiscalYear;
        end;
        repeat
            PeriodNo := PeriodNo + 1;
            if PeriodNo <> DeprTableLine."Period No." then
                DeprTableLine.FieldError("Period No.", Text002);
            if DeprTableHeader."Period Length" = DeprTableHeader."Period Length"::Period then begin
                FirstUserDefinedDeprDate := AccountingPeriod."Starting Date";
                if AccountingPeriod.Next <> 0 then
                    DaysInPeriod :=
                      DepreciationCalc.DeprDays(
                        FirstUserDefinedDeprDate,
                        DepreciationCalc.Yesterday(AccountingPeriod."Starting Date", Year365Days),
                        Year365Days);
                if DaysInPeriod = 0 then
                    Error(Text003, AccountingPeriod.TableCaption);
                if DaysInPeriod <= 5 then
                    Error(
                      Text004);
            end;
            InsertTableBuffer(DeprTableLine, TotalNoOfDays, DaysInPeriod, PeriodNo);
        until (DeprTableLine.Next = 0) or (TotalNoOfDays > EndingLimit);

        while TotalNoOfDays < EndingLimit do begin
            DeprTableBufferTmp."Entry No." := DeprTableBufferTmp."Entry No." + 1;
            DeprTableBufferTmp.Insert();
            TotalNoOfDays := TotalNoOfDays + DaysInPeriod;
        end;
    end;

    local procedure InsertTableBuffer(var DeprTableLine: Record "Depreciation Table Line"; var TotalNoOfDays: Integer; DaysInPeriod: Integer; PeriodNo: Integer)
    begin
        TotalNoOfDays := TotalNoOfDays + DaysInPeriod;
        DeprTableBufferTmp."Entry No." := PeriodNo;
        DeprTableBufferTmp."No. of Days in Period" := DaysInPeriod;
        if DeprTableHeader."Total No. of Units" > 0 then
            DeprTableBufferTmp."Period Depreciation %" :=
              DeprTableLine."No. of Units in Period" * 100 / DeprTableHeader."Total No. of Units"
        else
            DeprTableBufferTmp."Period Depreciation %" := DeprTableLine."Period Depreciation %";
        DeprTableBufferTmp.Insert();
    end;
}

