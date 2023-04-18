#if not CLEAN21
page 2343 "BC O365 Payment Instr. Card"
{
    Caption = 'Payment instructions';
    DataCaptionExpression = O365PaymentInstructions.Name;
    PageType = Card;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

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
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Short name';
                    ToolTip = 'Specifies a short description of the payment instructions.';
                }
            }
            field(PaymentInstructionsControl; PaymentInstructionsText)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Payment instructions';
                MultiLine = true;
                ToolTip = 'Specifies the payment instructions that will appear in the bottom of your invoices.';
            }
            field(DefaultControl; DefaultTxt)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Editable = false;
                Enabled = NOT IsDefault;
                ShowCaption = false;

                trigger OnDrillDown()
                begin
                    if NameText = '' then
                        Error(MustSpecifyNameErr);

                    SaveRecord();
                    O365PaymentInstructions.Validate(Default, true);
                    O365PaymentInstructions.Modify(true);
                    Session.LogMessage('00001SC', SetAsDefaultTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PaymentInstrCategoryLbl);
                    UpdateDefaultLabel();
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        PaymentInstructionsText := O365PaymentInstructions.GetPaymentInstructionsInCurrentLanguage();
        NameText := O365PaymentInstructions.GetNameInCurrentLanguage();

        UpdateDefaultLabel();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not (CloseAction in [ACTION::LookupOK, ACTION::OK]) then
            exit;

        if NameText = '' then
            Error(MustSpecifyNameErr);

        SaveRecord();
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
                Session.LogMessage('00001SD', NewRecordTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PaymentInstrCategoryLbl);
            end;
            Validate(Name, NameText);
            SetPaymentInstructions(PaymentInstructionsText);
            DeleteTranslationsForRecord();
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
#endif
