codeunit 135952 "Reten. Pol. Upgrade Test"
{
    Subtype = Test;

    var
        LibraryAssert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    [Test]
    procedure TestSentNotificationEntryRetentionPolicyUpdated()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetentionPeriod: Record "Retention Period";
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
    begin
        // Init
        Initialize();

        // Setup
        RetentionPolicySetup.SetRange("Table Id", Database::"Sent Notification Entry");
        RetentionPolicySetup.DeleteAll();

        // Exercise
        RetentionPolicySetup.Init();
        RetentionPolicySetup.Validate("Table Id", Database::"Sent Notification Entry");
        RetentionPolicySetup.Insert(true);

        // Verify
        RetentionPolicySetupLine.Get(Database::"Sent Notification Entry", 10000);
        LibraryAssert.IsFalse(RetentionPolicySetupLine.IsLocked(), 'Retention Policy Line shouldn''t be locked');
        RetentionPeriod.Get(RetentionPolicySetupLine."Retention Period");
        LibraryAssert.AreEqual(Format(Enum::"Retention Period Enum"::"6 Months"), Format(RetentionPeriod."Retention Period"), 'Incorrect period for retention policy setup line');
    end;

    [Test]
    procedure TestChangeLogRetentionPolicyUpdated()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
        ChangeLogEntry: Record "Change Log Entry";
    begin
        // Init
        Initialize();

        // Setup
        RetentionPolicySetup.SetRange("Table Id", Database::"Change Log Entry");
        RetentionPolicySetup.DeleteAll();

        // Exercise
        RetentionPolicySetup."Table Id" := Database::"Change Log Entry";
        RetentionPolicySetup.Insert(true);

        // Verify
        RetentionPolicySetupLine.Get(Database::"Change Log Entry", 10000);
        LibraryAssert.IsTrue(RetentionPolicySetupLine.IsLocked(), 'Retention Policy Line should be locked');
        ChangeLogEntry.SetView(RetentionPolicySetupLine.GetTableFilterView());
        LibraryAssert.AreEqual(Format(true), ChangeLogEntry.GetFilter(Protected), 'The Filter View on the retention policy line is incorrect.');
        LibraryAssert.AreEqual(UpperCase(Format("Retention Period Enum"::"1 Year")), RetentionPolicySetupLine."Retention Period", 'Incorrect period for retention policy setup line');

        RetentionPolicySetupLine.Get(Database::"Change Log Entry", 20000);
        LibraryAssert.IsTrue(RetentionPolicySetupLine.IsLocked(), 'Retention Policy Line should be locked');
        ChangeLogEntry.SetView(RetentionPolicySetupLine.GetTableFilterView());
        LibraryAssert.AreEqual(StrSubstNo('%1|%2', "Field Log Entry Feature"::"Monitor Sensitive Fields", "Field Log Entry Feature"::All), ChangeLogEntry.GetFilter("Field Log Entry Feature"), 'The Filter View on the retention policy line is incorrect.');
        LibraryAssert.AreEqual(UpperCase(Format("Retention Period Enum"::"28 Days")), RetentionPolicySetupLine."Retention Period", 'Incorrect period for retention policy setup line');

        RetentionPolicySetupLine.Get(Database::"Change Log Entry", 30000);
        LibraryAssert.IsFalse(RetentionPolicySetupLine.IsLocked(), 'Retention Policy Line should be locked');
        ChangeLogEntry.SetView(RetentionPolicySetupLine.GetTableFilterView());
        LibraryAssert.AreEqual(Format(false), ChangeLogEntry.GetFilter(Protected), 'The Filter View on the retention policy line is incorrect.');
        LibraryAssert.AreEqual(UpperCase(Format("Retention Period Enum"::"1 Year")), RetentionPolicySetupLine."Retention Period", 'Incorrect period for retention policy setup line');
    end;

    [Test]
    procedure TestRegisteredWhseActivityHdrRetentionPolicyUpdated()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
    begin
        // Init
        Initialize();

        // Setup
        RetentionPolicySetup.SetRange("Table Id", Database::"Registered Whse. Activity Hdr.");
        RetentionPolicySetup.DeleteAll();

        // Exercise
        Clear(RetentionPolicySetup);
        RetentionPolicySetup.Validate("Table Id", Database::"Registered Whse. Activity Hdr.");
        RetentionPolicySetup.Insert(true);

        // Verify
        LibraryAssert.AreEqual(RegisteredWhseActivityHdr.FieldNo("Registering Date"), RetentionPolicySetup."Date Field No.", 'Date Field No. is incorrect initialized');
    end;

    [Test]
    procedure TestPostedWhseShipmentHeaderRetentionPolicyUpdated()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
    begin
        // Init
        Initialize();

        // Setup
        RetentionPolicySetup.SetRange("Table Id", Database::"Posted Whse. Shipment Header");
        RetentionPolicySetup.DeleteAll();

        // Exercise
        Clear(RetentionPolicySetup);
        RetentionPolicySetup.Validate("Table Id", Database::"Posted Whse. Shipment Header");
        RetentionPolicySetup.Insert(true);

        // Verify
        LibraryAssert.AreEqual(PostedWhseShipmentHeader.FieldNo("Posting Date"), RetentionPolicySetup."Date Field No.", 'Date Field No. is incorrect initialized');
    end;

    [Test]
    procedure TestPostedWhseReceiptHeaderRetentionPolicyUpdated()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
    begin
        // Init
        Initialize();

        // Setup
        RetentionPolicySetup.SetRange("Table Id", Database::"Posted Whse. Receipt Header");
        RetentionPolicySetup.DeleteAll();

        // Exercise
        RetentionPolicySetup."Table Id" := Database::"Posted Whse. Receipt Header";
        RetentionPolicySetup.Insert(true);

        // Verify
        RetentionPolicySetupLine.Get(Database::"Posted Whse. Receipt Header", 10000);
        LibraryAssert.IsTrue(RetentionPolicySetupLine.IsLocked(), 'Retention Policy Line should be locked');
        PostedWhseReceiptHeader.SetView(RetentionPolicySetupLine.GetTableFilterView());
        LibraryAssert.AreEqual(StrSubstNo('%1', PostedWhseReceiptHeader."Document Status"::"Partially Put Away"), PostedWhseReceiptHeader.GetFilter("Document Status"), 'The Filter View on the retention policy line is incorrect.');
        LibraryAssert.AreEqual(UpperCase(Format(Enum::"Retention Period Enum"::"Never Delete")), RetentionPolicySetupLine."Retention Period", 'Incorrect period for retention policy setup line');

        RetentionPolicySetupLine.Get(Database::"Posted Whse. Receipt Header", 20000);
        LibraryAssert.IsFalse(RetentionPolicySetupLine.IsLocked(), 'Retention Policy Line shouldn''t be locked');
        PostedWhseReceiptHeader.SetView(RetentionPolicySetupLine.GetTableFilterView());
        LibraryAssert.AreEqual(Format(PostedWhseReceiptHeader."Document Status"::"Completely Put Away"), PostedWhseReceiptHeader.GetFilter("Document Status"), 'The Filter View on the retention policy line is incorrect.');
        LibraryAssert.AreEqual(UpperCase(Format("Retention Period Enum"::"1 Year")), RetentionPolicySetupLine."Retention Period", 'Incorrect period for retention policy setup line');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        Commit();
        IsInitialized := true;
    end;
}