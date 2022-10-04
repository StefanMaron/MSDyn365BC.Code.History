#if not CLEAN21
page 2338 "BC O365 Payments Settings"
{
    Caption = ' ';
    Editable = false;
    PageType = CardPart;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(Control5)
            {
                InstructionalText = 'You can change the default payment terms and payment instructions for each invoice. We will use payment terms to calculate the due date for you, whereas payment instructions will be displayed at the bottom of your invoices.';
                ShowCaption = false;
            }
            group(Control1)
            {
                ShowCaption = false;
                field(PaymentTermsCode; PaymentTermsCode)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Payment terms';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the default payment terms used, such as within 14 days.';

                    trigger OnAssistEdit()
                    var
                        TempO365PaymentTerms: Record "O365 Payment Terms" temporary;
                    begin
                        TempO365PaymentTerms.RefreshRecords();
                        if TempO365PaymentTerms.Get(PaymentTermsCode) then;
                        if PAGE.RunModal(PAGE::"O365 Payment Terms List", TempO365PaymentTerms) = ACTION::LookupOK then
                            O365SalesInitialSetup.UpdateDefaultPaymentTerms(TempO365PaymentTerms.Code);
                        UpdateFields();
                    end;
                }
            }
            group(Control6)
            {
                ShowCaption = false;
                field(PaymentInstructionsShortName; PaymentInstructionsShortName)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Payment instructions';
                    Importance = Promoted;

                    trigger OnAssistEdit()
                    var
                        O365PaymentInstructions: Record "O365 Payment Instructions";
                    begin
                        O365PaymentInstructions.SetRange(Default, true);
                        O365PaymentInstructions.FindFirst();
                        O365PaymentInstructions.Get(O365PaymentInstructions.Id);
                        O365PaymentInstructions.SetRange(Default);

                        if PAGE.RunModal(PAGE::"BC O365 Payment Instr. List", O365PaymentInstructions) = ACTION::LookupOK then begin
                            O365PaymentInstructions.Validate(Default, true);
                            O365PaymentInstructions.Modify(true);
                        end;
                        UpdateFields();
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
        UpdateFields();
    end;

    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        PaymentTermsCode: Code[10];
        PaymentInstructionsShortName: Text;

    local procedure UpdateFields()
    var
        O365PaymentInstructions: Record "O365 Payment Instructions";
    begin
        O365SalesInitialSetup.Get();
        PaymentTermsCode := O365SalesInitialSetup."Default Payment Terms Code";

        O365PaymentInstructions.SetRange(Default, true);
        if O365PaymentInstructions.FindFirst() then
            PaymentInstructionsShortName := O365PaymentInstructions.GetNameInCurrentLanguage();
    end;
}
#endif
