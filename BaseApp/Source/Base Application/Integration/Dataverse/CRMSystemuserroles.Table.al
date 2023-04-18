table 5390 "CRM Systemuserroles"
{
    // Dynamics CRM Version: 9.1.0.1450

    Caption = 'CRM Systemuserroles';
    ExternalName = 'systemuserroles';
    TableType = CRM;

    fields
    {
        field(1; SystemUserId; Guid)
        {
            Caption = 'SystemUserId';
            DataClassification = SystemMetadata;
            ExternalAccess = Read;
            ExternalName = 'systemuserid';
            ExternalType = 'Uniqueidentifier';
        }
        field(2; RoleId; Guid)
        {
            Caption = 'RoleId';
            DataClassification = SystemMetadata;
            ExternalAccess = Read;
            ExternalName = 'roleid';
            ExternalType = 'Uniqueidentifier';
        }
        field(3; SystemUserRoleId; Guid)
        {
            Caption = 'SystemUserRoleId';
            DataClassification = SystemMetadata;
            Description = 'For internal use only.';
            ExternalAccess = Insert;
            ExternalName = 'systemuserroleid';
            ExternalType = 'Uniqueidentifier';
        }
        field(4; VersionNumber; BigInteger)
        {
            Caption = 'VersionNumber';
            DataClassification = SystemMetadata;
            ExternalAccess = Read;
            ExternalName = 'versionnumber';
            ExternalType = 'BigInt';
        }
    }

    keys
    {
        key(Key1; SystemUserRoleId)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

