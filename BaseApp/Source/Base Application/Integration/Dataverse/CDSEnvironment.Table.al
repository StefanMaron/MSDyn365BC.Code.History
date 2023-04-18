table 7202 "CDS Environment"
{
    Access = Internal;
    LookupPageId = "CDS Environments";

    fields
    {
        field(1; "API Url"; Text[120])
        {
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(2; "Environment Name"; Text[250])
        {
            DataClassification = OrganizationIdentifiableInformation;
        }

        field(3; Id; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(4; "Last Updated"; DateTime)
        {
            DataClassification = SystemMetadata;
        }
        field(5; State; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(6; "Unique Name"; Text[120])
        {
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(7; Url; Text[250])
        {
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(8; Version; Text[25])
        {
            DataClassification = SystemMetadata;
        }
        field(9; "Url Name"; Text[250])
        {
            DataClassification = OrganizationIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; "Unique Name")
        {
            Clustered = true;
        }
        key(Key2; "Environment Name")
        {
        }
    }
}
