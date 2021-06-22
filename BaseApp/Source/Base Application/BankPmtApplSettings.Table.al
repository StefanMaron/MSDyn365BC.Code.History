table 1253 "Bank Pmt. Appl. Settings"
{
    Caption = 'Bank Payment Application Settings';

    fields
    {
        field(1; PrimaryKey; Code[20])
        {
            DataClassification = SystemMetadata;
        }

        field(3; "Vendor Ledger Entries Matching"; Boolean)
        {
            DataClassification = SystemMetadata;
        }

        field(4; "Cust. Ledger Entries Matching"; Boolean)
        {
            DataClassification = SystemMetadata;
        }

        field(5; "Bank Ledger Entries Matching"; Boolean)
        {
            DataClassification = SystemMetadata;
        }

        field(6; "RelatedParty Name Matching"; Enum "Pmt. Appl. Related Party Name Matching")
        {
            DataClassification = SystemMetadata;
        }

        field(7; "Bank Ledg Closing Doc No Match"; boolean)
        {
            DataClassification = SystemMetadata;
        }

        field(8; "Apply Man. Disable Suggestions"; boolean)
        {
            DataClassification = SystemMetadata;
        }

        field(9; "Enable Apply Immediatelly"; boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(10; "Empl. Ledger Entries Matching"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; PrimaryKey)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure GetOrInsert()
    begin
        if Get('') then
            exit;

        "Vendor Ledger Entries Matching" := true;
        "Cust. Ledger Entries Matching" := true;
        "Bank Ledger Entries Matching" := true;
        "Empl. Ledger Entries Matching" := true;
        "Bank Ledg Closing Doc No Match" := false;
        Insert(true);
    end;
}

