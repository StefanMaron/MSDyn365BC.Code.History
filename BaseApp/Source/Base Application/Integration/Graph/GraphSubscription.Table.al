// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using System.Integration;

table 5455 "Graph Subscription"
{
    Caption = 'Graph Subscription';
    Permissions = TableData "Webhook Subscription" = rimd;
    TableType = MicrosoftGraph;
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
    ObsoleteReason = 'This functionality is out of support';
    DataClassification = CustomerContent;

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
    begin
        exit(false);
    end;

    procedure CreateWebhookSubscription(var WebhookSubscription: Record "Webhook Subscription"): Boolean
    begin
        exit(false);
    end;
}

