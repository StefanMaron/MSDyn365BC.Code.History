codeunit 134343 "UI Ledger Entries Page"
{
    Permissions = TableData "G/L Entry" = i,
                  TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = i,
                  TableData "Change Log Entry" = i,
                  TableData "Issued Reminder Header" = i,
                  TableData "Issued Fin. Charge Memo Header" = i;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [UI]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        ExportedToPaymentFileEditableErr: Label 'Exported to Payment File field must be editable.';
        DescriptionEditableErr: Label 'Description field must be editable.';
        GLEntryExistsErr: Label 'You cannot delete change log entry %1 because G/L entry %2 exists.';
	    LibrarySales: Codeunit "Library - Sales";

    [Test]
    [Scope('OnPrem')]
    procedure ChangeExportedToPaymentLineOnCustLedgEntriesPage()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        EntryNo: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 273543] Stan can change value of "Exported to Payment File" on Customer Ledger Entries page

        // [GIVEN] Customer Ledger Entry
        EntryNo := MockCustLedgEntry;

        // [GIVEN] Opened Customer Ledger Entries page
        CustomerLedgerEntries.OpenEdit;
        CustomerLedgerEntries.FILTER.SetFilter("Entry No.", Format(EntryNo));
        Assert.IsTrue(CustomerLedgerEntries."Exported to Payment File".Editable, ExportedToPaymentFileEditableErr);

        // [WHEN] Mark "Exported to Payment File" on Customer Ledger Entries page
        CustomerLedgerEntries."Exported to Payment File".SetValue(true);
        CustomerLedgerEntries.Close;

        // [THEN] "Exported to Payment File" is true in Customer Ledger Entry
        CustLedgerEntry.Get(EntryNo);
        CustLedgerEntry.TestField("Exported to Payment File");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeExportedToPaymentLineOnVendLedgEntriesPage()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        EntryNo: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 273543] Stan can change value of "Exported to Payment File" on Vendor Ledger Entries page

        // [GIVEN] Vendor Ledger Entry
        EntryNo := MockVendLedgEntry;

        // [GIVEN] Opened Vendor Ledger Entries page
        VendorLedgerEntries.OpenEdit;
        VendorLedgerEntries.FILTER.SetFilter("Entry No.", Format(EntryNo));
        Assert.IsTrue(VendorLedgerEntries."Exported to Payment File".Editable, ExportedToPaymentFileEditableErr);

        // [WHEN] Mark "Exported to Payment File" on Vendor Ledger Entries page
        VendorLedgerEntries."Exported to Payment File".SetValue(true);
        VendorLedgerEntries.Close;

        // [THEN] "Exported to Payment File" is true in Vendor Ledger Entry
        VendorLedgerEntry.Get(EntryNo);
        VendorLedgerEntry.TestField("Exported to Payment File");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditGLEntryDescription()
    var
        GLEntry: Record "G/L Entry";
        ChangeLogEntry: Record "Change Log Entry";
        GeneralLedgerEntries: TestPage "General Ledger Entries";
        EntryNo: Integer;
        OldDesctiption: Text;
        NewDesctiption: Text;
    begin
        // [FEATURE] [General Ledger]
        // [SCENARIO 286946] Stan is able to change description of G/L entry

        // [GIVEN] General Ledger Entry with Descirption = "Old Description"
        OldDesctiption := LibraryUtility.GenerateRandomText(MaxStrLen(GLEntry.Description));
        EntryNo := MockGLEntryWithDescription(OldDesctiption);

        // [GIVEN] Opened General Ledger Entries page
        GeneralLedgerEntries.OpenEdit;
        GeneralLedgerEntries.FILTER.SetFilter("Entry No.", Format(EntryNo));
        Assert.IsTrue(GeneralLedgerEntries.Description.Editable, DescriptionEditableErr);

        // [WHEN] Description is being changed to "New Description"
        NewDesctiption := LibraryUtility.GenerateRandomText(MaxStrLen(GLEntry.Description));
        GeneralLedgerEntries.Description.SetValue(
          CopyStr(NewDesctiption, 1, MaxStrLen(GLEntry.Description)));
        GeneralLedgerEntries.Close;

        // [THEN] Desctiption is "New Description" in General Ledger Entry
        GLEntry.Get(EntryNo);
        GLEntry.TestField(Description, NewDesctiption);

        // [THEN] Change log entry created with "Protected" = "Yes"
        FindChangeLogEntry(ChangeLogEntry, EntryNo, GLEntry.FieldNo(Description));
        ChangeLogEntry.TestField(Protected, true);
        VerifyChangeLogEntry(ChangeLogEntry, OldDesctiption, NewDesctiption);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,DeleteChangeLogeRPH,ErrorMessagesMPH')]
    [Scope('OnPrem')]
    procedure DeleteChangeLogEntriesForGLEntry()
    var
        ChangeLogEntry: Record "Change Log Entry";
        GLEntryNo: Integer;
        ChangeLogEntryNo: Integer;
    begin
        // [FEATURE] [General Ledger]
        // [SCENARIO 306088] User is not able to delete change log entries related to existent G/L Entry
        Initialize;

        // [GIVEN] Change Log Entries "1" and "2" related to table Customer
        MockChangeLogEntries(ChangeLogEntry, DATABASE::Customer, LibraryRandom.RandIntInRange(3, 5));
        // [GIVEN] General Ledger Entry "123" with Descirption = "Old Description"
        // [GIVEN] Description of G/L entry "123" is changed to "New Description" which leads to Change Log Entry "3" related to G/L entry "123"
        CreateUpdateGLEntryDescription(GLEntryNo, ChangeLogEntryNo);

        // [WHEN] User run Change Log - Delete report for all records
        LibraryVariableStorage.Enqueue(StrSubstNo(GLEntryExistsErr, ChangeLogEntryNo, GLEntryNo));
        RunDeleteChangeLogEntries;

        // [THEN] Change log entries "1" and "2" are deleted
        Assert.RecordIsEmpty(ChangeLogEntry);
        // [THEN] Change log entry "3" is not deleted
        Assert.IsTrue(ChangeLogEntry.Get(ChangeLogEntryNo), 'Change log entry must not be deleted');
        // [THEN] Confirm "One or more entries cannot be deleted. Do you want to open the list of errors?"
        // [THEN] Error Messages page contains records related to Change Log Entry "3"
        // Verification in the ErrorMessagesMPH

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ChangeLogEntriesMPH')]
    [Scope('OnPrem')]
    procedure GLEntryShowChangeHistory()
    var
        GLEntry: Record "G/L Entry";
        GeneralLedgerEntries: TestPage "General Ledger Entries";
        EntryNo: Integer;
        OldDesctiption: Text;
        NewDesctiption: Text;
    begin
        // [FEATURE] [General Ledger]
        // [SCENARIO 306088] User can open the history of G/L Entry Descripton update
        Initialize;

        // [GIVEN] General Ledger Entry "123" with Descirption = "Old Description"
        OldDesctiption := LibraryUtility.GenerateRandomText(MaxStrLen(GLEntry.Description));
        EntryNo := MockGLEntryWithDescription(OldDesctiption);

        // [GIVEN] Opened General Ledger Entries page
        GeneralLedgerEntries.OpenEdit;
        GeneralLedgerEntries.FILTER.SetFilter("Entry No.", Format(EntryNo));

        // [GIVEN] Description is being changed to "New Description"
        NewDesctiption := LibraryUtility.GenerateRandomText(MaxStrLen(GLEntry.Description));
        GeneralLedgerEntries.Description.SetValue(
          CopyStr(NewDesctiption, 1, MaxStrLen(GLEntry.Description)));
        GeneralLedgerEntries.OK.Invoke;

        // [WHEN] Action "Show change history" is being selected
        GeneralLedgerEntries.OpenEdit;
        GeneralLedgerEntries.FILTER.SetFilter("Entry No.", Format(EntryNo));
        GeneralLedgerEntries.ShowChangeHistory.Invoke;

        // [THEN] Change log entries page opened filtered by "Table No." = "17" and "Entry No." = "123"
        Assert.AreEqual(Format(DATABASE::"G/L Entry"), LibraryVariableStorage.DequeueText, 'Invalid filter by Table No.');
        Assert.AreEqual(Format(EntryNo), LibraryVariableStorage.DequeueText, 'Invalid filter by Entry No.');

        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
    end;

    local procedure CreateUpdateGLEntryDescription(var GLEntryNo: Integer; var ChangeLogEntryNo: Integer)
    var
        DummyGLEntry: Record "G/L Entry";
        ChangeLogEntry: Record "Change Log Entry";
        GeneralLedgerEntries: TestPage "General Ledger Entries";
    begin
        GLEntryNo := MockGLEntryWithDescription(LibraryUtility.GenerateRandomText(MaxStrLen(DummyGLEntry.Description)));
        GeneralLedgerEntries.OpenEdit;
        GeneralLedgerEntries.FILTER.SetFilter("Entry No.", Format(GLEntryNo));
        GeneralLedgerEntries.Description.SetValue(
          LibraryUtility.GenerateRandomText(MaxStrLen(DummyGLEntry.Description)));
        GeneralLedgerEntries.Close;

        FindChangeLogEntry(ChangeLogEntry, GLEntryNo, DummyGLEntry.FieldNo(Description));
        ChangeLogEntryNo := ChangeLogEntry."Entry No.";
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectShowDocumentForFinanceChargeMemoInCustomerLE()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        IssuedFinanceChargeMemo: TestPage "Issued Finance Charge Memo";
    begin
        // [FEATURE] [Finance Charge Memo]
        // [SCENARIO 337539] Run "Show Document" from Customer Ledger Entries page for Finance Charge Memo

        // [GIVEN] Created Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Created Issued Finance Charge Memo "IFCM"
        CreateIssuedFinChargeMemoHeader(IssuedFinChargeMemoHeader, Customer."No.");

        // [GIVEN] Issued Finance Charge Memo has related Customer Ledger Entry
        MockCustomerLedgerEntryWithDocNo(
          CustLedgerEntry, Customer."No.", CustLedgerEntry."Document Type"::"Finance Charge Memo", IssuedFinChargeMemoHeader."No.");

        // [WHEN] Run "Show Document" function
        IssuedFinanceChargeMemo.Trap();
        CustLedgerEntry.ShowDoc();

        // [THEN] Page Issued Finance Charge Memo with "IFCM" is opened
        IssuedFinanceChargeMemo."No.".AssertEquals(IssuedFinChargeMemoHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectShowDocumentForReminderInCustomerLE()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminder: TestPage "Issued Reminder";
    begin
        // [FEATURE] [Reminder]
        // [SCENARIO 337539] Run "Show Document" from Customer Ledger Entries page for Reminder

        // [GIVEN] Created Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Created Issued Reminder Header "R"
        CreateIssuedReminderHeader(IssuedReminderHeader, Customer."No.");

        // [GIVEN] Issued Reminder has related Customer Ledger Entry
        MockCustomerLedgerEntryWithDocNo(
          CustLedgerEntry, Customer."No.", CustLedgerEntry."Document Type"::Reminder, IssuedReminderHeader."No.");

        // [WHEN] Run "Show Document" function
        IssuedReminder.Trap();
        CustLedgerEntry.ShowDoc();

        // [THEN] Page Issued Reminder with "R" is opened
        IssuedReminder."No.".AssertEquals(IssuedReminderHeader."No.");
    end;

    local procedure FindChangeLogEntry(var ChangeLogEntry: Record "Change Log Entry"; EntryNo: Integer; FieldNo: Integer)
    begin
        ChangeLogEntry.SetRange("Table No.", DATABASE::"G/L Entry");
        ChangeLogEntry.SetRange("Primary Key Field 1 Value", Format(EntryNo, 0, 9));
        ChangeLogEntry.SetRange("Field No.", FieldNo);
        ChangeLogEntry.FindFirst;
    end;

    local procedure MockChangeLogEntries(var ChangeLogEntry: Record "Change Log Entry"; TableNo: Integer; NumberOfEntries: Integer)
    var
        i: Integer;
        EntryNo: Integer;
        FirstEntryNo: Integer;
        LastEntryNo: Integer;
    begin
        if ChangeLogEntry.FindLast then;
        EntryNo := ChangeLogEntry."Entry No.";
        FirstEntryNo := EntryNo + 1;
        for i := 1 to NumberOfEntries do begin
            EntryNo := EntryNo + 1;
            ChangeLogEntry.Init();
            ChangeLogEntry."Entry No." := EntryNo;
            ChangeLogEntry."Table No." := TableNo;
            ChangeLogEntry."Date and Time" := CurrentDateTime;
            ChangeLogEntry.Insert();
        end;
        LastEntryNo := EntryNo;
        ChangeLogEntry.SetRange("Entry No.", FirstEntryNo, LastEntryNo);
    end;

    local procedure MockCustLedgEntry(): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry.Insert();
        exit(CustLedgerEntry."Entry No.");
    end;

    local procedure MockVendLedgEntry(): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry.Insert();
        exit(VendorLedgerEntry."Entry No.");
    end;

    local procedure MockGLEntryWithDescription(Descirption: Text): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FieldNo("Entry No."));
        GLEntry.Description := CopyStr(Descirption, 1, MaxStrLen(GLEntry.Description));
        GLEntry.Insert();
        exit(GLEntry."Entry No.");
    end;

    local procedure RunDeleteChangeLogEntries()
    var
        ChangeLogEntry: Record "Change Log Entry";
    begin
        Commit();
        ChangeLogEntry.SetFilter("Date and Time", '..%1', CreateDateTime(CalcDate('<1D>', Today), 0T));
        REPORT.RunModal(REPORT::"Change Log - Delete", true, false, ChangeLogEntry);
    end;

    local procedure VerifyChangeLogEntry(ChangeLogEntry: Record "Change Log Entry"; OldDescription: Text; NewDescription: Text)
    begin
        ChangeLogEntry.TestField("Type of Change", ChangeLogEntry."Type of Change"::Modification);
        ChangeLogEntry.TestField("Old Value", OldDescription);
        ChangeLogEntry.TestField("New Value", NewDescription);
    end;

    local procedure MockCustomerLedgerEntryWithDocNo(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocumentType: Option; DocumentNo: Code[20])
    begin
        CustLedgerEntry.Get(MockCustLedgEntry);
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Document Type" := DocumentType;
        CustLedgerEntry."Document No." := DocumentNo;
        CustLedgerEntry.Modify;
    end;

    local procedure CreateIssuedFinChargeMemoHeader(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; CustomerNo: Code[20]): Code[20]
    begin
        with IssuedFinChargeMemoHeader do begin
            Init;
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::"Issued Fin. Charge Memo Header");
            "Customer No." := CustomerNo;
            Insert;
            exit("No.");
        end;
    end;

    local procedure CreateIssuedReminderHeader(var IssuedReminderHeader: Record "Issued Reminder Header"; CustomerNo: Code[20]): Code[20]
    begin
        with IssuedReminderHeader do begin
            Init;
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::"Issued Reminder Header");
            "Customer No." := CustomerNo;
            Insert;
            exit("No.");
        end;
    end;
    
    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Message: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DeleteChangeLogeRPH(var ChangeLogDelete: TestRequestPage "Change Log - Delete")
    begin
        ChangeLogDelete.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ErrorMessagesMPH(var ErrorMessages: TestPage "Error Messages")
    begin
        ErrorMessages.FILTER.SetFilter(Description, LibraryVariableStorage.DequeueText);
        Assert.IsTrue(ErrorMessages.First, 'Error not found');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChangeLogEntriesMPH(var ChangeLogEntries: TestPage "Change Log Entries")
    begin
        LibraryVariableStorage.Enqueue(ChangeLogEntries.FILTER.GetFilter("Table No."));
        LibraryVariableStorage.Enqueue(ChangeLogEntries.FILTER.GetFilter("Primary Key Field 1 Value"));
        ChangeLogEntries.OK.Invoke;
    end;
}

