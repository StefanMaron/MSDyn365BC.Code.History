table 14961 "Payroll Analysis Line Template"
{
    Caption = 'Payroll Analysis Line Template';
    LookupPageID = "Pay. Analysis Line Templates";

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
        field(3; "Default Column Template Name"; Code[10])
        {
            Caption = 'Default Column Template Name';
            TableRelation = "Payroll Analysis Column Tmpl.";
        }
        field(4; "Payroll Analysis View Code"; Code[10])
        {
            Caption = 'Payroll Analysis View Code';
            TableRelation = "Payroll Analysis View".Code;

            trigger OnValidate()
            begin
                ValidateAnalysisViewCode;
            end;
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
        PayrollAnalysisLine.SetRange("Analysis Line Template Name", Name);
        PayrollAnalysisLine.DeleteAll(true);
    end;

    var
        PayrollAnalysisLine: Record "Payroll Analysis Line";
        CalcGroupFilterNotEmptyErr: Label 'Payroll Analysis Line Template %1 contains lines with Calc Group Filter. This filter can be used only with payroll analysis view.';

    [Scope('OnPrem')]
    procedure GetRecDescription(): Text[250]
    begin
        exit(StrSubstNo('%1 %2=''%3''',
            TableCaption,
            FieldCaption(Name), Name));
    end;

    local procedure ValidateAnalysisViewCode()
    begin
        if "Payroll Analysis View Code" = '' then begin
            PayrollAnalysisLine.SetRange("Analysis Line Template Name", Name);
            PayrollAnalysisLine.SetFilter("Calc Group Filter", '<>%1', '');
            if not PayrollAnalysisLine.IsEmpty then
                Error(CalcGroupFilterNotEmptyErr, Name);
        end;
    end;
}

