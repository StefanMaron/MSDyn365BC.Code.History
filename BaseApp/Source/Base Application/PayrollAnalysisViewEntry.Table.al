table 14966 "Payroll Analysis View Entry"
{
    Caption = 'Payroll Analysis View Entry';
    LookupPageID = "Payroll Analysis View Entries";

    fields
    {
        field(1; "Analysis View Code"; Code[10])
        {
            Caption = 'Analysis View Code';
            NotBlank = true;
            TableRelation = "Payroll Analysis View";
        }
        field(3; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element";
        }
        field(4; "Payroll Element Type"; Option)
        {
            Caption = 'Payroll Element Type';
            OptionCaption = 'Wage,Bonus,Income Tax,Netto Salary,Tax Deduction,Deduction,Other,FSS,FFOMS,TFOMS,FSS Travm,PF Nakop,PF Strax';
            OptionMembers = Wage,Bonus,"Income Tax","Netto Salary","Tax Deduction",Deduction,Other,FSS,FFOMS,TFOMS,"FSS Travm","PF Nakop","PF Strax";
        }
        field(5; "Element Group"; Code[20])
        {
            Caption = 'Element Group';
            TableRelation = "Payroll Element Group";
        }
        field(8; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(9; "Org. Unit Code"; Code[10])
        {
            Caption = 'Org. Unit Code';
            TableRelation = "Organizational Unit";
        }
        field(10; "Use PF Accum. System"; Boolean)
        {
            Caption = 'Use PF Accum. System';
        }
        field(15; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(20; "Dimension 1 Value Code"; Code[20])
        {
            CaptionClass = GetCaptionClass(1);
            Caption = 'Dimension 1 Value Code';
        }
        field(21; "Dimension 2 Value Code"; Code[20])
        {
            CaptionClass = GetCaptionClass(2);
            Caption = 'Dimension 2 Value Code';
        }
        field(22; "Dimension 3 Value Code"; Code[20])
        {
            CaptionClass = GetCaptionClass(3);
            Caption = 'Dimension 3 Value Code';
        }
        field(23; "Dimension 4 Value Code"; Code[20])
        {
            CaptionClass = GetCaptionClass(4);
            Caption = 'Dimension 4 Value Code';
        }
        field(30; "Payroll Amount"; Decimal)
        {
            Caption = 'Payroll Amount';
        }
        field(31; "Taxable Amount"; Decimal)
        {
            Caption = 'Taxable Amount';
        }
        field(40; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(41; "Calc Group"; Code[10])
        {
            Caption = 'Calc Group';
            TableRelation = "Payroll Calc Group";
        }
    }

    keys
    {
        key(Key1; "Analysis View Code", "Element Code", "Payroll Element Type", "Element Group", "Employee No.", "Org. Unit Code", "Use PF Accum. System", "Posting Date", "Dimension 1 Value Code", "Dimension 2 Value Code", "Dimension 3 Value Code", "Dimension 4 Value Code", "Calc Group")
        {
            Clustered = true;
            SumIndexFields = "Payroll Amount", "Taxable Amount";
        }
    }

    fieldgroups
    {
    }

    var
        PayrollAnalysisView: Record "Payroll Analysis View";
        Text000: Label '1,5,,Dimension 1 Value Code';
        Text001: Label '1,5,,Dimension 2 Value Code';
        Text002: Label '1,5,,Dimension 3 Value Code';
        Text003: Label '1,5,,Dimension 4 Value Code';

    [Scope('OnPrem')]
    procedure GetCaptionClass(AnalysisViewDimType: Integer): Text[250]
    begin
        if PayrollAnalysisView.Code <> "Analysis View Code" then
            PayrollAnalysisView.Get("Analysis View Code");

        case AnalysisViewDimType of
            1:
                begin
                    if PayrollAnalysisView."Dimension 1 Code" <> '' then
                        exit('1,5,' + PayrollAnalysisView."Dimension 1 Code");
                    exit(Text000);
                end;
            2:
                begin
                    if PayrollAnalysisView."Dimension 2 Code" <> '' then
                        exit('1,5,' + PayrollAnalysisView."Dimension 2 Code");
                    exit(Text001);
                end;
            3:
                begin
                    if PayrollAnalysisView."Dimension 3 Code" <> '' then
                        exit('1,5,' + PayrollAnalysisView."Dimension 3 Code");
                    exit(Text002);
                end;
            4:
                begin
                    if PayrollAnalysisView."Dimension 4 Code" <> '' then
                        exit('1,5,' + PayrollAnalysisView."Dimension 4 Code");
                    exit(Text003);
                end;
        end;
    end;
}

