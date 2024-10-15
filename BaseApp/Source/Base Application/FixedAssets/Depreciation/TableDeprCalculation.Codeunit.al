namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.Foundation.Period;

codeunit 5618 "Table Depr. Calculation"
{

    trigger OnRun()
    begin
    end;

    var
        AccountingPeriod: Record "Accounting Period";
        DeprBook: Record "Depreciation Book";
        DeprTableHeader: Record "Depreciation Table Header";
        TempDeprTableBuffer: Record "Depreciation Table Buffer" temporary;
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

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'There are no lines defined for %1 %2 = %3.';
        Text001: Label '%1 = %2 and %3 %4 = %5 must not be different.';
#pragma warning restore AA0470
        Text002: Label 'must be an unbroken sequence';
#pragma warning disable AA0470
        Text003: Label 'Period must be specified in %1.';
#pragma warning restore AA0470
        Text004: Label 'The number of days in an accounting period must not be less than 5.';
#pragma warning disable AA0470
        Text005: Label 'cannot be %1 when %2 is %3 in %4 %5';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure GetTablePercent(DeprBookCode: Code[10]; DeprTableCode: Code[10]; FirstUserDefinedDeprDate: Date; StartingDate: Date; EndingDate: Date): Decimal
    var
        IsHandled: Boolean;
    begin
        ClearAll();
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
        IsHandled := false;
        OnBeforeValidateYear365Days(DeprBook, IsHandled);
        if not IsHandled then
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
                        DeprBook.TableCaption(), DeprBook.Code));
                DaysInFiscalYear := 365;
            end;
        StartingLimit := DepreciationCalc.DeprDays(FirstUserDefinedDeprDate, StartingDate, Year365Days);
        EndingLimit := DepreciationCalc.DeprDays(FirstUserDefinedDeprDate, EndingDate, Year365Days);
        OnGetTablePercentOnAfterSetLimits(DeprBookCode, DeprTableCode, FirstUserDefinedDeprDate, StartingDate, EndingDate, StartingLimit, EndingLimit);

        if not Year365Days then
            if Date2DMY(StartingDate, 2) = 2 then
                if Date2DMY(StartingDate + 1, 1) = 1 then
                    StartingLimit := StartingLimit - (30 - Date2DMY(StartingDate, 1));
        CreateTableBuffer(FirstUserDefinedDeprDate);
        exit(CalculatePercent());
    end;

    local procedure CalculatePercent(): Decimal
    begin
        TempDeprTableBuffer.Find('-');
        LastPointer := 0;
        Percentage := 0;

        repeat
            FirstPointer := LastPointer + 1;
            LastPointer := FirstPointer + TempDeprTableBuffer."No. of Days in Period" - 1;
            NumberOfDays := 0;
            if not ((StartingLimit > LastPointer) or (EndingLimit < FirstPointer)) then begin
                if (StartingLimit < FirstPointer) and (EndingLimit <= LastPointer) then
                    NumberOfDays := EndingLimit - FirstPointer + 1;
                if (StartingLimit < FirstPointer) and (EndingLimit > LastPointer) then
                    NumberOfDays := TempDeprTableBuffer."No. of Days in Period";
                if (StartingLimit >= FirstPointer) and (EndingLimit <= LastPointer) then
                    NumberOfDays := EndingLimit - StartingLimit + 1;
                if (StartingLimit >= FirstPointer) and (EndingLimit > LastPointer) then
                    NumberOfDays := LastPointer - StartingLimit + 1;
                Percentage :=
                  Percentage + TempDeprTableBuffer."Period Depreciation %" * NumberOfDays /
                  TempDeprTableBuffer."No. of Days in Period";
            end;
        until TempDeprTableBuffer.Next() = 0;
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
              DeprTableHeader.TableCaption(), DeprTableHeader.FieldCaption(Code), DeprTableHeader.Code);

        if DeprTableHeader."Period Length" = DeprTableHeader."Period Length"::Period then
            if AccountingPeriod.IsEmpty() then
                AccountingPeriodMgt.InitDefaultAccountingPeriod(AccountingPeriod, FirstUserDefinedDeprDate)
            else begin
                AccountingPeriod.SetFilter("Starting Date", '>=%1', FirstUserDefinedDeprDate);
                if AccountingPeriod.Find('-') then;
                if AccountingPeriod."Starting Date" <> FirstUserDefinedDeprDate then
                    Error(
                      Text001,
                      FADeprBook.FieldCaption("First User-Defined Depr. Date"), FirstUserDefinedDeprDate,
                      AccountingPeriod.TableCaption(), AccountingPeriod.FieldCaption("Starting Date"),
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
                if AccountingPeriod.Next() <> 0 then begin
                    DaysInPeriod :=
                      DepreciationCalc.DeprDays(
                        FirstUserDefinedDeprDate,
                        DepreciationCalc.Yesterday(AccountingPeriod."Starting Date", Year365Days),
                        Year365Days);
                    OnCreateTableBufferOnAfterCalculateDaysInPeriod(DeprBook, AccountingPeriod, FirstUserDefinedDeprDate, Year365Days, DaysInPeriod);
                end;
                if DaysInPeriod = 0 then
                    Error(Text003, AccountingPeriod.TableCaption());
                if DaysInPeriod <= 5 then
                    Error(
                      Text004);
            end;
            InsertTableBuffer(DeprTableLine, TotalNoOfDays, DaysInPeriod, PeriodNo);
        until (DeprTableLine.Next() = 0) or (TotalNoOfDays > EndingLimit);

        while TotalNoOfDays < EndingLimit do begin
            TempDeprTableBuffer."Entry No." := TempDeprTableBuffer."Entry No." + 1;
            TempDeprTableBuffer.Insert();
            TotalNoOfDays := TotalNoOfDays + DaysInPeriod;
        end;
    end;

    local procedure InsertTableBuffer(var DeprTableLine: Record "Depreciation Table Line"; var TotalNoOfDays: Integer; DaysInPeriod: Integer; PeriodNo: Integer)
    begin
        TotalNoOfDays := TotalNoOfDays + DaysInPeriod;
        TempDeprTableBuffer."Entry No." := PeriodNo;
        TempDeprTableBuffer."No. of Days in Period" := DaysInPeriod;
        if DeprTableHeader."Total No. of Units" > 0 then
            TempDeprTableBuffer."Period Depreciation %" :=
              DeprTableLine."No. of Units in Period" * 100 / DeprTableHeader."Total No. of Units"
        else
            TempDeprTableBuffer."Period Depreciation %" := DeprTableLine."Period Depreciation %";
        TempDeprTableBuffer.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateYear365Days(DepreBook: Record "Depreciation Book"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTableBufferOnAfterCalculateDaysInPeriod(DeprBook: Record "Depreciation Book"; AccountingPeriod: Record "Accounting Period"; FirstUserDefinedDeprDate: Date; Year365Days: Boolean; var DaysInPeriod: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTablePercentOnAfterSetLimits(DeprBookCode: Code[10]; DeprTableCode: Code[10]; FirstUserDefinedDeprDate: Date; StartingDate: Date; EndingDate: Date; var StartingLimit: Integer; var EndingLimit: Integer)
    begin
    end;
}

