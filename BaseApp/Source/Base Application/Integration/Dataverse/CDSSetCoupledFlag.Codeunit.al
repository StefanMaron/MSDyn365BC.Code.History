#if not CLEAN23
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Sales.History;
using Microsoft.Upgrade;
using System.Threading;
using System.Upgrade;

codeunit 5363 "CDS Set Coupled Flag"
{
    TableNo = "Job Queue Entry";
    Permissions = TableData "Sales Invoice Header" = m;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by flow fields Coupled to Dataverse';
    ObsoleteTag = '23.0';

    trigger OnRun()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        RecRef: RecordRef;
        CoupledToCRMFieldRef: FieldRef;
        CoupledToCRMFieldNo: Integer;
        ExistingValue: Boolean;
    begin
        RestartFailedJobQueueEntriesOnce();

        if not CRMIntegrationRecord.Get(Rec."Record ID to Process") then
            exit;

        if CRMIntegrationRecord."Table ID" = 0 then
            exit;

        if not TryOpen(RecRef, CRMIntegrationRecord."Table ID") then
            exit;

        if not RecRef.GetBySystemId(CRMIntegrationRecord."Integration ID") then
            exit;

        if not CRMIntegrationManagement.FindCoupledToCRMField(RecRef, CoupledToCRMFieldRef) then
            exit;

        CoupledToCRMFieldNo := CoupledToCRMFieldRef.Number();
        if not RecRef.GetBySystemId(CRMIntegrationRecord."Integration ID") then
            exit;

        CoupledToCRMFieldRef := RecRef.Field(CoupledToCRMFieldNo);

        ExistingValue := CoupledToCRMFieldRef.Value();
        if ExistingValue = true then
            exit;

        CoupledToCRMFieldRef.Value := true;
        RecRef.Modify();
        Session.LogMessage('0000GAY', StrSubstNo(SuccessfullyMarkedInvoiceAsCoupledTxt, RecRef.Caption(), CRMIntegrationRecord."Integration ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
    end;

    local procedure RestartFailedJobQueueEntriesOnce()
    var
        JobQueueEntry: Record "Job Queue Entry";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        Counter: Integer;
        EarliestStartDateTime: DateTime;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetRestartSetCoupledFlagJQEsUpgradeTag()) then
            exit;

        if not TaskScheduler.CanCreateTask() then
            exit;

        EarliestStartDateTime := CurrentDateTime + 120000;
        JobQueueEntry.SetRange("Job Queue Category Code", JobQueueCategoryLbl);
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Error);
        if JobQueueEntry.FindSet() then begin
            Session.LogMessage('0000GE1', RestartingFailedJobQueueEntriesTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            repeat
                JobQueueEntry."Earliest Start Date/Time" := EarliestStartDateTime;
                Codeunit.RUN(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
                Counter += 1;
                EarliestStartDateTime := EarliestStartDateTime + (Counter * 10000);
            until JobQueueEntry.Next() = 0;
            Session.LogMessage('0000GE2', DoneRestartingFailedJobQueueEntriesTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetRestartSetCoupledFlagJQEsUpgradeTag());
    end;

    [TryFunction]
    local procedure TryOpen(var RecRef: RecordRef; TableId: Integer)
    begin
        RecRef.Open(TableId);
    end;

    var
        SuccessfullyMarkedInvoiceAsCoupledTxt: Label 'Successfully marked %1 %2 as coupled to Dataverse.', Locked = true;
        RestartingFailedJobQueueEntriesTxt: Label 'Restarting failed CDS Set Coupled Flag job queue entries.', Locked = true;
        DoneRestartingFailedJobQueueEntriesTxt: Label 'Done restarting failed CDS Set Coupled Flag job queue entries.', Locked = true;
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        JobQueueCategoryLbl: Label 'BCI CPLFLG', Locked = true;

}
#endif