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
        NotificationMsg: Label 'The list of 1099 form boxes is not up to date.';
        ConfirmIRS1099CodeUpdateQst: Label 'One or more entries have been posted with IRS 1099 code %1.\\Do you want to continue and update all the data associated with this vendor and the existing IRS 1099 code with the new code, %2?', Comment = '%1 - old code;%2 - new code';
        BlockIfUpgradeNeededErr: Label 'You must update the form boxes in the 1099 Forms-Boxes window before you can run this report.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UpgradeOfIRS1099CodesNeededByDefault()
    var
        IRS1099Management: Codeunit "IRS 1099 Management";
    begin
        // [FEAUTURE] [UT]
        // [SCENARIO 283821] Make sure that upgrade is needed if IRS 1099 code "DIV-07" does not exists

        Initialize;
        Assert.IsTrue(IRS1099Management.UpgradeNeeded, 'Upgrade not needed');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NotificationThrownOnIRS1099FormBoxPage()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        IRS1099FormBoxPage: TestPage "IRS 1099 Form-Box";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 283821] Notification of upgrade thrown on opening IRS 1099 Form Box Page if code IRS 1099 code "DIV-07" does not exist

        Initialize;
        IRS1099FormBoxPage.OpenView;
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NotificationNotShowOnIRS1099FormBoxPage()
    var
        IRS1099FormBoxPage: TestPage "IRS 1099 Form-Box";
        IRSCode: Code[10];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 283821] Notification of upgrade not shown on opening IRS 1099 Form Box Page if code IRS 1099 code "DIV-07" exists

        Initialize;
        IRSCode := GetIRS1099UpgradeCode;
        InsertIRS1099Code(IRSCode);

        IRS1099FormBoxPage.OpenView;
        IRS1099FormBoxPage.FILTER.SetFilter(Code, IRSCode);
        IRS1099FormBoxPage.Code.AssertEquals(IRSCode);

        RemoveIRS1099UpgradeCode;
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

        Initialize;
        RemoveIRS1099UpgradeCode;

        // [GIVEN] TASKSCHEDULER.CANCREATETASK is TRUE
        BindSubscription(IRS1099UpgradeTest);
        LibraryVariableStorage.Enqueue(UpgradeFormBoxesScheduledMsg);

        // [WHEN] Upgrade form boxes
        IRS1099Management.UpgradeFormBoxes;

        // [THEN] Job Queue Entry created and opened in Job Queue Entry Card
        // Verify by JobQueueEntryCardPageHandler

        LibraryVariableStorage.AssertEmpty;
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

        Initialize;
        RemoveIRS1099UpgradeCode;

        // [GIVEN] TASKSCHEDULER.CANCREATETASK is FALSE
        LibraryVariableStorage.Enqueue(ConfirmUpgradeNowQst);
        LibraryVariableStorage.Enqueue(FormBoxesUpgradedMsg);

        // [WHEN] Upgrade form boxes
        IRS1099Management.UpgradeFormBoxes;

        // [THEN] Confirmation about upgrade raised
        // Verify by ConfirmationHandler
        // [THEN] Upgrade performed and new code is added
        Assert.IsFalse(IRS1099Management.UpgradeNeeded, 'Upgrade was not performed');

        // [THEN] Message about successfull upgrade shown
        // Verify by MessageHandler
        LibraryVariableStorage.AssertEmpty;

        // Tear down
        RemoveIRS1099UpgradeCode;
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

        Initialize;
        IRSCode := LibraryUtility.GenerateGUID;
        InsertIRS1099Code(IRSCode);

        Vendor.Init();
        Vendor."No." := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("No."), DATABASE::Vendor);
        Vendor."IRS 1099 Code" := IRSCode;
        Vendor.Insert();

        IRSCode := LibraryUtility.GenerateGUID;
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

        Initialize;
        OldIRSCode := LibraryUtility.GenerateGUID;
        InsertIRS1099Code(OldIRSCode);
        MockDataWithIRS1099Code(
          Vendor, VendorLedgerEntry, PurchaseHeader, PurchInvHeader, PurchCrMemoHdr,
          GenJournalLineAccount, GenJournalLineBalAccount, OldIRSCode);
        NewIRSCode := LibraryUtility.GenerateGUID;
        InsertIRS1099Code(NewIRSCode);

        LibraryVariableStorage.Enqueue(StrSubstNo(ConfirmIRS1099CodeUpdateQst, Vendor."IRS 1099 Code", NewIRSCode));
        Vendor.Validate("IRS 1099 Code", NewIRSCode);

        VendorLedgerEntry.Find;
        VendorLedgerEntry.TestField("IRS 1099 Code", Vendor."IRS 1099 Code");

        PurchaseHeader.Find;
        PurchaseHeader.TestField("IRS 1099 Code", Vendor."IRS 1099 Code");

        PurchInvHeader.Find;
        PurchInvHeader.TestField("IRS 1099 Code", Vendor."IRS 1099 Code");

        PurchCrMemoHdr.Find;
        PurchCrMemoHdr.TestField("IRS 1099 Code", Vendor."IRS 1099 Code");

        GenJournalLineAccount.Find;
        GenJournalLineAccount.TestField("IRS 1099 Code", Vendor."IRS 1099 Code");

        GenJournalLineBalAccount.Find;
        GenJournalLineBalAccount.TestField("IRS 1099 Code", Vendor."IRS 1099 Code");

        LibraryVariableStorage.AssertEmpty;
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

        Initialize;
        RemoveIRS1099UpgradeCode;
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

        Initialize;
        RemoveIRS1099UpgradeCode;
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

        Initialize;
        IRSCode := GetIRS1099UpgradeCode;
        InsertIRS1099Code(IRSCode);

        // [GIVEN] Payment applied to invoice with "IRS 1099 Code" = "DIV-05" and "IRS Amount" = 100
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);
        LibraryVariableStorage.Enqueue(LibraryReportValidation.GetFileName);
        MockAppliedPmtEntry(DetailedVendorLedgEntry);
        Vendor.SetRange("No.", DetailedVendorLedgEntry."Vendor No.");
        Vendor1099Div.SetTableView(Vendor);
        Vendor1099Div.Run;

        // [WHEN] Print "Vendor 1099 Div" report
        LibraryReportValidation.OpenFile;

        // [THEN] Amount = 100 printed for "DIV-05" code
        LibraryReportValidation.VerifyCellValueOnWorksheet(15, 4, Format(-DetailedVendorLedgEntry.Amount), '1');

        LibraryVariableStorage.AssertEmpty;
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

        Initialize;
        IRSCode := GetIRS1099UpgradeCode;
        InsertIRS1099Code(IRSCode);

        // [GIVEN] Payment applied to invoice with "IRS 1099 Code" = "DIV-05" and "IRS Amount" = 100
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);
        LibraryVariableStorage.Enqueue(LibraryReportValidation.GetFileName);
        MockAppliedPmtEntry(DetailedVendorLedgEntry);
        Vendor.SetRange("No.", DetailedVendorLedgEntry."Vendor No.");
        Vendor1099Div.SetTableView(Vendor);
        Vendor1099Div.Run;

        // [WHEN] Print "Vendor 1099 Div" report
        LibraryReportValidation.OpenFile;

        // [THEN] Amount = 100 printed for "DIV-05" code
        LibraryReportValidation.VerifyCellValueOnWorksheet(15, 4, Format(-DetailedVendorLedgEntry.Amount), '1');

        LibraryVariableStorage.AssertEmpty;
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

        Initialize;
        MockDataWithIRS1099Code(
          Vendor, VendorLedgerEntry, PurchaseHeader, PurchInvHeader, PurchCrMemoHdr, GenJournalLineAccount, GenJournalLineBalAccount, '');
        NewIRSCode := LibraryUtility.GenerateGUID;
        InsertIRS1099Code(NewIRSCode);

        Vendor.Validate("IRS 1099 Code", NewIRSCode);

        VendorLedgerEntry.Find;
        VendorLedgerEntry.TestField("IRS 1099 Code", '');

        PurchaseHeader.Find;
        PurchaseHeader.TestField("IRS 1099 Code", '');

        PurchInvHeader.Find;
        PurchInvHeader.TestField("IRS 1099 Code", '');

        PurchCrMemoHdr.Find;
        PurchCrMemoHdr.TestField("IRS 1099 Code", '');

        GenJournalLineAccount.Find;
        GenJournalLineAccount.TestField("IRS 1099 Code", '');

        GenJournalLineBalAccount.Find;
        GenJournalLineBalAccount.TestField("IRS 1099 Code", '');
    end;

    local procedure Initialize()
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        // Mimic changes before update for year 2019 to test an upgrade scenarios
        IRS1099FormBox.SetFilter(Code, '*DIV*');
        IRS1099FormBox.DeleteAll();
        InsertIRS1099Code('DIV-05');
        InsertIRS1099Code('DIV-06');
        InsertIRS1099Code('DIV-08');
        InsertIRS1099Code('DIV-9');
        InsertIRS1099Code('DIV-10');
    end;

    local procedure GetIRS1099UpgradeCode(): Code[10]
    begin
        exit('DIV-07');
    end;

    local procedure RemoveIRS1099UpgradeCode()
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        IRS1099FormBox.SetRange(Code, GetIRS1099UpgradeCode);
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
        MockVendLedgEntry(VendorLedgerEntry, LibraryPurchase.CreateVendorNo, VendorLedgerEntry."Document Type"::Payment);
        MockApplnDtldVendLedgerEntry(
          DetailedVendorLedgEntry, VendorLedgerEntry, LibraryRandom.RandInt(100), LibraryRandom.RandInt(100));

        MockVendLedgEntry(VendorLedgerEntry, VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Document Type"::Invoice);
        MockApplnDtldVendLedgerEntry(
          DetailedVendorLedgEntry, VendorLedgerEntry,
          DetailedVendorLedgEntry."Transaction No.", DetailedVendorLedgEntry."Application No.");
    end;

    local procedure MockVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendNo: Code[20]; DocType: Option)
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Vendor No." := VendNo;
        VendorLedgerEntry."Posting Date" := WorkDate;
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
    [Scope('OnPrem')]
    procedure SetCanCreateTaskOnBeforeUpgradeFormBoxes(var Handled: Boolean; var CreateTask: Boolean)
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
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText, Text);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
        Assert.ExpectedMessage(NotificationMsg, Notification.Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText, Question);
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099DivRequestPageHandler(var Vendor1099Div: TestRequestPage "Vendor 1099 Div")
    begin
        Vendor1099Div.SaveAsExcel(LibraryVariableStorage.DequeueText);
    end;
}

