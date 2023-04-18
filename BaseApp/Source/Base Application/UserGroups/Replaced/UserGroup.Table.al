table 9000 "User Group"
{
    Caption = 'User Group';
    DataPerCompany = false;
#if not CLEAN22
    LookupPageID = "User Groups";
#endif
    ReplicateData = false;
#if not CLEAN22
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '25.0';
#endif 
    ObsoleteReason = 'Replaced by the Security Group table and Security Group codeunit in the security groups system.';

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; "Default Profile ID"; Code[30])
        {
            Caption = 'Default Profile ID';
            TableRelation = "All Profile"."Profile ID";
        }
        field(4; "Assign to All New Users"; Boolean)
        {
            Caption = 'Assign to All New Users';

#if not CLEAN22
            trigger OnValidate()
            var
                UserGroup: Record "User Group";
                EnvironmentInfo: Codeunit "Environment Information";
            begin
                if not EnvironmentInfo.IsSaaS() then
                    exit;

                if "Assign to All New Users" = true then
                    exit;

                // When deselecting this option, if the last auto-assign user group is deselected,
                // it means that new users will get no permissions
                // and therefore they will not be able to login.
                UserGroup.SetRange("Assign to All New Users", true);
                UserGroup.SetFilter(Code, '<>%1', Code);
                if UserGroup.Count = 0 then
                    if not Confirm(NewUsersCannotLoginQst) then
                        Error('');
            end;
#endif
        }
        field(5; Customized; Boolean)
        {
            Caption = 'Customized';
            Editable = false;
        }
        field(6; "Default Profile App ID"; Guid)
        {
            Caption = 'Default Profile App ID';
        }
        field(7; "Default Profile Scope"; Option)
        {
            Caption = 'Default Profile Scope';
            OptionCaption = 'System,Tenant';
            OptionMembers = System,Tenant;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

#if not CLEAN22
    trigger OnDelete()
    var
        UserGroupMember: Record "User Group Member";
        UserGroupPlan: Record "User Group Plan";
    begin
        UserGroupMember.SetRange("User Group Code", Code);
        if not UserGroupMember.IsEmpty() then
            Error(HasMembersErr);

        UserGroupPlan.SetRange("User Group Code", Code);
        if not UserGroupPlan.IsEmpty() then
            Error(PartOfPlansErr);
    end;

    trigger OnInsert()
    begin
        TestField(Code);
        Customized := true;
    end;

    trigger OnModify()
    begin
        Customized := true;
    end;

    trigger OnRename()
    begin
        Customized := true;
    end;

    var
        HasMembersErr: Label 'You cannot delete this user group because it has members.';
        NewUsersCannotLoginQst: Label 'You have not specified a user group that will be assigned automatically to new users. If users are not assigned a user group, they cannot sign in. \\Do you want to continue?';
        PartOfPlansErr: Label 'You cannot delete this user group because it is part of one or more plans.';

    procedure IsUserMember(var User: Record User; SelectedCompany: Text[30]): Boolean
    var
        UserGroupMember: Record "User Group Member";
    begin
        UserGroupMember.SetRange("User Group Code", Code);
        UserGroupMember.SetRange("User Security ID", User."User Security ID");
        UserGroupMember.SetRange("Company Name", SelectedCompany);
        exit(not UserGroupMember.IsEmpty);
    end;

    procedure SetUserGroupMembership(var User: Record User; NewUserGroupMembership: Boolean; SelectedCompany: Text[30])
    var
        UserGroupMember: Record "User Group Member";
    begin
        if UserGroupMember.Get(Code, User."User Security ID", SelectedCompany) then begin
            if not NewUserGroupMembership then
                UserGroupMember.Delete(true);
            exit;
        end;
        if not NewUserGroupMembership then
            exit;
        UserGroupMember.Init();
        UserGroupMember."User Group Code" := Code;
        UserGroupMember."User Security ID" := User."User Security ID";
        UserGroupMember."Company Name" := SelectedCompany;
        UserGroupMember.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure ExportUserGroups(FileName: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        ExportImportUserGroups: XMLport "Export/Import User Groups";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        ExportImportUserGroups.SetTableView(Rec);
        ExportImportUserGroups.SetDestination(OutStr);
        ExportImportUserGroups.Export();
        if FileName = '' then
            exit(FileManagement.BLOBExport(TempBlob, TableCaption + '.xml', true));
        exit(FileManagement.BLOBExport(TempBlob, FileName, false));
    end;

    [Scope('OnPrem')]
    procedure ImportUserGroups(FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        ExportImportUserGroups: XMLport "Export/Import User Groups";
        InStr: InStream;
    begin
        if FileManagement.BLOBImport(TempBlob, FileName) = '' then
            exit;
        TempBlob.CreateInStream(InStr);
        ExportImportUserGroups.SetSource(InStr);
        ExportImportUserGroups.Import();
    end;
#endif
}

