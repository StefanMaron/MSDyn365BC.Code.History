page 10692 "Electronic VAT Setup Card"
{
    PageType = Card;
    SourceTable = "Elec. VAT Setup";
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    Caption = 'Electronic VAT Setup';
    DataCaptionExpression = '';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Enabled; Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the electronic VAT declaration feature is enabled.';
                }
                field(ClientID; ClientID)
                {
                    Caption = 'Client ID';
                    ToolTip = 'Specifies the client ID token.';
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = Masked;

                    trigger OnValidate()
                    begin
                        ElecVATOAuthMgt.SetToken("Client ID", ClientID, DataScope::Company);
                        ClientID := "Client ID";
                        ElecVATOAuthMgt.UpdateElecVATOAuthSetupRecordsWithClientIDAndSecret("Client ID", "Client Secret")
                    end;
                }
                field(ClientSecret; ClientSecret)
                {
                    Caption = 'Client Secret';
                    ToolTip = 'Specifies the client secret token.';
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = Masked;

                    trigger OnValidate()
                    begin
                        ElecVATOAuthMgt.SetToken("Client Secret", ClientSecret, DataScope::Company);
                        ClientSecret := "Client Secret";
                        ElecVATOAuthMgt.UpdateElecVATOAuthSetupRecordsWithClientIDAndSecret("Client ID", "Client Secret")
                    end;
                }
                field("Redirect URL"; "Redirect URL")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the redirect URL.';
                }
                field("Validate VAT Return Url"; "Validate VAT Return Url")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the URL to validate VAT return.';
                }
                field("Exchange ID-Porten Token Url"; "Exchange ID-Porten Token Url")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the URL to exchange the access token with the Altinn token.';
                }
                field("Submission Environment URL"; "Submission Environment URL")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the URL for the submission environment.';
                }
                field("Submission App URL"; "Submission App URL")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the URL for the submission app.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(OpenOAuthSetup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open OAuth 2.0 setup page';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Opens the OAuth 2.0 setup for the current user.';

                trigger OnAction()
                var
                    ElecVATOAuthMgt: Codeunit "Elec. VAT OAuth Mgt.";
                begin
                    ElecVATOAuthMgt.OpenOAuthSetupPage();
                end;
            }
        }
    }
    var
        ElecVATOAuthMgt: Codeunit "Elec. VAT OAuth Mgt.";
        [NonDebuggable]
        ClientID: Text;
        [NonDebuggable]
        ClientSecret: Text;

    trigger OnOpenPage()
    begin
        ClientID := "Client ID";
        ClientSecret := "Client Secret";
    end;
}
