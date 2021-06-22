codeunit 5446 "Graph Webhook Sync To NAV"
{
    TableNo = "Webhook Notification";

    trigger OnRun()
    var
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        IntegrationTableMapping: Record "Integration Table Mapping";
        WebhookSubscription: Record "Webhook Subscription";
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
        GraphIntegrationTableSync: Codeunit "Graph Integration Table Sync";
        GraphSubscriptionManagement: Codeunit "Graph Subscription Management";
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
        InboundConnectionName: Text;
        EmptyGuid: Guid;
        IntegrationMappingCode: Code[20];
        TableID: Integer;
    begin
        OnFindWebhookSubscription(WebhookSubscription, "Subscription ID", IntegrationMappingCode);
        if IntegrationMappingCode = '' then
            exit;

        SendTraceTag('000016Z', GraphSubscriptionManagement.TraceCategory, VERBOSITY::Verbose,
          StrSubstNo(ReceivedNotificationTxt, "Change Type", IntegrationMappingCode, "Resource ID"),
          DATACLASSIFICATION::SystemMetadata);

        GraphConnectionSetup.RegisterConnections;
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        TableID := GraphDataSetup.GetInboundTableID(IntegrationMappingCode);
        InboundConnectionName := GraphConnectionSetup.GetInboundConnectionName(TableID);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, InboundConnectionName, true);

        case DelChr("Change Type", '=', ' ') of
            GetGraphSubscriptionCreatedChangeType,
          GetGraphSubscriptionUpdatedChangeType:
                if GraphSubscriptionManagement.GetSourceRecordRef(SourceRecordRef, Rec, IntegrationTableMapping."Integration Table ID") then
                    GraphIntegrationTableSync.PerformRecordSynchFromIntegrationTable(IntegrationTableMapping, SourceRecordRef);
            GetGraphSubscriptionDeletedChangeType:
                if GraphSubscriptionManagement.GetDestinationRecordRef(DestinationRecordRef, Rec, IntegrationTableMapping."Table ID") then begin
                    GraphIntegrationTableSync.PerformRecordDeleteFromIntegrationTable(IntegrationTableMapping, DestinationRecordRef);
                    ArchiveIntegrationRecords(Rec, DestinationRecordRef.Number);
                end;
            GetGraphSubscriptionMissedChangeType:
                IntegrationSynchJobErrors.LogSynchError(EmptyGuid, RecordId, RecordId,
                  StrSubstNo(WebhookNotificationTxt, "Change Type", "Resource ID"));
            else
                IntegrationSynchJobErrors.LogSynchError(EmptyGuid, RecordId, RecordId,
                  StrSubstNo(UnsupportedChangeTypeErr, "Change Type"));
        end;
    end;

    var
        ChangeType: Option Created,Updated,Deleted,Missed;
        UnsupportedChangeTypeErr: Label 'The %1 change type is not supported.', Comment = 'The Missed change type is not supported.';
        WebhookNotificationTxt: Label 'Change Type = %1, Resource ID = %2.', Comment = 'Change Type = Missed, Resource ID = ABC.';
        ReceivedNotificationTxt: Label 'Received %1 notification for the %2 table mapping. Graph ID: %3.', Comment = '%1 - Change type; %2 - table mapping code; %3 - Graph ID', Locked = true;

    procedure GetGraphSubscriptionChangeTypes(): Text[250]
    begin
        // Created,Updated,Deleted
        exit(StrSubstNo('%1,%2,%3',
            GetGraphSubscriptionCreatedChangeType, GetGraphSubscriptionUpdatedChangeType, GetGraphSubscriptionDeletedChangeType));
    end;

    procedure GetGraphSubscriptionCreatedChangeType(): Text[50]
    begin
        exit(Format(ChangeType::Created, 0, 0));
    end;

    procedure GetGraphSubscriptionUpdatedChangeType(): Text[50]
    begin
        exit(Format(ChangeType::Updated, 0, 0));
    end;

    procedure GetGraphSubscriptionDeletedChangeType(): Text[50]
    begin
        exit(Format(ChangeType::Deleted, 0, 0));
    end;

    procedure GetGraphSubscriptionMissedChangeType(): Text[50]
    begin
        exit(Format(ChangeType::Missed, 0, 0));
    end;

    local procedure ArchiveIntegrationRecords(WebhookNotification: Record "Webhook Notification"; TableId: Integer)
    var
        GraphIntegrationRecord: Record "Graph Integration Record";
        GraphIntegrationRecArchive: Record "Graph Integration Rec. Archive";
        OutputStream: OutStream;
    begin
        GraphIntegrationRecord.SetRange("Graph ID", WebhookNotification."Resource ID");
        GraphIntegrationRecord.SetRange("Table ID", TableId);
        if GraphIntegrationRecord.FindFirst then begin
            GraphIntegrationRecArchive.TransferFields(GraphIntegrationRecord);
            GraphIntegrationRecArchive."Webhook Notification".CreateOutStream(OutputStream);
            OutputStream.Write(ReadWebhookNotificationDetails(WebhookNotification));
            if GraphIntegrationRecArchive.Insert() then
                GraphIntegrationRecord.Delete();
        end;
    end;

    local procedure ReadWebhookNotificationDetails(WebhookNotification: Record "Webhook Notification") WebhookNotificationDetails: Text
    var
        InputStream: InStream;
    begin
        if WebhookNotification.Notification.HasValue then begin
            WebhookNotification.CalcFields(Notification);
            WebhookNotification.Notification.CreateInStream(InputStream);
            InputStream.Read(WebhookNotificationDetails);
        end else
            WebhookNotificationDetails :=
              StrSubstNo(WebhookNotificationTxt, WebhookNotification."Change Type", WebhookNotification."Resource ID");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindWebhookSubscription(var WebhookSubscription: Record "Webhook Subscription"; SubscriptionID: Text[150]; var IntegrationMappingCode: Code[20])
    begin
    end;
}

