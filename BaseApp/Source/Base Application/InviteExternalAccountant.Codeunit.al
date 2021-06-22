codeunit 9033 "Invite External Accountant"
{

    trigger OnRun()
    begin
    end;

    var
        ErrorAcquiringTokenErr: Label 'Failed to acquire an access token.  This is necessary to invite the external accountant.  Contact your administrator.', Locked = true;
        InviteReedemUrlTxt: Label 'inviteRedeemUrl', Locked = true;
        InvitedUserIdTxt: Label 'invitedUser', Locked = true;
        IdTxt: Label 'id', Locked = true;
        ConsumedUnitsTxt: Label 'consumedUnits', Locked = true;
        ErrorTxt: Label 'error', Locked = true;
        MessageTxt: Label 'message', Locked = true;
        ValueTxt: Label 'value', Locked = true;
        SkuIdTxt: Label 'skuId', Locked = true;
        PrepaidUnitsTxt: Label 'prepaidUnits', Locked = true;
        EnabledUnitsTxt: Label 'enabled', Locked = true;
        GlobalAdministratorRoleTemplateIdTxt: Label '62e90394-69f5-4237-9190-012177145e10', Locked = true;
        UserAdministratorRoleTemplateIdTxt: Label 'fe930be7-5e62-47db-91af-98c3a49a38b1', Locked = true;
        ExternalAccountantLicenseSkuIdTxt: Label '9a1e33ed-9697-43f3-b84c-1b0959dbb1d4', Locked = true;
        TrialViralLicenseSkuIdTxt: Label '6a4a1628-9b9a-424d-bed5-4118f0ede3fd', Locked = true;
        InviteExternalAccountantTelemetryCategoryTxt: Label 'AL Dynamics 365 Invite External Accountant', Locked = true;
        InviteExternalAccountantTelemetryStartTxt: Label 'Invite External Accountant process started.', Locked = true;
        InviteExternalAccountantTelemetryEndTxt: Label 'Invite External Accountant process ended with the following result:  %1:  License is %2.', Locked = true;
        InviteExternalAccountantTelemetryLicenseFailTxt: Label 'Invite External Accountant wizard failed to start due to there being no external accountant license available.', Locked = true;
        InviteExternalAccountantTelemetryAADPermissionFailTxt: Label 'Invite External Accountant wizard failed to start due to the user not having the necessary AAD permissions.', Locked = true;
        InviteExternalAccountantTelemetryUserTablePermissionFailTxt: Label 'Invite External Accountant wizard failed to start due to the session not being admin or the user being Super in all companies.', Locked = true;
        InviteExternalAccountantTelemetryCreateNewUserSuccessTxt: Label 'Invite External Accountant wizard successfully created a new user.', Locked = true;
        InviteExternalAccountantTelemetryCreateNewUserFailedTxt: Label 'Invite External Accountant wizard was unable to create a new user.', Locked = true;
        ResponseCodeTxt: Label 'responseCode', Locked = true;
        EmailAddressIsConsumerAccountTxt: Label 'The email address looks like a personal email address.  Enter your accountant''s work email address to continue.';
        EmailAddressIsInvalidTxt: Label 'The email address is invalid.  Enter your accountant''s work email address to continue.';
        InsufficientDataReturnedFromInvitationsApiTxt: Label 'Insufficient information was returned when inviting the user. Please contact your administrator.';
        WidsClaimNameTok: Label 'WIDS', Locked = true;
        ExternalAccountantLicenseAvailabilityErr: Label 'Failed to determine if an External Accountant license is available. Please try again later.';
        UrlHelper: Codeunit "Url Helper";

    [Scope('OnPrem')]
    procedure InvokeInvitationsRequest(DisplayName: Text; EmailAddress: Text; WebClientUrl: Text; var InvitedUserId: Guid; var InviteReedemUrl: Text; var ErrorMessage: Text): Boolean
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        InviteUserIdJsonObject: DotNet JObject;
        InviteUserIdObjectValue: Text;
        ResponseContent: Text;
        Body: Text;
        FoundInviteRedeemUrlValue: Boolean;
        FoundInvitedUserObjectValue: Boolean;
        FoundInviteUserIdValue: Boolean;
    begin
        Body := '{';
        Body := Body + '"invitedUserDisplayName" : "' + DisplayName + '",';
        Body := Body + '"invitedUserEmailAddress" : "' + EmailAddress + '",';
        Body := Body + '"inviteRedirectUrl" : "' + WebClientUrl + '",';
        Body := Body + '"sendInvitationMessage" : "false"';
        Body := Body + '}';

        if InvokeRequestWithGraphAccessToken(GetGraphInvitationsUrl, 'POST', Body, ResponseContent) then begin
            JSONManagement.InitializeObject(ResponseContent);
            JSONManagement.GetJSONObject(JsonObject);
            FoundInviteRedeemUrlValue :=
              JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, InviteReedemUrlTxt, InviteReedemUrl);
            FoundInvitedUserObjectValue :=
              JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, InvitedUserIdTxt, InviteUserIdObjectValue);
            JSONManagement.InitializeObject(InviteUserIdObjectValue);
            JSONManagement.GetJSONObject(InviteUserIdJsonObject);
            FoundInviteUserIdValue := JSONManagement.GetGuidPropertyValueFromJObjectByName(InviteUserIdJsonObject, IdTxt, InvitedUserId);

            if FoundInviteRedeemUrlValue and FoundInvitedUserObjectValue and FoundInviteUserIdValue then
                exit(true);

            ErrorMessage := InsufficientDataReturnedFromInvitationsApiTxt;
            exit(false);
        end;

        ErrorMessage := GetMessageFromErrorJSON(ResponseContent);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure InvokeUserProfileUpdateRequest(var GuestGraphUser: DotNet UserInfo; CountryLetterCode: Text; var ErrorMessage: Text): Boolean
    var
        Body: Text;
        ResponseContent: Text;
        GraphUserUrl: Text;
    begin
        GraphUserUrl := GetGraphUserUrl + '/' + GuestGraphUser.ObjectId;
        Body := '{"usageLocation" : "' + CountryLetterCode + '"}';

        // Set usage location on guest user to current tenant's country letter code.
        if InvokeRequestWithGraphAccessToken(GraphUserUrl, 'PATCH', Body, ResponseContent) then
            exit(true);

        ErrorMessage := GetMessageFromErrorJSON(ResponseContent);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure InvokeUserAssignLicenseRequest(var GraphUser: DotNet UserInfo; TargetLicense: Text; var ErrorMessage: Text): Boolean
    var
        Body: Text;
        ResponseContent: Text;
        Url: Text;
    begin
        Url := GetGraphUserUrl + '/' + GraphUser.ObjectId + '/assignLicense';

        Body := '{';
        Body := Body + '"addLicenses": [';
        Body := Body + '{';
        Body := Body + '"disabledPlans": [],';
        Body := Body + '"skuId": "' + TargetLicense + '"';
        Body := Body + '}],';
        Body := Body + '"removeLicenses": []';
        Body := Body + '}';

        if InvokeRequestWithGraphAccessToken(Url, 'POST', Body, ResponseContent) then
            exit(true);

        ErrorMessage := GetMessageFromErrorJSON(ResponseContent);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure InvokeIsExternalAccountantLicenseAvailable(var ErrorMessage: Text; var TargetLicense: Text): Boolean
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        JsonArray: DotNet JArray;
        PrepaidUnitsJsonObject: DotNet JObject;
        NumberSkus: Integer;
        ResponseContent: Text;
        SkuIdValue: Text;
        ConsumedUnitsValue: Decimal;
        PrepaidUnitsValue: Text;
        EnabledUnitsValue: Decimal;
    begin
        if InvokeRequestWithGraphAccessToken(GetGraphSubscribedSkusUrl, 'GET', '', ResponseContent) then begin
            if not JSONManagement.TryParseJObjectFromString(JsonObject, ResponseContent) then
                Error(ExternalAccountantLicenseAvailabilityErr);

            if not JSONManagement.GetArrayPropertyValueFromJObjectByName(JsonObject, ValueTxt, JsonArray) then
                Error(ExternalAccountantLicenseAvailabilityErr);
            JSONManagement.InitializeCollectionFromJArray(JsonArray);

            NumberSkus := JSONManagement.GetCollectionCount;
            while NumberSkus > 0 do begin
                NumberSkus := NumberSkus - 1;
                if JSONManagement.GetJObjectFromCollectionByIndex(JsonObject, NumberSkus) then begin
                    if not JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, SkuIdTxt, SkuIdValue) then
                        Error(ExternalAccountantLicenseAvailabilityErr);
                    if not JSONManagement.GetDecimalPropertyValueFromJObjectByName(JsonObject, ConsumedUnitsTxt, ConsumedUnitsValue) then
                        Error(ExternalAccountantLicenseAvailabilityErr);
                    // Check to see if there is an external accountant license available.
                    if (SkuIdValue = ExternalAccountantLicenseSkuIdTxt) or (SkuIdValue = TrialViralLicenseSkuIdTxt) then begin
                        TargetLicense := SkuIdValue;
                        if not JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, PrepaidUnitsTxt, PrepaidUnitsValue) then
                            Error(ExternalAccountantLicenseAvailabilityErr);
                        if not JSONManagement.TryParseJObjectFromString(PrepaidUnitsJsonObject, PrepaidUnitsValue) then
                            Error(ExternalAccountantLicenseAvailabilityErr);
                        if not JSONManagement.GetDecimalPropertyValueFromJObjectByName(PrepaidUnitsJsonObject, EnabledUnitsTxt, EnabledUnitsValue) then
                            Error(ExternalAccountantLicenseAvailabilityErr);

                        if ConsumedUnitsValue < EnabledUnitsValue then
                            exit(true);

                        exit(false);
                    end;
                end;
            end;
        end;

        ErrorMessage := GetMessageFromErrorJSON(ResponseContent);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure VerifySMTPIsEnabledAndSetup(): Boolean
    var
        SMTPMail: Codeunit "SMTP Mail";
    begin
        if not SMTPMail.IsEnabled then
            exit(false);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure InvokeEmailAddressIsAADAccount(EmailAddress: Text; var ErrorMessage: Text): Boolean
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        ResponseContent: Text;
        Url: Text;
        Body: Text;
        ResponseCodeValue: Text;
    begin
        Url := UrlHelper.GetSignupPrefix + 'api/signupservice/usersignup?api-version=1';
        Body := '{"emailaddress": "' + EmailAddress + '","skuid": "StoreForBusinessIW","skipVerificationEmail": true}';

        InvokeRequestWithSignupAccessToken(Url, 'POST', Body, ResponseContent);
        JSONManagement.InitializeObject(ResponseContent);
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, ResponseCodeTxt, ResponseCodeValue);
        case ResponseCodeValue of
            'Success':
                exit(true);
            'UserExists':
                exit(true);
            'ConsumerDomainNotAllowed':
                ErrorMessage := EmailAddressIsConsumerAccountTxt;
            else
                ErrorMessage := EmailAddressIsInvalidTxt;
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure InvokeIsUserAdministrator(): Boolean
    var
        ClaimValue: Text;
    begin
        ClaimValue := GetCurrentUserTokenClaim(WidsClaimNameTok);
        if ClaimValue = '' then
            exit(false);

        if StrPos(UpperCase(ClaimValue), UpperCase(GlobalAdministratorRoleTemplateIdTxt)) > 0 then
            exit(true);
        if StrPos(UpperCase(ClaimValue), UpperCase(UserAdministratorRoleTemplateIdTxt)) > 0 then
            exit(true);

        exit(false);
    end;

    local procedure GetCurrentUserTokenClaim(ClaimName: Text): Text
    var
        UserAccountHelper: DotNet NavUserAccountHelper;
    begin
        exit(UserAccountHelper.GetCurrentUserTokenClaim(ClaimName));
    end;

    [Scope('OnPrem')]
    procedure CreateNewUser(InvitedUserId: Guid)
    var
        AzureADUserManagement: Codeunit "Azure AD User Management";
        AzureADGraph: codeunit "Azure AD Graph";
        UserAssignedPlans: DotNet GenericList1;
        GuestGraphUser: DotNet UserInfo;
        "Count": Integer;
    begin
        repeat
            Sleep(2000);
            Count := Count + 1;
            AzureADGraph.TryGetUserByObjectId(InvitedUserId, GuestGraphUser);
            AzureADGraph.GetUserAssignedPlans(GuestGraphUser, UserAssignedPlans);
        until (UserAssignedPlans.Count > 1) or (Count = 10);

        if UserAssignedPlans.Count > 1 then begin
            OnInvitationCreateNewUser(true);
            AzureADUserManagement.CreateNewUserFromGraphUser(GuestGraphUser);
        end else
            OnInvitationCreateNewUser(false);
    end;

    [Scope('OnPrem')]
    procedure TryGetGuestGraphUser(InvitedUserId: Guid; var GuestGraphUser: DotNet UserInfo): Boolean
    var
        AzureADGraph: codeunit "Azure AD Graph";
        FoundUser: Boolean;
        "Count": Integer;
    begin
        repeat
            Sleep(2000);
            Count := Count + 1;
            FoundUser := AzureADGraph.TryGetUserByObjectId(InvitedUserId, GuestGraphUser);
        until FoundUser or (Count = 10);

        exit(FoundUser);
    end;

    procedure UpdateAssistedSetup()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        AssistedSetup.Complete(Info.Id(), PAGE::"Invite External Accountant");
    end;

    local procedure InvokeRequestWithGraphAccessToken(Url: Text; Verb: Text; Body: Text; var ResponseContent: Text): Boolean
    begin
        exit(InvokeRequest(Url, Verb, Body, UrlHelper.GetGraphUrl, ResponseContent));
    end;

    local procedure InvokeRequestWithSignupAccessToken(Url: Text; Verb: Text; Body: Text; var ResponseContent: Text): Boolean
    begin
        exit(InvokeRequest(Url, Verb, Body, UrlHelper.GetSignupPrefix, ResponseContent));
    end;

    local procedure InvokeRequest(Url: Text; Verb: Text; Body: Text; AuthResourceUrl: Text; var ResponseContent: Text): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        AzureADMgt: Codeunit "Azure AD Mgt.";
        AzureADTenant: Codeunit "Azure AD Tenant";
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        WebRequestHelper: Codeunit "Web Request Helper";
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseHeaders: DotNet NameValueCollection;
        WebException: DotNet WebException;
        InStr: InStream;
        AccessToken: Text;
        ServiceUrl: Text;
        ChunkText: Text;
        WasSuccessful: Boolean;
    begin
        AccessToken := AzureADMgt.GetGuestAccessToken(AuthResourceUrl, AzureADTenant.GetAadTenantId);

        if AccessToken = '' then
            Error(ErrorAcquiringTokenErr);

        HttpWebRequestMgt.Initialize(Url);
        HttpWebRequestMgt.DisableUI;
        HttpWebRequestMgt.SetReturnType('application/json');
        HttpWebRequestMgt.SetContentType('application/json');
        HttpWebRequestMgt.SetMethod(Verb);
        HttpWebRequestMgt.AddHeader('Authorization', 'Bearer ' + AccessToken);
        if Verb <> 'GET' then
            HttpWebRequestMgt.AddBodyAsText(Body);

        TempBlob.CreateInStream(InStr);
        if HttpWebRequestMgt.GetResponse(InStr, HttpStatusCode, ResponseHeaders) then
            WasSuccessful := true
        else begin
            WebRequestHelper.GetWebResponseError(WebException, ServiceUrl);
            WebException.Response.GetResponseStream.CopyTo(InStr);
            WasSuccessful := false;
        end;

        while not InStr.EOS do begin
            InStr.ReadText(ChunkText);
            ResponseContent += ChunkText;
        end;

        exit(WasSuccessful);
    end;

    local procedure GetMessageFromErrorJSON(ResponseContent: Text): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        ErrorObjectValue: Text;
        MessageValue: Text;
    begin
        JSONManagement.InitializeObject(ResponseContent);
        JSONManagement.GetJSONObject(JsonObject);
        if JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, ErrorTxt, ErrorObjectValue) then begin
            JSONManagement.InitializeObject(ErrorObjectValue);
            JSONManagement.GetJSONObject(JsonObject);
            JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, MessageTxt, MessageValue);
        end;

        exit(MessageValue);
    end;

    local procedure GetGraphInvitationsUrl(): Text
    begin
        exit(UrlHelper.GetGraphUrl + 'v1.0/invitations');
    end;

    local procedure GetGraphUserUrl(): Text
    begin
        exit(UrlHelper.GetGraphUrl + 'v1.0/users');
    end;

    local procedure GetGraphSubscribedSkusUrl(): Text
    begin
        exit(UrlHelper.GetGraphUrl + 'v1.0/subscribedSkus');
    end;

    [EventSubscriber(ObjectType::Page, 9033, 'OnInvitationStart', '', false, false)]
    local procedure SendTelemetryForInvitationStart()
    begin
        SendTraceTag('0000178', InviteExternalAccountantTelemetryCategoryTxt, VERBOSITY::Normal,
          InviteExternalAccountantTelemetryStartTxt, DATACLASSIFICATION::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Page, 9033, 'OnInvitationNoExternalAccountantLicenseFail', '', false, false)]
    local procedure SendTelemetryForInvitationNoExternalAccountantLicenseFail()
    begin
        SendTraceTag('0000179', InviteExternalAccountantTelemetryCategoryTxt, VERBOSITY::Error,
          InviteExternalAccountantTelemetryLicenseFailTxt, DATACLASSIFICATION::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Page, 9033, 'OnInvitationNoAADPermissionsFail', '', false, false)]
    local procedure SendTelemetryForInvitationNoAADPermissionsFail()
    begin
        SendTraceTag('000017A', InviteExternalAccountantTelemetryCategoryTxt, VERBOSITY::Error,
          InviteExternalAccountantTelemetryAADPermissionFailTxt, DATACLASSIFICATION::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Page, 9033, 'OnInvitationNoUserTablePermissionsFail', '', false, false)]
    local procedure SendTelemetryForInvitationNoUserTableWritePermissionsFail()
    begin
        SendTraceTag('00001DK', InviteExternalAccountantTelemetryCategoryTxt, VERBOSITY::Error,
          InviteExternalAccountantTelemetryUserTablePermissionFailTxt, DATACLASSIFICATION::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Page, 9033, 'OnInvitationEnd', '', false, false)]
    local procedure SendTelemetryForInvitationEnd(WasInvitationSuccessful: Boolean; Result: Text; TargetLicense: Text)
    begin
        if WasInvitationSuccessful then
            SendTraceTag('000017B', InviteExternalAccountantTelemetryCategoryTxt, VERBOSITY::Normal,
              StrSubstNo(InviteExternalAccountantTelemetryEndTxt, Result, TargetLicense), DATACLASSIFICATION::SystemMetadata)
        else
            SendTraceTag('000017C', InviteExternalAccountantTelemetryCategoryTxt, VERBOSITY::Error,
              StrSubstNo(InviteExternalAccountantTelemetryEndTxt, Result, TargetLicense), DATACLASSIFICATION::SystemMetadata);
    end;

    [EventSubscriber(ObjectType::Codeunit, 9033, 'OnInvitationCreateNewUser', '', false, false)]
    local procedure SendTelemetryForInvitationCreateNewUser(UserCreated: Boolean)
    begin
        if UserCreated then
            SendTraceTag('00001DL', InviteExternalAccountantTelemetryCategoryTxt, VERBOSITY::Normal,
              InviteExternalAccountantTelemetryCreateNewUserSuccessTxt, DATACLASSIFICATION::SystemMetadata)
        else
            SendTraceTag('00001DM', InviteExternalAccountantTelemetryCategoryTxt, VERBOSITY::Error,
              InviteExternalAccountantTelemetryCreateNewUserFailedTxt, DATACLASSIFICATION::SystemMetadata);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInvitationCreateNewUser(UserCreated: Boolean)
    begin
        // This event is called when the invitation process tries to create a user.
    end;
}

