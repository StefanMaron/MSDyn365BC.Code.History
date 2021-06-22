codeunit 889 "SmartList Designer Impl"
{
    Access = Internal;

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

    local procedure CanHandleSmartListEvents(): Boolean
    var
        SmartListDesignerHandlerRec: Record "SmartList Designer Handler";
        OurAppInfo: ModuleInfo;
        TempInfo: ModuleInfo;
    begin
        NAVApp.GetCurrentModuleInfo(OurAppInfo);

        // No handler record exists, insert ourselves as the handler
        if not SmartListDesignerHandlerRec.Get() then begin
            SmartListDesignerHandlerRec.Init();
            SmartListDesignerHandlerRec.HandlerExtensionId := OurAppInfo.Id();
            SmartListDesignerHandlerRec.Insert();
        end else // The extension in the handler record is no longer installed, change it to ourselves
            if not NAVApp.GetModuleInfo(SmartListDesignerHandlerRec.HandlerExtensionId, TempInfo) then begin
                SmartListDesignerHandlerRec.HandlerExtensionId := OurAppInfo.Id();
                SmartListDesignerHandlerRec.Modify();
            end;

        exit(SmartListDesignerHandlerRec.HandlerExtensionId = OurAppInfo.Id());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SmartList Designer Subscribers", 'OnBeforeDefaultGetEnabled', '', false, false)]
    local procedure OnBeforeDefaultGetEnabled(var Handled: Boolean; var Enabled: Boolean)
    begin
        if Handled then
            exit;

        if not CanHandleSmartListEvents() then
            exit;

        Handled := true;
        Enabled := IsDesignerEnabled();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SmartList Designer Subscribers", 'OnBeforeDefaultCreateNewForTableAndView', '', false, false)]
    local procedure OnBeforeDefaultCreateNewForTableAndView(var Handled: Boolean; TableId: Integer; ViewId: Text)
    begin
        if Handled then
            exit;

        if not CanHandleSmartListEvents() then
            exit;

        if IsDesignerEnabled() then begin
            Handled := true;
            RunForTable(TableId, ViewId);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SmartList Designer Subscribers", 'OnBeforeDefaultOnEditQuery', '', false, false)]
    local procedure OnBeforeDefaultOnEditQuery(var Handled: Boolean; QueryId: Text)
    var
        parsedId: Guid;
    begin
        if Handled then
            exit;

        if not CanHandleSmartListEvents() then
            exit;

        if IsDesignerEnabled() and EVALUATE(parsedId, QueryId) then begin
            Handled := true;
            RunForQuery(parsedId);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SmartList Designer Subscribers", 'OnBeforeDefaultOnInvalidQueryNavigation', '', false, false)]
    local procedure OnBeforeDefaultOnInvalidQueryNavigation(var Handled: Boolean; Id: BigInteger);
    var
        NavigationRec: Record "Query Navigation";
        Builder: Page "Query Navigation Builder";
    begin
        if Handled then
            exit;

        if not CanHandleSmartListEvents() then
            exit;

        Handled := true;

        if Confirm(InvalidActionConfirmationTxt) then begin
            NavigationRec.SetRange(Id, Id);
            NavigationRec.FindFirst();

            Builder.OpenForEditingExistingNavigation(NavigationRec);
        end;
    end;

    var
        SmartListIsDisabledErr: Label 'The SmartList Designer is not enabled.';
        UserDoesNotHaveAccessErr: Label 'The user does not have permission to access the SmartList Designer.';
        InvalidActionConfirmationTxt: Label 'The Navigation action is no longer valid. Would you like to edit the Navigation to fix the issue?';
}