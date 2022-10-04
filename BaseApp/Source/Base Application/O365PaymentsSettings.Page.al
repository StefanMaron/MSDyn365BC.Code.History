#if not CLEAN21
page 2138 "O365 Payments Settings"
{
    Caption = 'Payments';
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group("Payment terms")
            {
                Caption = 'Payment terms';
                InstructionalText = 'Select the payment terms to specify when and how the customer must pay the total amount.';
                group(Control5)
                {
                    InstructionalText = 'You can change payment terms and method for each invoice.';
                    ShowCaption = false;
                }
                field(PaymentTermsCode; PaymentTermsCode)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Payment terms';
                    QuickEntry = false;
                    TableRelation = "Payment Terms" WHERE("Discount %" = CONST(0));
                    ToolTip = 'Specifies the payment terms that you select from on customer cards to define when the customer must pay, such as within 14 days.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        O365PaymentTerms: Record "O365 Payment Terms";
                        CloseAction: Action;
                    begin
                        CloseAction := PAGE.RunModal(PAGE::"O365 Payment Terms List", O365PaymentTerms);
                        if CloseAction <> ACTION::LookupOK then
                            exit;

                        PaymentTermsCode := O365PaymentTerms.Code;
                    end;
                }
                field(PaymentMethodCode; PaymentMethodCode)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Payment method';
                    QuickEntry = false;
                    TableRelation = "Payment Method" WHERE("Use for Invoicing" = CONST(true));
                    ToolTip = 'Specifies the payment methods that you select from on customer cards to define how the customer must pay, such as bank transfer.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        O365PaymentMethod: Record "O365 Payment Method";
                        CloseAction: Action;
                    begin
                        CloseAction := PAGE.RunModal(PAGE::"O365 Payment Method List", O365PaymentMethod);
                        if CloseAction <> ACTION::LookupOK then
                            exit;

                        PaymentMethodCode := O365PaymentMethod.Code;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        Intialize();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        O365SalesInitialSetup.Get();
        if PaymentTermsCode <> O365SalesInitialSetup."Default Payment Terms Code" then
            O365SalesInitialSetup.UpdateDefaultPaymentTerms(PaymentTermsCode);

        if PaymentMethodCode <> O365SalesInitialSetup."Default Payment Method Code" then
            O365SalesInitialSetup.UpdateDefaultPaymentMethod(PaymentMethodCode);
    end;

    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        PaymentTermsCode: Code[10];
        PaymentMethodCode: Code[10];

    local procedure Intialize()
    begin
        O365SalesInitialSetup.Get();
        PaymentTermsCode := O365SalesInitialSetup."Default Payment Terms Code";
        PaymentMethodCode := O365SalesInitialSetup."Default Payment Method Code";
    end;
}
#endif
