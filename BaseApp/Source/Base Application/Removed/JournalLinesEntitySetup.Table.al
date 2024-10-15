table 5479 "Journal Lines Entity Setup"
{
    Caption = 'Journal Lines Entity Setup';
    ObsoleteReason = 'Became obsolete after refactoring of the NAV APIs.';
    ObsoleteState = Removed;
    ObsoleteTag = '18.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Default Journal Batch Name"; Code[10])
        {
            Caption = 'Default Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = const('GENERAL'));
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

