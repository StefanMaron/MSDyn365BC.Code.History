page 1060 "Payment Services"
{
    AdditionalSearchTerms = 'paypal,microsoft pay payments,worldpay,online payment';
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Services';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Payment Service Setup";
    SourceTableTemporary = true;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the payment service.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the payment service.';
                }
                field(Enabled; Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the payment service is enabled.';
                }
                field("Always Include on Documents"; "Always Include on Documents")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the payment service is always available in the Payment Service field on outgoing sales documents.';
                }
                field("Terms of Service"; "Terms of Service")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a link to the Terms of Service page for the payment service.';

                    trigger OnDrillDown()
                    begin
                        TermsOfServiceDrillDown;
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(NewAction)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New';
                Image = NewDocument;
                Promoted = true;
                PromotedCategory = New;
                PromotedIsBig = true;
                ToolTip = 'Add a payment service (such as PayPal) on the application that lets customers make online payments for sales orders and invoices.';

                trigger OnAction()
                begin
                    if NewPaymentService then begin
                        Reset;
                        DeleteAll();
                        OnRegisterPaymentServices(Rec);
                    end;
                end;
            }
            action(Setup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Setup';
                Enabled = SetupEditable;
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Change the payment service setup.';

                trigger OnAction()
                begin
                    OpenSetupCard;
                    Reset;
                    DeleteAll();
                    OnRegisterPaymentServices(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateSetupEditable;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.Update;
    end;

    trigger OnOpenPage()
    var
        TempPaymentServiceSetupProviders: Record "Payment Service Setup" temporary;
    begin
        OnRegisterPaymentServices(Rec);
        OnRegisterPaymentServiceProviders(TempPaymentServiceSetupProviders);
        if TempPaymentServiceSetupProviders.IsEmpty then
            Error(NoServicesInstalledErr);
    end;

    var
        NoServicesInstalledErr: Label 'No payment service extension has been installed.';
        SetupEditable: Boolean;

    local procedure UpdateSetupEditable()
    begin
        SetupEditable := not IsEmpty;
    end;
}

