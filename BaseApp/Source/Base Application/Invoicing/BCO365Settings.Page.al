#if not CLEAN21
page 2315 "BC O365 Settings"
{
    Caption = 'Configure Invoicing';
    PageType = Card;
    RefreshOnActivate = true;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(Control14)
            {
                ShowCaption = false;
                part(GraphMailPage; "BC O365 Graph Mail Settings")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Email account';
                    UpdatePropagation = Both;
                }
            }
#if not CLEAN20
            group(Control15)
            {
                ShowCaption = false;
                Visible = false;
                ObsoleteReason = 'Empty group';
                ObsoleteState = Pending;
                ObsoleteTag = '20.0';

                part(SmtpMailPage; "Email Scenarios FactBox") // Original part has been removed, Email Scenarios Factbox as dummy and part is not visible
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Email account';
                    UpdatePropagation = Both;
                    Visible = false;
                    ObsoleteReason = 'Part has been removed.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '20.0';
                }
            }
#endif
            part("Email settings"; "BC O365 Email Settings Part")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Email settings';
            }
            part("Invoice and estimate numbers"; "BC O365 No. Series Settings")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Invoice and estimate numbers';
            }
            part(Payments; "BC O365 Payments Settings")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Payments';
            }
            part("Payment instructions"; "BC O365 Payment Instr Settings")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Payment instructions';
            }
            part("Payment services"; "BC O365 Payment Services")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Payment services';
                UpdatePropagation = Both;
                Visible = PaymentServicesVisible;
            }
            part("VAT rates"; "BC O365 VAT Posting Setup List")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'VAT rates';
            }
            part("VAT registration no."; "BC O365 Business Info Settings")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'VAT registration no.';
            }
            part(Services; "BC O365 Service Settings")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Services';
            }
            part("Intuit QuickBooks"; "BC O365 Quickbooks Settings")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Intuit QuickBooks';
                Visible = QuickBooksVisible;
                ObsoleteState = Pending;
                ObsoleteReason = 'Quickbooks integration to Invoicing is discontinued.';
                ObsoleteTag = '17.0';
            }
            group(Control11)
            {
                ShowCaption = false;
                group(Share)
                {
                    Caption = 'Share';
                    InstructionalText = 'Share an overview of sent invoices in an email.';
                    field(ExportInvoices; ExportInvoicesLbl)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            PAGE.RunModal(PAGE::"O365 Export Invoices");
                        end;
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
    begin
        TempPaymentServiceSetup.OnRegisterPaymentServiceProviders(TempPaymentServiceSetup);
        PaymentServicesVisible := not TempPaymentServiceSetup.IsEmpty();

        QuickBooksVisible := O365SalesManagement.GetQuickBooksVisible();
    end;

    var
        O365SalesManagement: Codeunit "O365 Sales Management";
        PaymentServicesVisible: Boolean;
        ExportInvoicesLbl: Label 'Send invoice overview';
        QuickBooksVisible: Boolean;
}
#endif
