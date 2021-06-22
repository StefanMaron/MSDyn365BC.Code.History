page 2321 "BC O365 Payment Method Card"
{
    Caption = 'Payment Method';
    LinksAllowed = false;
    PageType = Card;

    layout
    {
        area(content)
        {
            group(Control4)
            {
                InstructionalText = 'Specify how the customer paid you.';
                ShowCaption = false;
                field(PaymentMethodCode; PaymentMethodCode)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Short name';
                    ToolTip = 'Specifies the short name of the payment method.';
                }
                field(PaymentMethodDescription; PaymentMethodDescription)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the payment method.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        PaymentMethodCode := PaymentMethod.Code;
        PaymentMethodDescription := CopyStr(PaymentMethod.GetDescriptionInCurrentLanguage, 1, MaxStrLen(PaymentMethodDescription));
        if PaymentMethodCode = '' then
            CurrPage.Caption := NewPaymentMethodTxt;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        PaymentMethodTranslation: Record "Payment Method Translation";
        LocalPaymentMethod: Record "Payment Method";
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        Language: Codeunit Language;
    begin
        if CloseAction = ACTION::LookupCancel then
            exit;

        if PaymentMethodCode = '' then
            Error(MustSpecifyCodeErr);

        // Clean up translation if description changed
        if (PaymentMethod.Description <> PaymentMethodDescription) and
           (PaymentMethod.Code <> '')
        then begin
            if PaymentMethodTranslation.Get(PaymentMethod.Code, Language.GetUserLanguageCode) then
                PaymentMethodTranslation.Delete(true);
        end;

        // Handle the code
        if not PaymentMethod.Get(PaymentMethod.Code) then begin
            if LocalPaymentMethod.Get(PaymentMethodCode) then
                Error(PaymentMethodAlreadyExistErr);
            PaymentMethod.Validate(Code, PaymentMethodCode);
            PaymentMethod.Validate("Use for Invoicing", true);
            PaymentMethod.Insert(true);
        end else
            if PaymentMethod.Code <> PaymentMethodCode then begin
                if LocalPaymentMethod.Get(PaymentMethodCode) then
                    Error(PaymentMethodAlreadyExistErr);
                PaymentMethod.Rename(PaymentMethodCode);
                if O365SalesInitialSetup.Get and (O365SalesInitialSetup."Default Payment Method Code" = PaymentMethodCode) then
                    O365SalesInitialSetup.UpdateDefaultPaymentMethod(PaymentMethodCode);
            end;

        // Handle the description
        if PaymentMethodDescription <> PaymentMethod.Description then begin
            PaymentMethodTranslation.SetRange("Payment Method Code", PaymentMethod.Code);
            PaymentMethodTranslation.DeleteAll();
            PaymentMethod.Validate(Description, PaymentMethodDescription);
            PaymentMethod.Modify(true);
        end;
    end;

    var
        PaymentMethod: Record "Payment Method";
        PaymentMethodDescription: Text[50];
        PaymentMethodCode: Code[10];
        PaymentMethodAlreadyExistErr: Label 'You already have a payment method with this name. Please use a different name.';
        MustSpecifyCodeErr: Label 'You must specify a short name for this payment method.';
        NewPaymentMethodTxt: Label 'New payment method.';

    procedure SetPaymentMethod(NewPaymentMethod: Record "Payment Method")
    begin
        PaymentMethod := NewPaymentMethod;
    end;
}

