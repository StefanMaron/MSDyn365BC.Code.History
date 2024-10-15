table 17398 "Person Income Entry"
{
    Caption = 'Person Income Entry';
    DrillDownPageID = "Person Income Entries";

    fields
    {
        field(1; "Person Income Line No."; Integer)
        {
            Caption = 'Person Income Line No.';
        }
        field(3; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionCaption = ' ,Taxable Income,Tax Deduction,Accrued Income Tax,Paid Income Tax,Paid Taxable Income';
            OptionMembers = " ","Taxable Income","Tax Deduction","Accrued Income Tax","Paid Income Tax","Paid Taxable Income";
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Payment';
            OptionMembers = " ",Payment;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; Base; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Base';
        }
        field(8; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(9; "Person No."; Code[20])
        {
            Caption = 'Person No.';
            TableRelation = Person;
        }
        field(10; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";
        }
        field(11; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("User ID");
            end;
        }
        field(13; "Person Income No."; Code[20])
        {
            Caption = 'Person Income No.';
            TableRelation = "Person Income Header";

            trigger OnValidate()
            var
                PersonIncomeHeader: Record "Person Income Header";
            begin
                PersonIncomeHeader.Get("Person Income No.");
                "Person No." := PersonIncomeHeader."Person No.";
            end;
        }
        field(14; "Tax Code"; Code[10])
        {
            Caption = 'Tax Code';
            TableRelation = "Payroll Directory".Code WHERE(Type = CONST(Income));
        }
        field(16; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(17; "Tax %"; Option)
        {
            Caption = 'Tax %';
            OptionCaption = ' ,13,30,35,9';
            OptionMembers = " ","13","30","35","9";
        }
        field(18; "Tax Deduction Code"; Code[10])
        {
            Caption = 'Tax Deduction Code';
            TableRelation = "Payroll Directory".Code WHERE(Type = CONST("Tax Deduction"));
        }
        field(19; Calculation; Boolean)
        {
            Caption = 'Calculation';
            Editable = false;
        }
        field(20; "Vendor Ledger Entry No."; Integer)
        {
            Caption = 'Vendor Ledger Entry No.';
            TableRelation = "Vendor Ledger Entry";
        }
        field(21; "Employee Ledger Entry No."; Integer)
        {
            Caption = 'Employee Ledger Entry No.';
            TableRelation = "Employee Ledger Entry";
        }
        field(22; Interim; Boolean)
        {
            Caption = 'Interim';
        }
        field(23; "Tax Deduction Amount"; Decimal)
        {
            Caption = 'Tax Deduction Amount';
        }
        field(24; "Advance Payment"; Boolean)
        {
            Caption = 'Advance Payment';
        }
        field(26; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(27; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
    }

    keys
    {
        key(Key1; "Person Income No.", "Person Income Line No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Entry Type", "Tax Code", "Tax %", Interim, "Advance Payment")
        {
            SumIndexFields = Base, Amount, "Tax Deduction Amount";
        }
        key(Key3; "Employee Ledger Entry No.")
        {
        }
        key(Key4; "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestField(Calculation, false);
    end;

    trigger OnModify()
    begin
        TestField(Calculation, false);
    end;

    trigger OnRename()
    begin
        Error('');
    end;
}

