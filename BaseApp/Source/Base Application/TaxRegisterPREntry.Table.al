table 17214 "Tax Register PR Entry"
{
    Caption = 'Tax Register PR Entry';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Section Code"; Code[10])
        {
            Caption = 'Section Code';
            TableRelation = "Tax Register Section";
        }
        field(3; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            Editable = false;
        }
        field(5; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            Editable = false;
        }
        field(13; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(21; Amount; Decimal)
        {
            BlankZero = true;
            Caption = 'Amount';
        }
        field(38; "Where Used Register IDs"; Code[61])
        {
            Caption = 'Where Used Register IDs';
            Editable = false;
        }
        field(50; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(101; "Ledger Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Ledger Entry No.';
        }
        field(102; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Payment';
            OptionMembers = " ",Payment;
        }
        field(103; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(106; Description; Text[70])
        {
            Caption = 'Description';
        }
        field(108; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(121; "Dimension 1 Value Code"; Code[20])
        {
            CaptionClass = TaxRegMgt.GetDimCaptionClass("Section Code", 1);
            Caption = 'Dimension 1 Value Code';
        }
        field(122; "Dimension 2 Value Code"; Code[20])
        {
            CaptionClass = TaxRegMgt.GetDimCaptionClass("Section Code", 2);
            Caption = 'Dimension 2 Value Code';
        }
        field(123; "Dimension 3 Value Code"; Code[20])
        {
            CaptionClass = TaxRegMgt.GetDimCaptionClass("Section Code", 3);
            Caption = 'Dimension 3 Value Code';
        }
        field(124; "Dimension 4 Value Code"; Code[20])
        {
            CaptionClass = TaxRegMgt.GetDimCaptionClass("Section Code", 4);
            Caption = 'Dimension 4 Value Code';
        }
        field(150; "Employee Payroll Account No."; Code[20])
        {
            Caption = 'Employee Payroll Account No.';
            TableRelation = "G/L Account";
        }
        field(151; "Org. Unit Code"; Code[10])
        {
            Caption = 'Org. Unit Code';
            TableRelation = "Organizational Unit";
        }
        field(152; "Payroll Element Type"; Option)
        {
            Caption = 'Payroll Element Type';
            OptionCaption = 'Wage,Bonus,Income Tax,Netto Salary,Tax Deduction,Deduction,Other,Funds,Reporting';
            OptionMembers = Wage,Bonus,"Income Tax","Netto Salary","Tax Deduction",Deduction,Other,Funds,Reporting;
        }
        field(153; "Payroll Element Code"; Code[20])
        {
            Caption = 'Payroll Element Code';
            TableRelation = "Payroll Element";
        }
        field(154; "Payroll Directory Code"; Code[10])
        {
            Caption = 'Payroll Directory Code';
            TableRelation = "Payroll Directory".Code WHERE(Type = FIELD("Payroll Directory Type"));
        }
        field(155; "Payroll Element Group"; Code[20])
        {
            Caption = 'Payroll Element Group';
            TableRelation = "Payroll Element Group";
        }
        field(156; "Payroll Directory Type"; Option)
        {
            Caption = 'Payroll Directory Type';
            OptionCaption = ' ,Income,Allowance,Tax Deduction,Tax';
            OptionMembers = " ",Income,Allowance,"Tax Deduction",Tax;
        }
        field(158; "Org. Unit Name"; Text[50])
        {
            CalcFormula = Lookup ("Organizational Unit".Name WHERE(Code = FIELD("Org. Unit Code")));
            Caption = 'Org. Unit Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(159; "Payroll Source"; Option)
        {
            Caption = 'Payroll Source';
            OptionCaption = ' ,Cost,Profit,FSI,FOSI';
            OptionMembers = " ",Cost,Profit,FSI,FOSI;
        }
        field(160; "Employee Statistics Group Code"; Code[10])
        {
            Caption = 'Employee Statistics Group Code';
            TableRelation = "Employee Statistics Group";
        }
        field(161; "Employee Category Code"; Code[10])
        {
            Caption = 'Employee Category Code';
            TableRelation = "Employee Category";
        }
        field(162; "Payroll Posting Group"; Code[20])
        {
            Caption = 'Payroll Posting Group';
            TableRelation = "Payroll Posting Group";
        }
        field(163; "Fund Type"; Option)
        {
            Caption = 'Fund Type';
            OptionCaption = ' ,FSI,FSI Injury,Federal FMI,Territorial FMI,PF Accum. Part,PF Insur. Part';
            OptionMembers = " ",FSI,"FSI Injury","Federal FMI","Territorial FMI","PF Accum. Part","PF Insur. Part";
        }
        field(201; "Amount (FCY)"; Decimal)
        {
            BlankZero = true;
            Caption = 'Amount (FCY)';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Section Code", "Ending Date")
        {
        }
        key(Key3; "Section Code", "Starting Date")
        {
        }
        key(Key4; "Section Code", "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }

    var
        TaxRegMgt: Codeunit "Tax Register Mgt.";

    [Scope('OnPrem')]
    procedure ObjectName(Type: Option "Full Name","Last Name and Initials","Last Name Only"): Text[100]
    var
        Employee: Record Employee;
    begin
        if Employee.Get("Employee No.") then
            case Type of
                Type::"Full Name":
                    exit(Employee.FullName);
                Type::"Last Name and Initials":
                    exit(Employee."Last Name" + ' ' + Employee.Initials);
                Type::"Last Name Only":
                    exit(Employee."Last Name");
                else
                    Error('');
            end;
    end;

    [Scope('OnPrem')]
    procedure Navigating()
    var
        Navigate: Page Navigate;
    begin
        Clear(Navigate);
        Navigate.SetDoc("Posting Date", "Document No.");
        Navigate.Run;
    end;

    [Scope('OnPrem')]
    procedure SetFieldFilter(FieldNumber: Integer) FieldInList: Boolean
    begin
        FieldInList := FieldNumber in [
                                       FieldNo(Amount)
                                       ];
    end;

    [Scope('OnPrem')]
    procedure FormTitle(): Text[250]
    var
        TaxRegName: Record "Tax Register";
    begin
        FilterGroup(2);
        TaxRegName.SetRange("Section Code", "Section Code");
        TaxRegName.SetFilter("Register ID", DelChr(GetFilter("Where Used Register IDs"), '=', '~'));
        FilterGroup(0);
        if TaxRegName.Find('-') then
            if TaxRegName.Next = 0 then
                exit(TaxRegName.Description);
    end;
}

