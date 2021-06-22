page 5094 "Marketing Setup"
{
    ApplicationArea = Basic, Suite, RelationshipMgmt;
    Caption = 'Marketing Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Marketing Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Visible = NOT SoftwareAsAService;
                field("Attachment Storage Type"; "Attachment Storage Type")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies how you want to store attachments. The following options exist:';

                    trigger OnValidate()
                    begin
                        AttachmentStorageTypeOnAfterVa;
                    end;
                }
                field("Attachment Storage Location"; "Attachment Storage Location")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = AttachmentStorageLocationEnabl;
                    ToolTip = 'Specifies the drive and path to the location where you want attachments stored if you selected Disk File in the Attachment Storage Type field.';

                    trigger OnValidate()
                    begin
                        AttachmentStorageLocationOnAft;
                    end;
                }
            }
            group(Inheritance)
            {
                Caption = 'Inheritance';
                group(Inherit)
                {
                    Caption = 'Inherit';
                    field("Inherit Salesperson Code"; "Inherit Salesperson Code")
                    {
                        ApplicationArea = Suite, RelationshipMgmt;
                        Caption = 'Salesperson Code';
                        ToolTip = 'Specifies that you want to copy the salesperson code from the contact card of a company to the contact card for the individual contact person or people working for that company.';
                    }
                    field("Inherit Territory Code"; "Inherit Territory Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Territory Code';
                        ToolTip = 'Specifies that you want to copy the territory code from the contact card of a company to the contact card for the individual contact person or people working for that company.';
                    }
                    field("Inherit Country/Region Code"; "Inherit Country/Region Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Country/Region Code';
                        ToolTip = 'Specifies that you want to copy the country/region code from the contact card of a company to the contact card for the individual contact person or people working for that company.';
                    }
                    field("Inherit Language Code"; "Inherit Language Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Language Code';
                        ToolTip = 'Specifies that you want to copy the language code from the contact card of a company to the contact card for the individual contact person or people working for that company.';
                    }
                    field("Inherit Address Details"; "Inherit Address Details")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Address Details';
                        ToolTip = 'Specifies that you want to copy the address details from the contact card of a company to the contact card for the individual contact person or people working for that company.';
                    }
                    field("Inherit Communication Details"; "Inherit Communication Details")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Communication Details';
                        ToolTip = 'Specifies that you want to copy the communication details, such as telex and fax numbers, from the contact card of a company to the contact card for the individual contact person or people working for that company.';
                    }
                }
            }
            group(Defaults)
            {
                Caption = 'Defaults';
                group(Default)
                {
                    Caption = 'Default';
                    field("Default Salesperson Code"; "Default Salesperson Code")
                    {
                        ApplicationArea = Suite, RelationshipMgmt;
                        Caption = 'Salesperson Code';
                        ToolTip = 'Specifies the salesperson code to assign automatically to contacts when they are created.';
                    }
                    field("Default Territory Code"; "Default Territory Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Territory Code';
                        ToolTip = 'Specifies the territory code to automatically assign to contacts when they are created.';
                    }
                    field("Default Country/Region Code"; "Default Country/Region Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Country/Region Code';
                        ToolTip = 'Specifies the country/region code to assign automatically to contacts when they are created.';
                    }
                    field("Default Language Code"; "Default Language Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Language Code';
                        ToolTip = 'Specifies the language code to assign automatically to contacts when they are created.';
                    }
                    field("Default Correspondence Type"; "Default Correspondence Type")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Correspondence Type';
                        ToolTip = 'Specifies the preferred type of correspondence for the interaction. NOTE: If you use the Web client, you must not select the Hard Copy option because printing is not possible from the web client.';
                    }
                    field("Def. Company Salutation Code"; "Def. Company Salutation Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Company Salutation Code';
                        ToolTip = 'Specifies the salutation code to assign automatically to contact companies when they are created.';
                    }
                    field("Default Person Salutation Code"; "Default Person Salutation Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Person Salutation Code';
                        ToolTip = 'Specifies the salutation code to assign automatically to contact persons when they are created.';
                    }
                    field("Default Sales Cycle Code"; "Default Sales Cycle Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Sales Cycle Code';
                        ToolTip = 'Specifies the sales cycle code to automatically assign to opportunities when they are created.';
                    }
                    field("Default To-do Date Calculation"; "Default To-do Date Calculation")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Task Date Calculation';
                        ToolTip = 'Specifies the task date calculation formula to use to calculate the ending date for tasks in Business Central if you haven''t entered any due date in the Outlook task. If you leave the field blank, today''s date is applied.';
                    }
                }
            }
            group(Interactions)
            {
                Caption = 'Interactions';
                field("Mergefield Language ID"; "Mergefield Language ID")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the language ID of the Windows language to use for naming the merge fields shown when editing an attachment in Microsoft Word.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Language: Codeunit Language;
                    begin
                        Language.LookupApplicationLanguageId("Mergefield Language ID");
                    end;
                }
                group("Bus. Relation Code for")
                {
                    Caption = 'Bus. Relation Code for';
                    field("Bus. Rel. Code for Customers"; "Bus. Rel. Code for Customers")
                    {
                        ApplicationArea = Basic, Suite, RelationshipMgmt;
                        Caption = 'Customers';
                        ToolTip = 'Specifies the business relation code that identifies that a contact is also a customer.';
                    }
                    field("Bus. Rel. Code for Vendors"; "Bus. Rel. Code for Vendors")
                    {
                        ApplicationArea = Basic, Suite, RelationshipMgmt;
                        Caption = 'Vendors';
                        ToolTip = 'Specifies the business relation code that identifies that a contact is also a vendor.';
                    }
                    field("Bus. Rel. Code for Bank Accs."; "Bus. Rel. Code for Bank Accs.")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Bank Accounts';
                        ToolTip = 'Specifies the business relation code that identifies that a contact is also a bank account.';
                    }
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Contact Nos."; "Contact Nos.")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    ToolTip = 'Specifies the code for the number series to use when assigning numbers to contacts.';
                }
                field("Campaign Nos."; "Campaign Nos.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code for the number series to use when assigning numbers to campaigns.';
                }
                field("Segment Nos."; "Segment Nos.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code for the number series to use when assigning numbers to segments.';
                }
                field("To-do Nos."; "To-do Nos.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code for the number series to use when assigning numbers to tasks.';
                }
                field("Opportunity Nos."; "Opportunity Nos.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code for the number series to use when assigning numbers to opportunities.';
                }
            }
            group(Duplicates)
            {
                Caption = 'Duplicates';
                field("Maintain Dupl. Search Strings"; "Maintain Dupl. Search Strings")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the automatic update of search strings used to search for duplicates. You can set up search strings in the Duplicate Search String Setup table.';
                }
                field("Autosearch for Duplicates"; "Autosearch for Duplicates")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that you want to search automatically for duplicates each time a contact is created or modified.';
                }
                field("Search Hit %"; "Search Hit %")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the level of precision to apply when searching for duplicates.';
                }
            }
            group("Email Logging")
            {
                Caption = 'Email Logging';
                field("Autodiscovery E-Mail Address"; "Autodiscovery E-Mail Address")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the email address that you want to use in discovery of an Exchange Server. You specify a valid email address, which enables the discovery of the associated Exchange Server. You can validate the email address after you enter an address.';

                    trigger OnValidate()
                    begin
                        if "Autodiscovery E-Mail Address" <> xRec."Autodiscovery E-Mail Address" then begin
                            OnAfterMarketingSetupEmailLoggingUsed;
                            ExchangeWebServicesClient.InvalidateService
                        end;
                    end;
                }
                field("Exchange Service URL"; "Exchange Service URL")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the address of your Exchange service. Setting this URL makes the email validation done by Validate Email Logging Setup faster.';

                    trigger OnValidate()
                    begin
                        if "Exchange Service URL" <> xRec."Exchange Service URL" then begin
                            OnAfterMarketingSetupEmailLoggingUsed;
                            ExchangeWebServicesClient.InvalidateService
                        end;
                    end;
                }
                field("Exchange Account User Name"; "Exchange Account User Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the name of the user account that has access to Exchange.';

                    trigger OnValidate()
                    begin
                        if "Exchange Account User Name" <> xRec."Exchange Account User Name" then begin
                            OnAfterMarketingSetupEmailLoggingUsed;
                            ExchangeWebServicesClient.InvalidateService;
                        end;
                    end;
                }
                field(ExchangeAccountPasswordTemp; ExchangeAccountPasswordTemp)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Exchange Account Password';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the password of the user account that has access to Exchange.';

                    trigger OnValidate()
                    begin
                        OnAfterMarketingSetupEmailLoggingUsed;
                        SetExchangeAccountPassword(ExchangeAccountPasswordTemp);
                        Commit();
                        ExchangeWebServicesClient.InvalidateService;
                    end;
                }
                field("Email Batch Size"; "Email Batch Size")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of email messages that you want to process in one run of a job queue that has been set up to handle email logging. By default, the number of messages to process is 0, which means that email messages are not batched together. You can modify this value when you are fine tuning your process so that the execution of a job queue does not take too long. Any email message that is not logged in any particular run will be handled in a subsequent run that has been scheduled.';

                    trigger OnValidate()
                    begin
                        OnAfterMarketingSetupEmailLoggingUsed;
                    end;
                }
                group(Control5)
                {
                    ShowCaption = false;
                    field("Queue Folder Path"; "Queue Folder Path")
                    {
                        ApplicationArea = RelationshipMgmt;
                        ToolTip = 'Specifies the name of the queue folder in Microsoft Outlook.';

                        trigger OnAssistEdit()
                        var
                            ExchangeFolder: Record "Exchange Folder";
                        begin
                            if GetExchangeFolder(ExchangeFolder, Text014) then
                                SetQueueFolder(ExchangeFolder);
                        end;
                    }
                    field("Storage Folder Path"; "Storage Folder Path")
                    {
                        ApplicationArea = RelationshipMgmt;
                        ToolTip = 'Specifies the name of the storage folder in Microsoft Outlook.';

                        trigger OnAssistEdit()
                        var
                            ExchangeFolder: Record "Exchange Folder";
                        begin
                            if GetExchangeFolder(ExchangeFolder, Text015) then
                                SetStorageFolder(ExchangeFolder);
                        end;
                    }
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
        area(navigation)
        {
            group("&Setup")
            {
                Caption = '&Setup';
                Image = Setup;
                action("Social Engagement Setup")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Social Engagement Setup';
                    Image = SocialListening;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Page "Social Listening Setup";
                    ToolTip = 'Set up the Microsoft Social Engagement server URL, agree to the license terms, and enable the Social Listening for Customers, Vendors, and/or Items.';
                }
                action("Duplicate Search String Setup")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Duplicate Search String Setup';
                    Image = CompareContacts;
                    RunObject = Page "Duplicate Search String Setup";
                    ToolTip = 'View or edit the list of search strings to use when searching for duplicates.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Validate EmailLogging Setup")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Validate Email Logging Setup';
                    Image = ValidateEmailLoggingSetup;
                    ToolTip = 'Test that email logging is set up correctly.';

                    trigger OnAction()
                    var
                        ErrorMessage: Text;
                    begin
                        if ValidateEmailLoggingSetup(Rec, ErrorMessage) then
                            Message(Text012)
                        else
                            Error(ErrorMessage);
                    end;
                }
                action("Clear EmailLogging Setup")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Clear Email Logging Setup';
                    Image = ClearLog;
                    ToolTip = 'Clear what is currently set up for email logging.';

                    trigger OnAction()
                    begin
                        if Confirm(Text009, true) then
                            ClearEmailLoggingSetup(Rec);
                    end;
                }
                action("Generate Integration IDs for Connector for Microsoft Dynamics")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Generate Integration IDs for Connector for Microsoft Dynamics';
                    Image = CreateSerialNo;
                    ToolTip = 'Generate identifiers (GUID) for records that can be used by Dynamics 365 Sales and in Dynamics 365.';

                    trigger OnAction()
                    var
                        IntegrationManagement: Codeunit "Integration Management";
                    begin
                        if Confirm(Text004, true) then begin
                            IntegrationManagement.SetupIntegrationTables;
                            Message(Text005);
                        end;
                    end;
                }
            }
        }
    }

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        SoftwareAsAService := EnvironmentInfo.IsSaaS;
    end;

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;

        AttachmentStorageLocationEnabl := "Attachment Storage Type" = "Attachment Storage Type"::"Disk File";
        ExchangeAccountPasswordTemp := '';
        if ("Exchange Account User Name" <> '') and (not IsNullGuid("Exchange Account Password Key")) then
            ExchangeAccountPasswordTemp := '**********';
    end;

    var
        ExchangeWebServicesClient: Codeunit "Exchange Web Services Client";
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        ExchangeAccountPasswordTemp: Text;
        [InDataSet]
        AttachmentStorageLocationEnabl: Boolean;
        Text004: Label 'You are about to add integration data to tables. This process may take several minutes. Do you want to continue?';
        Text005: Label 'The integration data has been added to the tables.';
        Text006: Label 'A valid email address is needed to find an instance of Exchange Server.';
        Text007: Label 'Exchange Server cannot be found.';
        Text008: Label 'The specified Exchange folder does not exist.';
        Text009: Label 'This clears the fields in your email logging setup. Do you want to continue?';
        Text010: Label 'The specified Queue folder does not exist or cannot be accessed.';
        Text011: Label 'The specified Storage folder does not exist or cannot be accessed.';
        Text012: Label 'Email logging setup was successfully validated and completed.';
        Text013: Label 'Validating #1#';
        Text014: Label 'Select Queue folder';
        Text015: Label 'Select Storage folder';
        Text016: Label 'Interaction Template Setup';
        SoftwareAsAService: Boolean;

    procedure SetAttachmentStorageType()
    begin
        if ("Attachment Storage Type" = "Attachment Storage Type"::Embedded) or
           ("Attachment Storage Location" <> '')
        then begin
            Modify;
            Commit();
            REPORT.Run(REPORT::"Relocate Attachments");
        end;
    end;

    procedure SetAttachmentStorageLocation()
    begin
        if "Attachment Storage Location" <> '' then begin
            Modify;
            Commit();
            REPORT.Run(REPORT::"Relocate Attachments");
        end;
    end;

    local procedure AttachmentStorageTypeOnAfterVa()
    begin
        AttachmentStorageLocationEnabl := "Attachment Storage Type" = "Attachment Storage Type"::"Disk File";
        SetAttachmentStorageType;
    end;

    local procedure AttachmentStorageLocationOnAft()
    begin
        SetAttachmentStorageLocation;
    end;

    [Scope('OnPrem')]
    procedure InitExchangeService()
    var
        Credentials: DotNet WebCredentials;
        Result: Boolean;
    begin
        if "Autodiscovery E-Mail Address" = '' then
            Error(Text006);

        if "Exchange Account User Name" <> '' then begin
            CreateExchangeAccountCredentials(Credentials);
            Result :=
              ExchangeWebServicesClient.InitializeOnServer("Autodiscovery E-Mail Address",
                "Exchange Service URL", Credentials.Credentials);
        end else
            Result := ExchangeWebServicesClient.InitializeOnClient("Autodiscovery E-Mail Address", "Exchange Service URL");

        if not Result then
            Error(Text007);
    end;

    local procedure GetExchangeFolder(var ExchangeFolder: Record "Exchange Folder"; FoldersCaption: Text): Boolean
    var
        ExchangeFoldersPage: Page "Exchange Folders";
    begin
        InitExchangeService;
        ExchangeFoldersPage.Initialize(ExchangeWebServicesClient, FoldersCaption);
        ExchangeFoldersPage.LookupMode(true);
        if ACTION::LookupOK = ExchangeFoldersPage.RunModal then begin
            ExchangeFoldersPage.GetRecord(ExchangeFolder);
            if not ExchangeWebServicesClient.FolderExists(ExchangeFolder.ReadUniqueID) then
                Error(Text008);
            exit(true);
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ClearEmailLoggingSetup(var MarketingSetup: Record "Marketing Setup")
    begin
        ExchangeWebServicesClient.InvalidateService;

        Clear(MarketingSetup."Autodiscovery E-Mail Address");
        Clear(MarketingSetup."Email Batch Size");

        Clear(MarketingSetup."Queue Folder Path");
        if MarketingSetup."Queue Folder UID".HasValue then
            Clear(MarketingSetup."Queue Folder UID");

        Clear(MarketingSetup."Storage Folder Path");
        if MarketingSetup."Storage Folder UID".HasValue then
            Clear(MarketingSetup."Storage Folder UID");

        Clear(MarketingSetup."Exchange Account User Name");
        Clear(MarketingSetup."Exchange Service URL");

        if not IsNullGuid(MarketingSetup."Exchange Account Password Key") then
            IsolatedStorageManagement.Delete(MarketingSetup."Exchange Account Password Key", DATASCOPE::Company);
        Clear(MarketingSetup."Exchange Account Password Key");

        MarketingSetup.Modify();
    end;

    local procedure ValidateEmailLoggingSetup(var MarketingSetup: Record "Marketing Setup"; var ErrorMsg: Text): Boolean
    var
        EmailLoggingDispatcher: Codeunit "Email Logging Dispatcher";
        ProgressWindow: Dialog;
        Credentials: DotNet WebCredentials;
        ValidationCaption: Text;
        CanInitialize: Boolean;
    begin
        ExchangeWebServicesClient.InvalidateService;

        ValidationCaption := FieldCaption("Autodiscovery E-Mail Address");
        ProgressWindow.Open(Text013, ValidationCaption);

        if "Exchange Account User Name" <> '' then begin
            CreateExchangeAccountCredentials(Credentials);
            CanInitialize := ExchangeWebServicesClient.InitializeOnServer("Autodiscovery E-Mail Address",
                "Exchange Service URL", Credentials.Credentials);
        end else
            CanInitialize := ExchangeWebServicesClient.InitializeOnClient("Autodiscovery E-Mail Address", "Exchange Service URL");

        if not CanInitialize then begin
            ErrorMsg := Text006;
            exit(false);
        end;

        ValidationCaption := FieldCaption("Queue Folder Path");
        ProgressWindow.Update;
        if not ExchangeWebServicesClient.FolderExists(MarketingSetup.GetQueueFolderUID) then begin
            ErrorMsg := Text010;
            exit(false);
        end;

        ValidationCaption := FieldCaption("Storage Folder Path");
        ProgressWindow.Update;
        if not ExchangeWebServicesClient.FolderExists(MarketingSetup.GetStorageFolderUID) then begin
            ErrorMsg := Text011;
            exit(false);
        end;

        // Emails cannot be automatically logged unless Interaction Template Setup configured correctly.
        ValidationCaption := Text016;
        ProgressWindow.Update;
        if not EmailLoggingDispatcher.CheckInteractionTemplateSetup(ErrorMsg) then
            exit(false);

        ProgressWindow.Close;
        Clear(ErrorMsg);
        MarketingSetup.Modify();

        OnAfterMarketingSetupEmailLoggingCompleted;
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMarketingSetupEmailLoggingUsed()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMarketingSetupEmailLoggingCompleted()
    begin
    end;
}

