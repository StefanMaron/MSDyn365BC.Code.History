// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

using Microsoft.Intercompany.Partner;

page 565 "CrossIntercompany Modify Setup"
{
    ApplicationArea = Intercompany;
    Caption = 'Intercompany External Setup';
    PageType = StandardDialog;
    SourceTable = "IC Partner";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(DataExchangeInformation)
            {
                ShowCaption = false;

                field("Code"; Rec.Code)
                {
                    Caption = 'IC Partner Code';
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the intercompany partner code.';
                    Enabled = false;
                    Editable = false;
                }
                field(ConnectionUrl; ConnectionUrl)
                {
                    Caption = 'IC Partner''s Connection URL';
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ToolTip = 'Specifies the connection URL for the intercompany partner''s environment.';
                }
                field(CompanyId; CompanyId)
                {
                    Caption = 'IC Partner''s Company ID';
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ToolTip = 'Specifies the intercompany partner''s company ID in their environment.';
                }
                field(ClientId; ClientId)
                {
                    Caption = 'Client ID';
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ToolTip = 'Specifies the client ID of the Microsoft Entra authentication application.';
                }
                field(ClientSecret; ClientSecret)
                {
                    Caption = 'Client Secret';
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the client secret of the Microsoft Entra authentication application.';
                }
                field(TokenEndpoint; TokenEndpoint)
                {
                    Caption = 'Token Endpoint';
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ToolTip = 'Specifies the OAuth 2.0 token endpoint of the Microsoft Entra authentication application.';
                }
                field(RedirectUrl; RedirectUrl)
                {
                    Caption = 'Redirect URL';
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ToolTip = 'Specifies the OAuth 2.0 redirect URL of the Microsoft Entra authentication application.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TestConnection)
            {
                ApplicationArea = Intercompany;
                Caption = 'Test Connection';
                ToolTip = 'Test the connection to the partner''s company to check whether authentication is correctly set up.';
                Image = InteractionTemplateSetup;
                trigger OnAction()
                var
                    CrossIntercompanyConnector: Codeunit "CrossIntercompany Connector";
                begin
                    if CrossIntercompanyConnector.TestICPartnerSetup(Rec) then
                        Message(SuccesfulConnectionMsg)
                    else
                        Message(FailedConnectionErr);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        PopulatePartnerSensibleDetails();
    end;

    var
        [NonDebuggable]
        ConnectionUrl, ClientSecret, TokenEndpoint, RedirectUrl : Text;
        [NonDebuggable]
        CompanyId, ClientId : Guid;
        SuccesfulConnectionMsg: Label 'Connection to the partner''s company was successful.';
        FailedConnectionErr: Label 'Connection to the partner''s company failed.';

    [NonDebuggable]
    local procedure PopulatePartnerSensibleDetails()
    var
        ICPartnerChangeMonitor: Codeunit "IC Partner Change Monitor";
    begin
        ICPartnerChangeMonitor.CheckHasPermissionsToChangeSensitiveFields();

        ConnectionUrl := Rec.GetSecret(Rec."Connection Url Key");
        if Rec.GetSecret(Rec."Company Id Key") <> '' then
            CompanyId := Rec.GetSecret(Rec."Company Id Key");
        if Rec.GetSecret(Rec."Client Id Key") <> '' then
            ClientId := Rec.GetSecret(Rec."Client Id Key");
        ClientSecret := Rec.GetSecret(Rec."Client Secret Key");
        TokenEndpoint := Rec.GetSecret(Rec."Token Endpoint Key");
        RedirectUrl := Rec.GetSecret(Rec."Redirect Url Key");
    end;
}
