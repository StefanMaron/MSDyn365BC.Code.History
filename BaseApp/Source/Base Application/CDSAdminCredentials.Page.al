page 7202 "CDS Admin Credentials"
{
    Caption = 'Common Data Service Administrator Credentials', Comment = 'Common Data Service is the name of a Microsoft Service and should not be translated.';
    PageType = StandardDialog;
    SourceTable = "Office Admin. Credentials";
    SourceTableTemporary = true;
    Extensible = false;

    layout
    {
        area(content)
        {
            label("Specify the credentials of the user that will be used to import the solution.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Specifies the credentials of the user that will be used to import and configure the integration solution.';
            }
            field(UserName; Email)
            {
                ApplicationArea = Basic, Suite;
                ExtendedDatatype = EMail;
                Caption = 'User Name';
                ToolTip = 'Specifies the name of the user that will be used to import and configure the integration solution.';
            }
            field(Password; Password)
            {
                ApplicationArea = Basic, Suite;
                ExtendedDatatype = Masked;
                ToolTip = 'Specifies the password of the user that will be used to import and configure the integration solution.';
            }
            label(InvalidUserMessage)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'The user must exist within Common Data Service with the security roles System Administrator and Solution Customizer.';
            }
        }
    }

    var
        EmptyUserNameErr: Label 'Enter user name.';
        EmptyPasswordErr: Label 'Enter password.';

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        TempCDSConnectionSetup: Record "CDS Connection Setup" temporary;
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
    begin
        if CloseAction = Action::LookupOK then begin
            if Email.Trim() = '' then
                Error(EmptyUserNameErr);
            if Password = '' then
                Error(EmptyPasswordErr);
            TempCDSConnectionSetup."Authentication Type" := TempCDSConnectionSetup."Authentication Type"::Office365;
            TempCDSConnectionSetup."Proxy Version" := CDSIntegrationImpl.GetLastProxyVersionItem();
            TempCDSConnectionSetup."Server Address" := Endpoint;
            TempCDSConnectionSetup."User Name" := Email;
            TempCDSConnectionSetup.SetPassword(Password);
            CDSIntegrationImpl.UpdateConnectionString(TempCDSConnectionSetup);
            CDSIntegrationImpl.CheckAdminUserPrerequisites(TempCDSConnectionSetup, Email, Password);
        end;
    end;
}

