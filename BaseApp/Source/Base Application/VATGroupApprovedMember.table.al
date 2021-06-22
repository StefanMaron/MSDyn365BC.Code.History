table 4800 "VATGroup Approved Member"
{
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to VAT Group Management extension table 4700 VAT Group Approved Member';
    ObsoleteTag = '18.0';

    fields
    {
        field(1; ID; Guid) { }
        field(2; "Group Member Name"; Text[250]) { }
        field(3; "Contact Person Name"; Text[250]) { }
        field(4; "Contact Person Email"; Text[250]) { }
        field(5; Company; Text[30]) { }
    }

    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
        key(GroupMemberName; "Group Member Name")
        {
        }
    }
}
