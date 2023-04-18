#if not CLEAN21
page 2320 "BC O365 Payment Terms Card"
{
    Caption = 'Payment Terms';
    LinksAllowed = false;
    PageType = Card;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(Control4)
            {
                InstructionalText = 'Specify when payment is due for invoices that use this payment term.';
                ShowCaption = false;
                field(PaymentTermsCode; PaymentTermsCode)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Short name';
                    ToolTip = 'Specifies the short name of the payment term.';
                }
                field(Days; Days)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Days';
                    ToolTip = 'Specifies the number of days until payments are due when this payment term is used.';

                    trigger OnValidate()
                    begin
                        if Days < 0 then
                            Error(DaysMustBePositiveErr);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Days := CalcDate(PaymentTerms."Due Date Calculation", Today) - Today;
        PaymentTermsCode := PaymentTerms.Code;
        if PaymentTermsCode = '' then
            CurrPage.Caption := NewPaymentTermTxt;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        LocalPaymentTerms: Record "Payment Terms";
        PaymentTermTranslation: Record "Payment Term Translation";
        DateFormula: DateFormula;
    begin
        if CloseAction = ACTION::LookupCancel then
            exit;

        if PaymentTermsCode = '' then
            Error(MustSpecifyCodeErr);

        // Handle the code
        if not PaymentTerms.Get(PaymentTerms.Code) then begin
            if LocalPaymentTerms.Get(PaymentTermsCode) then
                Error(PaymentTermsAlreadyExistErr);
            PaymentTerms.Code := PaymentTermsCode;
            PaymentTerms.Description := PaymentTermsCode;
            PaymentTerms.Insert(true);
        end else
            if PaymentTerms.Code <> PaymentTermsCode then begin
                if LocalPaymentTerms.Get(PaymentTermsCode) then
                    Error(PaymentTermsAlreadyExistErr);
                PaymentTermTranslation.SetRange("Payment Term", PaymentTerms.Code);
                PaymentTermTranslation.DeleteAll();
                PaymentTerms.Rename(PaymentTermsCode);
                PaymentTerms.Description := PaymentTermsCode;
                if O365SalesInitialSetup.Get() and (O365SalesInitialSetup."Default Payment Terms Code" = PaymentTermsCode) then
                    O365SalesInitialSetup.UpdateDefaultPaymentTerms(PaymentTermsCode);
            end;

        // Handle the date
        Evaluate(DateFormula, StrSubstNo(DayDueDateCalculationTxt, Days));
        PaymentTerms.Validate("Due Date Calculation", DateFormula);
        PaymentTerms.Modify(true);
    end;

    var
        PaymentTerms: Record "Payment Terms";
        Days: Integer;
        DayDueDateCalculationTxt: Label '<%1D>', Locked = true;
        PaymentTermsCode: Code[10];
        PaymentTermsAlreadyExistErr: Label 'You already have payment terms with this name. Please use a different name.';
        DaysMustBePositiveErr: Label 'Please specify 0 or more days. If you want to be paid immediately, then set the number of days to 0.';
        MustSpecifyCodeErr: Label 'You must specify a short name for these payment terms.';
        NewPaymentTermTxt: Label 'New payment term';

    procedure SetPaymentTerms(NewPaymentTerms: Record "Payment Terms")
    begin
        PaymentTerms := NewPaymentTerms;
    end;
}
#endif
