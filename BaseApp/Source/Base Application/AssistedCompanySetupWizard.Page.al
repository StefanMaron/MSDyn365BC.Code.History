// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using System.Email;
using System.IO;
using System.Reflection;
using System.Utilities;
using System.Integration;
using System.Environment;
using System.Environment.Configuration;
using System.Azure.Identity;
using Microsoft.Finance.VAT.Registration;

page 1803 "Assisted Company Setup Wizard"
{
    Caption = 'Company Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = NavigatePage;
    ShowFilter = false;
    SourceTable = "Config. Setup";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control96)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND NOT DoneVisible;
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control98)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND DoneVisible;
                field("MediaResourcesDone.""Media Reference"""; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control8)
            {
                ShowCaption = false;
                Visible = IntroVisible;
                group("Welcome to Company Setup.")
                {
                    Caption = 'Welcome to Company Setup.';
                    InstructionalText = 'To get started with Business Central, you must provide some basic information about your company. This information is used on external documents, such as sales invoices, and includes your company logo.';
                }
                group("Let's go!")
                {
                    Caption = 'Let''s go!';
                    InstructionalText = 'Choose Next so you can specify basic company information.';
                }
            }
#if not CLEAN21
#pragma warning disable AL0432
            group(Control18)
            {
                ShowCaption = false;
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Configuration package importing logic is seperated from this wizard, after introducting checklist.';
                ObsoleteTag = '21.0';
                group("Standard Setup")
                {
                    Caption = 'Standard Setup';
                    InstructionalText = 'The company will be ready to use when Setup has completed.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Configuration package importing logic is seperated from this wizard, after introducting checklist.';
                    ObsoleteTag = '21.0';
                    field(Standard; TypeStandard)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Set up as Standard';
                        ObsoleteState = Pending;
                        ObsoleteReason = 'Configuration package importing logic is seperated from this wizard, after introducting checklist.';
                        ObsoleteTag = '21.0';
                    }
                }
                group("Evaluation Setup")
                {
                    Caption = 'Evaluation Setup';
                    InstructionalText = 'The company will be set up in demonstration mode for exploring and testing.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Configuration package importing logic is seperated from this wizard, after introducting checklist.';
                    ObsoleteTag = '21.0';
                    field(Evaluation; TypeEvaluation)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Set up as Evaluation';
                        ObsoleteState = Pending;
                        ObsoleteReason = 'Configuration package importing logic is seperated from this wizard, after introducting checklist.';
                        ObsoleteTag = '21.0';
                    }
                }
                group(Important)
                {
                    Caption = 'Important';
                    InstructionalText = 'You cannot change your choice of setup after you choose Next.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Configuration package importing logic is seperated from this wizard, after introducting checklist.';
                    ObsoleteTag = '21.0';
                }
            }
#pragma warning restore
#endif
            group(Control56)
            {
                ShowCaption = false;
                Visible = CompanyDetailsVisible;
                group("Specify your company's address information and logo.")
                {
                    Caption = 'Specify your company''s address information and logo.';
                    InstructionalText = 'This is used in invoices and other documents where general information about your company is printed.';
                    field(Name; Rec.Name)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Company Name';
                        NotBlank = true;
                        ShowMandatory = true;
                    }
                    field(Address; Rec.Address)
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Address 2"; Rec."Address 2")
                    {
                        ApplicationArea = Basic, Suite;
                        Visible = false;
                    }
                    field("Post Code"; Rec."Post Code")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field(City; Rec.City)
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = Basic, Suite;
                        TableRelation = "Country/Region".Code;
                    }
                    field("VAT Registration No."; Rec."VAT Registration No.")
                    {
                        ApplicationArea = Basic, Suite;

                        trigger OnValidate()
                        var
                            VATRegistrationNoFormat: Record "VAT Registration No. Format";
                            VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
                            VATRegistrationLog: Record "VAT Registration Log";
                            VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
                            ResultRecordRef: RecordRef;
                        begin
                            Rec."VAT Registration No." := UpperCase(Rec."VAT Registration No.");
                            if Rec."VAT Registration No." = xRec."VAT Registration No." then
                                exit;
                            if not VATRegistrationNoFormat.Test(Rec."VAT Registration No.", Rec."Country/Region Code", '', DATABASE::"Company Information") then
                                exit;
                            if Rec."Country/Region Code" = '' then
                                exit;
                            if VATRegNoSrvConfig.VATRegNoSrvIsEnabled() then begin
                                VATRegistrationLogMgt.ValidateVATRegNoWithVIES(ResultRecordRef, Rec, Rec."Primary Key",
                                  VATRegistrationLog."Account Type"::"Company Information".AsInteger(), Rec."Country/Region Code");
                                ResultRecordRef.SetTable(Rec);
                            end;
                        end;
                    }
                    field("Industrial Classification"; Rec."Industrial Classification")
                    {
                        ApplicationArea = Basic, Suite;
                        NotBlank = true;
                        ShowMandatory = true;
                        Visible = false;
                    }
                    field(Picture; Rec.Picture)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Company Logo';

                        trigger OnValidate()
                        begin
                            LogoPositionOnDocumentsShown := Rec.Picture.HasValue;
                            if LogoPositionOnDocumentsShown then begin
                                if Rec."Logo Position on Documents" = Rec."Logo Position on Documents"::"No Logo" then
                                    Rec."Logo Position on Documents" := Rec."Logo Position on Documents"::Right;
                            end else
                                Rec."Logo Position on Documents" := Rec."Logo Position on Documents"::"No Logo";
                            CurrPage.Update(true);
                        end;
                    }
                }
            }
            group(Control45)
            {
                ShowCaption = false;
                Visible = CommunicationDetailsVisible;
                group("Specify the contact details for your company.")
                {
                    Caption = 'Specify the contact details for your company.';
                    InstructionalText = 'This is used in invoices and other documents where general information about your company is printed.';
                    field("Phone No."; Rec."Phone No.")
                    {
                        ApplicationArea = Basic, Suite;

                        trigger OnValidate()
                        var
                            TypeHelper: Codeunit "Type Helper";
                        begin
                            if Rec."Phone No." = '' then
                                exit;

                            if not TypeHelper.IsPhoneNumber(Rec."Phone No.") then
                                Error(InvalidPhoneNumberErr)
                        end;
                    }
                    field("E-Mail"; Rec."E-Mail")
                    {
                        ApplicationArea = Basic, Suite;
                        ExtendedDatatype = EMail;

                        trigger OnValidate()
                        var
                            MailManagement: Codeunit "Mail Management";
                        begin
                            if Rec."E-Mail" = '' then
                                exit;

                            MailManagement.CheckValidEmailAddress(Rec."E-Mail");
                        end;
                    }
                    field("Home Page"; Rec."Home Page")
                    {
                        ApplicationArea = Basic, Suite;

                        trigger OnValidate()
                        var
                            WebRequestHelper: Codeunit "Web Request Helper";
                        begin
                            if Rec."Home Page" = '' then
                                exit;

                            WebRequestHelper.IsValidUriWithoutProtocol(Rec."Home Page");
                        end;
                    }
                }
            }
            group(Control37)
            {
                ShowCaption = false;
                Visible = PaymentDetailsVisible;
                group("Specify your company's bank information.")
                {
                    Caption = 'Specify your company''s bank information.';
                    InstructionalText = 'This information is included on documents that you send to customer and vendors to inform about payments to your bank account.';
                    field("Bank Name"; Rec."Bank Name")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Bank Branch No."; Rec."Bank Branch No.")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Bank Account No."; Rec."Bank Account No.")
                    {
                        ApplicationArea = Basic, Suite;

                        trigger OnValidate()
                        begin
                            ShowBankAccountCreationWarning := not ValidateBankAccountNotEmpty();
                        end;
                    }
                    field("SWIFT Code"; Rec."SWIFT Code")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field(IBAN; Rec.IBAN)
                    {
                        ApplicationArea = Basic, Suite;
                    }
                }
                group(" ")
                {
                    Caption = ' ';
                    InstructionalText = 'To create a bank account that is linked to the related online bank account, you must specify the bank account information above.';
                    Visible = ShowBankAccountCreationWarning;
                }
            }
            group(Control9)
            {
                ShowCaption = false;
                Visible = DoneVisible;
                group("That's it!")
                {
                    Caption = 'That''s it!';
                    InstructionalText = 'Choose Finish to prepare the application for first use. This will take a few moments.';
                    field(HelpLbl; HelpLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            HyperLink(HelpLinkTxt);
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
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Back';
                Enabled = BackEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next';
                Enabled = NextEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                Enabled = FinishEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    GuidedExperience: Codeunit "Guided Experience";
                    AssistedCompanySetup: Codeunit "Assisted Company Setup";
                    ErrorText: Text;
                begin
                    BankAccount.TransferFields(TempBankAccount, true);
                    AssistedCompanySetup.ApplyUserInput(Rec, BankAccount, AccountingPeriodStartDate, false);

                    UpdateCompanyDisplayNameIfNameChanged();

                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Assisted Company Setup Wizard");
                    if (BankAccount."No." <> '') and (not TempOnlineBankAccLink.IsEmpty) then
                        if not TryLinkBankAccount() then
                            ErrorText := GetLastErrorText;
                    CurrPage.Close();

                    if ErrorText <> '' then begin
                        Message(StrSubstNo(BankAccountLinkingFailedMsg, ErrorText));
                        PAGE.Run(PAGE::"Bank Account List");
                    end;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LogoPositionOnDocumentsShown := Rec.Picture.HasValue;
    end;

    trigger OnInit()
    begin
        InitializeRecord();
        LoadTopBanners();
    end;

    trigger OnOpenPage()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        Clear(AccountingPeriodStartDate);

        ResetWizardControls();
        ShowIntroStep();

        if EnvironmentInfo.IsSaaS() then
            GetCompanyDetailsFromMicrosoft365();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        if CloseAction = ACTION::OK then
            if GuidedExperience.AssistedSetupExistsAndIsNotComplete(ObjectType::Page, PAGE::"Assisted Company Setup Wizard") then
                if not Confirm(NotSetUpQst, false) then
                    Error('');
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        TempBankAccount: Record "Bank Account" temporary;
        BankAccount: Record "Bank Account";
        TempOnlineBankAccLink: Record "Online Bank Acc. Link" temporary;
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        CompanyInfoNotification: Notification;
        AccountingPeriodStartDate: Date;
#if not CLEAN21
        TypeStandard: Boolean;
        TypeEvaluation: Boolean;
#endif
        Step: Option Intro,"Company Details","Communication Details","Payment Details",Done;
        BackEnabled: Boolean;
        NextEnabled: Boolean;
        FinishEnabled: Boolean;
        TopBannerVisible: Boolean;
        IntroVisible: Boolean;
        CompanyDetailsVisible: Boolean;
        CommunicationDetailsVisible: Boolean;
        PaymentDetailsVisible: Boolean;
        DoneVisible: Boolean;
        ShowCompanyInfoDownloadedNotification: Boolean;
        IsCompanyInfoDownloadedNotificationEnabled: Boolean;
        NotificationSent: Boolean;
        CompanyInfoDownloadedMsg: Label 'The information on this page was downloaded from Microsoft 365. Before you proceed, verify that it''s correct.';
        NotSetUpQst: Label 'The application is not set up. This guide will display the next time you sign in. If you do not want the guide to start, go to the Companies page and turn off the guide.\\Are you sure that you want to close this guide?';
        HelpLbl: Label 'Learn more about setting up your company';
        HelpLinkTxt: Label 'http://go.microsoft.com/fwlink/?LinkId=746160', Locked = true;
        LogoPositionOnDocumentsShown: Boolean;
        ShowBankAccountCreationWarning: Boolean;
        InvalidPhoneNumberErr: Label 'The phone number is invalid.';
        BankAccountLinkingFailedMsg: Label 'Linking the company bank account failed with the following message:\''%1''\Link the company bank account from the Bank Accounts page.', Comment = '%1 - an error message';
        GraphURLEndpointLbl: Label '%1v1.0/organization', Locked = true;
        ResourceNameTxt: Label 'Azure Service', Locked = true;
        BearerLbl: Label 'Bearer %1', Comment = '%1 = Access Token', Locked = true;

    local procedure NextStep(Backwards: Boolean)
    begin
        ResetWizardControls();

        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        case Step of
            Step::Intro:
                ShowIntroStep();
            Step::"Company Details":
                begin
                    SendCompanyInfoDownloadedFromOfficeNotification();
                    ShowCompanyDetailsStep();
                end;
            Step::"Communication Details":
                ShowCommunicationDetailsStep();
            Step::"Payment Details":
                begin
                    ShowPaymentDetailsStep();
                    ShowBankAccountCreationWarning := not ValidateBankAccountNotEmpty();
                end;
            Step::Done:
                begin
                    HideCompanyInfoDownloadedFromOfficeNotification();
                    ShowDoneStep();
                end;
        end;
        CurrPage.Update(true);
    end;

    local procedure ShowIntroStep()
    begin
        IntroVisible := true;
        BackEnabled := false;
    end;

    local procedure ShowCompanyDetailsStep()
    begin
        CompanyDetailsVisible := true;
    end;

    local procedure ShowCommunicationDetailsStep()
    begin
        CommunicationDetailsVisible := true;
    end;

    local procedure ShowPaymentDetailsStep()
    begin
        PaymentDetailsVisible := true;
    end;

    local procedure ShowDoneStep()
    begin
        DoneVisible := true;
        NextEnabled := false;
        FinishEnabled := true;
    end;

    local procedure ResetWizardControls()
    begin
        // Buttons
        BackEnabled := true;
        NextEnabled := true;
        FinishEnabled := false;

        // Tabs
        IntroVisible := false;
        CompanyDetailsVisible := false;
        CommunicationDetailsVisible := false;
        PaymentDetailsVisible := false;
        DoneVisible := false;
    end;

    local procedure InitializeRecord()
    var
        CompanyInformation: Record "Company Information";
    begin
        Rec.Init();

        if CompanyInformation.Get() then begin
            Rec.TransferFields(CompanyInformation);
            if Rec.Name = '' then
                Rec.Name := CompanyName;
        end else
            Rec.Name := CompanyName;

        Rec.Insert();
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;
    end;

    local procedure ValidateBankAccountNotEmpty(): Boolean
    begin
        exit((Rec."Bank Account No." <> '') or TempOnlineBankAccLink.IsEmpty);
    end;

    [TryFunction]
    local procedure TryLinkBankAccount()
    begin
        BankAccount.OnMarkAccountLinkedEvent(TempOnlineBankAccLink, BankAccount);
    end;

    local procedure UpdateCompanyDisplayNameIfNameChanged()
    var
        Company: Record Company;
    begin
        if COMPANYPROPERTY.DisplayName() = Rec.Name then
            exit;

        Company.Get(CompanyName);
        Company."Display Name" := Rec.Name;
        Company.Modify();
    end;

    local procedure GetCompanyDetailsFromMicrosoft365()
    var
        JsonCompanyInfo: JsonObject;
    begin
        if TryDownloadCompanyDetailsFromMicrosoft365(JsonCompanyInfo) then
            if JsonCompanyInfo.Keys().Count > 0 then begin
                SetCompanyInfo(JsonCompanyInfo);
                ShowCompanyInfoDownloadedNotification := true;
            end;
    end;

    [NonDebuggable]
    [TryFunction]
    local procedure TryDownloadCompanyDetailsFromMicrosoft365(var JsonCompanyInfo: JsonObject)
    var
        AzureADMgt: Codeunit "Azure AD Mgt.";
        UrlHelper: Codeunit "Url Helper";
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        JsonResponse: JsonObject;
        JsonPropValue: JsonToken;
        CompaniesJsonArray: JsonArray;
        JsonContent: Text;
        AccessToken: Text;
    begin
        AccessToken := AzureADMgt.GetAccessToken(UrlHelper.GetGraphUrl(), ResourceNameTxt, false);
        RequestMessage.Method('GET');
        RequestMessage.SetRequestUri(StrSubstNo(GraphURLEndpointLbl, UrlHelper.GetGraphUrl()));
        Client.DefaultRequestHeaders().Add('Authorization', StrSubstNo(BearerLbl, AccessToken));
        Client.DefaultRequestHeaders().Add('Accept', 'application/json');

        if Client.Send(RequestMessage, ResponseMessage) then
            if ResponseMessage.HttpStatusCode() = 200 then begin
                ResponseMessage.Content.ReadAs(JsonContent);
                JsonResponse.ReadFrom(JsonContent);
                JsonResponse.Get('value', JsonPropValue);
                CompaniesJsonArray := JsonPropValue.AsArray();
                // if there are multiple companies do not automatically update the info
                if CompaniesJsonArray.Count() <> 1 then
                    exit;

                CompaniesJsonArray.Get(0, JsonPropValue);
                JsonCompanyInfo := JsonPropValue.AsObject();
            end
    end;

    local procedure SetCompanyInfo(CompanyInfoObj: JsonObject)
    var
        JsonPropValue: JsonToken;
    begin
        CompanyInfoObj.Get('displayName', JsonPropValue);
        Rec.Name := CopyStr(ProcessJsonPropertyValue(JsonPropValue), 1, MaxStrLen(Rec.Name));

        CompanyInfoObj.Get('street', JsonPropValue);
        Rec.Address := CopyStr(ProcessJsonPropertyValue(JsonPropValue), 1, MaxStrLen(Rec.Address));

        CompanyInfoObj.Get('postalCode', JsonPropValue);
        Rec."Post Code" := CopyStr(ProcessJsonPropertyValue(JsonPropValue), 1, MaxStrLen(Rec."Post Code"));

        CompanyInfoObj.Get('city', JsonPropValue);
        Rec.City := CopyStr(ProcessJsonPropertyValue(JsonPropValue), 1, MaxStrLen(Rec.City));

        CompanyInfoObj.Get('countryLetterCode', JsonPropValue);
        Rec."Country/Region Code" := CopyStr(ProcessJsonPropertyValue(JsonPropValue), 1, MaxStrLen(Rec."Country/Region Code"));

        CurrPage.Update();
    end;

    local procedure ProcessJsonPropertyValue(JsonPropValue: JsonToken): Text;
    var
        Str: Text;
    begin
        Str := Format(JsonPropValue);
        Str := DelChr(Str, '=', '"');
        if Str = 'null' then
            exit('');
        exit(Str);
    end;

    local procedure SendCompanyInfoDownloadedFromOfficeNotification()
    begin
        if ShowCompanyInfoDownloadedNotification and not NotificationSent then begin
            NotificationSent := true;
            IsCompanyInfoDownloadedNotificationEnabled := true;
            CompanyInfoNotification.Message := CompanyInfoDownloadedMsg;
            CompanyInfoNotification.Send();
        end;
    end;

    local procedure HideCompanyInfoDownloadedFromOfficeNotification()
    begin
        if IsCompanyInfoDownloadedNotificationEnabled then begin
            IsCompanyInfoDownloadedNotificationEnabled := false;
            CompanyInfoNotification.Recall();
        end;
    end;
}
