page 248 "VAT Registration Config"
{
    ApplicationArea = Basic, Suite;
    Caption = 'EU VAT Registration No. Validation Service Setup';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    PopulateAllFields = false;
    ShowFilter = false;
    SourceTable = "VAT Reg. No. Srv Config";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                InstructionalText = 'VAT Information Exchange System is an electronic means of validating VAT identification numbers of economic operators registered in the European Union for cross-border transactions on goods and services.';
                field(ServiceEndpoint; "Service Endpoint")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = NOT Enabled;
                    ToolTip = 'Specifies the endpoint of the VAT registration number validation service.';
                }
                field(Enabled; Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the service is enabled.';

                    trigger OnValidate()
                    begin
                        if Enabled = xRec.Enabled then
                            exit;

                        if Enabled then begin
                            TestField("Service Endpoint");
                            Message(TermsAndAgreementMsg);
                        end;
                    end;
                }
                field(TermsOfServiceLbl; TermsOfServiceLbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies a hyperlink to disclaimer information for the service.';

                    trigger OnDrillDown()
                    var
                        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
                    begin
                        HyperLink(VATRegistrationLogMgt.GetServiceDisclaimerUR);
                    end;
                }
                field(DefaultTemplate; Rec."Default Template Code")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = Rec.Enabled;
                    ToolTip = 'Specifies the default template for validation of additional company information.';
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            group(Action7)
            {
                Caption = 'General';
                action(SettoDefault)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Default Endpoint';
                    Image = Default;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Set the default URL in the Service Endpoint field.';

                    trigger OnAction()
                    var
                        VATLookupExtDataHndl: Codeunit "VAT Lookup Ext. Data Hndl";
                    begin
                        if Enabled then
                            if Confirm(DisableServiceQst) then
                                Enabled := false
                            else
                                exit;

                        "Service Endpoint" := VATLookupExtDataHndl.GetVATRegNrValidationWebServiceURL;
                        Modify(true);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        VATRegNoSrvTemplate: Record "VAT Reg. No. Srv. Template";
    begin
        if not Get() then
            InitVATRegNrValidationSetup();

        VATRegNoSrvTemplate.CheckInitDefaultTemplate(Rec);
    end;

    var
        DisableServiceQst: Label 'You must turn off the service while you set default values. Should we turn it off for you?';
        TermsAndAgreementMsg: Label 'You are accessing a third-party website and service. Review the disclaimer before you continue.';
        TermsOfServiceLbl: Label 'VAT registration service (VIES) disclaimer';

    local procedure InitVATRegNrValidationSetup()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        VATLookupExtDataHndl: Codeunit "VAT Lookup Ext. Data Hndl";
    begin
        if FindFirst then
            exit;

        Init;
        "Service Endpoint" := VATLookupExtDataHndl.GetVATRegNrValidationWebServiceURL;
        Enabled := not EnvironmentInfo.IsSaaS;
        Insert;
    end;
}

