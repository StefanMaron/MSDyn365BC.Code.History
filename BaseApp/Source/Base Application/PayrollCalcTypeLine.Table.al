table 17405 "Payroll Calc Type Line"
{
    Caption = 'Payroll Calc Type Line';
    LookupPageID = "Payroll Calc Type Lines";

    fields
    {
        field(1; "Calc Type Code"; Code[20])
        {
            Caption = 'Calc Type Code';
            NotBlank = true;
            TableRelation = "Payroll Calc Type";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            NotBlank = true;
            TableRelation = "Payroll Element";

            trigger OnValidate()
            begin
                PayrollElement.Get("Element Code");
                "Element Code" := PayrollElement.Code;
                Calculate := PayrollElement.Calculate;
                "Element Type" := PayrollElement.Type;
                "Element Name" := PayrollElement."Element Group";
                "Posting Type" := PayrollElement."Posting Type";
                "Payroll Posting Group" := PayrollElement."Payroll Posting Group";
            end;
        }
        field(4; Activity; Boolean)
        {
            Caption = 'Activity';
            InitValue = true;
        }
        field(5; "Payroll Posting Group"; Code[20])
        {
            Caption = 'Payroll Posting Group';
            TableRelation = "Payroll Posting Group";
        }
        field(11; Calculate; Boolean)
        {
            Caption = 'Calculate';
            Editable = false;
        }
        field(12; "Element Type"; Option)
        {
            Caption = 'Element Type';
            Editable = false;
            OptionCaption = 'Wage,Bonus,Income Tax,Netto Salary,Tax Deduction,Deduction,Other,Funds,Reporting';
            OptionMembers = Wage,Bonus,"Income Tax","Netto Salary","Tax Deduction",Deduction,Other,Funds,Reporting;
        }
        field(13; "Element Name"; Text[50])
        {
            Caption = 'Element Name';
            Editable = false;
        }
        field(17; "Posting Type"; Option)
        {
            Caption = 'Posting Type';
            Editable = false;
            OptionCaption = 'Not Post,Charge,Liability,Liability Charge,Information Only';
            OptionMembers = "Not Post",Charge,Liability,"Liability Charge","Information Only";
        }
    }

    keys
    {
        key(Key1; "Calc Type Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Element Code")
        {
        }
        key(Key3; "Calc Type Code", "Element Type", "Element Code")
        {
        }
    }

    fieldgroups
    {
    }

    var
        PayrollElement: Record "Payroll Element";
}

