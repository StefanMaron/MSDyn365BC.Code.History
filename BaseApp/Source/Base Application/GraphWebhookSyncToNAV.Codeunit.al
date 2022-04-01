#if not CLEAN18
codeunit 5446 "Graph Webhook Sync To NAV"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will be removed. The functionality is not supported any more.';
    ObsoleteTag = '18.0';
    TableNo = "Webhook Notification";

    trigger OnRun()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        WebhookSubscription: Record "Webhook Subscription";
        GraphDataSetup: Codeunit "Graph Data Setup";
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
        GraphSubscriptionManagement: Codeunit "Graph Subscription Management";
        InboundConnectionName: Text;
        IntegrationMappingCode: Code[20];
        TableID: Integer;
    begin
        OnFindWebhookSubscription(WebhookSubscription, "Subscription ID", IntegrationMappingCode);
        if IntegrationMappingCode = '' then
            exit;

        Session.LogMessage('000016Z', StrSubstNo(ReceivedNotificationTxt, "Change Type", IntegrationMappingCode, "Resource ID"), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GraphSubscriptionManagement.TraceCategory);

        GraphConnectionSetup.RegisterConnections;
        GraphDataSetup.GetIntegrationTableMapping(IntegrationTableMapping, IntegrationMappingCode);
        TableID := GraphDataSetup.GetInboundTableID(IntegrationMappingCode);
        InboundConnectionName := GraphConnectionSetup.GetInboundConnectionName(TableID);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::MicrosoftGraph, InboundConnectionName, true);
    end;

    var
        ChangeType: Option Created,Updated,Deleted,Missed;
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

    [IntegrationEvent(false, false)]
    local procedure OnFindWebhookSubscription(var WebhookSubscription: Record "Webhook Subscription"; SubscriptionID: Text[150]; var IntegrationMappingCode: Code[20])
    begin
    end;
}

#endif