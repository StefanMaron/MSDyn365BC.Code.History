#if not CLEAN19
codeunit 889 "SmartList Designer Impl"
{
    Access = Internal;
    ObsoleteState = Pending;
    ObsoleteReason = 'The SmartList Designer is not supported in Business Central.';
    ObsoleteTag = '19.0';

    [TryFunction]
    procedure DoesUserHaveAPIAccess(UserSID: Guid)
    var
        TempPermission: Record "Permission" temporary;
        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
        TempCompanyName: Text[50];
    begin
        TempCompanyName := CopyStr(CompanyName(), 1, MaxStrLen(TempCompanyName)); // Necessary to avoid AA0139 - Possible overflow
        EffectivePermissionsMgt.PopulateEffectivePermissionsBuffer(
            TempPermission,
            UserSID,
            TempCompanyName,
            TempPermission."Object Type"::System,
            9600, // Id of the 'SmartListDesignerApi' system object
            false);

        if not (TempPermission."Execute Permission" = TempPermission."Execute Permission"::Yes) then
            Error(UserDoesNotHaveAccessErr);
    end;

    procedure RunForNew()
    var
        SmartListDesignerPage: Page "SmartList Designer";
    begin
        AssertEnabled();
        SmartListDesignerPage.Run();
    end;

    procedure RunForQuery(QueryId: Guid)
    var
        SmartListDesignerPage: Page "SmartList Designer";
    begin
        AssertEnabled();
        SmartListDesignerPage.RunForEditExistingQuery(Format(QueryId, 36, 4).Trim());
    end;

    procedure RunForTable(TableNo: Integer; ViewId: Text)
    var
        SmartListDesignerPage: Page "SmartList Designer";
    begin
        AssertEnabled();
        SmartListDesignerPage.RunForNewQueryOverTableAndView(TableNo, ViewId);
    end;

    local procedure AssertEnabled()
    begin
        if not IsDesignerEnabled() then
            Error(SmartListIsDisabledErr);
    end;

    procedure IsDesignerEnabled(): Boolean
    begin
        exit(false); // Disabled until the full experience is shipped (see #372652)
    end;

    var
        SmartListIsDisabledErr: Label 'The SmartList Designer is not enabled.';
        UserDoesNotHaveAccessErr: Label 'The user does not have permission to access the SmartList Designer.';
}
#endif