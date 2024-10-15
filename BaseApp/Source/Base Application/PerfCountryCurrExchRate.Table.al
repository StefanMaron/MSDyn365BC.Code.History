table 11764 "Perf. Country Curr. Exch. Rate"
{
    Caption = 'Perf. Country Curr. Exch. Rate';
    DataCaptionFields = "Currency Code";
    ObsoleteState = Removed;
    ObsoleteReason = 'The functionality of VAT Registration in Other Countries has been removed and this table should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '18.0';

    fields
    {
        field(10; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(20; "Perform. Country/Region Code"; Code[10])
        {
            Caption = 'Perform. Country/Region Code';
            NotBlank = true;
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
}
