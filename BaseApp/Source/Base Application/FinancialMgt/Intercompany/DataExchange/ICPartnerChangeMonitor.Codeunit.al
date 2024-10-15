namespace Microsoft.Intercompany.DataExchange;

using System.Security.User;
using System.Security.AccessControl;
using Microsoft.Intercompany.Partner;

codeunit 489 "IC Partner Change Monitor"
{
    [EventSubscriber(ObjectType::Table, Database::"IC Partner", 'OnBeforeInsertEvent', '', false, false)]
    local procedure CheckPermissionsBeforeInsert(RunTrigger: Boolean; var Rec: Record "IC Partner")
    begin
        if HasSensitiveFieldsSet(Rec) then
            CheckHasPermissionsToChangeSensitiveFields();
    end;

    [EventSubscriber(ObjectType::Table, Database::"IC Partner", 'OnBeforeModifyEvent', '', false, false)]
    local procedure CheckPermissionsOnBeforeModifyEvent(RunTrigger: Boolean; var Rec: Record "IC Partner"; var xRec: Record "IC Partner")
    begin
        if HasSensitiveFieldsSet(Rec) then
            CheckHasPermissionsToChangeSensitiveFields();

        if HasSensitiveFieldsSet(xRec) then
            CheckHasPermissionsToChangeSensitiveFields();

        if not xRec.IsTemporary() then
            if xRec.Find() then;

        if HasSensitiveFieldsSet(xRec) then
            CheckHasPermissionsToChangeSensitiveFields();
    end;

    [EventSubscriber(ObjectType::Table, Database::"IC Partner", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure CheckPermissionsOnBeforeDeleteEvent(RunTrigger: Boolean; var Rec: Record "IC Partner")
    begin
        if HasSensitiveFieldsSet(Rec) then
            CheckHasPermissionsToChangeSensitiveFields();
    end;

    [EventSubscriber(ObjectType::Table, Database::"IC Partner", 'OnBeforeRenameEvent', '', false, false)]
    local procedure CheckPermissionsOnBeforeRenameEvent(RunTrigger: Boolean; var Rec: Record "IC Partner")
    begin
        if HasSensitiveFieldsSet(Rec) then
            CheckHasPermissionsToChangeSensitiveFields();
    end;

    local procedure HasSensitiveFieldsSet(var ICPartner: Record "IC Partner"): Boolean
    var
        SensitiveFieldsUsed: Boolean;
    begin
        SensitiveFieldsUsed := not (IsNullGuid(ICPartner."Token Endpoint Key") and
                                    IsNullGuid(ICPartner."Token Key") and
                                    IsNullGuid(ICPartner."Redirect Url key") and
                                    IsNullGuid(ICPartner."Client Secret Key") and
                                    IsNullGuid(ICPartner."Client Id Key") and
                                    IsNullGuid(ICPartner."Company Id Key") and
                                    IsNullGuid(ICPartner."Connection Url Key"));
        exit(SensitiveFieldsUsed);
    end;

    internal procedure CheckHasPermissionsToChangeSensitiveFields()
    var
        DummyAccessControl: Record "Access Control";
        UserPermissions: Codeunit "User Permissions";
        CurrentModuleInfo: ModuleInfo;
    begin
        if UserPermissions.IsSuper(UserSecurityId()) then
            exit;

        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        if not UserPermissions.HasUserPermissionSetAssigned(UserSecurityId(), CompanyName(), ICCompanySetupPermissionSetNameTxt, DummyAccessControl.Scope::System, CurrentModuleInfo.Id) then
            Error(YouMustHaveICPartnerEditPermissionToChangeSensitiveFieldsErr, ICCompanySetupPermissionSetNameTxt);
    end;

    var
        YouMustHaveICPartnerEditPermissionToChangeSensitiveFieldsErr: Label 'To modify sensitive Cross-Environment Setup values, you must be assigned the %1 or SUPER permission set.', Comment = '%1 - Name of permission set';
        ICCompanySetupPermissionSetNameTxt: Label 'D365 IC Partner Edit';
}