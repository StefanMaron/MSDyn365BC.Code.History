page 411 "Graph Mail Setup"
{
    Caption = 'Email Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    SourceTable = "Graph Mail Setup";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control8)
            {
                InstructionalText = 'Invoices will be sent from this account.';
                ShowCaption = false;
                Visible = TokenAcquired;
                field("Sender Name"; "Sender Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies the name of the account that sends email on behalf of your business.';
                }
                field("Sender Email"; "Sender Email")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies the email account that sends email on behalf of your business.';
                }
                field(SendTestMail; SendTestMailLbl)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        SMTPUserSpecifiedAddress: Page "SMTP User-Specified Address";
                        Recipient: Text;
                    begin
                        CurrPage.SaveRecord;
                        Commit();

                        SMTPUserSpecifiedAddress.SetEmailAddress("Sender Email");
                        if SMTPUserSpecifiedAddress.RunModal = ACTION::OK then begin
                            Recipient := SMTPUserSpecifiedAddress.GetEmailAddress;
                            SendTestMail(Recipient);
                            Message(StrSubstNo(TestSuccessMsg, Recipient));
                        end;
                    end;
                }
                group(Control13)
                {
                    ShowCaption = false;
                    Visible = CanSwitchToUserAccount;
                    field(SetupMyAccountLbl; SetupMyAccountLbl)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            ClearRefreshCode;
                            TokenAcquired := false;
                            InitAuthFlow;
                        end;
                    }
                }
                field(ShowSmtp; AdvancedSetupLbl)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    var
                        GraphMailSetup: Record "Graph Mail Setup";
                        O365SetupEmail: Codeunit "O365 Setup Email";
                    begin
                        if PAGE.RunModal(PAGE::"BC O365 Email Setup Wizard") <> ACTION::LookupOK then
                            exit;

                        if O365SetupEmail.SMTPEmailIsSetUp then begin
                            ClearRefreshCode;
                            if LookupMode then
                                if GraphMailSetup.Get then
                                    GraphMailSetup.Delete();

                            CurrPage.Close;
                        end;
                    end;
                }
                group(Control7)
                {
                    ShowCaption = false;
                    Visible = NOT LookupMode;
                    field(ClearSetupLbl; ClearSetupLbl)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ShowCaption = false;
                        Visible = false;

                        trigger OnDrillDown()
                        begin
                            ClearRefreshCode;
                            CurrPage.Close;
                        end;
                    }
                }
            }
            group(Control5)
            {
                InstructionalText = 'Gathering information...';
                ShowCaption = false;
                Visible = NOT TokenAcquired;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    var
        User: Record User;
        GraphMail: Codeunit "Graph Mail";
    begin
        TokenAcquired := IsolatedStorage.Contains(Format(RefreshTokenKeyTxt), DataScope::Company) and ("Expires On" > CurrentDateTime);

        if IsEnabled then
            if User.Get(UserSecurityId) then
                CanSwitchToUserAccount := User."Authentication Email" <> "Sender Email";

        if CanSwitchToUserAccount then
            CanSwitchToUserAccount := GraphMail.UserHasLicense;

        if not TokenAcquired then
            InitAuthFlow;
    end;

    trigger OnOpenPage()
    var
        GraphMailSetup: Record "Graph Mail Setup";
    begin
        if not GraphMailSetup.Get then
            GraphMailSetup.Insert();

        if GraphMailSetup.IsEnabled then begin
            GraphMailSetup.RenewRefreshToken; // validates values
            GraphMailSetup.Modify(true);
        end;

        TransferFields(GraphMailSetup);
        Insert;

        LookupMode := CurrPage.LookupMode;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        GraphMailSetup: Record "Graph Mail Setup";
    begin
        if (not CurrPage.LookupMode) or (CloseAction = ACTION::LookupOK) then begin
            if not GraphMailSetup.Get then
                GraphMailSetup.Insert();

            GraphMailSetup.TransferFields(Rec);
            GraphMailSetup.Validate(Enabled, true);
            GraphMailSetup.Modify(true);
        end;
    end;

    var
        TokenAcquired: Boolean;
        SendTestMailLbl: Label 'Send a test email';
        SetupMyAccountLbl: Label 'Send from my email account';
        AdvancedSetupLbl: Label 'Send from another email account';
        TestSuccessMsg: Label 'A test email was sent to %1.', Comment = '%1 = an email address';
        ClearSetupLbl: Label 'Do not send from this account';
        LookupMode: Boolean;
        CanSwitchToUserAccount: Boolean;
        RefreshTokenKeyTxt: Label 'RefreshTokenKey', Locked = true;

    local procedure InitAuthFlow()
    begin
        if not Initialize(true) then
            CurrPage.Close;

        TokenAcquired := true;
        Modify;
    end;

    local procedure ClearRefreshCode()
    begin
        if IsolatedStorage.Contains(Format(RefreshTokenKeyTxt), DataScope::Company) then
            IsolatedStorage.Delete(Format(RefreshTokenKeyTxt), DataScope::Company);
    end;
}

