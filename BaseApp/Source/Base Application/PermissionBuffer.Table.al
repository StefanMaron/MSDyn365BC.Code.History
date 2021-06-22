table 9852 "Permission Buffer"
{
    Caption = 'Permission Buffer';
    DataPerCompany = false;
    ReplicateData = false;

    fields
    {
        field(1; Source; Option)
        {
            Caption = 'Source';
            DataClassification = SystemMetadata;
            OptionCaption = 'Normal,Entitlement';
            OptionMembers = Normal,Entitlement;
        }
        field(2; "Permission Set"; Code[20])
        {
            Caption = 'Permission Set';
            DataClassification = SystemMetadata;
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'User-Defined,Extension,System';
            OptionMembers = "User-Defined",Extension,System;
        }
        field(4; "Read Permission"; Option)
        {
            Caption = 'Read Permission';
            DataClassification = SystemMetadata;
            InitValue = Yes;
            OptionCaption = ' ,Yes,Indirect';
            OptionMembers = " ",Yes,Indirect;
        }
        field(5; "Insert Permission"; Option)
        {
            Caption = 'Insert Permission';
            DataClassification = SystemMetadata;
            InitValue = Yes;
            OptionCaption = ' ,Yes,Indirect';
            OptionMembers = " ",Yes,Indirect;
        }
        field(6; "Modify Permission"; Option)
        {
            Caption = 'Modify Permission';
            DataClassification = SystemMetadata;
            InitValue = Yes;
            OptionCaption = ' ,Yes,Indirect';
            OptionMembers = " ",Yes,Indirect;
        }
        field(7; "Delete Permission"; Option)
        {
            Caption = 'Delete Permission';
            DataClassification = SystemMetadata;
            InitValue = Yes;
            OptionCaption = ' ,Yes,Indirect';
            OptionMembers = " ",Yes,Indirect;
        }
        field(8; "Execute Permission"; Option)
        {
            Caption = 'Execute Permission';
            DataClassification = SystemMetadata;
            InitValue = Yes;
            OptionCaption = ' ,Yes,Indirect';
            OptionMembers = " ",Yes,Indirect;
        }
        field(9; "App ID"; Guid)
        {
            Caption = 'App ID';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Type, "Permission Set")
        {
            Clustered = true;
        }
        key(Key2; Source)
        {
        }
    }

    fieldgroups
    {
    }

    local procedure GetScope(): Integer
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        case Type of
            Type::System:
                exit(AggregatePermissionSet.Scope::System);
            Type::"User-Defined",
          Type::Extension:
                exit(AggregatePermissionSet.Scope::Tenant);
        end;
    end;

    procedure GetAppID(): Guid
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        Scope: Integer;
        ZeroGuid: Guid;
    begin
        Scope := GetScope;
        if Type <> Type::Extension then
            exit(ZeroGuid);

        AggregatePermissionSet.SetRange(Scope, Scope);
        AggregatePermissionSet.SetRange("Role ID", "Permission Set");
        AggregatePermissionSet.FindFirst;
        exit(AggregatePermissionSet."App ID");
    end;

    procedure OpenPermissionsPage(RunAsModal: Boolean)
    var
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
    begin
        PermissionPagesMgt.ShowPermissions(GetScope, GetAppID, "Permission Set", RunAsModal)
    end;
}

