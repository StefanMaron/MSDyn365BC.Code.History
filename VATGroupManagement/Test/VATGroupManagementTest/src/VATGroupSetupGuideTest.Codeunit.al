codeunit 139741 "VAT Group Setup Guide Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Workaround description: the error, if the test fails, is thrown both in the failing test BUT ALSO in the procedure ConfirmHandlerYes (when present)
    // because otherwise the first error will be caught in the procedure OnQueryClosePage from the page "VAT Group Setup Guide".
    // If a test fails with the error message "Unhandled UI: Confirm The setup for the VAT Group is not finished.\\Are you sure you want to exit?"
    // it's probably because an error was thrown in a procedure where there is no ConfirmHandlerYes handler but the real error message has not been displayed
    // because it has been caught in the procedure OnQueryClosePage from the page "VAT Group Setup Guide".

    var
        Assert: Codeunit Assert;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure TestWelcomePageSection()
    var
        VATGroupSetupGuideTestPage: TestPage "VAT Group Setup Guide";
    begin
        // [WHEN] The environment is OnPrem
        EnableSaaS(false);

        // [WHEN] The user opens the Welcome page section
        VATGroupSetupGuideTestPage.OpenView();

        // [THEN] The Back button should be disabled, the Next button should be enabled and the Finish button should be disabled
        CheckButtons(VATGroupSetupGuideTestPage, false, true, false);

        VATGroupSetupGuideTestPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure TestSelectTypePageSection()
    var
        VATGroupSetupGuideTestPage: TestPage "VAT Group Setup Guide";
    begin
        // [WHEN] The environment is OnPrem
        EnableSaaS(false);

        // Welcome page section
        // [WHEN] When the user clicks Next to open the SelectType page section
        VATGroupSetupGuideTestPage.OpenEdit();
        VATGroupSetupGuideTestPage.ActionNext.Invoke();

        // Select Type page section
        // [THEN] The Back button should be disabled, the Next button should be disabled and the Finish button should be enabled
        CheckButtons(VATGroupSetupGuideTestPage, false, false, true);
        // [THEN] The Field VATGroupRole should be visible
        Assert.IsTrue(VATGroupSetupGuideTestPage.VATGroupRole.Visible(), 'The Field VATGroupRole should be visible');

        // [WHEN] The user chooses the Representative VAT Group Role
        VATGroupSetupGuideTestPage.VATGroupRole.SetValue(1);
        // [THEN] The Back button should be enabled, the Next button should be enabled and the Finish button should be disabled
        CheckButtons(VATGroupSetupGuideTestPage, true, true, false);

        // [WHEN] The user chooses the empty VAT Group Role
        VATGroupSetupGuideTestPage.VATGroupRole.SetValue(0);
        // [THEN] The Back button should be disabled, the Next button should be disabled and the Finish button should be enabled
        CheckButtons(VATGroupSetupGuideTestPage, false, false, true);

        // [WHEN] The user chooses the Member VAT Group Role
        VATGroupSetupGuideTestPage.VATGroupRole.SetValue(2);
        // [THEN] The Back button should be enabled, the Next button should be enabled and the Finish button should be disabled
        CheckButtons(VATGroupSetupGuideTestPage, true, true, false);

        VATGroupSetupGuideTestPage.Close();
    end;

    [Test]
    [HandlerFunctions('VATGroupApprovedMemberListHandler')]
    procedure TestRepresentativeSetup()
    var
        VATGroupApprovedMember: Record "VAT Group Approved Member";
        VATGroupSetupGuideTestPage: TestPage "VAT Group Setup Guide";
    begin
        // [WHEN] The environment is OnPrem
        EnableSaaS(false);

        // Clear the table and populate it with a new approved member
        VATGroupApprovedMember.DeleteAll();
        VATGroupApprovedMember.ID := CreateGuid();
        VATGroupApprovedMember.Insert();

        // Welcome page section
        // [WHEN] The user clicks Next to open the SelectType page section
        VATGroupSetupGuideTestPage.OpenEdit();
        VATGroupSetupGuideTestPage.ActionNext.Invoke();

        // Select Type page section
        // [WHEN] The user chooses the Representative VAT Group Role and clicks Next to open the Approved Members page section
        VATGroupSetupGuideTestPage.VATGroupRole.SetValue(1);
        VATGroupSetupGuideTestPage.ActionNext.Invoke();

        // Approved Members page section
        // [THEN] The Back button should be enabled, the Next button should be enabled and the Finish button should be disabled
        CheckButtons(VATGroupSetupGuideTestPage, true, true, false);
        // [THEN] The ApprovedMembers link should be visible
        Assert.IsTrue(VATGroupSetupGuideTestPage.ApprovedMembers.Visible(), 'Approved Members button should be visible');

        // [THEN] Only one approved member should be present
        Assert.AreEqual('1', VATGroupSetupGuideTestPage.ApprovedMembers.Value(), 'Approved Members numbers should be 0');

        // [WHEN] The user clicks the link the Page "VAT Group Approved Member List" opens
        // [WHEN] The user add a new approved member in the page (handler function)
        VATGroupSetupGuideTestPage.ApprovedMembers.Drilldown();
        // [THEN] Two approved members should be present
        Assert.AreEqual('2', VATGroupSetupGuideTestPage.ApprovedMembers.Value(), 'Approved Members numbers should be 0');

        // [WHEN] The user clicks Next to open the Finish page section
        VATGroupSetupGuideTestPage.ActionNext.Invoke();

        // Finish page section
        // [THEN] The Back button should be enabled, the Next button should be disabled and the Finish button should be enabled
        CheckButtons(VATGroupSetupGuideTestPage, true, false, true);
        // [THEN] The TestConnection button should not be visible
        Assert.IsFalse(VATGroupSetupGuideTestPage.TestConnection.Visible(), 'TestConnection button should not be visible');
        // [THEN] The ActionFinish button should be visible
        Assert.IsTrue(VATGroupSetupGuideTestPage.ActionFinish.Visible(), 'ActionFinish button should be visible');
        // [THEN] The "Enable JobQueue" button should not be visible
        Assert.IsFalse(VATGroupSetupGuideTestPage."Enable JobQueue".Visible(), '"Enable JobQueue" button should not be visible');

        // [WHEN] The user clicks the Finish button
        // [THEN] Setup is completed without errors
        VATGroupSetupGuideTestPage.ActionFinish.Invoke();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure TestMemberSetupPageSection()
    var
        VATGroupSetupGuideTestPage: TestPage "VAT Group Setup Guide";
    begin
        // [WHEN] The environment is OnPrem
        EnableSaaS(false);

        // Welcome page section
        // [WHEN] The user clicks Next to open the SelectType page section
        VATGroupSetupGuideTestPage.OpenEdit();
        VATGroupSetupGuideTestPage.ActionNext.Invoke();

        // SelectType page section
        // [WHEN] The user chooses the Member VAT Group Role
        VATGroupSetupGuideTestPage.VATGroupRole.SetValue(2);
        VATGroupSetupGuideTestPage.ActionNext.Invoke();

        // [THEN] The Back button should be enabled, the Next button should be disabled and the Finish button should be disabled
        CheckButtons(VATGroupSetupGuideTestPage, true, false, false);

        // [THEN] The Back buttons MemberGuid, APIURL, GroupRepresentativeCompany, VATGroupAuthenticationType should be visible
        Assert.IsTrue(VATGroupSetupGuideTestPage.MemberGuid.Visible(), 'MemberGuid Field should be visible');
        Assert.IsTrue(VATGroupSetupGuideTestPage.APIURL.Visible(), 'APIURL Field should be visible');
        Assert.IsTrue(VATGroupSetupGuideTestPage.GroupRepresentativeCompany.Visible(), 'GroupRepresentativeCompany Field should be visible');
        Assert.IsTrue(VATGroupSetupGuideTestPage.VATGroupAuthenticationType.Visible(), 'VATGroupAuthenticationType Field should be visible');
        Assert.IsFalse(VATGroupSetupGuideTestPage.VATGroupAuthenticationTypeSaas.Visible(), 'VATGroupAuthenticationTypeSaas Field should not be visible');

        // [THEN] The user can change the authentication type
        VATGroupSetupGuideTestPage.VATGroupAuthenticationType.SetValue(0); // Web Service Access key
        VATGroupSetupGuideTestPage.VATGroupAuthenticationType.SetValue(1); // OAuth2
        VATGroupSetupGuideTestPage.VATGroupAuthenticationType.SetValue(2); // Windows Authentication

        // [WHEN] The user types the required info
        VATGroupSetupGuideTestPage.APIURL.Value('TestValue');
        VATGroupSetupGuideTestPage.GroupRepresentativeCompany.Value('TestValue');
        // [THEN] The Back button should be enabled, the Next button should be enabled and the Finish button should be disabled
        CheckButtons(VATGroupSetupGuideTestPage, true, true, false);

        VATGroupSetupGuideTestPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure TestMemberSetupPageSectionSaas()
    var
        VATGroupSetupGuideTestPage: TestPage "VAT Group Setup Guide";
    begin
        // [WHEN] The environment is OnPrem
        EnableSaaS(true);

        // Welcome page section
        // [WHEN] The user clicks Next to open the SelectType page section
        VATGroupSetupGuideTestPage.OpenEdit();
        VATGroupSetupGuideTestPage.ActionNext.Invoke();

        // SelectType page section
        // [WHEN] The user chooses the Member VAT Group Role
        VATGroupSetupGuideTestPage.VATGroupRole.SetValue(2);
        VATGroupSetupGuideTestPage.ActionNext.Invoke();

        // [THEN] The Back button should be enabled, the Next button should be disabled and the Finish button should be disabled
        CheckButtons(VATGroupSetupGuideTestPage, true, false, false);

        // [THEN] The Back buttons MemberGuid, APIURL, GroupRepresentativeCompany, VATGroupAuthenticationType should be visible
        Assert.IsTrue(VATGroupSetupGuideTestPage.MemberGuid.Visible(), 'MemberGuid Field should be visible');
        Assert.IsTrue(VATGroupSetupGuideTestPage.APIURL.Visible(), 'APIURL Field should be visible');
        Assert.IsTrue(VATGroupSetupGuideTestPage.GroupRepresentativeCompany.Visible(), 'GroupRepresentativeCompany Field should be visible');
        Assert.IsTrue(VATGroupSetupGuideTestPage.VATGroupAuthenticationTypeSaas.Visible(), 'VATGroupAuthenticationTypeSaas Field should be visible');
        Assert.IsFalse(VATGroupSetupGuideTestPage.VATGroupAuthenticationType.Visible(), 'VATGroupAuthenticationType Field should not be visible');

        // [THEN] The user can change the authentication type
        asserterror VATGroupSetupGuideTestPage.VATGroupAuthenticationTypeSaas.SetValue(2); // Windows Authentication should not be visible
        ClearLastError(); // remove last error (expected error) otherwise test will fail when the handler ConfirmHandlerYes is called
        VATGroupSetupGuideTestPage.VATGroupAuthenticationTypeSaas.SetValue(0); // Web Service Access key
        VATGroupSetupGuideTestPage.VATGroupAuthenticationTypeSaas.SetValue(1); // OAuth2

        // [WHEN] The user types the required info
        VATGroupSetupGuideTestPage.APIURL.Value('TestValue');
        VATGroupSetupGuideTestPage.GroupRepresentativeCompany.Value('TestValue');
        // [THEN] The Back button should be enabled, the Next button should be enabled and the Finish button should be disabled
        CheckButtons(VATGroupSetupGuideTestPage, true, true, false);

        VATGroupSetupGuideTestPage.Close();
    end;

    [Test]
    procedure TestMemberWebServiceAccessKeyAuthenticationUntilFinishStep()
    var
        VATGroupSetupGuideTestPage: TestPage "VAT Group Setup Guide";
    begin
        // [WHEN] The environment is OnPrem
        EnableSaaS(false);

        // Welcome page
        // [WHEN] The user clicks Next to open the SelectType page section
        VATGroupSetupGuideTestPage.OpenEdit();
        VATGroupSetupGuideTestPage.ActionNext.Invoke();

        // SelectType page
        // [WHEN] The user chooses the Member VAT Group Role and clicks Next to open the Authentication section page
        VATGroupSetupGuideTestPage.VATGroupRole.SetValue(2);
        VATGroupSetupGuideTestPage.ActionNext.Invoke();

        // Authentication section page
        // [WHEN] The user types the required info
        VATGroupSetupGuideTestPage.APIURL.Value('TestValue');
        VATGroupSetupGuideTestPage.GroupRepresentativeCompany.Value('TestValue');
        // [WHEN] The user set the authentication type to Web Service Access Key
        VATGroupSetupGuideTestPage.VATGroupAuthenticationType.SetValue(0);
        // [WHEN] The user clicks Next to open the Web Service Access Key Authentication page section 
        VATGroupSetupGuideTestPage.ActionNext.Invoke();

        // Web Service Access Key Authentication page section 
        // [THEN] The Back button should be enabled, the Next button should be disabled and the Finish button should be disabled
        CheckButtons(VATGroupSetupGuideTestPage, true, false, false);
        // [THEN] The Username and WebServiceAccessKey fields should be visible
        Assert.IsTrue(VATGroupSetupGuideTestPage.Username.Visible(), 'The Username field should be visible');
        Assert.IsTrue(VATGroupSetupGuideTestPage.WebServiceAccessKey.Visible(), 'The WebServiceAccessKey field should be visible');

        // [WHEN] The user inserts the configuration values
        VATGroupSetupGuideTestPage.Username.Value('TestValue');
        VATGroupSetupGuideTestPage.WebServiceAccessKey.Value('TestValue');
        // [THEN] The Back button should be enabled, the Next button should be enabled and the Finish button should be disabled
        CheckButtons(VATGroupSetupGuideTestPage, true, true, false);
        // [WHEN] The user clicks Next to open the VAT Report Configuration page section    
        VATGroupSetupGuideTestPage.ActionNext.Invoke();

        // VAT Report Configuration page section
        // [THEN] The Back button should be enabled, the Next button should be enabled and the Finish button should be disabled
        CheckButtons(VATGroupSetupGuideTestPage, true, true, false);
        // [WHEN] The user clicks Next to open the Finish page section
        VATGroupSetupGuideTestPage.ActionNext.Invoke();

        // Finish page section 
        // [THEN] The Back button should be enabled, the Next button should be disabled and the Finish button should be enabled
        CheckButtons(VATGroupSetupGuideTestPage, true, false, true);
        // [THEN] The TestConnection button should be visible
        Assert.IsTrue(VATGroupSetupGuideTestPage.TestConnection.Visible(), 'The button TestConnection should be visible');
        // [THEN] The "Enable JobQueue" button should not be visible
        Assert.IsFalse(VATGroupSetupGuideTestPage."Enable JobQueue".Visible(), 'The button "Enable JobQueue" should not be visible');

        // [WHEN] The User click the TestConnection button 
        // [THEN] A error is expected because the connection has wrong configuration values
        asserterror VATGroupSetupGuideTestPage.TestConnection.Invoke();

        // [THEN] The "Enable JobQueue" button should not be visible (it gets visible only when the TestConnection is successfully executed)
        Assert.IsFalse(VATGroupSetupGuideTestPage."Enable JobQueue".Visible(), 'The button "Enable JobQueue" should not be visible');

        // [WHEN] The user click the Finish button
        // [THEN] Setup is completed without errors
        VATGroupSetupGuideTestPage.ActionFinish.Invoke();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure TestMemberOAuth2UntilFinishStep()
    var
        VATGroupSetupGuideTestPage: TestPage "VAT Group Setup Guide";
    begin
        // [WHEN] The environment is OnPrem
        EnableSaaS(false);

        // Welcome page
        // [WHEN] The user clicks Next to open the SelectType page section
        VATGroupSetupGuideTestPage.OpenEdit();
        VATGroupSetupGuideTestPage.ActionNext.Invoke();

        // SelectType page
        // [WHEN] The user chooses the Member VAT Group Role and clicks Next to open the Authentication section page
        VATGroupSetupGuideTestPage.VATGroupRole.SetValue(2);
        VATGroupSetupGuideTestPage.ActionNext.Invoke();

        // Authentication section page
        // [WHEN] The user types the required info
        VATGroupSetupGuideTestPage.APIURL.Value('TestValue');
        VATGroupSetupGuideTestPage.GroupRepresentativeCompany.Value('TestValue');
        // [WHEN] The user set the authentication type to OAuth2
        VATGroupSetupGuideTestPage.VATGroupAuthenticationType.SetValue(1);
        // [WHEN] The user clicks Next to open the OAuth2 page section 
        VATGroupSetupGuideTestPage.ActionNext.Invoke();

        // OAuth2 page section 
        // [THEN] The Back button should be enabled, the Next button should be disabled and the Finish button should be disabled
        CheckButtons(VATGroupSetupGuideTestPage, true, false, false);
        // [THEN] The ClientID, Client Secret, OAuth 2.0 Authority Endpoint, OAuth 2.0 Resource URL and OAuth 2.0 Redirect URL fields should be visible
        Assert.IsTrue(VATGroupSetupGuideTestPage.ClientId.Visible(), 'ClientID field should be visible');
        Assert.IsTrue(VATGroupSetupGuideTestPage.ClientSecret.Visible(), 'Client Secret field should be visible');
        Assert.IsTrue(VATGroupSetupGuideTestPage.OAuthAuthorityUrl.Visible(), 'OAuth 2.0 Authority Endpoint field should be visible');
        Assert.IsTrue(VATGroupSetupGuideTestPage.ResourceURL.Visible(), 'OAuth 2.0 Resource URL field should be visible');
        Assert.IsTrue(VATGroupSetupGuideTestPage.RedirectURL.Visible(), 'OAuth 2.0 Redirect URL field should be visible');

        // [WHEN] The user add the required information to set up the OAuth
        VATGroupSetupGuideTestPage.ClientId.SetValue('TestValue');
        VATGroupSetupGuideTestPage.ClientSecret.SetValue('TestValue');
        VATGroupSetupGuideTestPage.OAuthAuthorityUrl.SetValue('http://OAuth-test-URL.com');
        VATGroupSetupGuideTestPage.ResourceURL.SetValue('http://OAuth-test-URL.com');
        VATGroupSetupGuideTestPage.RedirectURL.SetValue('http://OAuth-test-URL.com');
        // [THEN] The Back button should be enabled, the Next button should be enabled and the Finish button should be disabled
        CheckButtons(VATGroupSetupGuideTestPage, true, true, false);

        // [WHEN] The user clicks the Next button to test the OAuth connection
        // [THEN] A error is expected because from the test we cannot verify the authentication
        asserterror VATGroupSetupGuideTestPage.ActionNext.Invoke();
    end;


    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestMemberWindowsAuthentication()
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
        VATGroupSetupGuideTestPage: TestPage "VAT Group Setup Guide";
    begin
        VATReportsConfiguration.DeleteAll();

        // [WHEN] The environment is OnPrem
        EnableSaaS(false);

        // Welcome page
        // [WHEN] The user clicks Next to open the SelectType page section
        VATGroupSetupGuideTestPage.OpenEdit();
        VATGroupSetupGuideTestPage.ActionNext.Invoke();

        // SelectType page
        // [WHEN] The user chooses the Member VAT Group Role and clicks Next to open the Authentication section page
        VATGroupSetupGuideTestPage.VATGroupRole.SetValue(2);
        VATGroupSetupGuideTestPage.ActionNext.Invoke();

        // Authentication section page
        // [WHEN] The user types the required info
        VATGroupSetupGuideTestPage.APIURL.Value(GetAPIURL());
        VATGroupSetupGuideTestPage.GroupRepresentativeCompany.Value(CompanyName());
        // [WHEN] The user set the authentication type to Windows Authentication
        VATGroupSetupGuideTestPage.VATGroupAuthenticationType.SetValue(2);
        // [WHEN] The user clicks Next to open the VAT Report Configuration page section    
        VATGroupSetupGuideTestPage.ActionNext.Invoke();

        // VAT Report Configuration page section
        // [THEN] The Back button should be enabled, the Next button should be enabled and the Finish button should be disabled
        CheckButtons(VATGroupSetupGuideTestPage, true, true, false);
        // [WHEN] The user clicks Next to open the Finish page section
        VATGroupSetupGuideTestPage.ActionNext.Invoke();

        // Finish page section 
        // [THEN] The Back button should be enabled, the Next button should be disabled and the Finish button should be enabled
        CheckButtons(VATGroupSetupGuideTestPage, true, false, true);
        Assert.IsTrue(VATGroupSetupGuideTestPage.TestConnection.Visible(), 'The button TestConnection should be visible');
        Assert.IsFalse(VATGroupSetupGuideTestPage."Enable JobQueue".Visible(), 'The button "Enable JobQueue" should not be visible');

        // [WHEN] The User click the TestConnection button 
        // [THEN] The connection is successfully working
        VATGroupSetupGuideTestPage.TestConnection.Invoke();

        // Re-enable when batch request is fixed
        // [THEN] The "Enable JobQueue" button should be visible (it gets visible only when the TestConnection is successfully executed)
        //Assert.IsTrue(VATGroupSetupGuideTestPage."Enable JobQueue".Visible(), 'The button "Enable JobQueue" should be visible');

        // [WHEN] The user click the Finish button
        // [THEN] Setup is completed without errors
        VATGroupSetupGuideTestPage.ActionFinish.Invoke();

        // [WHEN] The setup is completed
        // [THEN] A VATGROUP record is inserted in the table "VAT Reports Configuration"
        VATReportsConfiguration.SetFilter("Submission Codeunit ID", Format(Codeunit::"VAT Group Submit To Represent."));
        VATReportsConfiguration.SetFilter("VAT Report Version", 'VATGROUP');
        Assert.AreEqual(1, VATReportsConfiguration.Count(), 'A record for VATGROUP should be created in the table "VAT Reports Configuration"');
    end;

    local procedure EnableSaaS(IsSaaS: Boolean)
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(IsSaaS);
    end;

    local procedure GetAPIURL(): Text
    var
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        TmpURL: Text;
    begin
        TmpURL := LibraryGraphMgt.CreateQueryTargetURL(Query::"VAT Group Submission Status", '');
        TmpURL := CopyStr(TmpURL, 1, StrPos(TmpURL, '/api/') - 1);
        exit(TmpURL);
    end;

    local procedure CheckButtons(var VATGroupSetupGuideTestPage: TestPage "VAT Group Setup Guide"; ActionBack: Boolean; ActionNext: Boolean; ActionFinish: Boolean)
    begin
        Assert.AreEqual(ActionBack, VATGroupSetupGuideTestPage.ActionBack.Enabled(), StrSubstNo('The Back button should be enabled: %1', ActionBack));
        Assert.AreEqual(ActionNext, VATGroupSetupGuideTestPage.ActionNext.Enabled(), StrSubstNo('The Next button should be enabled: %1', ActionNext));
        Assert.AreEqual(ActionFinish, VATGroupSetupGuideTestPage.ActionFinish.Enabled(), StrSubstNo('The Finish button should be enabled: %1', ActionFinish));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;

        Assert.AreEqual('', GetLastErrorText(), GetLastErrorText());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATGroupApprovedMemberListHandler(var VATGroupApprovedMemberList: TestPage "VAT Group Approved Member List")
    begin
        VATGroupApprovedMemberList.New();
        VATGroupApprovedMemberList.ID.SetValue(CreateGuid());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}