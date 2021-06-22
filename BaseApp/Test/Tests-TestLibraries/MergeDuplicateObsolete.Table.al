table 134400 "Merge Duplicate Obsolete"
{
    ObsoleteState = Removed;
    ObsoleteReason = 'verify if Merge Duplicate function skips obsolete tables';

    fields
    {
        field(1; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
    }

    keys
    {
        key(Key1; "Customer No.")
        {
            Clustered = true;
        }
    }

}