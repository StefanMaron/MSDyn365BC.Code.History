page 2347 "BC O365 Service Settings"
{
    Caption = ' ';
    PageType = CardPart;

    layout
    {
        area(content)
        {
            group(Control4)
            {
                ShowCaption = false;
                field(ViesEnabled; VATRegNoSrvConfig.Enabled)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'VAT registration service';
                    Importance = Promoted;
                    ToolTip = 'Specifies if the service is enabled.';

                    trigger OnValidate()
                    begin
                        if VATRegNoSrvConfig.Enabled then
                            VATRegNoSrvConfig.TestField("Service Endpoint");

                        VATRegNoSrvConfig.Modify(true);
                    end;
                }
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

