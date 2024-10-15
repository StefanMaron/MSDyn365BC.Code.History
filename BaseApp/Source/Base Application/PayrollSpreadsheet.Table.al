table 17453 "Payroll Spreadsheet"
{
    Caption = 'Payroll Spreadsheet';

    fields
    {
        field(1; Name; Text[105])
        {
            Caption = 'Name';
        }
        field(2; "Value 1"; Decimal)
        {
            Caption = 'Value 1';
        }
        field(3; "Value 2"; Decimal)
        {
            Caption = 'Value 2';
        }
        field(4; "Value 3"; Decimal)
        {
            Caption = 'Value 3';
        }
        field(5; "Dimension Code"; Code[30])
        {
            Caption = 'Dimension Code';
        }
        field(6; "Code"; Text[5])
        {
            Caption = 'Code';
        }
        field(7; "Code 2"; Text[5])
        {
            Caption = 'Code 2';
        }
        field(8; "Name 2"; Text[70])
        {
            Caption = 'Name 2';
        }
        field(9; Days; Text[10])
        {
            Caption = 'Days';
        }
        field(10; Hours; Text[10])
        {
            Caption = 'Hours';
        }
        field(11; "Value Text 1"; Text[10])
        {
            Caption = 'Value Text 1';
        }
        field(12; "Value Text 2"; Text[10])
        {
            Caption = 'Value Text 2';
        }
        field(13; "Employee No."; Text[10])
        {
            Caption = 'Employee No.';
        }
        field(14; "Posting Group Code"; Code[10])
        {
            Caption = 'Posting Group Code';
        }
        field(20; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(21; "Element Type"; Option)
        {
            Caption = 'Element Type';
            OptionCaption = ' ,Addition or Deduction,Other Income';
            OptionMembers = " ","Addition or Deduction","Other Income";
        }
        field(22; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            TableRelation = "Payroll Element";
        }
        field(23; "Taxable Pension Fund"; Decimal)
        {
            Caption = 'Taxable Pension Fund';
        }
        field(24; "Taxable Other"; Decimal)
        {
            Caption = 'Taxable Other';
        }
        field(25; "Fund 1"; Decimal)
        {
            Caption = 'Fund 1';
        }
        field(26; "Fund 2"; Decimal)
        {
            Caption = 'Fund 2';
        }
        field(27; "Fund 3"; Decimal)
        {
            Caption = 'Fund 3';
        }
        field(28; "Fund 4"; Decimal)
        {
            Caption = 'Fund 4';
        }
        field(29; "Fund 5"; Decimal)
        {
            Caption = 'Fund 5';
        }
        field(30; "Total Fund"; Decimal)
        {
            Caption = 'Total Fund';
        }
        field(31; "Fund 6"; Decimal)
        {
            Caption = 'Fund 6';
        }
        field(32; "Hours Tariff"; Text[4])
        {
            Caption = 'Hours Tariff';
        }
        field(33; "Fund 7"; Decimal)
        {
            Caption = 'Fund 7';
        }
        field(34; "Fund 8"; Decimal)
        {
            Caption = 'Fund 8';
        }
    }

    keys
    {
        key(Key1; "Dimension Code", Name, "Name 2")
        {
            Clustered = true;
        }
        key(Key2; "Code", Name, "Code 2", "Name 2")
        {
        }
        key(Key3; "Employee No.", "Code 2", "Name 2", "Code", Name)
        {
        }
        key(Key4; "Code 2", "Name 2", "Code", Name)
        {
        }
        key(Key5; Name)
        {
        }
        key(Key6; "Dimension Code", "Posting Group Code")
        {
        }
        key(Key7; "Posting Group Code", "Dimension Code")
        {
        }
        key(Key8; "Code", "Code 2", Name, "Name 2", "Employee No.")
        {
        }
        key(Key9; "Line No.")
        {
        }
    }

    fieldgroups
    {
    }
}

