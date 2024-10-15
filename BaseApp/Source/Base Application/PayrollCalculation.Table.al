table 17406 "Payroll Calculation"
{
    Caption = 'Payroll Calculation';
    DataCaptionFields = "Element Code";

    fields
    {
        field(1; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            NotBlank = true;
            TableRelation = "Payroll Element";

            trigger OnValidate()
            begin
                PayrollElement.Get("Element Code");
                Description := PayrollElement.Description;
            end;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            NotBlank = true;
            TableRelation = "Payroll Period";
        }
    }

    keys
    {
        key(Key1; "Element Code", "Period Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        PayrollCalculationLine.Reset;
        PayrollCalculationLine.SetRange("Element Code", "Element Code");
        PayrollCalculationLine.SetRange("Period Code", "Period Code");
        PayrollCalculationLine.DeleteAll(true);
    end;

    trigger OnRename()
    begin
        Error(Text001, TableCaption);
    end;

    var
        PayrollCalculationLine: Record "Payroll Calculation Line";
        PayrollElement: Record "Payroll Element";
        Text001: Label 'You cannot rename a %1.';
}

