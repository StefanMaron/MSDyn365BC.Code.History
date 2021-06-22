/// <summary>
/// Executes logic when to show the whats new notifier page.
/// </summary>
codeunit 897 "What's New Notifier"
{
    Access = Internal;
    Permissions = TableData "What's New Notified" = rimd;
    ObsoleteState = Pending;
    ObsoleteReason = 'Temporary solution';
    ObsoleteTag = '16.0';

    trigger OnRun()
    var
        Company: Record Company;
        WhatsNewNotified: Record "What's New Notified";
        EnvironmentInfo: Codeunit "Environment Information";
        ClientTypeMgt: Codeunit "Client Type Management";
        AppVersion: Text;
    begin
        // Saas only
        if not EnvironmentInfo.IsSaaS() then
            exit;

        // The user does not have the required table permissions  
        if not (WhatsNewNotified.ReadPermission() and WhatsNewNotified.WritePermission()) then begin
            SendTraceTag('0000BKI', 'What''s New Notifier', Verbosity::Warning, 'User has insufficient permissions! Cannot show what''s new wizard.', DataClassification::SystemMetadata);
            exit;
        end;

        // Web clients session only
        if ClientTypeMgt.GetCurrentClientType() <> ClientType::Web then
            exit;

        // Cannot show page
        if not IsGuiAllowed() then
            exit;

        // Only prod tenants
        if EnvironmentInfo.IsSandbox() then
            exit;

        // Non-evaluation companies
        if Company.Get(CompanyName()) and Company."Evaluation Company" then
            exit;

        if not GetAppMajorVersion(AppVersion) then begin
            SendTraceTag('0000BKD', 'What''s New Notifier', Verbosity::Warning, 'Something''s wrong with the version! Cannot show what''s new wizard.', DataClassification::SystemMetadata);
            exit;
        end;

        // Only for major version 16
        if AppVersion <> '16' then
            exit;

        // Notified before
        if WhatsNewNotified.Get(UserSecurityId(), AppVersion) then
            exit;

        Commit();

        Page.RunModal(Page::"What's New Wizard");

        MarkWhatsNewAsNotified(AppVersion);
    end;

    local procedure MarkWhatsNewAsNotified(ApplicationVersion: Text)
    var
        WhatsNewNotified: Record "What's New Notified";
    begin
        WhatsNewNotified."User Security ID" := UserSecurityId();
        WhatsNewNotified."Application Version" := CopyStr(ApplicationVersion, 1, MaxStrLen(WhatsNewNotified."Application Version"));
        WhatsNewNotified."Date Notified" := CurrentDateTime();

        if WhatsNewNotified.Insert() then; // Don't insert a second time
    end;

    [TryFunction]
    local procedure GetAppMajorVersion(var MajorVersion: Text)
    var
        ModInfo: ModuleInfo;
        AppVersion: Text;
        Versions: List of [Text];
    begin
        NavApp.GetCurrentModuleInfo(ModInfo);
        AppVersion := Format(ModInfo.AppVersion()); // e.g. 16.0.43535.3453453
        Versions := AppVersion.Split('.');

        MajorVersion := Versions.Get(1);
        OnGetAppMajorVersion(MajorVersion);
    end;

    local procedure IsGuiAllowed() IsGuiAllowed: Boolean
    begin
        IsGuiAllowed := GuiAllowed();
        OnGetGuiAllowed(IsGuiAllowed);
    end;

    /// <summary>
    /// Raises an event to be able to change the return value of IsGuiAllowed function. Used for testing.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnGetGuiAllowed(var IsGuiAllowed: Boolean)
    begin
    end;

    /// <summary>
    /// Raises an event to be able to change the return value of GetAppMajorVersion function. Used for testing.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnGetAppMajorVersion(var MajorVersion: Text)
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"O365 Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromO365Activities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Account Manager Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromAccountManagerActivities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Accounting Services Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromAccountingServicesActivities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Acc. Payables Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromAccPayablesActivities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Acc. Receivable Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromAccReceivablesActivities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

    [EventSubscriber(ObjectType::Page, Page::"IT Operations Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromITOperationsActivities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Bookkeeper Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromBookkeeperActivities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Resource Manager Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromResourceManagerActivities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Machine Operator Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromMachineOperatorActivities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

    [EventSubscriber(ObjectType::Page, Page::"O365 Sales Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromO365SalesActivities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Agent Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromPurchaseAgentActivities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Rapidstart Services Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromRapidstartServicesActivities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Service Dispatcher Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromServiceDispatcherActivities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Shop Super. basic Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromShopSuperbasicActivities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Shop Supervisor Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromShopSupervisorActivities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Accountant Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromAccountantActivities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Project Manager Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromProjectManagerActivities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

    [EventSubscriber(ObjectType::Page, Page::"SO Processor Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromSOProcessorActivities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

    [EventSubscriber(ObjectType::Page, Page::"User Security Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromUserSecurityActivities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Whse Ship & Receive Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromWhseShipReceiveActivities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

    [EventSubscriber(ObjectType::Page, Page::"WMS Ship & Receive Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromWMSShipReceiveActivities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

    [EventSubscriber(ObjectType::Page, Page::"User Tasks Activities", 'OnOpenPageEvent', '', false, false)]
    local procedure RunFromUserTasksActivities()
    begin
        Codeunit.Run(Codeunit::"What's New Notifier");
    end;

}