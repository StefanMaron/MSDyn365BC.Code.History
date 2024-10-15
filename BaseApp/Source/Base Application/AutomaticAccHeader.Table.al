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
            CalcFormula = Sum ("Automatic Acc. Line"."Allocation %" WHERE("Automatic Acc. No." = FIELD("No.")));
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

    var
        AutoAccountLine: Record "Automatic Acc. Line";
}

