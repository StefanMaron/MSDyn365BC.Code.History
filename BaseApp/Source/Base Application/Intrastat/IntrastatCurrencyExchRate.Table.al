table 31061 "Intrastat Currency Exch. Rate"
{
    Caption = 'Intrastat Currency Exch. Rate';
    ObsoleteState = Removed;
    ObsoleteReason = 'Unsupported functionality';
    ObsoleteTag = '21.0';

    fields
    {
        field(1; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(2; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            NotBlank = true;
        }
        field(5; "Exchange Rate Amount"; Decimal)
        {
            Caption = 'Exchange Rate Amount';
            DecimalPlaces = 1 : 6;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Currency Code", "Starting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure ExchangeRate(Date: Date; CurrencyCode: Code[10]): Decimal
    begin
        Reset();
        SetRange("Currency Code", CurrencyCode);
        SetRange("Starting Date", 0D, Date);
        if FindLast() then
            exit("Exchange Rate Amount");
        exit(1);
    end;

    [Scope('OnPrem')]
    procedure xExchangeRateMandatory(PeriodStartDate: Date; Date1: Date; Currencycode: Code[10]): Decimal
    begin
        if Currencycode = '' then
            exit(1);
        Reset();
        SetRange("Currency Code", Currencycode);
        SetRange("Starting Date", PeriodStartDate, Date1);
        FindLast();
        exit("Exchange Rate Amount");
    end;
}
