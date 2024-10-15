table 14969 "Payroll Statistics Buffer"
{
    Caption = 'Payroll Statistics Buffer';

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(2; "Element Type Filter"; Option)
        {
            Caption = 'Element Type Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Wage,Bonus,Income Tax,Netto Salary,Tax Deduction,Deduction,Other,FSS,FFOMS,TFOMS,FSS Travm,PF Nakop,PF Strax';
            OptionMembers = Wage,Bonus,"Income Tax","Netto Salary","Tax Deduction",Deduction,Other,FSS,FFOMS,TFOMS,"FSS Travm","PF Nakop","PF Strax";
        }
        field(3; "Element Filter"; Code[20])
        {
            Caption = 'Element Filter';
            FieldClass = FlowFilter;
            TableRelation = "Payroll Element";
            ValidateTableRelation = false;
        }
        field(4; "Employee Filter"; Code[20])
        {
            Caption = 'Employee Filter';
            FieldClass = FlowFilter;
            TableRelation = Employee;
            ValidateTableRelation = false;
        }
        field(5; "Org. Unit Filter"; Code[20])
        {
            Caption = 'Org. Unit Filter';
            FieldClass = FlowFilter;
            TableRelation = "Organizational Unit";
            ValidateTableRelation = false;
        }
        field(6; "Element Group Filter"; Code[20])
        {
            Caption = 'Element Group Filter';
            FieldClass = FlowFilter;
            TableRelation = "Payroll Element Group";
            ValidateTableRelation = false;
        }
        field(7; "Use PF Accum. System Filter"; Boolean)
        {
            Caption = 'Use PF Accum. System Filter';
            FieldClass = FlowFilter;
        }
        field(9; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            ClosingDates = true;
            FieldClass = FlowFilter;
        }
        field(10; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(11; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(12; "Work Mode Filter"; Option)
        {
            Caption = 'Work Mode Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Primary Job,Internal Co-work,External Co-work';
            OptionMembers = "Primary Job","Internal Co-work","External Co-work";
        }
        field(13; "Disability Group Filter"; Option)
        {
            Caption = 'Disability Group Filter';
            FieldClass = FlowFilter;
            OptionCaption = ' ,1,2,3';
            OptionMembers = " ","1","2","3";
        }
        field(14; "Income Tax Base Filter"; Boolean)
        {
            Caption = 'Income Tax Base Filter';
            FieldClass = FlowFilter;
        }
        field(15; "Payment Source Filter"; Option)
        {
            Caption = 'Payment Source Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Employer,FSI';
            OptionMembers = Employer,FSI;
        }
        field(16; "Contract Type Filter"; Option)
        {
            Caption = 'Contract Type Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Labor Contract,Civil Contract';
            OptionMembers = "Labor Contract","Civil Contract";
        }
        field(17; "Insurance Fee Category Filter"; Code[2])
        {
            Caption = 'Insurance Fee Category Filter';
            FieldClass = FlowFilter;
        }
        field(20; "Payroll Amount"; Decimal)
        {
            CalcFormula = Sum ("Payroll Ledger Entry"."Payroll Amount" WHERE("Employee No." = FIELD("Employee Filter"),
                                                                             "Element Type" = FIELD("Element Type Filter"),
                                                                             "Element Code" = FIELD("Element Filter"),
                                                                             "Org. Unit Code" = FIELD("Org. Unit Filter"),
                                                                             "Element Group" = FIELD("Element Group Filter"),
                                                                             "Use PF Accum. System" = FIELD("Use PF Accum. System Filter"),
                                                                             "Posting Date" = FIELD("Date Filter"),
                                                                             "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                             "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                             "Work Mode" = FIELD("Work Mode Filter"),
                                                                             "Disability Group" = FIELD("Disability Group Filter"),
                                                                             "Income Tax Base" = FIELD("Income Tax Base Filter"),
                                                                             "Payment Source" = FIELD("Payment Source Filter"),
                                                                             "Insurance Fee Category Code" = FIELD("Insurance Fee Category Filter")));
            Caption = 'Payroll Amount';
            FieldClass = FlowField;
        }
        field(21; "Taxable Amount"; Decimal)
        {
            CalcFormula = Sum ("Payroll Ledger Entry"."Taxable Amount" WHERE("Employee No." = FIELD("Employee Filter"),
                                                                             "Element Type" = FIELD("Element Type Filter"),
                                                                             "Element Code" = FIELD("Element Filter"),
                                                                             "Org. Unit Code" = FIELD("Org. Unit Filter"),
                                                                             "Element Group" = FIELD("Element Group Filter"),
                                                                             "Use PF Accum. System" = FIELD("Use PF Accum. System Filter"),
                                                                             "Posting Date" = FIELD("Date Filter"),
                                                                             "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                             "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                             "Work Mode" = FIELD("Work Mode Filter"),
                                                                             "Disability Group" = FIELD("Disability Group Filter"),
                                                                             "Income Tax Base" = FIELD("Income Tax Base Filter"),
                                                                             "Payment Source" = FIELD("Payment Source Filter"),
                                                                             "Insurance Fee Category Code" = FIELD("Insurance Fee Category Filter")));
            Caption = 'Taxable Amount';
            FieldClass = FlowField;
        }
        field(22; Quantity; Decimal)
        {
            CalcFormula = Sum ("Payroll Ledger Entry".Quantity WHERE("Employee No." = FIELD("Employee Filter"),
                                                                     "Element Type" = FIELD("Element Type Filter"),
                                                                     "Element Code" = FIELD("Element Filter"),
                                                                     "Org. Unit Code" = FIELD("Org. Unit Filter"),
                                                                     "Element Group" = FIELD("Element Group Filter"),
                                                                     "Use PF Accum. System" = FIELD("Use PF Accum. System Filter"),
                                                                     "Posting Date" = FIELD("Date Filter"),
                                                                     "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                     "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                     "Work Mode" = FIELD("Work Mode Filter"),
                                                                     "Disability Group" = FIELD("Disability Group Filter"),
                                                                     "Income Tax Base" = FIELD("Income Tax Base Filter"),
                                                                     "Payment Source" = FIELD("Payment Source Filter"),
                                                                     "Insurance Fee Category Code" = FIELD("Insurance Fee Category Filter")));
            Caption = 'Quantity';
            FieldClass = FlowField;
        }
        field(23; "Payment Days"; Decimal)
        {
            CalcFormula = Sum ("Payroll Ledger Entry"."Payment Days" WHERE("Employee No." = FIELD("Employee Filter"),
                                                                           "Element Type" = FIELD("Element Type Filter"),
                                                                           "Element Code" = FIELD("Element Filter"),
                                                                           "Org. Unit Code" = FIELD("Org. Unit Filter"),
                                                                           "Element Group" = FIELD("Element Group Filter"),
                                                                           "Use PF Accum. System" = FIELD("Use PF Accum. System Filter"),
                                                                           "Posting Date" = FIELD("Date Filter"),
                                                                           "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                           "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                           "Work Mode" = FIELD("Work Mode Filter"),
                                                                           "Disability Group" = FIELD("Disability Group Filter"),
                                                                           "Income Tax Base" = FIELD("Income Tax Base Filter"),
                                                                           "Payment Source" = FIELD("Payment Source Filter")));
            Caption = 'Payment Days';
            FieldClass = FlowField;
        }
        field(70; "Analysis View Filter"; Code[10])
        {
            Caption = 'Analysis View Filter';
            FieldClass = FlowFilter;
            TableRelation = "Payroll Analysis View";
        }
        field(71; "Dimension 1 Filter"; Code[20])
        {
            Caption = 'Dimension 1 Filter';
            FieldClass = FlowFilter;
        }
        field(72; "Dimension 2 Filter"; Code[20])
        {
            Caption = 'Dimension 2 Filter';
            FieldClass = FlowFilter;
        }
        field(73; "Dimension 3 Filter"; Code[20])
        {
            Caption = 'Dimension 3 Filter';
            FieldClass = FlowFilter;
        }
        field(74; "Dimension 4 Filter"; Code[20])
        {
            Caption = 'Dimension 4 Filter';
            FieldClass = FlowFilter;
        }
        field(90; "Analysis - Payroll Amount"; Decimal)
        {
            CalcFormula = Sum ("Payroll Analysis View Entry"."Payroll Amount" WHERE("Analysis View Code" = FIELD("Analysis View Filter"),
                                                                                    "Element Code" = FIELD("Element Filter"),
                                                                                    "Payroll Element Type" = FIELD("Element Type Filter"),
                                                                                    "Element Group" = FIELD("Element Group Filter"),
                                                                                    "Employee No." = FIELD("Employee Filter"),
                                                                                    "Org. Unit Code" = FIELD("Org. Unit Filter"),
                                                                                    "Use PF Accum. System" = FIELD("Use PF Accum. System Filter"),
                                                                                    "Posting Date" = FIELD("Date Filter"),
                                                                                    "Dimension 1 Value Code" = FIELD("Dimension 1 Filter"),
                                                                                    "Dimension 2 Value Code" = FIELD("Dimension 2 Filter"),
                                                                                    "Dimension 3 Value Code" = FIELD("Dimension 3 Filter"),
                                                                                    "Dimension 4 Value Code" = FIELD("Dimension 4 Filter"),
                                                                                    "Calc Group" = FIELD("Calc Group Filter")));
            Caption = 'Analysis - Payroll Amount';
            FieldClass = FlowField;
        }
        field(91; "Analysis - Taxable Amount"; Decimal)
        {
            CalcFormula = Sum ("Payroll Analysis View Entry"."Taxable Amount" WHERE("Analysis View Code" = FIELD("Analysis View Filter"),
                                                                                    "Element Code" = FIELD("Element Filter"),
                                                                                    "Payroll Element Type" = FIELD("Element Type Filter"),
                                                                                    "Element Group" = FIELD("Element Group Filter"),
                                                                                    "Employee No." = FIELD("Employee Filter"),
                                                                                    "Org. Unit Code" = FIELD("Org. Unit Filter"),
                                                                                    "Use PF Accum. System" = FIELD("Use PF Accum. System Filter"),
                                                                                    "Posting Date" = FIELD("Date Filter"),
                                                                                    "Dimension 1 Value Code" = FIELD("Dimension 1 Filter"),
                                                                                    "Dimension 2 Value Code" = FIELD("Dimension 2 Filter"),
                                                                                    "Dimension 3 Value Code" = FIELD("Dimension 3 Filter"),
                                                                                    "Dimension 4 Value Code" = FIELD("Dimension 4 Filter"),
                                                                                    "Calc Group" = FIELD("Calc Group Filter")));
            Caption = 'Analysis - Taxable Amount';
            FieldClass = FlowField;
        }
        field(92; "Calc Group Filter"; Code[10])
        {
            Caption = 'Calc Group Filter';
            FieldClass = FlowFilter;
            TableRelation = "Payroll Calc Group";
            ValidateTableRelation = false;
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
    }
}

