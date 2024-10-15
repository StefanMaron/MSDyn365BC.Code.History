table 11203 "Automatic Acc. Header"
{
    Caption = 'Automatic Acc. Header';
    DrillDownPageID = "Automatic Acc. List";
    LookupPageID = "Automatic Acc. List";

    fields
    {
        field(1; "No."; Code[10])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; Balance; Decimal)
        {
            CalcFormula = Sum("Automatic Acc. Line"."Allocation %" WHERE("Automatic Acc. No." = FIELD("No.")));
            Caption = 'Balance';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        AutoAccountLine.SetRange("Automatic Acc. No.", "No.");
        AutoAccountLine.DeleteAll(true);
    end;

    trigger OnInsert()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0001P9A', AccTok, Enum::"Feature Uptake Status"::"Set up");
    end;


    var
        AutoAccountLine: Record "Automatic Acc. Line";
        AccTok: Label 'SE Automatic Account', Locked = true;
}

