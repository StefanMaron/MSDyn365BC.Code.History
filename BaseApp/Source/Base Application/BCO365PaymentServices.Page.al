page 2348 "BC O365 Payment Services"
{
    Caption = ' ';
    LinksAllowed = false;
    PageType = CardPart;
    RefreshOnActivate = true;
    ShowFilter = false;

    layout
    {
        area(content)
        {
            group(Control2)
            {
                InstructionalText = 'You can use an online service to manage payments. If you add a payment service, your invoices will include a link that your customers can use to pay you. We will then register the payment for you here.';
                ShowCaption = false;
            }
            group(Control8)
            {
                ShowCaption = false;
                Visible = ShowChoice;
                field(MsPayOrPaypalOption; MsPayOrPaypalOption)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Payment Service';

                    trigger OnValidate()
                    begin
                        if MsPayOrPaypalOption = MsPayOrPaypalOption::"Microsoft Pay Payments" then begin
                            O365SalesInvoicePayment.SetMspayDefault;
                            if Confirm(RemovePaypalSettingsQst) then
                                PaypalAccountProxy.SetPaypalAccount('', true);
                        end else
                            O365SalesInvoicePayment.SetPaypalDefault;

                        UpdateControls;
                        CurrPage.Update;
                    end;
                }
            }
            group(Control75)
            {
                ShowCaption = false;
            }
            group(Control85)
            {
                ShowCaption = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        // Currently the OnAfterGetCurrRecord trigger in the pageextension is not executed if the
        // trigger in the main page is empty.
    end;

    trigger OnInit()
    begin
        UpdateControls;
    end;

    var
        PaypalAccountProxy: Codeunit "Paypal Account Proxy";
        O365SalesInvoicePayment: Codeunit "O365 Sales Invoice Payment";
        MsPayOrPaypalOption: Option PayPal,"Microsoft Pay Payments";
        RemovePaypalSettingsQst: Label 'You can set up Paypal in Microsoft Pay Payments from your Business Profile. Do you want us to remove your Paypal setup from Invoicing?', Comment = '"Microsoft Pay Payments" should not be translated';
        ShowChoice: Boolean;
        PaymentServiceCategoryTxt: Label 'AL Payment Services', Locked = true;
        TooManyPaymServicesTelemetryMsg: Label 'Too many payment providers found: %1.', Locked = true;

    local procedure UpdateControls()
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        NumberOfPaymentServiceSetups: Integer;
        PaypalIsDefault: Boolean;
        PaypalIsEnabled: Boolean;
    begin
        PaypalAccountProxy.GetPaypalSetupOptions(PaypalIsEnabled, PaypalIsDefault);

        if PaypalIsDefault then
            MsPayOrPaypalOption := MsPayOrPaypalOption::PayPal
        else
            MsPayOrPaypalOption := MsPayOrPaypalOption::"Microsoft Pay Payments";

        TempPaymentServiceSetup.OnRegisterPaymentServices(TempPaymentServiceSetup);
        TempPaymentServiceSetup.SetRange(Enabled, true);
        NumberOfPaymentServiceSetups := TempPaymentServiceSetup.Count();
        if NumberOfPaymentServiceSetups > 2 then
            SendTraceTag('00001WJ', PaymentServiceCategoryTxt, VERBOSITY::Warning,
              StrSubstNo(TooManyPaymServicesTelemetryMsg, NumberOfPaymentServiceSetups), DATACLASSIFICATION::SystemMetadata);
        ShowChoice := NumberOfPaymentServiceSetups > 1;
    end;
}

