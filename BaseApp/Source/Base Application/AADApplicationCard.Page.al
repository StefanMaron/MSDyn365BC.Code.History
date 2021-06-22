page 9861 "AAD Application Card"
{
    Caption = 'AAD Application Card', Comment = 'AAD Application should not be translated';
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report';
    RefreshOnActivate = true;
    SourceTable = "AAD Application";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Client Id"; "Client Id")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Standard;
                    ToolTip = 'Specifies the client Id for the external App.';
                }
                field(Description; Description)
                {
                    ShowMandatory = true;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description.';
                }
                field(State; State)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Standard;
                    ToolTip = 'Specifies the state for the external App.';
                }

                field("Contact Information"; "Contact Information")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies contact information.';
                }
                group(Extension)
                {
                    field("App ID"; "App ID")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies App Id.';
                    }
                    field("App Name"; "App Name")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies App name.';
                    }
                }
            }

            part(UserGroups; "User Groups User SubPage")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Groups';
                SubPageLink = "User Security ID" = field("User ID");
                UpdatePropagation = Both;
            }
            part(Permissions; "User Subform")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Permission Sets';
                SubPageLink = "User Security ID" = field("User Id");
            }

        }
    }
    actions
    {
        area(Processing)
        {
            action(Consent)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Grant Consent';
                Image = Setup;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Enabled = not IsVEApp;
                Scope = Repeater;
                ToolTip = 'Grant consent for this application to access data from Business Central.';


                trigger OnAction()

                begin
                    GrantConsent();
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        AADApplicationSetup: Codeunit "AAD Application Setup";
    begin
        IsVEApp := LowerCase(GraphMgtGeneralTools.StripBrackets(Format(Rec."Client Id"))) = AADApplicationSetup.GetD365BCForVEAppId();
    end;

    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        CommonOAuthAuthorityUrlLbl: Label 'https://login.microsoftonline.com/common/adminconsent', Locked = true;
        ConsentFailedErr: Label 'Failed to give consent.';
        ConsentSuccessTxt: Label 'Consent was given successfully.';
        IsVEApp: Boolean;

    [NonDebuggable]
    [Scope('OnPrem')]
    local procedure GrantConsent();
    var
        OAuth2: Codeunit OAuth2;
        Success: Boolean;
        ErrorMsgTxt: Text;
    begin
        OAuth2.RequestClientCredentialsAdminPermissions(GraphMgtGeneralTools.StripBrackets(Format("Client Id")), CommonOAuthAuthorityUrlLbl, '', Success, ErrorMsgTxt);
        if not Success then
            if ErrorMsgTxt <> '' then
                Error(ErrorMsgTxt)
            else
                Error(ConsentFailedErr);
        Message(ConsentSuccessTxt);
    end;
}