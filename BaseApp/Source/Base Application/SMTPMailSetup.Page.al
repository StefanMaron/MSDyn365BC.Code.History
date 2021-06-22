page 409 "SMTP Mail Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'SMTP Mail Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "SMTP Mail Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("SMTP Server"; "SMTP Server")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the SMTP server.';

                    trigger OnValidate()
                    begin
                        SetCanSendTestMail;
                        CurrPage.Update;
                    end;
                }
                field("SMTP Server Port"; "SMTP Server Port")
                {
                    ApplicationArea = Basic, Suite;
                    MinValue = 1;
                    NotBlank = true;
                    ToolTip = 'Specifies the port of the SMTP server. The default setting is 25.';

                    trigger OnValidate()
                    begin
                        SetCanSendTestMail;
                    end;
                }
                field(Authentication; Authentication)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of authentication that the SMTP mail server uses.';

                    trigger OnValidate()
                    begin
                        AuthenticationOnAfterValidate;
                    end;
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = UserIDEditable;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
                field(Password; Password)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Password';
                    Editable = PasswordEditable;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the password of the SMTP server.';

                    trigger OnValidate()
                    begin
                        SetPassword(Password);
                        Commit();
                    end;
                }
                field("Secure Connection"; "Secure Connection")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if your SMTP mail server setup requires a secure connection that uses a cryptography or security protocol, such as secure socket layers (SSL). Clear the check box if you do not want to enable this security setting.';
                }
                field("Send As"; "Send As")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = UserIDEditable;
                    ToolTip = 'Specifies the ID of the user in whose name emails will be sent. For example, this can be useful when you want multiple people to be able to send messages that appear to come from a single sender, such as sales@companyname.';
                }
                field("Allow Sender Substitution"; "Allow Sender Substitution")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Allow Sender Substitution';
                    ToolTip = 'Specifies that the SMTP server allows you to change sender name and email.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ApplyOffice365)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Apply Office 365 Server Settings';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Apply the Office 365 server settings to this record.';

                trigger OnAction()
                var
                    SMTPMail: Codeunit "SMTP Mail";
                    ConfirmManagement: Codeunit "Confirm Management";
                begin
                    if CurrPage.Editable then begin
                        if not ("SMTP Server" = '') then
                            if not ConfirmManagement.GetResponseOrDefault(ConfirmApplyO365Qst, true) then
                                exit;
                        SMTPMail.ApplyOffice365Smtp(Rec);
                        AuthenticationOnAfterValidate;
                        SetCanSendTestMail;
                        CurrPage.Update;
                    end
                end;
            }
            action(SendTestMail)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Test Email Setup', Comment = '{Locked="&"}';
                Enabled = CanSendTestMail;
                Image = SendMail;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Sends email to the email address that is specified in the SMTP Settings window.';

                trigger OnAction()
                begin
                    CODEUNIT.Run(CODEUNIT::"SMTP Test Mail");
                end;
            }
        }
    }

    trigger OnInit()
    begin
        PasswordEditable := true;
        UserIDEditable := true;
    end;

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
            SetPassword('');
        end else
            Password := '***';
        UserIDEditable := Authentication = Authentication::Basic;
        PasswordEditable := Authentication = Authentication::Basic;
        SetCanSendTestMail;
    end;

    var
        Password: Text[250];
        [InDataSet]
        UserIDEditable: Boolean;
        [InDataSet]
        PasswordEditable: Boolean;
        CanSendTestMail: Boolean;
        ConfirmApplyO365Qst: Label 'Do you want to override the current data?';

    local procedure AuthenticationOnAfterValidate()
    begin
        UserIDEditable := Authentication = Authentication::Basic;
        PasswordEditable := Authentication = Authentication::Basic;
    end;

    local procedure SetCanSendTestMail()
    begin
        CanSendTestMail := "SMTP Server" <> '';
    end;
}

