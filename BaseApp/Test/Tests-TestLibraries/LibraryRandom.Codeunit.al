codeunit 130440 "Library - Random"
{
    // Pseudo random number generator.

    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        Seed: Integer;

    procedure RandDec(Range: Integer; Decimals: Integer): Decimal
    begin
        exit(RandInt(Range * Power(10, Decimals)) / Power(10, Decimals));
    end;

    procedure RandDecInRange("Min": Integer; "Max": Integer; Decimals: Integer): Decimal
    begin
        // Returns a pseudo random decimal in the interval (Min,Max]
        exit(Min + RandDec(Max - Min, Decimals));
    end;

    procedure RandDecInDecimalRange("Min": Decimal; "Max": Decimal; Precision: Integer): Decimal
    var
        Min2: Integer;
        Max2: Integer;
        Pow: Integer;
    begin
        Pow := Power(10, Precision);
        Min2 := Round(Min * Pow, 1, '>');
        Max2 := Round(Max * Pow, 1, '<');
        exit(RandIntInRange(Min2, Max2) / Pow);
    end;

    procedure RandInt(Range: Integer): Integer
    begin
        // Returns a pseudo random integer in the interval [1,Range]
        if Range < 1 then
            exit(1);
        exit(1 + Round(Uniform * (Range - 1), 1));
    end;

    procedure RandIntInRange("Min": Integer; "Max": Integer): Integer
    begin
        exit(Min - 1 + RandInt(Max - Min + 1));
    end;

    procedure RandDate(Delta: Integer): Date
    begin
        if Delta = 0 then
            exit(WorkDate);
        exit(CalcDate(StrSubstNo('<%1D>', Delta / Abs(Delta) * RandInt(Abs(Delta))), WorkDate));
    end;

    procedure RandDateFrom(FromDate: Date; Range: Integer): Date
    begin
        if Range = 0 then
            exit(FromDate);
        exit(CalcDate(StrSubstNo('<%1D>', Range / Abs(Range) * RandInt(Range)), FromDate));
    end;

    procedure RandDateFromInRange(FromDate: Date; FromRange: Integer; ToRange: Integer): Date
    begin
        if FromRange >= ToRange then
            exit(FromDate);
        exit(CalcDate(StrSubstNo('<+%1D>', RandIntInRange(FromRange, ToRange)), FromDate));
    end;

    procedure RandPrecision(): Decimal
    begin
        exit(1 / Power(10, RandInt(5)));
    end;

    procedure RandText(Length: Integer): Text
    var
        GuidTxt: Text;
    begin
        while StrLen(GuidTxt) < Length do
            GuidTxt += LowerCase(DelChr(Format(CreateGuid), '=', '{}-'));
        exit(CopyStr(GuidTxt, 1, Length));
    end;

    procedure Init(): Integer
    begin
        // Updates the seed from the current time
        exit(SetSeed(Time - 000000T));
    end;

    procedure SetSeed(Val: Integer): Integer
    begin
        // Set the random seed to reproduce pseudo random sequence
        Seed := Val;
        Seed := Seed mod 10000;  // Overflow protection
        exit(Seed);
    end;

    local procedure UpdateSeed()
    begin
        // Generates a new seed value and
        Seed := Seed + 3;
        Seed := Seed * 3;
        Seed := Seed * Seed;
        Seed := Seed mod 10000;  // Overflow protection
    end;

    local procedure Uniform(): Decimal
    begin
        // Generates a pseudo random uniform number
        UpdateSeed;

        exit((Seed mod 137) / 137);
    end;

    [EventSubscriber(ObjectType::Codeunit, 130403, 'OnSetSeed', '', false, false)]
    local procedure OnSetSeedHandler(NewSeed: Integer)
    begin
        SetSeed(NewSeed);
    end;
}

