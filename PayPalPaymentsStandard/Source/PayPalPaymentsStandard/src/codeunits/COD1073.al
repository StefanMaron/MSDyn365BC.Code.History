codeunit 1073 "MS - PayPal Webhook Management"
{
    Permissions = TableData 2000000199 = rimd;
    TableNo = 2000000194;

    trigger OnRun();
    var
        MSPayPalTransactionsMgt: Codeunit 1075;
        InvoiceNo: Text;
        InvoiceNoCode: Code[20];
        TotalAmount: Decimal;
    begin
        IF MSPayPalTransactionsMgt.ValidateNotification(Rec, InvoiceNo, TotalAmount) THEN BEGIN
            InvoiceNoCode := COPYSTR(InvoiceNo, 1, MAXSTRLEN(InvoiceNoCode));
            if not PostPaymentForInvoice(InvoiceNoCode, TotalAmount) then begin
                SendTraceTag('00008IH', PayPalTelemetryCategoryTok, VERBOSITY::Warning, PaymentRegistrationFailedTxt, DataClassification::SystemMetadata);
                exit;
            end;
            SENDTRACETAG('00001V8', PayPalTelemetryCategoryTok, VERBOSITY::Normal, MerchantsCustomerPaidTxt, DataClassification::SystemMetadata);
        END;
    end;

    var
        PayPalCreatedByTok: Label 'PAYPAL.COM', Locked = true;
        PayPalTelemetryCategoryTok: Label 'AL Paypal', Locked = true;
        MerchantsCustomerPaidTxt: Label 'The payment of the merchant''s customer was successfully processed.', Locked = true;
        ProcessingPaymentInBackgroundSessionTxt: Label 'Processing payment in a background session.', Locked = true;
        ProcessingPaymentInCurrentSessionTxt: Label 'Processing payment in the current session.', Locked = true;
        WebhookSubscriptionNotFoundTxt: Label 'Webhook subscription is not found.', Locked = true;
        NonPayPalPaymentTxt: Label 'The payment is ignored because it is not recognized as a PayPal payment.', Locked = true;
        NoRemainingPaymentsTxt: Label 'The payment is ignored because no payment remains.', Locked = true;
        OverpaymentTxt: Label 'The payment is ignored because of overpayment.', Locked = true;
        ProcessingWebhookNotificationTxt: Label 'Processing webhook notification.', Locked = true;
        RegisteringPaymentTxt: Label 'Registering the payment.', Locked = true;
        PaymentRegistrationFailedTxt: Label 'Payment registration failed.', Locked = true;
        PaymentRegistrationSucceedTxt: Label 'Payment registration succeed.', Locked = true;

    [EventSubscriber(ObjectType::Table, 2000000194, 'OnAfterInsertEvent', '', false, false)]
    local procedure SyncToNavOnWebhookNotificationInsert(var Rec: Record 2000000194; RunTrigger: Boolean);
    var
        WebhookSubscription: Record 2000000199;
        WebhookManagement: Codeunit 5377;
        AccountID: Text[250];
        WebHooksAdapterUri: Text[250];
        BackgroundSessionAllowed: Boolean;
    begin
        SendTraceTag('00008IP', PayPalTelemetryCategoryTok, VERBOSITY::Normal, ProcessingWebhookNotificationTxt, DataClassification::SystemMetadata);

        AccountID := LOWERCASE(Rec."Subscription ID");
        WebHooksAdapterUri := LOWERCASE(WebhookManagement.GetNotificationUrl());
        IF NOT WebhookSubscription.GET(AccountID, WebHooksAdapterUri) THEN BEGIN
            SendTraceTag('00008GK', PayPalTelemetryCategoryTok, VERBOSITY::Normal, WebhookSubscriptionNotFoundTxt, DataClassification::SystemMetadata);
            EXIT;
        END;

        IF STRPOS(WebhookSubscription."Created By", PayPalCreatedByTok) = 0 THEN BEGIN
            SendTraceTag('00008GL', PayPalTelemetryCategoryTok, VERBOSITY::Normal, NonPayPalPaymentTxt, DataClassification::SystemMetadata);
            EXIT;
        END;

        BackgroundSessionAllowed := TRUE;
        OnBeforeRunPayPalNotificationBackgroundSession(BackgroundSessionAllowed);

        IF BackgroundSessionAllowed THEN BEGIN
            SendTraceTag('00008GM', PayPalTelemetryCategoryTok, VERBOSITY::Normal, ProcessingPaymentInBackgroundSessionTxt, DataClassification::SystemMetadata);
            TASKSCHEDULER.CREATETASK(CODEUNIT::"MS - PayPal Webhook Management", 0, TRUE, COMPANYNAME(), CURRENTDATETIME() + 200, Rec.RECORDID())
        END ELSE BEGIN
            SendTraceTag('00008GN', PayPalTelemetryCategoryTok, VERBOSITY::Normal, ProcessingPaymentInCurrentSessionTxt, DataClassification::SystemMetadata);
            CODEUNIT.RUN(CODEUNIT::"MS - PayPal Webhook Management", Rec);
        END;

        COMMIT();
    end;

    procedure GetCreatedByFilterForWebhooks(): Text;
    begin
        exit('@*' + PayPalCreatedByTok + '*');
    end;

    local procedure PostPaymentForInvoice(InvoiceNo: Code[20]; AmountReceived: Decimal): Boolean;
    var
        TempPaymentRegistrationBuffer: Record 981 temporary;
        PaymentMethod: Record 289;
        PaymentRegistrationMgt: Codeunit 980;
        O365SalesInvoicePayment: Codeunit 2105;
        MSPayPalStandardMgt: Codeunit 1070;
    begin
        IF NOT O365SalesInvoicePayment.CollectRemainingPayments(InvoiceNo, TempPaymentRegistrationBuffer) THEN BEGIN
            SendTraceTag('00008GO', PayPalTelemetryCategoryTok, VERBOSITY::Normal, NoRemainingPaymentsTxt, DataClassification::SystemMetadata);
            EXIT(FALSE);
        END;

        IF TempPaymentRegistrationBuffer."Remaining Amount" >= AmountReceived THEN BEGIN
            SendTraceTag('00008GP', PayPalTelemetryCategoryTok, VERBOSITY::Normal, RegisteringPaymentTxt, DataClassification::SystemMetadata);
            TempPaymentRegistrationBuffer.VALIDATE("Amount Received", AmountReceived);
            TempPaymentRegistrationBuffer.VALIDATE("Date Received", WORKDATE());
            MSPayPalStandardMgt.GetPayPalPaymentMethod(PaymentMethod);
            TempPaymentRegistrationBuffer.VALIDATE("Payment Method Code", PaymentMethod.Code);
            TempPaymentRegistrationBuffer.MODIFY(TRUE);
            PaymentRegistrationMgt.Post(TempPaymentRegistrationBuffer, FALSE);
            OnAfterPostPayPalPayment(TempPaymentRegistrationBuffer, AmountReceived);
            SendTraceTag('00008IG', PayPalTelemetryCategoryTok, VERBOSITY::Normal, PaymentRegistrationSucceedTxt, DataClassification::SystemMetadata);
            EXIT(TRUE);
        END;

        SendTraceTag('00008GQ', PayPalTelemetryCategoryTok, VERBOSITY::Normal, OverpaymentTxt, DataClassification::SystemMetadata);
        OnAfterReceivePayPalOverpayment(TempPaymentRegistrationBuffer, AmountReceived);

        EXIT(FALSE);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPayPalPayment(var TempPaymentRegistrationBuffer: Record 981 temporary; AmountReceived: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReceivePayPalOverpayment(var TempPaymentRegistrationBuffer: Record 981 temporary; AmountReceived: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunPayPalNotificationBackgroundSession(var AllowBackgroundSessions: Boolean);
    begin
    end;

}


