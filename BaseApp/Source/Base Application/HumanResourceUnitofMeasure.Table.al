table 5220 "Human Resource Unit of Measure"
{
    Caption = 'Human Resource Unit of Measure';
    DataCaptionFields = "Code";
    DrillDownPageID = "Human Res. Units of Measure";
    LookupPageID = "Human Res. Units of Measure";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            TableRelation = "Unit of Measure";
        }
        field(2; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            InitValue = 1;

            trigger OnValidate()
            begin
                if "Qty. per Unit of Measure" <= 0 then
                    FieldError("Qty. per Unit of Measure", Text000);
                HumanResSetup.Get();
                if HumanResSetup."Base Unit of Measure" = Code then
                    TestField("Qty. per Unit of Measure", 1);
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", "Qty. per Unit of Measure")
        {
        }
    }

    var
        Text000: Label 'must be greater than 0';
        HumanResSetup: Record "Human Resources Setup";
}

