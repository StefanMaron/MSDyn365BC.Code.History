page 1270 "OCR Service Setup"
{
    AdditionalSearchTerms = 'electronic document,e-invoice,incoming document,document exchange,import invoice,lexmark,optical character recognition';
    ApplicationArea = Basic, Suite;
    Caption = 'OCR Service Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Encryption,Navigate';
    ShowFilter = false;
    SourceTable = "OCR Service Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                group(Control23)
                {
                    ShowCaption = false;
                    field("User Name"; "User Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = EditableByNotEnabled;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the user name that represents your company''s login to the OCR service.';

                        trigger OnValidate()
                        begin
                            CurrPage.SaveRecord;
                        end;
                    }
                    field(Password; Password)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Password';
                        Editable = EditableByNotEnabled;
                        ExtendedDatatype = Masked;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the password that is used for your company''s login to the OCR service.';

                        trigger OnValidate()
                        begin
                            SavePassword("Password Key", Password);
                            if Password <> '' then
                                CheckEncryption;
                        end;
                    }
                    field(AuthorizationKey; AuthorizationKey)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Authorization Key';
                        Editable = EditableByNotEnabled;
                        ExtendedDatatype = Masked;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the authorization key that is used for your company''s login to the OCR service.';

                        trigger OnValidate()
                        begin
                            SavePassword("Authorization Key", AuthorizationKey);
                            if AuthorizationKey <> '' then
                                CheckEncryption;
                        end;
                    }
                    field("Default OCR Doc. Template"; "Default OCR Doc. Template")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = EditableByNotEnabled;
                        ToolTip = 'Specifies the OCR template that must be used by default for electronic documents that are received from the OCR service. You can change the OCR template on the individual incoming document card before sending the related file to the OCR service.';

                        trigger OnValidate()
                        begin
                            CurrPage.Update
                        end;
                    }
                }
                group(Control25)
                {
                    ShowCaption = false;
                    field("Master Data Sync Enabled"; "Master Data Sync Enabled")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = EditableByNotEnabled;
                        ToolTip = 'Specifies whether or not the master data sync has been enabled.';

                        trigger OnValidate()
                        begin
                            UpdateBasedOnSyncEnable;
                        end;
                    }
                    field("Master Data Last Sync"; "Master Data Last Sync")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the last time when the master data was synched.';
                    }
                    field(Enabled; Enabled)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies if the service is enabled.';

                        trigger OnValidate()
                        begin
                            UpdateBasedOnEnable;
                            CurrPage.Update
                        end;
                    }
                    field(ShowEnableWarning; ShowEnableWarning)
                    {
                        ApplicationArea = Basic, Suite;
                        AssistEdit = false;
                        Editable = false;
                        Enabled = NOT EditableByNotEnabled;

                        trigger OnDrillDown()
                        begin
                            DrilldownCode;
                        end;
                    }
                }
            }
            group(Service)
            {
                Caption = 'Service';
                field("Sign-up URL"; "Sign-up URL")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    ToolTip = 'Specifies the web page where you sign up for the OCR service.';
                }
                field("Service URL"; "Service URL")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the address of the OCR service. The service specified in the Service URL field is called when you send and receive files for OCR.';
                }
                field("Sign-in URL"; "Sign-in URL")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    ToolTip = 'Specifies the sign-in page for the OCR service. This is the web page where you enter your company''s user name, password, and authorization key to sign in to the service.';
                }
            }
            group(CustomerStatus)
            {
                Caption = 'Status';
                field("Customer Name"; "Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies your company''s name at the provider of the OCR service.';
                }
                field("Customer ID"; "Customer ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies your company''s customer ID at the provider of the OCR service.';
                }
                field("Customer Status"; "Customer Status")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies your company''s status at the provider of the OCR service.';
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
                ToolTip = 'Change the service and sign-up URLs to their default values. You cannot cancel this action to revert back to the current values.';

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
                ToolTip = 'Check that the settings that you added are correct and the connection to the Data Exchange Service is working.';

                trigger OnAction()
                var
                    OCRServiceMgt: Codeunit "OCR Service Mgt.";
                begin
                    OCRServiceMgt.TestConnection(Rec);
                end;
            }
            action(UpdateOCRDocTemplateList)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Update OCR Doc. Template List';
                Image = Template;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Check for new document templates that the OCR service supports, and add them to the list.';

                trigger OnAction()
                var
                    OCRServiceMgt: Codeunit "OCR Service Mgt.";
                begin
                    OCRServiceMgt.UpdateOcrDocumentTemplates;
                end;
            }
            action(ResyncMasterData)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Resync Master Data';
                Enabled = EditableBySyncEnabled;
                Image = CopyFromChartOfAccounts;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Synchronize master data for vendors and vendor bank accounts with the OCR service.';

                trigger OnAction()
                var
                    ReadSoftOCRMasterDataSync: Codeunit "ReadSoft OCR Master Data Sync";
                begin
                    Clear("Master Data Last Sync");
                    Modify;
                    ReadSoftOCRMasterDataSync.SyncMasterData(false, false);
                end;
            }
            action(JobQueueEntry)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Job Queue Entry';
                Enabled = Enabled;
                Image = JobListSetup;
                Promoted = true;
                PromotedCategory = Category5;
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
                Enabled = EditableByNotEnabled;
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
                Promoted = true;
                PromotedCategory = Category5;
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
        UpdateEncryptedField("Password Key", Password);
        UpdateEncryptedField("Authorization Key", AuthorizationKey);
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateBasedOnEnable;
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
        Password: Text[50];
        AuthorizationKey: Text[50];
        ShowEnableWarning: Text;
        EditableByNotEnabled: Boolean;
        EnabledWarningTok: Label 'You must disable the service before you can make changes.';
        DisableEnableQst: Label 'Do you want to disable the OCR service?';
        EnableServiceQst: Label 'The %1 is not enabled. Are you sure you want to exit?', Comment = '%1 = pagecaption (OCR Service Setup)';
        EncryptionIsNotActivatedQst: Label 'Data encryption is not activated. It is recommended that you encrypt data. \Do you want to open the Data Encryption Management window?';
        EditableBySyncEnabled: Boolean;
        CheckedEncryption: Boolean;

    local procedure UpdateBasedOnEnable()
    begin
        EditableByNotEnabled := (not Enabled) and CurrPage.Editable;
        ShowEnableWarning := '';
        if CurrPage.Editable and Enabled then
            ShowEnableWarning := EnabledWarningTok;
        UpdateBasedOnSyncEnable;
    end;

    local procedure UpdateBasedOnSyncEnable()
    begin
        EditableBySyncEnabled := "Master Data Sync Enabled" and Enabled;
        if EditableBySyncEnabled then
            exit;
        if "Master Data Last Sync" = 0DT then
            exit;
        Clear("Master Data Last Sync");
        Modify;
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
            if not EncryptionEnabled then
                if Confirm(EncryptionIsNotActivatedQst) then
                    PAGE.Run(PAGE::"Data Encryption Management");
        end;
    end;
}

