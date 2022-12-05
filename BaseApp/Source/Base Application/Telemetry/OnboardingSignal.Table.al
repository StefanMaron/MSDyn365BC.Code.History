table 5490 "Onboarding Signal"
{
    Access = Internal;
    Extensible = false;
    DataClassification = OrganizationIdentifiableInformation;
    DataPerCompany = false;
    ReplicateData = false;
    Scope = Cloud;
    Description = 'Company table is not extensible. We also want to separate the logic in case we want to do the same for User for example.';

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'Used as primary key';
            AutoIncrement = true;
        }
        field(2; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            Description = 'Should be unique for now.';
        }
        field(3; "Onboarding Completed"; Boolean)
        {
            Caption = 'Whether a company has onboarded or not';
        }
    }

    keys
    {
        key(key1; "No.")
        {
        }
    }
}