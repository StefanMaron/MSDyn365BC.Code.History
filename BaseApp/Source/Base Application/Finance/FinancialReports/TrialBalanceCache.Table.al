namespace Microsoft.Finance.FinancialReports;

table 1318 "Trial Balance Cache"
{
    Caption = 'Trial Balance Cache';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = AccountData;
        }
        field(3; "Period 1 Amount"; Decimal)
        {
            Caption = 'Period 1 Amount';
            DataClassification = AccountData;
        }
        field(4; "Period 2 Amount"; Decimal)
        {
            Caption = 'Period 2 Amount';
            DataClassification = AccountData;
        }
        field(5; "Period 1 Caption"; Text[50])
        {
            Caption = 'Period 1 Caption';
        }
        field(6; "Period 2 Caption"; Text[50])
        {
            Caption = 'Period 2 Caption';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

