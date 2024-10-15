namespace Microsoft.Integration.Dataverse;

table 5399 "CDS System User Profiles"
{
    ExternalName = 'systemuserprofiles';
    TableType = CRM;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; SystemUserId; GUID)
        {
            ExternalName = 'systemuserid';
            ExternalType = 'Uniqueidentifier';
            ExternalAccess = Read;
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(2; FieldSecurityProfileId; GUID)
        {
            ExternalName = 'fieldsecurityprofileid';
            ExternalType = 'Uniqueidentifier';
            ExternalAccess = Read;
            DataClassification = SystemMetadata;
        }
        field(3; SystemUserProfileId; GUID)
        {
            ExternalName = 'systemuserprofileid';
            ExternalType = 'Uniqueidentifier';
            ExternalAccess = Insert;
            Description = 'For internal use only.';
            DataClassification = SystemMetadata;
        }
        field(4; VersionNumber; BigInteger)
        {
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
            ExternalAccess = Read;
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(PK; SystemUserProfileId)
        {
            Clustered = true;
        }
    }
}