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
                        SMTPMail: Codeunit "SMTP Mail";
                    begin
                        SMTPMail.CheckValidEmailAddresses(EmailAddress);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    var
        EmailAddress: Text;

    procedure GetEmailAddress(): Text
    begin
        exit(EmailAddress);
    end;

    procedure SetEmailAddress(Address: Text)
    begin
        EmailAddress := Address;
    end;
}

