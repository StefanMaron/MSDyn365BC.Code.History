namespace Microsoft.CRM.Outlook;

table 5306 "Outlook Synch. Lookup Name"
{
    Caption = 'Outlook Synch. Lookup Name';
    DataClassification = CustomerContent;
    ReplicateData = false;
    ObsoleteState = Removed;
    ObsoleteReason = 'Legacy outlook sync functionality has been removed.';
    ObsoleteTag = '22.0';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            Editable = false;
        }
        field(2; Name; Text[80])
        {
            Caption = 'Name';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; Name)
        {
        }
    }

    fieldgroups
    {
    }
}
