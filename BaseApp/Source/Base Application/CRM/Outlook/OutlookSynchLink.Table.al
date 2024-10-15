namespace Microsoft.CRM.Outlook;

table 5302 "Outlook Synch. Link"
{
    Caption = 'Outlook Synch. Link';
    DataClassification = CustomerContent;
    ReplicateData = false;
    ObsoleteState = Removed;
    ObsoleteReason = 'Legacy outlook sync functionality has been removed.';
    ObsoleteTag = '22.0';

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
        }
        field(2; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
        }
        field(3; "Outlook Entry ID"; BLOB)
        {
            Caption = 'Outlook Entry ID';
        }
        field(4; "Outlook Entry ID Hash"; Text[32])
        {
            Caption = 'Outlook Entry ID Hash';
        }
        field(5; "Search Record ID"; Code[250])
        {
            Caption = 'Search Record ID';
        }
        field(6; "Synchronization Date"; DateTime)
        {
            Caption = 'Synchronization Date';
        }
    }

    keys
    {
        key(Key1; "User ID", "Record ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
