codeunit 139316 "Company Creation Wizard Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Company Creation Wizard] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        CompanyAlreadyExistsErr: Label 'A company with that name already exists. Try a different name.';
        SpecifyCompanyNameErr: Label 'To continue, you must specify a name for the company.';
        FinExtendedTxt: Label 'Advanced Experience / Cronus Company Sample Data / Setup Data';
        NoDataTxt: Label 'No Sample Data / No Setup Data';
        SetupNotCompletedQst: Label 'The company has not yet been created.\\Are you sure that you want to exit?';
        NoDataExtendedTxt: Label 'Create a company with the desired experience for companies with any process complexity';
        FinExtendedTextTxt: Label 'Create a company with the Advanced functionality scope containing everything you need to evaluate';

    [Test]
    [Scope('OnPrem')]
    procedure CheckCompanySetupStatus()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
    begin
        // [SCENARIO] All new companies do not have to show the setup wizard at the first login
        // [GIVEN] All types of companies
        // [THEN] The flag enabled is set to false
        Assert.AreEqual(false, AssistedCompanySetupStatus.Enabled, 'The flag should be set to false.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [Scope('OnPrem')]
    procedure WizardShowsProductionSetupDataOnlyFirstIfFullSaaSDisabled()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        CompanyCreationWizard: TestPage "Company Creation Wizard";
        NewCompanyData: Enum "Company Data Type (Production)";
    begin
        // [GIVEN] Full SaaS experience is disabled
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] Open Company Creation Wizard on Basic Information tab
        CompanyCreationWizard.OpenEdit();
        CompanyCreationWizard.ActionNext.Invoke(); // Basic Information page

        // [THEN] Company Data is "Production - Setup Data Only"
        Assert.AreEqual(
            CompanyCreationWizard.CompanyData.Value, Format(NewCompanyData::"Production - Setup Data Only"),
            'First option should be Production - Setup Data Only.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [Scope('OnPrem')]
    procedure WizardShowsThreeOptionsIfFullSaaSDisabled()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        CompanyCreationWizard: TestPage "Company Creation Wizard";
        NewCompanyData: Enum "Company Data Type (Production)";
        NewCompanyDataSandbox: Enum "Company Data Type (Sandbox)";
    begin
        // [GIVEN] Full SaaS experience is disabled
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        // [GIVEN] Open Company Creation Wizard on Basic Information tab
        CompanyCreationWizard.OpenEdit();
        CompanyCreationWizard.ActionNext.Invoke(); // Basic Information page
        // [WHEN] Set Company Data as "None"
        NewCompanyData := NewCompanyData::"Create New - No Data";
        CompanyCreationWizard.CompanyData.SetValue(NewCompanyData);
        // [THEN] Company Data is "None"
        Assert.ExpectedMessage(Format(NewCompanyData), CompanyCreationWizard.CompanyData.Value);
        Assert.IsFalse(CompanyCreationWizard.CompanyFullData.Visible(), 'CompanyFullData should be invisible');

        // [WHEN] Set Company Data as "Extended Evaluation Data"
        NewCompanyData := NewCompanyDataSandbox::"Advanced Evaluation - Complete Sample Data";
        asserterror CompanyCreationWizard.CompanyData.SetValue(NewCompanyData);
        // [THEN] Error: there is no such option.
        Assert.ExpectedError('Validation error for Field: CompanyData');
    end;

    [Test]
    [HandlerFunctions('HandleConfirm')]
    [Scope('OnPrem')]
    procedure WizardShowsExtendedDataOptionIfFullSaaSEnabled()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        CompanyCreationWizard: TestPage "Company Creation Wizard";
        NewCompanyData: Enum "Company Data Type (Sandbox)";
    begin
        // [GIVEN] Full SaaS experience is enabled
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        MockSandbox(true);
        // [GIVEN] Open Company Creation Wizard on Basic Information tab
        CompanyCreationWizard.OpenEdit();
        CompanyCreationWizard.ActionNext.Invoke(); // Basic Information page

        // [WHEN] Set Company Data as "Extended Evaluation Data"
        NewCompanyData := NewCompanyData::"Advanced Evaluation - Complete Sample Data";
        CompanyCreationWizard.CompanyFullData.SetValue(NewCompanyData);

        // [THEN] Company Data is "Extended Data", Company Data Description contains 'Full Evaluation Data'
        Assert.IsFalse(CompanyCreationWizard.CompanyData.Visible(), 'CompanyData should be invisible');
        Assert.ExpectedMessage(Format(NewCompanyData), CompanyCreationWizard.CompanyFullData.Value);
        Assert.ExpectedMessage(FinExtendedTxt, CompanyCreationWizard.NewCompanyDataDescription.Value);
        Assert.ExpectedMessage(FinExtendedTextTxt, CompanyCreationWizard.NewCompanyDataDescription.Value);
        MockSandbox(false);
    end;

    [Test]
    [HandlerFunctions('HandleConfirm')]
    [Scope('OnPrem')]
    procedure WizardShowsFourOptionsIfFullSaaSEnabled()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        CompanyCreationWizard: TestPage "Company Creation Wizard";
        NewCompanyData: Enum "Company Data Type (Sandbox)";
    begin
        // [GIVEN] Full SaaS experience is enabled
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        MockSandbox(true);
        // [GIVEN] Open Company Creation Wizard on Basic Information tab
        CompanyCreationWizard.OpenEdit();
        CompanyCreationWizard.ActionNext.Invoke(); // Basic Information page

        // [WHEN] Set Company Data as "No Data"
        NewCompanyData := NewCompanyData::"Create New - No Data";
        CompanyCreationWizard.CompanyFullData.SetValue(NewCompanyData);

        // [THEN] Company Data is "No Data", Company Data Description contains 'No Sample Data.. Create your own company'
        Assert.IsFalse(CompanyCreationWizard.CompanyData.Visible(), 'CompanyData should be invisible');
        Assert.ExpectedMessage(Format(NewCompanyData), CompanyCreationWizard.CompanyFullData.Value);
        Assert.ExpectedMessage(NoDataExtendedTxt, CompanyCreationWizard.NewCompanyDataDescription.Value);
        Assert.ExpectedMessage(NoDataTxt, CompanyCreationWizard.NewCompanyDataDescription.Value);
        MockSandbox(false);

        // [THEN] Setting Company Data as the third option "No Data" is not possible
        NewCompanyData := "Company Data Type (Sandbox)".FromInteger(2); // "No Data";
        asserterror CompanyCreationWizard.CompanyFullData.SetValue(NewCompanyData);
        Assert.ExpectedError('Validation error for Field: CompanyFullData');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyCompanyCreatedWhenWizardCompleted()
    var
        Company: Record Company;
        CompanyCreationWizard: TestPage "Company Creation Wizard";
        NewCompanyName: Text;
    begin
        // [WHEN] The company creation wizard is completed
        NewCompanyName := LibraryUtility.GenerateRandomCode(Company.FieldNo(Name), DATABASE::Company);
        RunWizardToCompletion(CompanyCreationWizard, NewCompanyName);
        CompanyCreationWizard.ActionFinish.Invoke();

        // [THEN] A new company was created
        Assert.IsTrue(Company.Get(NewCompanyName), 'The new company was not created');
        Assert.IsFalse(IsNullGuid(Company.Id), 'An Id was not created for the new company');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WizardStopsWhenCompanyNameNotSpecified()
    var
        CompanyCreationWizard: TestPage "Company Creation Wizard";
    begin
        // [GIVEN] An openend company creation wizard on the Basic information page
        CompanyCreationWizard.Trap();
        PAGE.Run(PAGE::"Company Creation Wizard");
        CompanyCreationWizard.ActionNext.Invoke(); // Basic Information page

        // [WHEN] No company name is entered and next is pressed
        asserterror CompanyCreationWizard.ActionNext.Invoke(); // That's it page

        // [THEN] An error message is thrown, preventing the user from continuing
        Assert.ExpectedError(SpecifyCompanyNameErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WizardStopsWhenAlreadyExistingCompanyNameIsSpecified()
    var
        CompanyCreationWizard: TestPage "Company Creation Wizard";
    begin
        // [GIVEN] An openend company creation wizard on the Basic information page
        CompanyCreationWizard.Trap();
        PAGE.Run(PAGE::"Company Creation Wizard");
        CompanyCreationWizard.ActionNext.Invoke(); // Basic Information page

        // [WHEN] A company name of an already existing company is entered
        asserterror CompanyCreationWizard.CompanyName.SetValue(CompanyName);

        // [THEN] An error message is thrown, preventing the user from continuing
        Assert.ExpectedError(CompanyAlreadyExistsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TrimHeadingTrailingSpacesInNewCompanyName()
    var
        Company: Record Company;
        CompanyCreationWizard: TestPage "Company Creation Wizard";
        NewCompanyName: Text;
    begin
        // [SCENARIO 224319] Company creation wizard trims heading and trailing spaces in new company name
        NewCompanyName := LibraryUtility.GenerateRandomCode(Company.FieldNo(Name), DATABASE::Company);
        RunWizardToCompletion(CompanyCreationWizard, ' ' + NewCompanyName + ' ');
        CompanyCreationWizard.ActionFinish.Invoke();

        Company.Get(NewCompanyName);
        Company.TestField(Id);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WizardsSucceedsAfterDeletingAndCreatingCompanyWithSameName()
    var
        Company: Record Company;
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        CompanyCreationWizard: TestPage "Company Creation Wizard";
        NewCompanyData: Enum "Company Data Type (Internal)";
        NewCompanyName: Text[30];
    begin
        // [WHEN] The company creation wizard is completed
        NewCompanyName := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Company.Name)), 1, MaxStrLen(Company.Name));
        RunWizardToCompletion(CompanyCreationWizard, NewCompanyName);
        CompanyCreationWizard.ActionFinish.Invoke();

        // [WHEN] The company is deleted
        Company.SetRange(Name, NewCompanyName);
        if Company.FindFirst() then
            Company.Delete(true);

        // [WHEN] The company is created again with same name
        AssistedCompanySetup.CreateNewCompany(NewCompanyName);
        AssistedCompanySetup.SetUpNewCompany(NewCompanyName, NewCompanyData::None.AsInteger());

        // [THEN] The company was created with no errors
        Assert.IsTrue(Company.Get(NewCompanyName), 'The new company was not created');
        Assert.IsFalse(IsNullGuid(Company.Id), 'An Id was not created for the new company');
    end;

    local procedure MockSandbox(Enable: Boolean)
    var
        LibraryPermissions: Codeunit "Library - Permissions";
    begin
        LibraryPermissions.SetTestTenantEnvironmentType(Enable);
    end;

    local procedure RunWizardToCompletion(var CompanyCreationWizard: TestPage "Company Creation Wizard"; NewCompanyName: Text)
    var
        NewCompanyData: Option "ENU=Evaluation - Sample Data","Production - Setup Data Only","No Data","Advanced Evaluation - Complete Sample Data","Create New - No Data";
    begin
        CompanyCreationWizard.Trap();
        PAGE.Run(PAGE::"Company Creation Wizard");

        CompanyCreationWizard.ActionNext.Invoke(); // Basic Information page
        CompanyCreationWizard.ActionBack.Invoke(); // Welcome page
        Assert.IsFalse(CompanyCreationWizard.ActionBack.Enabled(), 'Back should not be enabled at the beginning of the wizard');
        CompanyCreationWizard.ActionNext.Invoke(); // Basic Information page
        CompanyCreationWizard.CompanyName.SetValue(NewCompanyName);
        CompanyCreationWizard.CompanyData.SetValue(NewCompanyData::"No Data"); // Set to None to avoid lengthy data import
        CompanyCreationWizard.ActionNext.Invoke(); // Manage Users page
        CompanyCreationWizard.ActionNext.Invoke(); // That's it page
        Assert.IsTrue(CompanyCreationWizard.ActionBack.Enabled(), 'Back should be enabled at the end of the wizard');
        Assert.IsFalse(CompanyCreationWizard.ActionNext.Enabled(), 'Next should not be enabled at the end of the wizard');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HandleConfirm(Message: Text[1024]; var Reply: Boolean)
    begin
        case true of
            StrPos(Message, 'Do you want to save the encryption key?') <> 0:
                Reply := false;
            StrPos(Message, 'Enabling encryption will generate an encryption key') <> 0:
                Reply := true;
            StrPos(Message, 'Disabling encryption will decrypt the encrypted data') <> 0:
                Reply := true;
            StrPos(Message, SetupNotCompletedQst) <> 0:
                Reply := true;
            else
                Reply := false;
        end;
    end;
}

