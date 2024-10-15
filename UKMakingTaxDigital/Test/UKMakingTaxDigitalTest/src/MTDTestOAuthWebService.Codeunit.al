// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 148081 "MTDTestOAuthWebService"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Making Tax Digital] [OAuth 2.0] [Web Service]
    end;

    var
        LibraryMakingTaxDigital: Codeunit "Library - Making Tax Digital";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        CheckCompanyVATNoAfterSuccessAuthorizationQst: Label 'Authorization successful.\Do you want to open the Company Information setup to verify the VAT registration number?';
        OAuthNotConfiguredErr: Label 'OAuth setup is not enabled for HMRC Making Tax Digital.';
        OpenSetupQst: Label 'Do you want to open the setup?';
        RetrievePaymentsErr: Label 'Not possible to retrieve VAT payments.';
        RetrieveVATPaymentsTxt: Label 'Retrieve VAT Payments.', Locked = true;
        InvokeRequestMsg: Label 'Invoke GET request.', Locked = true;
        Error_VRN_INVALID_Txt: Label 'The provided VRN is invalid.', Locked = true;
        Error_INVALID_DATE_FROM_Txt: Label 'Invalid date from.', Locked = true;
        Error_INVALID_DATE_TO_Txt: Label 'Invalid date to.', Locked = true;
        Error_INVALID_DATE_RANGE_Txt: Label 'Invalid date range.', Locked = true;
        Error_INVALID_STATUS_Txt: Label 'Invalid status.', Locked = true;
        Error_PERIOD_KEY_INVALID_Txt: Label 'Invalid period key.', Locked = true;
        Error_INVALID_REQUEST_Txt: Label 'Invalid request.', Locked = true;
        Error_VAT_TOTAL_VALUE_Txt: Label 'TotalVatDue should be equal to the sum of vatDueSales and vatDueAcquisitions.', Locked = true;
        Error_VAT_NET_VALUE_Txt: Label 'NetVatDue should be the difference between the largest and the smallest values among totalVatDue and vatReclaimedCurrPeriod.', Locked = true;
        Error_INVALID_NUMERIC_VALUE_Txt: Label 'Please provide a numeric field.', Locked = true;
        Error_DATE_RANGE_TOO_LARGE_Txt: Label 'The date of the requested return cannot be more than four years from the current date.', Locked = true;
        Error_NOT_FINALISED_Txt: Label 'User has not declared VAT return as final.', Locked = true;
        Error_DUPLICATE_SUBMISSION_Txt: Label 'User has has already submitted a VAT return for the given period.', Locked = true;
        Error_CLIENT_OR_AGENT_NOT_AUTHORISED_Txt: Label 'The client and/or agent is not authorised.', Locked = true;
        Error_NOT_FOUND_Txt: Label 'The remote endpoint has indicated that no associated data is found.', Locked = true;
        Error_TOO_MANY_REQ_Txt: Label 'The HMRC service is busy. Try again later.', Locked = true;
        RefreshSuccessfulTxt: Label 'Refresh token successful.';
        RefreshFailedTxt: Label 'Refresh token failed.';
        ReasonTxt: Label 'Reason: ';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckVATRegNoAfterAuthorization_Deny()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        OAuth20SetupPage: TestPage "OAuth 2.0 Setup";
    begin
        // [FEATURE] [UI] [Authorization]
        // [SCENARIO 258181] PAG 1140 "OAuth 2.0 Setup" confirm about check VAT Reg. No. is shown after success authorization (deny confirm)
        // MockServicePacket399 MockService\MakingTaxDigital\200_authorize.txt
        Initialize();
        LibraryMakingTaxDigital.CreateOAuthSetup(OAuth20Setup, OAuth20Setup.Status::Disabled, '');
        LibraryMakingTaxDigital.MockAzureClientToken('MockServicePacket399');
        OpenOAuthSetupPage(OAuth20SetupPage, OAuth20Setup);

        LibraryVariableStorage.Enqueue(false); // deny confirm
        OAuth20SetupPage."Enter Authorization Code".SetValue('Test Authorization Code');
        OAuth20SetupPage.Close();

        OAuth20Setup.Find();
        OAuth20Setup.TestField(Status, OAuth20Setup.Status::Enabled);
        Assert.ExpectedMessage(CheckCompanyVATNoAfterSuccessAuthorizationQst, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,CompanyInformation_MPH')]
    [Scope('OnPrem')]
    procedure CheckVATRegNoAfterAuthorization_Accept()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        OAuth20SetupPage: TestPage "OAuth 2.0 Setup";
    begin
        // [FEATURE] [UI] [Authorization]
        // [SCENARIO 258181] PAG 1140 "OAuth 2.0 Setup" confirm about check VAT Reg. No. is shown after success authorization (accept confirm)
        // MockServicePacket399 MockService\MakingTaxDigital\200_authorize.txt
        Initialize();
        LibraryMakingTaxDigital.CreateOAuthSetup(OAuth20Setup, OAuth20Setup.Status::Disabled, '');
        LibraryMakingTaxDigital.MockAzureClientToken('MockServicePacket399');
        OpenOAuthSetupPage(OAuth20SetupPage, OAuth20Setup);

        LibraryVariableStorage.Enqueue(true); // accept confirm
        OAuth20SetupPage."Enter Authorization Code".SetValue('Test Authorization Code');
        OAuth20SetupPage.Close();

        OAuth20Setup.Find();
        OAuth20Setup.TestField(Status, OAuth20Setup.Status::Enabled);
        Assert.ExpectedMessage(CheckCompanyVATNoAfterSuccessAuthorizationQst, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,OAuth20SetupSetStatus_MPH')]
    [Scope('OnPrem')]
    procedure CheckOAuthConfigured_GetPayments_AcceptOpenSetup_SetEnabled()
    var
        DummyOAuth20Setup: Record "OAuth 2.0 Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 258181] COD 10530 "MTD Mgt.".RetrievePayments() confirms to open OAuth setup (accept open, set Enabled setup)
        // MockServicePacket330 MockService\MakingTaxDigital\200_payment.txt
        Initialize();
        LibraryMakingTaxDigital.SetupOAuthAndVATRegNo(false, '', 'MockServicePacket330');

        LibraryVariableStorage.Enqueue(true); // accept open OAuth setup
        LibraryVariableStorage.Enqueue(DummyOAuth20Setup.Status::Enabled);
        InvokeRetrievePayments(false);

        Assert.ExpectedMessage(StrSubstNo('%1\%2', OAuthNotConfiguredErr, OpenSetupQst), LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ParseErrors_Basic()
    begin
        // [SCENARIO 258181] Parsing of basic HMRC json error response in case of error code = 400\403\404
        // MockServicePacket310..Packet327
        PerformParseErrorScenario('MockServicePacket310', Error_VRN_INVALID_Txt);
        PerformParseErrorScenario('MockServicePacket311', Error_INVALID_DATE_FROM_Txt);
        PerformParseErrorScenario('MockServicePacket312', Error_INVALID_DATE_FROM_Txt);
        PerformParseErrorScenario('MockServicePacket313', Error_INVALID_DATE_TO_Txt);
        PerformParseErrorScenario('MockServicePacket314', Error_INVALID_DATE_TO_Txt);
        PerformParseErrorScenario('MockServicePacket315', Error_INVALID_DATE_RANGE_Txt);
        PerformParseErrorScenario('MockServicePacket316', Error_INVALID_DATE_RANGE_Txt);
        PerformParseErrorScenario('MockServicePacket317', Error_INVALID_STATUS_Txt);
        PerformParseErrorScenario('MockServicePacket318', Error_PERIOD_KEY_INVALID_Txt);
        PerformParseErrorScenario('MockServicePacket319', Error_INVALID_REQUEST_Txt);
        PerformParseErrorScenario('MockServicePacket320', Error_VAT_TOTAL_VALUE_Txt);
        PerformParseErrorScenario('MockServicePacket321', Error_VAT_NET_VALUE_Txt);
        PerformParseErrorScenario('MockServicePacket322', Error_INVALID_NUMERIC_VALUE_Txt);

        PerformParseErrorScenario('MockServicePacket323', Error_DATE_RANGE_TOO_LARGE_Txt);
        PerformParseErrorScenario('MockServicePacket324', Error_NOT_FINALISED_Txt);
        PerformParseErrorScenario('MockServicePacket325', Error_DUPLICATE_SUBMISSION_Txt);
        PerformParseErrorScenario('MockServicePacket326', Error_CLIENT_OR_AGENT_NOT_AUTHORISED_Txt);

        PerformParseErrorScenario('MockServicePacket327', Error_NOT_FOUND_Txt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ParseErrors_Advanced()
    var
        Value: array[6] of Text;
    begin
        // [SCENARIO 258181] Parsing of custom HMRC json error response
        // MockServicePacket328 MockService\MakingTaxDigital\400_custom.txt
        Initialize();
        LibraryMakingTaxDigital.SetupOAuthAndVATRegNo(true, '', 'MockServicePacket328');

        Value[1] := '400_custom_msg';
        Value[2] := '400_custom_err1_msg';
        Value[3] := '400_custom_err2_msg';
        Value[4] := '400_custom_err2_path';
        Value[5] := '400';
        Value[6] := 'BadRequest';

        asserterror InvokeRetrievePayments(true);

        VerifyParseErrorScenario(StrSubstNo('%1\%2\%3 (path %4)', Value[1], Value[2], Value[3], Value[4]));
        LibraryMakingTaxDigital.VerifyLatestHttpLogForSandbox(
            false,
            InvokeRequestMsg + ' ' + RetrieveVATPaymentsTxt,
            StrSubstNo('Http error %1 (%2). %3\%4\%5 (path %6)', Value[5], Value[6], Value[1], Value[2], Value[3], Value[4]),
            true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ParseErrors_Error429_TooManyReq()
    var
        Value: array[2] of Text;
    begin
        // [SCENARIO 258181] Parsing of http error 429 "Too Many Requests"
        // MockServicePacket329 MockService\MakingTaxDigital\429_too_many_requests.txt
        Initialize();
        LibraryMakingTaxDigital.SetupOAuthAndVATRegNo(true, '', 'MockServicePacket329');
        Value[1] := 'The request for the API is throttled as you have exceeded your quota.';
        Value[2] := '429';

        asserterror InvokeRetrievePayments(true);

        VerifyParseErrorScenario(Error_TOO_MANY_REQ_Txt);
        LibraryMakingTaxDigital.VerifyLatestHttpLogForSandbox(
            false,
            InvokeRequestMsg + ' ' + RetrieveVATPaymentsTxt,
            StrSubstNo('Http error %1 (%2). %3', 429, Value[2], Value[1]),
            true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MTDConnection_InvokeRequest_RefreshAccessToken_Negative()
    var
        MTDConnection: Codeunit "MTD Connection";
        ActualMessage: Text;
        HttpError: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 313380] COD 10537 "MTD Connection".InvokeRequest_RefreshAccessToken() in case of negative response
        // MockServicePacket304 MockService\MakingTaxDigital\401_unauthorized.txt
        Initialize();
        LibraryMakingTaxDigital.SetupOAuthAndVATRegNo(true, '/MockServicePacket304', '');

        HttpError := 'Http error 401 (Unauthorized)\invalid client id or secret';

        Assert.IsFalse(MTDConnection.InvokeRequest_RefreshAccessToken(ActualMessage), '');

        Assert.AreEqual(STRSUBSTNO('%1\%2%3', RefreshFailedTxt, ReasonTxt, HttpError), ActualMessage, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MTDConnection_InvokeRequest_RefreshAccessToken_Positive()
    var
        MTDConnection: Codeunit "MTD Connection";
        ActualMessage: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 313380] COD 10537 "MTD Connection".InvokeRequest_RefreshAccessToken() in case of positive response
        // MockServicePacket399 MockService\MakingTaxDigital\200_authorize.txt
        Initialize();
        LibraryMakingTaxDigital.SetupOAuthAndVATRegNo(true, '/MockServicePacket399', '');
        Assert.IsTrue(MTDConnection.InvokeRequest_RefreshAccessToken(ActualMessage), '');

        Assert.AreEqual(RefreshSuccessfulTxt, ActualMessage, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FraudPreventionHeaders()
    var
        MTDConnection: Codeunit "MTD Connection";
        JSONMgt: Codeunit "JSON Management";
        ResponseJson: Text;
        HttpError: Text;
    begin
        // [FEATURE] [Fraud Prevention]
        // [SCENARIO 316966] Fraud Prevention Headers are sent each http request
        // MockServicePacket340 MockService\MakingTaxDigital\200_period_open.txt
        Initialize();
        LibraryMakingTaxDigital.SetupOAuthAndVATRegNo(true, '', 'MockServicePacket340');

        Assert.IsTrue(MTDConnection.InvokeRequest_RetrieveVATReturnPeriods(WorkDate(), WorkDate(), ResponseJson, HttpError, false), '');

        JSONMgt.InitializeFromString(LibraryMakingTaxDigital.GetLatestHttpLogText());
        Assert.ExpectedMessage('***', JSONMgt.GetValue('Request.Header.Gov-Client-Connection-Method'));
        Assert.ExpectedMessage('***', JSONMgt.GetValue('Request.Header.Gov-Client-User-IDs'));
        Assert.ExpectedMessage('***', JSONMgt.GetValue('Request.Header.Gov-Client-Timezone'));
        Assert.ExpectedMessage('***', JSONMgt.GetValue('Request.Header.Gov-Client-User-Agent'));
        Assert.ExpectedMessage('***', JSONMgt.GetValue('Request.Header.Gov-Vendor-Version'));
        Assert.ExpectedMessage('***', JSONMgt.GetValue('Request.Header.Gov-Vendor-License-IDs'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FraudPreventionHeadersDisabled()
    var
        MTDConnection: Codeunit "MTD Connection";
        JSONMgt: Codeunit "JSON Management";
        ResponseJson: Text;
        HttpError: Text;
    begin
        // [FEATURE] [Fraud Prevention]
        // [SCENARIO 316966] Fraud Prevention Headers are not sent in case of VAT Report Setup "Disable Fraud Prevention Headers" = true
        // MockServicePacket340 MockService\MakingTaxDigital\200_period_open.txt
        Initialize();
        LibraryMakingTaxDigital.SetupOAuthAndVATRegNo(true, '', 'MockServicePacket340');

        UpdateVATReportSetup(true);
        Assert.IsTrue(MTDConnection.InvokeRequest_RetrieveVATReturnPeriods(WorkDate(), WorkDate(), ResponseJson, HttpError, false), '');

        JSONMgt.InitializeFromString(LibraryMakingTaxDigital.GetLatestHttpLogText());
        Assert.AreEqual('', JSONMgt.GetValue('Request.Header.Gov-Client-Connection-Method'), '');
        Assert.AreEqual('', JSONMgt.GetValue('Request.Header.Gov-Client-User-IDs'), '');
        Assert.AreEqual('', JSONMgt.GetValue('Request.Header.Gov-Client-Timezone'), '');
        Assert.AreEqual('', JSONMgt.GetValue('Request.Header.Gov-Client-User-Agent'), '');
        Assert.AreEqual('', JSONMgt.GetValue('Request.Header.Gov-Vendor-Version'), '');
        Assert.AreEqual('', JSONMgt.GetValue('Request.Header.Gov-Vendor-License-IDs'), '');

        UpdateVATReportSetup(false);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;
        IsInitialized := true;

        LibraryMakingTaxDigital.SetOAuthSetupSandbox(true);
    end;

    local procedure PerformParseErrorScenario(VATRegNo: Text; ExpectedMessage: Text)
    begin
        Initialize();
        LibraryMakingTaxDigital.SetupOAuthAndVATRegNo(true, '', VATRegNo);

        asserterror InvokeRetrievePayments(true);

        VerifyParseErrorScenario(ExpectedMessage);
    end;

    local procedure InvokeRetrievePayments(ShowMessage: Boolean)
    var
        MTDMgt: Codeunit "MTD Mgt.";
        TotalCount: Integer;
        NewCount: Integer;
        ModifiedCount: Integer;
    begin
        MTDMgt.RetrievePayments(WorkDate(), WorkDate(), TotalCount, NewCount, ModifiedCount, ShowMessage);
    end;

    local procedure OpenOAuthSetupPage(var OAuth20SetupPage: TestPage "OAuth 2.0 Setup"; OAuth20Setup: Record "OAuth 2.0 Setup")
    begin
        OAuth20SetupPage.Trap();
        Page.Run(Page::"OAuth 2.0 Setup", OAuth20Setup);
    end;

    local procedure UpdateVATReportSetup(DisableFPHeaders: Boolean)
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        with VATReportSetup do begin
            Get();
            "MTD Disable FraudPrev. Headers" := DisableFPHeaders;
            Modify();
        end;
    end;

    local procedure VerifyParseErrorScenario(ExpectedMessage: Text)
    begin
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo('%1\%2%3', RetrievePaymentsErr, LibraryMakingTaxDigital.GetResonLbl(), ExpectedMessage));
    end;

    [ModalPageHandler]
    procedure OAuth20SetupSetStatus_MPH(var OAuth20SetupPage: TestPage "OAuth 2.0 Setup")
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
    begin
        OAuth20Setup.Get(LibraryMakingTaxDigital.GetOAuthSandboxSetupCode());
        OAuth20Setup.Status := LibraryVariableStorage.DequeueInteger();
        OAuth20Setup.Modify();
        OAuth20SetupPage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CompanyInformation_MPH(var OAuth20SetupPage: TestPage "Company Information")
    begin
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}
