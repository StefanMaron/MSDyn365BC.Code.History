table 5455 "Graph Subscription"
{
    Caption = 'Graph Subscription';
    Permissions = TableData "Webhook Subscription" = rimd;
    TableType = MicrosoftGraph;

    fields
    {
        field(1; ChangeType; Text[250])
        {
            Caption = 'ChangeType', Locked = true;
            ExternalName = 'ChangeType';
            ExternalType = 'Edm.String';
        }
        field(2; ClientState; Text[50])
        {
            Caption = 'ClientState', Locked = true;
            ExternalName = 'ClientState';
            ExternalType = 'Edm.String';
        }
        field(3; ExpirationDateTime; DateTime)
        {
            Caption = 'ExpirationDateTime', Locked = true;
            ExternalName = 'SubscriptionExpirationDateTime';
            ExternalType = 'Edm.DateTimeOffset';
        }
        field(4; NotificationUrl; Text[250])
        {
            Caption = 'NotificationUrl', Locked = true;
            ExternalName = 'NotificationURL';
            ExternalType = 'Edm.String';
        }
        field(5; Resource; Text[250])
        {
            Caption = 'Resource', Locked = true;
            ExternalName = 'Resource';
            ExternalType = 'Edm.String';
        }
        field(6; Type; Text[250])
        {
            Caption = 'Type', Locked = true;
            ExternalName = '@odata.type';
            ExternalType = 'Edm.String';
        }
        field(7; Id; Text[150])
        {
            Caption = 'Id', Locked = true;
            ExternalName = 'Id';
            ExternalType = 'Edm.String';
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure CreateGraphSubscription(var GraphSubscription: Record "Graph Subscription"; ResourceEndpoint: Text[250]): Boolean
    var
        GraphConnectionSetup: Codeunit "Graph Connection Setup";
        GraphSubscriptionMgt: Codeunit "Graph Subscription Management";
        GraphWebhookSyncToNAV: Codeunit "Graph Webhook Sync To NAV";
    begin
        GraphSubscription.Reset();
        GraphSubscription.Id := CreateGuid;
        GraphSubscription.ChangeType := GraphWebhookSyncToNAV.GetGraphSubscriptionChangeTypes;
        GraphSubscription.ExpirationDateTime := CurrentDateTime + GraphSubscriptionMgt.GetMaximumExpirationDateTimeOffset;
        GraphSubscription.Resource := ResourceEndpoint;
        GraphSubscription.ClientState := CreateGuid;
        GraphSubscription.NotificationUrl := GraphConnectionSetup.GetGraphNotificationUrl;
        GraphSubscription.Type := GraphSubscriptionMgt.GetGraphSubscriptionType;
        exit(GraphSubscription.Insert);
    end;

    procedure CreateWebhookSubscription(var WebhookSubscription: Record "Webhook Subscription"): Boolean
    var
        MarketingSetup: Record "Marketing Setup";
        GraphSubscriptionMgt: Codeunit "Graph Subscription Management";
    begin
        GraphSubscriptionMgt.CleanExistingWebhookSubscription(Resource, CompanyName);
        Clear(WebhookSubscription);
        WebhookSubscription."Subscription ID" := Id;
        WebhookSubscription.Endpoint := Resource;
        WebhookSubscription."Client State" := ClientState;
        WebhookSubscription."Company Name" := CompanyName;
        WebhookSubscription."Run Notification As" := MarketingSetup.TrySetWebhookSubscriptionUserAsCurrentUser;
        exit(WebhookSubscription.Insert);
    end;
}

