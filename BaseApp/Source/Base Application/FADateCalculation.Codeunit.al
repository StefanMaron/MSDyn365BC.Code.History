codeunit 5617 "FA Date Calculation"
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'is later than %1';
        Text001: Label 'It was not possible to find a %1 in %2.';
        DeprBook: Record "Depreciation Book";

    procedure GetFiscalYear(DeprBookCode: Code[10]; EndingDate: Date): Date
    var
        AccountingPeriod: Record "Accounting Period";
        FAJnlLine: Record "FA Journal Line";
    begin
        with DeprBook do begin
            Get(DeprBookCode);
            if "New Fiscal Year Starting Date" > 0D then begin
                if "New Fiscal Year Starting Date" > EndingDate then
                    FieldError(
                      "New Fiscal Year Starting Date",
                      StrSubstNo(Text000, FAJnlLine.FieldCaption("FA Posting Date")));
                exit("New Fiscal Year Starting Date");
            end;
        end;
        with AccountingPeriod do begin
            if IsEmpty then
                exit(CalcDate('<-CY>', EndingDate));
            SetRange("New Fiscal Year", true);
            SetRange("Starting Date", 0D, EndingDate);
            if FindLast then
                exit("Starting Date");

            Error(Text001, FieldCaption("Starting Date"), TableCaption);
        end;
    end;

    procedure CalculateDate(StartingDate: Date; NumberOfDays: Integer; Year365Days: Boolean): Date
    var
        Years: Integer;
        Days: Integer;
        Months: Integer;
        LocalDate: Date;
    begin
        if NumberOfDays <= 0 then
            exit(StartingDate);
        if Year365Days then
            exit(CalculateDate365(StartingDate, NumberOfDays));
        Years := Date2DMY(StartingDate, 3);
        Months := Date2DMY(StartingDate, 2);
        Days := Date2DMY(StartingDate, 1);
        if Date2DMY(StartingDate + 1, 1) = 1 then
            Days := 30;
        Days := Days + NumberOfDays;
        Months := Months + (Days div 30);
        Days := Days mod 30;
        if Days = 0 then begin
            Days := 30;
            Months := Months - 1;
        end;
        Years := Years + (Months div 12);
        Months := Months mod 12;
        if Months = 0 then begin
            Months := 12;
            Years := Years - 1;
        end;
        if (Months = 2) and (Days > 28) then begin
            Days := 28;
            LocalDate := DMY2Date(28, 2, Years) + 1;
            if Date2DMY(LocalDate, 1) = 29 then
                Days := 29;
        end;
        case Months of
            1, 3, 5, 7, 8, 10, 12:
                if Days = 30 then
                    Days := 31;
        end;
        exit(DMY2Date(Days, Months, Years));
    end;

    local procedure CalculateDate365(StartingDate: Date; NumberOfDays: Integer): Date
    var
        Calendar: Record Date;
        NoOfDays: Integer;
        EndingDate: Date;
        FirstDate: Boolean;
    begin
        with Calendar do begin
            SetRange("Period Type", "Period Type"::Date);
            SetRange("Period Start", StartingDate, DMY2Date(31, 12, 9999));
            NoOfDays := 1;
            FirstDate := true;
            if Find('-') then
                repeat
                    if (not ((Date2DMY("Period Start", 1) = 29) and (Date2DMY("Period Start", 2) = 2))) or
                       FirstDate
                    then
                        NoOfDays := NoOfDays + 1;
                    FirstDate := false;
                until (Next = 0) or (NumberOfDays < NoOfDays);
            EndingDate := "Period Start";
            if (Date2DMY(EndingDate, 1) = 29) and (Date2DMY(EndingDate, 2) = 2) then
                EndingDate := EndingDate + 1;
            exit(EndingDate);
        end;
    end;
}

