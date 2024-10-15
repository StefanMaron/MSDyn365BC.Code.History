table 2850 "Native - API Tax Setup"
{
    Caption = 'Native - API Tax Setup';
    ReplicateData = false;
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
    ObsoleteReason = 'These objects will be removed';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Total Tax Percentage"; Decimal)
        {
            Caption = 'Total Tax Percentage';
        }
        field(10; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
        field(20; "VAT Percentage"; Decimal)
        {
            Caption = 'VAT Percentage';
        }
        field(21; "VAT Regulation Reference ID"; Guid)
        {
            Caption = 'VAT Regulation Reference ID';
        }
        field(22; "VAT Regulation Description"; Text[250])
        {
            Caption = 'VAT Regulation Description';
        }
        field(30; City; Text[30])
        {
            Caption = 'City';
        }
        field(31; "City Rate"; Decimal)
        {
            Caption = 'City Rate';

            trigger OnValidate()
            begin
                "Total Tax Percentage" := "City Rate" + "State Rate";
            end;
        }
        field(32; State; Code[2])
        {
            Caption = 'State';
        }
        field(33; "State Rate"; Decimal)
        {
            Caption = 'State Rate';

            trigger OnValidate()
            begin
                "Total Tax Percentage" := "City Rate" + "State Rate";
            end;
        }
        field(40; "GST or HST Code"; Code[10])
        {
            Caption = 'GST or HST Code';
        }
        field(41; "GST or HST Description"; Text[50])
        {
            Caption = 'GST or HST Description';
            Editable = false;
        }
        field(42; "GST or HST Rate"; Decimal)
        {
            Caption = 'GST or HST Rate';

            trigger OnValidate()
            begin
                "Total Tax Percentage" := "PST Rate" + "GST or HST Rate";
            end;
        }
        field(45; "PST Code"; Code[10])
        {
            Caption = 'PST Code';
        }
        field(46; "PST Description"; Text[50])
        {
            Caption = 'PST Description';
            Editable = false;
        }
        field(47; "PST Rate"; Decimal)
        {
            Caption = 'PST Rate';

            trigger OnValidate()
            begin
                "Total Tax Percentage" := "PST Rate" + "GST or HST Rate";
            end;
        }
        field(100; Default; Boolean)
        {
            Caption = 'Default';
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
        }
        field(9600; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Sales Tax,VAT', Locked = true;
            OptionMembers = "Sales Tax",VAT;
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}