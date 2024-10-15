namespace Microsoft.CRM.Setup;

using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Interaction;
#if not CLEAN22
using Microsoft.CRM.Outlook;
using System;
#endif
using System.Environment;
#if not CLEAN22
using System.Email;
using System.Environment.Configuration;
#endif
using System.Globalization;
#if not CLEAN22
using System.Integration;
using System.Security.Encryption;
#endif

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
                Visible = not SoftwareAsAService;
                field("Attachment Storage Type"; Rec."Attachment Storage Type")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies how you want to store attachments. The following options exist:';

                    trigger OnValidate()
                    begin
                        AttachmentStorageTypeOnAfterVa();
                    end;
                }
                field("Attachment Storage Location"; Rec."Attachment Storage Location")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = AttachmentStorageLocationEnabl;
                    ToolTip = 'Specifies the drive and path to the location where you want attachments stored if you selected Disk File in the Attachment Storage Type field.';

                    trigger OnValidate()
                    begin
                        AttachmentStorageLocationOnAft();
                    end;
                }
            }
            group(Inheritance)
            {
                Caption = 'Inheritance';
                group(Inherit)
                {
                    Caption = 'Inherit';
                    field("Inherit Salesperson Code"; Rec."Inherit Salesperson Code")
                    {
                        ApplicationArea = Suite, RelationshipMgmt;
                        Caption = 'Salesperson Code';
                        ToolTip = 'Specifies that you want to copy the salesperson code from the contact card of a company to the contact card for the individual contact person or people working for that company.';
                    }
                    field("Inherit Territory Code"; Rec."Inherit Territory Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Territory Code';
                        ToolTip = 'Specifies that you want to copy the territory code from the contact card of a company to the contact card for the individual contact person or people working for that company.';
                    }
                    field("Inherit Country/Region Code"; Rec."Inherit Country/Region Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Country/Region Code';
                        ToolTip = 'Specifies that you want to copy the country/region code from the contact card of a company to the contact card for the individual contact person or people working for that company.';
                    }
                    field("Inherit Language Code"; Rec."Inherit Language Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Language Code';
                        ToolTip = 'Specifies that you want to copy the language code from the contact card of a company to the contact card for the individual contact person or people working for that company.';
                    }
                    field("Inherit Address Details"; Rec."Inherit Address Details")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Address Details';
                        ToolTip = 'Specifies that you want to copy the address details from the contact card of a company to the contact card for the individual contact person or people working for that company.';
                    }
                    field("Inherit Communication Details"; Rec."Inherit Communication Details")
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
                    field("Default Salesperson Code"; Rec."Default Salesperson Code")
                    {
                        ApplicationArea = Suite, RelationshipMgmt;
                        Caption = 'Salesperson Code';
                        ToolTip = 'Specifies the salesperson code to assign automatically to contacts when they are created.';
                    }
                    field("Default Territory Code"; Rec."Default Territory Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Territory Code';
                        ToolTip = 'Specifies the territory code to automatically assign to contacts when they are created.';
                    }
                    field("Default Country/Region Code"; Rec."Default Country/Region Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Country/Region Code';
                        ToolTip = 'Specifies the country/region code to assign automatically to contacts when they are created.';
                    }
                    field("Default Language Code"; Rec."Default Language Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Language Code';
                        ToolTip = 'Specifies the language code to assign automatically to contacts when they are created.';
                    }
                    field("Default Format Region"; Rec."Default Format Region")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Format Region Code';
                        ToolTip = 'Specifies the region format to assign automatically to contacts when they are created.';
                    }
                    field("Default Correspondence Type"; Rec."Default Correspondence Type")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Correspondence Type';
                        ToolTip = 'Specifies the preferred type of correspondence for the interaction. NOTE: If you use the Web client, you must not select the Hard Copy option because printing is not possible from the web client.';
                    }
                    field("Def. Company Salutation Code"; Rec."Def. Company Salutation Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Company Salutation Code';
                        ToolTip = 'Specifies the salutation code to assign automatically to contact companies when they are created.';
                    }
                    field("Default Person Salutation Code"; Rec."Default Person Salutation Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Person Salutation Code';
                        ToolTip = 'Specifies the salutation code to assign automatically to contact persons when they are created.';
                    }
                    field("Default Sales Cycle Code"; Rec."Default Sales Cycle Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Sales Cycle Code';
                        ToolTip = 'Specifies the sales cycle code to automatically assign to opportunities when they are created.';
                    }
                    field("Default To-do Date Calculation"; Rec."Default To-do Date Calculation")
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
                field("Mergefield Language ID"; Rec."Mergefield Language ID")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the language ID of the Windows language to use for naming the merge fields shown when editing an attachment in Microsoft Word.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Language: Codeunit Language;
                    begin
                        Language.LookupApplicationLanguageId(Rec."Mergefield Language ID");
                    end;
                }
                group("Bus. Relation Code for")
                {
                    Caption = 'Bus. Relation Code for';
                    field("Bus. Rel. Code for Customers"; Rec."Bus. Rel. Code for Customers")
                    {
                        ApplicationArea = Basic, Suite, RelationshipMgmt;
                        Caption = 'Customers';
                        ToolTip = 'Specifies the business relation code that identifies that a contact is also a customer.';
                    }
                    field("Bus. Rel. Code for Vendors"; Rec."Bus. Rel. Code for Vendors")
                    {
                        ApplicationArea = Basic, Suite, RelationshipMgmt;
                        Caption = 'Vendors';
                        ToolTip = 'Specifies the business relation code that identifies that a contact is also a vendor.';
                    }
                    field("Bus. Rel. Code for Bank Accs."; Rec."Bus. Rel. Code for Bank Accs.")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Bank Accounts';
                        ToolTip = 'Specifies the business relation code that identifies that a contact is also a bank account.';
                    }
                    field("Bus. Rel. Code for Employees"; Rec."Bus. Rel. Code for Employees")
                    {
                        ApplicationArea = Basic, Suite, RelationshipMgmt;
                        Caption = 'Employees';
                        ToolTip = 'Specifies the business relation code that identifies that a contact is also an employee.';
                    }
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Contact Nos."; Rec."Contact Nos.")
                {
                    ApplicationArea = Basic, Suite, RelationshipMgmt;
                    ToolTip = 'Specifies the code for the number series to use when assigning numbers to contacts.';
                }
                field("Campaign Nos."; Rec."Campaign Nos.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code for the number series to use when assigning numbers to campaigns.';
                }
                field("Segment Nos."; Rec."Segment Nos.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code for the number series to use when assigning numbers to segments.';
                }
                field("To-do Nos."; Rec."To-do Nos.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code for the number series to use when assigning numbers to tasks.';
                }
                field("Opportunity Nos."; Rec."Opportunity Nos.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code for the number series to use when assigning numbers to opportunities.';
                }
            }
            group(Duplicates)
            {
                Caption = 'Duplicates';
                field("Maintain Dupl. Search Strings"; Rec."Maintain Dupl. Search Strings")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the automatic update of search strings used to search for duplicates. You can set up search strings in the Duplicate Search String Setup table.';
                }
                field("Autosearch for Duplicates"; Rec."Autosearch for Duplicates")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that you want to search automatically for duplicates each time a contact is created or modified.';
                }
                field("Search Hit %"; Rec."Search Hit %")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the level of precision to apply when searching for duplicates.';
                }
            }
#if not CLEAN22
            group("Email Logging")
            {
                Caption = 'Email Logging';
                Visible = not EmailLoggingUsingGraphApiFeatureEnabled;
                ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
                ObsoleteState = Pending;
                ObsoleteTag = '22.0';

                field("Autodiscovery E-Mail Address"; Rec."Autodiscovery E-Mail Address")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the email address that you want to use in discovery of an Exchange Server. You specify a valid email address, which enables the discovery of the associated Exchange Server. You can validate the email address after you enter an address.';
                    Enabled = not EmailLoggingEnabled;
                    ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
                    ObsoleteState = Pending;
                    ObsoleteTag = '22.0';

                    trigger OnValidate()
                    begin
                        if Rec."Autodiscovery E-Mail Address" <> xRec."Autodiscovery E-Mail Address" then begin
                            OnAfterMarketingSetupEmailLoggingUsed();
                            ExchangeWebServicesClient.InvalidateService();
                        end;
                    end;
                }
                field("Exchange Service URL"; Rec."Exchange Service URL")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the address of your Exchange service. Setting this URL makes the email validation done by Validate Email Logging Setup faster.';
                    Enabled = not EmailLoggingEnabled;
                    ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
                    ObsoleteState = Pending;
                    ObsoleteTag = '22.0';

                    trigger OnValidate()
                    begin
                        if Rec."Exchange Service URL" <> xRec."Exchange Service URL" then begin
                            OnAfterMarketingSetupEmailLoggingUsed();
                            ExchangeWebServicesClient.InvalidateService();
                        end;
                    end;
                }
                field("Authentication Type"; AuthenticationType)
                {
                    ShowCaption = true;
                    Visible = not SoftwareAsAService;
                    Enabled = not EmailLoggingEnabled;
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Authentication Type';
                    OptionCaption = 'OAuth2,Basic';
                    ToolTip = 'Specifies the authentication type will be used to connect to Exchange.', Comment = 'Exchange is a name of a Microsoft Service and should not be translated.';
                    ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
                    ObsoleteState = Pending;
                    ObsoleteTag = '22.0';

                    trigger OnValidate()
                    begin
                        if SoftwareAsAService then
                            exit;

                        OnAfterMarketingSetupEmailLoggingUsed();
                        ApplyAuthenticationType();
                        ExchangeWebServicesClient.InvalidateService();
                    end;
                }
                group(OAuth2Group)
                {
                    Visible = AuthenticationType = AuthenticationType::OAuth2;
                    ShowCaption = false;
                    ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
                    ObsoleteState = Pending;
                    ObsoleteTag = '22.0';

                    field("Exchange Client Id"; Rec."Exchange Client Id")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Client ID';
                        Visible = ClientCredentialsVisible;
                        Enabled = not EmailLoggingEnabled;
                        ToolTip = 'Specifies the ID of the Microsoft Entra application that will be used to connect to Exchange.', Comment = 'Exchange and Microsoft Entra are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';
                        ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
                        ObsoleteState = Pending;
                        ObsoleteTag = '22.0';

                        trigger OnValidate()
                        begin
                            if Rec."Exchange Client Id" <> xRec."Exchange Client Id" then begin
                                OnAfterMarketingSetupEmailLoggingUsed();
                                ResetBasicAuthFields();
                                ExchangeWebServicesClient.InvalidateService();
                            end;
                        end;
                    }
                    field("Exchange Client Secret Key"; ExchangeClientSecretTemp)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Client Secret';
                        ExtendedDatatype = Masked;
                        Visible = ClientCredentialsVisible;
                        Enabled = not EmailLoggingEnabled;
                        ToolTip = 'Specifies the Microsoft Entra application secret that will be used to connect to Exchange.', Comment = 'Exchange and Microsoft Entra are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';
                        ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
                        ObsoleteState = Pending;
                        ObsoleteTag = '22.0';

                        trigger OnValidate()
                        begin
                            OnAfterMarketingSetupEmailLoggingUsed();
                            Rec.SetExchangeClientSecret(ExchangeClientSecretTemp);
                            ResetBasicAuthFields();
                            Commit();
                            ExchangeWebServicesClient.InvalidateService();
                        end;
                    }
                    field("Exchange Redirect URL"; Rec."Exchange Redirect URL")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Redirect URL';
                        ExtendedDatatype = URL;
                        Visible = ClientCredentialsVisible;
                        Enabled = not EmailLoggingEnabled;
                        ToolTip = 'Specifies the redirect URL of the Microsoft Entra application that will be used to connect to Exchange.', Comment = 'Exchange and Microsoft Entra are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';
                        ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
                        ObsoleteState = Pending;
                        ObsoleteTag = '22.0';

                        trigger OnValidate()
                        begin
                            if Rec."Exchange Redirect URL" <> xRec."Exchange Redirect URL" then begin
                                OnAfterMarketingSetupEmailLoggingUsed();
                                ResetBasicAuthFields();
                                ExchangeWebServicesClient.InvalidateService();
                            end;
                        end;
                    }
                }
                group(BasicAuthGroup)
                {
                    Visible = AuthenticationType = AuthenticationType::Basic;
                    ShowCaption = false;
                    ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
                    ObsoleteState = Pending;
                    ObsoleteTag = '22.0';

                    field("Exchange Account User Name"; Rec."Exchange Account User Name")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Exchange User';
                        ToolTip = 'Specifies the email account that the scheduled job must use to connect to Exchange and process emails.', Comment = 'Exchange is a name of a Microsoft Service and should not be translated.';
                        Visible = BasicAuthVisible;
                        Enabled = not EmailLoggingEnabled;
                        ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
                        ObsoleteState = Pending;
                        ObsoleteTag = '22.0';

                        trigger OnValidate()
                        begin
                            if Rec."Exchange Account User Name" <> xRec."Exchange Account User Name" then begin
                                OnAfterMarketingSetupEmailLoggingUsed();
                                ResetOAuth2Fields();
                                Commit();
                                ExchangeWebServicesClient.InvalidateService();
                            end;
                        end;
                    }
                    field(ExchangeAccountPasswordTemp; ExchangeAccountPasswordTemp)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Exchange Account Password';
                        ExtendedDatatype = Masked;
                        ToolTip = 'Specifies the password of the user account that has access to Exchange.';
                        Visible = BasicAuthVisible;
                        Enabled = not EmailLoggingEnabled;
                        ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
                        ObsoleteState = Pending;
                        ObsoleteTag = '22.0';

                        trigger OnValidate()
                        begin
                            OnAfterMarketingSetupEmailLoggingUsed();
                            ResetOAuth2Fields();
                            Rec.SetExchangeAccountPassword(ExchangeAccountPasswordTemp);
                            Commit();
                            ExchangeWebServicesClient.InvalidateService();
                        end;
                    }
                }
                field("Email Batch Size"; Rec."Email Batch Size")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of email messages that you want to process in one run of a job queue that has been set up to handle email logging. By default, the number of messages to process is 0, which means that email messages are not batched together. You can modify this value when you are fine tuning your process so that the execution of a job queue does not take too long. Any email message that is not logged in any particular run will be handled in a subsequent run that has been scheduled.';
                    Enabled = not EmailLoggingEnabled;
                    ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
                    ObsoleteState = Pending;
                    ObsoleteTag = '22.0';

                    trigger OnValidate()
                    begin
                        OnAfterMarketingSetupEmailLoggingUsed();
                    end;
                }
                group(Control5)
                {
                    ShowCaption = false;
                    ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
                    ObsoleteState = Pending;
#pragma warning disable AS0072
                    ObsoleteTag = '22.0';
#pragma warning restore AS0072

                    field("Queue Folder Path"; Rec."Queue Folder Path")
                    {
                        ApplicationArea = RelationshipMgmt;
                        ToolTip = 'Specifies the path of the queue folder in Microsoft Outlook.';
                        Enabled = not EmailLoggingEnabled;
                        ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
                        ObsoleteState = Pending;
                        ObsoleteTag = '22.0';

                        trigger OnAssistEdit()
                        var
                            ExchangeFolder: Record "Exchange Folder";
                            SetupEmailLogging: Codeunit "Setup Email Logging";
                        begin
                            if EmailLoggingEnabled then
                                exit;
                            ApplyAuthenticationType();
                            if not TryInitExchangeService() then
                                if AuthenticationType = AuthenticationType::OAuth2 then begin
                                    SignInExchangeAdminUser();
                                    Commit();
                                    InitExchangeService();
                                end;
                            if SetupEmailLogging.GetExchangeFolder(ExchangeWebServicesClient, ExchangeFolder, Text014) then
                                Rec.SetQueueFolder(ExchangeFolder);
                        end;
                    }
                    field("Storage Folder Path"; Rec."Storage Folder Path")
                    {
                        ApplicationArea = RelationshipMgmt;
                        ToolTip = 'Specifies the path of the storage folder in Microsoft Outlook.';
                        Enabled = not EmailLoggingEnabled;
                        ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
                        ObsoleteState = Pending;
                        ObsoleteTag = '22.0';

                        trigger OnAssistEdit()
                        var
                            ExchangeFolder: Record "Exchange Folder";
                            SetupEmailLogging: Codeunit "Setup Email Logging";
                        begin
                            if EmailLoggingEnabled then
                                exit;
                            ApplyAuthenticationType();
                            if not TryInitExchangeService() then
                                if AuthenticationType = AuthenticationType::OAuth2 then begin
                                    SignInExchangeAdminUser();
                                    Commit();
                                    InitExchangeService();
                                end;
                            if SetupEmailLogging.GetExchangeFolder(ExchangeWebServicesClient, ExchangeFolder, Text015) then
                                Rec.SetStorageFolder(ExchangeFolder);
                        end;
                    }
                }
                field("Email Logging Enabled"; EmailLoggingEnabled)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Enabled', Comment = 'Name of the check box that shows whether the Email Logging is enabled.';
                    ToolTip = 'Specifies if email logging is enabled. When you select this field, you must sign in with an administrator user account and give consent to the application that will be used to connect to Exchange.';
                    ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
                    ObsoleteState = Pending;
                    ObsoleteTag = '22.0';

                    trigger OnValidate()
                    var
                        SetupEmailLogging: Codeunit "Setup Email Logging";
                        ErrorMessage: Text;
                    begin
                        if EmailLoggingEnabled then begin
                            ApplyAuthenticationType();
                            if not TryInitExchangeService() then
                                if AuthenticationType = AuthenticationType::OAuth2 then
                                    SignInExchangeAdminUser();
                            if not ValidateEmailLoggingSetup(Rec, ErrorMessage) then
                                Error(ErrorMessage);
                            Session.LogMessage('0000CIF', EmailLoggingEnabledTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                            SetupEmailLogging.CreateEmailLoggingJobQueueSetup();
                        end else begin
                            Session.LogMessage('0000CIG', EmailLoggingDisabledTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                            SetupEmailLogging.DeleteEmailLoggingJobQueueSetup();
                            ExchangeWebServicesClient.InvalidateService();
                            if SoftwareAsAService then
                                if (Rec."Exchange Account User Name" <> '') or (not IsNullGuid(Rec."Exchange Account Password Key")) then begin
                                    Session.LogMessage('0000CPO', DisableBasicAuthenticationTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                                    if not IsNullGuid(Rec."Exchange Account Password Key") then
                                        IsolatedStorageManagement.Delete(Rec."Exchange Account Password Key", DATASCOPE::Company);
                                    Clear(Rec."Exchange Account Password Key");
                                    Clear(Rec."Exchange Account User Name");
                                end;
                        end;
                        Rec."Email Logging Enabled" := EmailLoggingEnabled;
                        Rec.Modify();
                        CurrPage.Update(false);
                    end;
                }
            }
#endif
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
#if not CLEAN22
                action("Email Logging Assisted Setup")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Email Logging Assisted Setup';
                    Image = Setup;
                    ToolTip = 'Runs Email Logging Setup Wizard.';
                    Enabled = not EmailLoggingEnabled;
                    Visible = not EmailLoggingUsingGraphApiFeatureEnabled;
                    ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
                    ObsoleteState = Pending;
                    ObsoleteTag = '22.0';

                    trigger OnAction()
                    var
                        SetupEmailLogging: Codeunit "Setup Email Logging";
                        GuidedExperience: Codeunit "Guided Experience";
                        GuidedExperienceType: Enum "Guided Experience Type";
                    begin
                        SetupEmailLogging.RegisterAssistedSetup();
                        Commit(); // Make sure all data is committed before we run the wizard
                        GuidedExperience.Run(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Setup Email Logging");
                        if Rec.Find() then
                            EmailLoggingEnabled := Rec."Email Logging Enabled";
                        CurrPage.Update(false);
                    end;
                }
                action("Validate EmailLogging Setup")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Validate Email Logging Setup';
                    Image = ValidateEmailLoggingSetup;
                    ToolTip = 'Test that email logging is set up correctly.';
                    Visible = not EmailLoggingUsingGraphApiFeatureEnabled;
                    ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
                    ObsoleteState = Pending;
                    ObsoleteTag = '22.0';

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
                    Enabled = not EmailLoggingEnabled;
                    Visible = not EmailLoggingUsingGraphApiFeatureEnabled;
                    ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
                    ObsoleteState = Pending;
                    ObsoleteTag = '22.0';

                    trigger OnAction()
                    begin
                        if Confirm(Text009, true) then
                            ClearEmailLoggingSetup(Rec);
                    end;
                }
#endif
                action("Email Logging Using Graph API")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Email Logging Setup';
                    Image = Setup;
                    ToolTip = 'Open the Email Logging Setup window.';
#if not CLEAN22
                    Visible = EmailLoggingUsingGraphApiFeatureEnabled;
#endif

                    trigger OnAction()
                    begin
                        OnRunEmailLoggingSetup();
                    end;
                }
#if not CLEAN22
#pragma warning disable AA0194
                action("Generate Integration IDs for Connector for Microsoft Dynamics")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Generate Integration IDs for Connector for Microsoft Dynamics';
                    Image = CreateSerialNo;
                    ToolTip = 'Generate identifiers (GUID) for records that can be used by Dynamics 365 Sales and in Dynamics 365.';
                    Visible = false;
                    ObsoleteReason = 'This functionality is deprecated.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '22.0';
                }
#pragma warning restore AA0194
#endif
            }
        }
    }

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
#if not CLEAN22
        SetupEmailLogging: Codeunit "Setup Email Logging";
#endif
    begin
#if not CLEAN22
        EmailLoggingUsingGraphApiFeatureEnabled := SetupEmailLogging.IsEmailLoggingUsingGraphApiFeatureEnabled();
#endif
        SoftwareAsAService := EnvironmentInfo.IsSaaSInfrastructure();
#if not CLEAN22
        ClientCredentialsVisible := not SoftwareAsAService;
        BasicAuthVisible := not SoftwareAsAService;
#endif
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        AttachmentStorageLocationEnabl := Rec."Attachment Storage Type" = Enum::"Attachment Storage Type"::"Disk File";

#if not CLEAN22
        AuthenticationType := AuthenticationType::OAuth2;
        if not SoftwareAsAService then
            if Rec."Exchange Account User Name" <> '' then
                AuthenticationType := AuthenticationType::Basic;

        if AuthenticationType = AuthenticationType::OAuth2 then begin
            ExchangeClientSecretTemp := '';
            if (Rec."Exchange Client Id" <> '') and (not IsNullGuid(Rec."Exchange Client Secret Key")) then
                ExchangeClientSecretTemp := '**********';
        end else begin
            ExchangeAccountPasswordTemp := '';
            if (Rec."Exchange Account User Name" <> '') and (not IsNullGuid(Rec."Exchange Account Password Key")) then
                ExchangeAccountPasswordTemp := '**********';
        end;

        EmailLoggingEnabled := Rec."Email Logging Enabled";
#endif
    end;

    var
#if not CLEAN22
        ExchangeWebServicesClient: Codeunit "Exchange Web Services Client";
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        ExchangeAccountPasswordTemp: Text;
        ExchangeClientSecretTemp: Text;
#endif
        AttachmentStorageLocationEnabl: Boolean;
#if not CLEAN22
        Text006: Label 'A valid email address is needed to find an instance of Exchange Server.';
        Text009: Label 'This clears the fields in your email logging setup. Do you want to continue?';
        Text010: Label 'The specified Queue folder does not exist or cannot be accessed.';
        Text011: Label 'The specified Storage folder does not exist or cannot be accessed.';
        Text012: Label 'Email logging setup was successfully validated and completed.';
        Text013: Label 'Validating #1#';
        Text014: Label 'Select Queue folder';
        Text015: Label 'Select Storage folder';
        Text016: Label 'Interaction Template Setup';
        EmailLoggingTelemetryCategoryTxt: Label 'AL Email Logging', Locked = true;
        EmailLoggingEnabledTxt: Label 'Email Logging has been enabled from Marketing Setup page', Locked = true;
        EmailLoggingDisabledTxt: Label 'Email Logging has been disabled from Marketing Setup page', Locked = true;
        DisableBasicAuthenticationTxt: Label 'Basic authentication is disabled. OAuth authentication is enforced to be used  next time.', Locked = true;
        CannotAccessRootPublicFolderErr: Label 'Could not access the root public folder with the specified user.';
        CannotInitializeConnectionToExchangeErr: Label 'Could not initialize connection to Exchange.', Comment = 'Exchange is a name of a Microsoft service and should not be translated.';
        QueueFolderNotAccessibleTxt: Label 'The specified Queue folder does not exist or cannot be accessed.';
        StorageFolderNotAccessibleTxt: Label 'The specified Storage folder does not exist or cannot be accessed.';
        EmptyAutodiscoveryEmailAddressTxt: Label 'A valid email address is needed to find an instance of Exchange Server.';
        CannotAccessRootPublicFolderTxt: Label 'Could not access the root public folder. User: %1, URL: %2', Locked = true;
        CannotInitializeConnectionToExchangeWithoutTokenTxt: Label 'Could not initialize connection to Exchange. User: %1, URL: %2', Locked = true;
        ServiceInitializedTxt: Label 'Service has been initalized.', Locked = true;
        ServiceValidatedTxt: Label 'Service has been validated.', Locked = true;
        ExchangeTenantIdNotSpecifiedTxt: Label 'Exchange tenant ID is not specified.', Locked = true;
        ExchangeAccountNotSpecifiedTxt: Label 'Exchange account is not specified.', Locked = true;
        ExchangeAccountSpecifiedTxt: Label 'Exchange account is specified.', Locked = true;
        SignInAdminTxt: Label 'Sign in Exchange admin user.', Locked = true;
        ServiceNotInitializedTxt: Label 'Service is not initialized.', Locked = true;
        EmailLoggingSetupValidatedTxt: Label 'Email logging setup has been validated.', Locked = true;
        InteractionTemplateSetupNotConfiguredTxt: Label 'Interaction Template Setup is not configured.', Locked = true;
#endif
        SoftwareAsAService: Boolean;
#if not CLEAN22
        ClientCredentialsVisible: Boolean;
        BasicAuthVisible: Boolean;
        EmailLoggingEnabled: Boolean;
        EmailLoggingUsingGraphApiFeatureEnabled: Boolean;
        AuthenticationType: Option OAuth2,Basic;
#endif

    procedure SetAttachmentStorageType()
    begin
        if (Rec."Attachment Storage Type" = "Attachment Storage Type"::Embedded) or
           (Rec."Attachment Storage Location" <> '')
        then begin
            Rec.Modify();
            Commit();
            REPORT.Run(REPORT::"Relocate Attachments");
        end;
    end;

    procedure SetAttachmentStorageLocation()
    begin
        if Rec."Attachment Storage Location" <> '' then begin
            Rec.Modify();
            Commit();
            REPORT.Run(REPORT::"Relocate Attachments");
        end;
    end;

    local procedure AttachmentStorageTypeOnAfterVa()
    begin
        AttachmentStorageLocationEnabl := Rec."Attachment Storage Type" = Enum::"Attachment Storage Type"::"Disk File";
        SetAttachmentStorageType();
    end;

    local procedure AttachmentStorageLocationOnAft()
    begin
        SetAttachmentStorageLocation();
    end;

#if not CLEAN22
    [TryFunction]
    [NonDebuggable]
    local procedure TryInitExchangeService()
    begin
        InitExchangeService();
    end;

    [Obsolete('Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0', '22.0')]
    [Scope('OnPrem')]
    [NonDebuggable]
    procedure InitExchangeService()
    var
        TempExchangeFolder: Record "Exchange Folder" temporary;
        SetupEmailLogging: Codeunit "Setup Email Logging";
        WebCredentials: DotNet WebCredentials;
        OAuthCredentials: DotNet OAuthCredentials;
        TenantId: Text;
        Token: SecretText;
        Initialized: Boolean;
    begin
        if Rec."Autodiscovery E-Mail Address" = '' then begin
            Session.LogMessage('0000D91', EmptyAutodiscoveryEmailAddressTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Error(Text006);
        end;

        ExchangeWebServicesClient.InvalidateService();

        TenantId := Rec.GetExchangeTenantId();
        if TenantId <> '' then begin
            Session.LogMessage('0000D92', ExchangeTenantIdNotSpecifiedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            SetupEmailLogging.GetClientCredentialsAccessToken(TenantId, Token);
            CreateOAuthCredentials(OAuthCredentials, Token);
            Initialized := ExchangeWebServicesClient.InitializeOnServerWithImpersonation(Rec."Autodiscovery E-Mail Address", Rec."Exchange Service URL", OAuthCredentials);
        end else
            if Rec."Exchange Account User Name" <> '' then begin
                Session.LogMessage('0000D93', ExchangeAccountSpecifiedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                Rec.CreateExchangeAccountCredentials(WebCredentials);
                Initialized := ExchangeWebServicesClient.InitializeOnServer(Rec."Autodiscovery E-Mail Address", Rec."Exchange Service URL", WebCredentials.Credentials);
            end else begin
                Session.LogMessage('0000D94', ExchangeAccountNotSpecifiedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                Initialized := ExchangeWebServicesClient.InitializeOnClient(Rec."Autodiscovery E-Mail Address", Rec."Exchange Service URL");
            end;

        if not Initialized then begin
            Session.LogMessage('0000D95', StrSubstNo(CannotInitializeConnectionToExchangeWithoutTokenTxt, Rec."Autodiscovery E-Mail Address", Rec."Exchange Service URL"), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Error(CannotInitializeConnectionToExchangeErr);
        end;

        Session.LogMessage('0000D96', ServiceInitializedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

        ExchangeWebServicesClient.GetPublicFolders(TempExchangeFolder);
        if TempExchangeFolder.IsEmpty() then begin
            Session.LogMessage('0000D97', StrSubstNo(CannotAccessRootPublicFolderTxt, Rec."Autodiscovery E-Mail Address", Rec."Exchange Service URL"), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Error(CannotAccessRootPublicFolderErr);
        end;

        Session.LogMessage('0000D98', ServiceValidatedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
    end;

    [NonDebuggable]
    local procedure CreateOAuthCredentials(var OAuthCredentials: DotNet OAuthCredentials; Token: SecretText)
    begin
        OAuthCredentials := OAuthCredentials.OAuthCredentials(Token.Unwrap());
    end;

    [NonDebuggable]
    local procedure SignInExchangeAdminUser()
    var
        SetupEmailLogging: Codeunit "Setup Email Logging";
        Token: Text;
        TenantId: Text;
    begin
        Session.LogMessage('0000D99', SignInAdminTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
        if Rec."Autodiscovery E-Mail Address" = '' then begin
            Session.LogMessage('0000D9A', EmptyAutodiscoveryEmailAddressTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Error(Text006);
        end;

        SetupEmailLogging.PromptAdminConsent(Token);
        SetupEmailLogging.ExtractTenantIdFromAccessToken(TenantId, Token);
        Rec.SetExchangeTenantId(TenantId);
    end;

    [Obsolete('Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0', '22.0')]
    [Scope('OnPrem')]
    procedure ClearEmailLoggingSetup(var MarketingSetup: Record "Marketing Setup")
    var
        SetupEmailLogging: Codeunit "Setup Email Logging";
    begin
        ExchangeWebServicesClient.InvalidateService();
        SetupEmailLogging.ClearEmailLoggingSetup(MarketingSetup);
    end;

    [NonDebuggable]
    local procedure ValidateEmailLoggingSetup(var MarketingSetup: Record "Marketing Setup"; var ErrorMsg: Text): Boolean
    var
        EmailLoggingDispatcher: Codeunit "Email Logging Dispatcher";
        ProgressWindow: Dialog;
        ValidationCaption: Text;
    begin
        ValidationCaption := Rec.FieldCaption("Autodiscovery E-Mail Address");
        ProgressWindow.Open(Text013, ValidationCaption);

        if not TryInitExchangeService() then begin
            Session.LogMessage('0000D9E', ServiceNotInitializedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            ErrorMsg := GetLastErrorText();
            exit(false);
        end;

        ValidationCaption := Rec.FieldCaption("Queue Folder Path");
        ProgressWindow.Update();
        if not ExchangeWebServicesClient.FolderExists(MarketingSetup.GetQueueFolderUID()) then begin
            Session.LogMessage('0000D9F', QueueFolderNotAccessibleTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            ErrorMsg := Text010;
            exit(false);
        end;

        ValidationCaption := Rec.FieldCaption("Storage Folder Path");
        ProgressWindow.Update();
        if not ExchangeWebServicesClient.FolderExists(MarketingSetup.GetStorageFolderUID()) then begin
            Session.LogMessage('0000D9G', StorageFolderNotAccessibleTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            ErrorMsg := Text011;
            exit(false);
        end;

        // Emails cannot be automatically logged unless Interaction Template Setup configured correctly.
        ValidationCaption := Text016;
        ProgressWindow.Update();
        if not EmailLoggingDispatcher.CheckInteractionTemplateSetup(ErrorMsg) then begin
            Session.LogMessage('0000D9H', InteractionTemplateSetupNotConfiguredTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit(false);
        end;

        ProgressWindow.Close();
        Clear(ErrorMsg);
        MarketingSetup.Modify();

        OnAfterMarketingSetupEmailLoggingCompleted();
        Session.LogMessage('0000D9I', EmailLoggingSetupValidatedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
        exit(true);
    end;

    local procedure ApplyAuthenticationType()
    begin
        if AuthenticationType = AuthenticationType::OAuth2 then
            ResetBasicAuthFields()
        else
            ResetOAuth2Fields();
    end;

    local procedure ResetBasicAuthFields()
    var
        EmptyPassword: Text;
    begin
        if SoftwareAsAService then
            exit;

        Rec."Exchange Account User Name" := '';
        EmptyPassword := '';
        Rec.SetExchangeAccountPassword(EmptyPassword);
        Commit();
    end;

    local procedure ResetOAuth2Fields()
    var
        EmptySecret: Text;
    begin
        if SoftwareAsAService then
            exit;

        Rec.ResetExchangeTenantId();
        Rec."Exchange Client Id" := '';
        EmptySecret := '';
        Rec.SetExchangeClientSecret(EmptySecret);
        Commit();
    end;

    [Obsolete('Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0', '22.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterMarketingSetupEmailLoggingUsed()
    begin
    end;

    [Obsolete('Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0', '22.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterMarketingSetupEmailLoggingCompleted()
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnRunEmailLoggingSetup()
    begin
    end;
}

