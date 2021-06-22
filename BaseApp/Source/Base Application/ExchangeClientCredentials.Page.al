page 1613 "Exchange Client Credentials"
{
    Caption = 'Application Client ID and Secret';
    PageType = StandardDialog;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    Extensible = false;

    layout
    {
        area(content)
        {
            label(SpecifyClientIdAndSecret)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Specify the ID, application secret and redirect URL of the Azure Active Directory application that will be used to connect to Exchange.', Comment = 'Exchange and Azure Active Directory are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';
            }
            field(ClientId; Name)
            {
                ApplicationArea = RelationshipMgmt;
                ExtendedDatatype = EMail;
                Caption = 'Client ID';
                ToolTip = 'Specifies the ID of the Azure Active Directory application that will be used to connect to Exchange.', Comment = 'Exchange and Azure Active Directory are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';
            }
            field(ClientSecret; Value)
            {
                ApplicationArea = RelationshipMgmt;
                ExtendedDatatype = Masked;
                Caption = 'Client Secret';
                ToolTip = 'Specifies the secret of the Azure Active Directory application that will be used to connect to Exchange.', Comment = 'Exchange and Azure Active Directory are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';
            }
            field(RedirectURL; "Value Long")
            {
                ApplicationArea = RelationshipMgmt;
                ExtendedDatatype = URL;
                Caption = 'Redirect URL';
                ToolTip = 'Specifies the redirect URL of the Azure Active Directory application that will be used to connect to Exchange.', Comment = 'Exchange and Azure Active Directory are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';
            }
        }
    }

    var
        EmptyClientIdErr: Label 'You must specify the Azure Active Directory ID.';
        EmptyClientSecretErr: Label 'You must specify the Azure Active Directory application secret.';

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::LookupOK, Action::OK] then begin
            if Name = '' then
                Error(EmptyClientIdErr);
            if Value = '' then
                Error(EmptyClientSecretErr);
        end;
    end;
}

