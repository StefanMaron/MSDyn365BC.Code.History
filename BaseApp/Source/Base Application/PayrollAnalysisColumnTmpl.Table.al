table 14963 "Payroll Analysis Column Tmpl."
{
    Caption = 'Payroll Analysis Column Tmpl.';
    LookupPageID = "Pay. Analysis Column Templates";

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        PayrollAnalysisColumn.SetRange("Analysis Column Template", Name);
        PayrollAnalysisColumn.DeleteAll(true);
    end;

    var
        PayrollAnalysisColumn: Record "Payroll Analysis Column";
}

