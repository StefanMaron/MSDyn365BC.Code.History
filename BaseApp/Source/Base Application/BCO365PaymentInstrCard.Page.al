page 2343 "BC O365 Payment Instr. Card"
{
    Caption = 'Payment instructions';
    DataCaptionExpression = O365PaymentInstructions.Name;
    PageType = Card;

    layout
    {
        area(content)
        {
            group(Control6)
            {
                ShowCaption = false;
                group(Control2)
                {
                    InstructionalText = 'Provide instructions to your customers on how you want to be paid. For the best result, use at most 300 characters.';
                    ShowCaption = false;
                }
                field(NameControl; NameText)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Short name';
                    ToolTip = 'Specifies a short description of the payment instructions.';
                }
            }
            field(PaymentInstructionsControl; PaymentInstructionsText)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Payment instructions';
                MultiLine = true;
                ToolTip = 'Specifies the payment instructions that will appear in the bottom of your invoices.';
            }
            field(DefaultControl; DefaultTxt)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Editable = false;
                Enabled = NOT IsDefault;
                ShowCaption = false;

                trigger OnDrillDown()
                begin
                    if NameText = '' then
                        Error(MustSpecifyNameErr);

                    SaveRecord;
                    O365PaymentInstructions.Validate(Default, true);
                    O365PaymentInstructions.Modify(true);
                    SendTraceTag('00001SC', PaymentInstrCategoryLbl, VERBOSITY::Normal, SetAsDefaultTelemetryTxt, DATACLASSIFICATION::SystemMetadata);
                    UpdateDefaultLabel;
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        PaymentInstructionsText := O365PaymentInstructions.GetPaymentInstructionsInCurrentLanguage;
        NameText := O365PaymentInstructions.GetNameInCurrentLanguage;

        UpdateDefaultLabel;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not (CloseAction in [ACTION::LookupOK, ACTION::OK]) then
            exit;

        if NameText = '' then
            Error(MustSpecifyNameErr);

        SaveRecord;
    end;

    var
        O365PaymentInstructions: Record "O365 Payment Instructions";
        PaymentInstructionsText: Text;
        NameText: Text[20];
        MustSpecifyNameErr: Label 'You must specify a name for these payment instructions.';
        SetAsDefaultLbl: Label 'Set as default payment instructions';
        DefaultTxt: Text;
        InstructionsAreDefaultTxt: Label 'These are the default payment instructions';
        IsDefault: Boolean;
        PaymentInstrCategoryLbl: Label 'AL Payment Instructions', Locked = true;
        SetAsDefaultTelemetryTxt: Label 'Default payment instructions changed.', Locked = true;
        NewRecordTelemetryTxt: Label 'New payment instructions inserted.', Locked = true;

    procedure SetPaymentInstructionsOnPage(NewO365PaymentInstructions: Record "O365 Payment Instructions")
    begin
        O365PaymentInstructions := NewO365PaymentInstructions;
    end;

    local procedure SaveRecord()
    begin
        with O365PaymentInstructions do begin
            if not Get(Id) then begin
                Insert(true);
                SendTraceTag('00001SD', PaymentInstrCategoryLbl, VERBOSITY::Normal, NewRecordTelemetryTxt, DATACLASSIFICATION::SystemMetadata);
            end;
            Validate(Name, NameText);
            SetPaymentInstructions(PaymentInstructionsText);
            DeleteTranslationsForRecord;
            Modify(true);
        end;
    end;

    local procedure UpdateDefaultLabel()
    begin
        if O365PaymentInstructions.Default then begin
            IsDefault := true;
            DefaultTxt := InstructionsAreDefaultTxt;
        end else
            DefaultTxt := SetAsDefaultLbl;
    end;

    procedure GetIsDefault(): Boolean
    begin
        exit(IsDefault);
    end;
}

