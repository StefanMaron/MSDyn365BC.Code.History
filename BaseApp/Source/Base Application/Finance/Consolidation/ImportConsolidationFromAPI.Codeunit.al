﻿namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using System.Azure.KeyVault;
using System.Environment;
using System.Reflection;
using System.Security.Authentication;
using System.Telemetry;
using System.Utilities;

codeunit 102 "Import Consolidation from API"
{
    Access = Internal;
    Permissions = tabledata "General Ledger Setup" = R,
                  tabledata "Gen. Journal Batch" = R;

    var
        ConsolidationSetup: Record "Consolidation Setup";
        Consolidate: Codeunit "Consolidate";
        CurrentAADTenantId: Text;
        BusinessUnitAPIBaseUrl: Text;
        UrlNotBCMsg: Label 'The URL provided is not in the businesscentral.dynamics.com domain. Do you want to continue?';
        BusinessUnitNotConfiguredForAPIErr: Label 'Business unit %1 is not configured for API import. You can configure it in the "Business Unit" card page.', Comment = '%1 - Business unit code';
        EntriesAtClosingDateErr: Label 'Entries posted in a closing date %1 were found while consolidating G/L account %2', Comment = '%1 - Closing date, %2 - G/L account no.';
        APIStatusCodeErr: Label 'API call to subsidiary BC company failed with status code %1 - %2', Comment = '%1 - Status code, %2 - Status text';
        APITooManyRequestsErr: Label 'Too many requests to subsidiary BC company''s API. Attempt the consolidation when no other processes are using the APIs or configure the thresholds in the "Consolidation Setup" page.';
        APIGetSingleGotOtherErr: Label 'API call expected 1 result, got %1', Comment = '%1 - Number of results';
        NeedSelectCompanyErr: Label 'You need to select a company to extract data from.';
        SelectOnlyOneCompanyErr: Label 'You can only select one company per business unit.';
        PrivacyConsentNoGUIErr: Label 'Getting privacy consent requires user interaction.';
        BusinessUnitConsentErr: Label 'The business unit %1 needs to consent for their data to be transferred to the consolidation company. Open the page Consolidation Setup in that company and enable the company as subsidiary.', Comment = '%1 - Business unit code';
        ExchangeRateNotDefinedInBusinessUnitErr: Label 'Exchange rate for %1 is not defined in Business Unit.', Comment = '%1 - Currency Code';
        PostingDateFilterTok: Label 'postingDate ge %1 and postingDate le %2', Locked = true, Comment = '%1 - Starting date, %2 - Ending date';
        CurrencyCodeFilterTok: Label 'currencyCode eq ''%1''', Locked = true, Comment = '%1 - Currency code';
        DimensionCodeFilterTok: Label 'code eq ''%1''', Locked = true, Comment = '%1 - Dimension code';
        DimensionConsolidationCodeFilterTok: Label 'consolidationCode eq ''%1''', Locked = true, Comment = '%1 - Dimension code';
        GLAccountFilterTok: Label 'accountNumber eq ''%1''', Locked = true, Comment = '%1 - G/L account no.';
        ClientIdAKVKeyTok: Label 'bctobc-finconsolid-clientid', Locked = true;
        ClientCertificateAKVKeyTok: Label 'bctobc-finconsolid-clientcertname', Locked = true;
        ClientSecretAKVKeyTok: Label 'bctobc-finconsolid-clientsecret', Locked = true;
        AuthorityURLTok: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/authorize', Locked = true;
        PPEAuthorityURLTok: Label 'https://login.windows-ppe.net/%1/oauth2', Locked = true;
        FinancialsScopeTok: Label 'https://api.businesscentral.dynamics.com/Financials.ReadWrite.All', Locked = true;
        PPEFinancialsScopeTok: Label 'https://api.businesscentral.dynamics-tie.com/.default', Locked = true;
        RedirectURLTok: Label 'https://businesscentral.dynamics.com/OAuthLanding.htm', Locked = true;
        PPERedirectUrlTok: Label 'https://businesscentral.dynamics-tie.com/OAuthLanding.htm', Locked = true;
        TelemetryCategoyTok: Label 'financial-consolidations', Locked = true;
        GetTokenCalledFromOnPremMsg: Label 'Get token called from OnPrem', Locked = true;
        RefreshingTokenMsg: Label 'Refreshing token for Financial Consolidations', Locked = true;
        AKVSecretNotFoundMsg: Label 'AKV key not found', Locked = true;
        FeatureTelemetryNameTok: Label 'Financial Consolidations - API', Locked = true;
        ApiVersionTok: Label 'v2.0', Locked = true;
        CompaniesEndpointSegmentTok: Label '/companies', Locked = true;
        CurrencyExchangeRatesSegmentTok: Label '/currencyExchangeRates', Locked = true;
        LastCurrencyExchangeRateQueryOptionsTok: Label '$filter=%1 and startingDate le %2&$orderby=startingDate desc&$top=1&$count=true', Locked = true, Comment = '%1 - Currency code filter, %2 - Date';

    internal procedure GetPrivacyConsentChoice(): Boolean
    var
        PrivacyStatement: Page "Privacy Statement";
    begin
        if not GuiAllowed() then
            Error(PrivacyConsentNoGUIErr);
        if PrivacyStatement.RunModal() <> Action::OK then
            exit(false);
        exit(PrivacyStatement.GetConsentState());
    end;

    internal procedure GetFeatureTelemetryName(): Text
    begin
        exit(FeatureTelemetryNameTok);
    end;

    [NonDebuggable()]
    internal procedure AcquireTokenAndStoreInIsolatedStorage(BusinessUnit: Record "Business Unit")
    var
        StorageKey, Token : Text;
    begin
        SetAADTenantId(BusinessUnit."AAD Tenant ID");
        StorageKey := IsolatedStorageKey(CurrentAADTenantId);
        Token := GetToken(CurrentAuthorityUrl());
        if (not EncryptionEnabled()) or (StrLen(Token) > 215) then
            IsolatedStorage.Set(StorageKey, Token, DataScope::Company)
        else
            IsolatedStorage.SetEncrypted(StorageKey, Token, DataScope::Company);
    end;

    [NonDebuggable()]
    internal procedure IsStoredTokenValidForBusinessUnit(BusinessUnit: Record "Business Unit"): Boolean
    var
        StatusCode: Integer;
        Token, StatusReason, StorageKey : Text;
    begin
        StorageKey := IsolatedStorageKey(GuidToText(BusinessUnit."AAD Tenant ID"));
        if not IsolatedStorage.Contains(StorageKey, DataScope::Company) then
            exit(false);
        IsolatedStorage.Get(StorageKey, DataScope::Company, Token);
        HttpGetText(TestEndpointForBusinessUnit(BusinessUnit), Token, StatusCode, StatusReason);
        if StatusCode <> 200 then
            exit(false);
        exit(true);
    end;

    local procedure CurrentAuthorityUrl(): Text
    begin
        if IsPPE() then
            exit(StrSubstNo(PPEAuthorityURLTok, CurrentAADTenantId));
        exit(StrSubstNo(AuthorityURLTok, CurrentAADTenantId));
    end;

    local procedure IsPPE(): Boolean
    begin
        exit(StrPos(LowerCase(GetUrl(ClientType::Web)), 'businesscentral.dynamics-tie.com') <> 0);
    end;

    internal procedure GetCurrencyFactorFromBusinessUnit(var BusinessUnit: Record "Business Unit"): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        QueryOptions, Response : Text;
        ExchangeRateAmount, Result : Decimal;
        ExchangeRatesCount: Integer;
        JsonObject: JsonObject;
        JsonToken: JsonToken;
    begin
        SetAADTenantId(BusinessUnit."AAD Tenant ID");
        if not IsStoredTokenValidForBusinessUnit(BusinessUnit) then
            AcquireTokenAndStoreInIsolatedStorage(BusinessUnit);

        GeneralLedgerSetup.Get();
        QueryOptions := StrSubstNo(LastCurrencyExchangeRateQueryOptionsTok, StrSubstNo(CurrencyCodeFilterTok, GeneralLedgerSetup."LCY Code"), FormatDateForAPICall(WorkDate()));
        Response := HttpGetTextWithStatusHandling(APIV2RootEndpointForBusinessUnit(BusinessUnit) + CurrencyExchangeRatesSegmentTok + '?' + QueryOptions);
        ExchangeRatesCount := ParseCount(Response);
        if ExchangeRatesCount = 0 then
            Error(ExchangeRateNotDefinedInBusinessUnitErr, GeneralLedgerSetup."LCY Code");
        JsonObject := ParseDataSingle(Response);
        JsonObject.Get('exchangeRateAmount', JsonToken);
        ExchangeRateAmount := JsonToken.AsValue().AsDecimal();
        if ExchangeRateAmount = 0 then
            exit(0);
        JsonObject.Get('relationalExchangeRateAmount', JsonToken);
        Result := JsonToken.AsValue().AsDecimal() / ExchangeRateAmount;
        exit(Result);
    end;

    internal procedure SelectCompanyForBusinessUnit(var BusinessUnit: Record "Business Unit")
    var
        TempCompany: Record Company temporary;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CompanySelector: Page "Company Selector";
        CompanyJsonToken: JsonToken;
        PropertyJsonToken: JsonToken;
    begin
        AcquireTokenAndStoreInIsolatedStorage(BusinessUnit);
        foreach CompanyJsonToken in HttpGet(CompaniesEndpointForBusinessUnit(BusinessUnit)) do begin
            CompanyJsonToken.AsObject().Get('id', PropertyJsonToken);
            TempCompany.Id := PropertyJsonToken.AsValue().AsText();
            CompanyJsonToken.AsObject().Get('name', PropertyJsonToken);
            TempCompany.Name := CopyStr(PropertyJsonToken.AsValue().AsText(), 1, MaxStrLen(TempCompany.Name));
            CompanyJsonToken.AsObject().Get('displayName', PropertyJsonToken);
            TempCompany."Display Name" := CopyStr(PropertyJsonToken.AsValue().AsText(), 1, MaxStrLen(TempCompany."Display Name"));
            TempCompany.Insert();
        end;
        CompanySelector.SetCompanies(TempCompany);
        CompanySelector.LookupMode(true);
        Commit();
        if CompanySelector.RunModal() <> Action::LookupOK then
            Error(NeedSelectCompanyErr);
        CompanySelector.GetSelectedCompany(TempCompany);
        if TempCompany.Count() > 1 then
            Error(SelectOnlyOneCompanyErr);
        TempCompany.FindFirst();
        BusinessUnit."External Company Id" := TempCompany.Id;
        BusinessUnit."External Company Name" := TempCompany.Name;
        SetBusinessUnitAPIBaseUrl(BusinessUnit);
        if not VerifySubsidiaryConsent() then
            Error(BusinessUnitConsentErr, BusinessUnit.Code);
        FeatureTelemetry.LogUptake('0000KOL', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
        Session.LogMessage('0000KTR', 'Configured new external BC company:' + UserSecurityId() + ', ' + BusinessUnit.Code, Verbosity::Normal, DataClassification::EndUserPseudonymousIdentifiers, TelemetryScope::All, '', '');
    end;

    local procedure SetBusinessUnitAPIBaseUrl(var BusinessUnit: Record "Business Unit")
    begin
        BusinessUnitAPIBaseUrl := CompaniesEndpointForBusinessUnit(BusinessUnit) + '(' + GuidToText(BusinessUnit."External Company Id") + ')';
    end;

    internal procedure GetAADTenantIdFromBCUrl(Url: Text): Text
    var
        Matches: Record Matches;
        Regex: Codeunit Regex;
    begin
        Regex.Match(Url, '[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}', 0, Matches);
        if Matches.FindFirst() then
            exit(Matches.ReadValue());
    end;

    internal procedure ValidateBCUrl(Url: Text): Boolean
    var
        UnexpectedDomain: Boolean;
    begin
        if not Url.StartsWith('https://') then
            exit(false);
        if GetAADTenantIdFromBCUrl(Url) = '' then
            exit(false);

        if IsPPE() then
            UnexpectedDomain := StrPos(LowerCase(Url), 'businesscentral.dynamics-tie.com') = 0
        else
            UnexpectedDomain := StrPos(LowerCase(Url), 'businesscentral.dynamics.com') = 0;

        if not UnexpectedDomain then
            exit(true);
        exit(Confirm(UrlNotBCMsg, false));
    end;

    local procedure APIV2RootEndpointForBusinessUnit(BusinessUnit: Record "Business Unit"): Text
    begin
        exit(BusinessUnit."BC API URL" + ApiVersionTok);
    end;

    local procedure CompaniesEndpointForBusinessUnit(BusinessUnit: Record "Business Unit"): Text
    begin
        exit(APIV2RootEndpointForBusinessUnit(BusinessUnit) + CompaniesEndpointSegmentTok);
    end;

    local procedure TestEndpointForBusinessUnit(BusinessUnit: Record "Business Unit"): Text
    begin
        exit(CompaniesEndpointForBusinessUnit(BusinessUnit) + '?$top=0');
    end;

    local procedure GuidToText(Guid: Guid): Text
    begin
        exit(LowerCase(Guid).Replace('{', '').Replace('}', ''));
    end;

    local procedure IsolatedStorageKey(AADTenantID: Text): Text
    begin
        exit('fc-' + AADTenantID);
    end;

    local procedure SetAADTenantId(NewAADTenantId: Guid)
    begin
        CurrentAADTenantId := GuidToText(NewAADTenantId);
    end;

    [NonDebuggable()]
    local procedure GetToken(AuthorityURL: Text): Text
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        EnvironmentInformation: Codeunit "Environment Information";
        OAuth2: Codeunit OAuth2;
        Scopes: List of [Text];
        ClientId, ClientSecret, Certificate, CertificateName, FinancialsScope, RedirectURL : Text;
        AccessToken, IdToken, AuthError : Text;
        IsEnvPPE: Boolean;
    begin
        IsEnvPPE := IsPPE();
        Session.LogMessage('0000KTS', RefreshingTokenMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoyTok);
        if not EnvironmentInformation.IsSaaS() then begin
            Session.LogMessage('0000KOB', GetTokenCalledFromOnPremMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoyTok);
            exit(AccessToken);
        end;
        if not AzureKeyVault.GetAzureKeyVaultSecret(ClientIdAKVKeyTok, ClientId) then begin
            Session.LogMessage('0000KOE', AKVSecretNotFoundMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoyTok);
            exit(AccessToken);
        end;
        FinancialsScope := FinancialsScopeTok;
        RedirectURL := RedirectURLTok;
        if IsEnvPPE then begin
            FinancialsScope := PPEFinancialsScopeTok;
            RedirectURL := PPERedirectUrlTok;
            if not AzureKeyVault.GetAzureKeyVaultSecret(ClientSecretAKVKeyTok, ClientSecret) then begin
                Session.LogMessage('0000KOI', AKVSecretNotFoundMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoyTok);
                exit(AccessToken);
            end
        end else begin
            if not AzureKeyVault.GetAzureKeyVaultSecret(ClientCertificateAKVKeyTok, CertificateName) then begin
                Session.LogMessage('0000KOC', AKVSecretNotFoundMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoyTok);
                exit(AccessToken);
            end;
            if not AzureKeyVault.GetAzureKeyVaultCertificate(CertificateName, Certificate) then begin
                Session.LogMessage('0000KOD', AKVSecretNotFoundMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoyTok);
                exit(AccessToken);
            end;
        end;
        Scopes.Add(FinancialsScope);
        if IsEnvPPE then begin
            if OAuth2.AcquireAuthorizationCodeTokenFromCache(ClientId, ClientSecret, RedirectURL, AuthorityURL, Scopes, AccessToken) then
                if AccessToken <> '' then
                    exit(AccessToken);
            if OAuth2.AcquireTokensByAuthorizationCode(ClientId, ClientSecret, AuthorityURL, RedirectURL, Scopes, Enum::"Prompt Interaction"::"Admin Consent", AccessToken, IdToken, AuthError) then
                exit(AccessToken);
        end else begin
            if OAuth2.AcquireAuthorizationCodeTokenFromCacheWithCertificate(ClientId, Certificate, RedirectURL, AuthorityURL, Scopes, AccessToken) then
                if AccessToken <> '' then
                    exit(AccessToken);
            if OAuth2.AcquireTokensByAuthorizationCodeWithCertificate(ClientId, Certificate, AuthorityURL, RedirectUrl, Scopes, Enum::"Prompt Interaction"::"Select Account", AccessToken, IdToken, AuthError) then
                exit(AccessToken);
        end;
    end;

    [NonDebuggable()]
    local procedure HttpGetTextWithTokenInIsolatedStorage(Uri: Text; var StatusCode: Integer; var StatusReasonPhrase: Text): Text
    var
        StorageKey, Token : Text;
    begin
        StorageKey := IsolatedStorageKey(CurrentAADTenantId);
        if IsolatedStorage.Contains(StorageKey, DataScope::Company) then
            IsolatedStorage.Get(StorageKey, DataScope::Company, Token);
        exit(HttpGetText(Uri, Token, StatusCode, StatusReasonPhrase));
    end;

    [NonDebuggable()]
    local procedure HttpGetText(Uri: Text; Token: Text; var StatusCode: Integer; var StatusReasonPhrase: Text): Text
    var
        HttpRequestMessage: HttpRequestMessage;
        HttpHeaders: HttpHeaders;
        HttpResponseMessage: HttpResponseMessage;
        HttpClient: HttpClient;
        Response: Text;
    begin
        HttpRequestMessage.Method('GET');
        HttpRequestMessage.SetRequestUri(Uri);
        HttpHeaders := HttpClient.DefaultRequestHeaders();
        HttpHeaders.Add('Accept', 'application/json');
        HttpHeaders.Add('Authorization', 'Bearer ' + Token);
        HttpClient.Send(HttpRequestMessage, HttpResponseMessage);
        StatusCode := HttpResponseMessage.HttpStatusCode();
        StatusReasonPhrase := HttpResponseMessage.ReasonPhrase();
        HttpResponseMessage.Content().ReadAs(Response);
        exit(Response);
    end;

    local procedure HttpGetTextWithStatusHandling(Uri: Text): Text
    var
        StatusReasonPhrase, Response : Text;
        StatusCode, Attempt : Integer;
    begin
        while Attempt <= ConsolidationSetup.MaxAttempts429 do begin
            Response := HttpGetTextWithTokenInIsolatedStorage(Uri, StatusCode, StatusReasonPhrase);
            case StatusCode of
                200:
                    exit(Response);
                429:
                    System.Sleep(ConsolidationSetup.WaitMsRetries);
                else
                    Error(APIStatusCodeErr, StatusCode, StatusReasonPhrase);
            end;
            Attempt += 1;
        end;
        Error(APITooManyRequestsErr);
    end;

    internal procedure ImportConsolidationForBusinessUnit(var ConsolidationProcess: Record "Consolidation Process"; var BusinessUnit: Record "Business Unit" temporary)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        SelectedDimension: Record "Selected Dimension";
        GLSetupJsonObject: JsonObject;
        ValidateNoPostingsAtClosingDates: Boolean;
        AdditionalReportingCurrencyCode: Code[10];
        CurrencyCode: Code[10];
    begin
        GeneralLedgerSetup.Get();
        ConsolidationSetup.GetOrCreateWithDefaults();
        Clear(Consolidate);
        if BusinessUnit."Default Data Import Method" <> BusinessUnit."Default Data Import Method"::API then
            Error(BusinessUnitNotConfiguredForAPIErr, BusinessUnit.Code);
        if (BusinessUnit."BC API URL" = '') or IsNullGuid(BusinessUnit."External Company Id") then
            Error(BusinessUnitNotConfiguredForAPIErr, BusinessUnit.Code);

        SetAADTenantId(BusinessUnit."AAD Tenant ID");
        SetBusinessUnitAPIBaseUrl(BusinessUnit);

        if GeneralLedgerSetup."Journal Templ. Name Mandatory" then
            GenJournalBatch.Get(ConsolidationProcess."Journal Template Name", ConsolidationProcess."Journal Batch Name");

        Consolidate.SetDocNo(ConsolidationProcess."Document No.");
        if GeneralLedgerSetup."Journal Templ. Name Mandatory" then
            Consolidate.SetGenJnlBatch(GenJournalBatch);

        SelectedDimension.SetRange("User ID", UserId());
        SelectedDimension.SetRange("Object Type", 3);
        SelectedDimension.SetRange("Object ID", REPORT::"Import Consolidation from DB");
        Consolidate.SetSelectedDim(SelectedDimension);

        ValidateNoPostingsAtClosingDates := ConsolidationProcess."Starting Date" = NormalDate(ConsolidationProcess."Starting Date");
        if not VerifySubsidiaryConsent(GLSetupJsonObject) then
            Error(BusinessUnitConsentErr, BusinessUnit.Code);
        GetAndSetPostingGLAccounts(ValidateNoPostingsAtClosingDates, ConsolidationProcess."Starting Date", ConsolidationProcess."Ending Date");
        GetAndSetGLEntriesForGLAccountsToConsolidate(ConsolidationProcess."Starting Date", ConsolidationProcess."Ending Date", ConsolidationProcess."Dimensions to Transfer");
        if (BusinessUnit."Currency Code" <> '') and (BusinessUnit."Currency Exchange Rate Table" = BusinessUnit."Currency Exchange Rate Table"::"Business Unit") then
            CurrencyCode := GetAndSetCurrencyExchangeRates(GLSetupJsonObject, ConsolidationProcess."Parent Currency Code", BusinessUnit."Currency Code", ConsolidationProcess."Ending Date", BusinessUnit."Currency Exchange Rate Table", AdditionalReportingCurrencyCode);

        Consolidate.SetGlobals('', '', CopyStr(BusinessUnit."External Company Name", 1, 30), CurrencyCode, AdditionalReportingCurrencyCode, ConsolidationProcess."Parent Currency Code", 0, ConsolidationProcess."Starting Date", ConsolidationProcess."Ending Date");
        Consolidate.UpdateGLEntryDimSetID();
        Consolidate.Run(BusinessUnit);
    end;

    local procedure VerifySubsidiaryConsent(): Boolean
    var
        GLSetupJsonObject: JsonObject;
    begin
        exit(VerifySubsidiaryConsent(GLSetupJsonObject));
    end;

    local procedure VerifySubsidiaryConsent(var GLSetupJsonObject: JsonObject): Boolean
    var
        JsonToken: JsonToken;
    begin
        GLSetupJsonObject := GetGLSetup();
        GLSetupJsonObject.Get('allowQueryFromConsolidation', JsonToken);
        exit(JsonToken.AsValue().AsBoolean());
    end;

    local procedure FormatDateForAPICall(Date: Date): Text
    begin
        exit(Format(Date, 10, '<Year4>-<Month,2>-<Day,2>'));
    end;

    local procedure GetAndSetCurrencyExchangeRates(var GLSetupJsonObject: JsonObject; ParentCurrencyCode: Code[10]; BusinessUnitCurrencyCode: Code[10]; EndingDate: Date; CurrencyExchangeRateTable: Option; var AdditionalReportingCurrencyCode: Code[10]): Code[10]
    var
        BusinessUnit: Record "Business Unit";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        JsonToken: JsonToken;
        PropertyJsonToken: JsonToken;
        CurrencyFilter: Text;
        CurrencyCode: Code[10];
        LocalCurrencyCode: Code[10];
    begin
        GLSetupJsonObject.Get('additionalReportingCurrency', JsonToken);
        AdditionalReportingCurrencyCode := CopyStr(JsonToken.AsValue().AsCode(), 1, MaxStrLen(AdditionalReportingCurrencyCode));
        GLSetupJsonObject.Get('localCurrencyCode', JsonToken);
        LocalCurrencyCode := CopyStr(JsonToken.AsValue().AsCode(), 1, MaxStrLen(LocalCurrencyCode));

        if (ParentCurrencyCode = '') and (AdditionalReportingCurrencyCode = '') then
            exit('');

        if LocalCurrencyCode <> '' then
            CurrencyCode := LocalCurrencyCode
        else
            CurrencyCode := BusinessUnitCurrencyCode;

        if ParentCurrencyCode <> '' then
            CurrencyFilter += StrSubstNo(CurrencyCodeFilterTok, ParentCurrencyCode);
        if AdditionalReportingCurrencyCode <> '' then begin
            if CurrencyFilter <> '' then
                CurrencyFilter += ' or ';
            CurrencyFilter += StrSubstNo(CurrencyCodeFilterTok, AdditionalReportingCurrencyCode);
        end;

        if CurrencyExchangeRateTable = BusinessUnit."Currency Exchange Rate Table"::Local then
            exit(CurrencyCode);

        foreach JsonToken in GetCurrencyExchangeRates(CurrencyFilter, EndingDate) do begin
            JsonToken.AsObject().Get('currencyCode', PropertyJsonToken);
            CurrencyExchangeRate."Currency Code" := CopyStr(PropertyJsonToken.AsValue().AsCode(), 1, MaxStrLen(CurrencyExchangeRate."Currency Code"));
            JsonToken.AsObject().Get('startingDate', PropertyJsonToken);
            CurrencyExchangeRate."Starting Date" := PropertyJsonToken.AsValue().AsDate();
            JsonToken.AsObject().Get('relationalCurrencyCode', PropertyJsonToken);
            CurrencyExchangeRate."Relational Currency Code" := CopyStr(PropertyJsonToken.AsValue().AsCode(), 1, MaxStrLen(CurrencyExchangeRate."Relational Currency Code"));
            JsonToken.AsObject().Get('exchangeRateAmount', PropertyJsonToken);
            CurrencyExchangeRate."Exchange Rate Amount" := PropertyJsonToken.AsValue().AsDecimal();
            JsonToken.AsObject().Get('relationalExchangeRateAmount', PropertyJsonToken);
            CurrencyExchangeRate."Relational Exch. Rate Amount" := PropertyJsonToken.AsValue().AsDecimal();
            Consolidate.InsertExchRate(CurrencyExchangeRate);
        end;
        exit(CurrencyCode);
    end;

    local procedure GetAndSetGLEntriesForGLAccountsToConsolidate(StartingDate: Date; EndingDate: Date; DimensionsToTransfer: Text)
    var
        TempGLAccount: Record "G/L Account" temporary;
        AccountNoFilter: Text;
        DateFilter: Text;
        BatchCount: Integer;
        GLAccountBatchLimit: Integer;
        First: Boolean;
    begin
        // GLEntries are obtained from the GL Accounts of interest. Each request to GLEntries filters by a maximum of GLAccountBatchLimit GL Accounts
        GLAccountBatchLimit := 60;

        DateFilter := StrSubstNo(PostingDateFilterTok, FormatDateForAPICall(StartingDate), FormatDateForAPICall(EndingDate));
        Consolidate.GetGLAccounts(TempGLAccount);
        First := true;
        if not TempGLAccount.FindSet() then
            exit;
        repeat
            if First then
                First := false
            else
                AccountNoFilter += ' or ';
            AccountNoFilter += GLAccountToFilter(TempGLAccount);
            BatchCount += 1;
            if BatchCount >= GLAccountBatchLimit then begin
                GetAndSetGLEntries(AccountNoFilter, DateFilter, DimensionsToTransfer);
                AccountNoFilter := '';
                First := true;
                BatchCount := 0;
            end;
        until TempGLAccount.Next() = 0;
        if BatchCount > 0 then
            GetAndSetGLEntries(AccountNoFilter, DateFilter, DimensionsToTransfer);
    end;

    local procedure GetAndSetGLEntries(AccountNoFilter: Text; DateFilter: Text; DimensionsToTransfer: Text)
    var
        TempDimensionInOtherCompany: Record Dimension temporary;
        GLEntry: Record "G/L Entry";
        TempDimensionBuffer: Record "Dimension Buffer" temporary;
        DimCodeInOtherCompany, DimConsolidationCode : Code[20];
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        PropertyJsonToken: JsonToken;
        DimJsonToken: JsonToken;
        DimPropertyJsonToken: JsonToken;
        GLEntryNo: Integer;
    begin
        JsonArray := GetGLEntries(DateFilter, AccountNoFilter);

        if JsonArray.Count() = 0 then
            exit;

        if DimensionsToTransfer <> '' then
            GetDimensionsFromOtherCompanyMatchingSelected(DimensionsToTransfer, TempDimensionInOtherCompany);

        foreach JsonToken in JsonArray do begin
            JsonToken.AsObject().Get('entryNumber', PropertyJsonToken);
            GLEntry."Entry No." := PropertyJsonToken.AsValue().AsInteger();
            JsonToken.AsObject().Get('accountNumber', PropertyJsonToken);
            GLEntry."G/L Account No." := CopyStr(PropertyJsonToken.AsValue().AsCode(), 1, MaxStrLen(GLEntry."G/L Account No."));
            JsonToken.AsObject().Get('postingDate', PropertyJsonToken);
            GLEntry."Posting Date" := PropertyJsonToken.AsValue().AsDate();
            JsonToken.AsObject().Get('debitAmount', PropertyJsonToken);
            GLEntry."Debit Amount" := PropertyJsonToken.AsValue().AsDecimal();
            JsonToken.AsObject().Get('creditAmount', PropertyJsonToken);
            GLEntry."Credit Amount" := PropertyJsonToken.AsValue().AsDecimal();
            JsonToken.AsObject().Get('additionalCurrencyDebitAmount', PropertyJsonToken);
            GLEntry."Add.-Currency Debit Amount" := PropertyJsonToken.AsValue().AsDecimal();
            JsonToken.AsObject().Get('additionalCurrencyCreditAmount', PropertyJsonToken);
            GLEntry."Add.-Currency Credit Amount" := PropertyJsonToken.AsValue().AsDecimal();
            GLEntryNo := Consolidate.InsertGLEntry(GLEntry);
            JsonToken.AsObject().Get('dimensionSetLines', PropertyJsonToken);
            TempDimensionBuffer."Table ID" := Database::"G/L Entry";
            TempDimensionBuffer."Entry No." := GLEntryNo;
            foreach DimJsonToken in PropertyJsonToken.AsArray() do begin
                DimJsonToken.AsObject().Get('code', DimPropertyJsonToken);
                DimCodeInOtherCompany := CopyStr(DimPropertyJsonToken.AsValue().AsCode(), 1, MaxStrLen(TempDimensionBuffer."Dimension Code"));
                DimJsonToken.AsObject().Get('consolidationCode', DimPropertyJsonToken);
                DimConsolidationCode := CopyStr(DimPropertyJsonToken.AsValue().AsCode(), 1, MaxStrLen(DimConsolidationCode));
                if DimConsolidationCode <> '' then
                    TempDimensionBuffer."Dimension Code" := DimConsolidationCode
                else
                    TempDimensionBuffer."Dimension Code" := DimCodeInOtherCompany;
                DimJsonToken.AsObject().Get('valueCode', DimPropertyJsonToken);
                TempDimensionBuffer."Dimension Value Code" := CopyStr(DimPropertyJsonToken.AsValue().AsCode(), 1, MaxStrLen(TempDimensionBuffer."Dimension Value Code"));
                DimJsonToken.AsObject().Get('valueConsolidationCode', DimPropertyJsonToken);
                DimConsolidationCode := CopyStr(DimPropertyJsonToken.AsValue().AsCode(), 1, MaxStrLen(DimConsolidationCode));
                if DimConsolidationCode <> '' then
                    TempDimensionBuffer."Dimension Value Code" := DimConsolidationCode;
                if TempDimensionInOtherCompany.Get(DimCodeInOtherCompany) then
                    Consolidate.InsertEntryDim(TempDimensionBuffer, GLEntryNo)
            end;
        end;
    end;

    local procedure GetDimensionsFromOtherCompanyMatchingSelected(DimensionsToTransfer: Text; var DimensionInOtherCompany: Record Dimension temporary)
    var
        DimensionFilter: Text;
    begin
        DimensionFilter := GetDimensionsRequestFilter(DimensionsToTransfer, DimensionCodeFilterTok);
        GetDimensionsFromOtherCompany(DimensionFilter, DimensionInOtherCompany);
        DimensionFilter := GetDimensionsRequestFilter(DimensionsToTransfer, DimensionConsolidationCodeFilterTok);
        GetDimensionsFromOtherCompany(DimensionFilter, DimensionInOtherCompany);
        // https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/webservices/odata-known-limitations#filters
    end;

    local procedure GetDimensionsRequestFilter(DimensionsToTransfer: Text; FieldFilter: Text): Text
    var
        DimensionCodeInConsolidationCompany, DimensionFilter : Text;
        First: Boolean;
    begin
        First := true;
        foreach DimensionCodeInConsolidationCompany in DimensionsToTransfer.Split(';') do begin
            if not First then
                DimensionFilter += ' or '
            else
                First := false;
            DimensionFilter += StrSubstNo(FieldFilter, DimensionCodeInConsolidationCompany);
        end;
        exit(DimensionFilter);
    end;

    local procedure GetDimensionsFromOtherCompany(Filter: Text; var DimensionInOtherCompany: Record Dimension temporary)
    var
        JsonToken: JsonToken;
        PropertyJsonToken: JsonToken;
    begin
        foreach JsonToken in GetDimensions(Filter) do begin
            JsonToken.AsObject().Get('code', PropertyJsonToken);
            DimensionInOtherCompany.Code := CopyStr(PropertyJsonToken.AsValue().AsCode(), 1, MaxStrLen(DimensionInOtherCompany.Code));
            DimensionInOtherCompany.Insert();
        end;
    end;

    local procedure GLAccountToFilter(TempGLAccount: Record "G/L Account" temporary): Text
    begin
        exit(GLAccountToFilter(TempGLAccount."No."));
    end;

    local procedure GLAccountToFilter(GLAccountNo: Code[20]): Text
    begin
        exit(StrSubstNo(GLAccountFilterTok, GLAccountNo));
    end;

    local procedure GetAndSetPostingGLAccounts(ValidateNoPostingsAtClosingDates: Boolean; StartingDate: Date; EndingDate: Date)
    var
        GLAccount: Record "G/L Account";
        TempAccountingPeriod: Record "Accounting Period" temporary;
        TypeHelper: Codeunit "Type Helper";
        JsonToken: JsonToken;
        PropertyJsonToken: JsonToken;
    begin
        if ValidateNoPostingsAtClosingDates then
            foreach JsonToken in GetAccountingPeriods(StartingDate, EndingDate) do begin
                JsonToken.AsObject().Get('startingDate', PropertyJsonToken);
                TempAccountingPeriod."Starting Date" := PropertyJsonToken.AsValue().AsDate();
                TempAccountingPeriod.Insert();
            end;

        foreach JsonToken in GetPostingGLAccounts() do begin
            JsonToken.AsObject().Get('number', PropertyJsonToken);
            GLAccount."No." := CopyStr(PropertyJsonToken.AsValue().AsCode(), 1, MaxStrLen(GLAccount."No."));
            if ValidateNoPostingsAtClosingDates then
                CheckNoPostingsAtClosingDates(GLAccount."No.", TempAccountingPeriod);
            JsonToken.AsObject().Get('consolidationTranslationMethod', PropertyJsonToken);
            GLAccount."Consol. Translation Method" := TypeHelper.GetOptionNoFromTableField(PropertyJsonToken.AsValue().AsText(), Database::"G/L Account", GLAccount.FieldNo("Consol. Translation Method"));
            JsonToken.AsObject().Get('consolidationDebitAccount', PropertyJsonToken);
            GLAccount."Consol. Debit Acc." := CopyStr(PropertyJsonToken.AsValue().AsCode(), 1, MaxStrLen(GLAccount."Consol. Debit Acc."));
            JsonToken.AsObject().Get('consolidationCreditAccount', PropertyJsonToken);
            GLAccount."Consol. Credit Acc." := CopyStr(PropertyJsonToken.AsValue().AsCode(), 1, MaxStrLen(GLAccount."Consol. Credit Acc."));
            Consolidate.InsertGLAccount(GLAccount);
        end;
    end;

    local procedure CheckNoPostingsAtClosingDates(GLAccountNo: Code[20]; var TempAccountingPeriod: Record "Accounting Period" temporary)
    var
        ClosingDate: Date;
        EntriesAtClosingDates: Integer;
    begin
        if not TempAccountingPeriod.FindSet() then
            exit;
        repeat
            ClosingDate := TempAccountingPeriod."Starting Date" - 1;
            EntriesAtClosingDates := GetGLEntriesCountAtDate(GLAccountNo, ClosingDate);
            if EntriesAtClosingDates <> 0 then
                Error(EntriesAtClosingDateErr, ClosingDate, GLAccountNo);
        until TempAccountingPeriod.Next() = 0;
    end;

    local procedure GetGLSetup(): JsonObject
    var
        Response: Text;
        IsHandled: Boolean;
    begin
        OnBeforeGetGLSetup(IsHandled, Response);
        if IsHandled then
            exit(ParseDataSingle(Response));
        exit(HttpGetSingle(BusinessUnitAPIBaseUrl + '/generalLedgerSetup'));
    end;

    local procedure GetCurrencyExchangeRates(CurrencyFilter: Text; EndingDate: Date): JsonArray
    var
        Response: Text;
        IsHandled: Boolean;
    begin
        OnBeforeGetCurrencyExchangeRates(CurrencyFilter, EndingDate, IsHandled, Response);
        if IsHandled then
            exit(ParseData(Response));
        exit(HttpGet(BusinessUnitAPIBaseUrl + CurrencyExchangeRatesSegmentTok + '?$filter=(' + CurrencyFilter + ') and startingDate le ' + FormatDateForAPICall(EndingDate)));
    end;

    local procedure GetGLEntries(DateFilter: Text; AccountNoFilter: Text): JsonArray
    var
        Response: Text;
        IsHandled: Boolean;
    begin
        OnBeforeGetGLEntries(DateFilter, AccountNoFilter, IsHandled, Response);
        if IsHandled then
            exit(ParseData(Response));
        exit(HttpGet(BusinessUnitAPIBaseUrl + '/generalLedgerEntries?$filter=' + DateFilter + ' and (' + AccountNoFilter + ')&$expand=dimensionSetLines', true));
    end;

    local procedure GetDimensions(DimensionFilter: Text): JsonArray
    var
        Response: Text;
        IsHandled: Boolean;
    begin
        OnBeforeGetDimensions(DimensionFilter, IsHandled, Response);
        if IsHandled then
            exit(ParseData(Response));
        exit(HttpGet(BusinessUnitAPIBaseUrl + '/dimensions?$filter=' + DimensionFilter));
    end;

    local procedure GetGLEntriesCountAtDate(GLAccountNo: Code[20]; ClosingDate: Date): Integer
    var
        Response: Text;
        IsHandled: Boolean;
    begin
        OnBeforeGetGLEntriesCountAtDate(GLAccountNo, ClosingDate, IsHandled, Response);
        if IsHandled then
            exit(ParseCount(Response));
        exit(HttpGetCount(BusinessUnitAPIBaseUrl + '/generalLedgerEntries?$filter=' + GLAccountToFilter(GLAccountNo) + ' and postingDate eq ' + FormatDateForAPICall(ClosingDate)));
    end;

    local procedure GetPostingGLAccounts(): JsonArray
    var
        Response: Text;
        IsHandled: Boolean;
    begin
        OnBeforeGetPostingGLAccounts(IsHandled, Response);
        if IsHandled then
            exit(ParseData(Response));
        exit(HttpGet(BusinessUnitAPIBaseUrl + '/accounts?$filter=accountType eq ''Posting'''));
    end;

    local procedure GetAccountingPeriods(StartingDate: Date; EndingDate: Date): JsonArray
    var
        Response: Text;
        IsHandled: Boolean;
    begin
        OnBeforeGetAccountingPeriods(StartingDate, EndingDate, IsHandled, Response);
        if IsHandled then
            exit(ParseData(Response));
        exit(HttpGet(BusinessUnitAPIBaseUrl + '/accountingPeriods?$filter=newFiscalYear eq true and dateLocked eq true and startingDate ge ' + FormatDateForAPICall(StartingDate + 1) + ' and startingDate le ' + FormatDateForAPICall(EndingDate)));
    end;

    local procedure ParseData(Response: Text): JsonArray
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
    begin
        JsonObject.ReadFrom(Response);
        JsonObject.Get('value', JsonToken);
        exit(JsonToken.AsArray());
    end;

    local procedure ParseDataSingle(Response: Text): JsonObject
    var
        JsonArray: JsonArray;
        JsonToken: JsonToken;
    begin
        JsonArray := ParseData(Response);
        if JsonArray.Count() <> 1 then
            Error(APIGetSingleGotOtherErr, JsonArray.Count());
        JsonArray.Get(0, JsonToken);
        exit(JsonToken.AsObject());
    end;

    local procedure ParseCount(Response: Text): Integer
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
    begin
        JsonObject.ReadFrom(Response);
        JsonObject.Get('@odata.count', JsonToken);
        exit(JsonToken.AsValue().AsInteger());
    end;

    local procedure HttpGetCount(Uri: Text): Integer
    begin
        exit(ParseCount(HttpGetTextWithStatusHandling(Uri + '&$count=true&$top=0')));
    end;

    local procedure HttpGet(Uri: Text): JsonArray
    begin
        exit(HttpGet(Uri, false));
    end;

    local procedure HttpGet(Uri: Text; Paginate: Boolean): JsonArray
    var
        TotalJsonArray: JsonArray;
        JsonToken: JsonToken;
        UriWithPagination: Text;
        RecordsRead, Count : Integer;
    begin
        if Paginate then begin
            Count := HttpGetCount(Uri);
            RecordsRead := 0;
            while RecordsRead < Count do begin
                UriWithPagination := Uri + '&$skip=' + Format(RecordsRead) + '&$top=' + Format(ConsolidationSetup.PageSize);
                foreach JsonToken in ParseData(HttpGetTextWithStatusHandling(UriWithPagination)) do
                    TotalJsonArray.Add(JsonToken);
                RecordsRead += ConsolidationSetup.PageSize;
            end;
            exit(TotalJsonArray);
        end
        else
            exit(ParseData(HttpGetTextWithStatusHandling(Uri)));
    end;

    local procedure HttpGetSingle(Uri: Text): JsonObject
    begin
        exit(ParseDataSingle(HttpGetTextWithStatusHandling(Uri)));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetGLSetup(var IsHandled: Boolean; var Response: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCurrencyExchangeRates(CurrencyFilter: Text; EndingDate: Date; var IsHandled: Boolean; var Response: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetGLEntries(DateFilter: Text; AccountNoFilter: Text; var IsHandled: Boolean; var Response: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDimensions(DimensionFilter: Text; var IsHandled: Boolean; var Response: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetGLEntriesCountAtDate(GLAccountNo: Code[20]; ClosingDate: Date; var IsHandled: Boolean; var Response: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAccountingPeriods(StartingDate: Date; EndingDate: Date; var IsHandled: Boolean; var Response: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPostingGLAccounts(var IsHandled: Boolean; var Response: Text)
    begin
    end;
}