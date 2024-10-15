﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

page 2508 "Extension Deployment Status"
{
    Extensible = false;
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "NAV App Tenant Operation";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; AppName)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the App.';
                }
                field(Publisher; Publisher)
                {
                    ApplicationArea = All;
                    Caption = 'Publisher';
                    ToolTip = 'Specifies the name of the App Publisher.';
                }
                field("Operation Type"; OperationType)
                {
                    ApplicationArea = All;
                    Caption = 'Operation Type';
                    ToolTip = 'Specifies the deployment type.';
                }
                field(Status; Status)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    ToolTip = 'Specifies the deployment status.';
                }
                field(Schedule; Schedule)
                {
                    ApplicationArea = All;
                    Caption = 'Schedule';
                    ToolTip = 'Specifies the deployment Schedule.';
                    Width = 12;
                }
                field(AppVersion; Version)
                {
                    ApplicationArea = All;
                    Caption = 'App Version';
                    ToolTip = 'Specifies the version of the App.';
                    Width = 6;
                }
                field("Started On"; "Started On")
                {
                    ApplicationArea = All;
                    Caption = 'Started Date';
                    ToolTip = 'Specifies the deployment start date.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(View)
            {
                ApplicationArea = All;
                Image = View;
                Scope = Repeater;
                ShortCutKey = 'Return';
                Visible = false;

                trigger OnAction()
                var
                    ExtnDeploymentStatusDetail: Page "Extn Deployment Status Detail";
                begin
                    ExtnDeploymentStatusDetail.SetRecord(Rec);
                    ExtnDeploymentStatusDetail.Run();
                    CurrPage.Update();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        ExtensionOperationImpl: Codeunit "Extension Operation Impl";
    begin
        if "Operation Type" = 0 then
            OperationType := OperationType::Install
        else
            OperationType := OperationType::Upload;

        ExtensionOperationImpl.GetDeployOperationInfo("Operation ID", Version, Schedule, Publisher, AppName, Description);

        if Status = Status::InProgress then
            ExtensionOperationImpl.RefreshStatus("Operation ID");
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

