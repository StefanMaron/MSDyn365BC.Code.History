page 20002 "APIV1 - Aut. Extensions"
{
    APIGroup = 'automation';
    APIPublisher = 'microsoft';
    APIVersion = 'v1.0';
    Caption = 'extensions', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    EntityName = 'extension';
    EntitySetName = 'extensions';
    InsertAllowed = false;
    ModifyAllowed = false;
    ODataKeyFields = "Package ID";
    PageType = API;
    SourceTable = 2000000160;
    SourceTableView = SORTING(Name) WHERE(Name = FILTER(<> '_Exclude_*'), "Package Type" = FILTER(= 0 | 2));  //TODO
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(packageId; "Package ID")
                {
                    ApplicationArea = All;
                    Caption = 'packageId', Locked = true;
                }
                field(id; ID)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                }
                field(displayName; Name)
                {
                    ApplicationArea = All;
                    Caption = 'displayName', Locked = true;
                }
                field(publisher; Publisher)
                {
                    ApplicationArea = All;
                    Caption = 'publisher', Locked = true;
                }
                field(versionMajor; "Version Major")
                {
                    ApplicationArea = All;
                    Caption = 'versionMajor', Locked = true;
                }
                field(versionMinor; "Version Minor")
                {
                    ApplicationArea = All;
                    Caption = 'versionMinor', Locked = true;
                }
                field(scope; Scope)
                {
                    ApplicationArea = All;
                    Caption = 'scope', Locked = true;
                    Editable = false;
                }
                field(isInstalled; Isinstalled)
                {
                    ApplicationArea = All;
                    Caption = 'isInstalled', Locked = true;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    var
        ExtensionManagement: Codeunit 2504;
    begin
        Isinstalled := ExtensionManagement.IsInstalledByPackageId("Package ID");
    end;

    trigger OnOpenPage()
    var
        EnvironmentInfo: codeunit 457;
    begin
        BINDSUBSCRIPTION(AutomationAPIManagement);

        FILTERGROUP(2);
        IF EnvironmentInfo.IsSaas() THEN
            SETFILTER("PerTenant Or Installed", '%1', TRUE)
        ELSE
            SETFILTER("Tenant Visible", '%1', TRUE);
        FILTERGROUP(0);
    end;

    var
        AutomationAPIManagement: Codeunit 5435;

        Isinstalled: Boolean;
        IsNotInstalledErr: Label 'The extension %1 is not installed.', Comment = '%1=name of app';
        IsInstalledErr: Label 'The extension %1 is already installed.', Comment = '%1=name of app';

    [ServiceEnabled]
    [Scope('Cloud')]
    procedure install(var ActionContext: WebServiceActionContext)
    var
        ExtensionManagement: Codeunit 2504;
    begin
        IF ExtensionManagement.IsInstalledByPackageId("Package ID") THEN
            ERROR(STRSUBSTNO(IsInstalledErr, Name));

        ExtensionManagement.InstallExtension("Package ID", GLOBALLANGUAGE(), FALSE);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"APIV1 - Aut. Extensions");
        ActionContext.AddEntityKey(FieldNo(Id), id);
        ActionContext.SetResultCode(WebServiceActionResultCode::Deleted);
    end;

    [ServiceEnabled]
    [Scope('Cloud')]
    procedure uninstall(var ActionContext: WebServiceActionContext)
    var
        ExtensionManagement: Codeunit 2504;
    begin
        IF NOT ExtensionManagement.IsInstalledByPackageId("Package ID") THEN
            ERROR(STRSUBSTNO(IsNotInstalledErr, Name));

        ExtensionManagement.UninstallExtension("Package ID", FALSE);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"APIV1 - Aut. Extensions");
        ActionContext.AddEntityKey(FieldNo(Id), id);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}

