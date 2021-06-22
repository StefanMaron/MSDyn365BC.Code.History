codeunit 136208 "Marketing Interaction"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Interaction] [Marketing]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryWorkflow: Codeunit "Library - Workflow";
        FileMgt: Codeunit "File Management";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        isInitialized: Boolean;
        FieldEmptyErr: Label 'You must fill in the %1 field.';
        UnknownErr: Label 'Unknown error.';
        RollbackErr: Label 'Rollback.';
        DialogTxt: Label 'Dialog';
        CanNotBeSpecifiedErr: Label '%1 = %2 can not be specified for %3 %4.';
        WordAppExist: Boolean;
        WizardAction: Enum "Interaction Template Wizard Action";
        FinishWizardLaterQst: Label 'Do you want to finish this interaction later?';
        SelectContactErr: Label 'You must select a contact to interact with.';
        MergedFieldErr: Label 'Value %1 from merged file are not equal to %2.', Comment = '%1 = Merged value,%2 = Original value';
        AttachmentErr: Label 'Wrong attachment.';
        IsNotFoundOnPageErr: Label 'is not found on the page.';
        FirstContentBodyTxt: Label 'First Content Body Text';
        AttachmentExportQst: Label 'Do you want to export attachment to view or edit it externaly?';
        FilePathsAreNotEqualErr: Label 'Export file path is not equal to file path of the attachment.';

    [Test]
    [Scope('OnPrem')]
    procedure CreationInteractionGroup()
    var
        InteractionGroup: Record "Interaction Group";
    begin
        // Test that it is possible to create a new Interaction Group.

        // 1. Setup:
        Initialize;

        // 2. Exercise: Create Interaction Group.
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);

        // 3. Verify: Check that Interaction Group created.
        InteractionGroup.Get(InteractionGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreationInteractionTemplate()
    var
        InteractionGroup: Record "Interaction Group";
        InteractionTemplate: Record "Interaction Template";
    begin
        // Test that it is possible to create a new Interaction Template.

        // 1. Setup: Create Interaction Group.
        Initialize;
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);

        // 2. Exercise: Create Interaction Template with Interaction Group Code.
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate.Validate("Interaction Group Code", InteractionGroup.Code);
        InteractionTemplate.Modify(true);

        // 3. Verify: Check that Interaction Template created with Interaction Group Code.
        InteractionTemplate.Get(InteractionTemplate.Code);
        InteractionTemplate.TestField("Interaction Group Code", InteractionGroup.Code);
    end;

    [Test]
    [HandlerFunctions('ModalFormInteractionGroupStat')]
    [Scope('OnPrem')]
    procedure OpenInteractionGroupStatistics()
    var
        InteractionGroup: Record "Interaction Group";
        InteractionTemplate: Record "Interaction Template";
        SegmentHeader: Record "Segment Header";
        InteractionGroupStatistics: Page "Interaction Group Statistics";
    begin
        // Test that it is possible to open Interaction Group Statistics with correct values.

        // 1. Setup: Create Interaction Group, Interaction Template. Create a Segment.
        Initialize;
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);

        UpdateInteractionTemplate(InteractionTemplate, InteractionGroup.Code);
        CreateSegment(SegmentHeader, InteractionTemplate.Code);

        // 2. Exercise: Run Log Segment Batch Job for Created Segment.
        RunLogSegment(SegmentHeader."No.");

        // 3. Verify: Check that Interaction Group Statistics opens with correct values.
        LibraryVariableStorage.Enqueue(InteractionTemplate."Unit Cost (LCY)");
        LibraryVariableStorage.Enqueue(InteractionTemplate."Unit Duration (Min.)");
        Clear(InteractionGroupStatistics);
        InteractionGroupStatistics.SetRecord(InteractionGroup);
        InteractionGroupStatistics.RunModal;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RemoveAttachment()
    var
        InteractionTemplate: Record "Interaction Template";
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
    begin
        // Test that it is possible to Remove Attachment from Interaction Template.

        // 1. Setup: Find the Interaction Template with Attachment.
        Initialize;
        InteractionTemplate.SetFilter("Attachment No.", '<>0');  // Check for an Template that has some attachment.
        InteractionTemplate.FindFirst;

        // 2. Exercise: Remove the Attachment.
        InteractionTmplLanguage.Get(InteractionTemplate.Code, InteractionTemplate."Language Code (Default)");
        InteractionTmplLanguage.RemoveAttachment(true);

        // 3. Verify: Check the Attachment has been removed.
        InteractionTemplate.CalcFields("Attachment No.");
        InteractionTemplate.TestField("Attachment No.", 0);  // Checks that there are no attachment.

        // 4. TearDown:
        TransactionRollback;
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerCreateInteract')]
    [Scope('OnPrem')]
    procedure InteractionWithoutTemplate()
    var
        Contact: Record Contact;
        SegmentLine: Record "Segment Line";
        LibraryMarketing: Codeunit "Library - Marketing";
    begin
        // Test that application generates an error on creating Interaction without Interaction Template code in Interaction Wizard.

        // 1. Setup: Create a Contact.
        Initialize;
        LibraryMarketing.CreateCompanyContact(Contact);

        // 2. Exercise: Create Interaction without Interaction Template code in Interaction Wizard.
        asserterror CreateInteractionFromContact(Contact, '');

        // 3. Verify: Check application generates an error on creating Interaction without Interaction Template code in Interaction Wizard.
        Assert.AreEqual(StrSubstNo(FieldEmptyErr, SegmentLine.FieldCaption("Interaction Template Code")), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerCreateInteract')]
    [Scope('OnPrem')]
    procedure InteractionWithoutDescription()
    var
        Contact: Record Contact;
        InteractionTemplate: Record "Interaction Template";
        SegmentLine: Record "Segment Line";
        LibraryMarketing: Codeunit "Library - Marketing";
    begin
        // [SCENARIO] Application generates an error on creating Interaction without Description in "Create Interaction" page.
        Initialize;
        // [GIVEN] Create a Contact.
        LibraryMarketing.CreateCompanyContact(Contact);
        // [GIVEN] Create Interaction Template, where Description is <blank>
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate.Description := '';
        InteractionTemplate.Modify();
        // [GIVEN] Run "Create Interaction" page from Contact

        // [WHEN] Enter "Interaction Template Code" and close the page
        // by ModalFormHandlerCreateInteract
        asserterror CreateInteractionFromContact(Contact, InteractionTemplate.Code);

        // [THEN] The error : "You must fill in the Description"
        Assert.AreEqual(StrSubstNo(FieldEmptyErr, SegmentLine.FieldCaption(Description)), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('CreateInteractPageHandler')]
    [Scope('OnPrem')]
    procedure InteractionForContact()
    var
        Contact: Record Contact;
        InteractionGroup: Record "Interaction Group";
        TemplateCode: Code[10];
    begin
        // Test for successful Contact Interaction.

        // 1. Setup: Create Interaction Group, Create Interaction Template, Create Contact, Save Template Code in Global Variable.
        Initialize;
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);
        TemplateCode := CreateAndUpdateTemplate(InteractionGroup.Code);
        LibraryMarketing.CreateCompanyContact(Contact);

        // 2. Exercise: Create Interaction for Contact.
        CreateInteractionFromContact(Contact, TemplateCode);

        // 3. Verify: Verify that Interaction successfully logged in Interaction Log Entry.
        VerifyInteractionLogEntry(Contact."No.", TemplateCode);
    end;

    [Test]
    [HandlerFunctions('CreateInteractPageHandler')]
    [Scope('OnPrem')]
    procedure InteractionFromLogEntries()
    var
        Contact: Record Contact;
        InteractionGroup: Record "Interaction Group";
        InteractionLogEntry: Record "Interaction Log Entry";
        TemplateCode: array[2] of Code[10];
    begin
        // Test to check that it is possible to create Interaction for a Contact from Interaction Log Entries.

        // 1. Setup: Create Interaction Group, Interaction Templates, Create Contact and Interaction for the Contact.
        Initialize;
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);
        TemplateCode[1] := CreateAndUpdateTemplate(InteractionGroup.Code);
        TemplateCode[2] := CreateAndUpdateTemplate(InteractionGroup.Code);
        LibraryMarketing.CreateCompanyContact(Contact);
        CreateInteractionFromContact(Contact, TemplateCode[1]);

        // 2. Exercise: Create Interaction From Interaction Log Entries.
        FindInteractionLogEntry(InteractionLogEntry, Contact."No.", InteractionGroup.Code, TemplateCode[1]);
        CreateInteractionFromLogEntry(InteractionLogEntry, TemplateCode[2], false, 0, 0);

        // 3. Verify: Verify Interaction Log Entry for the Second Interaction Template.
        VerifyInteractionLogEntry(Contact."No.", TemplateCode[2]);
    end;

    [Test]
    [HandlerFunctions('CreateInteractPageHandler')]
    [Scope('OnPrem')]
    procedure InteractionForNewCostAndAmount()
    var
        Contact: Record Contact;
        InteractionGroup: Record "Interaction Group";
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionTemplate: Record "Interaction Template";
        CostLCY: Decimal;
        DurationMin: Decimal;
    begin
        // Test to check Interaction Details can be successfully updated while creating Interaction for Contact.
        Initialize;

        // 1. Setup: Create Interaction Group, Interaction Template, Create Contact and Interaction for the Contact.
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);
        InteractionTemplate.Get(CreateAndUpdateTemplate(InteractionGroup.Code));
        LibraryMarketing.CreateCompanyContact(Contact);
        CreateInteractionFromContact(Contact, InteractionTemplate.Code);

        // Take Random Cost LCY and Duration greater than Interaction Template's Cost LCY and Duration and store in Global Variable.
        CostLCY := InteractionTemplate."Unit Cost (LCY)" + LibraryRandom.RandInt(10);
        DurationMin := InteractionTemplate."Unit Duration (Min.)" + LibraryRandom.RandInt(10);

        // 2. Exercise: Create Interaction From Interaction Log Entries.
        FindInteractionLogEntry(InteractionLogEntry, Contact."No.", InteractionGroup.Code, InteractionTemplate.Code);
        CreateInteractionFromLogEntry(InteractionLogEntry, InteractionTemplate.Code, true, CostLCY, DurationMin);

        // 3. Verify: Verify that new Cost and Duration updated in Interaction Log Entry.
        InteractionLogEntry.FindLast;
        InteractionLogEntry.TestField("Cost (LCY)", CostLCY);
        InteractionLogEntry.TestField("Duration (Min.)", DurationMin);
    end;

    [Test]
    [HandlerFunctions('CreateInteractPageHandler')]
    [Scope('OnPrem')]
    procedure InteractionTemplateStatistics()
    var
        Contact: Record Contact;
        InteractionGroup: Record "Interaction Group";
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionTemplate: Record "Interaction Template";
        CostLCY: Decimal;
        DurationMin: Decimal;
    begin
        // Test to verify Interaction Template Statistics after creating Interaction.
        Initialize;

        // 1. Setup: Create Interaction Group, Interaction Template, Create Contact and Interaction for the Contact.
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);
        InteractionTemplate.Get(CreateAndUpdateTemplate(InteractionGroup.Code));
        LibraryMarketing.CreateCompanyContact(Contact);
        CreateInteractionFromContact(Contact, InteractionTemplate.Code);

        // Take Random Cost LCY and Duration greater than Interaction Template's Cost LCY and Duration and store in Global Variable.
        DurationMin := InteractionTemplate."Unit Duration (Min.)" + LibraryRandom.RandInt(10);
        CostLCY := InteractionTemplate."Unit Cost (LCY)" + LibraryRandom.RandInt(10);

        // 2. Exercise: Create Interaction From Interaction Log Entries.
        FindInteractionLogEntry(InteractionLogEntry, Contact."No.", InteractionGroup.Code, InteractionTemplate.Code);
        CreateInteractionFromLogEntry(InteractionLogEntry, InteractionTemplate.Code, true, CostLCY, DurationMin);

        // 3. Verify: Verify Values on Interaction Template Statistics Page.
        InteractionTemplate.CalcFields("No. of Interactions", "Cost (LCY)", "Duration (Min.)");
        VerifyTemplateStatistics(InteractionTemplate);
    end;

    [Test]
    [HandlerFunctions('CreateInteractPageHandler')]
    [Scope('OnPrem')]
    procedure InteractionGroupStatistics()
    var
        Contact: Record Contact;
        InteractionGroup: Record "Interaction Group";
        InteractionLogEntry: Record "Interaction Log Entry";
        TemplateCode: array[2] of Code[10];
    begin
        // Test to verify Interaction Group Statistics after creating Interaction.

        // 1. Setup: Create Interaction Group, Interaction Templates, Create Contact and Interaction for the Contact.
        Initialize;
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);
        TemplateCode[1] := CreateAndUpdateTemplate(InteractionGroup.Code);  // Set value in global variable.
        TemplateCode[2] := CreateAndUpdateTemplate(InteractionGroup.Code);
        LibraryMarketing.CreateCompanyContact(Contact);
        CreateInteractionFromContact(Contact, TemplateCode[1]);

        // 2. Exercise: Create Interaction From Interaction Log Entries.
        FindInteractionLogEntry(InteractionLogEntry, Contact."No.", InteractionGroup.Code, TemplateCode[1]);
        CreateInteractionFromLogEntry(InteractionLogEntry, TemplateCode[2], false, 0, 0);

        // 3. Verify: Verify Entries on Interaction Group Statistics Page.
        InteractionGroup.CalcFields("No. of Interactions", "Cost (LCY)", "Duration (Min.)");
        VerifyTemplateGroupStatistics(InteractionGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWizardActionWithoutLangCode()
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [UT] [Interaction Template]
        // [SCENARIO] "Wizard Action" can be validated with any value for an Interaction Template without Interaction Tmpl. Language
        Initialize;
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);

        with InteractionTemplate do
            for WizardAction := WizardAction::" " to WizardAction::Merge do begin
                Validate("Wizard Action", WizardAction);
                Assert.AreEqual(WizardAction, "Wizard Action", FieldCaption("Wizard Action"));
            end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWizardActionWithLangCodeWithoutAttachment()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [UT] [Interaction Template]
        // [SCENARIO] "Wizard Action" can not be validated with "Merge" value for an Interaction Template with Interaction Tmpl. Language without attachment
        Initialize;
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        CreateInteractionTmplLangWithoutAttachment(InteractionTmplLanguage, InteractionTemplate.Code);

        with InteractionTemplate do begin
            Validate("Language Code (Default)", InteractionTmplLanguage."Language Code");
            for WizardAction := WizardAction::" " to WizardAction::Import do begin
                Validate("Wizard Action", WizardAction);
                Assert.AreEqual(WizardAction, "Wizard Action", FieldCaption("Wizard Action"));
            end;

            asserterror Validate("Wizard Action", WizardAction::Merge);
            Assert.ExpectedErrorCode(DialogTxt);
            Assert.ExpectedError(
              StrSubstNo(CanNotBeSpecifiedErr, FieldCaption("Wizard Action"), WizardAction::Merge, TableCaption, Code));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWizardActionWithLangCodeWithWordAttachment()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractionTemplate: Record "Interaction Template";
        SavedWizardAction: Enum "Interaction Template Wizard Action";
    begin
        // [FEATURE] [UT] [Interaction Template]
        // [SCENARIO] "Wizard Action" value can not be validated with "Merge" value for an Interaction Template with Interaction Tmpl. Language with Word attachment
        Initialize;

        InteractionTmplLanguage.SetRange("Attachment No.", FindWordAttachment);
        InteractionTmplLanguage.FindFirst;
        InteractionTemplate.Get(InteractionTmplLanguage."Interaction Template Code");
        SavedWizardAction := InteractionTemplate."Wizard Action";

        with InteractionTemplate do begin
            for WizardAction := WizardAction::" " to WizardAction::Import do begin
                Validate("Wizard Action", WizardAction);
                Assert.AreEqual(WizardAction, "Wizard Action", FieldCaption("Wizard Action"));
            end;

            WizardAction := WizardAction::Merge;
            asserterror Validate("Wizard Action", WizardAction);
            Assert.ExpectedErrorCode(DialogTxt);
            Assert.ExpectedError(
              StrSubstNo(CanNotBeSpecifiedErr, FieldCaption("Wizard Action"), WizardAction, TableCaption, Code));
        end;

        // Tear Down
        InteractionTemplate.Validate("Wizard Action", SavedWizardAction);
        InteractionTemplate.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWizardActionWithLangCodeWithEmailMergeAttachment()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [UT] [Interaction Template]
        // [SCENARIO] "Wizard Action" value can be only "Merge" for an Interaction Template with Interaction Tmpl. Language with Email Merge attachment
        Initialize;
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        CreateInteractionTmplLangWithEmailMergeAttachment(InteractionTmplLanguage, InteractionTemplate.Code, '');
        Commit();

        with InteractionTemplate do begin
            Validate("Language Code (Default)", InteractionTmplLanguage."Language Code");
            Assert.AreEqual(WizardAction::Merge, "Wizard Action", FieldCaption("Wizard Action"));

            for WizardAction := WizardAction::" " to WizardAction::Import do begin
                asserterror Validate("Wizard Action", WizardAction);
                Assert.ExpectedErrorCode(DialogTxt);
                Assert.ExpectedError(
                  StrSubstNo(CanNotBeSpecifiedErr, FieldCaption("Wizard Action"), WizardAction, TableCaption, Code));
            end;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WizardActionIsChangedFromEmptyToMergeAfterValidateEmailMergeAttachment()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractionTemplate: Record "Interaction Template";
        LanguageCode: array[2] of Code[10];
    begin
        // [FEATURE] [UT] [Interaction Template]
        // [SCENARIO] "Wizard Action" value is changed from "" to "Merge" after validate Interaction Tmpl. Language with Email Merge attachment
        Initialize;
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        LanguageCode[1] :=
          CreateInteractionTmplLangWithoutAttachment(InteractionTmplLanguage, InteractionTemplate.Code);
        LanguageCode[2] :=
          CreateInteractionTmplLangWithEmailMergeAttachment(
            InteractionTmplLanguage, InteractionTemplate.Code, StrSubstNo('<>%1', LanguageCode[1]));

        with InteractionTemplate do begin
            Validate("Language Code (Default)", LanguageCode[1]);
            Validate("Language Code (Default)", LanguageCode[2]);
            Assert.AreEqual(WizardAction::Merge, "Wizard Action", FieldCaption("Wizard Action"));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WizardActionIsChangedFromMergeToEmptyAfterValidateLangCodeWithoutAttachment()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractionTemplate: Record "Interaction Template";
        LanguageCode: array[2] of Code[10];
    begin
        // [FEATURE] [UT] [Interaction Template]
        // [SCENARIO] "Wizard Action" value is changed from "Merge" to "" after validate Interaction Tmpl. Language without attachment
        Initialize;
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        LanguageCode[1] :=
          CreateInteractionTmplLangWithoutAttachment(InteractionTmplLanguage, InteractionTemplate.Code);
        LanguageCode[2] :=
          CreateInteractionTmplLangWithEmailMergeAttachment(
            InteractionTmplLanguage, InteractionTemplate.Code, StrSubstNo('<>%1', LanguageCode[1]));

        with InteractionTemplate do begin
            Validate("Language Code (Default)", LanguageCode[2]);
            Validate("Language Code (Default)", LanguageCode[1]);
            Assert.AreEqual(WizardAction::" ", "Wizard Action", FieldCaption("Wizard Action"));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateCustomLayoutFromInterTmplLangPage()
    var
        DummyAttachment: Record Attachment;
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        CustomReportLayout: Record "Custom Report Layout";
        InteractTmplLanguages: TestPage "Interact. Tmpl. Languages";
    begin
        // [FEATURE] [UT] [UI] [Interaction Template] [Email Merge]
        // [SCENARIO] Email Merge attachment is created when validate "Custom Layout No." field on "Interact. Tmpl. Languages" page
        Initialize;
        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage);

        InteractTmplLanguages.OpenView;
        InteractTmplLanguages.GotoRecord(InteractionTmplLanguage);
        CustomReportLayout.Get(LibraryMarketing.FindEmailMergeCustomLayoutNo);
        InteractTmplLanguages.CustLayoutDescription.SetValue(CustomReportLayout.Description);
        InteractTmplLanguages.Close;

        InteractionTmplLanguage.Find;
        DummyAttachment.SetRange("No.", InteractionTmplLanguage."Attachment No.");
        Assert.RecordIsNotEmpty(DummyAttachment);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RevalidateCustomLayoutFromInterTmplLangPage()
    var
        DummyAttachment: Record Attachment;
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        CustomReportLayout: Record "Custom Report Layout";
        InteractTmplLanguages: TestPage "Interact. Tmpl. Languages";
        AttachmentNo: array[2] of Integer;
    begin
        // [FEATURE] [UT] [UI] [Interaction Template] [Email Merge]
        // [SCENARIO] Email Merge attachment is created when validate a new "Custom Layout No." field on "Interact. Tmpl. Languages" page
        Initialize;
        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage);

        InteractTmplLanguages.OpenView;
        InteractTmplLanguages.GotoRecord(InteractionTmplLanguage);

        CustomReportLayout.Get(LibraryMarketing.FindEmailMergeCustomLayoutNo);
        InteractTmplLanguages.CustLayoutDescription.SetValue(CustomReportLayout.Description);
        InteractionTmplLanguage.Find;
        AttachmentNo[1] := InteractionTmplLanguage."Attachment No.";

        CustomReportLayout.Get(LibraryMarketing.FindEmailMergeCustomLayoutNo);
        InteractTmplLanguages.CustLayoutDescription.SetValue(CustomReportLayout.Description);
        InteractionTmplLanguage.Find;
        AttachmentNo[2] := InteractionTmplLanguage."Attachment No.";

        InteractTmplLanguages.Close;

        DummyAttachment.SetRange("No.", AttachmentNo[1]);
        Assert.RecordIsEmpty(DummyAttachment);

        DummyAttachment.SetRange("No.", AttachmentNo[2]);
        Assert.RecordIsNotEmpty(DummyAttachment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroCustomLayoutFromInterTmplLangPage()
    var
        DummyAttachment: Record Attachment;
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        CustomReportLayout: Record "Custom Report Layout";
        InteractTmplLanguages: TestPage "Interact. Tmpl. Languages";
        "Count": Integer;
    begin
        // [FEATURE] [UT] [UI] [Interaction Template] [Email Merge]
        // [SCENARIO] Email Merge attachment is deleted after validate "Custom Layout No." = 0 "Interact. Tmpl. Languages" page
        Initialize;
        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage);
        Count := DummyAttachment.Count();

        InteractTmplLanguages.OpenView;
        InteractTmplLanguages.GotoRecord(InteractionTmplLanguage);
        CustomReportLayout.Get(LibraryMarketing.FindEmailMergeCustomLayoutNo);
        InteractTmplLanguages.CustLayoutDescription.SetValue(CustomReportLayout.Description);
        InteractTmplLanguages.CustLayoutDescription.SetValue('');
        InteractTmplLanguages.Close;

        InteractionTmplLanguage.Find;
        Assert.AreEqual(0, InteractionTmplLanguage."Attachment No.", InteractionTmplLanguage.FieldCaption("Attachment No."));
        Assert.RecordCount(DummyAttachment, Count);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteInteractionTmplWithEmailMergeAttachment()
    var
        DummyAttachment: Record Attachment;
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractionTemplate: Record "Interaction Template";
        "Count": Integer;
        i: Integer;
    begin
        // [FEATURE] [UT] [UI] [Interaction Template] [Email Merge]
        // [SCENARIO] Email Merge attachments are removed when delete Interaction Template with several attachments
        Initialize;
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        Count := DummyAttachment.Count();

        for i := 2 to LibraryRandom.RandIntInRange(2, 5) do
            CreateInteractionTmplLangWithEmailMergeAttachment(InteractionTmplLanguage, InteractionTemplate.Code, '');

        InteractionTemplate.Delete(true);

        Assert.RecordCount(DummyAttachment, Count);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteInteractionLogEntryWithAttachment()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        Attachment: Record Attachment;
    begin
        // [FEATURE] [UT] [Attachment]
        // [SCENARIO] Attachment is removed when delete "Interaction Log Entry" record with attachment
        Initialize;
        LibraryMarketing.CreateAttachment(Attachment);
        MockInterLogEntryWithAttachment(InteractionLogEntry, Attachment."No.");

        InteractionLogEntry.Delete(true);

        Attachment.SetRecFilter;
        Assert.RecordIsEmpty(Attachment);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteTwoCanceledInteractionLogEntriesWithOneAttachment()
    var
        Attachment: Record Attachment;
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        // [FEATURE] [Attachment]
        // [SCENARIO 285790] Attachment is removed when delete all canceled Interaction Log Entries
        // [SCENARIO 285790] with one related attachment
        Initialize;
        InteractionLogEntry.ModifyAll(Canceled, false);

        // [GIVEN] Two canceled Interaction Log Entries with one attachment
        LibraryMarketing.CreateAttachment(Attachment);
        MockCanceledInterLogEntryWithAttachment(Attachment."No.");
        MockCanceledInterLogEntryWithAttachment(Attachment."No.");
        // [WHEN] Delete all canceled Interaction Log Entries
        Commit();
        REPORT.Run(REPORT::"Delete Interaction Log Entries", false);
        // [THEN] Attachment is removed
        Attachment.SetRecFilter;
        Assert.RecordIsEmpty(Attachment);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteOneOfTwoCanceledInteractionLogEntriesWithOneAttachment()
    var
        Attachment: Record Attachment;
        InteractionLogEntry: Record "Interaction Log Entry";
        EntryNo: Integer;
    begin
        // [FEATURE] [Attachment]
        // [SCENARIO 285790] Attachment is not removed when delete one of canceled Interaction Log Entries
        // [SCENARIO 285790] with one related attachment
        Initialize;
        InteractionLogEntry.ModifyAll(Canceled, false);

        // [GIVEN] Two canceled Interaction Log Entries with one attachment
        LibraryMarketing.CreateAttachment(Attachment);
        EntryNo := MockCanceledInterLogEntryWithAttachment(Attachment."No.");
        MockCanceledInterLogEntryWithAttachment(Attachment."No.");
        // [WHEN] Delete first of two canceled Interaction Log Entries
        InteractionLogEntry.SetRange("Entry No.", EntryNo);
        Commit();
        REPORT.Run(REPORT::"Delete Interaction Log Entries", false, false, InteractionLogEntry);
        // [THEN] Attachment is not removed
        Attachment.SetRecFilter;
        Assert.RecordIsNotEmpty(Attachment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLine_IsHTML_Negative_EmptyRecord()
    var
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO] SegmentLine.IsHTMLAttachment() returns FALSE for empty record
        Initialize;
        TempSegmentLine.LoadAttachment(false);
        Assert.IsFalse(TempSegmentLine.IsHTMLAttachment, TempSegmentLine.TableCaption);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLine_IsHTML_Negative_NotHTMLAttachment()
    var
        TempSegmentLine: Record "Segment Line" temporary;
        Attachment: Record Attachment;
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO] SegmentLine.IsHTMLAttachment() returns FALSE for the record with not a HTML attachment
        Initialize;
        LibraryMarketing.CreateAttachment(Attachment);
        TempSegmentLine."Attachment No." := Attachment."No.";

        TempSegmentLine.LoadAttachment(false);

        Assert.IsFalse(TempSegmentLine.IsHTMLAttachment, TempSegmentLine.TableCaption);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLine_IsHTML_Positive()
    var
        Attachment: Record Attachment;
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Segment] [Email Merge]
        // [SCENARIO] SegmentLine.IsHTMLAttachment() returns TRUE for the record with Email Merge attachment
        Initialize;
        LibraryMarketing.CreateEmailMergeAttachment(Attachment);
        TempSegmentLine."Attachment No." := Attachment."No.";

        TempSegmentLine.LoadAttachment(false);

        Assert.IsTrue(TempSegmentLine.IsHTMLAttachment, TempSegmentLine.TableCaption);

        // Tear Down
        Attachment.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ContentPreviewMPH')]
    [Scope('OnPrem')]
    procedure SegmentLine_PreviewHTMLContent()
    var
        Attachment: Record Attachment;
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Segment] [Email Merge]
        // [SCENARIO] SegmentLine.PreviewHTMLContent() opens "Content Preview" page for Email Merge attachment
        Initialize;
        LibraryMarketing.CreateEmailMergeAttachment(Attachment);
        TempSegmentLine."Attachment No." := Attachment."No.";
        TempSegmentLine.LoadAttachment(false);

        TempSegmentLine.PreviewHTMLContent;

        // Verify "Content Preview" page is opened in ContentPreviewMPH handler

        // Tear Down
        Attachment.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLine_LoadContentBodyText()
    var
        Attachment: Record Attachment;
        TempSegmentLine: Record "Segment Line" temporary;
        ContentBodyText: Text;
    begin
        // [FEATURE] [UT] [Segment] [Email Merge]
        // [SCENARIO] SegmentLine.LoadContentBodyTextFromCustomLayoutAttachment() returns content text
        Initialize;
        ContentBodyText := LibraryMarketing.CreateEmailMergeAttachment(Attachment);
        TempSegmentLine."Attachment No." := Attachment."No.";
        TempSegmentLine.LoadAttachment(false);

        Assert.AreEqual(
          ContentBodyText,
          TempSegmentLine.LoadContentBodyTextFromCustomLayoutAttachment,
          TempSegmentLine.FieldCaption("Attachment No."));

        // Tear Down
        Attachment.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLine_UpdateContentBodyText()
    var
        Attachment: Record Attachment;
        TempSegmentLine: Record "Segment Line" temporary;
        NewContentBodyText: Text;
    begin
        // [FEATURE] [UT] [Segment] [Email Merge]
        // [SCENARIO] SegmentLine.UpdateContentBodyTextInCustomLayoutAttachment() updates content text
        Initialize;
        LibraryMarketing.CreateEmailMergeAttachment(Attachment);
        NewContentBodyText := LibraryUtility.GenerateRandomAlphabeticText(LibraryRandom.RandIntInRange(2000, 3000), 0);
        TempSegmentLine."Attachment No." := Attachment."No.";
        TempSegmentLine.LoadAttachment(false);

        TempSegmentLine.UpdateContentBodyTextInCustomLayoutAttachment(NewContentBodyText);

        Assert.AreEqual(
          NewContentBodyText,
          TempSegmentLine.LoadContentBodyTextFromCustomLayoutAttachment,
          TempSegmentLine.FieldCaption("Attachment No."));

        // Tear Down
        Attachment.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AttachmentNotLoadedWhenItAlreadyExists()
    var
        Attachment: array[2] of Record Attachment;
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Segment] [Email Merge]
        // [SCENARIO 220243] When using Attachment loading with optimization new attachment is not loaded if attachment already exists

        // [GIVEN] Create Attachment "A1" and load it to Segment Line "SL"
        Initialize;
        CreateSegmentLineWithAttachment(TempSegmentLine, Attachment[1], FirstContentBodyTxt);

        // [GIVEN] Create Attachment "A2"
        LibraryMarketing.CreateEmailMergeAttachment(Attachment[2]);
        TempSegmentLine."Attachment No." := Attachment[2]."No.";

        // [WHEN] Load attachment to "SL" with optimization (check if attachment already exists).
        TempSegmentLine.LoadAttachment(false);

        // [THEN] Attachment was not loaded ("SL" Attachment = "A1")
        Assert.AreEqual(
          FirstContentBodyTxt,
          TempSegmentLine.LoadContentBodyTextFromCustomLayoutAttachment,
          TempSegmentLine.FieldCaption("Attachment No."));

        // Tear Down
        Attachment[1].Delete(true);
        Attachment[2].Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AttachmentLoadedWhenLoadWithForceAttachment()
    var
        Attachment: array[2] of Record Attachment;
        TempSegmentLine: Record "Segment Line" temporary;
        ContentBodyText: Text;
    begin
        // [FEATURE] [UT] [Segment] [Email Merge]
        // [SCENARIO 220243] When using Attachment loading with reload forcing new attachment is loaded even if attachment already exists

        // [GIVEN] Create Attachment "A1" and load it to Segment Line "SL"
        Initialize;
        CreateSegmentLineWithAttachment(TempSegmentLine, Attachment[1], FirstContentBodyTxt);

        // [GIVEN] Create Attachment "A2"
        ContentBodyText := LibraryMarketing.CreateEmailMergeAttachment(Attachment[2]);
        TempSegmentLine."Attachment No." := Attachment[2]."No.";

        // [WHEN] Load attachment to "SL" with Reload forcing
        TempSegmentLine.LoadAttachment(true);

        // [THEN] Attachment was loaded ("SL" Attachment = "A2")
        Assert.AreEqual(
          ContentBodyText,
          TempSegmentLine.LoadContentBodyTextFromCustomLayoutAttachment,
          TempSegmentLine.FieldCaption("Attachment No."));

        // Tear Down
        Attachment[1].Delete(true);
        Attachment[2].Delete(true);
    end;

    [Test]
    [HandlerFunctions('InteractTmplLanguagesMPH')]
    [Scope('OnPrem')]
    procedure SegmentLine_LanguageCodeOnLookup()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractionTemplate: Record "Interaction Template";
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO] SegmentLine.LanguageCodeOnLookup() opens "Interact. Tmpl. Languages" page
        Initialize;
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        CreateInteractionTmplLangWithEmailMergeAttachment(InteractionTmplLanguage, InteractionTemplate.Code, '');

        MockSegmentLine(TempSegmentLine, InteractionTmplLanguage, '', '', 0D, '');
        TempSegmentLine.LoadAttachment(false);

        LibraryVariableStorage.Enqueue(TempSegmentLine."Interaction Template Code");
        LibraryVariableStorage.Enqueue(TempSegmentLine."Language Code");
        TempSegmentLine.LanguageCodeOnLookup;

        // Verify "Interact. Tmpl. Languages" page is opened in InteractTmplLanguagesMPH handler

        // Tear Down
        InteractionTemplate.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure SegmentLine_FinishWizard_ConfirmNo()
    var
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO] SegmentLine.FinishWizard(FALSE): asks for confirm action
        Initialize;

        TempSegmentLine.FinishWizard(false);

        // Verify finish later confirm question in ConfirmHandlerNo handler
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SegmentLine_FinishWizard_ConfirmYes_InterTmplIsMandatory()
    var
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO] SegmentLine.FinishWizard(FALSE): "Contact No." field is mandatory for empty Segment Line
        Initialize;

        asserterror TempSegmentLine.FinishWizard(false);

        // Verify finish later confirm question in ConfirmHandlerNo handler
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(SelectContactErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLine_FinishWizard_ContactIsMandatory()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO] SegmentLine.FinishWizard(TRUE): "Contact No." field is mandatory
        Initialize;
        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage);

        MockSegmentLine(TempSegmentLine, InteractionTmplLanguage, '', '', 0D, '');

        asserterror TempSegmentLine.FinishWizard(true);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(SelectContactErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLine_FinishWizard_SalesPersonIsMandatory()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO] SegmentLine.FinishWizard(TRUE): "Salesperson Code" field is mandatory
        Initialize;
        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage);

        MockSegmentLine(TempSegmentLine, InteractionTmplLanguage, MockContactNo(''), '', 0D, '');

        asserterror TempSegmentLine.FinishWizard(true);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(FieldEmptyErr, TempSegmentLine.FieldCaption("Salesperson Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLine_FinishWizard_DateIsMandatory()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO] SegmentLine.FinishWizard(TRUE): Date field is mandatory
        Initialize;

        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage);
        MockSegmentLine(TempSegmentLine, InteractionTmplLanguage, MockContactNo(''), MockSalesPersonCode, 0D, '');

        asserterror TempSegmentLine.FinishWizard(true);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(FieldEmptyErr, TempSegmentLine.FieldCaption(Date)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLine_FinishWizard_DescriptionIsMandatory()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        TempSegmentLine: Record "Segment Line" temporary;
        ContactCode: Code[20];
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO] SegmentLine.FinishWizard(TRUE): Description field is mandatory
        Initialize;

        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage);
        ContactCode := MockContactNo('');
        MockSegmentLine(TempSegmentLine, InteractionTmplLanguage, ContactCode, MockSalesPersonCode, WorkDate, '');

        asserterror TempSegmentLine.FinishWizard(true);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(FieldEmptyErr, TempSegmentLine.FieldCaption(Description)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLine_FinishWizard_InteractionLogEntry_NotEmail()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        TempSegmentLine: Record "Segment Line" temporary;
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO] SegmentLine.FinishWizard(TRUE): Interaction Log Entry is created in case of not Email Correspondence Type
        Initialize;
        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage);
        MockSegmentLine(
          TempSegmentLine, InteractionTmplLanguage, MockContactNo(InteractionTmplLanguage."Language Code"),
          MockSalesPersonCode, WorkDate, LibraryUtility.GenerateGUID);

        InteractionLogEntry.FindLast;
        TempSegmentLine.FinishWizard(true);

        VerifyInteractionLogEntryDetails(InteractionLogEntry."Entry No." + 1, TempSegmentLine);
    end;

    [Test]
    [HandlerFunctions('CreateInteraction_VerifyHTMLContentVisibility_MPH,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure CreateInteraction_HTMLContentIsNotVisible_NotEmailMergeTemplate()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Email Merge]
        // [SCENARIO] "Create Interaction" page is opened with not visible HTML content for not Email Merge template
        Initialize;
        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage);
        MockFullSegmentLine(TempSegmentLine, InteractionTmplLanguage);

        LibraryVariableStorage.Enqueue(false);
        CreateInteractionFromContact_EmailMerge(TempSegmentLine);

        // Verify html content visibility in CreateInteraction_VerifyHTMLContentVisibility_MPH handler
    end;

    [Test]
    [HandlerFunctions('CreateInteraction_VerifyHTMLContentVisibility_MPH,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure CreateInteraction_HTMLContentIsVisibleFor_EmailMergeTemplate()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Email Merge]
        // [SCENARIO] "Create Interaction" page is opened with visible HTML content for Email Merge template
        Initialize;
        PrepareInteractionTmplLangCodeWithEmailMergeAttachment(InteractionTmplLanguage);
        MockFullSegmentLine(TempSegmentLine, InteractionTmplLanguage);

        LibraryVariableStorage.Enqueue(true);
        CreateInteractionFromContact_EmailMerge(TempSegmentLine);

        // Verify html content visibility in CreateInteraction_VerifyHTMLContentVisibility_MPH handler
    end;

    [Test]
    [HandlerFunctions('CreateInteraction_ValidateLanguageCode_MPH,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure CreateInteraction_HTMLContentIsNotVisible_NotEmailMergeLangTmpl()
    var
        InteractionTmplLanguage: array[2] of Record "Interaction Tmpl. Language";
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Email Merge]
        // [SCENARIO] "Create Interaction" page: html content is hide when validate Language Code for not Email Merge template
        Initialize;
        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage[1]);
        CreateInteractionTmplLangWithEmailMergeAttachment(
          InteractionTmplLanguage[2], InteractionTmplLanguage[1]."Interaction Template Code",
          StrSubstNo('<>%1', InteractionTmplLanguage[1]."Language Code"));

        MockFullSegmentLine(TempSegmentLine, InteractionTmplLanguage[2]);

        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(InteractionTmplLanguage[1]."Language Code");
        CreateInteractionFromContact_EmailMerge(TempSegmentLine);

        // Verify html content visibility in CreateInteraction_ValidateLanguageCode_MPH handler
    end;

    [Test]
    [HandlerFunctions('CreateInteraction_ValidateLanguageCode_MPH,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure CreateInteraction_HTMLContentIsVisible_EmailMergeLangTmpl()
    var
        InteractionTmplLanguage: array[2] of Record "Interaction Tmpl. Language";
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Email Merge]
        // [SCENARIO] "Create Interaction" page: html content is shown when validate Language Code for Email Merge template
        Initialize;
        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage[1]);
        CreateInteractionTmplLangWithEmailMergeAttachment(
          InteractionTmplLanguage[2], InteractionTmplLanguage[1]."Interaction Template Code",
          StrSubstNo('<>%1', InteractionTmplLanguage[1]."Language Code"));

        MockFullSegmentLine(TempSegmentLine, InteractionTmplLanguage[1]);

        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(InteractionTmplLanguage[2]."Language Code");
        CreateInteractionFromContact_EmailMerge(TempSegmentLine);

        // Verify html content visibility in CreateInteraction_ValidateLanguageCode_MPH handler
    end;

    [Test]
    [HandlerFunctions('CreateInteraction_ValidateHTMLContent_MPH,ContentPreviewMPH,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure CreateInteraction_ValidateAndPreviewHTMLContent()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Email Merge]
        // [SCENARIO] "Create Interaction" page: validate and preview html content
        Initialize;
        PrepareInteractionTmplLangCodeWithEmailMergeAttachment(InteractionTmplLanguage);
        MockFullSegmentLine(TempSegmentLine, InteractionTmplLanguage);

        CreateInteractionFromContact_EmailMerge(TempSegmentLine);

        // Validate and preview html content in CreateInteraction_ValidateHTMLContent_MPH
    end;

    [Test]
    [HandlerFunctions('InteractionSaveMergedDocumentPageHandler')]
    [Scope('OnPrem')]
    procedure InteractionSaveMergedDocumentToDisk()
    var
        Contact: Record Contact;
        InteractionGroup: Record "Interaction Group";
        InteractionTemplate: Record "Interaction Template";
        MarketingSetup: Record "Marketing Setup";
        Attachment: Record Attachment;
        TempServerDirectory: Text;
        MergedFieldValue: Text[250];
        TemplateCode: Code[10];
    begin
        // [SCENARIO 380114] Test that document saved in Storage Path is merged.

        Initialize;

        TempServerDirectory := FileMgt.ServerCreateTempSubDirectory;

        // [GIVEN] Storage Path is Disk File
        UpdateMarketingSetup(MarketingSetup, MarketingSetup."Attachment Storage Type"::"Disk File", TempServerDirectory);

        // [GIVEN] Interaction Group, Create Interaction Template, Create Contact
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);
        TemplateCode := CreateAndUpdateTemplate(InteractionGroup.Code);

        // [GIVEN] MEMO template for Interaction
        CreateInteractionTmplLanguageWithAttachmentNo(TemplateCode, 7); // Memo
        InteractionTemplate.Get(TemplateCode);

        // [GIVEN] Contact with Name = "X"
        LibraryMarketing.CreateCompanyContact(Contact);

        // [WHEN] Create Interaction
        LibraryVariableStorage.Enqueue(TemplateCode);
        Contact.CreateInteraction;

        // [THEN] Verify that 4th control of merged word document contains "X"
        AttachmentFromInteractionLogEntry(Attachment, Contact."No.", InteractionGroup.Code, TemplateCode);
        MergedFieldValue := WordDocumentTakeValue(Attachment, 4); // Contact_Name
        Assert.AreEqual(Contact."No.", MergedFieldValue, StrSubstNo(MergedFieldErr, MergedFieldValue, Contact."No."));

        // Tear Down
        FileMgt.ServerRemoveDirectory(TempServerDirectory, true);
    end;

    [Test]
    [HandlerFunctions('InteractionSaveMergedDocumentPageHandler')]
    [Scope('OnPrem')]
    procedure InteractionSaveMergedDocumentToBLOB()
    var
        Contact: Record Contact;
        InteractionGroup: Record "Interaction Group";
        MarketingSetup: Record "Marketing Setup";
        Attachment: Record Attachment;
        MergedFieldValue: Text[250];
        TemplateCode: Code[10];
    begin
        // [SCENARIO 380114] Test that document saved in BLOB field is merged.

        Initialize;

        // [GIVEN] Storage Path is Embedded
        UpdateMarketingSetup(MarketingSetup, MarketingSetup."Attachment Storage Type"::Embedded, '');

        // [GIVEN] Interaction Group, Create Interaction Template
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);
        TemplateCode := CreateAndUpdateTemplate(InteractionGroup.Code);

        // [GIVEN] MEMO template for Interaction
        CreateInteractionTmplLanguageWithAttachmentNo(TemplateCode, 7); // Memo

        // [GIVEN] Contact with Name = "X"
        LibraryMarketing.CreateCompanyContact(Contact);

        // [WHEN] Create Interaction
        LibraryVariableStorage.Enqueue(TemplateCode);
        Contact.CreateInteraction;

        // [THEN] Verify that 4th control of merged word document contains "X"
        AttachmentFromInteractionLogEntry(Attachment, Contact."No.", InteractionGroup.Code, TemplateCode);
        MergedFieldValue := WordDocumentTakeValue(Attachment, 4); // Contact_Name
        Assert.AreEqual(Contact."No.", MergedFieldValue, StrSubstNo(MergedFieldErr, MergedFieldValue, Contact."No."));
    end;

    [Test]
    [HandlerFunctions('ModalReportHandler,MessageHandler,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure LogSegmentWithEmailWordAttachmentSMTPSetup() // To be removed together with deprecated SMTP objects
    var
        LibraryEmailFeature: Codeunit "Library - Email Feature";
    begin
        LibraryEmailFeature.SetEmailFeatureEnabled(false);
        LogSegmentWithEmailWordAttachmentInternal();
    end;

    // [Test]
    [HandlerFunctions('ModalReportHandler,MessageHandler,EmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure LogSegmentWithEmailWordAttachment()
    var
        LibraryEmailFeature: Codeunit "Library - Email Feature";
    begin
        LibraryEmailFeature.SetEmailFeatureEnabled(true);
        LogSegmentWithEmailWordAttachmentInternal();
    end;

    procedure LogSegmentWithEmailWordAttachmentInternal()
    var
        SegmentHeader: Record "Segment Header";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        EmailFeature: Codeunit "Email Feature";
        Segment: TestPage Segment;
        FileExtension: Text[250];
    begin
        // [SCENARIO 178203] User sends email with Word document as attachment in Web client
        Initialize;
        if EmailFeature.IsEnabled() then
            LibraryWorkflow.SetUpEmailAccount()
        else begin
            LibraryWorkflow.SetUpSMTPEmailSetup;
            UpdateSMTPSetup;
        end;
        // [GIVEN] Interaction Template with Word attachment
        FileExtension := 'DOC';
        // [GIVEN] Segment for email
        PrepareSegmentForEmail(SegmentHeader, FileExtension);
        // [GIVEN] Emulate Web client
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        // [WHEN] Log Segment
        Segment.OpenView;
        Segment.GotoRecord(SegmentHeader);
        Segment.LogSegment.Invoke;
        // [THEN] Email dialog launched (verification in handler)
    end;

    [Test]
    [HandlerFunctions('ModalReportHandler,MessageHandler,EmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure LogSegmentWithEmailTextAttachmentSMTPSetup() // To be removed together with deprecated SMTP objects
    var
        LibraryEmailFeature: Codeunit "Library - Email Feature";
    begin
        LibraryEmailFeature.SetEmailFeatureEnabled(false);
        LogSegmentWithEmailTextAttachmentInternal();
    end;

    // [Test]
    [HandlerFunctions('ModalReportHandler,MessageHandler,EmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure LogSegmentWithEmailTextAttachment()
    var
        LibraryEmailFeature: Codeunit "Library - Email Feature";
    begin
        LibraryEmailFeature.SetEmailFeatureEnabled(true);
        LogSegmentWithEmailTextAttachmentInternal();
    end;

    procedure LogSegmentWithEmailTextAttachmentInternal()
    var
        SegmentHeader: Record "Segment Header";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        LibraryWorkflow: Codeunit "Library - Workflow";
        EmailFeature: Codeunit "Email Feature";
        Segment: TestPage Segment;
        FileExtension: Text[250];
    begin
        // [SCENARIO 178203] User sends email with text document as attachment in Web client
        Initialize;
        if EmailFeature.IsEnabled() then
            LibraryWorkflow.SetUpEmailAccount()
        else begin
            LibraryWorkflow.SetUpSMTPEmailSetup;
            UpdateSMTPSetup;
        end;
        // [GIVEN] Interaction Template with text attachment
        FileExtension := 'TXT';
        // [GIVEN] Segment for email
        PrepareSegmentForEmail(SegmentHeader, FileExtension);
        // [GIVEN] Emulate Web client
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        // [WHEN] Log Segment
        Segment.OpenView;
        Segment.GotoRecord(SegmentHeader);
        Segment.LogSegment.Invoke;
        // [THEN] Email dialog launched (verification in handler)
    end;

    [Test]
    [HandlerFunctions('CreateInteraction_Cancel_MPH,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure InteractionLogEntry_ResumeInteraction_LongFilters()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252197] TAB 5065 "Interaction Log Entry".ResumeInteraction() in case of long field filters
        // [SCENARIO 255837]
        Initialize;

        // [GIVEN] Interaction Log Entry with "Salesperson Code" = "A" (and applied field filter =  "A"), where "A" - 20-char length value
        // [WHEN] Perform "Interaction Log Entry".ResumeInteraction()
        // [THEN] Page 5077 "Create Interaction" is opened with "Salesperson Code" = "A" (and applied field filter =  "A")
        // Cancel "Create Interaction" (CreateInteraction_Cancel_MPH) and decline save (ConfirmHandlerNo)
        MockInterLogEntryWithRandomDetails(InteractionLogEntry);
        with InteractionLogEntry do begin
            SetFilter("To-do No.", "To-do No." + '|' + "To-do No.");
            SetFilter("Contact Company No.", "Contact Company No." + '|' + "Contact Company No.");
            SetFilter("Contact No.", "Contact No." + '|' + "Contact No.");
            SetFilter("Salesperson Code", "Salesperson Code" + '|' + "Salesperson Code");
            SetFilter("Campaign No.", "Campaign No." + '|' + "Campaign No.");
            SetFilter("Opportunity No.", "Opportunity No." + '|' + "Opportunity No.");

            ResumeInteraction;

            Find;
            VerifyFilterValuesAfterResumeInteraction(
              "To-do No.", "Contact Company No.", "Contact No.", "Salesperson Code", "Campaign No.", "Opportunity No.");
        end;

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CreateInteraction_Cancel_MPH,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure InteractionLogEntry_ResumeInteraction_BlankedFilters()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252197] TAB 5065 "Interaction Log Entry".ResumeInteraction() in case of blanked field filters
        // [SCENARIO 255837]
        Initialize;

        // [GIVEN] Interaction Log Entry with "Salesperson Code" = "A" (and no applied field filter)
        // [WHEN] Perform "Interaction Log Entry".ResumeInteraction()
        // [THEN] Page 5077 "Create Interaction" is opened with "Salesperson Code" = "A" (and applied field filter =  "A")
        // Cancel "Create Interaction" (CreateInteraction_Cancel_MPH) and decline save (ConfirmHandlerNo)
        MockInterLogEntryWithRandomDetails(InteractionLogEntry);
        with InteractionLogEntry do begin
            ResumeInteraction;

            Find;
            VerifyFilterValuesAfterResumeInteraction(
              "To-do No.", "Contact Company No.", "Contact No.", "Salesperson Code", "Campaign No.", "Opportunity No.");
        end;

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CreateInteraction_Cancel_MPH,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure InteractionLogEntry_ResumeInteraction_BlankedValues()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252197] TAB 5065 "Interaction Log Entry".ResumeInteraction() in case of blanked field values
        // [SCENARIO 255837]
        Initialize;

        // [GIVEN] Interaction Log Entry with "Salesperson Code" = ""
        // [WHEN] Perform "Interaction Log Entry".ResumeInteraction()
        // [THEN] Page 5077 "Create Interaction" is opened with "Salesperson Code" = "" (and no applied field filter)
        // Cancel "Create Interaction" (CreateInteraction_Cancel_MPH) and decline save (ConfirmHandlerNo)
        with InteractionLogEntry do begin
            Init;
            ResumeInteraction;
            VerifyFilterValuesAfterResumeInteraction('', '', '', '', '', '');
        end;

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CreateInteraction_Cancel_MPH,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure InteractionLogEntry_ResumeInteraction_FiltersOrderAB()
    var
        InteractionLogEntry: array[2] of Record "Interaction Log Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252197] TAB 5065 "Interaction Log Entry".ResumeInteraction() in case of "Salesperson Code" = "A", filter "A|B" and two records
        // [SCENARIO 255837]
        Initialize;

        // [GIVEN] Interaction Log Entry "X" with "Salesperson Code" = "A"
        // [GIVEN] Interaction Log Entry "Y" with "Salesperson Code" = "B"
        // [GIVEN] Select Interaction Log Entry "X", apply "Salesperson Code" filter "A|B"
        // [WHEN] Perform "Interaction Log Entry".ResumeInteraction()
        // [THEN] Page 5077 "Create Interaction" is opened with "Salesperson Code" = "A" (and applied field filter =  "A")
        // Cancel "Create Interaction" (CreateInteraction_Cancel_MPH) and decline save (ConfirmHandlerNo)
        MockInterLogEntryWithGivenSalesPersonCode(InteractionLogEntry[1], LibraryUtility.GenerateGUID);
        MockInterLogEntryWithGivenSalesPersonCode(InteractionLogEntry[2], LibraryUtility.GenerateGUID);
        with InteractionLogEntry[1] do begin
            SetFilter("Salesperson Code", "Salesperson Code" + '|' + InteractionLogEntry[2]."Salesperson Code");

            ResumeInteraction;

            Find;
            VerifyFilterValuesAfterResumeInteraction('', '', '', "Salesperson Code", '', '');
        end;

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('CreateInteraction_Cancel_MPH,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure InteractionLogEntry_ResumeInteraction_FiltersOrderBA()
    var
        InteractionLogEntry: array[2] of Record "Interaction Log Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252197] TAB 5065 "Interaction Log Entry".ResumeInteraction() in case of "Salesperson Code" "B", filter "A|B" and two records
        // [SCENARIO 255837]
        Initialize;

        // [GIVEN] Interaction Log Entry "X" with "Salesperson Code" = "A"
        // [GIVEN] Interaction Log Entry "Y" with "Salesperson Code" = "B"
        // [GIVEN] Select Interaction Log Entry "Y", apply "Salesperson Code" filter "A|B"
        // [WHEN] Perform "Interaction Log Entry".ResumeInteraction()
        // [THEN] Page 5077 "Create Interaction" is opened with "Salesperson Code" = "B" (and applied field filter =  "B")
        // Cancel "Create Interaction" (CreateInteraction_Cancel_MPH) and decline save (ConfirmHandlerNo)
        MockInterLogEntryWithGivenSalesPersonCode(InteractionLogEntry[1], LibraryUtility.GenerateGUID);
        MockInterLogEntryWithGivenSalesPersonCode(InteractionLogEntry[2], LibraryUtility.GenerateGUID);
        with InteractionLogEntry[2] do begin
            SetFilter("Salesperson Code", InteractionLogEntry[1]."Salesperson Code" + '|' + "Salesperson Code");

            ResumeInteraction;

            Find;
            VerifyFilterValuesAfterResumeInteraction('', '', '', "Salesperson Code", '', '');
        end;

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LogDocumentNoEmail()
    var
        SalesHeader: Record "Sales Header";
        InteractionLogEntry: Record "Interaction Log Entry";
        SegManagement: Codeunit SegManagement;
    begin
        // [SCENARIO] Create a sales invoice for a customer that has a contact with correspondence type email but no email address
        Initialize;
        // [GIVEN] Marketing setup with default correspondence type of email
        SetDefaultCorrespondenceType(InteractionLogEntry."Correspondence Type"::Email);
        // [GIVEN] A Sales Invoice to a customer with a contact without email
        CreateSalesInvoiceForCustomerWithContact(SalesHeader);

        // [WHEN] A document creation is logged
        SegManagement.LogDocument(SegManagement.SalesInvoiceInterDocType, SalesHeader."No.", 0, 0, DATABASE::Contact,
          SalesHeader."Bill-to Contact No.", SalesHeader."Salesperson Code", SalesHeader."Campaign No.",
          SalesHeader."Posting Description", '');

        // [THEN] The correspondence is logged with blank correspondence type
        VerifyBlankCorrespondenceTypeOnInteractionLogEntryForContact(SalesHeader."Bill-to Contact No.", SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LogDocumentNoFax()
    var
        SalesHeader: Record "Sales Header";
        InteractionLogEntry: Record "Interaction Log Entry";
        SegManagement: Codeunit SegManagement;
    begin
        // [SCENARIO] Create a sales invoice for a customer that has a contact with correspondence type fax but no fax number
        Initialize;
        // [GIVEN] Marketing setup with default correspondence type of fax
        SetDefaultCorrespondenceType(InteractionLogEntry."Correspondence Type"::Fax);

        // [GIVEN] A Sales Invoice to a customer with a contact without fax
        CreateSalesInvoiceForCustomerWithContact(SalesHeader);

        // [WHEN] A document creation is logged
        SegManagement.LogDocument(SegManagement.SalesInvoiceInterDocType, SalesHeader."No.", 0, 0, DATABASE::Contact,
          SalesHeader."Bill-to Contact No.", SalesHeader."Salesperson Code", SalesHeader."Campaign No.",
          SalesHeader."Posting Description", '');

        // [THEN] The interaction is logged with blank correspondence type
        VerifyBlankCorrespondenceTypeOnInteractionLogEntryForContact(SalesHeader."Bill-to Contact No.", SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderShowInteractionLogEntriesSuiteAppArea()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        InteractionLogEntries: TestPage "Interaction Log Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 199812] Action "Interaction log entries" on sales order page opens list of related interaciton log entries if #Suite app area enabled
        Initialize;
        LibraryApplicationArea.EnableFoundationSetup;

        // [GIVEN] Create sales order XXX
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);

        // [GIVEN] Mock interaction log entry related to created sales order XXX
        MockInterLogEntryRelatedToSalesDocument(SalesHeader);

        // [WHEN] Action "Interaction log entries" is being pushed on sales order card page
        SalesOrder.OpenEdit;
        SalesOrder.GotoRecord(SalesHeader);
        InteractionLogEntries.Trap;
        SalesOrder.PageInteractionLogEntries.Invoke;

        // [THEN] Opened Interaction log entries page contains entry related to order XXX
        VerifyInterLogEntry(
          InteractionLogEntries."Entry No.".AsInteger, SalesHeader."No.", GetInterLogEntryDocTypeFromSalesDoc(SalesHeader));

        // TearDown
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderShowInteractionLogEntriesBasicAppArea()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 199812] Action "Interaction log entries" is not available on sales order page if only #Basic app area enabled
        Initialize;
        LibraryApplicationArea.EnableBasicSetup;

        // [GIVEN] Create sales order XXX
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);

        // [WHEN] Order card page is being opened
        SalesOrder.OpenEdit;
        SalesOrder.GotoRecord(SalesHeader);

        // [THEN] Action "Interaction log entries" is hidden
        asserterror SalesOrder.PageInteractionLogEntries.Invoke;
        Assert.ExpectedError(IsNotFoundOnPageErr);

        // TearDown
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteShowInteractionLogEntriesSuiteAppArea()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
        InteractionLogEntries: TestPage "Interaction Log Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 199812] Action "Interaction log entries" on sales quote page opens list of related interaciton log entries if #Suite app area enabled
        Initialize;
        LibraryApplicationArea.EnableFoundationSetup;

        // [GIVEN] Create sales quote XXX
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo);

        // [GIVEN] Mock interaction log entry related to created sales quote XXX
        MockInterLogEntryRelatedToSalesDocument(SalesHeader);

        // [WHEN] Action "Interaction log entries" is being pushed on sales quote card page
        SalesQuote.OpenEdit;
        SalesQuote.GotoRecord(SalesHeader);
        InteractionLogEntries.Trap;
        SalesQuote.PageInteractionLogEntries.Invoke;

        // [THEN] Opened Interaction log entries page contains entry related to quote XXX
        InteractionLogEntries.First;
        VerifyInterLogEntry(
          InteractionLogEntries."Entry No.".AsInteger, SalesHeader."No.", GetInterLogEntryDocTypeFromSalesDoc(SalesHeader));

        // TearDown
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteShowInteractionLogEntriesBasicAppArea()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 199812] Action "Interaction log entries" is not available on sales quote page if only #Basic app area enabled
        Initialize;
        LibraryApplicationArea.EnableBasicSetup;

        // [GIVEN] Create sales quote XXX
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo);

        // [WHEN] quote card page is being opened
        SalesQuote.OpenEdit;
        SalesQuote.GotoRecord(SalesHeader);

        // [THEN] Action "Interaction log entries" is hidden
        asserterror SalesQuote.PageInteractionLogEntries.Invoke;
        Assert.ExpectedError(IsNotFoundOnPageErr);

        // TearDown
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CommentsFromInteractionLogEntriesPageForSuitUserExperience()
    var
        InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line";
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionLogEntries: TestPage "Interaction Log Entries";
        InterLogEntryCommentSheet: TestPage "Inter. Log Entry Comment Sheet";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 199903] User is able to add comments for interaction log entry when user experience is Suite
        Initialize;

        // [GIVEN] User experience set to Suite
        LibraryApplicationArea.EnableRelationshipMgtSetup;

        // [GIVEN] Mock interaction log entry XXX
        MockInterLogEntry(InteractionLogEntry);

        // [GIVEN] Create comment YYY for interaction log entry XXX
        CreateInteractionLogEntryComment(InterLogEntryCommentLine, InteractionLogEntry."Entry No.");

        // [GIVEN] Open page Interaction Log Entries with entry XXX
        InteractionLogEntries.OpenView;
        InteractionLogEntries.GotoRecord(InteractionLogEntry);

        // [WHEN] Action Comments is being hit
        InterLogEntryCommentSheet.Trap;
        InteractionLogEntries."Co&mments".Invoke;

        // [THEN] Comment YYY is displayed in the opened Inter. Log Entry Comment Sheet
        InterLogEntryCommentSheet.Date.AssertEquals(InterLogEntryCommentLine.Date);
        InterLogEntryCommentSheet.Comment.AssertEquals(InterLogEntryCommentLine.Comment);

        // TearDown
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IntLogCommentCopiedToCreatedOpportunity()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line";
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
    begin
        // [SCENARIO 202036] Creating opportunity from interaction log copies comments to opportunity
        Initialize;

        // [GIVEN] Mock interaction log entry XXX
        MockInterLogEntry(InteractionLogEntry);

        // [GIVEN] Create comment YYY for interaction log entry XXX
        CreateInteractionLogEntryComment(InterLogEntryCommentLine, InteractionLogEntry."Entry No.");

        // [WHEN] Opportunity is being created from interaction log entry
        InteractionLogEntry.AssignNewOpportunity;

        // [THEN] Comment YYY is copied to opportunity's comment
        FindOpportunityCommentLine(InteractionLogEntry."Opportunity No.", RlshpMgtCommentLine);
        VerifyOpporunityCommentLine(InterLogEntryCommentLine, RlshpMgtCommentLine);
    end;

    [Test]
    [HandlerFunctions('MakePhoneCall_MPH,InterLogEntryCommentSheet_MPH,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CommentsForMakePhoneCallPage()
    var
        Contact: Record Contact;
        InteractionLogEntry: Record "Interaction Log Entry";
        InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line";
        ContactList: TestPage "Contact List";
        CommentDate: Date;
        CommentText: Text;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 202034] Comments entered from Make Phone Call page saved into interaction log entries comments
        Initialize;

        // [GIVEN] User experience set to Suite
        LibraryApplicationArea.EnableRelationshipMgtSetup;

        // [GIVEN] Create contact XXX wiht phone number
        CreateContactWithPhoneNo(Contact);

        // [GIVEN] Open contact card with contact XXX
        ContactList.OpenView;
        ContactList.GotoRecord(Contact);

        // [GIVEN] Run Make Phone Call action
        // [GIVEN] Run Comments action
        // [WHEN] Comment YYY is being entered, comments page is being closed, and Phone call completed
        CommentDate := LibraryUtility.GenerateRandomDate(WorkDate, CalcDate('<1Y>', WorkDate));
        CommentText :=
          LibraryUtility.GenerateRandomCode(
            InterLogEntryCommentLine.FieldNo(Comment),
            DATABASE::"Inter. Log Entry Comment Line");
        LibraryVariableStorage.Enqueue(CommentDate);
        LibraryVariableStorage.Enqueue(CommentText);
        ContactList.MakePhoneCall.Invoke;

        // [THEN] Comment YYY saved into interacton log entry comments
        FindContactInteractionLogEntry(InteractionLogEntry, Contact."No.");
        FindIntLogEntryCommentLine(InteractionLogEntry."Entry No.", InterLogEntryCommentLine);
        InterLogEntryCommentLine.TestField(Date, CommentDate);
        InterLogEntryCommentLine.TestField(Comment, CommentText);

        // TearDown
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [HandlerFunctions('SimpleEmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure EmailDraftInteractionLogEntryFromSalesOrderSMTPSetup() // To be removed together with deprecated SMTP objects
    var
        LibraryEmailFeature: Codeunit "Library - Email Feature";
    begin
        LibraryEmailFeature.SetEmailFeatureEnabled(false);
        EmailDraftInteractionLogEntryFromSalesOrderInternal();
    end;

    // [Test]
    [HandlerFunctions('SimpleEmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure EmailDraftInteractionLogEntryFromSalesOrder()
    var
        LibraryEmailFeature: Codeunit "Library - Email Feature";
    begin
        LibraryEmailFeature.SetEmailFeatureEnabled(true);
        EmailDraftInteractionLogEntryFromSalesOrderInternal();
    end;

    procedure EmailDraftInteractionLogEntryFromSalesOrderInternal()
    var
        InteractionTemplate: Record "Interaction Template";
        SalesHeader: Record "Sales Header";
        InteractionLogEntry: Record "Interaction Log Entry";
        DocumentPrint: Codeunit "Document-Print";
        LibraryWorkflow: Codeunit "Library - Workflow";
        EmailFeature: Codeunit "Email Feature";
    begin
        // [SCENARIO 199993] Sending by mail sales order confirmation does not lead to generation of interaction log entry with Email Draft template
        Initialize;
        if EmailFeature.IsEnabled() then
            LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] New interaction template XXX
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        // [GIVEN] Set template XXX as Email Draft in the Intraction Template Setup
        SetEmailDraftInteractionTemplate(InteractionTemplate.Code);
        // [GIVEN] New Sales order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);

        // [WHEN] Sales order confirmation is being sent by email
        DocumentPrint.EmailSalesHeader(SalesHeader);

        // [THEN] Interaction log entry created created once
        FindInteractionLogEntryByDocument(
          InteractionLogEntry, SalesHeader."No.", InteractionLogEntry."Document Type"::"Sales Ord. Cnfrmn.");
        Assert.RecordCount(InteractionLogEntry, 1);
        // [THEN] Interaction log entry "Interaction Template Code" is not equal to "XXX"
        Assert.AreNotEqual(InteractionTemplate.Code, InteractionLogEntry."Interaction Template Code", '')
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsModalPageHandler,SimpleEmailDialogModalPageHandler')]
    [Scope('OnPrem')]
    procedure EmailDraftInteractionLogEntryFromPurchOrderSMTPSetup() // To be removed together with deprecated SMTP objects
    var
        LibraryEmailFeature: Codeunit "Library - Email Feature";
    begin
        LibraryEmailFeature.SetEmailFeatureEnabled(false);
        EmailDraftInteractionLogEntryFromPurchOrderInternal();
    end;

    // [Test]
    [HandlerFunctions('SelectSendingOptionsModalPageHandler,SimpleEmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure EmailDraftInteractionLogEntryFromPurchOrder()
    var
        LibraryEmailFeature: Codeunit "Library - Email Feature";
    begin
        LibraryEmailFeature.SetEmailFeatureEnabled(true);
        EmailDraftInteractionLogEntryFromPurchOrderInternal();
    end;

    procedure EmailDraftInteractionLogEntryFromPurchOrderInternal()
    var
        InteractionTemplate: Record "Interaction Template";
        PurchaseHeader: Record "Purchase Header";
        InteractionLogEntry: Record "Interaction Log Entry";
        LibraryWorkflow: Codeunit "Library - Workflow";
        EmailFeature: Codeunit "Email Feature";
    begin
        // [SCENARIO 199993] Sending by mail Purchase order does not lead to generation of interaction log entry with Email Draft template
        Initialize;
        if EmailFeature.IsEnabled() then
            LibraryWorkflow.SetUpEmailAccount();

        // [GIVEN] New interaction template XXX
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        // [GIVEN] Set template XXX as Email Draft in the Intraction Template Setup
        SetEmailDraftInteractionTemplate(InteractionTemplate.Code);
        // [GIVEN] New Purchase order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo);

        // [WHEN] Purchase order confirmation is being sent by email
        PurchaseHeader.SetRecFilter;
        PurchaseHeader.SendRecords;

        // [THEN] Interaction log entry created once
        FindInteractionLogEntryByDocument(
          InteractionLogEntry, PurchaseHeader."No.", InteractionLogEntry."Document Type"::"Purch. Ord.");
        Assert.RecordCount(InteractionLogEntry, 1);
        // [THEN] Interaction log entry "Interaction Template Code" is not equal to "XXX"
        Assert.AreNotEqual(InteractionTemplate.Code, InteractionLogEntry."Interaction Template Code", '')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmailDraftEnabledForSuitUserExperience()
    var
        InteractionTemplate: Record "Interaction Template";
        InteractionTemplateSetupPage: TestPage "Interaction Template Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 199993] Email Draft Template field enabled on the page Interaction Template Setup with Suit user experience
        Initialize;

        // [GIVEN] User experience set to Suite
        LibraryApplicationArea.EnableRelationshipMgtSetup;

        // [GIVEN] New interaction template XXX
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        // [GIVEN] Set template XXX as Email Draft in the Intraction Template Setup
        SetEmailDraftInteractionTemplate(InteractionTemplate.Code);

        // [WHEN] Interaction Template Setup is being opened
        InteractionTemplateSetupPage.OpenEdit;

        // [THEN] Field Email Draft has value XXX
        InteractionTemplateSetupPage."E-Mail Draft".AssertEquals(InteractionTemplate.Code);

        // TearDown
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [HandlerFunctions('InteractionSaveMergedDocumentPageHandler,ConfirmHandlerExportAttachment')]
    [Scope('OnPrem')]
    procedure InteractionAttachmentWithoutWordApp()
    var
        Contact: Record Contact;
        InteractionGroup: Record "Interaction Group";
        MarketingInteraction: Codeunit "Marketing Interaction";
        TemplateCode: Code[10];
    begin
        // [FEATURE] [UI] [Word Application]
        // [SCENARIO 230955] Create Interaction with Word attachment when no Word application installed
        Initialize;

        // [GIVEN] Word application is not installed
        MarketingInteraction.SetWordAppExists(false);

        // [GIVEN] Interaction Template "X"
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);
        TemplateCode := CreateAndUpdateTemplate(InteractionGroup.Code);
        CreateInteractionTmplLanguageWithAttachmentNo(TemplateCode, 7);

        // [GIVEN] Contact with Name = "C"
        LibraryMarketing.CreateCompanyContact(Contact);

        // [WHEN] Create Interaction using Template "X" for Contact "C"
        BindSubscription(MarketingInteraction);
        CreateInteractionFromContact(Contact, TemplateCode);
        UnbindSubscription(MarketingInteraction);

        // [THEN] Confirmation Dialog asking to save file for later processing appears
        LibraryVariableStorage.DequeueText; // Dequeue not needed boolean variable
        Assert.ExpectedMessage(AttachmentExportQst, LibraryVariableStorage.DequeueText);
    end;

    [Test]
    [HandlerFunctions('InteractionSaveMergedDocumentPageHandler')]
    [Scope('OnPrem')]
    procedure InteractionAttachmentWithWordApp()
    var
        Contact: Record Contact;
        InteractionGroup: Record "Interaction Group";
        InteractionLogEntry: Record "Interaction Log Entry";
        MarketingInteraction: Codeunit "Marketing Interaction";
        TemplateCode: Code[10];
    begin
        // [FEATURE] [UI] [Word Application]
        // [SCENARIO 230955] Create Interaction with Word attachment when Word application installed
        Initialize;

        // [GIVEN] Word application is installed
        MarketingInteraction.SetWordAppExists(true);

        // [GIVEN] Interaction Template "X"
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);
        TemplateCode := CreateAndUpdateTemplate(InteractionGroup.Code);
        CreateInteractionTmplLanguageWithAttachmentNo(TemplateCode, 7);

        // [GIVEN] Contact with Name = "C"
        LibraryMarketing.CreateCompanyContact(Contact);

        // [WHEN] Create Interaction using Template "X" for Contact "C"
        BindSubscription(MarketingInteraction);
        CreateInteractionFromContact(Contact, TemplateCode);
        UnbindSubscription(MarketingInteraction);

        // [THEN] Interaction Log Entry created with Attachment
        FindInteractionLogEntry(InteractionLogEntry, Contact."No.", InteractionGroup.Code, TemplateCode);
        Assert.AreNotEqual(0, InteractionLogEntry."Attachment No.", AttachmentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_PopulateInterLogEntryToMergeSource()
    var
        Attachment: Record Attachment;
    begin
        // [FEATURE] [Merge Source]
        // [SCENARIO 278291] PopulateInterLogEntryToMergeSource HTML merge file generation for specific Interaction Log Entry
        Initialize;

        // [GIVEN] Attachment Record
        LibraryMarketing.CreateAttachment(Attachment);

        // [GIVEN] Attachment has "Merge Source" blob field with data for Interaction Log Entries 139, 140
        MockAttachmentMergeSource(Attachment);

        // [WHEN] WordManagement.PopulateInterLogEntryToMergeSource is run for record 140
        // [THEN] HTML Merge file generated only for record 140 and contains '<td>HundredForty</td>' value and closing '</tr> tag
        VerifyILEHTMLMergeFile(Attachment, 140, '<td>HundredForty</td>', '<td>HundredThirtyNine</td>');

        // [WHEN] WordManagement.PopulateInterLogEntryToMergeSource is run for record 139
        // [THEN] HTML Merge file generated only for record 139 and contains '<td>HundredThirtyNine</td>' value and closing '</tr> tag
        VerifyILEHTMLMergeFile(Attachment, 139, '<td>HundredThirtyNine</td>', '<td>HundredForty</td>');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportInteractionTemplates()
    var
        MarketingSetup: Record "Marketing Setup";
        InteractionGroup: Record "Interaction Group";
        InteractionTemplate: Record "Interaction Template";
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        NameValueBuffer: Record "Name/Value Buffer";
        MarketingInteraction: Codeunit "Marketing Interaction";
        FilePath: Text;
        ExportFilePath: Text;
    begin
        // [SCENARIO 323680] Attachment file path is valid when export Interaction Template.
        Initialize;

        // [GIVEN] Marketing Setup stores attachements on disk.
        MarketingSetup.Validate("Attachment Storage Type", MarketingSetup."Attachment Storage Type"::"Disk File");
        MarketingSetup.Validate("Attachment Storage Location", DelChr(TemporaryPath, '>', '\'));
        MarketingSetup.Modify(true);

        // [GIVEN] Interaction Template with *.docx file attachment.
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate.Validate("Interaction Group Code", InteractionGroup.Code);
        InteractionTemplate.Validate("Wizard Action", InteractionTemplate."Wizard Action"::Open);
        InteractionTemplate.Modify(true);
        CreateInteractionTmplLanguage(InteractionTmplLanguage, InteractionTemplate.Code, FindLanguageCode(''), '');
        InteractionTmplLanguage.Validate("Attachment No.", CreateAttachmentWithFileValue('docx'));
        InteractionTmplLanguage.Modify();
        FilePath := GetAttachmentFilePath(InteractionTmplLanguage."Attachment No.");

        // [WHEN] Invoke export attachment from Interaction Tmpl. Language.
        BindSubscription(MarketingInteraction);
        InteractionTmplLanguage.ExportAttachment;
        NameValueBuffer.Get(SessionId);
        ExportFilePath := NameValueBuffer.Value;
        UnbindSubscription(MarketingInteraction);

        // [THEN] The path of exported file is equal to path stored in attachment of Interaction Tmpl. Language.
        Assert.AreEqual(FilePath, ExportFilePath, FilePathsAreNotEqualErr);
    end;

    local procedure Initialize()
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Marketing Interaction");
        BindActiveDirectoryMockEvents;
        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Marketing Interaction");

        LibrarySales.SetCreditWarningsToNoWarnings;
        LibrarySales.SetStockoutWarning(false);

        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Marketing Setup");
        LibrarySetupStorage.Save(DATABASE::"Interaction Template Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Marketing Interaction");
    end;

    local procedure AttachmentFromInteractionLogEntry(var Attachment: Record Attachment; ContactNo: Code[20]; InteractionGroupCode: Code[10]; InteractionTemplateCode: Code[10])
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionLogEntry.Reset();
        InteractionLogEntry.SetRange("Contact No.", ContactNo);
        InteractionLogEntry.SetRange("Interaction Group Code", InteractionGroupCode);
        InteractionLogEntry.SetRange("Interaction Template Code", InteractionTemplateCode);
        InteractionLogEntry.FindFirst;
        Attachment.Get(InteractionLogEntry."Attachment No.");
    end;

    local procedure CreateAttachmentWithFileValue(FileExtension: Text[250]): Integer
    var
        Attachment: Record Attachment;
        OStream: OutStream;
    begin
        LibraryMarketing.CreateAttachment(Attachment);
        Attachment.Validate("File Extension", FileExtension);
        Attachment."Attachment File".CreateOutStream(OStream);
        OStream.WriteText(LibraryUtility.GenerateRandomText(10));
        Attachment.Modify();
        exit(Attachment."No.");
    end;

    local procedure CreateAndUpdateTemplate(InteractionGroupCode: Code[10]): Code[10]
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        UpdateInteractionTemplate(InteractionTemplate, InteractionGroupCode);
        exit(InteractionTemplate.Code);
    end;

    local procedure CreateContactWithEmail(var Contact: Record Contact)
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("E-Mail", 'someone@example.com');
        Contact.Modify(true);
    end;

    local procedure CreateContactWithPhoneNo(var Contact: Record Contact)
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("Phone No.", '1234567890');
        Contact.Modify(true);
    end;

    local procedure CreateInteractionFromContact(Contact: Record Contact; TemplateCode: Code[10])
    begin
        LibraryVariableStorage.Enqueue(TemplateCode);
        LibraryVariableStorage.Enqueue(false);
        Contact.CreateInteraction;
    end;

    local procedure CreateInteractionFromContact_EmailMerge(SegmentLine: Record "Segment Line")
    var
        Contact: Record Contact;
    begin
        LibraryVariableStorage.Enqueue(SegmentLine."Interaction Template Code");
        Contact.Get(SegmentLine."Contact No.");
        Contact.CreateInteraction;
    end;

    local procedure CreateInteractionFromLogEntry(var InteractionLogEntry: Record "Interaction Log Entry"; TemplateCode: Code[10]; AdditionalValuesinPageHandler: Boolean; CostLCY: Decimal; DurationMin: Decimal)
    begin
        LibraryVariableStorage.Enqueue(TemplateCode);
        LibraryVariableStorage.Enqueue(AdditionalValuesinPageHandler);
        LibraryVariableStorage.Enqueue(CostLCY);
        LibraryVariableStorage.Enqueue(DurationMin);
        InteractionLogEntry.CreateInteraction;
    end;

    local procedure CreateInteractionTmplLangWithoutAttachment(var InteractionTmplLanguage: Record "Interaction Tmpl. Language"; InteractionTemplateCode: Code[10]): Code[10]
    begin
        exit(
          CreateInteractionTmplLanguage(
            InteractionTmplLanguage, InteractionTemplateCode, FindLanguageCode(''), ''));
    end;

    local procedure CreateInteractionTmplLangWithEmailMergeAttachment(var InteractionTmplLanguage: Record "Interaction Tmpl. Language"; InteractionTemplateCode: Code[10]; LanguageFilter: Text): Code[10]
    var
        LanguageCode: Code[10];
    begin
        LanguageCode := CreateInteractionTmplLanguage(
            InteractionTmplLanguage, InteractionTemplateCode, FindLanguageCode(LanguageFilter),
            LibraryMarketing.FindEmailMergeCustomLayoutNo);
        InteractionTmplLanguage.CreateAttachment;
        exit(LanguageCode);
    end;

    local procedure CreateInteractionTmplLanguage(var InteractionTmplLanguage: Record "Interaction Tmpl. Language"; InteractionTemplateCode: Code[10]; LanguageCode: Code[10]; CustomLayoutCode: Code[20]): Code[10]
    begin
        with InteractionTmplLanguage do begin
            Init;
            Validate("Interaction Template Code", InteractionTemplateCode);
            Validate("Language Code", LanguageCode);
            Validate("Custom Layout Code", CustomLayoutCode);
            Insert(true);
            exit("Language Code");
        end;
    end;

    local procedure CreateInteractionTmplLanguageWithAttachmentNo(TemplateCode: Code[10]; AttachmentNo: Integer)
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
    begin
        InteractionTmplLanguage.Init();
        InteractionTmplLanguage."Interaction Template Code" := TemplateCode;
        InteractionTmplLanguage."Language Code" := '';
        InteractionTmplLanguage."Attachment No." := AttachmentNo;
        InteractionTmplLanguage.Insert();
    end;

    local procedure CreateInteractionTemplateWithCorrespondenceType(var InteractionTemplate: Record "Interaction Template"; CorrespondenceType: Enum "Correspondence Type")
    begin
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate."Correspondence Type (Default)" := CorrespondenceType;
        InteractionTemplate.Modify(true);
    end;

    local procedure CreateInteractionLogEntryComment(var InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line"; EntryNo: Integer)
    begin
        with InterLogEntryCommentLine do begin
            Init;
            "Entry No." := EntryNo;
            "Line No." := 10000;
            Date := WorkDate;
            Comment := LibraryUtility.GenerateRandomCode(FieldNo(Comment), DATABASE::"Inter. Log Entry Comment Line");
            Insert(true);
        end;
    end;

    local procedure CreateSegment(var SegmentHeader: Record "Segment Header"; InteractionTemplateCode: Code[10])
    var
        SegmentLine: Record "Segment Line";
        Contact: Record Contact;
    begin
        // Create Segment Header with Interaction Template and Segment Line with Contact No.
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        SegmentHeader.Validate("Interaction Template Code", InteractionTemplateCode);
        SegmentHeader.Modify(true);

        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeader."No.");
        Contact.SetFilter("Salesperson Code", '<>''''');
        Contact.FindFirst;
        SegmentLine.Validate("Contact No.", Contact."No.");
        SegmentLine.Modify(true);
    end;

    local procedure CreateSegmentWithInteractionTemplateAndContact(var SegmentHeader: Record "Segment Header"; InteractionTemplateCode: Code[10]; ContactNo: Code[20]; CorrespondenceType: Enum "Correspondence Type")
    var
        SegmentLine: Record "Segment Line";
    begin
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        SegmentHeader.Validate("Interaction Template Code", InteractionTemplateCode);
        SegmentHeader.Validate("Correspondence Type (Default)", CorrespondenceType);
        SegmentHeader.Validate("Subject (Default)", LibraryUtility.GenerateRandomText(MaxStrLen(SegmentHeader."Subject (Default)")));
        SegmentHeader.Modify(true);
        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeader."No.");
        SegmentLine.Validate("Contact No.", ContactNo);
        SegmentLine.Modify(true);
    end;

    local procedure CreateSegmentLineWithAttachment(var TempSegmentLine: Record "Segment Line" temporary; var Attachment: Record Attachment; ContentBodyText: Text)
    begin
        LibraryMarketing.CreateEmailMergeAttachment(Attachment);
        TempSegmentLine."Attachment No." := Attachment."No.";
        TempSegmentLine.LoadAttachment(false);
        TempSegmentLine.UpdateContentBodyTextInCustomLayoutAttachment(ContentBodyText);
    end;

    local procedure CreateSalutation(LanguageCode: Code[10]): Code[10]
    var
        Salutation: Record Salutation;
    begin
        LibraryMarketing.CreateSalutation(Salutation);
        CreateSalutationFormula(Salutation.Code, LanguageCode, "Salutation Formula Salutation Type"::Formal);
        CreateSalutationFormula(Salutation.Code, LanguageCode, "Salutation Formula Salutation Type"::Informal);
        exit(Salutation.Code);
    end;

    local procedure CreateSalutationFormula(SalutationCode: Code[10]; LanguageCode: Code[10]; SalutationType: Enum "Salutation Formula Salutation Type")
    var
        SalutationFormula: Record "Salutation Formula";
    begin
        LibraryMarketing.CreateSalutationFormula(SalutationFormula, SalutationCode, LanguageCode, SalutationType);
        SalutationFormula.Validate(Salutation, LibraryUtility.GenerateGUID);
        SalutationFormula.Modify();
    end;

    local procedure EnqueueVariablesForEmailDialog(Email: Text; Subject: Text; FileExtension: Text)
    begin
        LibraryVariableStorage.Enqueue(Email);
        LibraryVariableStorage.Enqueue(Subject);
        LibraryVariableStorage.Enqueue(FileExtension);
    end;

    local procedure FindInteractionLogEntry(var InteractionLogEntry: Record "Interaction Log Entry"; ContactNo: Code[20]; InteractionGroupCode: Code[10]; InteractionTemplateCode: Code[10])
    begin
        InteractionLogEntry.SetRange("Contact No.", ContactNo);
        InteractionLogEntry.SetRange("Interaction Group Code", InteractionGroupCode);
        InteractionLogEntry.SetRange("Interaction Template Code", InteractionTemplateCode);
        InteractionLogEntry.FindFirst;
    end;

    local procedure FindInteractionLogEntryByDocument(var InteractionLogEntry: Record "Interaction Log Entry"; DocumentNo: Code[20]; DocumentType: Enum "Interaction Log Entry Document Type")
    begin
        InteractionLogEntry.SetRange("Document No.", DocumentNo);
        InteractionLogEntry.SetRange("Document Type", DocumentType);
        InteractionLogEntry.FindFirst;
    end;

    local procedure FindWordAttachment(): Integer
    var
        Attachment: Record Attachment;
    begin
        with Attachment do begin
            SetRange("Storage Type", "Storage Type"::Embedded);
            SetFilter("File Extension", StrSubstNo('%1|%2', 'DOC', 'DOCX'));
            FindFirst;
            exit("No.");
        end;
    end;

    local procedure FindLanguageCode(CodeFilter: Text): Code[10]
    var
        Language: Record Language;
    begin
        with Language do begin
            SetFilter(Code, CodeFilter);
            FindFirst;
            exit(Code);
        end;
    end;

    local procedure FindOpportunityCommentLine(OpportunityNo: Code[20]; var RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line")
    begin
        RlshpMgtCommentLine.SetRange("Table Name", RlshpMgtCommentLine."Table Name"::Opportunity);
        RlshpMgtCommentLine.SetRange("No.", OpportunityNo);
        RlshpMgtCommentLine.FindSet;
    end;

    local procedure FindContactInteractionLogEntry(var InteractionLogEntry: Record "Interaction Log Entry"; ContactNo: Code[20])
    begin
        InteractionLogEntry.SetRange("Contact No.", ContactNo);
        InteractionLogEntry.FindFirst;
    end;

    local procedure FindIntLogEntryCommentLine(EntryNo: Integer; var InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line")
    begin
        InterLogEntryCommentLine.SetRange("Entry No.", EntryNo);
        InterLogEntryCommentLine.FindFirst;
    end;

    local procedure GetAttachmentFilePath(AttachmentNo: Integer): Text
    var
        Attachment: Record Attachment;
    begin
        Attachment.Get(AttachmentNo);
        exit(Attachment."Storage Pointer" + '\' + Format(Attachment."No.") + '.' + Attachment."File Extension");
    end;

    local procedure GetInterLogEntryDocTypeFromSalesDoc(SalesHeader: Record "Sales Header"): Enum "Interaction Log Entry Document Type"
    var
        DummyInteractionLogEntry: Record "Interaction Log Entry";
    begin
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Order:
                exit(DummyInteractionLogEntry."Document Type"::"Sales Ord. Cnfrmn.");
            SalesHeader."Document Type"::Quote:
                exit(DummyInteractionLogEntry."Document Type"::"Sales Qte.");
        end;
    end;

    local procedure MockAttachmentMergeSource(var Attachment: Record Attachment)
    var
        OutStream: OutStream;
    begin
        Attachment."Merge Source".CreateOutStream(OutStream);
        OutStream.Write('<html>');
        OutStream.Write('<body>');
        OutStream.Write('<table>');
        OutStream.Write('<tr>');
        OutStream.Write('<td>Entry No.</td>');
        OutStream.Write('<td>Value</td>');
        OutStream.Write('</tr>');
        OutStream.Write('<tr>');
        OutStream.Write('<td>139</td>');
        OutStream.Write('<td>HundredThirtyNine</td>');
        OutStream.Write('</tr>');
        OutStream.Write('<tr>');
        OutStream.Write('<td>140</td>');
        OutStream.Write('<td>HundredForty</td>');
        OutStream.Write('</tr>');
        OutStream.Write('</table>');
        OutStream.Write('</body>');
        OutStream.Write('</html>');
        Attachment.Modify();
    end;

    local procedure MockContactNo(LanguageCode: Code[10]): Code[20]
    var
        Contact: Record Contact;
    begin
        with Contact do begin
            Init;
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::Contact);
            "Salutation Code" := CreateSalutation(LanguageCode);
            "E-Mail" := LibraryUtility.GenerateRandomEmail;
            Insert;
            exit("No.");
        end;
    end;

    local procedure MockInterLogEntryWithAttachment(var InteractionLogEntry: Record "Interaction Log Entry"; AttachmentNo: Integer)
    begin
        with InteractionLogEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(InteractionLogEntry, FieldNo("Entry No."));
            "Attachment No." := AttachmentNo;
            Insert;
        end;
    end;

    local procedure MockCanceledInterLogEntryWithAttachment(AttachmentNo: Integer): Integer
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        MockInterLogEntryWithAttachment(InteractionLogEntry, AttachmentNo);
        InteractionLogEntry.Canceled := true;
        InteractionLogEntry.Modify();
        exit(InteractionLogEntry."Entry No.");
    end;

    local procedure MockInterLogEntry(var InteractionLogEntry: Record "Interaction Log Entry")
    begin
        with InteractionLogEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(InteractionLogEntry, FieldNo("Entry No."));
            Insert;
        end;
    end;

    local procedure MockInterLogEntryWithRandomDetails(var InteractionLogEntry: Record "Interaction Log Entry")
    begin
        MockInterLogEntry(InteractionLogEntry);
        with InteractionLogEntry do begin
            "To-do No." :=
              CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen("To-do No."), 0), 1, MaxStrLen("To-do No."));
            "Contact Company No." :=
              CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen("Contact Company No."), 0), 1, MaxStrLen("Contact Company No."));
            "Contact No." :=
              CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen("Contact No."), 0), 1, MaxStrLen("Contact No."));
            "Salesperson Code" :=
              CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen("Salesperson Code"), 0), 1, MaxStrLen("Salesperson Code"));
            "Campaign No." :=
              CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen("Campaign No."), 0), 1, MaxStrLen("Campaign No."));
            "Opportunity No." :=
              CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen("Opportunity No."), 0), 1, MaxStrLen("Opportunity No."));
            Modify;
        end;
    end;

    local procedure MockInterLogEntryWithGivenSalesPersonCode(var InteractionLogEntry: Record "Interaction Log Entry"; SalespersonCode: Code[20])
    begin
        MockInterLogEntry(InteractionLogEntry);
        with InteractionLogEntry do begin
            "Salesperson Code" := SalespersonCode;
            Modify;
        end;
    end;

    local procedure MockInterLogEntryRelatedToSalesDocument(SalesHeader: Record "Sales Header")
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        with InteractionLogEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(InteractionLogEntry, FieldNo("Entry No."));
            "Document No." := SalesHeader."No.";
            "Document Type" := GetInterLogEntryDocTypeFromSalesDoc(SalesHeader);
            "Contact No." := SalesHeader."Bill-to Contact No.";
            Insert;
        end;
    end;

    local procedure MockFullSegmentLine(var SegmentLine: Record "Segment Line"; InteractionTmplLanguage: Record "Interaction Tmpl. Language")
    begin
        MockSegmentLine(
          SegmentLine, InteractionTmplLanguage, MockContactNo(InteractionTmplLanguage."Language Code"),
          MockSalesPersonCode, WorkDate, LibraryUtility.GenerateGUID);
    end;

    local procedure MockSegmentLine(var SegmentLine: Record "Segment Line"; InteractionTmplLanguage: Record "Interaction Tmpl. Language"; ContactNo: Code[20]; SalespersonCode: Code[10]; NewDate: Date; NewDescription: Text[50])
    begin
        with SegmentLine do begin
            Init;
            if not IsTemporary then
                "Line No." := LibraryUtility.GetNewRecNo(SegmentLine, FieldNo("Line No."));
            "Interaction Template Code" := InteractionTmplLanguage."Interaction Template Code";
            "Language Code" := InteractionTmplLanguage."Language Code";
            "Attachment No." := InteractionTmplLanguage."Attachment No.";
            "Contact No." := ContactNo;
            "Salesperson Code" := SalespersonCode;
            Date := NewDate;
            Description := NewDescription;
            Insert;
        end;
    end;

    local procedure MockSalesPersonCode(): Code[10]
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        with SalespersonPurchaser do begin
            Init;
            Code := LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"Salesperson/Purchaser");
            Insert;
            exit(Code);
        end;
    end;

    local procedure PrepareInteractionTmplLangCodeWithoutAttachment(var InteractionTmplLanguage: Record "Interaction Tmpl. Language")
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        CreateInteractionTmplLangWithoutAttachment(InteractionTmplLanguage, InteractionTemplate.Code);
    end;

    local procedure PrepareInteractionTmplLangCodeWithEmailMergeAttachment(var InteractionTmplLanguage: Record "Interaction Tmpl. Language")
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        CreateInteractionTmplLangWithEmailMergeAttachment(InteractionTmplLanguage, InteractionTemplate.Code, '');
        InteractionTemplate.Validate("Language Code (Default)", InteractionTmplLanguage."Language Code");
        InteractionTemplate.Modify();
    end;

    local procedure PrepareSegmentForEmail(var SegmentHeader: Record "Segment Header"; FileExtension: Text[250])
    var
        Contact: Record Contact;
        InteractionTemplate: Record "Interaction Template";
    begin
        CreateInteractionTemplateWithCorrespondenceType(
          InteractionTemplate, InteractionTemplate."Correspondence Type (Default)"::Email);
        CreateInteractionTmplLanguageWithAttachmentNo(InteractionTemplate.Code, CreateAttachmentWithFileValue(FileExtension));

        CreateContactWithEmail(Contact);

        CreateSegmentWithInteractionTemplateAndContact(
          SegmentHeader, InteractionTemplate.Code, Contact."No.",
          SegmentHeader."Correspondence Type (Default)"::Email);
        Commit();
        EnqueueVariablesForEmailDialog(Contact."E-Mail", SegmentHeader."Subject (Default)", '.' + FileExtension);
    end;

    local procedure RunLogSegment(SegmentNo: Code[20])
    var
        LogSegment: Report "Log Segment";
    begin
        LogSegment.SetSegmentNo(SegmentNo);
        LogSegment.UseRequestPage(false);
        LogSegment.RunModal;
    end;

    local procedure SetEmailDraftInteractionTemplate(TemplateCode: Code[10])
    var
        InteractionTemplateSetup: Record "Interaction Template Setup";
    begin
        InteractionTemplateSetup.Get();
        InteractionTemplateSetup.Validate("E-Mail Draft", TemplateCode);
        InteractionTemplateSetup.Modify();
    end;

    [Scope('OnPrem')]
    procedure SetWordAppExists(NewWordAppExists: Boolean)
    begin
        WordAppExist := NewWordAppExists;
    end;

    local procedure TransactionRollback()
    begin
        asserterror Error(RollbackErr);
    end;

    local procedure UpdateInteractionTemplate(var InteractionTemplate: Record "Interaction Template"; InteractionGroupCode: Code[10])
    begin
        InteractionTemplate.Validate("Interaction Group Code", InteractionGroupCode);
        // Use Random for Unit Cost (LCY) and Unit Duration (Min.) because value is not important.
        InteractionTemplate.Validate("Unit Cost (LCY)", LibraryRandom.RandDec(10, 2));
        InteractionTemplate.Validate("Unit Duration (Min.)", LibraryRandom.RandDec(10, 2));
        InteractionTemplate.Modify(true);
    end;

    local procedure UpdateMarketingSetup(MarketingSetup: Record "Marketing Setup"; StorageType: Option; StorageLocation: Text)
    begin
        MarketingSetup.Get();
        MarketingSetup."Attachment Storage Type" := StorageType;
        MarketingSetup."Attachment Storage Location" :=
          CopyStr(StorageLocation, 1, MaxStrLen(MarketingSetup."Attachment Storage Location"));
        MarketingSetup.Modify();
    end;

    local procedure WordDocumentTakeValue(var Attachment: Record Attachment; MergeFieldNo: Integer) MergedFieldValue: Text[250]
    var
        [RunOnClient]
        WordApplication: DotNet "Microsoft.Office.Interop.Word.ApplicationClass";
        [RunOnClient]
        WordDocument: DotNet "Microsoft.Office.Interop.Word.Document";
        [RunOnClient]
        WordFields: DotNet "Microsoft.Office.Interop.Word.Fields";
        [RunOnClient]
        WordRange: DotNet "Microsoft.Office.Interop.Word.Range";
        [RunOnClient]
        WordHelper: DotNet WordHelper;
        FileName: Text;
    begin
        WordApplication := WordApplication.ApplicationClass;

        Attachment.CalcFields("Attachment File");
        FileName := Attachment.ConstFilename;
        Attachment.ExportAttachmentToClientFile(FileName);
        WordDocument := WordHelper.CallOpen(WordApplication, FileName, false, false);

        WordFields := WordDocument.Fields;
        WordRange := WordFields.Item(MergeFieldNo).Result;
        MergedFieldValue := WordRange.Text;

        Clear(WordDocument);
        WordHelper.CallQuit(WordApplication, false);
        Clear(WordApplication);
    end;

    local procedure VerifyInteractionLogEntry(ContactNo: Code[20]; InteractionTemplateCode: Code[10])
    var
        InteractionTemplate: Record "Interaction Template";
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionTemplate.Get(InteractionTemplateCode);
        FindInteractionLogEntry(InteractionLogEntry, ContactNo, InteractionTemplate."Interaction Group Code", InteractionTemplateCode);
        InteractionLogEntry.TestField("Cost (LCY)", InteractionTemplate."Unit Cost (LCY)");
        InteractionLogEntry.TestField("Duration (Min.)", InteractionTemplate."Unit Duration (Min.)");
    end;

    local procedure VerifyInteractionLogEntryDetails(ExpectedEntryNo: Integer; SegmentLine: Record "Segment Line")
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        with InteractionLogEntry do begin
            FindLast;
            Assert.AreEqual(ExpectedEntryNo, "Entry No.", FieldCaption("Entry No."));
            Assert.AreEqual(SegmentLine."Contact No.", "Contact No.", FieldCaption("Contact No."));
            Assert.AreEqual(SegmentLine."Salesperson Code", "Salesperson Code", FieldCaption("Salesperson Code"));
            Assert.AreEqual(SegmentLine.Date, Date, FieldCaption(Date));
            Assert.AreEqual(SegmentLine.Description, Description, FieldCaption(Description));
            Assert.AreEqual(SegmentLine."Interaction Template Code", "Interaction Template Code", FieldCaption("Interaction Template Code"));
            Assert.AreEqual(SegmentLine."Language Code", "Interaction Language Code", FieldCaption("Interaction Language Code"));
        end;
    end;

    local procedure VerifyTemplateGroupStatistics(InteractionGroup: Record "Interaction Group")
    var
        InteractionGroups: TestPage "Interaction Groups";
        InteractionGroupStatistics: TestPage "Interaction Group Statistics";
    begin
        // Open Interaction Group Statistics Page and verify values.
        InteractionGroups.OpenEdit;
        InteractionGroups.FILTER.SetFilter(Code, InteractionGroup.Code);
        InteractionGroupStatistics.Trap;
        InteractionGroups.Statistics.Invoke;

        InteractionGroupStatistics."No. of Interactions".AssertEquals(InteractionGroup."No. of Interactions");
        InteractionGroupStatistics."Cost (LCY)".AssertEquals(InteractionGroup."Cost (LCY)");
        InteractionGroupStatistics."Duration (Min.)".AssertEquals(InteractionGroup."Duration (Min.)");
    end;

    local procedure VerifyTemplateStatistics(InteractionTemplate: Record "Interaction Template")
    var
        InteractionTemplates: TestPage "Interaction Templates";
        InteractionTmplStatistics: TestPage "Interaction Tmpl. Statistics";
    begin
        // Open Interaction Template Statistics Page and verify values.
        InteractionTemplates.OpenEdit;
        InteractionTemplates.FILTER.SetFilter(Code, InteractionTemplate.Code);
        InteractionTmplStatistics.Trap;
        InteractionTemplates.Statistics.Invoke;

        InteractionTmplStatistics."No. of Interactions".AssertEquals(InteractionTemplate."No. of Interactions");
        InteractionTmplStatistics."Cost (LCY)".AssertEquals(InteractionTemplate."Cost (LCY)");
        InteractionTmplStatistics."Duration (Min.)".AssertEquals(InteractionTemplate."Duration (Min.)");
    end;

    local procedure VerifyFilterValuesAfterResumeInteraction(TodoNo: Code[20]; ContactCompanyNo: Code[20]; ContactNo: Code[20]; SalespersonCode: Code[20]; CampaignNo: Code[20]; OpportunityNo: Code[20])
    begin
        // "Salesperson Code" field value
        Assert.AreEqual(SalespersonCode, LibraryVariableStorage.DequeueText, '');
        // Filter values:
        Assert.AreEqual(TodoNo, LibraryVariableStorage.DequeueText, '');
        Assert.AreEqual(ContactCompanyNo, LibraryVariableStorage.DequeueText, '');
        Assert.AreEqual(ContactNo, LibraryVariableStorage.DequeueText, '');
        Assert.AreEqual(SalespersonCode, LibraryVariableStorage.DequeueText, '');
        Assert.AreEqual(CampaignNo, LibraryVariableStorage.DequeueText, '');
        Assert.AreEqual(OpportunityNo, LibraryVariableStorage.DequeueText, '');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(FinishWizardLaterQst, Question);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(FinishWizardLaterQst, Question);
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerExportAttachment(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContentPreviewMPH(var ContentPreview: TestPage "Content Preview")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateInteractPageHandler(var CreateInteraction: Page "Create Interaction"; var Response: Action)
    var
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        TempSegmentLine.Init();
        CreateInteraction.GetRecord(TempSegmentLine);
        TempSegmentLine.Insert();

        TempSegmentLine.Validate("Interaction Template Code",
          CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(TempSegmentLine."Interaction Template Code")));
        TempSegmentLine.Validate(Description, TempSegmentLine."Interaction Template Code");  // Validating Description as TemplateCode as using for contact search.
        TempSegmentLine.Modify();

        if LibraryVariableStorage.DequeueBoolean then begin
            TempSegmentLine.Validate("Cost (LCY)", LibraryVariableStorage.DequeueDecimal);
            TempSegmentLine.Validate("Duration (Min.)", LibraryVariableStorage.DequeueDecimal);
        end;

        TempSegmentLine.CheckStatus;
        TempSegmentLine.FinishWizard(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateInteraction_VerifyHTMLContentVisibility_MPH(var CreateInteraction: TestPage "Create Interaction")
    var
        HTMLMode: Boolean;
    begin
        HTMLMode := LibraryVariableStorage.DequeueBoolean;
        CreateInteraction."Interaction Template Code".SetValue(LibraryVariableStorage.DequeueText);

        Assert.AreEqual(HTMLMode, CreateInteraction.HTMLContentBodyText.Visible, CreateInteraction.Caption);
        Assert.AreEqual(HTMLMode, CreateInteraction.Preview.Visible, CreateInteraction.Caption);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateInteraction_ValidateLanguageCode_MPH(var CreateInteraction: TestPage "Create Interaction")
    var
        HTMLMode: Boolean;
        NewLanguageCode: Code[10];
    begin
        HTMLMode := LibraryVariableStorage.DequeueBoolean;
        NewLanguageCode := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(NewLanguageCode));
        CreateInteraction."Interaction Template Code".SetValue(LibraryVariableStorage.DequeueText);
        CreateInteraction."Language Code".SetValue(NewLanguageCode);

        Assert.AreEqual(HTMLMode, CreateInteraction.HTMLContentBodyText.Visible, CreateInteraction.Caption);
        Assert.AreEqual(HTMLMode, CreateInteraction.Preview.Visible, CreateInteraction.Caption);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateInteraction_ValidateHTMLContent_MPH(var CreateInteraction: TestPage "Create Interaction")
    var
        ContentText: Text;
    begin
        CreateInteraction."Interaction Template Code".SetValue(LibraryVariableStorage.DequeueText);
        ContentText := LibraryUtility.GenerateRandomAlphabeticText(LibraryRandom.RandIntInRange(2000, 3000), 0);
        CreateInteraction.HTMLContentBodyText.SetValue(ContentText);
        CreateInteraction.Preview.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InteractionSaveMergedDocumentPageHandler(var CreateInteraction: Page "Create Interaction"; var Response: Action)
    var
        TempSegmentLine: Record "Segment Line" temporary;
        TemplateCode: Code[10];
    begin
        TempSegmentLine.Init();
        CreateInteraction.GetRecord(TempSegmentLine);
        TempSegmentLine.Insert();

        TemplateCode := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(TemplateCode));
        TempSegmentLine.Validate("Interaction Template Code", TemplateCode);
        TempSegmentLine.Validate(Description, TemplateCode);  // Validating Description as TemplateCode as using for contact search.
        TempSegmentLine.Modify();

        TempSegmentLine.CheckStatus;
        TempSegmentLine.FinishWizard(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InteractTmplLanguagesMPH(var InteractTmplLanguages: TestPage "Interact. Tmpl. Languages")
    begin
        InteractTmplLanguages."Interaction Template Code".AssertEquals(LibraryVariableStorage.DequeueText);
        InteractTmplLanguages."Language Code".AssertEquals(LibraryVariableStorage.DequeueText);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerCreateInteract(var CreateInteraction: Page "Create Interaction"; var Response: Action)
    var
        TempSegmentLine: Record "Segment Line" temporary;
        TemplateCode: Code[10];
    begin
        TempSegmentLine.Init();
        CreateInteraction.GetRecord(TempSegmentLine);
        TempSegmentLine.Insert();
        TemplateCode := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(TemplateCode));
        if TemplateCode <> '' then begin
            TempSegmentLine.Validate("Interaction Template Code", TemplateCode);
            TempSegmentLine.Modify();
        end;

        TempSegmentLine.CheckStatus;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormInteractionGroupStat(var InteractionGroupStatistics: Page "Interaction Group Statistics"; var Response: Action)
    var
        InteractionGroup: Record "Interaction Group";
    begin
        InteractionGroupStatistics.GetRecord(InteractionGroup);
        InteractionGroup.CalcFields("Cost (LCY)", "Duration (Min.)");
        InteractionGroup.TestField("Cost (LCY)", LibraryVariableStorage.DequeueDecimal);
        InteractionGroup.TestField("Duration (Min.)", LibraryVariableStorage.DequeueDecimal);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MakePhoneCall_MPH(var MakePhoneCall: TestPage "Make Phone Call")
    begin
        MakePhoneCall.OpenCommentsPage.Invoke;
        MakePhoneCall.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InterLogEntryCommentSheet_MPH(var InterLogEntryCommentSheet: TestPage "Inter. Log Entry Comment Sheet")
    begin
        InterLogEntryCommentSheet.Date.SetValue(LibraryVariableStorage.DequeueDate);
        InterLogEntryCommentSheet.Comment.SetValue(LibraryVariableStorage.DequeueText);
        InterLogEntryCommentSheet.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ModalReportHandler(var LogSegment: TestRequestPage "Log Segment")
    begin
        LogSegment.Deliver.SetValue(true);
        LogSegment.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(MessageText: Text)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailDialogModalPageHandler(var EmailDialog: TestPage "Email Dialog")
    begin
        EmailDialog.SendTo.AssertEquals(LibraryVariableStorage.DequeueText);
        EmailDialog.Subject.AssertEquals(LibraryVariableStorage.DequeueText);
        Assert.AreNotEqual(0, StrPos(EmailDialog."Attachment Name".Value, LibraryVariableStorage.DequeueText), AttachmentErr);
        EmailDialog.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailEditorHandler(var EmailEditor: TestPage "Email Editor")
    begin
        EmailEditor.ToField.AssertEquals(LibraryVariableStorage.DequeueText);
        EmailEditor.SubjectField.AssertEquals(LibraryVariableStorage.DequeueText);
        Assert.AreNotEqual(0, StrPos(EmailEditor.Attachments.FileName.Value, LibraryVariableStorage.DequeueText), AttachmentErr);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CloseEmailEditorHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateInteraction_Cancel_MPH(var CreateInteraction: TestPage "Create Interaction")
    begin
        LibraryVariableStorage.Enqueue(CreateInteraction."Salesperson Code".Value);
        LibraryVariableStorage.Enqueue(CreateInteraction.FILTER.GetFilter("To-do No."));
        LibraryVariableStorage.Enqueue(CreateInteraction.FILTER.GetFilter("Contact Company No."));
        LibraryVariableStorage.Enqueue(CreateInteraction.FILTER.GetFilter("Contact No."));
        LibraryVariableStorage.Enqueue(CreateInteraction.FILTER.GetFilter("Salesperson Code"));
        LibraryVariableStorage.Enqueue(CreateInteraction.FILTER.GetFilter("Campaign No."));
        LibraryVariableStorage.Enqueue(CreateInteraction.FILTER.GetFilter("Opportunity No."));
        CreateInteraction.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SimpleEmailDialogModalPageHandler(var EmailDialog: TestPage "Email Dialog")
    begin
        EmailDialog.Cancel.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SimpleEmailEditorHandler(var EmailEditor: TestPage "Email Editor")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectSendingOptionsModalPageHandler(var SelectSendingOptions: TestPage "Select Sending Options")
    var
        DummyDocumentSendingProfile: Record "Document Sending Profile";
    begin
        SelectSendingOptions."E-Mail".SetValue(DummyDocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");
        SelectSendingOptions.OK.Invoke;
    end;

    local procedure SetDefaultCorrespondenceType(CorrespondenceType: Enum "Correspondence Type")
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        MarketingSetup.Validate("Default Correspondence Type", CorrespondenceType);
        MarketingSetup.Modify(true);
    end;

    local procedure CreateSalesInvoiceForCustomerWithContact(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Contact, LibraryUtility.GenerateRandomText(30));
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.", '', LibraryRandom.RandDec(100, 2), '', 0D);
    end;

    local procedure VerifyBlankCorrespondenceTypeOnInteractionLogEntryForContact(ContactNo: Code[20]; DocumentNo: Code[20])
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionLogEntry.SetRange("Contact No.", ContactNo);
        Assert.RecordCount(InteractionLogEntry, 1);
        InteractionLogEntry.FindFirst;
        InteractionLogEntry.TestField("Correspondence Type", InteractionLogEntry."Correspondence Type"::" ");
        InteractionLogEntry.TestField("Document No.", DocumentNo);
    end;

    local procedure VerifyInterLogEntry(EntryNo: Integer; ExpectedDocNo: Code[20]; ExpectedDocType: Enum "Interaction Log Entry Document Type")
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionLogEntry.Get(EntryNo);
        InteractionLogEntry.TestField("Document No.", ExpectedDocNo);
        InteractionLogEntry.TestField("Document Type", ExpectedDocType);
    end;

    local procedure VerifyOpporunityCommentLine(InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line"; RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line")
    begin
        RlshpMgtCommentLine.TestField(Date, InterLogEntryCommentLine.Date);
        RlshpMgtCommentLine.TestField(Comment, InterLogEntryCommentLine.Comment);
    end;

    local procedure VerifyILEHTMLMergeFile(Attachment: Record Attachment; InteractionLogEntryNo: Integer; ShouldFindValue: Text; ShouldNotFindValue: Text)
    var
        WordManagement: Codeunit WordManagement;
        FileManagement: Codeunit "File Management";
        Instream: InStream;
        MergeFile: File;
        HeaderIsReady: Boolean;
        TRCount: Integer;
        ValueFound: Boolean;
        WrongValueFound: Boolean;
        FileName: Text;
        TextLine: Text;
    begin
        FileName := FileManagement.ServerTempFileName('htm');
        MergeFile.WriteMode := true;
        MergeFile.TextMode := true;
        MergeFile.Create(FileName);
        WordManagement.PopulateInterLogEntryToMergeSource(MergeFile, Attachment, InteractionLogEntryNo, HeaderIsReady, 0);
        MergeFile.CreateInStream(Instream);
        repeat
            Instream.ReadText(TextLine);
            if StrPos(TextLine, ShouldFindValue) > 0 then
                ValueFound := true;
            if StrPos(TextLine, ShouldNotFindValue) > 0 then
                WrongValueFound := true;
            if StrPos(TextLine, '</tr>') > 0 then
                TRCount += 1;
        until Instream.EOS;
        MergeFile.Close;
        Assert.IsTrue(ValueFound, 'Value not found');
        Assert.IsFalse(WrongValueFound, 'Wrong value found');
        Assert.IsTrue(TRCount = 2, 'Wrong </tr> count');
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5054, 'OnBeforeCheckCanRunWord', '', false, false)]
    local procedure SetCanRunWord(var CanRunWord: Boolean; var CanRunWordModified: Boolean)
    begin
        CanRunWord := WordAppExist;
        CanRunWordModified := true;
    end;

    local procedure UpdateSMTPSetup()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
    begin
        SMTPMailSetup.Get();
        SMTPMailSetup."User ID" := 'test@test.com';
        SMTPMailSetup.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, 419, 'OnBeforeDownloadHandler', '', false, false)]
    local procedure OnBeforeDownloadHandler(var ToFolder: Text; ToFileName: Text; FromFileName: Text; var IsHandled: Boolean)
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.Init();
        NameValueBuffer.ID := SessionId;
        NameValueBuffer.Value := FromFileName;
        NameValueBuffer.Insert(true);
        IsHandled := true;
    end;
}

