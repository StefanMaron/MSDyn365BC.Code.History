page 2824 "Native - Test Mail"
{
    Caption = 'nativeInvoicingTestMail', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = true;
    ModifyAllowed = false;
    ODataKeyFields = "Code";
    PageType = List;
    SourceTable = "Native - Export Invoices";
    SourceTableTemporary = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'Use "Email Test Mail" codeunit from "System Application" to send out test emails.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(email; "E-mail")
                {
                    ApplicationArea = All;
                    Caption = 'email', Locked = true;

                    trigger OnValidate()
                    begin
                        if "E-mail" = '' then
                            Error(EmailErr);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        SMTPTestMail: Codeunit "SMTP Test Mail";
    begin
        CheckSmtpMailSetup;
        SMTPTestMail.SendTestMail("E-mail");
        exit(true);
    end;

    var
        EmailErr: Label 'The email address is not specified.';
        MailNotConfiguredErr: Label 'An email account must be configured to send emails.';

    local procedure CheckSmtpMailSetup()
    var
        O365SetupEmail: Codeunit "O365 Setup Email";
    begin
        if not O365SetupEmail.SMTPEmailIsSetUp then
            Error(MailNotConfiguredErr);
    end;
}
