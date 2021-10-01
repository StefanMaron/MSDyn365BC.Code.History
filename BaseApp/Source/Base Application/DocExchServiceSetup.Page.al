page 1275 "Doc. Exch. Service Setup"
{
    AdditionalSearchTerms = 'electronic document,e-invoice,incoming document,ocr,ecommerce';
    ApplicationArea = Basic, Suite;
    Caption = 'Document Exchange Service Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    PromotedActionCategories = 'New,Process,Page,Encryption';
    ShowFilter = false;
    SourceTable = "Doc. Exch. Service Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("User Agent"; "User Agent")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    ShowMandatory = true;
                    ToolTip = 'Specifies any text that you have entered to identify your company in document exchange processes.';
                }
#if not CLEAN19
                field(DocExchTenantID; DocExchTenantID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Doc. Exch. Tenant ID';
                    Visible = false;
                    Editable = EditableByNotEnabled;
                    ExtendedDatatype = Masked;
                    ShowMandatory = true;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies the tenant in the document exchange service that represents your company.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Authentication with OAuth 1.0 is deprecated.';
                    ObsoleteTag = '19.0';

                    trigger OnValidate()
                    begin
                        SavePassword("Doc. Exch. Tenant ID", DocExchTenantID);
                    end;
                }
#endif
                field(Sandbox; Sandbox)
                {
                    Caption = 'Sandbox';
                    ShowCaption = true;
                    Editable = EditableByNotEnabled;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the service is enabled in Sandbox';

                    trigger OnValidate()
                    begin
                        SetURLsToDefault(Sandbox);
                        AppUrl := DocExchServiceMgt.GetAppUrl(Rec);
                        CurrPage.SaveRecord();
                        DocExchServiceMgt.SendActivateAppNotification();
                    end;
                }
                field(Enabled; Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the service is enabled. When you enable the service, at least two job queue entries are created to process the traffic of electronic documents in and out of Microsoft Dynamics 365.';

                    trigger OnValidate()
                    begin
                        if IsEnabledChanged() then begin
                            CurrPage.Update(true);
                            UpdateBasedOnEnable();
                        end;
                    end;
                }
#if not CLEAN19
                field(ShowEnableWarning; ShowEnableWarning)
                {
                    ShowCaption = false;
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                    Enabled = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Authentication with OAuth 1.0 is deprecated.';
                    ObsoleteTag = '19.0';
                }
#endif
            }
            group(Token)
            {
                Caption = 'Token';
                Visible = StatusVisible;
                field("Token Issued At"; "Token Issued At")
                {
                    Caption = 'Issued At';
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the time at which the token was issued.';
                }
                field("Token Expired"; "Token Expired")
                {
                    Caption = 'Expired';
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = TokenStyleExpr;
                    ToolTip = 'Specifies whether the token has expired.';

                    trigger OnDrillDown()
                    begin
                        if TokenStatus then begin
                            Message(ValidTokenMsg);
                            exit;
                        end;
                        if not Confirm(RenewExpiredTokenQst) then
                            exit;
                        DocExchServiceMgt.RenewToken(false);
                        Get();
                        CurrPage.Update(false);
                    end;
                }
            }
            group(Service)
            {
                Caption = 'Service';
                field("Sign-up URL"; "Sign-up URL")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    ToolTip = 'Specifies the web page where you sign up for the document exchange service.';

                }
                field("Sign-in URL"; "Sign-in URL")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    ToolTip = 'Specifies the web page where you sign in to the document exchange service.';

                    trigger OnValidate()
                    begin
                        AppUrl := DocExchServiceMgt.GetAppUrl(Rec);
                    end;
                }
                field("App URL"; AppUrl)
                {
                    Caption = 'App URL';
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ExtendedDatatype = URL;
                    ToolTip = 'Specifies the app URL in the document exchange service app store.';
                }
                field("Service URL"; "Service URL")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the URL address of the document exchange service. The service specified in the Service URL field is called when you send and receive electronic documents.';

                    trigger OnValidate()
                    begin
                        Sandbox := DocExchServiceMgt.IsSandbox(Rec);
                    end;
                }
                field("Auth URL"; "Auth URL")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = OAuth2Visible;
                    Editable = EditableByNotEnabled;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the authentication URL address of the document exchange service.';
                }
                field("Token URL"; "Token URL")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = OAuth2Visible;
                    Editable = EditableByNotEnabled;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the token URL address of the document exchange service.';
                }
                field("Log Web Requests"; "Log Web Requests")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    ToolTip = 'Specifies if web requests occurring in connection with the service are logged. The log is located in the server Temp folder.';
                }
            }
            group(Authorization)
            {
                Caption = 'Authorization';
                Visible = OAuth2Visible;
#if not CLEAN19
                group(Consumer)
                {
                    Caption = 'Consumer';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Authentication with OAuth 1.0 is deprecated.';
                    ObsoleteTag = '19.0';
                    field(ConsumerKey; ConsumerKey)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Consumer Key';
                        Editable = EditableByNotEnabled;
                        ExtendedDatatype = Masked;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the 3-legged OAuth key for the consumer key. This is provided by the document exchange service provider.';
                        ObsoleteState = Pending;
                        ObsoleteReason = 'Authentication with OAuth 1.0 is deprecated.';
                        ObsoleteTag = '19.0';

                        trigger OnValidate()
                        begin
                            SavePassword("Consumer Key", ConsumerKey);
                            if ConsumerKey <> '' then
                                CheckEncryption();
                        end;
                    }
                    field(ConsumerSecret; ConsumerSecret)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Consumer Secret';
                        Editable = EditableByNotEnabled;
                        ExtendedDatatype = Masked;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the secret that protects the consumer key that you enter in the Consumer Key field.';
                        ObsoleteState = Pending;
                        ObsoleteReason = 'Authentication with OAuth 1.0 is deprecated.';
                        ObsoleteTag = '19.0';

                        trigger OnValidate()
                        begin
                            SavePassword("Consumer Secret", ConsumerSecret);
                            if ConsumerSecret <> '' then
                                CheckEncryption();
                        end;
                    }
                }
                group(Tokens)
                {
                    Caption = 'Tokens';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Authentication with OAuth 1.0 is deprecated.';
                    ObsoleteTag = '19.0';
                    field(TokenValue; TokenValue)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Token';
                        Editable = EditableByNotEnabled;
                        ExtendedDatatype = Masked;
                        ShowMandatory = true;
                        ToolTip = 'Specifies a 3-legged OAuth key for Token. This is provided by the document exchange service provider.';
                        ObsoleteState = Pending;
                        ObsoleteReason = 'Authentication with OAuth 1.0 is deprecated.';
                        ObsoleteTag = '19.0';

                        trigger OnValidate()
                        begin
                            SavePassword(Token, TokenValue);
                            if TokenValue <> '' then
                                CheckEncryption();
                        end;
                    }
                    field(TokenSecret; TokenSecret)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Token Secret';
                        Editable = EditableByNotEnabled;
                        ExtendedDatatype = Masked;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the 3-legged OAuth key for the token that you enter in the Token field.';
                        ObsoleteState = Pending;
                        ObsoleteReason = 'Authentication with OAuth 1.0 is deprecated.';
                        ObsoleteTag = '19.0';

                        trigger OnValidate()
                        begin
                            SavePassword("Token Secret", TokenSecret);
                            if TokenSecret <> '' then
                                CheckEncryption();
                        end;
                    }
                }
#endif
                field("Client Id"; "Client Id")
                {
                    Caption = 'Client ID';
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    ToolTip = 'Specifies the client ID of the application that will be used to connect to the document exchange service.';

                    trigger OnValidate()
                    begin
                        if Rec."Client Id" = '' then begin
                            AppUrl := '';
                            exit;
                        end;

                        if Rec."Client Id" = xRec."Client Id" then
                            exit;

                        Rec.SetAccessToken('');
                        Rec.SetRefreshToken('');
                        Rec."Id Token" := '';
                        Rec."Token Subject" := '';
                        Rec."Token Issued At" := 0DT;
                        Rec."Token Expired" := false;

                        CurrPage.SaveRecord();
                        AppUrl := DocExchServiceMgt.GetAppUrl(Rec);
                        DocExchServiceMgt.SendActivateAppNotification();
                    end;
                }
                field("Client Secret"; ClientSecret)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Client Secret';
                    Editable = EditableByNotEnabled;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the client secret of the application that will be used to connect to the document exchange service.';

                    trigger OnValidate()
                    begin
                        if not CurrPage.Editable then begin
                            ClientSecret := SavedClientSecret;
                            exit;
                        end;
                        if not IsTemporary() then
                            if ClientSecret <> '' then
                                CheckEncryption();
                        SetClientSecret(ClientSecret);
                        SavedClientSecret := ClientSecret;
                    end;
                }
                field("Redirect URL"; "Redirect URL")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled and not SoftwareAsAService;
                    ToolTip = 'Specifies the redirect URL of the application that will be used to to the document exchange service.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(SetURLsToDefault)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set URLs to Default';
                Enabled = EditableByNotEnabled;
                Image = Restore;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Change the service, sign-up, and sign-in URLs back to their default values. The changes occur immediately when you choose this action.';

                trigger OnAction()
                begin
                    SetURLsToDefault(Sandbox);
                    AppUrl := DocExchServiceMgt.GetAppUrl(Rec);
                end;
            }
            action(RenewToken)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Renew Token';
                Image = Restore;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Renew the token for connecting to the document exchange service. This might require administrator account credentials for the document exchange service.';

                trigger OnAction()
                begin
                    if not Confirm(RenewTokenQst) then
                        exit;
                    DocExchServiceMgt.RenewToken(true);
                    Get();
                    CurrPage.Update(false);
                end;
            }
            action(TestConnection)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Test Connection';
                Image = Link;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Check that the settings that you added are correct and the connection to the document exchange service is working.';

                trigger OnAction()
                begin
                    CheckConnection();
                    Get();
                    CurrPage.Update(false);
                end;
            }
            action(JobQueueEntry)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Job Queue Entry';
                Enabled = Enabled;
                Image = JobListSetup;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'View or edit the jobs that automatically process the incoming and outgoing electronic documents.';

                trigger OnAction()
                begin
                    ShowJobQueueEntry();
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
                PromotedCategory = Category4;
                PromotedIsBig = true;
                RunObject = Page "Data Encryption Management";
                RunPageMode = View;
                ToolTip = 'Enable or disable data encryption. Data encryption helps make sure that unauthorized users cannot read business data.';
            }
            action(ActivityLog)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Activity Log';
                Image = Log;
                ToolTip = 'See the status and any errors for the electronic document or OCR file that you send through the document exchange service.';

                trigger OnAction()
                var
                    ActivityLog: Record "Activity Log";
                begin
                    ActivityLog.ShowEntries(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateBasedOnEnable();
        SetStyleExpr();
    end;

    trigger OnAfterGetRecord()
    begin
        EditableByNotEnabled := not Enabled;
    end;

    trigger OnOpenPage()
    var
        ClientId: Text;
    begin
        Reset();
        if not Get() then begin
            Init();
            SetURLsToDefault(false);
            Insert(true);
        end;
        Sandbox := DocExchServiceMgt.IsSandbox(Rec);
        AppUrl := DocExchServiceMgt.GetAppUrl(Rec);
        ClientSecret := GetClientSecret();
        SavedClientSecret := ClientSecret;
        if ("Redirect URL" = '') or (SoftwareAsAservice and ("Redirect URL" <> DocExchServiceMgt.GetDefaultRedirectUrl())) then begin
            SetDefaultRedirectUrl();
            Modify();
        end;
        UpdateBasedOnEnable();

        if Enabled and "Token Expired" then begin
            DocExchServiceMgt.SendRenewTokenNotification();
            exit;
        end;

        ClientId := DocExchServiceMgt.GetClientId(Sandbox);
        if (ClientId <> '') and ("Token Issued At" = 0DT) then
            DocExchServiceMgt.SendActivateAppNotification();
    end;

    trigger OnInit()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        SoftwareAsAService := EnvironmentInformation.IsSaaSInfrastructure();
        if not SoftwareAsAService then
            OAuth2Visible := true
        else
            OAuth2Visible := not DocExchServiceMgt.HasPredefinedOAuth2Params();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not Enabled then
            if not Confirm(StrSubstNo(EnableServiceQst, CurrPage.Caption), true) then
                exit(false);
    end;

    var
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
#if not CLEAN19
        ConsumerKey: Text[50];
        ConsumerSecret: Text[50];
        TokenValue: Text[50];
        TokenSecret: Text[50];
        DocExchTenantID: Text[50];
        ShowEnableWarning: Text;
#endif
        Sandbox: Boolean;
        OAuth2Visible: Boolean;
        StatusVisible: Boolean;
        SoftwareAsAService: Boolean;
        EditableByNotEnabled: Boolean;
        CheckedEncryption: Boolean;
        TokenStatus: Boolean;
        TokenStyleExpr: Text;
        AppUrl: Text;
        [NonDebuggable]
        ClientSecret: Text;
        [NonDebuggable]
        SavedClientSecret: Text;
        ValidTokenMsg: Label 'The token is not expired.';
        EnableServiceQst: Label 'The %1 is not enabled. Are you sure you want to exit?', Comment = '%1 = page caption (Document Exchange Service Setup)';
        RenewTokenQst: Label 'Do you want to renew the token to connect to the document exchange service?\\You might have to sign in to your account for the document exchange service.';
        RenewExpiredTokenQst: Label 'The token for connecting to the document exchange service has expired.\\To renew the token, choose the Renew Token action.\\You might have to sign in to your account for the document exchange service.';
        EncryptionIsNotActivatedQst: Label 'Data encryption is not activated. It is recommended that you encrypt data. \Do you want to open the Data Encryption Management window?';

    local procedure UpdateBasedOnEnable()
    begin
        StatusVisible := Enabled;
        EditableByNotEnabled := not Enabled;
    end;

    local procedure SetStyleExpr()
    begin
        TokenStatus := not "Token Expired";
        TokenStyleExpr := GetStyleExpr(TokenStatus);
    end;

    local procedure GetStyleExpr(Status: Boolean): Text
    begin
        if Status then
            exit('Favorable');
        exit('Unfavorable');
    end;

    local procedure CheckEncryption()
    begin
        if not CheckedEncryption and not EncryptionEnabled() then begin
            CheckedEncryption := true;
            if Confirm(EncryptionIsNotActivatedQst) then begin
                PAGE.Run(PAGE::"Data Encryption Management");
                CheckedEncryption := false;
            end;
        end;
    end;
}

