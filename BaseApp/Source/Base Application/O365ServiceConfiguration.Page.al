page 2147 "O365 Service Configuration"
{
    Caption = 'Services';

    layout
    {
        area(content)
        {
            group("VAT Registration Service")
            {
                Caption = 'VAT Registration Service';
                group(Control2)
                {
                    Caption = 'VAT Registration Service';
                    field(ViesEnabled; VATRegNoSrvConfig.Enabled)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Enabled';
                        ToolTip = 'Specifies if the service is enabled.';

                        trigger OnValidate()
                        begin
                            if VATRegNoSrvConfig.Enabled then begin
                                VATRegNoSrvConfig.TestField("Service Endpoint");
                                Message(TermsAndAgreementMsg);
                            end;
                            VATRegNoSrvConfig.Modify(true);
                        end;
                    }
                    field(TermsOfServiceLbl; TermsOfServiceLbl)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        var
                            VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
                        begin
                            HyperLink(VATRegistrationLogMgt.GetServiceDisclaimerUR);
                        end;
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if not VATRegNoSrvConfig.FindFirst then
            InitVATRegNrValidationSetup;
    end;

    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        TermsAndAgreementMsg: Label 'You are accessing a third-party website and service. You should review the third-party''s terms and privacy policy before acquiring or using its website or service.';
        TermsOfServiceLbl: Label 'VAT registration service(VIES) disclaimer';

    local procedure InitVATRegNrValidationSetup()
    var
        VATLookupExtDataHndl: Codeunit "VAT Lookup Ext. Data Hndl";
    begin
        if VATRegNoSrvConfig.FindFirst then
            exit;

        VATRegNoSrvConfig.Init();
        VATRegNoSrvConfig."Service Endpoint" := VATLookupExtDataHndl.GetVATRegNrValidationWebServiceURL;
        VATRegNoSrvConfig.Enabled := true;
        VATRegNoSrvConfig.Insert();
    end;
}

