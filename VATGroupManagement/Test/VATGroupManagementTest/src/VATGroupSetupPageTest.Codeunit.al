codeunit 139745 "VAT Group Setup Page Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TestVATReportSetupNoRolePageBehavior()
    var
        VATReportSetupTestPage: TestPage "VAT Report Setup";
    begin
        // [GIVEN] The VAT Report Setup page is open
        VATReportSetupTestPage.OpenEdit();

        // [WHEN] No VAT Group role is selected
        VATReportSetupTestPage.VATGroupRole.SetValue(0);

        // [THEN] No page controls and buttons related to any VAT Group role should be displayed
        Assert.IsFalse(VATReportSetupTestPage.VATGroupAuthenticationType.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.VATGroupAuthenticationTypeSaas.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.MemberIdentifier.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.APIURL.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.GroupRepresentativeCompany.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.UserName.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.WebserviceAccessKey.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.ClientId.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.ClientSecret.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.AuthorityURL.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.ResourceURL.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.RedirectURL.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.ApprovedMembers.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.RenewToken.Visible(), 'Control should not be visible');
    end;

    [Test]
    procedure TestVATReportSetupRepresentativePageBehavior()
    var
        VATGroupApprovedMember: Record "VAT Group Approved Member";
        VATReportSetupTestPage: TestPage "VAT Report Setup";
        VATGroupApprovedMemberListTestPage: TestPage "VAT Group Approved Member List";
    begin
        // [GIVEN] There are no approved vat group members
        VATGroupApprovedMember.DeleteAll();

        // [GIVEN] The VAT Report Setup page is open
        VATReportSetupTestPage.OpenEdit();

        // [WHEN] Representative VAT Group role is selected
        VATReportSetupTestPage.VATGroupRole.SetValue(1);

        // [THEN] Only 1 control should be visible
        Assert.IsFalse(VATReportSetupTestPage.VATGroupAuthenticationType.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.VATGroupAuthenticationTypeSaas.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.MemberIdentifier.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.APIURL.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.GroupRepresentativeCompany.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.UserName.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.WebserviceAccessKey.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.ClientId.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.ClientSecret.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.AuthorityURL.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.ResourceURL.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.RedirectURL.Visible(), 'Control should not be visible');
        Assert.IsTrue(VATReportSetupTestPage.ApprovedMembers.Visible(), 'Control should be visible');
        Assert.IsFalse(VATReportSetupTestPage.RenewToken.Visible(), 'Control should not be visible');

        // [THEN] The Approved Members should reflect the count of how many members are approved.
        Assert.AreEqual(0, VATReportSetupTestPage.ApprovedMembers.AsInteger(), 'Should be 0 members');

        // [THEN] Clicking on the Approved Members control should open the VATGroupApprovedMember List Page
        VATGroupApprovedMemberListTestPage.Trap();
        VATReportSetupTestPage.ApprovedMembers.Drilldown();

        // [THEN] Inserting an approved member in that page should reflect on the value in the approved member control
        VATGroupApprovedMemberListTestPage.New();
        VATGroupApprovedMemberListTestPage.ID.SetValue(CreateGuid());
        VATGroupApprovedMemberListTestPage."Group Member Name".SetValue('TEST Member');
        VATGroupApprovedMemberListTestPage.New();
        VATGroupApprovedMemberListTestPage.Close();

        VATReportSetupTestPage.View().Invoke();
        Assert.AreEqual(1, VATReportSetupTestPage.ApprovedMembers.AsInteger(), 'Should be 1 member after the insert');
    end;

    [Test]
    procedure TestVATReportSetupMemberWindowsPageBehavior()
    var
        VATReportSetupTestPage: TestPage "VAT Report Setup";
    begin
        // [GIVEN] The VAT Report Setup page is open
        VATReportSetupTestPage.OpenEdit();

        // [GIVEN] The Member role is selected
        VATReportSetupTestPage.VATGroupRole.SetValue(2);

        // [WHEN] Windows authentication is selected
        VATReportSetupTestPage.VATGroupAuthenticationType.SetValue(2);

        // [THEN] Only page controls related to this role and authentication method should be visible
        Assert.IsTrue(VATReportSetupTestPage.VATGroupAuthenticationType.Visible(), 'Control should be visible');
        Assert.IsFalse(VATReportSetupTestPage.VATGroupAuthenticationTypeSaas.Visible(), 'Control should not be visible');
        Assert.IsTrue(VATReportSetupTestPage.MemberIdentifier.Visible(), 'Control should be visible');
        Assert.IsTrue(VATReportSetupTestPage.APIURL.Visible(), 'Control should be visible');
        Assert.IsTrue(VATReportSetupTestPage.GroupRepresentativeCompany.Visible(), 'Control should be visible');
        Assert.IsFalse(VATReportSetupTestPage.UserName.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.WebserviceAccessKey.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.ClientId.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.ClientSecret.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.AuthorityURL.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.ResourceURL.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.RedirectURL.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.ApprovedMembers.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.RenewToken.Visible(), 'Control should not be visible');
    end;

    [Test]
    procedure TestVATReportSetupMemberOnSaaSPageBehavior()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        VATReportSetupTestPage: TestPage "VAT Report Setup";
    begin
        // [GIVEN] The environment is SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] The VAT Report Setup page is open
        VATReportSetupTestPage.OpenEdit();

        // [WHEN] The Member role is selected
        VATReportSetupTestPage.VATGroupRole.SetValue(2);

        // [THEN] The SaaS specific authentication type control should be visible
        Assert.IsFalse(VATReportSetupTestPage.VATGroupAuthenticationType.Visible(), 'Control should not be visible');
        Assert.IsTrue(VATReportSetupTestPage.VATGroupAuthenticationTypeSaas.Visible(), 'Control should be visible');

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    procedure TestVATReportSetupMemberWSAKPageBehavior()
    var
        VATReportSetupTestPage: TestPage "VAT Report Setup";
    begin
        // [GIVEN] The VAT Report Setup page is open
        VATReportSetupTestPage.OpenEdit();

        // [GIVEN] The Member role is selected
        VATReportSetupTestPage.VATGroupRole.SetValue(2);

        // [WHEN] Windows authentication is selected
        VATReportSetupTestPage.VATGroupAuthenticationType.SetValue(0);

        // [WHEN] Secret values are inputed
        VATReportSetupTestPage.WebserviceAccessKey.SetValue('testkey');
        VATReportSetupTestPage.UserName.SetValue('testuser');

        // [THEN] Only page controls related to this role and authentication method should be visible
        Assert.IsTrue(VATReportSetupTestPage.VATGroupAuthenticationType.Visible(), 'Control should be visible');
        Assert.IsFalse(VATReportSetupTestPage.VATGroupAuthenticationTypeSaas.Visible(), 'Control should not be visible');
        Assert.IsTrue(VATReportSetupTestPage.MemberIdentifier.Visible(), 'Control should be visible');
        Assert.IsTrue(VATReportSetupTestPage.APIURL.Visible(), 'Control should be visible');
        Assert.IsTrue(VATReportSetupTestPage.GroupRepresentativeCompany.Visible(), 'Control should be visible');
        Assert.IsTrue(VATReportSetupTestPage.UserName.Visible(), 'Control should be visible');
        Assert.IsTrue(VATReportSetupTestPage.WebserviceAccessKey.Visible(), 'Control should be visible');
        Assert.IsFalse(VATReportSetupTestPage.ClientId.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.ClientSecret.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.AuthorityURL.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.ResourceURL.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.RedirectURL.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.ApprovedMembers.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.RenewToken.Visible(), 'Control should not be visible');

        // [THEN] Secret values should be obfuscated
        Assert.AreEqual('●●●●●●●●●●', VATReportSetupTestPage.UserName.Value(), 'Value should be masked');
        Assert.AreEqual('●●●●●●●●●●', VATReportSetupTestPage.WebserviceAccessKey.Value(), 'Value should be masked');
    end;

    [Test]
    procedure TestVATReportSetupMemberOAUTHPageBehavior()
    var
        VATReportSetupTestPage: TestPage "VAT Report Setup";
    begin
        // [GIVEN] The VAT Report Setup page is open
        VATReportSetupTestPage.OpenEdit();

        // [GIVEN] The Member role is selected
        VATReportSetupTestPage.VATGroupRole.SetValue(2);

        // [WHEN] Windows authentication is selected
        VATReportSetupTestPage.VATGroupAuthenticationType.SetValue(1);

        // [WHEN] Secret values are inputed
        VATReportSetupTestPage.ClientId.SetValue('testkey');
        VATReportSetupTestPage.ClientSecret.SetValue('testuser');

        // [THEN] Only page controls related to this role and authentication method should be visible
        Assert.IsTrue(VATReportSetupTestPage.VATGroupAuthenticationType.Visible(), 'Control should be visible');
        Assert.IsFalse(VATReportSetupTestPage.VATGroupAuthenticationTypeSaas.Visible(), 'Control should not be visible');
        Assert.IsTrue(VATReportSetupTestPage.MemberIdentifier.Visible(), 'Control should be visible');
        Assert.IsTrue(VATReportSetupTestPage.APIURL.Visible(), 'Control should be visible');
        Assert.IsTrue(VATReportSetupTestPage.GroupRepresentativeCompany.Visible(), 'Control should be visible');
        Assert.IsFalse(VATReportSetupTestPage.UserName.Visible(), 'Control should not be visible');
        Assert.IsFalse(VATReportSetupTestPage.WebserviceAccessKey.Visible(), 'Control should not be visible');
        Assert.IsTrue(VATReportSetupTestPage.ClientId.Visible(), 'Control should be visible');
        Assert.IsTrue(VATReportSetupTestPage.ClientSecret.Visible(), 'Control should be visible');
        Assert.IsTrue(VATReportSetupTestPage.AuthorityURL.Visible(), 'Control should be visible');
        Assert.IsTrue(VATReportSetupTestPage.ResourceURL.Visible(), 'Control should be visible');
        Assert.IsTrue(VATReportSetupTestPage.RedirectURL.Visible(), 'Control should be visible');
        Assert.IsFalse(VATReportSetupTestPage.ApprovedMembers.Visible(), 'Control should not be visible');
        Assert.IsTrue(VATReportSetupTestPage.RenewToken.Visible(), 'Control should be visible');

        // [THEN] Secret values should be obfuscated
        Assert.AreEqual('●●●●●●●●●●', VATReportSetupTestPage.ClientId.Value(), 'Value should be masked');
        Assert.AreEqual('●●●●●●●●●●', VATReportSetupTestPage.ClientSecret.Value(), 'Value should be masked');
    end;
}