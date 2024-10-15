table 14962 "Payroll Analysis Line"
{
    Caption = 'Payroll Analysis Line';

    fields
    {
        field(2; "Analysis Line Template Name"; Code[10])
        {
            Caption = 'Analysis Line Template Name';
            TableRelation = "Payroll Analysis Line Template";
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Row No."; Code[10])
        {
            Caption = 'Row No.';
        }
        field(5; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(6; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Payroll Element,Payroll Element Group,Employee,Org. Unit,Formula';
            OptionMembers = "Payroll Element","Payroll Element Group",Employee,"Org. Unit",Formula;

            trigger OnValidate()
            begin
                if Type <> xRec.Type then
                    if Type = Type::"Payroll Element" then
                        TestField("Element Filter", '');
            end;
        }
        field(7; Expression; Text[250])
        {
            Caption = 'Expression';
            TableRelation = IF (Type = CONST("Payroll Element")) "Payroll Element"
            ELSE
            IF (Type = CONST("Payroll Element Group")) "Payroll Element Group"
            ELSE
            IF (Type = CONST(Employee)) Employee
            ELSE
            IF (Type = CONST("Org. Unit")) "Organizational Unit";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(8; "New Page"; Boolean)
        {
            Caption = 'New Page';
        }
        field(9; Show; Option)
        {
            Caption = 'Show';
            OptionCaption = 'Yes,No,If Any Column Not Zero';
            OptionMembers = Yes,No,"If Any Column Not Zero";
        }
        field(10; Bold; Boolean)
        {
            Caption = 'Bold';
        }
        field(11; Italic; Boolean)
        {
            Caption = 'Italic';
        }
        field(12; Underline; Boolean)
        {
            Caption = 'Underline';
        }
        field(13; "Show Opposite Sign"; Boolean)
        {
            Caption = 'Show Opposite Sign';
        }
        field(15; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(16; "Employee Filter"; Code[20])
        {
            Caption = 'Employee Filter';
            FieldClass = FlowFilter;
            TableRelation = Employee;
        }
        field(17; "Dimension 1 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(1);
            Caption = 'Dimension 1 Filter';
            FieldClass = FlowFilter;
        }
        field(18; "Dimension 2 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(2);
            Caption = 'Dimension 2 Filter';
            FieldClass = FlowFilter;
        }
        field(19; "Dimension 3 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(3);
            Caption = 'Dimension 3 Filter';
            FieldClass = FlowFilter;
        }
        field(20; "Dimension 4 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(4);
            Caption = 'Dimension 4 Filter';
            FieldClass = FlowFilter;
        }
        field(21; "Dimension 1 Totaling"; Text[80])
        {
            CaptionClass = GetCaptionClass(5);
            Caption = 'Dimension 1 Totaling';
            //This property is currently not supported
            //TestTableRelation = false;
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(22; "Dimension 2 Totaling"; Text[80])
        {
            CaptionClass = GetCaptionClass(6);
            Caption = 'Dimension 2 Totaling';
            //This property is currently not supported
            //TestTableRelation = false;
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(23; "Dimension 3 Totaling"; Text[80])
        {
            CaptionClass = GetCaptionClass(7);
            Caption = 'Dimension 3 Totaling';
            //This property is currently not supported
            //TestTableRelation = false;
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(24; "Dimension 4 Totaling"; Text[80])
        {
            CaptionClass = GetCaptionClass(8);
            Caption = 'Dimension 4 Totaling';
            //This property is currently not supported
            //TestTableRelation = false;
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(26; Indentation; Integer)
        {
            Caption = 'Indentation';
            MinValue = 0;
        }
        field(32; "Element Type Filter"; Text[150])
        {
            Caption = 'Element Type Filter';

            trigger OnValidate()
            begin
                PayrollAnalysisReportMgt.ValidateFilter(
                  "Element Type Filter", DATABASE::"Payroll Analysis Line",
                  FieldNo("Element Type Filter"), true);
            end;
        }
        field(33; "Element Filter"; Text[250])
        {
            Caption = 'Element Filter';
            TableRelation = "Payroll Element";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if xRec."Element Filter" <> "Element Filter" then
                    if "Element Filter" <> '' then
                        if Type = Type::"Payroll Element" then
                            FieldError(Type);
            end;
        }
        field(34; "Use PF Accum. System Filter"; Option)
        {
            Caption = 'Use PF Accum. System Filter';
            OptionCaption = ' ,Yes,No';
            OptionMembers = " ",Yes,No;
        }
        field(39; "Income Tax Base Filter"; Option)
        {
            Caption = 'Income Tax Base Filter';
            OptionCaption = ' ,Yes,No';
            OptionMembers = " ",Yes,No;
        }
        field(41; "Work Mode Filter"; Text[80])
        {
            Caption = 'Work Mode Filter';
        }
        field(42; "Disability Group Filter"; Text[30])
        {
            Caption = 'Disability Group Filter';
        }
        field(43; "Payment Source Filter"; Text[150])
        {
            Caption = 'Payment Source Filter';

            trigger OnValidate()
            begin
                PayrollAnalysisReportMgt.ValidateFilter(
                  "Element Type Filter", DATABASE::"Payroll Analysis Line",
                  FieldNo("Payment Source Filter"), true);
            end;
        }
        field(44; "Contract Type Filter"; Text[30])
        {
            Caption = 'Contract Type Filter';
        }
        field(45; "Insurance Fee Category Filter"; Code[30])
        {
            Caption = 'Insurance Fee Category Filter';
            FieldClass = FlowFilter;
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(46; "Calc Group Filter"; Text[150])
        {
            Caption = 'Calc Group Filter';
            TableRelation = "Payroll Calc Group";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                ValidateCalcGroupFilter;
            end;
        }
    }

    keys
    {
        key(Key1; "Analysis Line Template Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        GLSetup: Record "General Ledger Setup";
        PayrollAnalysisView: Record "Payroll Analysis View";
        PayrollAnalysisReportMgt: Codeunit "Payroll Analysis Report Mgt.";
        HasGLSetup: Boolean;
        Text009: Label '1,6,,Dimension %1 Filter';
        Text010: Label ',, Totaling';
        Text011: Label '1,5,,Dimension %1 Totaling';

    local procedure GetCaptionClass(DimNo: Integer): Text[250]
    begin
        GetPayrollAnalysisView;

        case DimNo of
            1:
                if PayrollAnalysisView."Dimension 1 Code" <> '' then
                    exit('1,6,' + PayrollAnalysisView."Dimension 1 Code");
            2:
                if PayrollAnalysisView."Dimension 2 Code" <> '' then
                    exit('1,6,' + PayrollAnalysisView."Dimension 2 Code");
            3:
                if PayrollAnalysisView."Dimension 3 Code" <> '' then
                    exit('1,6,' + PayrollAnalysisView."Dimension 3 Code");
            4:
                if PayrollAnalysisView."Dimension 4 Code" <> '' then
                    exit('1,6,' + PayrollAnalysisView."Dimension 4 Code");
            5:
                if PayrollAnalysisView."Dimension 1 Code" <> '' then
                    exit('1,5,' + PayrollAnalysisView."Dimension 1 Code" + Text010);
            6:
                if PayrollAnalysisView."Dimension 2 Code" <> '' then
                    exit('1,5,' + PayrollAnalysisView."Dimension 2 Code" + Text010);
            7:
                if PayrollAnalysisView."Dimension 3 Code" <> '' then
                    exit('1,5,' + PayrollAnalysisView."Dimension 3 Code" + Text010);
            8:
                if PayrollAnalysisView."Dimension 4 Code" <> '' then
                    exit('1,5,' + PayrollAnalysisView."Dimension 4 Code" + Text010);
        end;
        if DimNo <= 4 then
            exit(StrSubstNo(Text009, DimNo));
        exit(StrSubstNo(Text011, DimNo - 3));
    end;

    local procedure GetPayrollAnalysisView()
    var
        PayrollAnalysisLineTemplate: Record "Payroll Analysis Line Template";
    begin
        if PayrollAnalysisLineTemplate.Name = "Analysis Line Template Name" then
            exit;

        if PayrollAnalysisLineTemplate.Get("Analysis Line Template Name") then
            if PayrollAnalysisLineTemplate."Payroll Analysis View Code" <> '' then
                PayrollAnalysisView.Get(PayrollAnalysisLineTemplate."Payroll Analysis View Code")
            else begin
                Clear(PayrollAnalysisView);
                if not HasGLSetup then
                    GLSetup.Get;
                HasGLSetup := true;
                PayrollAnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                PayrollAnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
            end;
    end;

    [Scope('OnPrem')]
    procedure GetRecDescription(): Text[250]
    begin
        exit(
          StrSubstNo('%1 %2=''%3'', %4=''%5''',
            TableCaption,
            FieldCaption("Analysis Line Template Name"), "Analysis Line Template Name",
            FieldCaption("Line No."), "Line No."));
    end;

    local procedure ValidateCalcGroupFilter()
    var
        PayrollAnalysisLineTemplate: Record "Payroll Analysis Line Template";
    begin
        TestField("Analysis Line Template Name");
        PayrollAnalysisLineTemplate.Get("Analysis Line Template Name");
        PayrollAnalysisLineTemplate.TestField("Payroll Analysis View Code");
    end;
}

