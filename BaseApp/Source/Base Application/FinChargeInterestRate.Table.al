table 3010590 "Fin. Charge Interest Rate"
{
    Caption = 'Fin. Charge Interest Rate';
    DataCaptionFields = "Fin. Charge Terms Code", "Start Date";
    ObsoleteReason = 'Merged to W1 table 572';
    ObsoleteState = Removed;
    ObsoleteTag = '15.0';

    fields
    {
        field(1; "Fin. Charge Terms Code"; Code[10])
        {
            Caption = 'Fin. Charge Terms Code';
            NotBlank = true;
            TableRelation = "Finance Charge Terms".Code;
        }
        field(2; "Start Date"; Date)
        {
            Caption = 'Start Date';
            NotBlank = true;
        }
        field(3; "Interest Rate"; Decimal)
        {
            Caption = 'Interest Rate';
            MaxValue = 100;
            MinValue = 0;
        }
        field(4; "Interest Period (Days)"; Integer)
        {
            Caption = 'Interest Period (Days)';
        }
    }

    keys
    {
        key(Key1; "Fin. Charge Terms Code", "Start Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

