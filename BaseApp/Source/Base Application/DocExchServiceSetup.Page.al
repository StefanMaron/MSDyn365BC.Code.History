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
                field(DocExchTenantID; DocExchTenantID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Doc. Exch. Tenant ID';
                    Editable = EditableByNotEnabled;
                    ExtendedDatatype = Masked;
                    ShowMandatory = true;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies the tenant in the document exchange service that represents your company.';

                    trigger OnValidate()
                    begin
                        SavePassword("Doc. Exch. Tenant ID", DocExchTenantID);
                    end;
                }
                field(Enabled; Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the service is enabled. When you enable the service, at least two job queue entries are created to process the traffic of electronic documents in and out of Microsoft Dynamics 365.';

                    trigger OnValidate()
                    begin
                        UpdateBasedOnEnable;
                        CurrPage.Update;
                    end;
                }
                field(ShowEnableWarning; ShowEnableWarning)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Enabled = NOT EditableByNotEnabled;

                    trigger OnDrillDown()
                    begin
                        DrilldownCode;
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
                field("Service URL"; "Service URL")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the URL address of the document exchange service. The service specified in the Service URL field is called when you send and receive electronic documents.';
                }
                field("Sign-in URL"; "Sign-in URL")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    ToolTip = 'Specifies the web page where you sign in to the document exchange service.';
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
                group(Consumer)
                {
                    Caption = 'Consumer';
                    field(ConsumerKey; ConsumerKey)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Consumer Key';
                        Editable = EditableByNotEnabled;
                        ExtendedDatatype = Masked;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the 3-legged OAuth key for the consumer key. This is provided by the document exchange service provider.';

                        trigger OnValidate()
                        begin
                            SavePassword("Consumer Key", ConsumerKey);
                            if ConsumerKey <> '' then
                                CheckEncryption;
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

                        trigger OnValidate()
                        begin
                            SavePassword("Consumer Secret", ConsumerSecret);
                            if ConsumerSecret <> '' then
                                CheckEncryption;
                        end;
                    }
                }
                group(Tokens)
                {
                    Caption = 'Tokens';
                    field(TokenValue; TokenValue)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Token';
                        Editable = EditableByNotEnabled;
                        ExtendedDatatype = Masked;
                        ShowMandatory = true;
                        ToolTip = 'Specifies a 3-legged OAuth key for Token. This is provided by the document exchange service provider.';

                        trigger OnValidate()
                        begin
                            SavePassword(Token, TokenValue);
                            if TokenValue <> '' then
                                CheckEncryption;
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

                        trigger OnValidate()
                        begin
                            SavePassword("Token Secret", TokenSecret);
                            if TokenSecret <> '' then
                                CheckEncryption;
                        end;
                    }
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
                    SetURLsToDefault;
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
                ToolTip = 'Check that the settings that you added are correct and the connection to the Data Exchange Service is working.';

                trigger OnAction()
                begin
                    CheckConnection;
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
                    ShowJobQueueEntry;
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
        UpdateBasedOnEnable;
        UpdateEncryptedField("Consumer Key", ConsumerKey);
        UpdateEncryptedField("Consumer Secret", ConsumerSecret);
        UpdateEncryptedField(Token, TokenValue);
        UpdateEncryptedField("Token Secret", TokenSecret);
        UpdateEncryptedField("Doc. Exch. Tenant ID", DocExchTenantID);
    end;

    trigger OnAfterGetRecord()
    begin
        EditableByNotEnabled := not Enabled;
    end;

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert(true);
            SetURLsToDefault;
        end;
        UpdateBasedOnEnable;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not Enabled then
            if not Confirm(StrSubstNo(EnableServiceQst, CurrPage.Caption), true) then
                exit(false);
    end;

    var
        ConsumerKey: Text[50];
        ConsumerSecret: Text[50];
        TokenValue: Text[50];
        TokenSecret: Text[50];
        DocExchTenantID: Text[50];
        EditableByNotEnabled: Boolean;
        ShowEnableWarning: Text;
        EnabledWarningTok: Label 'You must disable the service before you can make changes.';
        DisableEnableQst: Label 'Do you want to disable the document exchange service?';
        EnableServiceQst: Label 'The %1 is not enabled. Are you sure you want to exit?', Comment = '%1 = pagecaption (Document Exchange Service Setup)';
        CheckedEncryption: Boolean;
        EncryptionIsNotActivatedQst: Label 'Data encryption is not activated. It is recommended that you encrypt data. \Do you want to open the Data Encryption Management window?';

    local procedure UpdateBasedOnEnable()
    begin
        EditableByNotEnabled := not Enabled;
        ShowEnableWarning := '';
        if CurrPage.Editable and Enabled then
            ShowEnableWarning := EnabledWarningTok;
    end;

    local procedure DrilldownCode()
    begin
        if Confirm(DisableEnableQst, true) then begin
            Enabled := false;
            UpdateBasedOnEnable;
            CurrPage.Update;
        end;
    end;

    local procedure UpdateEncryptedField(InputGUID: Guid; var Text: Text[50])
    begin
        if IsNullGuid(InputGUID) then
            Text := ''
        else
            Text := '*************';
    end;

    local procedure CheckEncryption()
    begin
        if not CheckedEncryption and not EncryptionEnabled then begin
            CheckedEncryption := true;
            if Confirm(EncryptionIsNotActivatedQst) then begin
                PAGE.Run(PAGE::"Data Encryption Management");
                CheckedEncryption := false;
            end;
        end;
    end;
}

