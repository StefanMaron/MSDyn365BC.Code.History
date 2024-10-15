page 1450 "MS - Yodlee Bank Service Setup"
{
    Caption = 'Envestnet Yodlee Bank Feeds Service Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Page,Encryption,Bank';
    ShowFilter = false;
    SourceTable = 1450;
    UsageCategory = Tasks;
    ApplicationArea = Basic, Suite;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                group(Cobrand)
                {
                    Caption = 'Cobrand';
                    Visible = AdvancedView;
                    field(CobrandEnvironmentName; CobrandEnvironmentName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cobrand Name';
                        Editable = EditableByNotEnabled;
                        ExtendedDatatype = Masked;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the cobrand name.';

                        trigger OnValidate();
                        begin
                            SaveCobrandEnvironmentName("Cobrand Environment Name", CobrandEnvironmentName);
                            DefaultCredentials := HasDefaultCredentials();
                        end;
                    }
                    field(CobrandName; CobrandName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cobrand Login';
                        Editable = EditableByNotEnabled;
                        ExtendedDatatype = Masked;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the cobrand username.';

                        trigger OnValidate();
                        begin
                            SaveCobrandName("Cobrand Name", CobrandName);
                            DefaultCredentials := HasDefaultCredentials();
                        end;
                    }
                    field(CobrandPwd; CobrandPwd)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cobrand Password';
                        Editable = EditableByNotEnabled;
                        ExtendedDatatype = Masked;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the cobrand password.';

                        trigger OnValidate();
                        begin
                            SaveCobrandPassword("Cobrand Password", CobrandPwd);
                            DefaultCredentials := HasDefaultCredentials();
                        end;
                    }
                    field(DefaultCredentials; DefaultCredentials)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Pre-configured Credentials';
                        Editable = false;
                        ToolTip = 'Specifies if the cobrand username and password are preconfigured by an administrator.';
                    }
                }
                group(Consumer)
                {
                    Caption = 'Consumer';
                    field("Consumer Name"; "Consumer Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = ConsumerEditable;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the consumer username. If you leave the field blank, a username is created automatically.';
                    }
                    group(ConsumerAdvanced)
                    {
                        Visible = AdvancedView;
                        field(ConsumerPwd; ConsumerPwd)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Consumer Password';
                            Editable = EditableByNotEnabled;
                            ExtendedDatatype = Masked;
                            ShowMandatory = true;
                            ToolTip = 'Specifies the consumer password.';

                            trigger OnValidate();
                            begin
                                SaveConsumerPassword("Consumer Password", ConsumerPwd);
                            end;
                        }
                    }
                    field("User Profile Email Address"; "User Profile Email Address")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Consumer Email Address';
                        Editable = EditableByNotEnabled;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the email address that will be associated with the created consumer.';
                        Visible = UserProfileEmaiLAddressIsVisible;
                    }
                }
                group(Enabling)
                {
                    field("Log Web Requests"; "Log Web Requests")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies if web requests should be logged. This is normally only required for troubleshooting.';
                    }
                    field("Accept Terms of Use"; "Accept Terms of Use")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = EditableByNotEnabled;
                        ToolTip = 'Specifies if you accept the terms of use for the Envestnet Yodlee Bank Feeds service.';

                        trigger OnValidate();
                        var
                            TempMSYodleeBankServiceSetup: Record 1450 temporary;
                        begin
                            IF "Accept Terms of Use" THEN BEGIN
                                TempMSYodleeBankServiceSetup.COPY(Rec);
                                TempMSYodleeBankServiceSetup."Accept Terms of Use" := FALSE;
                                TempMSYodleeBankServiceSetup.INSERT();

                                PAGE.RUNMODAL(PAGE::"MS - Yodlee Terms of use", TempMSYodleeBankServiceSetup);

                                TempMSYodleeBankServiceSetup.GET();
                                IF NOT TempMSYodleeBankServiceSetup."Accept Terms of Use" THEN
                                    ERROR('');
                            END;
                        end;
                    }
                    field(Enabled; Enabled)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies if the service should be enabled.';

                        trigger OnValidate();
                        begin
                            ValidateEnabled();
                        end;
                    }
                    field(ShowEnableWarning; ShowEnableWarning)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        Enabled = NOT EditableByNotEnabled;
                        ShowCaption = false;
                        ToolTip = 'Specifies that the service must be disabled to make changes.';

                        trigger OnDrillDown();
                        begin
                            DrilldownCode();
                        end;
                    }
                }
            }
            group(Service)
            {
                Caption = 'Service';
                Visible = AdvancedView;
                field("Service URL"; "Service URL")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the URL of the Envestnet Yodlee Bank Feeds service.';

                    trigger OnValidate();
                    begin
                        UpdateMaskedValues();
                    end;
                }
                field("Bank Acc. Linking URL"; "Bank Acc. Linking URL")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the URL of the Envestnet Yodlee Bank Account Linking page.';
                }
                field("Bank Feed Import Format"; "Bank Feed Import Format")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    ToolTip = 'Specifies the format that Envestnet Yodlee bank feeds are imported in.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(SetDefaults)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Defaults';
                Enabled = EditableByNotEnabled;
                Image = Restore;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Set the default values for the Envestnet Yodlee Bank Feeds service.';

                trigger OnAction();
                var
                    MSYodleeBankServiceSetup: Record 1450;
                begin
                    SetValuesToDefault();
                    SetDefaultBankStatementImportCode();

                    IF NOT ISNULLGUID("Cobrand Name") THEN
                        MSYodleeBankServiceSetup.DeleteFromIsolatedStorage("Cobrand Name");

                    IF NOT ISNULLGUID("Cobrand Password") THEN
                        MSYodleeBankServiceSetup.DeleteFromIsolatedStorage("Cobrand Password");

                    CLEAR("Cobrand Name");
                    CLEAR("Cobrand Password");
                    MODIFY(TRUE);

                    AdvancedViewOnOpen := NOT HasDefaultCredentials();
                    AdvancedView := NOT HasDefaultCredentials();

                    CurrPage.UPDATE();
                end;
            }
            action(TestSetup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Test Setup';
                Image = Link;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Verify that the Envestnet Yodlee service has been configured correctly. A consumer account is automatically created when the service is enabled.';

                trigger OnAction();
                var
                    MSYodleeBankSession: Record 1453;
                begin
                    MSYodleeBankSession.ResetSessionTokens();
                    CheckSetup();
                end;
            }
            action(ResetTokens)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reset Tokens';
                Image = ResetStatus;
                ToolTip = 'Reset any active session tokens.';

                trigger OnAction();
                var
                    MSYodleeBankSession: Record 1453;
                begin
                    MSYodleeBankSession.ResetSessionTokens();
                end;
            }
            action(ShowAdvancedSettings)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Advanced Settings';
                Enabled = NOT AdvancedView;
                Image = ViewDetails;
                ToolTip = 'Show all of the setup fields for the Envestnet Yodlee service.';
                Visible = NOT AdvancedViewOnOpen;

                trigger OnAction();
                begin
                    AdvancedView := NOT AdvancedView;
                end;
            }
        }
        area(navigation)
        {
            action(EncryptionManagement)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Encryption Management';
                Image = EncryptionKeys;
                Promoted = true;
                PromotedCategory = Category5;
                PromotedIsBig = true;
                RunObject = Page 9905;
                RunPageMode = View;
                ToolTip = 'Configure encryption settings.';
            }
            action(ActivityLog)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Activity Log';
                Image = Log;
                ToolTip = 'View Envestnet Yodlee activities.';

                trigger OnAction();
                var
                    ActivityLog: Record 710;
                begin
                    ActivityLog.ShowEntries(Rec);
                end;
            }
            group("Data Exchange")
            {
                Caption = 'Data Exchange';
                action(ExportDataExchangeDefinition)
                {
                    ApplicationArea = Advanced;
                    Caption = 'Export Default Data Exchange Definition';
                    Image = Export;
                    ToolTip = 'Export the data exchange definition that is used to import Envestnet Yodlee bank feeds.';

                    trigger OnAction();
                    var
                        MSYodleeDataExchangeDef: Record 1452;
                    begin
                        MSYodleeDataExchangeDef.ExportDataExchDefinition();
                    end;
                }
                action(ResetDataExchangeDefinitionToDefault)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reset Data Exchange Definition to Default';
                    Image = Restore;
                    ToolTip = 'Use the default data exchange definition for the Envestnet Yodlee Bank Feeds service.';

                    trigger OnAction();
                    var
                        MSYodleeDataExchangeDef: Record 1452;
                    begin
                        MSYodleeDataExchangeDef.ResetDataExchToDefault();
                        ResetDefaultBankStatementImportFormat();
                        MODIFY();
                        CurrPage.UPDATE();
                    end;
                }
            }
            group(Bank)
            {
                Caption = 'Bank';
                action(BankAccounts)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Accounts';
                    Image = BankAccount;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    RunObject = Page "Bank Account List";
                    RunPageMode = View;
                    ToolTip = 'View the bank accounts.';
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord();
    begin
        EditableByNotEnabled := NOT Enabled;
        UpdateBasedOnEnable();
        UpdateMaskedValues();
    end;

    trigger OnOpenPage();
    var
        EnvironmentInfo: Codeunit 457;
        CompanyInformationMgt: Codeunit 1306;
    begin
        RESET();
        IF NOT GET() THEN BEGIN
            INIT();
            SetValuesToDefault();
            INSERT(TRUE);
        END;
        UpdateBasedOnEnable();

        AdvancedViewOnOpen := NOT HasDefaultCredentials();
        AdvancedView := NOT HasDefaultCredentials();
        ConsumerEditable := AdvancedView AND EditableByNotEnabled;
        UserProfileEmaiLAddressIsVisible := (NOT EnvironmentInfo.IsSaaS()) OR CompanyInformationMgt.IsDemoCompany();
    end;

    var
        CobrandEnvironmentName: Text[50];
        CobrandName: Text[50];
        CobrandPwd: Text[50];
        ConsumerPwd: Text[50];
        EditableByNotEnabled: Boolean;
        ConsumerEditable: Boolean;
        DefaultCredentials: Boolean;
        AdvancedView: Boolean;
        AdvancedViewOnOpen: Boolean;
        ShowEnableWarning: Text;
        EnabledWarningTok: Label 'You must disable the service before you can make changes.';
        DisableEnableQst: Label 'Do you want to disable the bank feed service?';
        RemoveConsumerOnDisableQst: Label 'Disabling the service will unlink all online bank accounts.\\Do you want to continue?';
        UserProfileEmaiLAddressIsVisible: Boolean;

    local procedure UpdateBasedOnEnable();
    begin
        EditableByNotEnabled := NOT Enabled;
        ConsumerEditable := AdvancedView AND EditableByNotEnabled;
        ShowEnableWarning := '';
        IF CurrPage.EDITABLE() AND Enabled THEN
            ShowEnableWarning := EnabledWarningTok;
    end;

    local procedure UpdateMaskedValues();
    begin
        IF HasPassword("Consumer Password") THEN
            ConsumerPwd := '*************'
        ELSE
            ConsumerPwd := '';

        IF HasCobrandPassword("Cobrand Password") THEN
            CobrandPwd := '*************'
        ELSE
            CobrandPwd := '';

        IF HasCobrandName("Cobrand Name") THEN
            CobrandName := '*************'
        ELSE
            CobrandName := '';

        IF HasCobrandEnvironmentName("Cobrand Environment Name") THEN
            CobrandEnvironmentName := '*************'
        ELSE
            CobrandEnvironmentName := '';

        DefaultCredentials := HasDefaultCredentials();
    end;

    local procedure DrilldownCode();
    begin
        IF NOT Enabled THEN
            EXIT;

        IF CONFIRM(DisableEnableQst, TRUE) THEN BEGIN
            VALIDATE(Enabled, FALSE);
            ValidateEnabled();
        END;
    end;

    local procedure ValidateEnabled();
    var
        MSYodleeBankSession: Record 1453;
        MSYodleeServiceMgt: Codeunit 1450;
    begin
        IF MSYodleeBankSession.GET() THEN BEGIN
            MSYodleeBankSession."Cob. Token Last Date Updated" := 0DT;
            MSYodleeBankSession."Cons. Token Last Date Updated" := 0DT;
            CLEAR(MSYodleeBankSession."Cobrand Session Token");
            CLEAR(MSYodleeBankSession."Consumer Session Token");
            MSYodleeBankSession.MODIFY(TRUE);
        END;

        IF (NOT Enabled) AND ("Consumer Name" <> '') AND HasPassword("Consumer Password") THEN
            IF CONFIRM(RemoveConsumerOnDisableQst, TRUE) THEN BEGIN
                CurrPage.SAVERECORD(); // GET on this Rec is performed on UnregisterConsumer
                MSYodleeServiceMgt.SetDisableRethrowException(TRUE);
                MSYodleeServiceMgt.UnregisterConsumer();
                GET();
            END ELSE
                ERROR(''); // rollback & prevent disable

        IF NOT Enabled THEN
            MSYodleeServiceMgt.UnlinkAllBankAccounts();

        UpdateBasedOnEnable();
        Commit();
        CurrPage.UPDATE();
    end;
}

