table 17418 "Payroll Ledger Entry"
{
    Caption = 'Payroll Ledger Entry';
    DrillDownPageID = "Payroll Ledger Entries";
    LookupPageID = "Payroll Ledger Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
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
        field(7; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(13; "Payroll Amount"; Decimal)
        {
            Caption = 'Payroll Amount';
        }
        field(14; "Taxable Amount"; Decimal)
        {
            Caption = 'Taxable Amount';
        }
        field(17; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(18; "Use Indexation"; Boolean)
        {
            Caption = 'Use Indexation';
        }
        field(19; "Depends on Salary"; Boolean)
        {
            Caption = 'Depends on Salary';
        }
        field(20; "Action End Date"; Date)
        {
            Caption = 'Action End Date';
        }
        field(21; "Action Start Date"; Date)
        {
            Caption = 'Action Start Date';
        }
        field(22; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = "Payroll Posting Group";
        }
        field(23; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(24; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(26; "Calc Group"; Code[10])
        {
            Caption = 'Calc Group';
            TableRelation = "Payroll Calc Group";
        }
        field(27; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(28; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(30; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element";
        }
        field(31; "Directory Code"; Code[10])
        {
            Caption = 'Directory Code';
        }
        field(32; "Element Type"; Option)
        {
            Caption = 'Element Type';
            OptionCaption = 'Wage,Bonus,Income Tax,Netto Salary,Tax Deduction,Deduction,Other,Funds,Reporting';
            OptionMembers = Wage,Bonus,"Income Tax","Netto Salary","Tax Deduction",Deduction,Other,Funds,Reporting;
        }
        field(33; "Element Group"; Code[20])
        {
            Caption = 'Element Group';
            TableRelation = "Payroll Element Group";
        }
        field(34; "Fund Type"; Option)
        {
            Caption = 'Fund Type';
            OptionCaption = ' ,FSI,FSI Injury,Federal FMI,Territorial FMI,PF Accum. Part,PF Insur. Part';
            OptionMembers = " ",FSI,"FSI Injury","Federal FMI","Territorial FMI","PF Accum. Part","PF Insur. Part";
        }
        field(35; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";
        }
        field(36; "Period Start Date"; Date)
        {
            Caption = 'Period Start Date';
        }
        field(37; "Period End Date"; Date)
        {
            Caption = 'Period End Date';
        }
        field(38; "Posting Type"; Option)
        {
            Caption = 'Posting Type';
            OptionCaption = 'Not Post,Charge,Liability,Liability Charge,Information Only';
            OptionMembers = "Not Post",Charge,Liability,"Liability Charge","Information Only";
        }
        field(39; "Vendor Ledger Entry No."; Integer)
        {
            Caption = 'Vendor Ledger Entry No.';
            TableRelation = "Vendor Ledger Entry";
        }
        field(40; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(41; "Canceled from Employee No."; Code[20])
        {
            Caption = 'Canceled from Employee No.';
            TableRelation = Employee;
        }
        field(42; "HR Order No."; Code[20])
        {
            Caption = 'HR Order No.';
        }
        field(43; "HR Order Date"; Date)
        {
            Caption = 'HR Order Date';
        }
        field(45; "Distrib. Costs"; Boolean)
        {
            Caption = 'Distrib. Costs';
        }
        field(46; "Payment Source"; Option)
        {
            Caption = 'Payment Source';
            OptionCaption = 'Employeer,FSI';
            OptionMembers = Employer,FSI;
        }
        field(50; "Time Activity Code"; Code[10])
        {
            Caption = 'Time Activity Code';
            TableRelation = "Time Activity";
        }
        field(53; "Business Unit"; Code[20])
        {
            Caption = 'Business Unit';
            TableRelation = "Business Unit";
        }
        field(57; "Calendar Code"; Code[10])
        {
            Caption = 'Calendar Code';
            TableRelation = "Payroll Calendar";
        }
        field(58; "Calc Type Code"; Code[20])
        {
            Caption = 'Calc Type Code';
            TableRelation = "Payroll Calc Type";
        }
        field(59; "Calculate Priority"; Integer)
        {
            Caption = 'Calculate Priority';
        }
        field(62; "Bonus Type"; Option)
        {
            Caption = 'Bonus Type';
            OptionCaption = ' ,Monthly,Quarterly,Semi-Annual,Annual';
            OptionMembers = " ",Monthly,Quarterly,"Semi-Annual",Annual;
        }
        field(63; "Work Mode"; Option)
        {
            Caption = 'Work Mode';
            OptionCaption = 'Primary Job,Internal Co-work,External Co-work';
            OptionMembers = "Primary Job","Internal Co-work","External Co-work";
        }
        field(64; "Disability Group"; Option)
        {
            Caption = 'Disability Group';
            OptionCaption = ' ,1,2,3';
            OptionMembers = " ","1","2","3";
        }
        field(65; "Contract Type"; Option)
        {
            Caption = 'Contract Type';
            OptionCaption = 'Labor Contract,Civil Contract';
            OptionMembers = "Labor Contract","Civil Contract";
        }
        field(73; Reversed; Boolean)
        {
            Caption = 'Reversed';
        }
        field(76; "Print Priority"; Integer)
        {
            Caption = 'Print Priority';
        }
        field(77; "AE Period From"; Code[10])
        {
            Caption = 'AE Period From';
            Editable = false;
            TableRelation = "Payroll Period";
        }
        field(78; "AE Period To"; Code[10])
        {
            Caption = 'AE Period To';
            TableRelation = "Payroll Period";
        }
        field(79; "Org. Unit Code"; Code[10])
        {
            Caption = 'Org. Unit Code';
            TableRelation = "Organizational Unit";
        }
        field(81; "Use PF Accum. System"; Boolean)
        {
            Caption = 'Use PF Accum. System';
        }
        field(82; "Pay Type"; Option)
        {
            Caption = 'Pay Type';
            OptionCaption = ' ,Salary Schedule,Social,Other Income';
            OptionMembers = " ","Salary Schedule",Social,"Other Income";
        }
        field(87; "Employee Payroll Account No."; Code[20])
        {
            Caption = 'Employee Payroll Account No.';
        }
        field(90; "Insurance Fee Category Code"; Code[2])
        {
            Caption = 'Insurance Fee Category Code';
        }
        field(109; "Amount (ACY)"; Decimal)
        {
            Caption = 'Amount (ACY)';
        }
        field(113; "FSI Base"; Boolean)
        {
            Caption = 'FSI Base';
        }
        field(115; "Federal FMI Base"; Boolean)
        {
            Caption = 'Federal FMI Base';
        }
        field(116; "Territorial FMI Base"; Boolean)
        {
            Caption = 'Territorial FMI Base';
        }
        field(117; "Pension Fund Base"; Boolean)
        {
            Caption = 'Pension Fund Base';
        }
        field(118; "Income Tax Base"; Boolean)
        {
            Caption = 'Income Tax Base';
        }
        field(119; "FSI Injury Base"; Boolean)
        {
            Caption = 'FSI Injury Base';
        }
        field(141; "Wage Period From"; Code[10])
        {
            Caption = 'Wage Period From';
            TableRelation = "Payroll Period";
        }
        field(142; "Wage Period To"; Code[10])
        {
            Caption = 'Wage Period To';
            TableRelation = "Payroll Period";
        }
        field(201; "Source Pay"; Option)
        {
            Caption = 'Source Pay';
            OptionCaption = ' ,Cost,Profit,FSI,FOSI';
            OptionMembers = " ",Cost,Profit,FSI,FOSI;
        }
        field(220; "AE Total Earnings"; Decimal)
        {
            Caption = 'AE Total Earnings';
            Editable = false;
        }
        field(221; "AE Daily Earnings"; Decimal)
        {
            Caption = 'AE Daily Earnings';
            Editable = false;
        }
        field(222; "AE Hourly Earnings"; Decimal)
        {
            Caption = 'AE Hourly Earnings';
        }
        field(223; "AE Total Days"; Decimal)
        {
            Caption = 'AE Total Days';
            Editable = false;
        }
        field(234; "Payment Percent"; Decimal)
        {
            Caption = 'Payment Percent';
        }
        field(240; "Code OKATO"; Code[11])
        {
            Caption = 'Code OKATO';
        }
        field(241; "Code KPP"; Code[10])
        {
            Caption = 'Code KPP';
        }
        field(244; "Vacation Posting Group"; Code[20])
        {
            Caption = 'Vacation Posting Group';
            TableRelation = "Payroll Posting Group";
        }
        field(250; "Working Days"; Decimal)
        {
            Caption = 'Working Days';
        }
        field(251; "Working Hours"; Decimal)
        {
            Caption = 'Working Hours';
        }
        field(252; "Worked Days"; Decimal)
        {
            Caption = 'Worked Days';
        }
        field(253; "Worked Hours"; Decimal)
        {
            Caption = 'Worked Hours';
        }
        field(256; "Payment Days"; Decimal)
        {
            Caption = 'Payment Days';
        }
        field(257; "Payment Hours"; Decimal)
        {
            Caption = 'Payment Hours';
        }
        field(258; "Days Not Paid"; Decimal)
        {
            Caption = 'Days Not Paid';
        }
        field(259; "Future Period Vacation Posted"; Boolean)
        {
            Caption = 'Future Period Vacation Posted';
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
        key(Key2; "Element Code")
        {
        }
        key(Key3; "Employee No.", "Period Code", "Element Code")
        {
        }
        key(Key4; "Org. Unit Code", "Element Type", "Element Code", "Posting Date", "Period Code", "Element Group", "Employee No.", "Use PF Accum. System", "Global Dimension 1 Code", "Global Dimension 2 Code", "Income Tax Base", "Work Mode", "Disability Group", "Payment Source")
        {
            SumIndexFields = "Payroll Amount", "Taxable Amount", Quantity, "Payment Days";
        }
        key(Key5; "HR Order No.", "HR Order Date", "Document Type")
        {
        }
        key(Key6; "Document No.", "Posting Date")
        {
        }
        key(Key7; "Posting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Employee No.", "Posting Date", "Document Type", "Document No.", "Element Code")
        {
        }
    }

    [Scope('OnPrem')]
    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption, "Entry No."));
    end;
}

