codeunit 2135 "O365 Setup Email"
{

    trigger OnRun()
    begin
        SetupEmail(false);
    end;

    var
        MailNotConfiguredErr: Label 'An email account must be configured to send emails.';

    procedure SetupEmail(ForceSetup: Boolean)
    begin
        Page.RunModal(Page::"Email Account Wizard");
    end;

    procedure CheckMailSetup()
    var
        EmailAccount: Codeunit "Email Account";
    begin
        if not EmailAccount.IsAnyAccountRegistered() then
            Error(MailNotConfiguredErr);
    end;
}

