table 1070 "MS - PayPal Standard Account"
{
    Caption = 'PayPal Payments Standard Account';
    DrillDownPageID = 1070;
    LookupPageID = 1070;
    Permissions = TableData 2000000199 = rimd;
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Integer)
        {
            AutoIncrement = true;
        }
        field(2; Name; Text[250])
        {
            NotBlank = true;
        }
        field(3; Description; Text[250])
        {
            NotBlank = true;
        }
        field(4; Enabled; Boolean)
        {

            trigger OnValidate();
            begin
                VerifyAccountID();
            end;
        }
        field(5; "Always Include on Documents"; Boolean)
        {

            trigger OnValidate();
            var
                MSPayPalStandardAccount: Record 1070;
                SalesHeader: Record 36;
            begin
                IF NOT "Always Include on Documents" THEN
                    EXIT;

                MSPayPalStandardAccount.SETRANGE("Always Include on Documents", TRUE);
                MSPayPalStandardAccount.SETFILTER("Primary Key", '<>%1', "Primary Key");
                MSPayPalStandardAccount.MODIFYALL("Always Include on Documents", FALSE, TRUE);

                IF NOT GUIALLOWED() THEN
                    EXIT;

                SalesHeader.SETFILTER("Document Type", STRSUBSTNO('%1|%2|%3',
                    SalesHeader."Document Type"::Invoice,
                    SalesHeader."Document Type"::Order,
                    SalesHeader."Document Type"::Quote));

                IF SalesHeader.FINDFIRST() AND NOT HideDialogs THEN
                    MESSAGE(UpdateOpenInvoicesManuallyMsg);
            end;
        }
        field(8; "Terms of Service"; Text[250])
        {
            ExtendedDatatype = URL;
        }
        field(10; "Account ID"; Text[250])
        {

            trigger OnValidate();
            begin
                VerifyAccountID();
                "Account ID" := LOWERCASE("Account ID");
            end;
        }
        field(12; "Target URL"; BLOB)
        {
            Caption = 'Service URL';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete();
    begin
        DeleteWebhookSubscription("Account ID");
    end;

    trigger OnModify();
    begin
        UpdateWebhookOnModify();
    end;

    var
        MSPayPalWebhooksMgt: Codeunit 1073;
        PayPalTelemetryCategoryTok: Label 'AL Paypal', Locked = true;
        AccountIDCannotBeBlankErr: Label 'You must specify an account ID for this payment service.';
        RefreshWebhooksSubscriptionMsg: Label 'Deleting and recreating Webhook Subscription.', Locked = true;
        AccountIDTooLongForWebhooksErr: Label 'The length of the specified PayPal account ID exceeds the maximum supported length of the webhook subscription ID, which is %1 characters.', Comment = '%1=integer value';
        UpdateOpenInvoicesManuallyMsg: Label 'A link for the PayPal payment service will be included for new sales documents. To add it to existing sales documents, you must manually select it in the Payment Service field on the sales document.';
        WebhooksNotAllowedForCurrentClientTypeTxt: Label 'Webhooks are not allowed for the current client type.', Locked = true;
        PaymentRegistrationSetupAlreadyExistsTxt: Label 'The payment registration setup already exists.', Locked = true;
        PaymentRegistrationSetupCreatedTxt: Label 'A payment registration setup is created.', Locked = true;
        PaymentRegistrationSetupNotCreatedTxt: Label 'A payment registration setup is not created.', Locked = true;
        WebhookSubscriptionNotCreatedTxt: Label 'A webhook subscription is not created.', Locked = true;
        WebhookSubscriptionCreatedTxt: Label 'A webhook subscription is created.', Locked = true;
        WebhookSubscriptionDeletedTxt: Label 'The webhook subscription is deleted.', Locked = true;
        WebhookSubscriptionDoesNotExistTxt: Label 'The webhook subscription does not exist.', Locked = true;
        InvalidTargetURLErr: Label 'The target URL is not valid.';
        HideDialogs: Boolean;

    procedure GetTargetURL(): Text;
    var
        InStream: InStream;
        TargetURL: Text;
    begin
        TargetURL := '';
        CALCFIELDS("Target URL");
        IF "Target URL".HASVALUE() THEN BEGIN
            "Target URL".CREATEINSTREAM(InStream);
            InStream.READ(TargetURL);
        END;
        EXIT(TargetURL);
    end;

    procedure SetTargetURL(TargetURL: Text);
    var
        MSPayPalStandardMgt: Codeunit 1070;
        OutStream: OutStream;
    begin
        if not MSPayPalStandardMgt.IsValidAndSecureURL(TargetURL) then
            Error(InvalidTargetURLErr);

        "Target URL".CREATEOUTSTREAM(OutStream);
        OutStream.WRITE(TargetURL);
        MODIFY();
    end;

    local procedure VerifyAccountID();
    begin
        IF Enabled THEN
            IF "Account ID" = '' THEN
                IF HideDialogs THEN
                    "Account ID" := ''
                ELSE
                    ERROR(AccountIDCannotBeBlankErr);
    end;

    procedure HideAllDialogs();
    begin
        HideDialogs := TRUE;
    end;

    local procedure UpdateWebhookOnModify();
    var
        PrevMSPayPalStandardAccount: Record 1070;
    begin
        PrevMSPayPalStandardAccount.GET("Primary Key");

        IF PrevMSPayPalStandardAccount."Account ID" <> "Account ID" THEN
            DeleteWebhookSubscription(PrevMSPayPalStandardAccount."Account ID");

        IF "Account ID" <> '' THEN
            IF Enabled THEN
                RegisterWebhookListenerForRec()
            ELSE
                DeleteWebhookSubscription("Account ID");

        CreatePaymentRegistrationSetupForCurrentUser();
    end;

    local procedure RegisterWebhookListenerForRec();
    var
        WebhookSubscription: Record 2000000199;
        MarketingSetup: Record 5079;
        WebhookManagement: Codeunit 5377;
        WebhooksAdapterUri: Text[250];
        SubscriptionId: Text[150];
    begin
        IF NOT WebhookManagement.IsCurrentClientTypeAllowed() THEN BEGIN
            SendTraceTag('00008H5', PayPalTelemetryCategoryTok, Verbosity::Normal, WebhooksNotAllowedForCurrentClientTypeTxt, DataClassification::SystemMetadata);
            EXIT;
        END;

        if StrLen("Account ID") > MaxStrLen(SubscriptionId) then begin
            SendTraceTag('00006TI', PayPalTelemetryCategoryTok, Verbosity::Warning, STRSUBSTNO(AccountIDTooLongForWebhooksErr, MaxStrLen(SubscriptionId)), DataClassification::SystemMetadata);
            ERROR(STRSUBSTNO(AccountIDTooLongForWebhooksErr, MaxStrLen(SubscriptionId)));
        end;

        SubscriptionId := CopyStr(LowerCase("Account ID"), 1, MaxStrLen(SubscriptionId));
        WebhookSubscription.SETRANGE("Subscription ID", SubscriptionId);
        WebhookSubscription.SetFilter("Created By", MSPayPalWebhooksMgt.GetCreatedByFilterForWebhooks());
        WebhooksAdapterUri := LOWERCASE(WebhookManagement.GetNotificationUrl());

        if WebhookManagement.FindWebhookSubscriptionMatchingEndPointUri(WebhookSubscription, WebhooksAdapterUri, 0, 0) then begin
            SendTraceTag('00006TJ', PayPalTelemetryCategoryTok, Verbosity::Warning, RefreshWebhooksSubscriptionMsg, DataClassification::SystemMetadata);
            WebhookSubscription.Delete(true); // Delete and re-insert: do not assume that if the account ID is the same, the webhook is equivalent
            Clear(WebhookSubscription);
        end;

        WebhookSubscription."Subscription ID" := SubscriptionId;
        WebhookSubscription.Endpoint := WebhooksAdapterUri;
        WebhookSubscription."Created By" := GetBaseURL();
        WebhookSubscription."Company Name" := CopyStr(COMPANYNAME(), 1, MaxStrLen(WebhookSubscription."Company Name"));
        WebhookSubscription."Run Notification As" := MarketingSetup.TrySetWebhookSubscriptionUserAsCurrentUser();
        IF NOT WebhookSubscription.INSERT() THEN
            SendTraceTag('00008H6', PayPalTelemetryCategoryTok, Verbosity::Warning, WebhookSubscriptionNotCreatedTxt, DataClassification::SystemMetadata)
        ELSE
            SendTraceTag('00008H7', PayPalTelemetryCategoryTok, Verbosity::Normal, WebhookSubscriptionCreatedTxt, DataClassification::SystemMetadata);
    end;

    local procedure DeleteWebhookSubscription(AccountId: Text[250]);
    var
        WebhookSubscription: Record 2000000199;
        WebhookManagement: Codeunit 5377;
        WebhooksAdapterUri: Text[250];
        SubscriptionId: Text[150];
    begin
        SubscriptionId := CopyStr(LowerCase(AccountId), 1, MaxStrLen(SubscriptionId));
        WebhookSubscription.SETRANGE("Subscription ID", SubscriptionId);
        WebhookSubscription.SetFilter("Created By", MSPayPalWebhooksMgt.GetCreatedByFilterForWebhooks());

        WebhooksAdapterUri := LOWERCASE(WebhookManagement.GetNotificationUrl());
        IF WebhookManagement.FindWebhookSubscriptionMatchingEndPointUri(WebhookSubscription, WebhooksAdapterUri, 0, 0) THEN BEGIN
            WebhookSubscription.DELETE(TRUE);
            SendTraceTag('00008H8', PayPalTelemetryCategoryTok, Verbosity::Normal, WebhookSubscriptionDeletedTxt, DataClassification::SystemMetadata);
        END;

        SendTraceTag('00008H9', PayPalTelemetryCategoryTok, Verbosity::Normal, WebhookSubscriptionDoesNotExistTxt, DataClassification::SystemMetadata);
    end;

    local procedure GetBaseURL(): Text[50];
    var
        PayPalUrl: Text;
    begin
        PayPalUrl := GetTargetURL();
        exit(GetURLWithoutQueryParams(PayPalUrl));
    end;

    local procedure GetURLWithoutQueryParams(URL: Text) BaseURL: Text[50];
    var
        ParametersStartPosition: Integer;
    begin
        ParametersStartPosition := STRPOS(URL, '?');
        IF ParametersStartPosition > 0 THEN
            BaseURL := COPYSTR(DELSTR(URL, ParametersStartPosition), 1, MAXSTRLEN(BaseURL))
        ELSE
            BaseURL := COPYSTR(URL, 1, MAXSTRLEN(BaseURL));
    end;

    LOCAL PROCEDURE CreatePaymentRegistrationSetupForCurrentUser();
    VAR
        PaymentRegistrationSetup: Record 980;
    BEGIN
        IF PaymentRegistrationSetup.GET(USERID()) THEN BEGIN
            SendTraceTag('00008HA', PayPalTelemetryCategoryTok, Verbosity::Normal, PaymentRegistrationSetupAlreadyExistsTxt, DataClassification::SystemMetadata);
            EXIT;
        END;
        IF PaymentRegistrationSetup.GET() THEN BEGIN
            PaymentRegistrationSetup."User ID" := CopyStr(USERID(), 1, MaxStrLen(PaymentRegistrationSetup."User ID"));
            IF PaymentRegistrationSetup.INSERT(TRUE) THEN BEGIN
                SendTraceTag('00008HB', PayPalTelemetryCategoryTok, Verbosity::Normal, PaymentRegistrationSetupCreatedTxt, DataClassification::SystemMetadata);
                EXIT;
            END;
        END;
        SendTraceTag('00008HC', PayPalTelemetryCategoryTok, Verbosity::Warning, PaymentRegistrationSetupNotCreatedTxt, DataClassification::SystemMetadata);
    END;
}
