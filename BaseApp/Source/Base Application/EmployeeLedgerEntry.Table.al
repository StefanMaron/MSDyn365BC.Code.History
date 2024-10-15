table 17413 "Employee Ledger Entry"
{
    Caption = 'Employee Ledger Entry';
    LookupPageID = "Employee Ledger Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element";
        }
        field(3; "Action Starting Date"; Date)
        {
            Caption = 'Action Starting Date';
        }
        field(4; "Action Ending Date"; Date)
        {
            Caption = 'Action Ending Date';
        }
        field(5; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(6; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(7; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = "Payroll Posting Group";
        }
        field(8; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(9; "Calendar Code"; Code[10])
        {
            Caption = 'Calendar Code';
            TableRelation = "Payroll Calendar";
        }
        field(10; "Payroll Calc Group"; Code[10])
        {
            Caption = 'Payroll Calc Group';
            TableRelation = "Payroll Calc Group";
        }
        field(11; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            NotBlank = true;
            TableRelation = Employee;
        }
        field(17; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(18; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(20; "Position No."; Code[20])
        {
            Caption = 'Position No.';
            TableRelation = Position;
        }
        field(21; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            TableRelation = "Labor Contract" WHERE("Employee No." = FIELD("Employee No."));
        }
        field(22; "HR Order No."; Code[20])
        {
            Caption = 'HR Order No.';
            Editable = false;
        }
        field(23; "HR Order Date"; Date)
        {
            Caption = 'HR Order Date';
            Editable = false;
        }
        field(24; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Vacation,Sick Leave,Travel,Other Absence';
            OptionMembers = " ",Vacation,"Sick Leave",Travel,"Other Absence";
        }
        field(25; "Time Activity Code"; Code[10])
        {
            Caption = 'Time Activity Code';
            TableRelation = "Time Activity";
        }
        field(26; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(27; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(30; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(31; "Vacation Type"; Option)
        {
            Caption = 'Vacation Type';
            OptionCaption = ' ,Regular,Additional,Education,Childcare,Other';
            OptionMembers = " ",Regular,Additional,Education,Childcare,Other;
        }
        field(32; "Payment Days"; Decimal)
        {
            Caption = 'Payment Days';
        }
        field(33; "Payment Percent"; Decimal)
        {
            Caption = 'Payment Percent';
        }
        field(34; "Sick Leave Type"; Option)
        {
            Caption = 'Sick Leave Type';
            OptionCaption = ' ,Common Disease,Common Injury,Professional Disease,Work Injury,Family Member Care,Post Vaccination,Quarantine,Sanatory Cure,Pregnancy Leave,Child Care 1.5 years,Child Care 3 years';
            OptionMembers = " ","Common Disease","Common Injury","Professional Disease","Work Injury","Family Member Care","Post Vaccination",Quarantine,"Sanatory Cure","Pregnancy Leave","Child Care 1.5 years","Child Care 3 years";
        }
        field(35; "Payment Source"; Option)
        {
            Caption = 'Payment Source';
            OptionCaption = 'Employeer,FSI';
            OptionMembers = Employeer,FSI;
        }
        field(43; "Days Not Paid"; Decimal)
        {
            Caption = 'Days Not Paid';
        }
        field(45; "Relative Person No."; Code[20])
        {
            Caption = 'Relative Person No.';
        }
        field(50; "External Document No."; Text[30])
        {
            Caption = 'External Document No.';
        }
        field(51; "External Document Date"; Date)
        {
            Caption = 'External Document Date';
        }
        field(52; "External Document Issued By"; Text[50])
        {
            Caption = 'External Document Issued By';
        }
        field(53; "Tax Inspection No."; Code[10])
        {
            Caption = 'Tax Inspection No.';
        }
        field(55; "Related to Entry No."; Integer)
        {
            Caption = 'Related to Entry No.';
            TableRelation = "Employee Ledger Entry";
        }
        field(56; Terminated; Boolean)
        {
            Caption = 'Terminated';
        }
        field(111; "AE Period From"; Code[10])
        {
            Caption = 'AE Period From';
            TableRelation = "Payroll Period";
        }
        field(112; "AE Period To"; Code[10])
        {
            Caption = 'AE Period To';
            TableRelation = "Payroll Period";
        }
        field(113; "Nonworking Days"; Integer)
        {
            Caption = 'Nonworking Days';
        }
        field(117; "Time Type"; Option)
        {
            Caption = 'Time Type';
            OptionCaption = 'Days,Working Days,Working Hours';
            OptionMembers = Days,"Working Days","Working Hours";
        }
        field(125; "Payment Hours"; Decimal)
        {
            Caption = 'Payment Hours';
        }
        field(127; "Wage Period From"; Code[10])
        {
            Caption = 'Wage Period From';
            TableRelation = "Payroll Period";
        }
        field(128; "Wage Period To"; Code[10])
        {
            Caption = 'Wage Period To';
            Editable = false;
            TableRelation = "Payroll Period";
        }
        field(142; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";
        }
        field(144; "Allocation Type"; Option)
        {
            Caption = 'Allocation Type';
            OptionCaption = ' ,Quarterly Allocation,Annual Allocation,Accumulation';
            OptionMembers = " ","Quarterly Allocation","Annual Allocation",Accumulation;
        }
        field(146; "Salary Indexation"; Boolean)
        {
            Caption = 'Salary Indexation';
        }
        field(147; "Depends on Salary Element"; Code[20])
        {
            Caption = 'Depends on Salary Element';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Wage));
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions;
            end;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Employee No.", "Element Code", "Action Starting Date")
        {
            SumIndexFields = Amount, "Payment Hours", "Payment Days";
        }
        key(Key3; "Element Code")
        {
            SumIndexFields = Amount, "Payment Hours", "Payment Days";
        }
        key(Key4; "Employee No.", "Action Starting Date", "Action Ending Date", "Element Code", "Period Code", "Wage Period To")
        {
            SumIndexFields = Amount, "Payment Hours", "Payment Days";
        }
        key(Key5; "Document No.", "Document Date")
        {
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption, "Entry No."));
    end;

    [Scope('OnPrem')]
    procedure SetEndingDate(var EmployeeLedgEntry: Record "Employee Ledger Entry"; EndDate: Date)
    begin
        EmployeeLedgEntry."Action Ending Date" := EndDate;
        EmployeeLedgEntry.Modify;
    end;
}

