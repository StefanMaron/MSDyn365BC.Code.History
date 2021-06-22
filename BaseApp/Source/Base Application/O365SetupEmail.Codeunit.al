codeunit 2135 "O365 Setup Email"
{

    trigger OnRun()
    begin
        SetupEmail(false);
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";
        EmailFeature: Codeunit "Email Feature";
        MailNotConfiguredErr: Label 'An email account must be configured to send emails.';

    [Obsolete('Use "Email Account Wizard" page from "System Application".', '17.0')]
    procedure SilentSetup()
    var
        GraphMail: Codeunit "Graph Mail";
    begin
        if GraphMail.IsEnabled or SMTPEmailIsSetUp then
            exit;

        if not GraphMail.HasConfiguration then
            Error(MailNotConfiguredErr);

        GraphMail.SetupGraph(false);

        if not GraphMail.IsEnabled then
            Error(MailNotConfiguredErr);
    end;

    procedure SetupEmail(ForceSetup: Boolean)
    var
        GraphMail: Codeunit "Graph Mail";
    begin
        if EmailFeature.IsEnabled() then begin
            Page.RunModal(Page::"Email Account Wizard");
            exit;
        end;

        if (not GraphMail.IsEnabled) and SMTPEmailIsSetUp then begin
            SetupSmtpEmail(ForceSetup);
            exit;
        end;

        if not GraphMail.HasConfiguration then begin
            SetupSmtpEmail(ForceSetup);
            exit;
        end;

        if not GraphMail.IsEnabled then
            if not GraphMail.UserHasLicense then begin
                SetupSmtpEmail(ForceSetup);
                exit;
            end;

        SetupGraphEmail(ForceSetup);
    end;

    local procedure SetupGraphEmail(ForceSetup: Boolean)
    var
        GraphMail: Codeunit "Graph Mail";
        RunSetup: Boolean;
    begin
        RunSetup := ForceSetup;
        if not RunSetup then
            if not GraphMail.IsEnabled then
                if not SMTPEmailIsSetUp or EmailFeature.IsEnabled() then
                    RunSetup := true;

        if RunSetup then
            if not GraphMail.SetupGraph(ForceSetup) then // Returns if graph mail was setup
                if not SMTPEmailIsSetUp or EmailFeature.IsEnabled() then begin // If it wasn't maybe smtp was configured instead
                    if ClientTypeManagement.GetCurrentClientType <> CLIENTTYPE::Phone then
                        Error('');
                    Error(MailNotConfiguredErr);
                end;
    end;

    [Obsolete('Email Accounts are setup using "Email Account Wizard" page from "System Application".', '17.0')]
    local procedure SetupSmtpEmail(ForceSetup: Boolean)
    begin
        if ForceSetup or (not SMTPEmailIsSetUp) then begin
            if not GuiAllowed then
                Error(MailNotConfiguredErr);

            if PAGE.RunModal(PAGE::"BC O365 Email Setup Wizard") <> ACTION::LookupOK then
                Error('');

            if not SMTPEmailIsSetUp then
                Error(MailNotConfiguredErr);
        end;
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    [Obsolete('Use IsAnyAccountRegistered in "Email Account" codeunit from "System Application".', '17.0')]
    procedure SMTPEmailIsSetUp(): Boolean
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        MailManagement: Codeunit "Mail Management";
    begin
        if not MailManagement.IsSMTPEnabled then
            exit(false);

        if SMTPMailSetup.GetSetup then
            exit((SMTPMailSetup."User ID" <> '') and (SMTPMailSetup.GetPassword() <> ''));
    end;

    procedure CheckMailSetup()
    var
        EmailAccount: Codeunit "Email Account";
    begin
        if EmailFeature.IsEnabled() then begin
            if not EmailAccount.IsAnyAccountRegistered() then
                Error(MailNotConfiguredErr);
            exit;
        end;

        if not SMTPEmailIsSetUp() then
            Error(MailNotConfiguredErr);
    end;
}

