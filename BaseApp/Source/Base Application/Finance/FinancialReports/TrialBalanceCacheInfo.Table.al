namespace Microsoft.Finance.FinancialReports;

table 1317 "Trial Balance Cache Info"
{
    Caption = 'Trial Balance Cache Info';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Last Modified Date/Time"; DateTime)
        {
            Caption = 'Last Modified Date/Time';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

