page 1607 "Office Update Available Dlg"
{
    Caption = 'Office Add-in Update Available';
    DataCaptionExpression = 'Office Add-in Update Available';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "Office Add-in";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            label(Empty)
            {
                ApplicationArea = Basic, Suite;
                Caption = '';
                Editable = false;
                Enabled = false;
                HideValue = true;
                ShowCaption = false;
                ToolTip = 'Specifies options for updating the add-in.';
            }
            label(AdminNonBreaking)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'An update is available for this Outlook add-in. To update the add-in, please contact your system administrator.';
                HideValue = true;
                ToolTip = 'Specifies an option for updating the add-in.';
                Visible = NOT UserCanUpdate AND UserCanContinue;
            }
            label(AdminBreaking)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'An update is available for this Outlook add-in. To continue using the add-in, please contact your system administrator.';
                ToolTip = 'Specifies an option for updating the add-in.';
                Visible = NOT UserCanUpdate AND NOT UserCanContinue;
            }
            label(UserNonBreaking)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'An update is available for this Outlook add-in. Do you want to apply the update now?';
                ToolTip = 'Specifies an option for updating the add-in.';
                Visible = UserCanContinue AND UserCanUpdate;
            }
            label(UserBreaking)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'An update is available for this Outlook add-in. To continue using the add-in, you must apply the update.';
                ToolTip = 'Specifies an option for updating the add-in.';
                Visible = NOT UserCanContinue AND UserCanUpdate;
            }
            field(UpgradeNow; UpgradeNowLbl)
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ShowCaption = false;
                ToolTip = 'Specifies that the add-in must be updated now.';
                Visible = UserCanUpdate;

                trigger OnDrillDown()
                begin
                    if ExchangeAddinSetup.PromptForCredentials then begin
                        ExchangeAddinSetup.DeployAddin(Rec);
                        Message(RestartClientMsg);
                        CurrPage.Close;
                    end;
                end;
            }
            field(UpgradeLater; GetLaterLabel)
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ShowCaption = false;
                ToolTip = 'Specifies that you want to continue using the add-in and update it later.';
                Visible = UserCanContinue;

                trigger OnDrillDown()
                begin
                    CurrPage.Close;
                end;
            }
            field(DontShowAgain; DontShowAgain)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Do not show this message again';
                ToolTip = 'Specifies if you want to not see this message again.';
                Visible = UserCanContinue;
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        UserCanUpdate := not IsAdminDeployed;
        UserCanContinue := not Breaking;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if DontShowAgain then begin
            if UserCanUpdate then
                Message(DontDisplayAgainMsg);
            InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.OfficeUpdateNotificationCode);
        end;

        if Breaking then
            exit(false);
    end;

    var
        DontDisplayAgainMsg: Label 'To update the add-in later, you must use the Office Add-In assisted setup guide.';
        RestartClientMsg: Label 'The add-in has been updated. Please close and reopen Outlook.';
        ContinueLbl: Label 'Continue';
        UpgradeNowLbl: Label 'Upgrade Now';
        UpgradeLaterLbl: Label 'Upgrade Later';
        ExchangeAddinSetup: Codeunit "Exchange Add-in Setup";
        InstructionMgt: Codeunit "Instruction Mgt.";
        DontShowAgain: Boolean;
        [InDataSet]
        UserCanContinue: Boolean;
        UserCanUpdate: Boolean;

    local procedure GetLaterLabel(): Text
    begin
        case true of
            UserCanContinue and not UserCanUpdate:
                exit(ContinueLbl);
            else
                exit(UpgradeLaterLbl);
        end;
    end;
}

