codeunit 132216 "Library - Permissions Verify"
{

    trigger OnRun()
    begin
    end;

    var
#if not CLEAN22
        UserGroupIsNotInPlanErr: Label 'User group %1 is not in plan %2.', Comment = '%1=user group,%2=plan name,%3=company name';
        UserGroupIsInPlanErr: Label 'User group %1 should not be part of plan %2.', Comment = '%1=user group,%2=plan name,%3=company name';
        UserIsNotInUserGroupErr: Label 'User %1 is not in user group %2, for company %3.', Comment = '%1=user name,%2=user group name, %3=company name';
        UserShouldNotBeInUserGroupErr: Label 'User %1 should not be part of user group %2, for company %3.', Comment = '%1=user name,%2=user group name, %3=company name';
        UserGroupDoesNotExistErr: Label 'User Group %1 does not exist.', Comment = '%1=user group name';
        UserGroupAccessControlErr: Label 'User Group Access Control still contains records related to user %1 and user group %2, for company %3.', Comment = '%1=user name, %2=user group code, %3=company name';
        UserGroupAccessControlMissingErr: Label 'User Group Access Control is missing records related to user %1 and user group %2, for company %3.', Comment = '%1=user name, %2=user group code, %3=company name';
        UserGroupMemberFoundErr: Label 'Found at least one record in table User Group Member, related to User Group %1.', Comment = '%1=user group code';
        UserGroupPermissionSetFoundErr: Label 'Found at least one record in table User Group Permission Set, related to User Group %1.', Comment = '%1=user group code';
        UserGroupPermissionSetDoesNotExistErr: Label 'User group %1 does not contain permission set %2.', Comment = '%1=user group code,%2=permission set code';
        UserGroupPlanFoundErr: Label 'Found at least one record in table User Group Plan, related to User Group %1.', Comment = '%1=user group code';
#endif
        UserIsNotInPlanErr: Label 'User %1 is not in plan %2.', Comment = '%1=user name,%2=plan name';
        UserShouldNotBeInPlanErr: Label 'User %1 should not be part of plan %2.', Comment = '%1=user name,%2=plan name';
        PlanDoesNotExistErr: Label 'Plan with GUID %1 does not exist.', Comment = '%1=subscription plan ID';
        UserDoesNotExistErr: Label 'User with GUID %1 does not exist.', Comment = '%1=User ID';
        UserDoesNotHavePermissionSetErr: Label 'User %1 does not have permission set %2 in company %3.', Comment = '%1=user name, %2=permission set code, %3 = company name.';
        MissingPermissionErr: Label 'You do not have %1  permissions on TableData %2.';
        SupplementalPermissionErr: Label 'Supplemental permissions %1 given on TableData %2.';
        Assert: Codeunit Assert;

#if not CLEAN22
    procedure UserGroupAccessControlDoesNotContain(UserID: Guid; UserGroupCode: Code[20])
    var
        UserGroupAccessControl: Record "User Group Access Control";
        User: Record User;
    begin
        GetUser(User, UserID);
        UserGroupAccessControl.SetRange("User Security ID", UserID);
        UserGroupAccessControl.SetRange("User Group Code", UserGroupCode);
        UserGroupAccessControl.SetRange("Company Name", CompanyName);
        if UserGroupAccessControl.FindFirst() then
            Error(UserGroupAccessControlErr, User."Full Name", UserGroupCode, CompanyName);
    end;

    procedure UserGroupAccessControlContains(UserID: Guid; UserGroupCode: Code[20])
    var
        UserGroupAccessControl: Record "User Group Access Control";
        User: Record User;
    begin
        GetUser(User, UserID);
        UserGroupAccessControl.SetRange("User Security ID", UserID);
        UserGroupAccessControl.SetRange("User Group Code", UserGroupCode);
        UserGroupAccessControl.SetRange("Company Name", CompanyName);
        if not UserGroupAccessControl.FindFirst() then
            Error(UserGroupAccessControlMissingErr, User."Full Name", UserGroupCode, CompanyName);
    end;

    procedure UserGroupIsInPlan(UserGroupCode: Code[20]; PlanID: Guid)
    var
        UserGroupPlan: Record "User Group Plan";
        AzureAdPlan: Codeunit "Azure AD Plan";
    begin
        VerifyUserGroupExists(UserGroupCode);

        if not AzureAdPlan.DoesPlanExist(PlanID) then
            Error(PlanDoesNotExistErr, PlanID);

        if not UserGroupPlan.Get(PlanID, UserGroupCode) then
            Error(UserGroupIsNotInPlanErr, UserGroupCode, PlanID);
    end;

    procedure UserGroupMembersDoNotExist(UserGroupCode: Code[30])
    var
        UserGroupMember: Record "User Group Member";
    begin
        UserGroupMember.SetRange("User Group Code", UserGroupCode);
        UserGroupMember.SetRange("Company Name", CompanyName);
        if UserGroupMember.FindFirst() then
            Error(UserGroupMemberFoundErr, UserGroupCode);
    end;

    procedure UserGroupPermissionSetExists(UserGroupCode: Code[30]; PermissionSetCode: Code[20])
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        UserGroupPermissionSet.SetRange("User Group Code", UserGroupCode);
        UserGroupPermissionSet.SetRange("Role ID", PermissionSetCode);
        if not UserGroupPermissionSet.FindFirst() then
            Error(UserGroupPermissionSetDoesNotExistErr, UserGroupCode, PermissionSetCode);
    end;

    procedure UserGroupPermissionSetsDoNotExist(UserGroupCode: Code[30])
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        UserGroupPermissionSet.SetRange("User Group Code", UserGroupCode);
        if UserGroupPermissionSet.FindFirst() then
            Error(UserGroupPermissionSetFoundErr, UserGroupCode);
    end;

    procedure UserGroupPlansDoNotExist(UserGroupCode: Code[30])
    var
        UserGroupPlan: Record "User Group Plan";
    begin
        UserGroupPlan.SetRange("User Group Code", UserGroupCode);
        if UserGroupPlan.FindFirst() then
            Error(UserGroupPlanFoundErr, UserGroupCode);
    end;
#endif

    procedure UserHasPermissionSet(UserID: Guid; PermissionSetCode: Code[20])
    begin
        UserHasPermissionSetInCompany(UserID, PermissionSetCode, CompanyName);
    end;

    procedure UserHasPermissionSetInCompany(UserID: Guid; PermissionSetCode: Code[20]; Company: Text[30])
    var
        AccessControl: Record "Access Control";
        User: Record User;
    begin
        User.Get(UserID);
        AccessControl.SetRange("User Security ID", UserID);
        AccessControl.SetRange("Role ID", PermissionSetCode);
        AccessControl.SetRange("Company Name", Company);
        if not AccessControl.FindFirst() then
            Error(UserDoesNotHavePermissionSetErr, User."Full Name", PermissionSetCode, Company);
    end;

#if not CLEAN22
    procedure UserIsInUserGroup(UserID: Guid; UserGroupCode: Code[20])
    var
        UserGroupMember: Record "User Group Member";
        User: Record User;
    begin
        VerifyUserGroupExists(UserGroupCode);
        GetUser(User, UserID);
        if not UserGroupMember.Get(UserGroupCode, UserID, CompanyName) then
            Error(UserIsNotInUserGroupErr, User."User Name", UserGroupCode, CompanyName);
    end;

    procedure UserIsNotInUserGroup(UserID: Guid; UserGroupCode: Code[20])
    var
        UserGroupMember: Record "User Group Member";
        User: Record User;
    begin
        VerifyUserGroupExists(UserGroupCode);
        GetUser(User, UserID);
        if UserGroupMember.Get(UserGroupCode, UserID, CompanyName) then
            Error(UserShouldNotBeInUserGroupErr, User."User Name", UserGroupCode, CompanyName);
    end;

    local procedure VerifyUserGroupExists(UserGroupCode: Code[20])
    var
        UserGroup: Record "User Group";
    begin
        if not UserGroup.Get(UserGroupCode) then
            Error(UserGroupDoesNotExistErr, UserGroupCode);
    end;

    local procedure GetUser(var User: Record User; UserID: Guid)
    begin
        if not User.Get(UserID) then
            Error(UserDoesNotExistErr, UserID);
    end;
#endif

    procedure CreateRecWithRelatedFields(RecordRef: RecordRef)
    var
        TableRelationsMetadata: Record "Table Relations Metadata";
        RecordId: RecordID;
        RelatedRecordRef: RecordRef;
        RelatedRecordId: RecordID;
    begin
        RecordRef.Init();
        RecordRef.Insert(true);

        RecordId := RecordRef.RecordId;
        TableRelationsMetadata.SetRange("Table ID", RecordId.TableNo);
        TableRelationsMetadata.SetFilter("Field No.", '<>%1&<>%2',
            TableRelationsMetadata.FieldNo(SystemCreatedBy),
            TableRelationsMetadata.FieldNo(SystemModifiedBy));

        TableRelationsMetadata.FindSet();
        repeat
            RelatedRecordRef.Open(TableRelationsMetadata."Related Table ID");
            RelatedRecordId := RelatedRecordRef.RecordId;
            if RelatedRecordId.TableNo <> RecordId.TableNo then begin
                RelatedRecordRef.DeleteAll();
                RelatedRecordRef.Init();
                RelatedRecordRef.Insert();
            end;
            RelatedRecordRef.Close();
        until TableRelationsMetadata.Next() = 0;

        RecordRef.Close();
        Commit();
    end;

    [Scope('OnPrem')]
    procedure CheckReadAccessToRelatedTables(var ExcludedTables: DotNet GenericList1; RecordRef: RecordRef)
    var
        TableRelationsMetadata: Record "Table Relations Metadata";
        RelatedRecordRef: RecordRef;
        RelatedRecordId: RecordID;
        RecordId: RecordID;
    begin
        TableRelationsMetadata.Init();
        RecordId := RecordRef.RecordId;
        TableRelationsMetadata.SetRange("Table ID", RecordId.TableNo);
        TableRelationsMetadata.SetFilter("Field No.", '<>%1&<>%2',
            TableRelationsMetadata.FieldNo(SystemCreatedBy),
            TableRelationsMetadata.FieldNo(SystemModifiedBy));
        if TableRelationsMetadata.FindSet() then
            repeat
                RelatedRecordRef.Open(TableRelationsMetadata."Related Table ID");
                RelatedRecordId := RelatedRecordRef.RecordId;
                if not ExcludedTables.Contains(RelatedRecordId.TableNo) then
                    VerifyReadPermissionTrue(RelatedRecordRef.Number);
                RelatedRecordRef.Close();
            until TableRelationsMetadata.Next() = 0;
    end;

    procedure VerifyReadPermissionTrue(TableNo: Integer)
    var
        RecordRef: RecordRef;
    begin
        RecordRef.Open(TableNo);
        RecordRef.FindFirst();
        Assert.IsTrue(RecordRef.ReadPermission, StrSubstNo(MissingPermissionErr, 'Read', Format(RecordRef.Caption)));
    end;

    procedure VerifyReadPermissionFalse(TableNo: Integer)
    var
        RecordRef: RecordRef;
    begin
        RecordRef.Open(TableNo);
        asserterror RecordRef.FindFirst();
        Assert.ExpectedError(StrSubstNo(MissingPermissionErr, Format(RecordRef.Caption)))
    end;

    procedure VerifyWritePermissionTrue(RecordRef: RecordRef)
    begin
        RecordRef.Init();
        RecordRef.Insert(true);
        RecordRef.Delete(true);
    end;

    procedure VerifyWritePermissionFalse(RecordRef: RecordRef)
    begin
        RecordRef.Init();

        asserterror RecordRef.Insert(true);
        Assert.IsFalse(RecordRef.WritePermission, StrSubstNo(SupplementalPermissionErr, 'Insert', Format(RecordRef.Caption)));

        asserterror RecordRef.Delete(true);
        Assert.IsFalse(RecordRef.WritePermission, StrSubstNo(SupplementalPermissionErr, 'Delete', Format(RecordRef.Caption)));
    end;
}

