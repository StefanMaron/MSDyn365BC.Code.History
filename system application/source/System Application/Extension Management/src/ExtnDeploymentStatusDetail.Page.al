﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Displays details about the deployment status of the selected extension.
/// </summary>
page 2509 "Extn Deployment Status Detail"
{
    Extensible = false;
    DataCaptionExpression = Description;
    DelayedInsert = false;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "NAV App Tenant Operation";
    SourceTableTemporary = true;
    ContextSensitiveHelpPage = 'ui-extensions';

    layout
    {
        area(content)
        {
            group(General)
            {
                group(Control16)
                {
                    ShowCaption = false;
                    field("App Name"; Name)
                    {
                        ApplicationArea = All;
                        Caption = 'App Name';
                        ToolTip = 'Specifies the name of the App.';
                        Visible = NOT HideName;
                    }
                    field("App Publisher"; Publisher)
                    {
                        ApplicationArea = All;
                        Caption = 'App Publisher';
                        ToolTip = 'Specifies the name of the App Publisher.';
                        Visible = NOT HideName;
                    }
                    field("App Version"; Version)
                    {
                        ApplicationArea = All;
                        Caption = 'App Version';
                        ToolTip = 'Specifies the version of the App.';
                        Visible = NOT HideName;
                    }
                    field(Schedule; DeploymentSchedule)
                    {
                        ApplicationArea = All;
                        Caption = 'Schedule';
                        ToolTip = 'Specifies the deployment Schedule.';
                        Visible = NOT HideName;
                    }
                    field("Started On"; "Started On")
                    {
                        ApplicationArea = All;
                        Caption = 'Started Date';
                        ToolTip = 'Specifies the Deployment start date.';
                    }
                }
                group(Control17)
                {
                    ShowCaption = false;
                    field(Status; Status)
                    {
                        ApplicationArea = All;
                        Caption = 'Status';
                        ToolTip = 'Specifies the deployment status.';
                    }
                    field(OpDetails; DeploymentDetails)
                    {
                        ApplicationArea = All;
                        Caption = 'Summary';
                        MultiLine = true;
                        ToolTip = 'Specifies the deployment summary details.';
                    }
                    group(Control18)
                    {
                        ShowCaption = false;
                        Visible = (ShowDetails) AND (NOT ShowDetailedMessage);
                        field(Details; DetailedMessageLbl)
                        {
                            ApplicationArea = All;
                            Caption = 'Details';
                            ShowCaption = false;
                            ToolTip = 'Specifies deploy operation details.';
                            Visible = ShowDetails;

                            trigger OnDrillDown()
                            var
                                ExtensionOperationImpl: Codeunit "Extension Operation Impl";
                            begin
                                DetailedMessageText := ExtensionOperationImpl.GetDeploymentDetailedStatusMessage("Operation ID");
                                DetailedMessageText := DetailedMessageText + ' - Job Id : ' +
                                  ExtensionOperationImpl.GetDeployOperationJobId("Operation ID");
                                ShowDetailedMessage := true;
                            end;
                        }
                    }
                }
            }
            group("Error Details")
            {
                Caption = 'Error Details';
                Visible = ShowDetailedMessage;
                field("Detailed Message box"; DetailedMessageText)
                {
                    ApplicationArea = All;
                    Caption = 'Detailed Message box';
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                    ToolTip = 'Specifies detailed message box.';
                    Visible = ShowDetailedMessage;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Refresh)
            {
                ApplicationArea = All;
                Enabled = NOT IsFinalStatus;
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    ExtensionOperationImpl: Codeunit "Extension Operation Impl";
                begin
                    ExtensionOperationImpl.RefreshStatus("Operation ID");
                    NavAppTenantOperationTable.SetRange("Operation ID", "Operation ID");
                    if not NavAppTenantOperationTable.FindFirst() then
                        CurrPage.Close();

                    SetEnvironmentVariables();
                end;
            }
            action("Download Details")
            {
                ApplicationArea = All;
                Caption = 'Download Details';
                Enabled = ShowDetails;
                Image = ExportFile;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Download the operation status details to a file.';

                trigger OnAction()
                var
                    ExtensionOperationImpl: Codeunit "Extension Operation Impl";
                begin
                    ExtensionOperationImpl.DownloadDeploymentStatusDetails("Operation ID");
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        ExtensionOperationImpl: Codeunit "Extension Operation Impl";
    begin
        NavAppTenantOperationTable.SetRange("Operation ID", "Operation ID");
        if not NavAppTenantOperationTable.FindFirst() then
            CurrPage.Close();

        IsFinalStatus := NavAppTenantOperationTable.Status in [Status::Completed, Status::Failed];

        if not IsFinalStatus then
            ExtensionOperationImpl.RefreshStatus("Operation ID");

        SetOperationRecord();

        ShowDetails := not (Status in [Status::InProgress, Status::Completed]);
        ExtensionOperationImpl.GetDeployOperationInfo("Operation ID", Version, DeploymentSchedule, Publisher, Name, Description);
        if Name = '' then
            HideName := true;
    end;

    var
        NavAppTenantOperationTable: Record "NAV App Tenant Operation";
        DeploymentDetails: BigText;
        DetailedMessageLbl: Label 'View Details';
        ShowDetails: Boolean;
        DetailedMessageText: Text;
        ShowDetailedMessage: Boolean;
        DeploymentSchedule: Text;
        Version: Text;
        Name: Text;
        Publisher: Text;
        HideName: Boolean;
        IsFinalStatus: Boolean;

    local procedure SetOperationRecord()
    var
        DetailsStream: InStream;
    begin
        TransferFields(NavAppTenantOperationTable, true);

        NavAppTenantOperationTable.CalcFields(Details);
        NavAppTenantOperationTable.Details.CreateInStream(DetailsStream, TEXTENCODING::UTF8);
        DeploymentDetails.Read(DetailsStream);
        Insert();
    end;

    local procedure SetEnvironmentVariables()
    var
        DetailsStream: InStream;
    begin
        Status := NavAppTenantOperationTable.Status;
        NavAppTenantOperationTable.CalcFields(Details);
        NavAppTenantOperationTable.Details.CreateInStream(DetailsStream, TEXTENCODING::UTF8);
        DeploymentDetails.Read(DetailsStream);

        CurrPage.Update();
        ShowDetails := Status <> Status::InProgress;
    end;
}

