#if not CLEAN21
page 2117 "O365 Mark As Paid"
{
    Caption = 'Register payment';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = StandardDialog;
    ShowFilter = false;
    SourceTable = "Payment Registration Buffer";
    SourceTableTemporary = true;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'Payment';
                InstructionalText = 'What is the payment amount received?';
                field(AmountReceived; TempPaymentRegistrationBuffer."Amount Received")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Amount Received';
                    ToolTip = 'Specifies the payment received.';

                    trigger OnValidate()
                    begin
                        if TempPaymentRegistrationBuffer."Amount Received" < 0 then begin
                            TempPaymentRegistrationBuffer."Amount Received" := 0;
                            Message(AmountReceivedSettoZeroMsg);
                        end;
                        TempPaymentRegistrationBuffer.Validate("Amount Received");
                        AmountModified := true;
                    end;
                }
                field(PaymentMethod; PaymentMethodCode)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Payment Method';
                    Editable = false;
                    TableRelation = "Payment Method";
                    ToolTip = 'Specifies how payment was made.';

                    trigger OnAssistEdit()
                    var
                        TempO365PaymentMethod: Record "O365 Payment Method" temporary;
                        PaymentMethod: Record "Payment Method";
                    begin
                        TempO365PaymentMethod.RefreshRecords();
                        if TempO365PaymentMethod.Get(PaymentMethodCode) then;
                        if PAGE.RunModal(PAGE::"O365 Payment Method List", TempO365PaymentMethod) = ACTION::LookupOK then
                            PaymentMethodCode := TempO365PaymentMethod.Code;
                        if not PaymentMethod.Get(PaymentMethodCode) then
                            Error(PaymentMethodDoesNotExistErr);
                    end;
                }
            }
            group("Payment Date")
            {
                Caption = 'Payment Date';
                InstructionalText = 'When was the payment amount received?';
                field(DateReceived; TempPaymentRegistrationBuffer."Date Received")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Date Received';
                    Importance = Additional;
                    ToolTip = 'Specifies the date the payment is received.';

                    trigger OnValidate()
                    var
                        SalesInvoiceHeader: Record "Sales Invoice Header";
                    begin
                        if SalesInvoiceHeader.Get(TempPaymentRegistrationBuffer."Document No.") then
                            if TempPaymentRegistrationBuffer."Date Received" < SalesInvoiceHeader."Posting Date" then begin
                                TempPaymentRegistrationBuffer."Date Received" := SalesInvoiceHeader."Posting Date";
                                Message(DateReceivedHasBeenSetToPostingDateMsg);
                            end;
                        TempPaymentRegistrationBuffer.Validate("Date Received");
                    end;
                }
            }
            group("Outstanding Amount")
            {
                Caption = 'Outstanding Amount';
                field(AmountBefore; TempPaymentRegistrationBuffer."Rem. Amt. after Discount")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = '1';
                    AutoFormatType = 10;
                    Caption = 'Before Payment';
                    Editable = false;
                    ToolTip = 'Specifies the amount that still needs to be paid.';
                }
                field(AmountAfter; TempPaymentRegistrationBuffer."Remaining Amount")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = '1';
                    AutoFormatType = 10;
                    Caption = 'After Payment';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the amount that has not been paid.';
                }
            }
            part(SalesHistoryListPart; "O365 Payment History ListPart")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Visible = SalesHistoryHasEntries;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        RefreshPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);

        SetPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);
        if O365SalesInitialSetup.Get() then
            PaymentMethodCode := O365SalesInitialSetup."Default Payment Method Code";
    end;

    trigger OnOpenPage()
    begin
        SetDefaultDate();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        PaymentMethod: Record "Payment Method";
    begin
        if CloseAction <> ACTION::OK then
            exit;

        if not PaymentMethod.Get(PaymentMethodCode) then
            Error(PaymentMethodDoesNotExistErr);

        TempPaymentRegistrationBuffer.Validate("Payment Method Code", PaymentMethodCode);
        TempPaymentRegistrationBuffer.Modify(true);
        if TempPaymentRegistrationBuffer."Amount Received" = 0 then
            Error(MustSpecifyAmountErr);

        O365SalesInitialSetup.UpdateDefaultPaymentMethod(PaymentMethodCode);
    end;

    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        SalesHistoryHasEntries: Boolean;
        MustSpecifyAmountErr: Label 'Specify the amount received.';
        AmountReceivedSettoZeroMsg: Label 'Negative amounts are not allowed, so we set it to zero. Update the amount again.';
        DateReceivedHasBeenSetToPostingDateMsg: Label 'The received date is earlier than the date the invoice was sent, so we set the date to when it was sent.';
        AmountModified: Boolean;
        PaymentMethodCode: Code[10];
        PaymentMethodDoesNotExistErr: Label 'The specified payment method does not exist, please select another payment method.';

    [Scope('OnPrem')]
    procedure SetPaymentRegistrationBuffer(var NewTempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary)
    begin
        TempPaymentRegistrationBuffer.Copy(NewTempPaymentRegistrationBuffer, true);
        SalesHistoryHasEntries :=
          CurrPage.SalesHistoryListPart.PAGE.ShowHistory(TempPaymentRegistrationBuffer."Document No.");
    end;

    procedure RefreshPaymentRegistrationBuffer(var InTempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary)
    var
        NewPaymentRegistrationBuffer: Record "Payment Registration Buffer";
        O365SalesInvoicePayment: Codeunit "O365 Sales Invoice Payment";
    begin
        O365SalesInvoicePayment.CalculatePaymentRegistrationBuffer(
          InTempPaymentRegistrationBuffer."Document No.", NewPaymentRegistrationBuffer);

        if (not AmountModified) or
           (InTempPaymentRegistrationBuffer."Rem. Amt. after Discount" <> NewPaymentRegistrationBuffer."Rem. Amt. after Discount")
        then begin
            NewPaymentRegistrationBuffer.Validate("Payment Method Code", InTempPaymentRegistrationBuffer."Payment Method Code");
            NewPaymentRegistrationBuffer.Validate("Date Received", InTempPaymentRegistrationBuffer."Date Received");

            InTempPaymentRegistrationBuffer.Copy(NewPaymentRegistrationBuffer);
        end;
    end;

    local procedure SetDefaultDate()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if SalesInvoiceHeader.Get(TempPaymentRegistrationBuffer."Document No.") then
            if TempPaymentRegistrationBuffer."Date Received" < SalesInvoiceHeader."Posting Date" then
                TempPaymentRegistrationBuffer.Validate("Date Received", SalesInvoiceHeader."Posting Date");
    end;
}
#endif
