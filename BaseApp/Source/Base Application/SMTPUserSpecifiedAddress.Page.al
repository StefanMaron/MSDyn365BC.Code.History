page 410 "SMTP User-Specified Address"
{
    Caption = 'Enter Email Address';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            group(Control4)
            {
                ShowCaption = false;
                field(EmailAddressField; EmailAddress)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Email Address';
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address.';

                    trigger OnValidate()
                    var
                        MailManagement: Codeunit "Mail Management";
                    begin
                        MailManagement.CheckValidEmailAddresses(EmailAddress);
                    end;
                }

                label(AnonymousAuthenticationMessage)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = IsAnonymousAuthentication;
                    Caption = 'This will be the To and From email addresses for the test message.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
    begin
        if SMTPMailSetup.GetSetup() then
            IsAnonymousAuthentication := SMTPMailSetup.Authentication = SMTPMailSetup.Authentication::Anonymous;
    end;

    var
        EmailAddress: Text;
        IsAnonymousAuthentication: Boolean;

    procedure GetEmailAddress(): Text
    begin
        exit(EmailAddress);
    end;

    procedure SetEmailAddress(Address: Text)
    begin
        EmailAddress := Address;
    end;
}

