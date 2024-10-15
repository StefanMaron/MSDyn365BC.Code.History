#if not CLEAN17
page 11757 "Registration Config"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Reg. No. Validation Service Setup (Obsolete)';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    PopulateAllFields = false;
    ShowFilter = false;
    SourceTable = "Reg. No. Srv Config";
    UsageCategory = Administration;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                InstructionalText = 'Information Exchange System is an electronic means of validating identification numbers of economic operators registered in the Czech Republic for national transactions on goods and services.';
                field(ServiceEndpoint; "Service Endpoint")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = NOT Enabled;
                    ToolTip = 'Specifies the endpoint of the registration number validation service.';
                }
                field(Enabled; Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the service is enabled.';

                    trigger OnValidate()
                    var
                        CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
                    begin
                        if Enabled = xRec.Enabled then
                            exit;

                        if Enabled then begin
                            if not CustomerConsentMgt.ConfirmUserConsent() then begin
                                Rec.Enabled := false;
                                exit;
                            end;
                            TestField("Service Endpoint");
                            Message(TermsAndAgreementMsg);
                        end;
                    end;
                }
                field(ServiceConditionsLbl; ServiceConditionsLbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies a hyperlink to operating conditions of service';

                    trigger OnDrillDown()
                    var
                        RegistrationLogMgt: Codeunit "Registration Log Mgt.";
                    begin
                        HyperLink(RegistrationLogMgt.GetServiceConditionsURL);
                    end;
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
                        RegLookupExtDataHndl: Codeunit "Reg. Lookup Ext. Data Hndl";
                    begin
                        if Enabled then
                            if Confirm(DisableServiceQst) then
                                Enabled := false
                            else
                                exit;

                        "Service Endpoint" := RegLookupExtDataHndl.GetRegistrationNoValidationWebServiceURL;
                        Modify(true);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Get then
            InitRegNrValidationSetup
    end;

    var
        DisableServiceQst: Label 'You must turn off the service while you set default values. Should we turn it off for you?';
        TermsAndAgreementMsg: Label 'You are accessing a third-party website and service. Review the disclaimer before you continue.';
        ServiceConditionsLbl: Label 'Service operating conditions';

    local procedure InitRegNrValidationSetup()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        RegLookupExtDataHndl: Codeunit "Reg. Lookup Ext. Data Hndl";
    begin
        if FindFirst then
            exit;

        Init;
        "Service Endpoint" := RegLookupExtDataHndl.GetRegistrationNoValidationWebServiceURL;
        Enabled := not EnvironmentInfo.IsSaaS;
        Insert;
    end;
}


#endif