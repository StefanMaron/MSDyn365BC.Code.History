page 20007 "APIV1 - Aut. Extension Depl."
{
    APIGroup = 'automation';
    APIPublisher = 'microsoft';
    APIVersion = 'v1.0';
    Caption = 'extensionDeploymentStatus', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    EntityName = 'extensionDeploymentStatus';
    EntitySetName = 'extensionDeploymentStatus';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = API;
    RefreshOnActivate = true;
    SourceTable = "NAV App Tenant Operation";
    SourceTableTemporary = true;
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(name; AppName)
                {
                    ApplicationArea = All;
                    Caption = 'name', Locked = true;
                    ToolTip = 'Specifies the name of the App.';
                }
                field(publisher; ExtensionPublisher)
                {
                    ApplicationArea = All;
                    Caption = 'publisher', Locked = true;
                    ToolTip = 'Specifies the name of the App Publisher.';
                }
                field(operationType; OperationTypeOption)
                {
                    ApplicationArea = All;
                    Caption = 'operationType', Locked = true;
                    ToolTip = 'Specifies the deployment type.';
                }
                field(status; Status)
                {
                    ApplicationArea = All;
                    Caption = 'status', Locked = true;
                    ToolTip = 'Specifies the deployment status.';
                }
                field(schedule; ExtensionSchedule)
                {
                    ApplicationArea = All;
                    Caption = 'schedule', Locked = true;
                    ToolTip = 'Specifies the deployment Schedule.';
                    Width = 12;
                }
                field(appVersion; Version)
                {
                    ApplicationArea = All;
                    Caption = 'appVersion', Locked = true;
                    ToolTip = 'Specifies the version of the App.';
                    Width = 6;
                }
                field(startedOn; "Started On")
                {
                    ApplicationArea = All;
                    Caption = 'startedOn', Locked = true;
                    ToolTip = 'Specifies the deployment start date.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }

    trigger OnAfterGetRecord()
    begin
        IF "Operation Type" = 0 THEN
            OperationTypeOption := OperationTypeOption::Install
        ELSE
            OperationTypeOption := OperationTypeOption::Upload;

        ExtensionManagement.GetDeployOperationInfo("Operation ID", Version, ExtensionSchedule, ExtensionPublisher, AppName, Description);
        IF Status = Status::InProgress THEN
            ExtensionManagement.RefreshStatus("Operation ID");
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        SETCURRENTKEY("Started On");
        ASCENDING(FALSE);
    end;

    var
        ExtensionManagement: Codeunit 2504;
        Version: Text;
        ExtensionSchedule: Text;
        ExtensionPublisher: Text;
        AppName: Text;
        OperationTypeOption: Option Upload,Install;
}

