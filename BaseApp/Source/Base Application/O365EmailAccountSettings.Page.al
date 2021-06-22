page 2135 "O365 Email Account Settings"
{
    Caption = 'Email Account';
    DeleteAllowed = false;
    Editable = false;
    RefreshOnActivate = true;
    SourceTable = "SMTP Mail Setup";

    layout
    {
        area(content)
        {
            group(Control4)
            {
                InstructionalText = 'Your invoices will be sent from the following email account.';
                ShowCaption = false;
                field("Email Provider"; EmailProvider)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Email Account type';
                    Editable = false;
                    ShowCaption = false;
                    Style = Strong;
                    StyleExpr = TRUE;
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Email';
                    Editable = false;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies your company''s email address.';

                    trigger OnValidate()
                    begin
                        MailManagement.ValidateEmailAddressField("User ID");
                    end;
                }
                field(EmailPassword; EmailPassword)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Password';
                    Editable = false;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies your company''s email account password.';
                    Visible = IsPhoneApp;

                    trigger OnValidate()
                    begin
                        if EmailPassword = '' then
                            RemovePassword
                        else
                            SetPassword(EmailPassword);
                    end;
                }
                field("SMTP Server"; "SMTP Server")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Server';
                    Editable = false;
                    Visible = false;
                }
                field(TestEmailLbl; TestEmailLbl)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = false;
                    ShowCaption = false;
                    Style = StandardAccent;
                    StyleExpr = TRUE;
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        SMTPTestMail: Codeunit "SMTP Test Mail";
                    begin
                        CurrPage.SaveRecord;
                        Commit();

                        if SMTPTestMail.SendTestMail("User ID") then
                            Message(SettingsDidWorkMsg, "User ID")
                        else
                            Message(SettingsDidNotWorkMsg);

                        CurrPage.Update;
                    end;
                }
            }
            field(AdvancedEmailSetupLbl; AdvancedEmailSetupLbl)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Editable = false;
                ShowCaption = false;
                Style = StandardAccent;
                StyleExpr = TRUE;

                trigger OnDrillDown()
                begin
                    CurrPage.SaveRecord;
                    Commit();
                    PAGE.Run(PAGE::"O365 Email Setup Wizard");
                end;
            }
            field(SendViaGraphLbl; SendViaGraphLbl)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Editable = false;
                ShowCaption = false;
                Visible = GraphMailAvailable;

                trigger OnDrillDown()
                begin
                    PAGE.RunModal(PAGE::"Graph Mail Setup");
                    CurrPage.Close;
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if IsNullGuid("Password Key") then
            EmailPassword := ''
        else
            EmailPassword := '***';
    end;

    trigger OnInit()
    var
        GraphMail: Codeunit "Graph Mail";
    begin
        IsPhoneApp := ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Phone;
        GraphMailAvailable := GraphMail.HasConfiguration;
    end;

    trigger OnOpenPage()
    var
        User: Record User;
    begin
        if not GetSetup or not SMTPMail.IsEnabled then begin
            Init;
            SMTPMail.ApplyOffice365Smtp(Rec);
            if User.Get(UserSecurityId) then
                "User ID" := User."Authentication Email";
            EmailPassword := '';
            Modify;
        end else
            if IsNullGuid("Password Key") then
                EmailPassword := ''
            else
                EmailPassword := '***';
        GetEmailProvider(Rec);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if "User ID" = '' then
            RemovePassword;
    end;

    var
        TestEmailLbl: Label 'Test Email';
        AdvancedEmailSetupLbl: Label 'Change Email Setup';
        SendViaGraphLbl: Label 'Send email from my account';
        SettingsDidNotWorkMsg: Label 'That did not work. Verify your email address and password.';
        SettingsDidWorkMsg: Label 'It works! A test email has been sent to %1.', Comment = '%1=email address';
        SMTPMail: Codeunit "SMTP Mail";
        MailManagement: Codeunit "Mail Management";
        ClientTypeManagement: Codeunit "Client Type Management";
        EmailPassword: Text[250];
        EmailProvider: Option "Office 365",Outlook,Gmail,Yahoo,"Other Email Provider";
        IsPhoneApp: Boolean;
        GraphMailAvailable: Boolean;

    local procedure GetEmailProvider(var SMTPMailSetup: Record "SMTP Mail Setup")
    begin
        if SMTPMail.IsOffice365Setup(SMTPMailSetup) then
            EmailProvider := EmailProvider::"Office 365"
        else
            if SMTPMail.IsOutlookSetup(SMTPMailSetup) then
                EmailProvider := EmailProvider::Outlook
            else
                if SMTPMail.IsGmailSetup(SMTPMailSetup) then
                    EmailProvider := EmailProvider::Gmail
                else
                    if SMTPMail.IsYahooSetup(SMTPMailSetup) then
                        EmailProvider := EmailProvider::Yahoo
                    else
                        EmailProvider := EmailProvider::"Other Email Provider";
    end;
}

