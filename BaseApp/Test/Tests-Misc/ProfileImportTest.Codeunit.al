codeunit 138697 "Profile Import Test"
{
    Subtype = Test;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        FileManagement: Codeunit "File Management";
        ImportSuccessTxt: Label 'Successfully imported';

    local procedure Init()
    var
        TenantProfile: Record "Tenant Profile";
    begin
        TenantProfile.DeleteAll();
    end;

    [Test]
    procedure ImportOverridingProfiles()
    var
        AllProfile1: Record "All Profile";
        AllProfile2: Record "All Profile";
        ProfileImportTest: codeunit "Profile Import Test";
        ProfileList: TestPage "Profile List";
        ProfileImportWizard: TestPage "Profile Import Wizard";
        ProfileZipFileName: Text;
        ProfileID1: Code[30];
        ProfileID2: Code[30];
    begin
        Init();
        BindSubscription(ProfileImportTest);
        // [GIVEN] Two user created profiles
        CreateProfile(AllProfile1);
        CreateProfile(AllProfile2);

        // [GIVEN] The current profiles have been exported
        ProfileList.OpenView();
        ProfileList.ExportProfiles.Invoke();
        ProfileZipFileName := ProfileImportTest.DequeueText();

        // [GIVEN] The profiles exported have been modified since
        ModifyProfile(AllProfile1);
        ModifyProfile(AllProfile2);

        // [WHEN] User imports the exported profiles
        ProfileImportWizard.OpenEdit();
        ProfileImportTest.Enqueue(ProfileZipFileName);
        ProfileImportWizard.SelectProfilePackageAction.Invoke();
        ProfileImportWizard.ActionImport.Invoke();
        ProfileImportWizard.ActionFinish.Invoke();

        // [THEN] The user created profiles are back to their old values
        VerifyProfileInDatabase(AllProfile1);
        VerifyProfileInDatabase(AllProfile2);

        UnbindSubscription(ProfileImportTest);
    end;

    [Test]
    procedure ImportAddingProfiles()
    var
        Profile1: Record "All Profile";
        Profile2: Record "All Profile";
        ProfileImportTest: codeunit "Profile Import Test";
        ProfileList: TestPage "Profile List";
        ProfileImportWizard: TestPage "Profile Import Wizard";
        ProfileZipFileName: Text;
        ProfileID1: Code[30];
        ProfileID2: Code[30];
    begin
        Init();
        BindSubscription(ProfileImportTest);
        // [GIVEN] Two user created profiles
        CreateProfile(Profile1);
        CreateProfile(Profile2);

        // [GIVEN] The current profiles have been exported
        ProfileList.OpenView();
        ProfileList.ExportProfiles.Invoke();
        ProfileZipFileName := ProfileImportTest.DequeueText();

        // [GIVEN] The profiles exported have been modified since
        Profile1.Delete();
        profile2.Delete();

        // [WHEN] User imports the exported profiles
        ProfileImportWizard.OpenEdit();
        ProfileImportTest.Enqueue(ProfileZipFileName);
        ProfileImportWizard.SelectProfilePackageAction.Invoke();
        ProfileImportWizard.ActionImport.Invoke();
        ProfileImportWizard.ActionFinish.Invoke();

        // [THEN] The user created profiles are back to their old values
        VerifyProfileInDatabase(Profile1);
        VerifyProfileInDatabase(Profile2);

        UnbindSubscription(ProfileImportTest);
    end;
    // TODO: Test import package fail, import package warning, import profile warning
    [Test]
    procedure ImportWizardPageMovement()
    var
        Profile1: Record "All Profile";
        Profile2: Record "All Profile";
        ProfileImport: Record "Profile Import";
        ProfileImportTest: codeunit "Profile Import Test";
        ProfileList: TestPage "Profile List";
        ProfileImportWizard: TestPage "Profile Import Wizard";
        ProfileZipFileName: Text;
    begin
        // [SCENARIO] Move around in the wizard and make sure pages are updated correctly
        Init();
        BindSubscription(ProfileImportTest);
        // [GIVEN] Two user created profiles
        CreateProfileWithPrefix(Profile1, 'a');
        CreateProfileWithPrefix(Profile2, 'b');

        // [GIVEN] The current profiles have been exported
        ProfileList.OpenView();
        ProfileList.ExportProfiles.Invoke();
        ProfileZipFileName := ProfileImportTest.DequeueText();

        // [GIVEN] The profiles exported have been modified since
        Profile1.Delete();
        profile2.Delete();

        // [WHEN] User imports only the first profile
        ProfileImportWizard.OpenEdit();
        ProfileImportTest.Enqueue(ProfileZipFileName);
        ProfileImportWizard.SelectProfilePackageAction.Invoke(); // Triggers OnBeforeUploadFileWithFilter
        ProfileImportWizard.GoToKey(Profile1."App ID", Profile1."Profile ID");
        Assert.AreEqual(Format("Creation Type"::Add), ProfileImportWizard.Action.Value(), 'Profile1 is not being added.');
        ProfileImportWizard.GoToKey(Profile2."App ID", Profile2."Profile ID");
        Assert.AreEqual(Format("Creation Type"::Add), ProfileImportWizard.Action.Value(), 'Profile2 is not being added.');
        ProfileImportWizard.Selected.SetValue(false); // Do not import profile 2
        ProfileImportWizard.ActionImport.Invoke();

        // [THEN] Wizard reports only one profile as being imported
        ProfileImportWizard.ProfileDesignerDiagnosticsListPart.First();
        Assert.AreEqual(Profile1."Profile ID", ProfileImportWizard.ProfileDesignerDiagnosticsListPart."Profile ID".Value(), 'Profile1 is not reported as imported');
        Assert.AreEqual(ImportSuccessTxt, ProfileImportWizard.ProfileDesignerDiagnosticsListPart.Message.Value(), 'Profile1 import message was not successful');
        ProfileImportWizard.ProfileDesignerDiagnosticsListPart.Next();
        Assert.AreEqual(Profile1."Profile ID", ProfileImportWizard.ProfileDesignerDiagnosticsListPart."Profile ID".Value(), 'More profiles than Profile1 was imported'); // Assuming only one profile was imported, then next will just stay on the same record

        // [THEN] Only the first profile is imported
        VerifyProfileInDatabase(Profile1);
        asserterror Profile2.Find();

        // [WHEN] Going back to the profile selection page
        ProfileImportWizard.BackAction.Invoke();

        // [THEN] Only profile1 is still selected but has changed status to replace. profile2 remains deselected
        ProfileImportWizard.GoToKey(Profile1."App ID", Profile1."Profile ID");
        Assert.AreEqual(Format(true), ProfileImportWizard.Selected.Value(), 'Profile1 is not selected.');
        //Assert.AreEqual(Format("Creation Type"::Replace), ProfileImportWizard.Action.Value(), 'Profile1 is not being replaced.');
        ProfileImportWizard.GoToKey(Profile2."App ID", Profile2."Profile ID");
        Assert.AreEqual(Format(false), ProfileImportWizard.Selected.Value(), 'Profile2 is selected.');
        Assert.AreEqual(Format("Creation Type"::Add), ProfileImportWizard.Action.Value(), 'Profile2 is not being added.');

        // [WHEN] Selecting only profile2 for import
        ProfileImportWizard.GoToKey(Profile1."App ID", Profile1."Profile ID");
        ProfileImportWizard.Selected.SetValue(false);
        ProfileImportWizard.GoToKey(Profile2."App ID", Profile2."Profile ID");
        ProfileImportWizard.Selected.SetValue(true);

        // [THEN] Import succeeds without any issues
        ProfileImportWizard.ActionImport.Invoke();

        // [THEN] Wizard reports only one profile as being imported
        ProfileImportWizard.ProfileDesignerDiagnosticsListPart.First();
        Assert.AreEqual(Profile2."Profile ID", ProfileImportWizard.ProfileDesignerDiagnosticsListPart."Profile ID".Value(), 'Profile2 is not reported as imported');
        Assert.AreEqual(ImportSuccessTxt, ProfileImportWizard.ProfileDesignerDiagnosticsListPart.Message.Value(), 'Profile2 import message was not successful');
        ProfileImportWizard.ProfileDesignerDiagnosticsListPart.Next();
        Assert.AreEqual(Profile2."Profile ID", ProfileImportWizard.ProfileDesignerDiagnosticsListPart."Profile ID".Value(), 'More profiles than Profile2 was imported'); // Assuming only one profile was imported, then next will just stay on the same record

        // [THEN] The second profile exist in the database
        VerifyProfileInDatabase(Profile2);

        // [WHEN] Going back to the profile selection page
        ProfileImportWizard.BackAction.Invoke();

        // [THEN] Only profile2 is still selected but has changed status to replace. profile1 remains deselected
        ProfileImportWizard.GoToKey(Profile2."App ID", Profile2."Profile ID");
        Assert.AreEqual(Format(true), ProfileImportWizard.Selected.Value(), 'Profile2 is not selected.');
        //Assert.AreEqual(Format("Creation Type"::Replace), ProfileImportWizard.Action.Value(), 'Profile2 is not being replaced.');
        ProfileImportWizard.GoToKey(Profile1."App ID", Profile1."Profile ID");
        Assert.AreEqual(Format(false), ProfileImportWizard.Selected.Value(), 'Profile1 is selected.');
        //Assert.AreEqual(Format("Creation Type"::Replace), ProfileImportWizard.Action.Value(), 'Profile1 is not being added.');

        // [WHEN] Going back to the profile selection page and re-importing the profile package
        ProfileImportWizard.BackAction.Invoke();
        ProfileImportTest.Enqueue(ProfileZipFileName);
        ProfileImportWizard.SelectProfilePackageAction.Invoke();

        // [THEN] Both profiles are reported as already imported and are both selected
        ProfileImportWizard.GoToKey(Profile1."App ID", Profile1."Profile ID");
        Assert.AreEqual(Format(true), ProfileImportWizard.Selected.Value(), 'Profile1 is not selected.');
        //Assert.AreEqual(Format("Creation Type"::Replace), ProfileImportWizard.Action.Value(), 'Profile1 is not being replaced.');
        ProfileImportWizard.GoToKey(Profile2."App ID", Profile2."Profile ID");
        Assert.AreEqual(Format(true), ProfileImportWizard.Selected.Value(), 'Profile2 not is selected.');
        //Assert.AreEqual(Format("Creation Type"::Replace), ProfileImportWizard.Action.Value(), 'Profile2 is not being replaced.');

        // [WHEN] Importing both profilesImport succeeds without any issues
        ProfileImportWizard.ActionImport.Invoke();

        // [THEN] Wizard reports only one profile as being imported
        ProfileImportWizard.ProfileDesignerDiagnosticsListPart.First();
        Assert.AreEqual(Profile1."Profile ID", ProfileImportWizard.ProfileDesignerDiagnosticsListPart."Profile ID".Value(), 'Profile1 is not reported as imported');
        Assert.AreEqual(ImportSuccessTxt, ProfileImportWizard.ProfileDesignerDiagnosticsListPart.Message.Value(), 'Profile1 import message was not successful');
        ProfileImportWizard.ProfileDesignerDiagnosticsListPart.Next();
        Assert.AreEqual(Profile2."Profile ID", ProfileImportWizard.ProfileDesignerDiagnosticsListPart."Profile ID".Value(), 'Profile2 is not reported as imported');
        Assert.AreEqual(ImportSuccessTxt, ProfileImportWizard.ProfileDesignerDiagnosticsListPart.Message.Value(), 'Profile2 import message was not successful');
        ProfileImportWizard.ProfileDesignerDiagnosticsListPart.Next();
        Assert.AreEqual(Profile2."Profile ID", ProfileImportWizard.ProfileDesignerDiagnosticsListPart."Profile ID".Value(), 'More than 2 profiles were imported');

        ProfileImportWizard.ActionFinish.Invoke();

        UnbindSubscription(ProfileImportTest);
    end;

    procedure DequeueText(): Text
    begin
        exit(LibraryVariableStorage.DequeueText());
    end;

    procedure Enqueue(Variable: Variant)
    begin
        LibraryVariableStorage.Enqueue(Variable);
    end;

    local procedure CreateProfile(var AllProfile: Record "All Profile")
    var
        test: record "Tenant Profile";
    begin
        CreateProfileWithPrefix(AllProfile, '');
    end;

    local procedure CreateProfileWithPrefix(var AllProfile: Record "All Profile"; Prefix: Text)
    var
        test: record "Tenant Profile";
    begin
        CLEAR(AllProfile);
        AllProfile.Scope := AllProfile.Scope::Tenant;
        AllProfile."Profile ID" := Prefix + LibraryRandom.RandText(MaxStrLen(AllProfile."Profile ID") - StrLen(Prefix));
        AllProfile.Description := LibraryRandom.RandText(MaxStrLen(AllProfile.Description));
        AllProfile."Role Center ID" := Page::"Job Project Manager RC";
        AllProfile."Disable Personalization" := true;
        AllProfile.Caption := LibraryRandom.RandText(MaxStrLen(AllProfile.Caption));
        AllProfile.Enabled := false;
        AllProfile.Promoted := true;
        AllProfile.Insert();
    end;

    local procedure ModifyProfile(AllProfile: Record "All Profile")
    begin
        AllProfile.Description := LibraryRandom.RandText(MaxStrLen(AllProfile.Description));
        AllProfile."Role Center ID" := Page::"Bookkeeper Role Center";
        AllProfile."Disable Personalization" := false;
        AllProfile.Caption := LibraryRandom.RandText(MaxStrLen(AllProfile.Caption));
        AllProfile.Enabled := true;
        AllProfile.Promoted := false;
        AllProfile.Modify();
    end;

    local procedure VerifyProfileInDatabase(AllProfile: Record "All Profile")
    var
        DatabaseAllProfile: Record "All Profile";
    begin
        DatabaseAllProfile.Get(AllProfile.Scope, AllProfile."App ID", AllProfile."Profile ID");
        Assert.AreEqual(AllProfile.Description, DatabaseAllProfile.Description, 'Description was not imported correctly.');
        Assert.AreEqual(AllProfile."Role Center ID", DatabaseAllProfile."Role Center ID", '"Role Center ID" was not imported correctly.');
        Assert.AreEqual(AllProfile.Caption, DatabaseAllProfile.Caption, 'Caption was not imported correctly.');
        Assert.AreEqual(AllProfile.Enabled, DatabaseAllProfile.Enabled, 'Enabled was not imported correctly.');
        Assert.AreEqual(AllProfile.Promoted, DatabaseAllProfile.Promoted, 'Promoted was not imported correctly.');
    end;

    // Subscribers

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeDownloadHandler', '', false, false)]
    local procedure SaveFileToDisk(var ToFolder: Text; ToFileName: Text; FromFileName: Text; var IsHandled: Boolean)
    var
        TempFile: File;
        ServerTempFileName: Text;
    begin
        // The download handler deletes the file before we can check the content, so need to copy it for the test to succeed
        ServerTempFileName := FileManagement.ServerTempFileName('zip');
        FileManagement.CopyServerFile(FromFileName, ServerTempFileName, false);

        LibraryVariableStorage.Enqueue(ServerTempFileName);
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeUploadFileWithFilter', '', false, false)]
    local procedure OnBeforeUploadFileWithFilter(var ServerFileName: Text; WindowTitle: Text[50]; ClientFileName: Text; FileFilter: Text; ExtFilter: Text; var IsHandled: Boolean)
    begin
        ServerFileName := LibraryVariableStorage.DequeueText();
        IsHandled := true;
    end;
}