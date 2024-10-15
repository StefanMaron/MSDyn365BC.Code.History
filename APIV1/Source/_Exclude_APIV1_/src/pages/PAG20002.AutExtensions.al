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
    SourceTable = "Published Application";
    SourceTableView = SORTING(Name)
                      WHERE(Name = FILTER(<> '_Exclude_*'),
                            "Tenant Visible" = CONST(true),
                            "Package Type" = FILTER(= Extension | Designer));
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
                field(versionBuild; "Version Build")
                {
                    ApplicationArea = All;
                    Caption = 'versionBuild', Locked = true;
                }
                field(versionRevision; "Version Revision")
                {
                    ApplicationArea = All;
                    Caption = 'versionRevision', Locked = true;
                }
                field(scope; GetExtensionScope())
                {
                    ApplicationArea = All;
                    Caption = 'scope', Locked = true;
                    Editable = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The scope of the extension has been replaced by the publishedAs property.';
                    ObsoleteTag = '16.0';
                }
                field(isInstalled; isExtensionInstalled)
                {
                    ApplicationArea = All;
                    Caption = 'isInstalled', Locked = true;
                    Editable = false;
                }
                field(publishedAs; "Published As")
                {
                    ApplicationArea = All;
                    Caption = 'publishedAs', Locked = true;
                    Editable = false;
                    ToolTip = 'TODO(pteisolation) We should remove the code cop error for API pages';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        isExtensionInstalled := ExtensionManagement.IsInstalledByPackageId("Package ID");
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

        IsExtensionInstalled: Boolean;
        IsNotInstalledErr: Label 'The extension %1 is not installed.', Comment = '%1=name of app';
        IsInstalledErr: Label 'The extension %1 is already installed.', Comment = '%1=name of app';

    [ServiceEnabled]
    [Scope('Cloud')]
    procedure install(var ActionContext: WebServiceActionContext)
    begin
        IF ExtensionManagement.IsInstalledByPackageId("Package ID") THEN
            ERROR(STRSUBSTNO(IsInstalledErr, Name));

        ExtensionManagement.InstallExtension("Package ID", GLOBALLANGUAGE(), FALSE);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"APIV1 - Aut. Extensions");
        ActionContext.AddEntityKey(FieldNo(ID), ID);
        ActionContext.SetResultCode(WebServiceActionResultCode::Deleted);
    end;

    [ServiceEnabled]
    [Scope('Cloud')]
    procedure uninstall(var ActionContext: WebServiceActionContext)
    begin
        IF NOT ExtensionManagement.IsInstalledByPackageId("Package ID") THEN
            ERROR(STRSUBSTNO(IsNotInstalledErr, Name));

        ExtensionManagement.UninstallExtension("Package ID", FALSE);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"APIV1 - Aut. Extensions");
        ActionContext.AddEntityKey(FieldNo(ID), ID);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    local procedure GetExtensionScope(): Integer
    begin
        if (Rec."Published As" = Rec."Published As"::Global) then
            exit(0)
        else
            exit(1);
    end;

    var
        ExtensionManagement: Codeunit 2504;

}

