table 11779 "VAT Attribute Code"
{
    Caption = 'VAT Attribute Code';
    DrillDownPageID = "VAT Attribute Codes";
    LookupPageID = "VAT Attribute Codes";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; "XML Code"; Code[20])
        {
            Caption = 'XML Code';
        }
        field(4; "VAT Statement Template Name"; Code[10])
        {
            Caption = 'VAT Statement Template Name';
        }
        field(5; Coefficient; Boolean)
        {
            Caption = 'Coefficient';
        }
    }

    keys
    {
        key(Key1; "VAT Statement Template Name", "Code")
        {
            Clustered = true;
        }
        key(Key2; "XML Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }

    var
        ValueCoefErr: Label 'The value of a coefficient %1 must be between 0 and 1.';

    [Scope('OnPrem')]
    procedure GetRoundingPrecision(): Decimal
    begin
        if Coefficient then
            exit(0.01);
        exit(1);
    end;

    [Scope('OnPrem')]
    procedure CheckValue(Value: Decimal)
    begin
        if Coefficient then
            if not (Value in [0 .. 1]) then
                Error(ValueCoefErr, Code);
    end;
}

