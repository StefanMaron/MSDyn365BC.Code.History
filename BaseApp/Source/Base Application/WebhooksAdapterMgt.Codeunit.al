codeunit 2201 "Webhooks Adapter Mgt."
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This function will be removed for security reason as it used to contain Microsoft secrets';
    ObsoleteTag = '15.2';
    trigger OnRun()
    begin
    end;

    var
        FunctionNotSupportedErr: Label 'This function is not supported';

    [Scope('OnPrem')]
    procedure GetAccessToken(ThrowErrors: Boolean) Token: Text
    begin
        Token := '';
        exit;
    end;

    [Scope('OnPrem')]
    procedure GetWebhooksAdapterUri(ThrowError: Boolean): Text
    begin
        exit('');
    end;

    procedure FindWebhookSubscription(var WebhookSubscription: Record "Webhook Subscription"; SubscriptionUri: Text[250]): Boolean
    begin
        error(FunctionNotSupportedErr);
    end;

    procedure DeleteWebhookSubscription(SubscriptionUri: Text[250])
    begin
        error(FunctionNotSupportedErr);
    end;

    procedure SetAzureKeyVaultManagement(NewAzureKeyVaultManagement: Codeunit 2200)
    begin
        error(FunctionNotSupportedErr);
    end;
}
