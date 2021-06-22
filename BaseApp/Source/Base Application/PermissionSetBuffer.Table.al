table 9009 "Permission Set Buffer"
{
    Caption = 'Permission Set Buffer';
    DataPerCompany = false;
    ReplicateData = false;

    fields
    {
        field(1; Scope; Option)
        {
            Caption = 'Scope';
            DataClassification = SystemMetadata;
            OptionCaption = 'System,Tenant';
            OptionMembers = System,Tenant;
        }
        field(2; "App ID"; Guid)
        {
            Caption = 'App ID';
            DataClassification = SystemMetadata;
        }
        field(3; "Role ID"; Code[20])
        {
            Caption = 'Role ID';
            DataClassification = SystemMetadata;
        }
        field(4; Name; Text[30])
        {
            Caption = 'Name';
            DataClassification = SystemMetadata;
        }
        field(5; "App Name"; Text[250])
        {
            Caption = 'App Name';
            DataClassification = SystemMetadata;
        }
        field(6; Type; Option)
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'User-Defined,Extension,System';
            OptionMembers = "User-Defined",Extension,System;
        }
    }

    keys
    {
        key(Key1; Type, "Role ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        IsTempErr: Label '%1 should only be used as a temporary record.', Comment = '%1 table caption';

    procedure SetType()
    begin
        Type := GetType(Scope, "App ID");
    end;

    procedure GetType(ScopeOpt: Option; AppID: Guid): Integer
    begin
        case true of
            (ScopeOpt = Scope::Tenant) and IsNullGuid(AppID):
                exit(Type::"User-Defined");
            ScopeOpt = Scope::Tenant:
                exit(Type::Extension);
            else
                exit(Type::System);
        end;
    end;

    procedure FillRecordBuffer()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSetBuffer: Record "Permission Set Buffer";
    begin
        if not IsTemporary then
            Error(IsTempErr, TableCaption);

        PermissionSetBuffer.CopyFilters(Rec);
        Reset();
        DeleteAll();

        if AggregatePermissionSet.FindSet then
            repeat
                // do not show permission sets for hidden extensions
                if StrPos(UpperCase(AggregatePermissionSet."App Name"), UpperCase('_Exclude_')) <> 1 then begin
                    Init;
                    "App ID" := AggregatePermissionSet."App ID";
                    "Role ID" := AggregatePermissionSet."Role ID";
                    Name := AggregatePermissionSet.Name;
                    "App Name" := AggregatePermissionSet."App Name";
                    Scope := AggregatePermissionSet.Scope;
                    SetType;
                    Insert;
                end;
            until AggregatePermissionSet.Next = 0;

        CopyFilters(PermissionSetBuffer);
    end;

    [Scope('OnPrem')]
    procedure RenameTenantPermissionSet()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
    begin
        if xRec."Role ID" = '' then
            exit;
        if xRec."Role ID" = "Role ID" then
            exit;
        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers;
        if Type = Type::"User-Defined" then begin
            TenantPermissionSet.Get(xRec."App ID", xRec."Role ID");
            TenantPermissionSet.Rename(xRec."App ID", "Role ID");
        end;
    end;
}

