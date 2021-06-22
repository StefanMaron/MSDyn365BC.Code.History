table 4801 "VATGroup Calculation"
{
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to VAT Group Management extension table 4701 VAT Group Calculation';
    ObsoleteTag = '18.0';

    fields
    {
        field(1; ID; Guid) { }
        field(2; "VAT Group Submission No."; Code[20]) { }
        field(3; "VAT Group Submission ID"; Guid) { }
        field(4; "VAT Report No."; Code[20]) { }
        field(5; "Group Member Name"; Text[250]) { }
        field(6; "Box No."; Text[30]) { }
        field(7; Amount; Decimal) { }
        field(8; "Submitted On"; DateTime) { }
    }

    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
    }
}
