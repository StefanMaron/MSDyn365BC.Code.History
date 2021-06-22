codeunit 356 DateComprMgt
{

    trigger OnRun()
    begin
    end;

    var
        AccountingPeriod: Record "Accounting Period";
        FiscYearDate: array[2] of Date;
        AccountingPeriodDate: array[2] of Date;
        Date1: Date;
        Date2: Date;

    procedure GetDateFilter(Date: Date; DateComprReg: Record "Date Compr. Register"; CheckFiscYearEnd: Boolean): Text[250]
    begin
        if (Date = 0D) or (Date = ClosingDate(Date)) then
            exit(Format(Date));

        if (Date < FiscYearDate[1]) or (Date > FiscYearDate[2]) then begin
            AccountingPeriod.SetRange("New Fiscal Year", true);
            AccountingPeriod."Starting Date" := Date;
            AccountingPeriod.Find('=<');
            FiscYearDate[1] := AccountingPeriod."Starting Date";
            AccountingPeriod."Starting Date" := Date;
            AccountingPeriod.Find('>');
            FiscYearDate[2] := AccountingPeriod."Starting Date" - 1;
            AccountingPeriod.SetRange("New Fiscal Year");
            if CheckFiscYearEnd then
                AccountingPeriod.TestField("Date Locked", true);
        end;

        if DateComprReg."Period Length" = DateComprReg."Period Length"::Day then
            exit(Format(Date));

        Date1 := DateComprReg."Starting Date";
        Date2 := DateComprReg."Ending Date";
        Maximize(Date1, FiscYearDate[1]);
        Minimize(Date2, FiscYearDate[2]);

        Maximize(Date1, CalcDate('<CY+1D-1Y>', Date));
        Minimize(Date2, CalcDate('<CY>', Date));
        if DateComprReg."Period Length" = DateComprReg."Period Length"::Year then
            exit(StrSubstNo('%1..%2', Date1, Date2));

        if (Date < AccountingPeriodDate[1]) or (Date > AccountingPeriodDate[2]) then begin
            AccountingPeriod."Starting Date" := Date;
            AccountingPeriod.Find('=<');
            AccountingPeriodDate[1] := AccountingPeriod."Starting Date";
            AccountingPeriod.Next;
            AccountingPeriodDate[2] := AccountingPeriod."Starting Date" - 1;
        end;

        if DateComprReg."Period Length" = DateComprReg."Period Length"::Period then begin
            Maximize(Date1, AccountingPeriodDate[1]);
            Minimize(Date2, AccountingPeriodDate[2]);
            exit(StrSubstNo('%1..%2', Date1, Date2));
        end;

        Maximize(Date1, CalcDate('<CQ+1D-1Q>', Date));
        Minimize(Date2, CalcDate('<CQ>', Date));
        if DateComprReg."Period Length" = DateComprReg."Period Length"::Quarter then
            exit(StrSubstNo('%1..%2', Date1, Date2));

        Maximize(Date1, CalcDate('<CM+1D-1M>', Date));
        Minimize(Date2, CalcDate('<CM>', Date));
        if DateComprReg."Period Length" = DateComprReg."Period Length"::Month then
            exit(StrSubstNo('%1..%2', Date1, Date2));

        Maximize(Date1, CalcDate('<CW+1D-1W>', Date));
        Minimize(Date2, CalcDate('<CW>', Date));
        exit(StrSubstNo('%1..%2', Date1, Date2));
    end;

    local procedure Maximize(var Date: Date; NewDate: Date)
    begin
        if Date < NewDate then
            Date := NewDate;
    end;

    local procedure Minimize(var Date: Date; NewDate: Date)
    begin
        if Date > NewDate then
            Date := NewDate;
    end;
}

