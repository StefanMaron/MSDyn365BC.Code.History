table 11764 "Perf. Country Curr. Exch. Rate"
{
    Caption = 'Perf. Country Curr. Exch. Rate';
    DataCaptionFields = "Currency Code";
    DrillDownPageID = "Perf. Country Curr. Exch. Rate";
    LookupPageID = "Perf. Country Curr. Exch. Rate";

    fields
    {
        field(10; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if "Currency Code" = "Relational Currency Code" then
                    Error(
                      CurrCodeBeSameErr, FieldCaption("Currency Code"), FieldCaption("Relational Currency Code"));
            end;
        }
        field(20; "Perform. Country/Region Code"; Code[10])
        {
            Caption = 'Perform. Country/Region Code';
            NotBlank = true;
            TableRelation = "Registration Country/Region"."Country/Region Code" WHERE("Account Type" = CONST("Company Information"),
                                                                                       "Account No." = FILTER(''));

            trigger OnValidate()
            var
                RegistrationCountry: Record "Registration Country/Region";
            begin
                RegistrationCountry.Get(RegistrationCountry."Account Type"::"Company Information", '', "Perform. Country/Region Code");
                RegistrationCountry.TestField("Currency Code (Local)", "Relational Currency Code");
            end;
        }
        field(30; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            NotBlank = true;
        }
        field(40; "Exchange Rate Amount"; Decimal)
        {
            Caption = 'Exchange Rate Amount';
            DecimalPlaces = 1 : 6;
            MinValue = 0;
        }
        field(50; "Relational Currency Code"; Code[10])
        {
            Caption = 'Relational Currency Code';
            Editable = false;
            TableRelation = Currency;

            trigger OnValidate()
            var
                RegistrationCountry: Record "Registration Country/Region";
            begin
                if "Currency Code" = "Relational Currency Code" then
                    Error(
                      CurrCodeBeSameErr, FieldCaption("Currency Code"), FieldCaption("Relational Currency Code"));
                if "Perform. Country/Region Code" <> '' then begin
                    RegistrationCountry.Get(RegistrationCountry."Account Type"::"Company Information", '', "Perform. Country/Region Code");
                    RegistrationCountry.TestField("Currency Code (Local)", "Relational Currency Code");
                end;
            end;
        }
        field(60; "Relational Exch. Rate Amount"; Decimal)
        {
            Caption = 'Relational Exch. Rate Amount';
            DecimalPlaces = 1 : 6;
            MinValue = 0;
        }
        field(70; "Fix Exchange Rate Amount"; Option)
        {
            Caption = 'Fix Exchange Rate Amount';
            OptionCaption = 'Currency,Relational Currency,Both';
            OptionMembers = Currency,"Relational Currency",Both;
        }
        field(80; "Intrastat Exch. Rate Amount"; Decimal)
        {
            Caption = 'Intrastat Exch. Rate Amount';
            DecimalPlaces = 1 : 6;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Currency Code", "Perform. Country/Region Code", "Starting Date")
        {
            Clustered = true;
        }
        key(Key2; "Relational Currency Code")
        {
        }
    }

    fieldgroups
    {
    }

    var
        PerfCountryCurrExchRate: array[2] of Record "Perf. Country Curr. Exch. Rate";
        CurrCodeBeSameErr: Label 'The currency code in the %1 field and the %2 field cannot be the same.';
        RegistrationCountryRegion: Record "Registration Country/Region";
        StatReportingSetup: Record "Stat. Reporting Setup";
        StartDate2: array[2] of Date;
        EndDate2: array[2] of Date;
        StatReportingSetupRead: Boolean;

    procedure ExchangeRate(Date: Date; PerformCountryCode: Code[10]; CurrencyCode: Code[10]): Decimal
    begin
        if not GetRegCountryRegion(PerformCountryCode) then
            exit(0);
        if RegistrationCountryRegion."Currency Code (Local)" = CurrencyCode then
            exit(1);
        FindCurrency(Date, PerformCountryCode, CurrencyCode, RegistrationCountryRegion."Currency Code (Local)", 1);
        TestField("Exchange Rate Amount");
        TestField("Relational Exch. Rate Amount");
        exit("Exchange Rate Amount" / "Relational Exch. Rate Amount");
    end;

    procedure ExchangeRateIntrastat(StartDate: Date; EndDate: Date; PerformCountryCode: Code[10]; CurrencyCode: Code[10]): Decimal
    var
        Mandatory: Boolean;
    begin
        if not GetRegCountryRegion(PerformCountryCode) then
            exit(0);
        if RegistrationCountryRegion."Currency Code (Local)" = CurrencyCode then
            exit(1);

        Mandatory := IsIntrastatExchRateMandatory(PerformCountryCode);
        if not Mandatory then
            StartDate := 0D;

        FindCurrencyInPeriod(
          StartDate, EndDate, PerformCountryCode, CurrencyCode, RegistrationCountryRegion."Currency Code (Local)", Mandatory, 1);

        if Mandatory then begin
            TestField("Intrastat Exch. Rate Amount");
            TestField("Relational Exch. Rate Amount");
        end else begin
            if "Intrastat Exch. Rate Amount" = 0 then
                "Intrastat Exch. Rate Amount" := 1;
            if "Relational Exch. Rate Amount" = 0 then
                "Relational Exch. Rate Amount" := 1;
        end;

        exit("Intrastat Exch. Rate Amount" / "Relational Exch. Rate Amount");
    end;

    [Scope('OnPrem')]
    procedure FindCurrency(Date: Date; PerformCountryCode: Code[10]; CurrencyCode: Code[10]; RelCurrencyCode: Code[10]; CacheNo: Integer)
    begin
        FindCurrencyInPeriod(0D, Date, PerformCountryCode, CurrencyCode, RelCurrencyCode, true, CacheNo);
    end;

    [Scope('OnPrem')]
    procedure FindCurrencyInPeriod(StartDate: Date; EndDate: Date; PerformCountryCode: Code[10]; CurrencyCode: Code[10]; RelCurrencyCode: Code[10]; Mandatory: Boolean; CacheNo: Integer)
    begin
        if (PerfCountryCurrExchRate[CacheNo]."Currency Code" = CurrencyCode) and
           (PerfCountryCurrExchRate[CacheNo]."Perform. Country/Region Code" = PerformCountryCode) and
           (StartDate2[CacheNo] = StartDate) and
           (EndDate2[CacheNo] = EndDate)
        then
            Rec := PerfCountryCurrExchRate[CacheNo]
        else begin
            if EndDate = 0D then
                EndDate := WorkDate;
            PerfCountryCurrExchRate[CacheNo].SetRange("Relational Currency Code", RelCurrencyCode);
            PerfCountryCurrExchRate[CacheNo].SetRange("Currency Code", CurrencyCode);
            PerfCountryCurrExchRate[CacheNo].SetRange("Perform. Country/Region Code", PerformCountryCode);
            PerfCountryCurrExchRate[CacheNo].SetRange("Starting Date", StartDate, EndDate);
            if Mandatory then
                PerfCountryCurrExchRate[CacheNo].FindLast
            else
                if not PerfCountryCurrExchRate[CacheNo].FindLast then
                    exit;
            Rec := PerfCountryCurrExchRate[CacheNo];
            StartDate2[CacheNo] := StartDate;
            EndDate2[CacheNo] := EndDate;
        end;
    end;

    procedure ExchangeAmount(Date: Date; PerformCountryCode: Code[10]; CurrencyCode: Code[10]; Amount: Decimal): Decimal
    begin
        GetRegCountryRegion(PerformCountryCode);
        if RegistrationCountryRegion."Currency Code (Local)" = CurrencyCode then
            exit(Amount);

        FindCurrency(Date, PerformCountryCode, CurrencyCode, RegistrationCountryRegion."Currency Code (Local)", 1);
        TestField("Exchange Rate Amount");
        TestField("Relational Exch. Rate Amount");
        exit(Amount * "Relational Exch. Rate Amount" / "Exchange Rate Amount");
    end;

    local procedure GetRegCountryRegion(PerformCountryCode: Code[10]): Boolean
    begin
        if RegistrationCountryRegion."Country/Region Code" = PerformCountryCode then
            exit(true);

        exit(RegistrationCountryRegion.Get(RegistrationCountryRegion."Account Type"::"Company Information", '', PerformCountryCode));
    end;

    local procedure GetStatReportingSetup()
    begin
        if not StatReportingSetupRead then
            StatReportingSetup.Get;
        StatReportingSetupRead := true;
    end;

    local procedure IsIntrastatExchRateMandatory(PerformCountryCode: Code[10]): Boolean
    var
        Result: Boolean;
    begin
        GetStatReportingSetup;
        Result := StatReportingSetup."Intrastat Exch.Rate Mandatory";
        if PerformCountryCode <> '' then
            if GetRegCountryRegion(PerformCountryCode) then
                Result := RegistrationCountryRegion."Intrastat Exch.Rate Mandatory";
        exit(Result);
    end;
}

