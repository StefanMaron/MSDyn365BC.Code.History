page 5448 "Automation Extension Depl."
{
    APIGroup = 'automation';
    APIPublisher = 'microsoft';
    Caption = 'ExtensionDeploymentStatus', Locked = true;
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
                field(publisher; Publisher)
                {
                    ApplicationArea = All;
                    Caption = 'publisher', Locked = true;
                    ToolTip = 'Specifies the name of the App Publisher.';
                }
                field(operationType; OperationType)
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
                field(schedule; Schedule)
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
    var
        ExtensionManagement: Codeunit "Extension Management";
    begin
        if "Operation Type" = 0 then
            OperationType := OperationType::Install
        else
            OperationType := OperationType::Upload;

        ExtensionManagement.GetDeployOperationInfo("Operation ID", Version, Schedule, Publisher, AppName, Description);

        if Status = Status::InProgress then
            ExtensionManagement.RefreshStatus("Operation ID");
    end;

    trigger OnOpenPage()
    begin
        SetCurrentKey("Started On");
        Ascending(false);
    end;

    var
        Version: Text;
        Schedule: Text;
        Publisher: Text;
        AppName: Text;
        OperationType: Option Upload,Install;
}

