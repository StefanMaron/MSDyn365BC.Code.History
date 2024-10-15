codeunit 138696 "Page Troubleshooting Test"
{
    Subtype = Test;
    EventSubscriberInstance = Manual;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        PageSuccessfullyValidatedTxt: Label 'OK';
        PageValidationFailedWithErrorsTxt: Label '%1 error(s)';
        LibraryPermissions: Codeunit "Library - Permissions";
        UsersCreateSuperUser: Codeunit "Users - Create Super User";
        ScanCompletedWithErrorsMsg: Label 'Scanning complete, %1 error(s) were found.';
        ScanCompletedSuccessfullyMsg: Label 'Scanning complete, no problems were found.';

    local procedure Init()
    var
        TenantProfile: Record "Tenant Profile";
        UserPageMetadata: Record "User Page Metadata";
        TenantProfilePageMetadata: Record "Tenant Profile Page Metadata";
    begin
        TenantProfile.DeleteAll();
        TenantProfilePageMetadata.DeleteAll();
        if UserPageMetadata.FindSet(true, true) then
            repeat
                UserPageMetadata.Delete();
            until UserPageMetadata.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('ScanCompletedSuccessfullyMessageHandler')]
    procedure ScanValidProfilePageCustomizations()
    var
        AllProfile: Record "All Profile";
        ProfileCustomizationList: TestPage "Profile Customization List";
    begin
        Init();
        LibraryLowerPermissions.SetO365Full();

        CreateProfile(AllProfile);
        AddValidPageCustomization(AllProfile);
        CreateProfile(AllProfile);
        AddValidPageCustomization(AllProfile);

        ProfileCustomizationList.OpenEdit();
        ProfileCustomizationList.TroubleshootProblems.Invoke();

        ProfileCustomizationList.First();
        repeat
            Assert.AreEqual(PageSuccessfullyValidatedTxt, ProfileCustomizationList.Health.Value, 'Page ' + ProfileCustomizationList.PageCaptionField.Value + ' is not healthy.');
        until ProfileCustomizationList.Next() = false;
    end;

    [Test]
    [HandlerFunctions('ScanCompletedWithErrorsMessageHandler')]
    procedure ScanInvalidProfilePageCustomizations()
    var
        AllProfile: Record "All Profile";
        ProfileCustomizationList: TestPage "Profile Customization List";
    begin
        Init();
        LibraryLowerPermissions.SetO365Full();

        CreateProfile(AllProfile);
        AddInvalidPageCustomization(AllProfile);
        CreateProfile(AllProfile);
        AddInvalidPageCustomization(AllProfile);

        ProfileCustomizationList.OpenEdit();
        ProfileCustomizationList.TroubleshootProblems.Invoke();

        ProfileCustomizationList.First();
        repeat
            Assert.AreEqual(StrSubstNo(PageValidationFailedWithErrorsTxt, 1), ProfileCustomizationList.Health.Value, 'Page ' + ProfileCustomizationList.PageCaptionField.Value + ' does not contain expected error.');
        until ProfileCustomizationList.Next() = false;
    end;

    [Test]
    [HandlerFunctions('ScanCompletedSuccessfullyMessageHandler')]
    procedure ScanValidUserPageCustomizations()
    var
        User: Record User;
        PersonalizedPages: TestPage "Personalized Pages";
    begin
        Init();

        CreateUser(User);
        AddValidPageCustomization(User);
        CreateUser(User);
        AddValidPageCustomization(User);
        LibraryLowerPermissions.SetO365Full();

        PersonalizedPages.OpenEdit();
        PersonalizedPages.TroubleshootIssues.Invoke();

        PersonalizedPages.First();
        repeat
            Assert.AreEqual(PageSuccessfullyValidatedTxt, PersonalizedPages.Health.Value, 'Page ' + PersonalizedPages.PageCaption.Value + ' is not healthy.');
        until PersonalizedPages.Next() = false;
    end;

    [Test]
    [HandlerFunctions('ScanCompletedWithErrorsMessageHandler')]
    procedure ScanInvalidUserPageCustomizations()
    var
        User: Record User;
        PersonalizedPages: TestPage "Personalized Pages";
    begin
        Init();

        CreateUser(User);
        AddInvalidPageCustomization(User);
        CreateUser(User);
        AddInvalidPageCustomization(User);
        LibraryLowerPermissions.SetO365Full();

        PersonalizedPages.OpenEdit();
        PersonalizedPages.TroubleshootIssues.Invoke();

        PersonalizedPages.First();
        repeat
            Assert.AreEqual(StrSubstNo(PageValidationFailedWithErrorsTxt, 1), PersonalizedPages.Health.Value, 'Page ' + PersonalizedPages.PageCaption.Value + ' does not contain expected error.');
        until PersonalizedPages.Next() = false;
    end;

    local procedure CreateProfile(var AllProfile: Record "All Profile")
    begin
        AllProfile.Scope := AllProfile.Scope::Tenant;
        AllProfile."Profile ID" := LibraryRandom.RandText(MaxStrLen(AllProfile."Profile ID"));
        AllProfile.Description := LibraryRandom.RandText(MaxStrLen(AllProfile.Description));
        AllProfile."Role Center ID" := Page::"Job Project Manager RC";
        AllProfile.Caption := LibraryRandom.RandText(MaxStrLen(AllProfile.Caption));
        AllProfile.Insert();
    end;

    local procedure CreateUser(var User: Record User)
    begin
        Codeunit.Run(Codeunit::"Users - Create Super User");
        LibraryPermissions.CreateAzureActiveDirectoryUser(User, LibraryRandom.RandText(50));
        UsersCreateSuperUser.AddUserAsSuper(User);
    end;

    local procedure AddValidPageCustomization(AllProfile: Record "All Profile")
    var
        TenantProfilePageMetadata: Record "Tenant Profile Page Metadata";
        OutStream: OutStream;
    begin
        TenantProfilePageMetadata."App ID" := AllProfile."App ID";
        TenantProfilePageMetadata."Profile ID" := AllProfile."Profile ID";
        TenantProfilePageMetadata."Page ID" := Page::"Profile Customization List";
        TenantProfilePageMetadata.Owner := TenantProfilePageMetadata.Owner::Tenant;
        TenantProfilePageMetadata."Page AL".CreateOutStream(OutStream);
        WriteValidPageCustomization(OutStream);

        TenantProfilePageMetadata.Insert();
    end;

    local procedure AddInvalidPageCustomization(AllProfile: Record "All Profile")
    var
        TenantProfilePageMetadata: Record "Tenant Profile Page Metadata";
        OutStream: OutStream;
    begin
        TenantProfilePageMetadata."App ID" := AllProfile."App ID";
        TenantProfilePageMetadata."Profile ID" := AllProfile."Profile ID";
        TenantProfilePageMetadata."Page ID" := Page::"Profile Customization List";
        TenantProfilePageMetadata.Owner := TenantProfilePageMetadata.Owner::Tenant;
        TenantProfilePageMetadata."Page AL".CreateOutStream(OutStream);
        WriteInvalidPageCustomization(OutStream);

        TenantProfilePageMetadata.Insert();
    end;

    local procedure AddValidPageCustomization(User: Record User)
    var
        UserPageMetadata: Record "User Page Metadata";
        OutStream: OutStream;
    begin
        UserPageMetadata."User SID" := User."User Security ID";
        UserPageMetadata."Page ID" := Page::"Profile Customization List";
        UserPageMetadata."Page AL".CreateOutStream(OutStream);
        WriteValidPageCustomization(OutStream);

        UserPageMetadata.Insert();
    end;

    local procedure AddInvalidPageCustomization(User: Record User)
    var
        UserPageMetadata: Record "User Page Metadata";
        OutStream: OutStream;
    begin
        UserPageMetadata."User SID" := User."User Security ID";
        UserPageMetadata."Page ID" := Page::"Profile Customization List";
        UserPageMetadata."Page AL".CreateOutStream(OutStream);
        WriteInvalidPageCustomization(OutStream);

        UserPageMetadata.Insert();
    end;

    local procedure WriteValidPageCustomization(var OutStream: OutStream)
    var
        CRLF: Text[2];
    begin
        CRLF[1] := 10;
        CRLF[2] := 13;
        OutStream.WriteText('pagecustomization MS___Configuration10 customizes "Customization Test Page"' + CRLF);
        OutStream.WriteText('{' + CRLF);
        OutStream.WriteText('    layout {' + CRLF);
        OutStream.WriteText('        modify(IntField) {' + CRLF);
        OutStream.WriteText('            Visible = false;' + CRLF);
        OutStream.WriteText('        }' + CRLF);
        OutStream.WriteText('    }' + CRLF);
        OutStream.WriteText('}');
    end;

    local procedure WriteInvalidPageCustomization(var OutStream: OutStream)
    var
        CRLF: Text[2];
    begin
        CRLF[1] := 10;
        CRLF[2] := 13;
        OutStream.WriteText('pagecustomization MS___Configuration10 customizes "Customization Test Page"' + CRLF);
        OutStream.WriteText('{' + CRLF);
        OutStream.WriteText('    layout {' + CRLF);
        OutStream.WriteText('        modify(IntField) {' + CRLF);
        OutStream.WriteText('            NonExistingAttribute = false;' + CRLF);
        OutStream.WriteText('        }' + CRLF);
        OutStream.WriteText('    }' + CRLF);
        OutStream.WriteText('}');
    end;

    [MessageHandler]
    procedure ScanCompletedSuccessfullyMessageHandler(Message: Text)
    begin
        Assert.AreEqual(ScanCompletedSuccessfullyMsg, Message, 'Unexpected message');
    end;

    [MessageHandler]
    procedure ScanCompletedWithErrorsMessageHandler(Message: Text)
    begin
        Assert.AreEqual(StrSubstNo(ScanCompletedWithErrorsMsg, 2), Message, 'Unexpected message');
    end;
}