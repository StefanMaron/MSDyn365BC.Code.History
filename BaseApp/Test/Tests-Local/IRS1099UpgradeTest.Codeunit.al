#if not CLEAN25
codeunit 144030 "IRS 1099 Upgrade Test"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData Vendor = rim,
                  TableData "Vendor Ledger Entry" = rim,
                  TableData "Purchase Header" = rim,
                  TableData "Gen. Journal Line" = rim,
                  TableData "Purch. Inv. Header" = rim,
                  TableData "Purch. Cr. Memo Hdr." = rim,
                  TableData "Detailed Vendor Ledg. Entry" = rim;
    Subtype = Test;
    TestPermissions = NonRestrictive;
    ObsoleteReason = 'Moved to IRS Forms App.';
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';

    trigger OnRun()
    begin
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        Assert: Codeunit Assert;
        UpgradeFormBoxesScheduledMsg: Label 'A job queue entry has been created.\\Make sure Earliest Start Date/Time field in the Job Queue Entry Card window is correct, and then choose the Set Status to Ready action to schedule a background job.';
        FormBoxesUpgradedMsg: Label 'The 1099 form boxes are successfully updated.';
        ConfirmUpgradeNowQst: Label 'The update process can take a while and block other users activities. Do you want to start the update now?';
        NotificationMsg: Label 'The list of 1099 form boxes is not up to date. Update: %1';
        ConfirmIRS1099CodeUpdateQst: Label 'One or more entries have been posted with IRS 1099 code %1.\\Do you want to continue and update all the data associated with this vendor and the existing IRS 1099 code with the new code, %2?', Comment = '%1 - old code;%2 - new code';
        BlockIfUpgradeNeededErr: Label 'You must update the form boxes in the 1099 Forms-Boxes window before you can run this report.';
        February2020Lbl: Label 'February 2020';
        Upgrade2021Lbl: Label '2021';
        Upgrade2022Lbl: Label '2022';
        IRS1099ComplianceMsg: Label 'You are compliant with the latest format of 1099 reporting.';

    [Test]
    [Scope('OnPrem')]
    procedure AllIRS1099CodesUpToDateInDemodata()
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        // [FEATURE] [DEMO]
        // [SCENARIO 374401] All IRS 1099 codes required for upgrade are up to date in the demodata

        IRS1099FormBox.Get(GetIRS1099UpgradeCode2019());
        IRS1099FormBox.Get(GetIRS1099UpgradeCode2020());
        IRS1099FormBox.Get(GetIRS1099UpgradeCode2020February());
        // TFS ID 412412: 1099 format 2021
        IRS1099FormBox.Get(GetIRS1099UpgradeCode2021());
        // TFS ID 454897: 1099 format 2022
        IRS1099FormBox.Get(GetIRS1099UpgradeCode2022());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UpgradeOfIRS1099CodesNeededByDefault()
    var
        IRS1099Management: Codeunit "IRS 1099 Management";
    begin
        // [FEAUTURE] [UT]
        // [SCENARIO 283821] Make sure that upgrade is needed if IRS 1099 code "DIV-07" does not exists

        Initialize();
        Assert.IsTrue(IRS1099Management.UpgradeNeeded(), 'Upgrade not needed');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NotificationUpgrade2019ThrownOnIRS1099FormBoxPage()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        IRS1099FormBoxPage: TestPage "IRS 1099 Form-Box";
    begin
        // [FEATURE] [UI] [DEMO]
        // [SCENARIO 283821] Notification of upgrade 2019 thrown on opening IRS 1099 Form Box Page if code IRS 1099 code "DIV-07" does not exist

        Initialize();
        LibraryVariableStorage.Enqueue('2019');
        IRS1099FormBoxPage.OpenView();
        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NotificationUpgrade2020ThrownOnIRS1099FormBoxPage()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        IRS1099FormBoxPage: TestPage "IRS 1099 Form-Box";
        IRSCode: Code[10];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 374401] Notification of upgrade 2020 thrown on opening IRS 1099 Form Box Page if code IRS 1099 code "NEC-01" does not exist

        Initialize();
        IRSCode := GetIRS1099UpgradeCode2019();
        InsertIRS1099Code(IRSCode);

        LibraryVariableStorage.Enqueue('2020');
        IRS1099FormBoxPage.OpenView();
        IRS1099FormBoxPage.FILTER.SetFilter(Code, IRSCode);
        IRS1099FormBoxPage.Code.AssertEquals(IRSCode);
        RemoveIRS1099UpgradeCodeYear2019();
        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NotificationUpgrade2020FebruaryThrownOnIRS1099FormBoxPage()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        IRS1099FormBoxPage: TestPage "IRS 1099 Form-Box";
        IRSCode: Code[10];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 387271] Notification of upgrade February 2020 thrown on opening IRS 1099 Form Box Page if code IRS 1099 code "NEC-01" does not exist

        Initialize();
        IRSCode := GetIRS1099UpgradeCode2019();
        InsertIRS1099Code(IRSCode);
        IRSCode := GetIRS1099UpgradeCode2020();
        InsertIRS1099Code(IRSCode);

        LibraryVariableStorage.Enqueue(February2020Lbl);
        IRS1099FormBoxPage.OpenView();
        IRS1099FormBoxPage.FILTER.SetFilter(Code, IRSCode);
        IRS1099FormBoxPage.Code.AssertEquals(IRSCode);
        RemoveIRS1099UpgradeCodeYear2019();
        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NotificationUpgrade2021ThrownOnIRS1099FormBoxPage()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        IRS1099FormBoxPage: TestPage "IRS 1099 Form-Box";
        IRSCode: Code[10];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 412412] Notification of upgrade February 2020 thrown on opening IRS 1099 Form Box Page if code IRS 1099 code "NEC-01" does not exist

        Initialize();
        IRSCode := GetIRS1099UpgradeCode2019();
        InsertIRS1099Code(IRSCode);
        IRSCode := GetIRS1099UpgradeCode2020();
        InsertIRS1099Code(IRSCode);
        IRSCode := GetIRS1099UpgradeCode2020February();
        InsertIRS1099Code(IRSCode);

        LibraryVariableStorage.Enqueue(Upgrade2021Lbl);
        IRS1099FormBoxPage.OpenView();
        IRS1099FormBoxPage.FILTER.SetFilter(Code, IRSCode);
        IRS1099FormBoxPage.Code.AssertEquals(IRSCode);
        RemoveIRS1099UpgradeCodeYear2019();
        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NotificationUpgrade2022ThrownOnIRS1099FormBoxPage()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        IRS1099FormBoxPage: TestPage "IRS 1099 Form-Box";
        IRSCode: Code[10];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 412412] Notification of upgrade February 2020 thrown on opening IRS 1099 Form Box Page if code IRS 1099 code "NEC-01" does not exist

        Initialize();
        IRSCode := GetIRS1099UpgradeCode2019();
        InsertIRS1099Code(IRSCode);
        IRSCode := GetIRS1099UpgradeCode2020();
        InsertIRS1099Code(IRSCode);
        IRSCode := GetIRS1099UpgradeCode2020February();
        InsertIRS1099Code(IRSCode);
        IRSCode := GetIRS1099UpgradeCode2021();
        InsertIRS1099Code(IRSCode);

        LibraryVariableStorage.Enqueue(Upgrade2022Lbl);
        IRS1099FormBoxPage.OpenView();
        IRS1099FormBoxPage.FILTER.SetFilter(Code, IRSCode);
        IRS1099FormBoxPage.Code.AssertEquals(IRSCode);
        RemoveIRS1099UpgradeCodeYear2019();
        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NotificationNotShowOnIRS1099FormBoxPage()
    var
        CodeCoverage: Record "Code Coverage";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        IRS1099FormBoxPage: TestPage "IRS 1099 Form-Box";
        IRSCode: Code[10];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 283821] Notification of upgrade not shown on opening IRS 1099 Form Box Page if IRS 1099 codes "DIV-07", "NEC-01" and "MISC-11" are exist

        Initialize();
        IRSCode := GetIRS1099UpgradeCode2019();
        InsertIRS1099Code(IRSCode);
        // TFS ID 374401: Support of US1099 for year 2020.
        IRSCode := GetIRS1099UpgradeCode2020();
        InsertIRS1099Code(IRSCode);
        // TFS ID 387271: Support of NEC-04 for year 2020.
        IRSCode := GetIRS1099UpgradeCode2020February();
        InsertIRS1099Code(IRSCode);
        // TFS ID 412412: 1099 format 2021
        IRSCode := GetIRS1099UpgradeCode2021();
        InsertIRS1099Code(IRSCode);
        // TFS ID 454897: 1099 format 2022
        IRSCode := GetIRS1099UpgradeCode2022();
        InsertIRS1099Code(IRSCode);

        CodeCoverageMgt.StartApplicationCoverage();
        IRS1099FormBoxPage.OpenView();
        IRS1099FormBoxPage.FILTER.SetFilter(Code, IRSCode);
        IRS1099FormBoxPage.Code.AssertEquals(IRSCode);
        CodeCoverageMgt.StopApplicationCoverage();

        Assert.AreEqual(
          0,
          CodeCoverageMgt.GetNoOfHitsCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"IRS 1099 Management", 'SendIRS1099UpgradeNotification'), '');

        RemoveIRS1099UpgradeCodeYear2019();
        RemoveIRS1099UpgradeCodeYear2020();
        RemoveIRS1099UpgradeCodeYear2020February();
        RemoveIRS1099UpgradeCodeYear2021();
        RemoveIRS1099UpgradeCodeYear2022();
    end;

    [Test]
    [HandlerFunctions('JobQueueEntryCardPageHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure JobQueueEntryCreatedWhenItIsPossibleToCreateTaskDuringUpgrade()
    var
        IRS1099Management: Codeunit "IRS 1099 Management";
        IRS1099UpgradeTest: Codeunit "IRS 1099 Upgrade Test";
    begin
        // [FEATURE] [Job Queue Entry]
        // [SCENARIO 283821] Job Queue Entry Card creates and opens when it's possible to create task during an upgrade

        Initialize();
        RemoveIRS1099UpgradeCodeYear2019();

        // [GIVEN] TASKSCHEDULER.CANCREATETASK is TRUE
        BindSubscription(IRS1099UpgradeTest);
        LibraryVariableStorage.Enqueue(UpgradeFormBoxesScheduledMsg);

        // [WHEN] Upgrade form boxes
        IRS1099Management.UpgradeFormBoxes();

        // [THEN] Job Queue Entry created and opened in Job Queue Entry Card
        // Verify by JobQueueEntryCardPageHandler

        LibraryVariableStorage.AssertEmpty();
        UnbindSubscription(IRS1099UpgradeTest);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UpgradePerformsAfterConfirmationWhenItIsNotPossibleToCreateTaskDuringUpgrade()
    var
        IRS1099Management: Codeunit "IRS 1099 Management";
    begin
        // [SCENARIO 283821] An upgrade performs after the confirmation when it is not possible to create task during an upgrade

        Initialize();
        RemoveIRS1099UpgradeCodeYear2019();

        // [GIVEN] TASKSCHEDULER.CANCREATETASK is FALSE
        LibraryVariableStorage.Enqueue(ConfirmUpgradeNowQst);
        LibraryVariableStorage.Enqueue(FormBoxesUpgradedMsg);

        // [WHEN] Upgrade form boxes
        IRS1099Management.UpgradeFormBoxes();

        // [THEN] Confirmation about upgrade raised
        // Verify by ConfirmationHandler
        // [THEN] Upgrade performed and new code is added
        Assert.IsFalse(IRS1099Management.UpgradeNeeded(), 'Upgrade was not performed');

        // [THEN] Message about successfull upgrade shown
        // Verify by MessageHandler
        LibraryVariableStorage.AssertEmpty();

        // Tear down
        RemoveIRS1099UpgradeCodeYear2019();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NoConfirmationThrownWhenUpdateIRSCodeInVendorWithoutRelatedData()
    var
        Vendor: Record Vendor;
        IRSCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 287814] No confirmation throws when update IRS code in Vendor without related data

        Initialize();
        IRSCode := LibraryUtility.GenerateGUID();
        InsertIRS1099Code(IRSCode);

        Vendor.Init();
        Vendor."No." := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("No."), DATABASE::Vendor);
        Vendor."IRS 1099 Code" := IRSCode;
        Vendor.Insert();

        IRSCode := LibraryUtility.GenerateGUID();
        InsertIRS1099Code(IRSCode);

        Vendor.Validate("IRS 1099 Code", IRSCode);
        Vendor.TestField("IRS 1099 Code", IRSCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IRSCodeGetsUpdatedInRelatedDataAfterUpdateInVendor()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        GenJournalLineAccount: Record "Gen. Journal Line";
        GenJournalLineBalAccount: Record "Gen. Journal Line";
        OldIRSCode: Code[10];
        NewIRSCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 287814] IRS Code gets updated in posted entries after update in vendor

        Initialize();
        OldIRSCode := LibraryUtility.GenerateGUID();
        InsertIRS1099Code(OldIRSCode);
        MockDataWithIRS1099Code(
          Vendor, VendorLedgerEntry, PurchaseHeader, PurchInvHeader, PurchCrMemoHdr,
          GenJournalLineAccount, GenJournalLineBalAccount, OldIRSCode);
        NewIRSCode := LibraryUtility.GenerateGUID();
        InsertIRS1099Code(NewIRSCode);

        LibraryVariableStorage.Enqueue(StrSubstNo(ConfirmIRS1099CodeUpdateQst, Vendor."IRS 1099 Code", NewIRSCode));
        Vendor.Validate("IRS 1099 Code", NewIRSCode);

        VendorLedgerEntry.Find();
        VendorLedgerEntry.TestField("IRS 1099 Code", Vendor."IRS 1099 Code");

        PurchaseHeader.Find();
        PurchaseHeader.TestField("IRS 1099 Code", Vendor."IRS 1099 Code");

        PurchInvHeader.Find();
        PurchInvHeader.TestField("IRS 1099 Code", Vendor."IRS 1099 Code");

        PurchCrMemoHdr.Find();
        PurchCrMemoHdr.TestField("IRS 1099 Code", Vendor."IRS 1099 Code");

        GenJournalLineAccount.Find();
        GenJournalLineAccount.TestField("IRS 1099 Code", Vendor."IRS 1099 Code");

        GenJournalLineBalAccount.Find();
        GenJournalLineBalAccount.TestField("IRS 1099 Code", Vendor."IRS 1099 Code");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099DivReportBlockedIfUpgradeNeeded()
    var
        Vendor1099Div: Report "Vendor 1099 Div";
    begin
        // [FEATURE] [Report]
        // [SCENARIO 287814] "Vendor 1099 Div" report is blocked if upgrade needed

        Initialize();
        RemoveIRS1099UpgradeCodeYear2019();
        asserterror Vendor1099Div.UseRequestPage(false);
        Assert.ExpectedError(BlockIfUpgradeNeededErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaBlockedIfUpgradeNeeded()
    var
        Vendor1099MagneticMedia: Report "Vendor 1099 Magnetic Media";
    begin
        // [FEATURE] [Report]
        // [SCENARIO 287814] "Vendor 1099 Magnetic Media" report is blocked if upgrade needed

        Initialize();
        RemoveIRS1099UpgradeCodeYear2019();
        asserterror Vendor1099MagneticMedia.UseRequestPage(false);
        Assert.ExpectedError(BlockIfUpgradeNeededErr);
    end;

    // [Test]
    [HandlerFunctions('Vendor1099DivRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099DivReportPrintsDiv05Code()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        Vendor: Record Vendor;
        Vendor1099Div: Report "Vendor 1099 Div";
        IRSCode: Code[10];
    begin
        // [FEATURE] [Report]
        // [SCENARIO 287814] "Vendor 1099 Div" report prints "DIV-05" code

        Initialize();
        IRSCode := GetIRS1099UpgradeCode2019();
        InsertIRS1099Code(IRSCode);

        // [GIVEN] Payment applied to invoice with "IRS 1099 Code" = "DIV-05" and "IRS Amount" = 100
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(LibraryReportValidation.GetFileName());
        MockAppliedPmtEntry(DetailedVendorLedgEntry);
        Vendor.SetRange("No.", DetailedVendorLedgEntry."Vendor No.");
        Vendor1099Div.SetTableView(Vendor);
        Vendor1099Div.Run();

        // [WHEN] Print "Vendor 1099 Div" report
        LibraryReportValidation.OpenFile();

        // [THEN] Amount = 100 printed for "DIV-05" code
        LibraryReportValidation.VerifyCellValueOnWorksheet(15, 4, Format(-DetailedVendorLedgEntry.Amount), '1');

        LibraryVariableStorage.AssertEmpty();
    end;

    // [Test]
    [HandlerFunctions('Vendor1099DivRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaReportExportsDiv05Code()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        Vendor: Record Vendor;
        Vendor1099Div: Report "Vendor 1099 Div";
        IRSCode: Code[10];
    begin
        // [FEATURE] [Report]
        // [SCENARIO 287814] "Vendor 1099 Magnetic Media" report exports "DIV-05" code to file

        Initialize();
        IRSCode := GetIRS1099UpgradeCode2019();
        InsertIRS1099Code(IRSCode);

        // [GIVEN] Payment applied to invoice with "IRS 1099 Code" = "DIV-05" and "IRS Amount" = 100
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(LibraryReportValidation.GetFileName());
        MockAppliedPmtEntry(DetailedVendorLedgEntry);
        Vendor.SetRange("No.", DetailedVendorLedgEntry."Vendor No.");
        Vendor1099Div.SetTableView(Vendor);
        Vendor1099Div.Run();

        // [WHEN] Print "Vendor 1099 Div" report
        LibraryReportValidation.OpenFile();

        // [THEN] Amount = 100 printed for "DIV-05" code
        LibraryReportValidation.VerifyCellValueOnWorksheet(15, 4, Format(-DetailedVendorLedgEntry.Amount), '1');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IRSCodeNotUpdatedInRelatedDataAfterUpdateInVendorIfInitialValueIsBlank()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        GenJournalLineAccount: Record "Gen. Journal Line";
        GenJournalLineBalAccount: Record "Gen. Journal Line";
        NewIRSCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 291872] IRS Code not updated in posted entries after update in vendor if initial code is blank

        Initialize();
        MockDataWithIRS1099Code(
          Vendor, VendorLedgerEntry, PurchaseHeader, PurchInvHeader, PurchCrMemoHdr, GenJournalLineAccount, GenJournalLineBalAccount, '');
        NewIRSCode := LibraryUtility.GenerateGUID();
        InsertIRS1099Code(NewIRSCode);

        Vendor.Validate("IRS 1099 Code", NewIRSCode);

        VendorLedgerEntry.Find();
        VendorLedgerEntry.TestField("IRS 1099 Code", '');

        PurchaseHeader.Find();
        PurchaseHeader.TestField("IRS 1099 Code", '');

        PurchInvHeader.Find();
        PurchInvHeader.TestField("IRS 1099 Code", '');

        PurchCrMemoHdr.Find();
        PurchCrMemoHdr.TestField("IRS 1099 Code", '');

        GenJournalLineAccount.Find();
        GenJournalLineAccount.TestField("IRS 1099 Code", '');

        GenJournalLineBalAccount.Find();
        GenJournalLineBalAccount.TestField("IRS 1099 Code", '');
    end;

    [Test]
    [HandlerFunctions('Vendor1099Misc2019RequestPageHandler')]
    [Scope('OnPrem')]
    procedure Misc1099ForYear2019RepShownFromVendPageWhenNECCodeDoesNoExist()
    var
        VendorList: TestPage "Vendor List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 374401] A "Vendor 1099 Misc 2019" report shown from the Vendor List page when "NEC-01" does not exist in the database

        Initialize();
        RemoveIRS1099UpgradeCodeYear2019();
        Commit();
        VendorList.OpenEdit();
        VendorList."Vendor 1099 Misc".Invoke();
    end;

    [Test]
    [HandlerFunctions('Vendor1099Misc2020RequestPageHandler')]
    [Scope('OnPrem')]
    procedure Misc1099ForYear2020RepShownFromVendPageWhenNECCodeExists()
    var
        VendorList: TestPage "Vendor List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 374401] A "Vendor 1099 Misc 2019" report shown from the Vendor List page when "NEC-01" code exists in the database

        Initialize();
        RemoveIRS1099UpgradeCodeYear2020();
        RemoveIRS1099UpgradeCodeYear2020February();
        InsertIRS1099Code(GetIRS1099UpgradeCode2020());
        Commit();
        VendorList.OpenEdit();
        VendorList."Vendor 1099 Misc".Invoke();
    end;

    [Test]
    [HandlerFunctions('Vendor1099Misc2019RequestPageHandler')]
    [Scope('OnPrem')]
    procedure Misc1099ForYear2019RepShownFromIRS1099FormBoxPageWhenNECCodeDoesNotExist()
    var
        IRS1099FormBox: TestPage "IRS 1099 Form-Box";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 374401] A "Vendor 1099 Misc 2019" report shown from the IRS-100 Form Box page when "NEC-01" does not exist in the database

        Initialize();
        RemoveIRS1099UpgradeCodeYear2019();
        Commit();
        IRS1099FormBox.OpenEdit();
        IRS1099FormBox."Vendor 1099 Misc".Invoke();
    end;

    [Test]
    [HandlerFunctions('Vendor1099Misc2020RequestPageHandler')]
    [Scope('OnPrem')]
    procedure Misc1099ForYear2020RepShownFromIRS1099FormBoxPageWhenNECCodeExists()
    var
        IRS1099FormBox: TestPage "IRS 1099 Form-Box";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 374401] A "Vendor 1099 Misc 2019" report shown from the IRS-100 Form Box page when "NEC-01" code exists in the database

        Initialize();
        RemoveIRS1099UpgradeCodeYear2020();
        RemoveIRS1099UpgradeCodeYear2020February();
        InsertIRS1099Code(GetIRS1099UpgradeCode2020());
        Commit();
        IRS1099FormBox.OpenEdit();
        IRS1099FormBox."Vendor 1099 Misc".Invoke();
    end;

    [Test]
    [HandlerFunctions('Vendor1099Misc2021RequestPageHandler')]
    [Scope('OnPrem')]
    procedure Misc1099ForYear2021RepShownFromVendPage()
    var
        VendorList: TestPage "Vendor List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 412412] A "Vendor 1099 Misc 2022" report shown from the Vendor List page when "MISC-11" code exists in the database

        Initialize();
        InsertIRS1099Code(GetIRS1099UpgradeCode2020());
        InsertIRS1099Code(GetIRS1099UpgradeCode2020February());
        InsertIRS1099Code(GetIRS1099UpgradeCode2021());
        Commit();
        VendorList.OpenEdit();
        VendorList."Vendor 1099 Misc".Invoke();
    end;

    [Test]
    [HandlerFunctions('Vendor1099Misc2021RequestPageHandler')]
    [Scope('OnPrem')]
    procedure Misc1099ForYear2020RepShownFromIRS1099FormBoxPage()
    var
        IRS1099FormBox: TestPage "IRS 1099 Form-Box";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 412412] A "Vendor 1099 Misc 2019" 2021 shown from the IRS-100 Form Box page when "MISC-11" code exists in the database

        Initialize();
        InsertIRS1099Code(GetIRS1099UpgradeCode2020());
        InsertIRS1099Code(GetIRS1099UpgradeCode2020February());
        InsertIRS1099Code(GetIRS1099UpgradeCode2021());
        Commit();
        IRS1099FormBox.OpenEdit();
        IRS1099FormBox."Vendor 1099 Misc".Invoke();
    end;

    [Test]
    [HandlerFunctions('Vendor1099Misc2022RequestPageHandler')]
    [Scope('OnPrem')]
    procedure Misc1099ForYear2022RepShownFromVendPage()
    var
        VendorList: TestPage "Vendor List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 454897] A "Vendor 1099 Misc 2022" report shown from the Vendor List page when "MISC-16" code exists in the database

        Initialize();
        InsertIRS1099Code(GetIRS1099UpgradeCode2020());
        InsertIRS1099Code(GetIRS1099UpgradeCode2020February());
        InsertIRS1099Code(GetIRS1099UpgradeCode2021());
        InsertIRS1099Code(GetIRS1099UpgradeCode2022());
        Commit();
        VendorList.OpenEdit();
        VendorList."Vendor 1099 Misc".Invoke();
    end;

    [Test]
    [HandlerFunctions('Vendor1099Misc2022RequestPageHandler')]
    [Scope('OnPrem')]
    procedure Misc1099ForYear2022RepShownFromIRS1099FormBoxPage()
    var
        IRS1099FormBox: TestPage "IRS 1099 Form-Box";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 454897] A "Vendor 1099 Misc 2022" report shown from the IRS-100 Form Box page when "MISC-16" code exists in the database

        Initialize();
        InsertIRS1099Code(GetIRS1099UpgradeCode2020());
        InsertIRS1099Code(GetIRS1099UpgradeCode2020February());
        InsertIRS1099Code(GetIRS1099UpgradeCode2021());
        InsertIRS1099Code(GetIRS1099UpgradeCode2022());
        Commit();
        IRS1099FormBox.OpenEdit();
        IRS1099FormBox."Vendor 1099 Misc".Invoke();
    end;

    [Test]
    [HandlerFunctions('Vendor1099Int2022RequestPageHandler')]
    [Scope('OnPrem')]
    procedure Int1099ForYear2022RepShownFromVendPage()
    var
        VendorList: TestPage "Vendor List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 454897] A "Vendor 1099 Int 2022" report shown from the Vendor List page when upgrade for year 2022 has been executed

        Initialize();
        InsertIRS1099Code(GetIRS1099UpgradeCode2020());
        InsertIRS1099Code(GetIRS1099UpgradeCode2020February());
        InsertIRS1099Code(GetIRS1099UpgradeCode2021());
        InsertIRS1099Code(GetIRS1099UpgradeCode2022());
        Commit();
        VendorList.OpenEdit();
        VendorList."Vendor 1099 Int".Invoke();
    end;

    [Test]
    [HandlerFunctions('Vendor1099Int2022RequestPageHandler')]
    [Scope('OnPrem')]
    procedure Int1099ForYear2022RepShownFromIRS1099FormBoxPage()
    var
        IRS1099FormBox: TestPage "IRS 1099 Form-Box";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 454897] A "Vendor 1099 Int 2022" report shown from the IRS-100 Form Box page when upgrade for year 2022 has been executed

        Initialize();
        InsertIRS1099Code(GetIRS1099UpgradeCode2020());
        InsertIRS1099Code(GetIRS1099UpgradeCode2020February());
        InsertIRS1099Code(GetIRS1099UpgradeCode2021());
        InsertIRS1099Code(GetIRS1099UpgradeCode2022());
        Commit();
        IRS1099FormBox.OpenEdit();
        IRS1099FormBox."Vendor 1099 Int".Invoke();
    end;

    [Test]
    [HandlerFunctions('Vendor1099Div2022RequestPageHandler')]
    [Scope('OnPrem')]
    procedure Div1099ForYear2022RepShownFromVendPage()
    var
        VendorList: TestPage "Vendor List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 454897] A "Vendor 1099 Div 2022" report shown from the Vendor List page when upgrade for year 2022 has been executed

        Initialize();
        InsertIRS1099Code(GetIRS1099UpgradeCode2020());
        InsertIRS1099Code(GetIRS1099UpgradeCode2020February());
        InsertIRS1099Code(GetIRS1099UpgradeCode2021());
        InsertIRS1099Code(GetIRS1099UpgradeCode2022());
        Commit();
        VendorList.OpenEdit();
        VendorList."Vendor 1099 Div".Invoke();
    end;

    [Test]
    [HandlerFunctions('Vendor1099Div2022RequestPageHandler')]
    [Scope('OnPrem')]
    procedure Div1099ForYear2022RepShownFromIRS1099FormBoxPage()
    var
        IRS1099FormBox: TestPage "IRS 1099 Form-Box";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 454897] A "Vendor 1099 Div 2022" report shown from the IRS-100 Form Box page when upgrade for year 2022 has been executed

        Initialize();
        InsertIRS1099Code(GetIRS1099UpgradeCode2020());
        InsertIRS1099Code(GetIRS1099UpgradeCode2020February());
        InsertIRS1099Code(GetIRS1099UpgradeCode2021());
        InsertIRS1099Code(GetIRS1099UpgradeCode2022());
        Commit();
        IRS1099FormBox.OpenEdit();
        IRS1099FormBox."Vendor 1099 Div".Invoke();
    end;

    [Test]
    [HandlerFunctions('Vendor1099Nec2022RequestPageHandler')]
    [Scope('OnPrem')]
    procedure Nec1099ForYear2022RepShownFromVendPage()
    var
        VendorList: TestPage "Vendor List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 454897] A "Vendor 1099 Nec 2022" report shown from the Vendor List page when upgrade for year 2022 has been executed

        Initialize();
        InsertIRS1099Code(GetIRS1099UpgradeCode2020());
        InsertIRS1099Code(GetIRS1099UpgradeCode2020February());
        InsertIRS1099Code(GetIRS1099UpgradeCode2021());
        InsertIRS1099Code(GetIRS1099UpgradeCode2022());
        Commit();
        VendorList.OpenEdit();
        VendorList.RunVendor1099NecReport.Invoke();
    end;

    [Test]
    [HandlerFunctions('Vendor1099Nec2022RequestPageHandler')]
    [Scope('OnPrem')]
    procedure Nec1099ForYear2022RepShownFromIRS1099FormBoxPage()
    var
        IRS1099FormBox: TestPage "IRS 1099 Form-Box";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 454897] A "Vendor 1099 Nec 2022" report shown from the IRS-100 Form Box page when upgrade for year 2022 has been executed

        Initialize();
        InsertIRS1099Code(GetIRS1099UpgradeCode2020());
        InsertIRS1099Code(GetIRS1099UpgradeCode2020February());
        InsertIRS1099Code(GetIRS1099UpgradeCode2021());
        InsertIRS1099Code(GetIRS1099UpgradeCode2022());
        Commit();
        IRS1099FormBox.OpenEdit();
        IRS1099FormBox.RunVendor1099NecReport.Invoke();
    end;

    [Test]
    [HandlerFunctions('CustomNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CompliantNotificationWhenNo1099UpgradeIsRequired()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        IRS1099FormBoxPage: TestPage "IRS 1099 Form-Box";
    begin
        // [SCENARIO 493444] Stan sees the "You are compliant with the 1099 requirements" notification when no 1099 upgrade is required

        Initialize();
        InsertIRS1099Code(GetIRS1099UpgradeCode2019());
        InsertIRS1099Code(GetIRS1099UpgradeCode2020());
        InsertIRS1099Code(GetIRS1099UpgradeCode2020February());
        InsertIRS1099Code(GetIRS1099UpgradeCode2021());
        InsertIRS1099Code(GetIRS1099UpgradeCode2022());
        LibraryVariableStorage.Enqueue(IRS1099ComplianceMsg);
        IRS1099FormBoxPage.OpenView();
        IRS1099FormBoxPage.Close();
        LibraryVariableStorage.AssertEmpty();
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoCompliantNotificationIfDisableNotification()
    var
        MyNotifications: Record "My Notifications";
        IRS1099Management: Codeunit "IRS 1099 Management";
        IRS1099FormBoxPage: TestPage "IRS 1099 Form-Box";
    begin
        // [SCENARIO 493444] Stan do not see the "You are compliant with the 1099 requirements" notification if it is disable in my notification

        Initialize();
        InsertIRS1099Code(GetIRS1099UpgradeCode2019());
        InsertIRS1099Code(GetIRS1099UpgradeCode2020());
        InsertIRS1099Code(GetIRS1099UpgradeCode2020February());
        InsertIRS1099Code(GetIRS1099UpgradeCode2021());
        InsertIRS1099Code(GetIRS1099UpgradeCode2022());
        MyNotifications.Disable(IRS1099Management.GetIRS1099CompliantNotificationID());
        IRS1099FormBoxPage.OpenView();
        IRS1099FormBoxPage.Close();
    end;

    local procedure Initialize()
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        // Mimic changes before update for years after 2019 to test an upgrade scenarios
        IRS1099FormBox.SetFilter(Code, '*DIV*');
        IRS1099FormBox.DeleteAll();
        InsertIRS1099Code('DIV-05');
        InsertIRS1099Code('DIV-06');
        InsertIRS1099Code('DIV-08');
        InsertIRS1099Code('DIV-9');
        InsertIRS1099Code('DIV-10');
        IRS1099FormBox.SetFilter(Code, '*NEC*|MISC-11|MISC-16');
        IRS1099FormBox.DeleteAll();
    end;

    local procedure GetIRS1099UpgradeCode2019(): Code[10]
    begin
        exit('DIV-07');
    end;

    local procedure GetIRS1099UpgradeCode2020(): Code[10]
    begin
        exit('NEC-01');
    end;

    local procedure GetIRS1099UpgradeCode2020February(): Code[10]
    begin
        exit('NEC-04');
    end;

    local procedure GetIRS1099UpgradeCode2021(): Code[10]
    begin
        exit('MISC-11');
    end;

    local procedure GetIRS1099UpgradeCode2022(): Code[10]
    begin
        exit('MISC-16');
    end;

    local procedure RemoveIRS1099UpgradeCodeYear2019()
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        IRS1099FormBox.SetRange(Code, GetIRS1099UpgradeCode2019());
        IRS1099FormBox.DeleteAll();
    end;

    local procedure RemoveIRS1099UpgradeCodeYear2020()
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        IRS1099FormBox.SetRange(Code, GetIRS1099UpgradeCode2020());
        IRS1099FormBox.DeleteAll();
    end;

    local procedure RemoveIRS1099UpgradeCodeYear2020February()
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        IRS1099FormBox.SetRange(Code, GetIRS1099UpgradeCode2020February());
        IRS1099FormBox.DeleteAll();
    end;

    local procedure RemoveIRS1099UpgradeCodeYear2021()
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        IRS1099FormBox.SetRange(Code, GetIRS1099UpgradeCode2021());
        IRS1099FormBox.DeleteAll();
    end;

    local procedure RemoveIRS1099UpgradeCodeYear2022()
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        IRS1099FormBox.SetRange(Code, GetIRS1099UpgradeCode2022());
        IRS1099FormBox.DeleteAll();
    end;

    local procedure MockDataWithIRS1099Code(var Vendor: Record Vendor; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PurchaseHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var GenJournalLineAccount: Record "Gen. Journal Line"; var GenJournalLineBalAccount: Record "Gen. Journal Line"; IRSCode: Code[10])
    begin
        Vendor.Init();
        Vendor."No." := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("No."), DATABASE::Vendor);
        Vendor."IRS 1099 Code" := IRSCode;
        Vendor.Insert();

        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Vendor No." := Vendor."No.";
        VendorLedgerEntry."IRS 1099 Code" := Vendor."IRS 1099 Code";
        VendorLedgerEntry.Insert();

        PurchaseHeader.Init();
        PurchaseHeader."No." := LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("No."), DATABASE::"Purchase Header");
        PurchaseHeader."Pay-to Vendor No." := Vendor."No.";
        PurchaseHeader."IRS 1099 Code" := Vendor."IRS 1099 Code";
        PurchaseHeader.Insert();

        PurchInvHeader.Init();
        PurchInvHeader."No." := LibraryUtility.GenerateRandomCode(PurchInvHeader.FieldNo("No."), DATABASE::"Purch. Inv. Header");
        PurchInvHeader."Pay-to Vendor No." := Vendor."No.";
        PurchInvHeader."IRS 1099 Code" := Vendor."IRS 1099 Code";
        PurchInvHeader.Insert();

        PurchCrMemoHdr.Init();
        PurchCrMemoHdr."No." := LibraryUtility.GenerateRandomCode(PurchCrMemoHdr.FieldNo("No."), DATABASE::"Purch. Cr. Memo Hdr.");
        PurchCrMemoHdr."Pay-to Vendor No." := Vendor."No.";
        PurchCrMemoHdr."IRS 1099 Code" := Vendor."IRS 1099 Code";
        PurchCrMemoHdr.Insert();

        GenJournalLineAccount.Init();
        GenJournalLineAccount."Line No." := LibraryUtility.GetNewRecNo(GenJournalLineAccount, GenJournalLineAccount.FieldNo("Line No."));
        GenJournalLineAccount."Account Type" := GenJournalLineAccount."Account Type"::Vendor;
        GenJournalLineAccount."Account No." := Vendor."No.";
        GenJournalLineAccount."IRS 1099 Code" := Vendor."IRS 1099 Code";
        GenJournalLineAccount.Insert();

        GenJournalLineBalAccount.Init();
        GenJournalLineBalAccount."Line No." :=
          LibraryUtility.GetNewRecNo(GenJournalLineBalAccount, GenJournalLineBalAccount.FieldNo("Line No."));
        GenJournalLineBalAccount."Account Type" := GenJournalLineBalAccount."Account Type"::Vendor;
        GenJournalLineBalAccount."Account No." := Vendor."No.";
        GenJournalLineBalAccount."IRS 1099 Code" := Vendor."IRS 1099 Code";
        GenJournalLineBalAccount.Insert();
    end;

    local procedure MockAppliedPmtEntry(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        MockVendLedgEntry(VendorLedgerEntry, LibraryPurchase.CreateVendorNo(), VendorLedgerEntry."Document Type"::Payment);
        MockApplnDtldVendLedgerEntry(
          DetailedVendorLedgEntry, VendorLedgerEntry, LibraryRandom.RandInt(100), LibraryRandom.RandInt(100));

        MockVendLedgEntry(VendorLedgerEntry, VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Document Type"::Invoice);
        MockApplnDtldVendLedgerEntry(
          DetailedVendorLedgEntry, VendorLedgerEntry,
          DetailedVendorLedgEntry."Transaction No.", DetailedVendorLedgEntry."Application No.");
    end;

    local procedure MockVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendNo: Code[20]; DocType: Enum "Gen. Journal Document Type")
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Vendor No." := VendNo;
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry."Document Type" := DocType;
        VendorLedgerEntry."IRS 1099 Code" := 'DIV-05';
        VendorLedgerEntry.Insert();
    end;

    local procedure MockApplnDtldVendLedgerEntry(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; TransNo: Integer; AppNo: Integer)
    begin
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, DetailedVendorLedgEntry.FieldNo("Entry No."));
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
        DetailedVendorLedgEntry."Vendor No." := VendorLedgerEntry."Vendor No.";
        DetailedVendorLedgEntry."Entry Type" := DetailedVendorLedgEntry."Entry Type"::Application;
        DetailedVendorLedgEntry."Transaction No." := TransNo;
        DetailedVendorLedgEntry."Application No." := AppNo;
        DetailedVendorLedgEntry.Amount := -LibraryRandom.RandDec(100, 2);
        DetailedVendorLedgEntry."Amount (LCY)" := -DetailedVendorLedgEntry.Amount;
        DetailedVendorLedgEntry."Ledger Entry Amount" := true;
        DetailedVendorLedgEntry.Insert();
        VendorLedgerEntry."IRS 1099 Amount" := DetailedVendorLedgEntry.Amount;
        VendorLedgerEntry.Modify();
    end;

    local procedure InsertIRS1099Code(NewIRSCode: Code[10])
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        IRS1099FormBox.Init();
        IRS1099FormBox.Code := NewIRSCode;
        IRS1099FormBox.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, 10500, 'OnBeforeUpgradeFormBoxes', '', false, false)]
    local procedure SetCanCreateTaskOnBeforeUpgradeFormBoxes(var Handled: Boolean; var CreateTask: Boolean)
    begin
        CreateTask := true;
        Handled := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure JobQueueEntryCardPageHandler(var JobQueueEntryCard: TestPage "Job Queue Entry Card")
    begin
        JobQueueEntryCard."Object Type to Run".AssertEquals('Codeunit');
        JobQueueEntryCard."Object ID to Run".AssertEquals(10501);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Text: Text)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Text);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
        Assert.ExpectedMessage(StrSubstNo(NotificationMsg, LibraryVariableStorage.DequeueText()), Notification.Message);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure CustomNotificationHandler(var Notification: Notification): Boolean
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Notification.Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099DivRequestPageHandler(var Vendor1099Div: TestRequestPage "Vendor 1099 Div")
    begin
        Vendor1099Div.SaveAsExcel(LibraryVariableStorage.DequeueText());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099Misc2019RequestPageHandler(var Vendor1099Misc: TestRequestPage "Vendor 1099 Misc")
    begin
        Vendor1099Misc.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099Misc2020RequestPageHandler(var Vendor1099Misc2020: TestRequestPage "Vendor 1099 Misc 2020")
    begin
        Vendor1099Misc2020.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099Misc2021RequestPageHandler(var Vendor1099Misc2021: TestRequestPage "Vendor 1099 Misc 2021")
    begin
        Vendor1099Misc2021.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099Misc2022RequestPageHandler(var Vendor1099Misc2022: TestRequestPage "Vendor 1099 Misc 2022")
    begin
        Vendor1099Misc2022.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099Int2022RequestPageHandler(var Vendor1099Int2022: TestRequestPage "Vendor 1099 Int 2022")
    begin
        Vendor1099Int2022.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099Div2022RequestPageHandler(var Vendor1099Div2022: TestRequestPage "Vendor 1099 Div 2022")
    begin
        Vendor1099Div2022.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099Nec2022RequestPageHandler(var Vendor1099Nec2022: TestRequestPage "Vendor 1099 Nec 2022")
    begin
        Vendor1099Nec2022.Cancel().Invoke();
    end;
}
#endif
