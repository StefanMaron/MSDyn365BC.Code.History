table 17419 "Detailed Payroll Ledger Entry"
{
    Caption = 'Detailed Payroll Ledger Entry';
    LookupPageID = "Dtld. Payroll Ledger Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Payroll Ledger Entry No."; Integer)
        {
            Caption = 'Payroll Ledger Entry No.';
            TableRelation = "Payroll Ledger Entry";
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Vacation,Sick Leave,Travel,Other Absence';
            OptionMembers = " ",Vacation,"Sick Leave",Travel,"Other Absence";
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; "Payroll Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Payroll Amount';
        }
        field(8; "Taxable Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Taxable Amount';
        }
        field(11; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(12; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(13; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(15; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(16; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(20; "Wage Period Code"; Code[10])
        {
            Caption = 'Wage Period Code';
            TableRelation = "Payroll Period";
        }
        field(21; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";
        }
        field(25; "Posting Type"; Option)
        {
            Caption = 'Posting Type';
            Editable = false;
            OptionCaption = 'Not Post,Charge,Liability,Liability Charge,Information Only';
            OptionMembers = "Not Post",Charge,Liability,"Liability Charge","Information Only";
        }
        field(26; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = "Payroll Posting Group";
        }
        field(28; "Directory Code"; Code[10])
        {
            Caption = 'Directory Code';
        }
        field(30; "Element Type"; Option)
        {
            Caption = 'Element Type';
            Editable = false;
            OptionCaption = 'Wage,Bonus,Income Tax,Netto Salary,Tax Deduction,Deduction,Other,Funds,Reporting';
            OptionMembers = Wage,Bonus,"Income Tax","Netto Salary","Tax Deduction",Deduction,Other,Funds,Reporting;
        }
        field(31; "Element Group"; Code[20])
        {
            Caption = 'Element Group';
            Editable = false;
            TableRelation = "Payroll Element Group";
        }
        field(32; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element" WHERE(Type = FIELD("Element Type"));
        }
        field(33; "Bonus Type"; Option)
        {
            Caption = 'Bonus Type';
            OptionCaption = ' ,Monthly,Quarterly,Semi-Annual,Annual';
            OptionMembers = " ",Monthly,Quarterly,"Semi-Annual",Annual;
        }
        field(34; "Fund Type"; Option)
        {
            Caption = 'Fund Type';
            OptionCaption = ' ,FSI,FSI Injury,Federal FMI,Territorial FMI,PF Accum. Part,PF Insur. Part';
            OptionMembers = " ",FSI,"FSI Injury","Federal FMI","Territorial FMI","PF Accum. Part","PF Insur. Part";
        }
        field(35; "Salary Indexation"; Boolean)
        {
            Caption = 'Salary Indexation';
        }
        field(36; "Depends on Salary Element"; Code[20])
        {
            Caption = 'Depends on Salary Element';
            TableRelation = "Payroll Element";
        }
        field(42; "HR Order No."; Code[20])
        {
            Caption = 'HR Order No.';
        }
        field(43; "HR Order Date"; Date)
        {
            Caption = 'HR Order Date';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Employee No.", "Element Type", "Element Group", "Element Code", "Posting Type", "Posting Group", "Directory Code", "Period Code", "Wage Period Code", "Posting Date")
        {
            SumIndexFields = "Payroll Amount", "Taxable Amount";
        }
        key(Key3; "Employee No.", "Wage Period Code", "Bonus Type")
        {
            SumIndexFields = "Payroll Amount";
        }
        key(Key4; "HR Order No.", "HR Order Date", "Document Type")
        {
        }
        key(Key5; "Document No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }
}

