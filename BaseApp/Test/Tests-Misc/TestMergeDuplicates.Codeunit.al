codeunit 134399 "Test Merge Duplicates"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Merge Duplicates]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        IsInitialized: Boolean;
        NewKeyErr: Label 'Duplicate must not be %1';
        NewKeyMustHaveValueErr: Label 'Duplicate must have a value';
        TestPageNotOpenErr: Label 'The TestPage is not open.';
        RecordMergedMsg: Label '%1 %2 has been merged to %1 %3.', Comment = '%1 - table name (Customer/Vendor); %2 - Duplicate key; %3 - Current key';
        CurrRecordErr: Label 'The current record is not set.';
        ConfirmMergeTxt: Label 'Are you sure you want to merge the two records? This step cannot be undone.';
        ConfirmRenameTxt: Label 'Are you sure you want to rename record %1?';
        ConfirmRemoveTxt: Label 'Are you sure you want to remove record %1?';
        ConflictResolution: Option "None",Remove,Rename;
        ModifyPKeyFieldErr: Label 'You must modify one of the primary key fields.';
        RestorePKeyFieldErr: Label 'You must restore the modified primary key field.';
        SameValueErr: Label 'Field %1 has same values in current and duplicate rec.';
        CurrentDoesNotExistErr: Label '%1 %2 does not exist.';
        NotFoundLocationErr: Label 'that cannot be found in the related table (Location).';
        RemoveDefaultDimMsg: Label 'you want to remove record Default Dimension: 18,';

    [Test]
    [Scope('OnPrem')]
    procedure T001_MergeLinePKIncludesTableNoAndFieldNo()
    var
        MergeDuplicatesLineBuffer: Record "Merge Duplicates Line Buffer";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] MergeDuplicatesLineBuffer PK is 'Type,Table ID,ID'
        Initialize;
        MergeDuplicatesLineBuffer."Table ID" := 1;
        MergeDuplicatesLineBuffer.ID := 1;
        MergeDuplicatesLineBuffer.Insert();

        MergeDuplicatesLineBuffer.Type += 1;
        Assert.IsTrue(MergeDuplicatesLineBuffer.Insert, 'Cannot insert rec: same ID, diff Type');

        MergeDuplicatesLineBuffer."Table ID" := 2;
        Assert.IsTrue(MergeDuplicatesLineBuffer.Insert, 'Cannot insert rec: same ID, diff Table ID');
    end;

    [Test]
    [HandlerFunctions('CustomerLookupModalHandler')]
    [Scope('OnPrem')]
    procedure T100_MergeActionOnCustomerCard()
    var
        Customer: array[2] of Record Customer;
        CustomerCardPage: TestPage "Customer Card";
        MergePage: TestPage "Merge Duplicate";
    begin
        // [FEATURE] [Customer] [UI]
        // [SCENARIO] Run action 'Merge Duplicate' from Customer Card.
        Initialize;
        // [GIVEN] Customers 'A' and 'B'
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);
        // [GIVEN] Open Customer Card on 'A'
        CustomerCardPage.OpenEdit;
        CustomerCardPage.FILTER.SetFilter("No.", Customer[1]."No.");
        CustomerCardPage.First;

        // [WHEN] Run action 'Merge Duplicate'
        MergePage.Trap;
        CustomerCardPage.MergeDuplicate.Invoke;

        // [THEN] Open page 'Merge Duplicate', where "Current" is 'A', "Duplicate" is <blank>
        MergePage.Current.AssertEquals(Customer[1]."No.");
        Assert.IsFalse(MergePage.Current.Editable, 'Current Editable');
        MergePage.Duplicate.AssertEquals('');
        Assert.IsTrue(MergePage.Duplicate.Editable, 'Duplicate Editable');
        // [THEN] Actions "Remove Dupllicate", "Rename Duplicate" are not visible
        Assert.IsFalse(MergePage."Remove Duplicate".Visible, 'Remove should be invisible');
        Assert.IsFalse(MergePage."Rename Duplicate".Visible, 'Rename should be invisible');

        // [WHEN] Lookup "Duplicate" for 'B' and push 'OK'
        LibraryVariableStorage.Enqueue(Customer[2]."No."); // to CustomerListModalHandler
        MergePage.Duplicate.Lookup;
        // [THEN] "Duplicate" is 'B'
        MergePage.Duplicate.AssertEquals(Customer[2]."No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T101_FieldsListFilledOnNewKeyValidation()
    var
        Contact: array[2] of Record Contact;
        MergeDuplicatesBuffer: Record "Merge Duplicates Buffer";
        MergePage: TestPage "Merge Duplicate";
        CurrFieldID: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO] List of fields is filled after validation of "Current".
        Initialize;
        // [GIVEN] Contacts 'A' and 'B'
        CreateContact(Contact[1]);
        CreateContact(Contact[2]);

        // [GIVEN] Open Merge page for 'A', where the fields part is empty
        MergePage.Trap;
        MergeDuplicatesBuffer.Show(DATABASE::Contact, Contact[1]."No.");
        Assert.IsFalse(MergePage.Fields.First, 'there must not be records in Fields part');

        // [WHEN] Pick 'B' as "Duplicate"
        MergePage.Duplicate.SetValue(Contact[2]."No.");

        // [THEN] Fields list is filled, positioned at the first field
        CurrFieldID := MergePage.Fields.ID.AsInteger;
        Assert.IsTrue(MergePage.Fields.First, 'there must be records in Fields part');
        MergePage.Fields.ID.AssertEquals(CurrFieldID);
        // [THEN] The first line, where "Name" is 'No.', "In Primary Key" is 'Yes', "Data Type" is 'Code'
        MergePage.Fields.Name.AssertEquals(Contact[1].FieldCaption("No."));
        MergePage.Fields."Data Type".AssertEquals('Code');
        MergePage.Fields."In Primary Key".AssertEquals(0);
        // [THEN] "Alternative Value" field is not editable
        Assert.IsFalse(MergePage.Fields."Duplicate Value".Editable, 'Duplicate Value.EDITABLE');
        // [THEN] Records list is empty
        Assert.IsFalse(MergePage.Tables.First, 'there must not be records in Tables part');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T102_FieldsListReFilledOnSecondNewKeyValidation()
    var
        Customer: array[3] of Record Customer;
        MergeDuplicatesBuffer: Record "Merge Duplicates Buffer";
        MergePage: TestPage "Merge Duplicate";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] FIlled list of fields is regenerated after second validation of "Current".
        Initialize;
        // [GIVEN] Customers 'A', 'B', and 'C'
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);
        LibrarySales.CreateCustomer(Customer[3]);
        // [GIVEN] Open Merge page for 'A', where the fields part is empty
        MergePage.Trap;
        MergeDuplicatesBuffer.Show(DATABASE::Customer, Customer[1]."No.");
        Assert.IsFalse(MergePage.Fields.First, 'there must not be records in Fields part');
        // [GIVEN] Pick 'B' as "Duplicate"
        MergePage.Duplicate.SetValue(Customer[2]."No.");

        // [WHEN] Pick 'C' as "Duplicate"
        MergePage.Duplicate.SetValue(Customer[3]."No.");

        // [THEN] Fields list is regenerated, data is taken from 'C'
        Assert.IsTrue(MergePage.Fields.First, 'there must be records in Fields part');
        MergePage.Fields."Duplicate Value".AssertEquals(Customer[3]."No.");
        // [THEN] Fields "Table ID", "Table Name", "Old Count", "New Count", Conflicts are invisible
        Assert.IsFalse(MergePage.Fields."Table ID".Visible, 'Table ID visible');
        Assert.IsFalse(MergePage.Fields."Table Name".Visible, 'Table Name visible');
        Assert.IsFalse(MergePage.Fields."Duplicate Count".Visible, 'Old Count visible');
        Assert.IsFalse(MergePage.Fields."Current Count".Visible, 'New Count visible');
        Assert.IsFalse(MergePage.Fields.Conflicts.Visible, 'Conflicts.VISIBLE');
        MergePage.Tables.Conflicts.AssertEquals('0');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure T103_ActionMergeRemovesCustomerMovesPickedFields()
    var
        Customer: array[2] of Record Customer;
        MergeDuplicatesBuffer: Record "Merge Duplicates Buffer";
        MergePage: TestPage "Merge Duplicate";
        ExpectedAddress: Text[100];
    begin
        // [FEATURE] [Customer] [UI]
        // [SCENARIO] Action "Merge" removes old customer, copies picked fields from old to new.
        Initialize;
        // [GIVEN] Customers 'A', where "Address" is 'Moscow', and 'B', where "Name" is 'B'
        LibrarySales.CreateCustomer(Customer[1]);
        ExpectedAddress := LibraryUtility.GenerateGUID;
        Customer[1].Address := ExpectedAddress;
        Customer[1].Modify();
        LibrarySales.CreateCustomer(Customer[2]);

        // [GIVEN] Open Merge page for 'A', where the fields part is empty
        MergePage.Trap;
        MergeDuplicatesBuffer.Show(DATABASE::Customer, Customer[1]."No.");
        // [GIVEN] Pick 'B' as "Duplicate"
        MergePage.Duplicate.SetValue(Customer[2]."No.");
        // [GIVEN] Set "Override" to 'Yes' for the field "Name"
        SetOverride(MergePage, Customer[1].FieldNo(Name), true);

        // [WHEN] Run "Merge" action and answer 'Yes' to confirmation
        LibraryVariableStorage.Enqueue(true); // Reply for ConfirmHandler
        MergePage.Merge.Invoke;
        Assert.ExpectedMessage(ConfirmMergeTxt, LibraryVariableStorage.DequeueText);

        // [THEN] Message 'Customer B has been merged to Customer A' is shown
        Assert.ExpectedMessage(
          StrSubstNo(RecordMergedMsg, MergeDuplicatesBuffer."Table Name", Customer[2]."No.", Customer[1]."No."),
          LibraryVariableStorage.DequeueText);
        LibraryVariableStorage.AssertEmpty;
        // [THEN] Customer 'B' does not exist
        Assert.IsFalse(Customer[2].Find, 'Customer A must not exist');
        // [THEN] Customer 'A' does exist, where "Name" = 'B', "Address" is 'Moscow'
        Assert.IsTrue(Customer[1].Find, 'Customer B must exist');
        Customer[1].TestField(Name, Customer[2].Name);
        Customer[1].TestField(Address, ExpectedAddress);
        // [THEN] Page is closed
        asserterror MergePage.First;
        Assert.ExpectedError(TestPageNotOpenErr);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T105_TablesListFilledOnNewKeyValidation()
    var
        Customer: array[2] of Record Customer;
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        MergeDuplicatesBuffer: Record "Merge Duplicates Buffer";
        MyCustomer: Record "My Customer";
        MergePage: TestPage "Merge Duplicate";
        CurrTableID: Integer;
    begin
        // [FEATURE] [Customer] [UI]
        // [SCENARIO] List of tables is filled if source customer has related records.
        Initialize;

        // [GIVEN] Customers 'B' with one bank account,"My Customer" record and one Customer Ledger Entry.
        CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount[1], Customer[1]."No.");
        MyCustomer."User ID" := UserId;
        MyCustomer."Customer No." := Customer[1]."No.";
        MyCustomer.Insert();
        CustLedgerEntry."Customer No." := Customer[1]."No.";
        CustLedgerEntry.Insert();
        // [GIVEN] Customer 'A' with zero bank accounts
        CreateCustomer(Customer[2]);

        // [GIVEN] Open Merge page for 'A', where the fields part is empty
        MergePage.Trap;
        MergeDuplicatesBuffer.Show(DATABASE::Customer, Customer[2]."No.");
        Assert.IsFalse(MergePage.Fields.First, 'there must not be records in Fields part');

        // [WHEN] Pick 'B' as "Duplicate"
        MergePage.Duplicate.SetValue(Customer[1]."No.");

        // [THEN] Fields list is filled
        Assert.IsTrue(MergePage.Fields.First, 'there must be records in Fields part');
        // [THEN] Records list with two records, where the first one has: "Table ID" is '287', "Table Name" is 'Customer Bank Account',
        // [THEN] "ID" is '1', "Name" is "Customer No.","In Primary Key" is 'Yes', "Old Count" is '0', "New Count" is '1', Conflicts is '0'
        CurrTableID := MergePage.Tables."Table ID".AsInteger;
        Assert.IsTrue(MergePage.Tables.First, 'there must be record in Tables part');
        MergePage.Tables."Table ID".AssertEquals(CurrTableID);
        MergePage.Tables."Table ID".AssertEquals('287');
        MergePage.Tables."Table Name".AssertEquals(CustomerBankAccount[1].TableCaption);
        MergePage.Tables.ID.AssertEquals('1');
        MergePage.Tables.Name.AssertEquals(CustomerBankAccount[1].FieldCaption("Customer No."));
        MergePage.Tables."In Primary Key".AssertEquals(0);
        MergePage.Tables."Duplicate Count".AssertEquals('1');
        MergePage.Tables."Current Count".AssertEquals('0');
        Assert.IsTrue(MergePage.Tables.Conflicts.Visible, 'Conflicts.VISIBLE');
        MergePage.Tables.Conflicts.AssertEquals('0');
        // [THEN] Field "Old Value" and "New Value" are invisible
        Assert.IsFalse(MergePage.Tables."Duplicate Value".Visible, 'Duplicate Value.VISIBLE');
        Assert.IsFalse(MergePage.Tables."Current Value".Visible, 'Current Value.VISIBLE');
        Assert.IsFalse(MergePage.Tables."Data Type".Visible, 'Data Type.VISIBLE');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T106_TablesListEmptyIfOldCountZero()
    var
        Contact: array[2] of Record Contact;
        MergeDuplicatesBuffer: Record "Merge Duplicates Buffer";
        MergePage: TestPage "Merge Duplicate";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] List of tables is not filled if the source contact has no related records.
        Initialize;

        // [GIVEN] Contact 'A' with records in related tables
        LibraryMarketing.CreatePersonContact(Contact[2]);
        // [GIVEN] Contact 'B' with zero records in related tables
        CreateContact(Contact[1]);

        // [GIVEN] Open Merge page for 'A', where the fields part is empty
        MergePage.Trap;
        MergeDuplicatesBuffer.Show(DATABASE::Contact, Contact[2]."No.");
        Assert.IsFalse(MergePage.Fields.First, 'there must not be records in Fields part');

        // [WHEN] Pick 'B' as "Duplicate"
        MergePage.Duplicate.SetValue(Contact[1]."No.");

        // [THEN] Fields list is filled
        Assert.IsTrue(MergePage.Fields.First, 'there must be records in Fields part');
        // [THEN] Tables list is empty
        Assert.IsFalse(MergePage.Tables.First, 'there must not be record in Tables part');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T107_ConflictsAreNotCalculatedOnNewKeyValidation()
    var
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        TempMergeDuplicatesBuffer: Record "Merge Duplicates Buffer" temporary;
        TempMergeDuplicatesLineBuffer: Record "Merge Duplicates Line Buffer" temporary;
        TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary;
    begin
        // [FEATURE] [Conflict]
        Initialize;
        // [GIVEN] Customer Bank Account 'X' exists for 2 Customers 'A' and 'B'
        CreateConflictingCustomerBanks(CustomerBankAccount);
        // [GIVEN] Merge duplicate 'B' to current 'A'
        TempMergeDuplicatesBuffer."Table ID" := DATABASE::Customer;
        TempMergeDuplicatesBuffer.Current := CustomerBankAccount[1]."Customer No.";

        // [WHEN] Set "Duplicate" as 'B'
        TempMergeDuplicatesBuffer.Validate(Duplicate, CustomerBankAccount[2]."Customer No.");

        // [THEN] Merge lines have no conflicts
        TempMergeDuplicatesBuffer.TestField(Conflicts, 0);
        TempMergeDuplicatesBuffer.GetLines(TempMergeDuplicatesLineBuffer, TempMergeDuplicatesConflict);
        Assert.RecordIsEmpty(TempMergeDuplicatesConflict);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T108_ConflictsAreCalculatedOnMergeAction()
    var
        CustomerBankAccount: array[4] of Record "Customer Bank Account";
        TempMergeDuplicatesBuffer: Record "Merge Duplicates Buffer" temporary;
        TempMergeDuplicatesLineBuffer: Record "Merge Duplicates Line Buffer" temporary;
        TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary;
        TableWithPK16Fields: Record "Table With PK 16 Fields";
    begin
        // [FEATURE] [Conflict]
        Initialize;
        // [GIVEN] Customer Bank Accounts 'X' and 'Y' for Customer 'A'
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount[1], LibrarySales.CreateCustomerNo);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount[2], CustomerBankAccount[1]."Customer No.");
        // [GIVEN] Customer Bank Account 'X' and 'Y' for Customer 'B'
        CustomerBankAccount[3] := CustomerBankAccount[1];
        CustomerBankAccount[3]."Customer No." := LibrarySales.CreateCustomerNo;
        CustomerBankAccount[3].Insert();
        CustomerBankAccount[4] := CustomerBankAccount[2];
        CustomerBankAccount[4]."Customer No." := CustomerBankAccount[3]."Customer No.";
        CustomerBankAccount[4].Insert();
        // [GIVEN] 4 records TableWithPK16Fields; 2 identical records except Code 'A' and 'B'
        TableWithPK16Fields.Create(1, CustomerBankAccount[1]."Customer No.", CustomerBankAccount[1].RecordId);
        TableWithPK16Fields.Field1 := CustomerBankAccount[3]."Customer No.";
        TableWithPK16Fields.Insert();
        TableWithPK16Fields.Field6 := 2;
        TableWithPK16Fields.Insert();
        TableWithPK16Fields.Field7 := CurrentDateTime + 100;
        TableWithPK16Fields.Insert();

        // [GIVEN] Merge Duplicate 'B' to current 'A'
        TempMergeDuplicatesBuffer."Table ID" := DATABASE::Customer;
        TempMergeDuplicatesBuffer.Current := CustomerBankAccount[1]."Customer No.";
        TempMergeDuplicatesBuffer.Validate(Duplicate, CustomerBankAccount[3]."Customer No.");
        TempMergeDuplicatesBuffer.Insert();

        // [WHEN] Run action 'Merge'
        TempMergeDuplicatesBuffer.Merge;

        // [THEN] Merge heder, where Conflicts is 3
        TempMergeDuplicatesBuffer.TestField(Conflicts, 3);
        TempMergeDuplicatesBuffer.GetLines(TempMergeDuplicatesLineBuffer, TempMergeDuplicatesConflict);
        Assert.RecordCount(TempMergeDuplicatesConflict, 3);
        // [THEN] Merge Related Table, where ID is '287', "Conflicts" is 2
        TempMergeDuplicatesLineBuffer.SetRange("Table ID", DATABASE::"Customer Bank Account");
        TempMergeDuplicatesLineBuffer.FindFirst;
        TempMergeDuplicatesLineBuffer.TestField(Conflicts, 2);
        // [THEN] Merge Related Table, where ID is '134399', "Conflicts" is 1
        TempMergeDuplicatesLineBuffer.SetRange("Table ID", DATABASE::"Table With PK 16 Fields");
        TempMergeDuplicatesLineBuffer.FindFirst;
        TempMergeDuplicatesLineBuffer.TestField(Conflicts, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T109_ConflictsCleanedOnNewKeyValidation()
    var
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        TempMergeDuplicatesBuffer: Record "Merge Duplicates Buffer" temporary;
        TempMergeDuplicatesLineBuffer: Record "Merge Duplicates Line Buffer" temporary;
        TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary;
    begin
        // [FEATURE] [Conflict]
        Initialize;
        // [GIVEN] Customer Bank Account 'X' for Customer 'A'
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount[1], LibrarySales.CreateCustomerNo);
        // [GIVEN] Customer Bank Account 'X' for Customer 'B'
        CustomerBankAccount[2] := CustomerBankAccount[1];
        CustomerBankAccount[2]."Customer No." := LibrarySales.CreateCustomerNo;
        CustomerBankAccount[2].Insert();
        // [GIVEN] Merge current 'A' to duplicate'B'
        TempMergeDuplicatesBuffer."Table ID" := DATABASE::Customer;
        TempMergeDuplicatesBuffer.Current := CustomerBankAccount[1]."Customer No.";
        // [GIVEN] Set "Duplicate" as 'B' and merge, getting a conflict
        TempMergeDuplicatesBuffer.Validate(Duplicate, CustomerBankAccount[2]."Customer No.");
        TempMergeDuplicatesBuffer.Insert();
        TempMergeDuplicatesBuffer.Merge;
        Assert.AreEqual(1, TempMergeDuplicatesBuffer.Conflicts, 'Conflicts after merge.');

        // [WHEN] Set "Duplicate" as new customer 'C'
        TempMergeDuplicatesBuffer.Validate(Duplicate, LibrarySales.CreateCustomerNo);

        // [THEN] Merge lines have no conflicts
        TempMergeDuplicatesBuffer.GetLines(TempMergeDuplicatesLineBuffer, TempMergeDuplicatesConflict);
        Assert.RecordIsEmpty(TempMergeDuplicatesConflict);
        TempMergeDuplicatesBuffer.TestField(Conflicts, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T110_LineFindConflictsRecalculatesConflictForTable()
    var
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        TempMergeDuplicatesLineBuffer: Record "Merge Duplicates Line Buffer" temporary;
        TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary;
    begin
        // [FEATURE] [Conflict] [UT]
        Initialize;
        // [GIVEN] Customer Bank Account 'X' for Customer 'A'
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount[1], LibrarySales.CreateCustomerNo);
        // [GIVEN] Customer Bank Account 'X' for Customer 'B'
        CustomerBankAccount[2] := CustomerBankAccount[1];
        CustomerBankAccount[2]."Customer No." := LibrarySales.CreateCustomerNo;
        CustomerBankAccount[2].Insert();

        // [GIVEN] Conflict Buffer, where are 2 conflicts for table '287' and
        TempMergeDuplicatesConflict."Table ID" := DATABASE::"Customer Bank Account";
        TempMergeDuplicatesConflict.Duplicate := CustomerBankAccount[1].RecordId;
        TempMergeDuplicatesConflict.Current := CustomerBankAccount[2].RecordId;
        TempMergeDuplicatesConflict.Insert();
        Clear(TempMergeDuplicatesConflict.Duplicate);
        TempMergeDuplicatesConflict.Insert();
        // [GIVEN] 1 conflict for table '18'
        TempMergeDuplicatesConflict."Table ID" := DATABASE::Customer;
        TempMergeDuplicatesConflict.Insert();

        TempMergeDuplicatesLineBuffer.Type := TempMergeDuplicatesLineBuffer.Type::Table;
        TempMergeDuplicatesLineBuffer.Validate("Table ID", DATABASE::"Customer Bank Account");
        TempMergeDuplicatesLineBuffer.Validate(ID, CustomerBankAccount[1].FieldNo("Customer No."));
        TempMergeDuplicatesLineBuffer.Insert();
        // [WHEN] FindConflicts() for table '287'
        TempMergeDuplicatesLineBuffer.FindConflicts(
          CustomerBankAccount[1]."Customer No.", CustomerBankAccount[2]."Customer No.", TempMergeDuplicatesConflict);

        // [THEN] Line Buffer, where Conflicts is '1'
        TempMergeDuplicatesLineBuffer.TestField(Conflicts, 1);
        // [THEN] Conflict Buffer has 1 conflict for table '287', where "Table Name" is 'Customer Bank Account'
        TempMergeDuplicatesConflict.SetRange("Table ID", DATABASE::"Customer Bank Account");
        Assert.RecordCount(TempMergeDuplicatesConflict, 1);
        TempMergeDuplicatesConflict.FindFirst;
        TempMergeDuplicatesConflict.TestField("Table Name", CustomerBankAccount[1].TableCaption);
        // [THEN] Conflict Buffer still has 1 conflict for table '18'
        TempMergeDuplicatesConflict.SetRange("Table ID", DATABASE::Customer);
        Assert.RecordCount(TempMergeDuplicatesConflict, 1);
    end;

    [Test]
    [HandlerFunctions('ConflictListModalHandler')]
    [Scope('OnPrem')]
    procedure T111_DrillDownConflicts()
    var
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        TempMergeDuplicatesBuffer: Record "Merge Duplicates Buffer" temporary;
        MergeDuplicatePage: TestPage "Merge Duplicate";
    begin
        // [FEATURE] [Conflict] [UI]
        Initialize;
        // [GIVEN] Customer Bank Account 'X' exists for 2 Customers 'A' and 'B'
        CreateConflictingCustomerBanks(CustomerBankAccount);
        // [GIVEN] Open "Merge Duplicate" on customer 'A'
        MergeDuplicatePage.Trap;
        TempMergeDuplicatesBuffer.Show(DATABASE::Customer, CustomerBankAccount[1]."Customer No.");
        // [GIVEN] set 'B' as Duplicate and run 'Merge', to see one conflict
        MergeDuplicatePage.Duplicate.SetValue(CustomerBankAccount[2]."Customer No.");
        MergeDuplicatePage.Merge.Invoke;
        Assert.IsTrue(MergeDuplicatePage.Conflicts.Visible, 'Conflicts should be visible');

        // [WHEN] DrillDown on "Conflicts"
        MergeDuplicatePage.Conflicts.DrillDown;

        // [THEN] Modal page "Merge Conflicts" is open, where two records for Customer Bank Account 'A,X' and 'B,X'
        Assert.AreEqual(DATABASE::"Customer Bank Account", LibraryVariableStorage.DequeueInteger, 'Conflict.TableID'); // handled by ConflictListModalHandler
        Assert.AreEqual(
          Format(CustomerBankAccount[1].RecordId),
          StrSubstNo('%1: %2', CustomerBankAccount[1].TableName, LibraryVariableStorage.DequeueText), 'Conflict.Current');
        Assert.AreEqual(
          Format(CustomerBankAccount[2].RecordId),
          StrSubstNo('%1: %2', CustomerBankAccount[2].TableName, LibraryVariableStorage.DequeueText), 'Conflict.Duplicate');
        // [THEN] Tab Related Tables, where "Table ID" = 287, "Conflicts" is '1'
        MergeDuplicatePage.Tables.FILTER.SetFilter("Table ID", '287');
        MergeDuplicatePage.Tables.First;
        MergeDuplicatePage.Tables.Conflicts.AssertEquals(1);
        MergeDuplicatePage.Close;
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConflictListViewConflictModalHandler,RemoveConflictModalHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T112_DrillDownConflictsRemove()
    var
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        TempMergeDuplicatesBuffer: Record "Merge Duplicates Buffer" temporary;
        MergeDuplicatePage: TestPage "Merge Duplicate";
    begin
        // [FEATURE] [Conflict] [UI]
        // [SCENARIO] Merge Duplicates Tables tab is getting updated after removal of the conflict.
        Initialize;
        // [GIVEN] Customer Bank Account 'X' exists for 2 Customers 'A' and 'B'
        CreateConflictingCustomerBanks(CustomerBankAccount);
        // [GIVEN] Open "Merge Duplicate" on customer 'A'
        MergeDuplicatePage.Trap;
        TempMergeDuplicatesBuffer.Show(DATABASE::Customer, CustomerBankAccount[1]."Customer No.");
        // [GIVEN] set 'B' as Duplicate and run 'Merge', to see one conflict
        MergeDuplicatePage.Duplicate.SetValue(CustomerBankAccount[2]."Customer No.");
        MergeDuplicatePage.Merge.Invoke;
        Assert.IsTrue(MergeDuplicatePage.Conflicts.Visible, 'Conflicts should be visible');

        // [GIVEN] DrillDown on "Conflicts"
        MergeDuplicatePage.Conflicts.DrillDown;
        // [WHEN] Run Remove Duplicate (and confirm)
        // handled by RemoveConflictModalHandler and ConfirmYesHandler

        // [THEN] "Current" and "Merge With" controls contain primary kee values: 'A,X' and 'B,X'
        Assert.AreEqual(
          Format(CustomerBankAccount[1].RecordId),
          StrSubstNo('%1: %2', CustomerBankAccount[1].TableName, LibraryVariableStorage.DequeueText), 'Conflict.CurrentRecID');
        Assert.AreEqual(
          Format(CustomerBankAccount[2].RecordId),
          StrSubstNo('%1: %2', CustomerBankAccount[2].TableName, LibraryVariableStorage.DequeueText), 'Conflict.DuplicateRecID');
        // [THEN] Tab Conflicts to Resolve is invisible
        Assert.IsFalse(MergeDuplicatePage.Conflicts.Visible, 'Conflicts.VISIBLE');
        // [THEN] Tab Related Tables, where "Table ID" = 287, "Conflicts" is '0'
        MergeDuplicatePage.Tables.Conflicts.AssertEquals(0);
        MergeDuplicatePage.Close;
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T115_AddFieldDataSetsCanBeRenamedAsYes()
    var
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary;
        TempMergeDuplicatesLineBuffer: Record "Merge Duplicates Line Buffer" temporary;
        TempPKInt: Record "Integer" temporary;
        RecordRef: array[2] of RecordRef;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Conflicting record fields get "Can Be Renamed" as 'Yes' only for PK field that is equal in both records
        Initialize;
        // [GIVEN] Conflicting Customer Bank Accounts: 'C00010,BANK' and 'C00020,BANK'
        CreateConflictingCustomerBanks(CustomerBankAccount);
        CreateConflict(CustomerBankAccount, TempMergeDuplicatesConflict);
        RecordRef[1].Get(TempMergeDuplicatesConflict.Current);
        RecordRef[2].Get(TempMergeDuplicatesConflict.Duplicate);
        TempMergeDuplicatesLineBuffer.GetPrimaryKeyFields(RecordRef[1], TempPKInt);
        // [WHEN] AddFieldData(1) for the field that is the foregn key
        TempMergeDuplicatesLineBuffer.AddFieldData(RecordRef, TempMergeDuplicatesConflict."Field ID", 1, true, TempPKInt);
        // [THEN] Line Buffer record, where "ID" = 1, "Name" = 'Customer No.', "Can Be Renamed" = 'No'
        TempMergeDuplicatesLineBuffer.Find;
        TempMergeDuplicatesLineBuffer.TestField(ID, 1);
        TempMergeDuplicatesLineBuffer.TestField(Name, CustomerBankAccount[1].FieldName("Customer No."));
        TempMergeDuplicatesLineBuffer.TestField("Can Be Renamed", false);

        // [WHEN] AddFieldData(2) for the field in primary key, equal in both records
        TempMergeDuplicatesLineBuffer.AddFieldData(RecordRef, TempMergeDuplicatesConflict."Field ID", 2, true, TempPKInt);
        // [THEN] Line Buffer record, where "ID" = 2, "Name" = 'Code', "Can Be Renamed" = 'Yes'
        TempMergeDuplicatesLineBuffer.Find;
        TempMergeDuplicatesLineBuffer.TestField(ID, 2);
        TempMergeDuplicatesLineBuffer.TestField(Name, CustomerBankAccount[1].FieldName(Code));
        TempMergeDuplicatesLineBuffer.TestField("Can Be Renamed");

        // [WHEN] AddFieldData(3) for the field out of the primary key
        TempMergeDuplicatesLineBuffer.AddFieldData(RecordRef, TempMergeDuplicatesConflict."Field ID", 3, true, TempPKInt);
        // [THEN] Line Buffer record, where "ID" = 3, "Name" = 'Name', "Can Be Renamed" = 'No'
        TempMergeDuplicatesLineBuffer.Find;
        TempMergeDuplicatesLineBuffer.TestField(ID, 3);
        TempMergeDuplicatesLineBuffer.TestField(Name, CustomerBankAccount[1].FieldName(Name));
        TempMergeDuplicatesLineBuffer.TestField("Can Be Renamed", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T116_AddFieldDataSetsCanBeRenamedAsNo()
    var
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary;
        TempMergeDuplicatesLineBuffer: Record "Merge Duplicates Line Buffer" temporary;
        TempPKInt: Record "Integer" temporary;
        RecordRef: array[2] of RecordRef;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Conflicting record fields get "Can Be Renamed" as 'No' if PK field is not equal in both records
        Initialize;
        // [GIVEN] Conflicting Customer Bank Accounts: 'C00010,BANK' and 'C00020,BANKX'
        CreateConflictingCustomerBanks(CustomerBankAccount);
        CustomerBankAccount[2].Rename(CustomerBankAccount[2]."Customer No.", CustomerBankAccount[2].Code + 'X');
        CreateConflict(CustomerBankAccount, TempMergeDuplicatesConflict);
        RecordRef[1].Get(TempMergeDuplicatesConflict.Current);
        RecordRef[2].Get(TempMergeDuplicatesConflict.Duplicate);
        TempMergeDuplicatesLineBuffer.GetPrimaryKeyFields(RecordRef[1], TempPKInt);

        // [WHEN] AddFieldData(2) for the field in primary key, not equal in both records
        TempMergeDuplicatesLineBuffer.AddFieldData(RecordRef, TempMergeDuplicatesConflict."Field ID", 2, true, TempPKInt);
        // [THEN] Line Buffer record, where "ID" = 2, "Name" = 'Code', "Can Be Renamed" = 'No'
        TempMergeDuplicatesLineBuffer.Find;
        TempMergeDuplicatesLineBuffer.TestField(ID, 2);
        TempMergeDuplicatesLineBuffer.TestField(Name, CustomerBankAccount[1].FieldName(Code));
        TempMergeDuplicatesLineBuffer.TestField("Can Be Renamed", false);

        // [WHEN] AddFieldData(3) for the field out of the primary key
        TempMergeDuplicatesLineBuffer.AddFieldData(RecordRef, TempMergeDuplicatesConflict."Field ID", 3, true, TempPKInt);
        // [THEN] Line Buffer record, where "ID" = 3, "Name" = 'Name', "Can Be Renamed" = 'No'
        TempMergeDuplicatesLineBuffer.Find;
        TempMergeDuplicatesLineBuffer.TestField(ID, 3);
        TempMergeDuplicatesLineBuffer.TestField(Name, CustomerBankAccount[1].FieldName(Name));
        TempMergeDuplicatesLineBuffer.TestField("Can Be Renamed", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T117_AddFieldDataSetsCanBeRenamedAsNoForNotConflict()
    var
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        TempMergeDuplicatesLineBuffer: Record "Merge Duplicates Line Buffer" temporary;
        TempPKInt: Record "Integer" temporary;
        RecordRef: array[2] of RecordRef;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Merge record fields get "Can Be Renamed" as 'No' if PK field is equal in both records
        Initialize;
        // [GIVEN] Conflicting Customer Bank Accounts: 'C00010,BANK' and 'C00020,BANK'
        CreateConflictingCustomerBanks(CustomerBankAccount);
        CustomerBankAccount[2].Rename(CustomerBankAccount[2]."Customer No.", CustomerBankAccount[2].Code + 'X');
        RecordRef[1].Get(CustomerBankAccount[1].RecordId);
        RecordRef[2].Get(CustomerBankAccount[2].RecordId);
        TempMergeDuplicatesLineBuffer.GetPrimaryKeyFields(RecordRef[1], TempPKInt);

        // [WHEN] AddFieldData(2) for the field in primary key, not equal in both records
        TempMergeDuplicatesLineBuffer.AddFieldData(RecordRef, 0, 2, true, TempPKInt);
        // [THEN] Line Buffer record, where "ID" = 2, "Name" = 'Code', "Can Be Renamed" = 'No'
        TempMergeDuplicatesLineBuffer.Find;
        TempMergeDuplicatesLineBuffer.TestField(ID, 2);
        TempMergeDuplicatesLineBuffer.TestField(Name, CustomerBankAccount[1].FieldName(Code));
        TempMergeDuplicatesLineBuffer.TestField("Can Be Renamed", false);

        // [WHEN] AddFieldData(3) for the field out of the primary key
        TempMergeDuplicatesLineBuffer.AddFieldData(RecordRef, 0, 3, true, TempPKInt);
        // [THEN] Line Buffer record, where "ID" = 3, "Name" = 'Name', "Can Be Renamed" = 'No'
        TempMergeDuplicatesLineBuffer.Find;
        TempMergeDuplicatesLineBuffer.TestField(ID, 3);
        TempMergeDuplicatesLineBuffer.TestField(Name, CustomerBankAccount[1].FieldName(Name));
        TempMergeDuplicatesLineBuffer.TestField("Can Be Renamed", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T118_AddFieldDataSetsCanBeRenamedAsYesForKeyWithRelation()
    var
        Customer: array[2] of Record Customer;
        TempMergeDuplicatesLineBuffer: Record "Merge Duplicates Line Buffer" temporary;
        ItemCrossReference: array[2] of Record "Item Cross Reference";
        TempPKInt: Record "Integer" temporary;
        RecordRef: array[2] of RecordRef;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Merge record fields get "Can Be Renamed" as 'Yes' if PK field is has any relation
        Initialize;
        // [GIVEN] 2 Conflicting Item Cross References for Customer 'A' and 'B'
        LibrarySales.CreateCustomer(Customer[1]);
        ItemCrossReference[1].Init();
        ItemCrossReference[1]."Item No." := LibraryUtility.GenerateGUID;
        ItemCrossReference[1]."Cross-Reference No." := 'X';
        ItemCrossReference[1]."Cross-Reference Type" := ItemCrossReference[1]."Cross-Reference Type"::Customer;
        ItemCrossReference[1]."Cross-Reference Type No." := Customer[1]."No.";
        ItemCrossReference[1].Insert();
        RecordRef[1].Get(ItemCrossReference[1].RecordId);

        LibrarySales.CreateCustomer(Customer[2]);
        ItemCrossReference[2] := ItemCrossReference[1];
        ItemCrossReference[2]."Cross-Reference Type No." := Customer[2]."No.";
        ItemCrossReference[2].Insert();
        RecordRef[2].Get(ItemCrossReference[2].RecordId);
        TempMergeDuplicatesLineBuffer.GetPrimaryKeyFields(RecordRef[1], TempPKInt);

        // [WHEN] AddFieldData("Item No."); "Item No." has tablerelation to Item table
        TempMergeDuplicatesLineBuffer.AddFieldData(
          RecordRef, ItemCrossReference[1].FieldNo("Cross-Reference Type No."), ItemCrossReference[1].FieldNo("Item No."), true, TempPKInt);
        // [THEN] Line Buffer record, where "ID" = 1, "Name" = 'Item No.', "Can Be Renamed" = 'Yes'
        TempMergeDuplicatesLineBuffer.Find;
        TempMergeDuplicatesLineBuffer.TestField(ID, 1);
        TempMergeDuplicatesLineBuffer.TestField(Name, ItemCrossReference[1].FieldName("Item No."));
        TempMergeDuplicatesLineBuffer.TestField("Can Be Renamed", true);

        // [WHEN] AddFieldData("Cross-Reference No."); "Cross-Reference No." has no tablerelation
        TempMergeDuplicatesLineBuffer.AddFieldData(
          RecordRef, ItemCrossReference[1].FieldNo("Cross-Reference Type No."),
          ItemCrossReference[1].FieldNo("Cross-Reference No."), true, TempPKInt);
        // [THEN] Line Buffer record, where "ID" = 6, "Name" = 'Cross-Reference No.', "Can Be Renamed" = 'Yes'
        TempMergeDuplicatesLineBuffer.Find;
        TempMergeDuplicatesLineBuffer.TestField(ID, 6);
        TempMergeDuplicatesLineBuffer.TestField(Name, ItemCrossReference[1].FieldName("Cross-Reference No."));
        TempMergeDuplicatesLineBuffer.TestField("Can Be Renamed", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T119_HasFieldToOverride()
    var
        TempMergeDuplicatesLineBuffer: array[3] of Record "Merge Duplicates Line Buffer" temporary;
    begin
        // [FEATURE] [UT]
        Initialize;
        TempMergeDuplicatesLineBuffer[1].Type := TempMergeDuplicatesLineBuffer[1].Type::Field;
        TempMergeDuplicatesLineBuffer[1]."Table ID" := 287;
        TempMergeDuplicatesLineBuffer[1].ID := 1;
        TempMergeDuplicatesLineBuffer[1].Override := false;
        TempMergeDuplicatesLineBuffer[1].Insert();

        Assert.IsFalse(TempMergeDuplicatesLineBuffer[1].HasFieldToOverride, Format(TempMergeDuplicatesLineBuffer[1].ID));

        TempMergeDuplicatesLineBuffer[2] := TempMergeDuplicatesLineBuffer[1];
        TempMergeDuplicatesLineBuffer[2].ID := 2;
        TempMergeDuplicatesLineBuffer[2].Override := true;
        TempMergeDuplicatesLineBuffer[2].Insert();

        Assert.IsTrue(TempMergeDuplicatesLineBuffer[2].HasFieldToOverride, Format(TempMergeDuplicatesLineBuffer[2].ID));

        TempMergeDuplicatesLineBuffer[3] := TempMergeDuplicatesLineBuffer[1];
        TempMergeDuplicatesLineBuffer[3].ID := 3;
        TempMergeDuplicatesLineBuffer[3].Override := false;
        TempMergeDuplicatesLineBuffer[3].Insert();

        Assert.IsTrue(TempMergeDuplicatesLineBuffer[3].HasFieldToOverride, Format(TempMergeDuplicatesLineBuffer[3].ID));

        TempMergeDuplicatesLineBuffer[2].Find;
        TempMergeDuplicatesLineBuffer[2].Override := false;
        TempMergeDuplicatesLineBuffer[2].Modify();

        Assert.IsFalse(TempMergeDuplicatesLineBuffer[1].HasFieldToOverride, Format(4));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T120_AddTableDateCalculatesInPrimaryKeyValue()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        MergeDuplicatesBuffer: Record "Merge Duplicates Buffer";
        MergeDuplicatesLineBuffer: Record "Merge Duplicates Line Buffer";
    begin
        // [FEATURE] [UT]
        Initialize;
        // [GIVEN] Customer Bank Account 'X' for Customer 'A'
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, LibrarySales.CreateCustomerNo);
        MergeDuplicatesBuffer."Table ID" := DATABASE::"Customer Bank Account";
        MergeDuplicatesBuffer.Current := CustomerBankAccount."Customer No.";
        MergeDuplicatesBuffer.Duplicate := CustomerBankAccount."Customer No.";
        // [WHEN] AddTableData()
        MergeDuplicatesLineBuffer.AddTableData(
          MergeDuplicatesBuffer, MergeDuplicatesBuffer."Table ID", CustomerBankAccount.FieldNo("Customer No."));
        // [THEN] Line, where "In Primary Key" is 'Yes'
        MergeDuplicatesLineBuffer.TestField("In Primary Key", MergeDuplicatesLineBuffer."In Primary Key"::Yes);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T121_OverwriteOnFieldInPrimaryKeyIsDenied()
    var
        MergeDuplicatesLineBuffer: Record "Merge Duplicates Line Buffer";
    begin
        // [FEATURE] [UT]
        Initialize;
        // [GIVEN] Line, where "Type" is 'Field', "In Primary Key" is 'Yes'
        MergeDuplicatesLineBuffer.Type := MergeDuplicatesLineBuffer.Type::Field;
        MergeDuplicatesLineBuffer."In Primary Key" := MergeDuplicatesLineBuffer."In Primary Key"::Yes;
        // [WHEN] Set "Override" to 'Yes'
        asserterror MergeDuplicatesLineBuffer.Validate(Override, true);
        // [THEN] Error message: 'In Primary Key must be No'
        Assert.ExpectedError(MergeDuplicatesLineBuffer.FieldCaption("In Primary Key"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T122_LineBufferDuplicateValueValidationCutsLongValue()
    var
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary;
        TempMergeDuplicatesLineBuffer: Record "Merge Duplicates Line Buffer" temporary;
        TempPKInt: Record "Integer" temporary;
        RecordRef: array[2] of RecordRef;
        NewLongValue: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] "Duplicate Value" is cut to the maximum length on validation
        Initialize;
        // [GIVEN] Line, where "Type" is 'Field', "In Primary Key" is 'Yes', "Can Be Modified" is 'Yes', "Duplicate Value" is 'B'
        CreateConflictingCustomerBanks(CustomerBankAccount);
        CreateConflict(CustomerBankAccount, TempMergeDuplicatesConflict);
        RecordRef[1].Get(TempMergeDuplicatesConflict.Current);
        RecordRef[2].Get(TempMergeDuplicatesConflict.Duplicate);
        TempMergeDuplicatesLineBuffer.GetPrimaryKeyFields(RecordRef[1], TempPKInt);
        TempMergeDuplicatesLineBuffer.AddFieldData(
          RecordRef, TempMergeDuplicatesConflict."Field ID", CustomerBankAccount[1].FieldNo(Code), true, TempPKInt);

        // [WHEN] Change "Duplicate Value" to a value that is longer that the maximum field length (20)
        NewLongValue := LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(CustomerBankAccount[1].Code) + 1, 0);
        TempMergeDuplicatesLineBuffer.Validate("Duplicate Value", CopyStr(NewLongValue, 1));

        // [THEN] "Duplicate Value" is cut to 20 (maximum for this field)
        Assert.AreEqual(
          MaxStrLen(CustomerBankAccount[1].Code), StrLen(TempMergeDuplicatesLineBuffer."Duplicate Value"), 'Length of Duplicate Value');
        Assert.AreEqual(1, StrPos(NewLongValue, TempMergeDuplicatesLineBuffer."Duplicate Value"), 'validated value cut wrong');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T123_MergeToNotExistingCurrentRecordMustFail()
    var
        Customer: Record Customer;
        TempMergeDuplicatesBuffer: Record "Merge Duplicates Buffer" temporary;
        Current: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Show error message 'Customer X does not exist' if Current record does not exist at the moment of merge
        Initialize;
        // [GIVEN] Current Customer 'A'
        LibrarySales.CreateCustomer(Customer);
        Current := Customer."No.";
        // [GIVEN] prepare "Merge with" for 'A'
        TempMergeDuplicatesBuffer.Init();
        TempMergeDuplicatesBuffer.Current := Current;
        TempMergeDuplicatesBuffer.Validate("Table ID", DATABASE::Customer);
        // [GIVEN] Customer 'A' is removed
        Customer.Delete();

        // [WHEN] Set "Duplicate" to 'B'
        asserterror TempMergeDuplicatesBuffer.Validate(Duplicate, LibrarySales.CreateCustomerNo);
        // [THEN] Error message: 'Customer A does not exist'
        Assert.ExpectedError(StrSubstNo(CurrentDoesNotExistErr, Customer.TableCaption, Current))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T124_MergeToNotExistingCurrentRecIdMustFail()
    var
        Customer: Record Customer;
        TempMergeDuplicatesBuffer: Record "Merge Duplicates Buffer" temporary;
        CurrentRecID: RecordID;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Show error message 'Customer: X does not exist' if Current Record Id does not exist at the moment of merge
        Initialize;
        // [GIVEN] Current Customer 'A'
        LibrarySales.CreateCustomer(Customer);
        CurrentRecID := Customer.RecordId;
        // [GIVEN] prepare "Merge with" for 'A'
        TempMergeDuplicatesBuffer.Validate("Current Record ID", CurrentRecID);
        // [GIVEN] Customer 'A' is removed
        Customer.Delete();
        LibrarySales.CreateCustomer(Customer);
        // [WHEN] Set "Duplicate Record ID" to 'B'
        asserterror TempMergeDuplicatesBuffer.Validate("Duplicate Record ID", Customer.RecordId);
        Assert.ExpectedError(StrSubstNo(CurrentDoesNotExistErr, '', Format(CurrentRecID)))
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [Scope('OnPrem')]
    procedure T125_NotConfirmedMergeDoesNothing()
    var
        Customer: array[2] of Record Customer;
        xCustomer: array[2] of Record Customer;
        ActualIntegrationRecord: Record "Integration Record";
        IntegrationRecord: array[2] of Record "Integration Record";
        TempMergeDuplicatesBuffer: Record "Merge Duplicates Buffer" temporary;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Merge does not happen if user does not confirm.
        Initialize;
        // [GIVEN] Customers 'A' (ID = 'AAA') and 'B' (ID = 'BBB')
        LibrarySales.CreateCustomer(Customer[1]);
        xCustomer[1] := Customer[1];
        IntegrationRecord[1].Get(Customer[1].Id);
        LibrarySales.CreateCustomer(Customer[2]);
        xCustomer[2] := Customer[2];
        IntegrationRecord[2].Get(Customer[2].Id);

        // [WHEN] Merge 'A' to 'B', but answer 'No' to confirmation
        TempMergeDuplicatesBuffer."Table ID" := DATABASE::Customer;
        TempMergeDuplicatesBuffer.Duplicate := Customer[1]."No.";
        TempMergeDuplicatesBuffer.Current := Customer[2]."No.";
        TempMergeDuplicatesBuffer.Insert();
        TempMergeDuplicatesBuffer.Merge;

        // [THEN] Customer 'A' does exist, where Name = 'A', ID is 'AAA'
        Assert.IsTrue(Customer[1].Find, 'Customer A must exist');
        Customer[1].TestField("No.", xCustomer[1]."No.");
        Customer[1].TestField(Name, Customer[1].Name);
        // [THEN] Integration Record 'AAA', where "Deleted On" is blank, "Record ID" points to 'A'
        ActualIntegrationRecord.Get(IntegrationRecord[1]."Integration ID");
        ActualIntegrationRecord.TestField("Deleted On", 0DT);
        Assert.AreEqual(ActualIntegrationRecord."Record ID", IntegrationRecord[1]."Record ID", 'Record ID #1');
        // [THEN] Customer 'B' does exist, where Name = 'B', ID is 'BBB'
        Assert.IsTrue(Customer[2].Find, 'Customer B must exist');
        Customer[2].TestField("No.", xCustomer[2]."No.");
        Customer[2].TestField(Name, Customer[2].Name);
        Customer[2].TestField(Id, IntegrationRecord[2]."Integration ID");
        // [THEN] Integration Record 'BBB', where "Deleted On" is blank, "Record ID" points to 'B'
        ActualIntegrationRecord.Get(IntegrationRecord[2]."Integration ID");
        ActualIntegrationRecord.TestField("Deleted On", 0DT);
        Assert.AreEqual(ActualIntegrationRecord."Record ID", IntegrationRecord[2]."Record ID", 'Record ID #2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T129_ConflictTableIDValidatesTableName()
    var
        TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary;
        MergeDuplicateConflictsPage: TestPage "Merge Duplicate Conflicts";
        MergeDuplicateConflicts: Page "Merge Duplicate Conflicts";
        RecRef: RecordRef;
        TableName: Text;
    begin
        // [FEATURE] [Conflict] [UT] [UI]
        // [SCENARIO] Conflict page shows "Table ID" and "Table Name"
        Initialize;
        // [GIVEN] Inserted Conflict for table 287
        TempMergeDuplicatesConflict.Validate("Table ID", DATABASE::"Customer Bank Account");
        TempMergeDuplicatesConflict.Insert();

        // [GIVEN] "Table Name" is 'Customer Bank Account'
        RecRef.Open(TempMergeDuplicatesConflict."Table ID");
        TableName := RecRef.Caption;
        RecRef.Close;
        TempMergeDuplicatesConflict.TestField("Table Name", TableName);

        // [WHEN] Open Conflicts page
        MergeDuplicateConflictsPage.Trap;
        MergeDuplicateConflicts.Set(TempMergeDuplicatesConflict);
        MergeDuplicateConflicts.Run;
        // [THEN] "Table ID" is 287, "Table Name" is 'Customer Bank Account'
        MergeDuplicateConflictsPage."Table ID".AssertEquals(DATABASE::"Customer Bank Account");
        MergeDuplicateConflictsPage."Table Name".AssertEquals(TableName);
        MergeDuplicateConflictsPage.Close;
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T130_ConflictPickedFieldsCopiedBeforeRemoval()
    var
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary;
        MergeDuplicatePage: TestPage "Merge Duplicate";
        ExpectedAddress: Text[100];
    begin
        // [FEATURE] [Conflict] [UI]
        // [SCENARIO] Fields picked for override are copied before removal of the conflicting record.
        Initialize;
        // [GIVEN] Customer Bank Account: 'C00010,BANK', where "Address" is 'Moscow'
        // [GIVEN] Conflicting Customer Bank Account: 'C00020,BANK', where "Name" is 'B'
        CreateConflictingCustomerBanks(CustomerBankAccount);
        ExpectedAddress := LibraryUtility.GenerateGUID;
        CustomerBankAccount[1].Address := ExpectedAddress;
        CustomerBankAccount[1].Modify();
        CreateConflict(CustomerBankAccount, TempMergeDuplicatesConflict);
        Assert.AreNotEqual(CustomerBankAccount[1].Name, CustomerBankAccount[2].Name, 'Names must be different');
        Assert.AreNotEqual(CustomerBankAccount[1].Address, CustomerBankAccount[2].Address, 'Addresses must be different');
        // [GIVEN] Field "Name", where "Current Value" is 'A', "Alternative Value" is 'B', "Override" is 'Yes'
        OpenMergePageForConflictingRecords(MergeDuplicatePage, TempMergeDuplicatesConflict);
        SetOverride(MergeDuplicatePage, CustomerBankAccount[1].FieldNo(Name), true);

        // [WHEN] run "Remove" action
        MergeDuplicatePage."Remove Duplicate".Invoke;

        // [THEN] Current record 'C00010,BANK', where "Name" is 'B', "Address" is 'Moscow'
        CustomerBankAccount[1].Find;
        CustomerBankAccount[1].TestField(Name, CustomerBankAccount[2].Name);
        CustomerBankAccount[1].TestField(Address, ExpectedAddress);
        // [THEN] Conflicting record does not exist
        Assert.IsFalse(CustomerBankAccount[2].Find, 'duplicate record must not exist');
        // [THEN] Merge Duplicate page is closed
        Assert.IsFalse(IsMergePageOpen(MergeDuplicatePage), 'Merge page should be closed')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T131_ConflictAnyPickedFieldDisablesRenameAction()
    var
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary;
        MergeDuplicatePage: TestPage "Merge Duplicate";
    begin
        // [FEATURE] [Conflict] [UI]
        // [SCENARIO] Renaming is not possible if any field is picked for override
        Initialize;
        // [GIVEN] Conflicting Customer Bank Accounts: 'C00010,BANK' and 'C00020,BANK', "Name" is different.
        CreateConflictingCustomerBanks(CustomerBankAccount);
        CreateConflict(CustomerBankAccount, TempMergeDuplicatesConflict);
        // [GIVEN] Open Merge Duplicate page for conflict
        OpenMergePageForConflictingRecords(MergeDuplicatePage, TempMergeDuplicatesConflict);
        // [GIVEN] Action "Rename" is enabled; "Alternative Value" is editable in "Code" field
        Assert.IsTrue(MergeDuplicatePage."Rename Duplicate".Enabled, 'Rename should be enabled before');
        VerifyFieldDuplicateValueEditable(MergeDuplicatePage, CustomerBankAccount[1].FieldNo(Code), true);
        // [GIVEN] Action "Remove" is enabled; "Override" controls are editable.
        Assert.IsTrue(MergeDuplicatePage."Remove Duplicate".Enabled, 'Remove should be enabled before');
        VerifyFieldOverrideEditable(MergeDuplicatePage, CustomerBankAccount[1].FieldNo(Name), true);

        // [WHEN] Set "Override" to 'Yes' for the field "Name"
        SetOverride(MergeDuplicatePage, CustomerBankAccount[1].FieldNo(Name), true);

        // [THEN] "Remove" action is enabled; "Override" controls are editable.
        Assert.IsTrue(MergeDuplicatePage."Remove Duplicate".Enabled, 'Remove should be enabled after');
        VerifyFieldOverrideEditable(MergeDuplicatePage, CustomerBankAccount[1].FieldNo(Name), true);
        // [THEN] "Rename" action is enabled; "Alternative Value" is not editable on "Code" field
        Assert.IsTrue(MergeDuplicatePage."Rename Duplicate".Enabled, 'Rename should be enabled after');
        VerifyFieldDuplicateValueEditable(MergeDuplicatePage, CustomerBankAccount[1].FieldNo(Code), false);
        MergeDuplicatePage.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T132_ConflictModifiedPKFieldDisabledRemoveAction()
    var
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary;
        MergeDuplicatePage: TestPage "Merge Duplicate";
    begin
        // [FEATURE] [Conflict] [UI]
        // [SCENARIO] Override checkboxes and Remove action are not editable if PK fields has been changed
        Initialize;
        // [GIVEN] Conflicting Customer Bank Accounts: 'C00010,BANK' and 'C00020,BANK', "Name" is different.
        CreateConflictingCustomerBanks(CustomerBankAccount);
        CreateConflict(CustomerBankAccount, TempMergeDuplicatesConflict);
        // [GIVEN] Open Merge Duplicate page for conflict
        OpenMergePageForConflictingRecords(MergeDuplicatePage, TempMergeDuplicatesConflict);
        // [GIVEN] Action "Rename" is enabled; "Alternative Value" is editable
        Assert.IsTrue(MergeDuplicatePage."Rename Duplicate".Enabled, 'Rename should be enabled before');
        VerifyFieldDuplicateValueEditable(MergeDuplicatePage, CustomerBankAccount[1].FieldNo(Code), true);
        // [GIVEN] Action "Remove" is enabled; "Override" control is editable.
        Assert.IsTrue(MergeDuplicatePage."Remove Duplicate".Enabled, 'Remove should be enabled before');
        VerifyFieldOverrideEditable(MergeDuplicatePage, CustomerBankAccount[1].FieldNo(Name), true);

        // [WHEN] Change "Code" in "Alternative Value" from 'BANK' to 'BANK-X'
        MergeDuplicatePage.Fields.FindFirstField(ID, CustomerBankAccount[1].FieldNo(Code));
        MergeDuplicatePage.Fields."Duplicate Value".SetValue(CustomerBankAccount[2].Code + '-X');

        // [THEN] "Remove" action is enabled; "Override" control is not editable.
        Assert.IsTrue(MergeDuplicatePage."Remove Duplicate".Enabled, 'Remove should be enabled after');
        VerifyFieldOverrideEditable(MergeDuplicatePage, CustomerBankAccount[1].FieldNo(Name), false);
        // [THEN] "Rename" action is enabled; "Alternative Value" is editable
        Assert.IsTrue(MergeDuplicatePage."Rename Duplicate".Enabled, 'Rename should be enabled after');
        VerifyFieldDuplicateValueEditable(MergeDuplicatePage, CustomerBankAccount[1].FieldNo(Code), true);

        // [WHEN] Run "Remove" action
        asserterror MergeDuplicatePage."Remove Duplicate".Invoke;
        // [THEN] Error message: 'Restore the modified primary key fields.'
        Assert.ExpectedError(RestorePKeyFieldErr);
        MergeDuplicatePage.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T133_ConflictPKValueEditableIfValuesAreTextAndPKl()
    var
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary;
        MergeDuplicatePage: TestPage "Merge Duplicate";
    begin
        // [FEATURE] [Conflict] [UI]
        // [SCENARIO] Alternative value is editable if the field is in PK and is of type Code or Text and not a foreign key.
        Initialize;
        // [GIVEN] Conflicting Customer Bank Accounts: 'C00010,BANK' and 'C00020,BANK',
        CreateConflictingCustomerBanks(CustomerBankAccount);
        CreateConflict(CustomerBankAccount, TempMergeDuplicatesConflict);

        // [WHEN] Open Merge Duplicate page for conflict
        OpenMergePageForConflictingRecords(MergeDuplicatePage, TempMergeDuplicatesConflict);

        // [THEN] The line for field "Customer No.", where "Alternative Value" is not editable (as a foreign key)
        VerifyFieldDuplicateValueEditable(MergeDuplicatePage, CustomerBankAccount[1].FieldNo("Customer No."), false);
        // [THEN] The line for field "Code", where "Alternative Value" is editable
        VerifyFieldDuplicateValueEditable(MergeDuplicatePage, CustomerBankAccount[1].FieldNo(Code), true);
        // [THEN] The line for field "Name", where "Alternative Value" is not editable (as out of the primary key)
        VerifyFieldDuplicateValueEditable(MergeDuplicatePage, CustomerBankAccount[1].FieldNo(Name), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T134_ConflicttPKValueEditableIfValueChanged()
    var
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary;
        MergeDuplicatePage: TestPage "Merge Duplicate";
    begin
        // [FEATURE] [Conflict] [UI]
        // [SCENARIO] Alternative value is editable if the field if the value has been changed.
        Initialize;
        // [GIVEN] Conflicting Customer Bank Accounts: 'C00010,BANK' and 'C00020,BANK',
        CreateConflictingCustomerBanks(CustomerBankAccount);
        CreateConflict(CustomerBankAccount, TempMergeDuplicatesConflict);
        // [GIVEN] Open Merge Duplicate page for conflict
        OpenMergePageForConflictingRecords(MergeDuplicatePage, TempMergeDuplicatesConflict);

        // [WHEN] Change "Code" in "Alternative Value" from 'BANK' to 'BANK-X'
        MergeDuplicatePage.Fields.FindFirstField(ID, CustomerBankAccount[1].FieldNo(Code));
        MergeDuplicatePage.Fields."Duplicate Value".SetValue(CustomerBankAccount[2].Code + '-X');
        // [THEN] The line for field "Code", where "Alternative Value" is editable
        VerifyFieldDuplicateValueEditable(MergeDuplicatePage, CustomerBankAccount[1].FieldNo(Code), true);

        // [WHEN] Change "Code" in "Alternative Value" from 'BANK-X' to 'BANK'
        MergeDuplicatePage.Fields."Duplicate Value".SetValue(CustomerBankAccount[1].Code);
        // [THEN] The line for field "Code", where "Alternative Value" is editable
        VerifyFieldDuplicateValueEditable(MergeDuplicatePage, CustomerBankAccount[1].FieldNo(Code), true);

        // [WHEN] Run "Rename" action
        asserterror MergeDuplicatePage."Rename Duplicate".Invoke;
        // [THEN] Error message: 'You must modify one of the primary key fields'
        Assert.ExpectedError(ModifyPKeyFieldErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MergeDuplicatesConflictingRecordsModalHandler')]
    [Scope('OnPrem')]
    procedure T135_ConflictRemoveActionAsksConfirmation()
    var
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary;
        MergeDuplicateConflicts: Page "Merge Duplicate Conflicts";
        MergeDuplicateConflictsPage: TestPage "Merge Duplicate Conflicts";
    begin
        // [FEATURE] [Conflict] [UI]
        // [SCENARIO] Remove action asks users confirmation
        Initialize;
        // [GIVEN] Conflicting Customer Bank Account 'X' exists for 2 Customers 'A' and 'B'
        CreateConflictingCustomerBanks(CustomerBankAccount);
        CreateConflict(CustomerBankAccount, TempMergeDuplicatesConflict);
        // [GIVEN] Open page "Merge Duplicate Conflicts", where is record for 'X'
        MergeDuplicateConflicts.Set(TempMergeDuplicatesConflict);
        MergeDuplicateConflictsPage.Trap;
        MergeDuplicateConflicts.Run;
        // [GIVEN] Run "View" and then "Remove" action
        LibraryVariableStorage.Enqueue(ConflictResolution::Remove); // Action for MergeDuplicatesConflictingRecordsModalHandler
        LibraryVariableStorage.Enqueue(true); // Reply for ConfirmHandler
        MergeDuplicateConflictsPage.ViewConflictRecords.Invoke;
        // [WHEN] User answers 'Yes' on confirmation: 'Are you sure you want to remove the record?'
        Assert.ExpectedMessage(StrSubstNo(ConfirmRemoveTxt, Format(CustomerBankAccount[2].RecordId)), LibraryVariableStorage.DequeueText);

        // [THEN] The Merge Conflicts page is closed
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean, 'Merge Conflicts page should be closed');
        // [THEN] Customer 'B' has no the bank account 'X'
        Assert.IsFalse(CustomerBankAccount[2].Find, 'Duplicate bank should not exist');
        // [THEN] Customer 'A' still has the bank account 'X'
        Assert.IsTrue(CustomerBankAccount[1].Find, 'Current bank should not exist');
        // [THEN] Conflict line is removed from the list
        Assert.IsFalse(MergeDuplicateConflictsPage.First, 'should be no conflicts in the list');
        MergeDuplicateConflictsPage.Close;
        // [THEN] Page is closed
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MergeDuplicatesConflictingRecordsModalHandler')]
    [Scope('OnPrem')]
    procedure T136_ConflictRemoveActionCanceledIfUserDenied()
    var
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary;
        MergeDuplicateConflicts: Page "Merge Duplicate Conflicts";
        MergeDuplicateConflictsPage: TestPage "Merge Duplicate Conflicts";
    begin
        // [FEATURE] [Conflict] [UI]
        // [SCENARIO] Remove action is canceled if user has not confirmed
        Initialize;
        // [GIVEN] Conflicting Customer Bank Account 'X' exists for 2 Customers 'A' and 'B'
        CreateConflictingCustomerBanks(CustomerBankAccount);
        CreateConflict(CustomerBankAccount, TempMergeDuplicatesConflict);
        // [GIVEN] Open page "Merge Duplicate Conflicts", where is record for 'X'
        MergeDuplicateConflicts.Set(TempMergeDuplicatesConflict);
        MergeDuplicateConflictsPage.Trap;
        MergeDuplicateConflicts.Run;
        // [GIVEN] Run "View" and then "Remove" action
        LibraryVariableStorage.Enqueue(ConflictResolution::Remove); // Action for MergeDuplicatesConflictingRecordsModalHandler
        LibraryVariableStorage.Enqueue(false); // Reply for ConfirmHandler
        MergeDuplicateConflictsPage.ViewConflictRecords.Invoke;
        // [WHEN] User answers 'No' on confirmation: 'Are you sure you want to remove the record?'
        Assert.ExpectedMessage(StrSubstNo(ConfirmRemoveTxt, Format(CustomerBankAccount[2].RecordId)), LibraryVariableStorage.DequeueText);

        // [THEN] The Merge Conflicts page is open
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, 'Merge Conflicts page should be open');
        // [THEN] Conflict line is in the list
        Assert.IsTrue(MergeDuplicateConflictsPage.First, 'should still be conflict in the list');
        // [THEN] Customer 'B' has the bank account 'X'
        Assert.IsTrue(CustomerBankAccount[2].Find, 'Duplicate bank should not exist');
        // [THEN] Customer 'A' has the bank account 'X'
        Assert.IsTrue(CustomerBankAccount[1].Find, 'Current bank should not exist');
        MergeDuplicateConflictsPage.Close;
        LibraryVariableStorage.AssertEmpty;
    end;

    // [Test]
    // [HandlerFunctions('ConfirmHandler,MergeDuplicatesConflictingRecordsModalHandler')]
    // [Scope('OnPrem')]
    // procedure T137_ConflictRenameActionAsksConfirmation()
    // var
    //     Customer: Record Customer;
    //     TableWithPK16Fields: array [2] of Record "Table With PK 16 Fields";
    //     TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary;
    //     MergeDuplicateConflicts: Page "Merge Duplicate Conflicts";
    //     MergeDuplicateConflictsPage: TestPage "Merge Duplicate Conflicts";
    //     RecID: RecordID;
    // begin
    //     // [FEATURE] [Conflict] [UI]
    //     // [SCENARIO] Rename action asks users confirmation
    //     Initialize;
    //     // [GIVEN] Conflicting TableWithPK16Fields exist for 2 Customers 'A' and 'B'
    //     LibrarySales.CreateCustomer(Customer);
    //     TableWithPK16Fields[1].Create(1,Customer."No.",Customer.RecordId);
    //     TempMergeDuplicatesConflict.Current := TableWithPK16Fields[1].RecordId;
    //     TableWithPK16Fields[2] := TableWithPK16Fields[1];
    //     TableWithPK16Fields[2].Field1 := LibrarySales.CreateCustomerNo;
    //     TableWithPK16Fields[2].Insert();
    //     TempMergeDuplicatesConflict.Duplicate := TableWithPK16Fields[2].RecordId;
    //     TempMergeDuplicatesConflict.Validate("Table ID",134399);
    //     TempMergeDuplicatesConflict."Field ID" := TableWithPK16Fields[1].FieldNo(Field1);
    //     TempMergeDuplicatesConflict.Insert();
    //     RecID := TableWithPK16Fields[2].RecordId;

    //     // [GIVEN] Open page "Merge Duplicate Conflicts", where is record for 'X'
    //     MergeDuplicateConflicts.Set(TempMergeDuplicatesConflict);
    //     MergeDuplicateConflictsPage.Trap;
    //     MergeDuplicateConflicts.Run;
    //     // [GIVEN] Run "Rename Duplicate" action
    //     LibraryVariableStorage.Enqueue(ConflictResolution::Rename); // Action for MergeDuplicatesConflictingRecordsModalHandler
    //     // [GIVEN] PK field value is changed from 'X' to 'Y'
    //     LibraryVariableStorage.Enqueue(TableWithPK16Fields[1].FieldNo(Field15)); // PK Field ID
    //     TableWithPK16Fields[2].Field15 := TableWithPK16Fields[2].Field15 + 'X';
    //     LibraryVariableStorage.Enqueue(TableWithPK16Fields[2].Field15); // New value for PK field
    //     // [WHEN] User answers 'Yes'
    //     LibraryVariableStorage.Enqueue(true); // Reply for ConfirmHandler
    //     MergeDuplicateConflictsPage.ViewConflictRecords.Invoke;
    //     Assert.ExpectedMessage(StrSubstNo(ConfirmRenameTxt,Format(RecID)),LibraryVariableStorage.DequeueText);

    //     // [THEN] The Merge Conflicts page is closed
    //     Assert.IsFalse(LibraryVariableStorage.DequeueBoolean,'Merge Conflicts page should be closed');
    //     // [THEN] Both TableWithPK16Fields records exist
    //     Assert.IsTrue(TableWithPK16Fields[2].Find,'Renamed record should exist');
    //     Assert.IsTrue(TableWithPK16Fields[1].Find,'Current record should exist');
    //     // [THEN] Conflict line is removed from the list
    //     Assert.IsFalse(MergeDuplicateConflictsPage.First,'should be no conflicts in the list');
    //     MergeDuplicateConflictsPage.Close;
    //     LibraryVariableStorage.AssertEmpty;
    // end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MergeDuplicatesConflictingRecordsModalHandler')]
    [Scope('OnPrem')]
    procedure T138_ConflictRenameActionCanceledIfUserDenied()
    var
        CustomerBankAccount: array[2] of Record "Customer Bank Account";
        TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary;
        MergeDuplicateConflicts: Page "Merge Duplicate Conflicts";
        MergeDuplicateConflictsPage: TestPage "Merge Duplicate Conflicts";
    begin
        // [FEATURE] [Conflict] [UI]
        // [SCENARIO] Rename action is canceled if user has not confirmed
        Initialize;
        // [GIVEN] Conflicting Customer Bank Account 'X' exists for 2 Customers 'A' and 'B'
        CreateConflictingCustomerBanks(CustomerBankAccount);
        CreateConflict(CustomerBankAccount, TempMergeDuplicatesConflict);
        // [GIVEN] Open page "Merge Duplicate Conflicts", where is record for 'X'
        MergeDuplicateConflicts.Set(TempMergeDuplicatesConflict);
        MergeDuplicateConflictsPage.Trap;
        MergeDuplicateConflicts.Run;
        // [GIVEN] Run "Rename Duplicate" action
        LibraryVariableStorage.Enqueue(ConflictResolution::Rename); // Action for MergeDuplicatesConflictingRecordsModalHandler
        // [GIVEN] PK field value is changed from 'X' to 'Y'
        LibraryVariableStorage.Enqueue(CustomerBankAccount[1].FieldNo(Code)); // PK Field ID
        LibraryVariableStorage.Enqueue(CustomerBankAccount[1].Code + 'X'); // New value for PK field
        // [WHEN] User answers 'No'
        LibraryVariableStorage.Enqueue(false); // Reply for ConfirmHandler
        MergeDuplicateConflictsPage.ViewConflictRecords.Invoke;
        Assert.ExpectedMessage(StrSubstNo(ConfirmRenameTxt, Format(CustomerBankAccount[2].RecordId)), LibraryVariableStorage.DequeueText);

        // [THEN] The Merge Conflicts page is open
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean, 'Merge Conflicts page should be open');
        // [THEN] Conflict line is in the list
        Assert.IsTrue(MergeDuplicateConflictsPage.First, 'should still be conflict in the list');
        // [THEN] Customer 'B' has the bank account 'X'
        Assert.IsTrue(CustomerBankAccount[2].Find, 'Duplicate bank should not exist');
        // [THEN] Customer 'A' has the bank account 'X'
        Assert.IsTrue(CustomerBankAccount[1].Find, 'Current bank should not exist');
        // [THEN] Page is not closed
        MergeDuplicateConflictsPage.Close;
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T139_ConflictRenameActionValidatesModifiedValue()
    var
        Location: Record Location;
        ItemAnalysisViewEntry: array[2] of Record "Item Analysis View Entry";
        MergeDuplicatesConflict: Record "Merge Duplicates Conflict";
        MergeDuplicate: Page "Merge Duplicate";
        MergeDuplicatePage: TestPage "Merge Duplicate";
        NotExistingLocationCode: Code[10];
    begin
        // [FEATURE] [Conflict] [UI]
        // [SCENARIO] Rename conflicting record if the modified field has a relation.
        Initialize;
        // [GIVEN] Two conflicting ItemAnalysisViewEntry, where "Location Code" is 'A', a master field is "Source No."
        Location.FindFirst;
        ItemAnalysisViewEntry[1]."Source No." := LibraryUtility.GenerateGUID;
        ItemAnalysisViewEntry[1]."Location Code" := Location.Code;
        ItemAnalysisViewEntry[1].Insert();
        ItemAnalysisViewEntry[2]."Source No." := LibraryUtility.GenerateGUID;
        ItemAnalysisViewEntry[2]."Location Code" := Location.Code;
        ItemAnalysisViewEntry[2].Insert();
        Commit();
        MergeDuplicatesConflict.Init();
        MergeDuplicatesConflict.Validate("Table ID", DATABASE::"Item Analysis View Entry");
        MergeDuplicatesConflict.Current := ItemAnalysisViewEntry[1].RecordId;
        MergeDuplicatesConflict.Duplicate := ItemAnalysisViewEntry[2].RecordId;
        MergeDuplicatesConflict."Field ID" := ItemAnalysisViewEntry[1].FieldNo("Source No.");

        // [GIVEN] Open MergeDuplicate page for conflicting records
        MergeDuplicate.SetConflict(MergeDuplicatesConflict);
        MergeDuplicatePage.Trap;
        MergeDuplicate.Run;

        // [GIVEN] Got to the field "Location Code", where "Alternative Value" is editable.
        MergeDuplicatePage.Fields.FILTER.SetFilter(Name, ItemAnalysisViewEntry[1].FieldName("Location Code"));
        MergeDuplicatePage.Fields.First;
        Assert.IsTrue(MergeDuplicatePage.Fields."Duplicate Value".Visible, 'Duplicate Value.VISIBLE');
        Assert.IsTrue(MergeDuplicatePage.Fields."Duplicate Value".Editable, 'Duplicate Value.EDITABLE');
        // [GIVEN] Location 'X' does not exist
        NotExistingLocationCode := LibraryUtility.GenerateGUID;
        // [WHEN] Set "Alternative Value" to 'X'
        asserterror MergeDuplicatePage.Fields."Duplicate Value".SetValue(NotExistingLocationCode);
        // [THEN] Error message: 'Value Y that cannot be found in the related table (Location).'
        Assert.ExpectedError(NotFoundLocationErr);

        // [GIVEN] Location 'B'
        Location.FindLast;
        // [WHEN] Set "Alternative Value" to 'b' (lower case)
        MergeDuplicatePage.Fields."Duplicate Value".SetValue(LowerCase(Location.Code));
        // [THEN] "Alternative Value" is 'B'
        MergeDuplicatePage.Fields."Duplicate Value".AssertEquals(Location.Code);

        // [WHEN] Run "Rename Duplicate" action
        MergeDuplicatePage."Rename Duplicate".Invoke;

        // [THEN] ItemAnalysisViewEntry, where "Location Code" is 'B'
        ItemAnalysisViewEntry[2]."Location Code" := Location.Code;
        Assert.IsTrue(ItemAnalysisViewEntry[2].Find, 'renamed record does not exist');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConflictListViewConflictModalHandler,RemoveConflictModalSimpleHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure T140_ConflictDefaultDimIsTakenIntoAccount()
    var
        Customer: array[2] of Record Customer;
        DefaultDimension: Record "Default Dimension";
        Dimension: array[2] of Record Dimension;
        DimensionValue: array[2] of Record "Dimension Value";
        MergeDuplicatesBuffer: Record "Merge Duplicates Buffer";
        MergePage: TestPage "Merge Duplicate";
    begin
        // [FEATURE] [Default Dimension]
        // [SCENARIO] Conflicting Default Dimensions are shown in the list of conflicts
        Initialize;
        // [GIVEN] Customer 'B' has Default Dimension for 'Project'
        LibraryDimension.CreateDimension(Dimension[1]);
        LibraryDimension.CreateDimensionValue(DimensionValue[1], Dimension[1].Code);
        CreateCustomer(Customer[1]);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Customer, Customer[1]."No.", DimensionValue[1]."Dimension Code", DimensionValue[1].Code);
        // [GIVEN] Customer 'A' has Default Dimension for 'Project' and 'Department'
        LibraryDimension.CreateDimension(Dimension[2]);
        LibraryDimension.CreateDimensionValue(DimensionValue[2], Dimension[2].Code);
        CreateCustomer(Customer[2]);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Customer, Customer[2]."No.", DimensionValue[1]."Dimension Code", DimensionValue[1].Code);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Customer, Customer[2]."No.", DimensionValue[2]."Dimension Code", DimensionValue[2].Code);

        // [GIVEN] Open Merge page for 'A'
        MergePage.Trap;
        MergeDuplicatesBuffer.Show(DATABASE::Customer, Customer[2]."No.");

        // [WHEN] Pick 'B' as "Duplicate"
        MergePage.Duplicate.SetValue(Customer[1]."No.");

        // [THEN] Related tables list contains record for "Default Dimension", where "Current Count" is 2, "Duplicate Count" is 1
        Assert.IsTrue(MergePage.Tables.First, 'no related records found');
        MergePage.Tables."Table ID".AssertEquals(Format(DATABASE::"Default Dimension"));
        MergePage.Tables."Current Count".AssertEquals(Format(2));
        MergePage.Tables."Duplicate Count".AssertEquals(Format(1));

        // [GIVEN] Run "Merge" action
        MergePage.Merge.Invoke;
        // [GIVEN] Drill down on Conflicts and run action View
        LibraryVariableStorage.Enqueue(true); // For ConfirmHandler
        MergePage.Conflicts.DrillDown;

        // [WHEN] Answer 'Yes' to confirmation: '... you want to remove record Default Dimension: 18,?'
        Assert.ExpectedMessage(RemoveDefaultDimMsg, LibraryVariableStorage.DequeueText);

        // [THEN] Default Dimensions for 'A' does exist, for 'B' is removed
        DefaultDimension.Get(DATABASE::Customer, Customer[2]."No.", Dimension[1].Code);
        DefaultDimension.Get(DATABASE::Customer, Customer[2]."No.", Dimension[2].Code);
        Assert.IsFalse(
          DefaultDimension.Get(DATABASE::Customer, Customer[1]."No.", Dimension[1].Code), 'default dim is not removed');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerSimple,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T141_MergeNotConflictingDefaultDim()
    var
        Customer: array[2] of Record Customer;
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        DimensionValue: array[2] of Record "Dimension Value";
        MergeDuplicatesBuffer: Record "Merge Duplicates Buffer";
        MergePage: TestPage "Merge Duplicate";
    begin
        // [FEATURE] [Default Dimension]
        // [SCENARIO] Not conflicting Customers Default Dimensions are merged.
        Initialize;
        // [GIVEN] Customer 'A' has Default Dimension for 'Project' = 'X'
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue[1], Dimension.Code);
        CreateCustomer(Customer[1]);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Customer, Customer[1]."No.", DimensionValue[1]."Dimension Code", DimensionValue[1].Code);
        // [GIVEN] Customer 'B' has Default Dimension for 'Department' = 'Y'
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue[2], Dimension.Code);
        CreateCustomer(Customer[2]);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Customer, Customer[2]."No.", DimensionValue[2]."Dimension Code", DimensionValue[2].Code);

        // [GIVEN] Open Merge page for 'A'
        MergePage.Trap;
        MergeDuplicatesBuffer.Show(DATABASE::Customer, Customer[2]."No.");

        // [WHEN] Pick 'B' as "Duplicate"
        MergePage.Duplicate.SetValue(Customer[1]."No.");

        // [THEN] Related tables list contains  record for "Default Dimension"
        Assert.IsTrue(MergePage.Tables.First, 'no related records found');
        MergePage.Tables."Table ID".AssertEquals(Format(DATABASE::"Default Dimension"));
        MergePage.Tables."Current Count".AssertEquals(Format(1));
        MergePage.Tables."Duplicate Count".AssertEquals(Format(1));

        // [WHEN] Run "Merge" action
        LibraryVariableStorage.Enqueue(true); // For ConfirmHandler
        MergePage.Merge.Invoke;

        // [THEN] Customer 'A' has Default Dimension for 'Project' = 'X', 'Department' = 'Y'
        DefaultDimension.Get(DATABASE::Customer, Customer[2]."No.", DimensionValue[2]."Dimension Code");
        DefaultDimension.TestField("Dimension Value Code", DimensionValue[2].Code);
        DefaultDimension.Get(DATABASE::Customer, Customer[2]."No.", DimensionValue[1]."Dimension Code");
        DefaultDimension.TestField("Dimension Value Code", DimensionValue[1].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T145_CollectTableRecordsWithConditionalRelation()
    var
        Customer: array[2] of Record Customer;
        ItemCrossReference: Record "Item Cross Reference";
        Item: Record Item;
        GenJournalLine: Record "Gen. Journal Line";
        TempMergeDuplicatesBuffer: Record "Merge Duplicates Buffer" temporary;
        TempMergeDuplicatesLineBuffer: Record "Merge Duplicates Line Buffer" temporary;
        Type: Option " ",Customer,Vendor;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Respect conditional relations while counting releted records in tables
        Initialize;
        // [GIVEN] Table 5717 contains 1 record for Customer 'A' and 2 record for Customer 'B'
        Item.FindFirst;
        LibrarySales.CreateCustomer(Customer[1]);
        AddItemCrossReference(Item, Type::Customer, Customer[1]."No.", 1);
        LibrarySales.CreateCustomer(Customer[2]);
        AddItemCrossReference(Item, Type::Customer, Customer[2]."No.", 2);
        // [GIVEN] Table 5717 contains 3 records for Vendor 'B'
        AddItemCrossReference(Item, Type::Vendor, Customer[2]."No.", 3);
        // [GIVEN] Table 81 contains 2 record for Customer 'A' and 1 record for Customer 'B'
        AddGenJnlLine(Type::Customer, Customer[1]."No.", 2);
        AddGenJnlLine(Type::Customer, Customer[2]."No.", 1);
        // [GIVEN] Table 81 contains 3 records for Vendor 'A' and 1 record for Vendor 'B'
        AddGenJnlLine(Type::Vendor, Customer[1]."No.", 3);
        AddGenJnlLine(Type::Vendor, Customer[2]."No.", 1);

        // [GIVEN] Prepare Merge for Customer 'A' and 'B'
        TempMergeDuplicatesBuffer.Validate("Table ID", DATABASE::Customer);
        TempMergeDuplicatesBuffer.Validate(Current, Customer[1]."No.");
        TempMergeDuplicatesBuffer.Validate(Duplicate, Customer[2]."No.");

        // [WHEN] AddTableData() to MergeDuplicatesLineBuffer for table 5717
        TempMergeDuplicatesLineBuffer.AddTableData(
          TempMergeDuplicatesBuffer, DATABASE::"Item Cross Reference", ItemCrossReference.FieldNo("Cross-Reference Type No."));

        // [THEN] MergeDuplicatesLineBuffer, where "Current Count"is '1', "Duplicate Count" is '2'
        TempMergeDuplicatesLineBuffer.TestField("Current Count", 1);
        TempMergeDuplicatesLineBuffer.TestField("Duplicate Count", 2);

        // [WHEN] AddTableData() to MergeDuplicatesLineBuffer for table 81
        TempMergeDuplicatesLineBuffer.AddTableData(
          TempMergeDuplicatesBuffer, DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("Account No."));

        // [THEN] MergeDuplicatesLineBuffer, where "Current Count"is '1', "Duplicate Count" is '2'
        TempMergeDuplicatesLineBuffer.TestField("Current Count", 2);
        TempMergeDuplicatesLineBuffer.TestField("Duplicate Count", 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure T150_MergeCustomers()
    var
        Customer: array[2] of Record Customer;
        ActualIntegrationRecord: Record "Integration Record";
        IntegrationRecord: array[2] of Record "Integration Record";
        TempMergeDuplicatesBuffer: Record "Merge Duplicates Buffer" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        O365CouponClaim: Record "O365 Coupon Claim";
        O365PostedCouponClaim: Record "O365 Posted Coupon Claim";
        NativePayment: Record "Native - Payment";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [Customer]
        // [SCENARIO] Action 'Merge Duplicate' removes one of customers
        Initialize;
        // [GIVEN] Customers 'A' (ID = 'AAA') and 'B' (ID = 'BBB')
        LibrarySales.CreateCustomer(Customer[1]);
        IntegrationRecord[1].Get(Customer[1].Id);
        LibrarySales.CreateCustomer(Customer[2]);
        IntegrationRecord[2].Get(Customer[2].Id);
        // [GIVEN] Journal Line, where "Account No." is 'A', "Bal. Account No." is 'B', "Customer Id" is 'AAA'
        GenJournalLine.Init();
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine.Validate("Account No.", Customer[1]."No.");
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::Customer;
        GenJournalLine.Validate("Bal. Account No.", Customer[2]."No.");
        GenJournalLine.Insert();
        GenJournalLine.TestField("Customer Id", IntegrationRecord[1]."Integration ID");
        // [GIVEN] O365CouponClaim, where "Customer Id" is 'AAA'
        O365CouponClaim."Claim ID" := LibraryUtility.GenerateGUID;
        O365CouponClaim."Customer Id" := IntegrationRecord[1]."Integration ID";
        O365CouponClaim.Insert();
        // [GIVEN] O365CouponClaim, where "Customer Id" is 'AAA'
        O365PostedCouponClaim."Claim ID" := LibraryUtility.GenerateGUID;
        O365PostedCouponClaim."Customer Id" := IntegrationRecord[1]."Integration ID";
        O365PostedCouponClaim.Insert();
        // [GIVEN] Native Payment, where "Customer No." is 'A', "Customer Id" is 'AAA'
        NativePayment."Applies-to Invoice Id" := CreateGuid;
        NativePayment.Validate("Customer No.", Customer[1]."No.");
        NativePayment.Insert();
        // [GIVEN] SalesInvoiceEntityAggregate, where "Sell-to Customer No." is 'A', "Customer Id" is 'AAA'
        SalesInvoiceEntityAggregate."No." := LibraryUtility.GenerateGUID;
        SalesInvoiceEntityAggregate.Validate("Sell-to Customer No.", Customer[1]."No.");
        SalesInvoiceEntityAggregate.Insert();
        // [GIVEN] SalesOrderEntityBuffer, where "Sell-to Customer No." is 'A', "Customer Id" is 'AAA'
        SalesOrderEntityBuffer."No." := LibraryUtility.GenerateGUID;
        SalesOrderEntityBuffer.Validate("Sell-to Customer No.", Customer[1]."No.");
        SalesOrderEntityBuffer.Insert();
        // [GIVEN] SalesQuoteEntityBuffer, where "Sell-to Customer No." is 'A', "Customer Id" is 'AAA'
        SalesQuoteEntityBuffer."No." := LibraryUtility.GenerateGUID;
        SalesQuoteEntityBuffer.Validate("Sell-to Customer No.", Customer[1]."No.");
        SalesQuoteEntityBuffer.Insert();
        // [GIVEN] SalesCrMemoEntityBuffer, where "Sell-to Customer No." is 'A', "Customer Id" is 'AAA'
        SalesCrMemoEntityBuffer."No." := LibraryUtility.GenerateGUID;
        SalesCrMemoEntityBuffer.Validate("Sell-to Customer No.", Customer[1]."No.");
        SalesCrMemoEntityBuffer.Insert();
        // [GIVEN] Default Dimension, where "Table ID" is '18', "No." is 'A', ParentID is 'AAA'
        DimensionValue.FindFirst;
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, Customer[1]."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.TestField(ParentId, IntegrationRecord[1]."Integration ID");

        // [WHEN] Merge 'A' to 'B'
        TempMergeDuplicatesBuffer."Table ID" := DATABASE::Customer;
        TempMergeDuplicatesBuffer.Duplicate := Customer[1]."No.";
        TempMergeDuplicatesBuffer.Current := Customer[2]."No.";
        TempMergeDuplicatesBuffer.Insert();
        LibraryVariableStorage.Enqueue(true); // Reply for ConfirmHandler
        TempMergeDuplicatesBuffer.Merge;
        Assert.ExpectedMessage(ConfirmMergeTxt, LibraryVariableStorage.DequeueText);

        // [THEN] Customer 'A' does not exist,
        Assert.IsFalse(Customer[1].Find, 'Customer A must not exist');
        // [THEN] Integration Record 'AAA', where "Deleted On" is filled, "Record ID" points to 'A'
        ActualIntegrationRecord.Get(IntegrationRecord[1]."Integration ID");
        Assert.AreNotEqual(0DT, ActualIntegrationRecord."Deleted On", 'Deleted On must not be blank.');
        Assert.AreEqual(ActualIntegrationRecord."Record ID", IntegrationRecord[1]."Record ID", 'Record ID #1');
        // [THEN] Customer 'B' does exist, where Name = 'B', ID is 'BBB'
        Assert.IsTrue(Customer[2].Find, 'Customer B must exist');
        Customer[2].TestField(Name, Customer[2].Name);
        Customer[2].TestField(Id, IntegrationRecord[2]."Integration ID");
        // [THEN] Integration Record 'BBB', where "Deleted On" is blank, "Record ID" points to 'B'
        ActualIntegrationRecord.Get(IntegrationRecord[2]."Integration ID");
        Assert.AreEqual(0DT, ActualIntegrationRecord."Deleted On", 'Deleted On must be blank.');
        Assert.AreEqual(ActualIntegrationRecord."Record ID", IntegrationRecord[2]."Record ID", 'Record ID #2');
        // [THEN] Journal Line, where "Account No." is 'B', "Bal. Account No." is 'B', "Customer Id" is 'BBB'
        GenJournalLine.Find;
        GenJournalLine.TestField("Bal. Account No.", Customer[2]."No.");
        GenJournalLine.TestField("Account No.", Customer[2]."No.");
        GenJournalLine.TestField("Customer Id", IntegrationRecord[2]."Integration ID");
        // [THEN] O365CouponClaim, where "Customer Id" is 'BBB'
        O365CouponClaim.Find;
        O365CouponClaim.TestField("Customer Id", IntegrationRecord[2]."Integration ID");
        // [THEN] O365PostedCouponClaim, where "Customer Id" is 'BBB'
        O365PostedCouponClaim.Find;
        O365PostedCouponClaim.TestField("Customer Id", IntegrationRecord[2]."Integration ID");
        // [THEN] Native Payment, where "Customer No." is 'B', "Customer Id" is 'BBB'
        NativePayment.Find;
        NativePayment.TestField("Customer No.", Customer[2]."No.");
        NativePayment.TestField("Customer Id", IntegrationRecord[2]."Integration ID");
        // [GIVEN] SalesInvoiceEntityAggregate, where "Sell-to Customer No." is 'B', "Customer Id" is 'BBB'
        SalesInvoiceEntityAggregate.Find;
        SalesInvoiceEntityAggregate.TestField("Sell-to Customer No.", Customer[2]."No.");
        SalesInvoiceEntityAggregate.TestField("Customer Id", IntegrationRecord[2]."Integration ID");
        // [GIVEN] SalesOrderEntityBuffer, where "Sell-to Customer No." is 'B', "Customer Id" is 'BBB'
        SalesOrderEntityBuffer.Find;
        SalesOrderEntityBuffer.TestField("Sell-to Customer No.", Customer[2]."No.");
        SalesOrderEntityBuffer.TestField("Customer Id", IntegrationRecord[2]."Integration ID");
        // [GIVEN] SalesQuoteEntityBuffer, where "Sell-to Customer No." is 'B', "Customer Id" is 'BBB'
        SalesQuoteEntityBuffer.Find;
        SalesQuoteEntityBuffer.TestField("Sell-to Customer No.", Customer[2]."No.");
        SalesQuoteEntityBuffer.TestField("Customer Id", IntegrationRecord[2]."Integration ID");
        // [GIVEN] SalesCrMemoEntityBuffer, where "Sell-to Customer No." is 'B', "Customer Id" is 'BBB'
        SalesCrMemoEntityBuffer.Find;
        SalesCrMemoEntityBuffer.TestField("Sell-to Customer No.", Customer[2]."No.");
        SalesCrMemoEntityBuffer.TestField("Customer Id", IntegrationRecord[2]."Integration ID");
        // [GIVEN] Default Dimension, where "Table ID" is '18', "No." is 'B', ParentID is 'BBB'
        DefaultDimension.SetRange("No.", Customer[2]."No.");
        DefaultDimension.FindFirst;
        DefaultDimension.TestField(ParentId, IntegrationRecord[2]."Integration ID");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T151_MergeCustomersFailOnRename()
    var
        Customer: array[2] of Record Customer;
        TempMergeDuplicatesBuffer: Record "Merge Duplicates Buffer" temporary;
        MyCustomer: Record "My Customer";
    begin
        // [FEATURE] [Conflict]
        // [SCENARIO] Action 'Merge Duplicate' does not remove one of customers on failure
        Initialize;
        // [GIVEN] Customers 'A' and 'B'are both in "My Customer"
        MyCustomer."User ID" := UserId;
        LibrarySales.CreateCustomer(Customer[1]);
        MyCustomer."Customer No." := Customer[1]."No.";
        MyCustomer.Insert();
        LibrarySales.CreateCustomer(Customer[2]);
        MyCustomer."Customer No." := Customer[2]."No.";
        MyCustomer.Insert();

        // [WHEN] Merge duplicate 'B' to current 'A', but fail on RENAME
        TempMergeDuplicatesBuffer."Table ID" := DATABASE::Customer;
        TempMergeDuplicatesBuffer.Current := Customer[1]."No.";
        TempMergeDuplicatesBuffer.Validate(Duplicate, Customer[2]."No.");
        TempMergeDuplicatesBuffer.Insert();
        TempMergeDuplicatesBuffer.Merge;

        // [THEN] Conflicts is '1'
        TempMergeDuplicatesBuffer.TestField(Conflicts, 1);
        // [THEN] Customer 'A' does exist
        Assert.IsTrue(Customer[1].Find, 'Customer A must exist');
        // [THEN] Customer 'B' does exist
        Assert.IsTrue(Customer[2].Find, 'Customer B must exist');
    end;

    [Test]
    [HandlerFunctions('CustomerLookupModalHandler')]
    [Scope('OnPrem')]
    procedure T152_MergeCustomersSameNoLookup()
    var
        Customer: Record Customer;
        MergeDuplicatesBuffer: Record "Merge Duplicates Buffer";
        MergePage: TestPage "Merge Duplicate";
    begin
        // [FEATURE] [Customer] [UI]
        // [SCENARIO] "Current" and "Duplicate" must be different on lookup "Current"
        Initialize;
        // [GIVEN] Customer 'A'
        Customer.FindFirst;
        // [GIVEN] Open Merge, where "Duplicate" is 'A'
        MergePage.Trap;
        MergeDuplicatesBuffer.Show(DATABASE::Customer, Customer."No.");
        LibraryVariableStorage.Enqueue(Customer."No."); // to CustomerListModalHandler
        // [WHEN] Lookup the same customer 'A' for "Duplicate"
        asserterror MergePage.Duplicate.Lookup;
        // [THEN] Error: "Current must not be A"
        Assert.ExpectedError(StrSubstNo(NewKeyErr, Customer."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T153_MergeCustomersSameNoValidate()
    var
        Customer: Record Customer;
        MergeDuplicatesBuffer: Record "Merge Duplicates Buffer";
        MergePage: TestPage "Merge Duplicate";
    begin
        // [FEATURE] [Customer] [UI]
        // [SCENARIO] "Current" and "Duplicate" must be different on validate "Current"
        Initialize;
        // [GIVEN] Customer 'A'
        Customer.FindFirst;
        // [GIVEN] Open Merge, where "Duplicate" is 'A'
        MergePage.Trap;
        MergeDuplicatesBuffer.Show(DATABASE::Customer, Customer."No.");
        LibraryVariableStorage.Enqueue(Customer."No."); // to CustomerListModalHandler
        // [WHEN] Set the same customer 'A' for "Duplicate"
        asserterror MergePage.Duplicate.SetValue(Customer."No.");
        // [THEN] Error: "Current must not be A"
        Assert.ExpectedError(StrSubstNo(NewKeyErr, Customer."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T154_MergeCustomersBlankNewNo()
    var
        Customer: Record Customer;
        MergeDuplicatesBuffer: Record "Merge Duplicates Buffer";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] "Current" must not be blank
        Initialize;
        // [GIVEN] Customer 'A'
        Customer.FindFirst;
        // [GIVEN] Open Merge, where "Current" is 'A'
        MergeDuplicatesBuffer.Init();
        MergeDuplicatesBuffer.Validate("Table ID", DATABASE::Customer);
        MergeDuplicatesBuffer.Validate(Current, Customer."No.");
        // [WHEN] Set "Duplicate" as <blank>
        asserterror MergeDuplicatesBuffer.Validate(Duplicate, '');
        // [THEN] Error: "Duplicate must have a value..."
        Assert.ExpectedError(NewKeyMustHaveValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T155_CollectFieldsDataForWrongOldKey()
    var
        Customer: Record Customer;
        MergeDuplicatesBuffer: Record "Merge Duplicates Buffer";
    begin
        // [FEATURE] [UT]
        Initialize;
        // [GIVEN] Customer 'X' does not exist
        // [GIVEN] "Duplicate" is 'X', "Current" is <blank>
        MergeDuplicatesBuffer.Init();
        MergeDuplicatesBuffer.Validate("Table ID", DATABASE::Customer);
        MergeDuplicatesBuffer.Current := '';

        // [WHEN] CollectFieldData
        Customer.FindFirst;
        asserterror MergeDuplicatesBuffer.Validate(Duplicate, Customer."No.");
        // [THEN] Error message 'Current record is not set.'
        Assert.ExpectedError(CurrRecordErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T156_CollectFieldsDataSkipsFieldEqualInBothRecords()
    var
        Customer: array[2] of Record Customer;
        MergeDuplicatesBuffer: Record "Merge Duplicates Buffer";
        TempMergeDuplicatesLineBuffer: Record "Merge Duplicates Line Buffer" temporary;
        TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary;
    begin
        // [FEATURE] [UT]
        Initialize;
        // [GIVEN] Customers 'A' and 'B'
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);
        // [GIVEN] "Duplicate" is 'A', "Current" is 'B'
        MergeDuplicatesBuffer.Init();
        MergeDuplicatesBuffer.Validate("Table ID", DATABASE::Customer);
        MergeDuplicatesBuffer.Current := Customer[1]."No.";

        // [WHEN] CollectFieldData
        MergeDuplicatesBuffer.Validate(Duplicate, Customer[2]."No.");

        // [THEN] There are no fields, where Old and New values are equal; no conflicts
        MergeDuplicatesBuffer.GetLines(TempMergeDuplicatesLineBuffer, TempMergeDuplicatesConflict);
        TempMergeDuplicatesLineBuffer.SetRange(Type, TempMergeDuplicatesLineBuffer.Type::Field);
        Assert.IsTrue(TempMergeDuplicatesLineBuffer.FindSet, 'there must be field lines');
        repeat
            if TempMergeDuplicatesLineBuffer."Current Value" = TempMergeDuplicatesLineBuffer."Duplicate Value" then
                Error(StrSubstNo(SameValueErr, TempMergeDuplicatesLineBuffer.ID));
        until TempMergeDuplicatesLineBuffer.Next = 0;
        Assert.RecordIsEmpty(TempMergeDuplicatesConflict);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,MessageHandlerSimple')]
    [Scope('OnPrem')]
    procedure T180_ExtendCustomerMergeWithFieldWithoutRelation()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: array[2] of Record Customer;
        MergeDuplicatesBuffer: Record "Merge Duplicates Buffer";
        TestMergeDuplicates: Codeunit "Test Merge Duplicates";
        MergeDuplicatePage: TestPage "Merge Duplicate";
    begin
        // [FEATURE] [Event]
        // [SCENARIO] Include the field that has no table relation into the merge process
        Initialize;
        // [GIVEN] Customers 'A' and 'B'
        CreateCustomer(Customer[1]);
        CreateCustomer(Customer[2]);

        // [GIVEN] 2 Gen. Journal Lines, where "Creditor No." is 'B' (has no relation to Customer)
        GenJournalLine.DeleteAll();
        GenJournalLine."Creditor No." := Customer[2]."No.";
        GenJournalLine.Insert();
        GenJournalLine."Line No." += 1;
        GenJournalLine.Insert();
        GenJournalLine."Line No." += 1;
        // [GIVEN] 1 Gen. Journal Line, where "Creditor No." is 'A' (has no relation to Customer)
        GenJournalLine."Creditor No." := Customer[1]."No.";
        GenJournalLine.Insert();

        // [GIVEN] Subscribe to TAB64.OnAfterFindRelatedFields to include TAB81."Creditor No."
        BindSubscription(TestMergeDuplicates);

        // [WHEN] Open Merge Duplicates page for 'A' and 'B'
        MergeDuplicatePage.Trap;
        MergeDuplicatesBuffer.Show(DATABASE::Customer, Customer[1]."No.");
        MergeDuplicatePage.Duplicate.SetValue(Customer[2]."No.");

        // [THEN] See "Creditor No." of table 81 in the related records list, "Current Count" is 1, "Duplicate Count" is 2.
        MergeDuplicatePage.Tables.FILTER.SetFilter("Table ID", '81');
        Assert.IsTrue(MergeDuplicatePage.Tables.First, 'Table 81 is not in the list');
        MergeDuplicatePage.Tables."Current Count".AssertEquals(Format(1));
        MergeDuplicatePage.Tables."Duplicate Count".AssertEquals(Format(2));

        // [WHEN] Run "Merge" action
        MergeDuplicatePage.Merge.Invoke;

        // [THEN] 3 Gen. Journal Lines, where "Creditor No." is 'A'
        GenJournalLine.SetRange("Creditor No.", Customer[1]."No.");
        Assert.RecordCount(GenJournalLine, 3);
        // [THEN] No Gen. Journal Lines, where "Creditor No." is 'B'
        GenJournalLine.SetRange("Creditor No.", Customer[2]."No.");
        Assert.RecordIsEmpty(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T200_MergeVendors()
    var
        Vendor: array[2] of Record Vendor;
        ActualIntegrationRecord: Record "Integration Record";
        IntegrationRecord: array[2] of Record "Integration Record";
        TempMergeDuplicatesBuffer: Record "Merge Duplicates Buffer" temporary;
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        IncomingDocument: Record "Incoming Document";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO] Action 'Merge Duplicate' removes one of vendors
        Initialize;
        // [GIVEN] Vendors 'A' (ID = 'AAA') and 'B' (ID = 'BBB')
        LibraryPurchase.CreateVendor(Vendor[1]);
        IntegrationRecord[1].Get(Vendor[1].Id);
        LibraryPurchase.CreateVendor(Vendor[2]);
        IntegrationRecord[2].Get(Vendor[2].Id);
        // [GIVEN] PurchInvEntityAggregate, where "Buy-from Vendor No." is 'A', "Vendor Id" is 'AAA'
        PurchInvEntityAggregate."No." := LibraryUtility.GenerateGUID;
        PurchInvEntityAggregate.Validate("Buy-from Vendor No.", Vendor[1]."No.");
        PurchInvEntityAggregate.Insert();
        // [GIVEN] IncomingDocument, where "Vendor No." is 'A', "Vendor ID" is 'AAA'
        IncomingDocument."Entry No." := -1;
        IncomingDocument.Validate("Vendor No.", Vendor[1]."No.");
        IncomingDocument.Validate("Vendor Id", IntegrationRecord[1]."Integration ID");
        IncomingDocument.Insert();
        // [GIVEN] Default Dimension, where "Table ID" is '18', "No." is 'A', ParentID is 'AAA'
        DimensionValue.FindFirst;
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension, Vendor[1]."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.TestField(ParentId, IntegrationRecord[1]."Integration ID");

        // [WHEN] Merge 'A' to 'B'
        TempMergeDuplicatesBuffer."Table ID" := DATABASE::Vendor;
        TempMergeDuplicatesBuffer.Duplicate := Vendor[1]."No.";
        TempMergeDuplicatesBuffer.Current := Vendor[2]."No.";
        TempMergeDuplicatesBuffer.Insert();
        TempMergeDuplicatesBuffer.Merge;

        // [THEN] Vendor 'A' does not exist,
        Assert.IsFalse(Vendor[1].Find, 'Vendor A must not exist');
        // [THEN] Integration Record 'AAA', where "Deleted On" is filled, "Record ID" points to 'A'
        ActualIntegrationRecord.Get(IntegrationRecord[1]."Integration ID");
        Assert.AreNotEqual(0DT, ActualIntegrationRecord."Deleted On", 'Deleted On must not be blank.');
        Assert.AreEqual(ActualIntegrationRecord."Record ID", IntegrationRecord[1]."Record ID", 'Record ID #1');
        // [THEN] Vendor 'B' does exist, where Name = 'B', "Id" is 'BBB'
        Assert.IsTrue(Vendor[2].Find, 'Vendor B must exist');
        Vendor[2].TestField(Name, Vendor[2].Name);
        Vendor[2].TestField(Id, IntegrationRecord[2]."Integration ID");
        // [THEN] Integration Record 'BBB', where "Deleted On" is blank, "Record ID" points to 'B'
        ActualIntegrationRecord.Get(IntegrationRecord[2]."Integration ID");
        Assert.AreEqual(0DT, ActualIntegrationRecord."Deleted On", 'Deleted On must be blank.');
        Assert.AreEqual(ActualIntegrationRecord."Record ID", IntegrationRecord[2]."Record ID", 'Record ID #2');
        // [GIVEN] PurchInvEntityAggregate, where "Sell-to Vendor No." is 'B', "Vendor Id" is 'BBB'
        PurchInvEntityAggregate.Find;
        PurchInvEntityAggregate.TestField("Buy-from Vendor No.", Vendor[2]."No.");
        PurchInvEntityAggregate.TestField("Vendor Id", IntegrationRecord[2]."Integration ID");
        // [GIVEN] IncomingDocument, where "Vendor No." is 'B', "Vendor ID" is 'BBB'
        IncomingDocument.Find;
        IncomingDocument.TestField("Vendor No.", Vendor[2]."No.");
        IncomingDocument.TestField("Vendor Id", IntegrationRecord[2]."Integration ID");
        // [GIVEN] Default Dimension, where "Table ID" is '18', "No." is 'B', ParentID is 'BBB'
        DefaultDimension.SetRange("No.", Vendor[2]."No.");
        DefaultDimension.FindFirst;
        DefaultDimension.TestField(ParentId, IntegrationRecord[2]."Integration ID");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('VendorLookupModalHandler')]
    [Scope('OnPrem')]
    procedure T210_MergeActionOnVendorCard()
    var
        Vendor: array[2] of Record Vendor;
        VendorCardPage: TestPage "Vendor Card";
        MergePage: TestPage "Merge Duplicate";
    begin
        // [FEATURE] [Vendor] [UI]
        // [SCENARIO] Run action 'Merge Duplicate' from Vendor Card.
        Initialize;
        // [GIVEN] Vendors 'A' and 'B'
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryPurchase.CreateVendor(Vendor[2]);
        // [GIVEN] Open Vendor Card on 'A'
        VendorCardPage.OpenEdit;
        VendorCardPage.FILTER.SetFilter("No.", Vendor[1]."No.");

        // [WHEN] Run action 'Merge Duplicate'
        MergePage.Trap;
        VendorCardPage.MergeDuplicate.Invoke;

        // [THEN] Open page 'Merge Duplicate', where "Current" is 'A', "Duplicate" is <blank>
        MergePage.Current.AssertEquals(Vendor[1]."No.");
        Assert.IsFalse(MergePage.Current.Editable, 'Current Editable');
        MergePage.Duplicate.AssertEquals('');
        Assert.IsTrue(MergePage.Duplicate.Editable, 'Duplicate Editable');
        // [THEN] Actions "Remove Dupllicate", "Rename Duplicate" are not visible
        Assert.IsFalse(MergePage."Remove Duplicate".Visible, 'Remove should be invisible');
        Assert.IsFalse(MergePage."Rename Duplicate".Visible, 'Rename should be invisible');

        // [WHEN] Lookup "Duplicate" for 'B' and push 'OK'
        LibraryVariableStorage.Enqueue(Vendor[2]."No."); // to VendorListModalHandler
        MergePage.Duplicate.Lookup;
        // [THEN] "Duplicate" is 'B'
        MergePage.Duplicate.AssertEquals(Vendor[2]."No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T250_MergeContacts()
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        ContDuplicateSearchString: Record "Cont. Duplicate Search String";
        Contact: array[2] of Record Contact;
        Customer: array[2] of Record Customer;
        ActualIntegrationRecord: Record "Integration Record";
        IntegrationRecord: array[2] of Record "Integration Record";
        TempMergeDuplicatesBuffer: Record "Merge Duplicates Buffer" temporary;
    begin
        // [FEATURE] [Contact]
        // [SCENARIO] Action 'Merge Duplicate' removes one of contacts
        Initialize;
        // [GIVEN] Customer 'A' with Contact 'CA' ("Integration ID" = 'AAA')
        LibraryMarketing.CreateContactWithCustomer(Contact[1], Customer[1]);
        IntegrationRecord[1].FindByRecordId(Contact[1].RecordId);
        // [GIVEN] Customer 'B' with Contact 'CB' ("Integration ID" = 'BBB')
        LibraryMarketing.CreateContactWithCustomer(Contact[2], Customer[2]);
        IntegrationRecord[2].FindByRecordId(Contact[2].RecordId);
        // [GIVEN] Merge Customer 'A' to 'B'
        TempMergeDuplicatesBuffer."Table ID" := DATABASE::Customer;
        TempMergeDuplicatesBuffer.Duplicate := Customer[1]."No.";
        TempMergeDuplicatesBuffer.Current := Customer[2]."No.";
        TempMergeDuplicatesBuffer.Insert();
        TempMergeDuplicatesBuffer.Merge;
        // [GIVEN] Customer 'A' is removed, both contacts are related to Customer 'B'
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", Customer[2]."No.");
        Assert.RecordCount(ContactBusinessRelation, 4);
        ContactBusinessRelation.SetRange("No.", Customer[1]."No.");
        Assert.RecordCount(ContactBusinessRelation, 0);

        // [GIVEN] Remove conflicting records in ContDuplicateSearchString
        ContDuplicateSearchString.SetRange("Contact Company No.", Contact[1]."No.");
        ContDuplicateSearchString.DeleteAll();

        // [WHEN] Merge Contact 'CA' to 'CB'
        TempMergeDuplicatesBuffer."Table ID" := DATABASE::Contact;
        TempMergeDuplicatesBuffer.Duplicate := Contact[1]."No.";
        TempMergeDuplicatesBuffer.Current := Contact[2]."No.";
        TempMergeDuplicatesBuffer.Insert();
        TempMergeDuplicatesBuffer.Merge;

        // [THEN] Contact 'CA' does not exist,
        Assert.IsFalse(Contact[1].Find, 'Contact A must not exist');
        // [THEN] Integration Record 'AAA', where "Deleted On" is filled, "Record ID" points to 'CA'
        ActualIntegrationRecord.Get(IntegrationRecord[1]."Integration ID");
        Assert.AreNotEqual(0DT, ActualIntegrationRecord."Deleted On", 'Deleted On must not be blank.');
        Assert.AreEqual(ActualIntegrationRecord."Record ID", IntegrationRecord[1]."Record ID", 'Record ID #1');
        // [THEN] Contact 'CB' does exist, where Name = 'B'
        Assert.IsTrue(Contact[2].Find, 'Contact B must exist');
        Contact[2].TestField(Name, Contact[2].Name);
        // [THEN] Integration Record 'BBB', where "Deleted On" is blank, "Record ID" points to 'CB'
        ActualIntegrationRecord.Get(IntegrationRecord[2]."Integration ID");
        Assert.AreEqual(0DT, ActualIntegrationRecord."Deleted On", 'Deleted On must be blank.');
        Assert.AreEqual(ActualIntegrationRecord."Record ID", IntegrationRecord[2]."Record ID", 'Record ID #2');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ContactLookupModalHandler')]
    [Scope('OnPrem')]
    procedure T260_MergeActionOnContactCard()
    var
        Customer: array[2] of Record Customer;
        Contact: array[2] of Record Contact;
        ContactCardPage: TestPage "Contact Card";
        MergePage: TestPage "Merge Duplicate";
    begin
        // [FEATURE] [Contact] [UI]
        // [SCENARIO] Run action 'Merge Duplicate' from Contact Card.
        Initialize;
        // [GIVEN] Contacts 'A' and 'B'
        LibraryMarketing.CreateContactWithCustomer(Contact[1], Customer[1]);
        LibraryMarketing.CreateContactWithCustomer(Contact[2], Customer[2]);
        // [GIVEN] Open Contact Card on 'A'
        ContactCardPage.OpenEdit;
        ContactCardPage.FILTER.SetFilter("No.", Contact[1]."No.");

        // [WHEN] Run action 'Merge Duplicate'
        MergePage.Trap;
        ContactCardPage.MergeDuplicate.Invoke;

        // [THEN] Open page 'Merge Duplicate', where "Current" is 'A', "Duplicate" is <blank>
        MergePage.Current.AssertEquals(Contact[1]."No.");
        Assert.IsFalse(MergePage.Current.Editable, 'Current Editable');
        MergePage.Duplicate.AssertEquals('');
        Assert.IsTrue(MergePage.Duplicate.Editable, 'Duplicate Editable');
        // [THEN] Actions "Remove Dupllicate", "Rename Duplicate" are not visible
        Assert.IsFalse(MergePage."Remove Duplicate".Visible, 'Remove should be invisible');
        Assert.IsFalse(MergePage."Rename Duplicate".Visible, 'Rename should be invisible');

        // [WHEN] Lookup "Duplicate" for 'B' and push 'OK'
        LibraryVariableStorage.Enqueue(Contact[2]."No."); // to ContactListModalHandler
        MergePage.Duplicate.Lookup;
        // [THEN] "Duplicate" is 'B'
        MergePage.Duplicate.AssertEquals(Contact[2]."No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure T150_MergeCustomers_IntegrationDisabled()
    var
        Customer: array[2] of Record Customer;
        IntegrationRecord: array[2] of Record "Integration Record";
        TempMergeDuplicatesBuffer: Record "Merge Duplicates Buffer" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        O365CouponClaim: Record "O365 Coupon Claim";
        O365PostedCouponClaim: Record "O365 Posted Coupon Claim";
        NativePayment: Record "Native - Payment";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 314793] Action 'Merge Duplicate' removes one of customers when Integration Service is disabled.
        Initialize;
        // [GIVEN] Intergration services disabled, Integraion Record table has been cleared.
        GenJournalLine.DeleteAll();
        DisableIntegration;
        // [GIVEN] Customers 'A' (ID = '0') and 'B' (ID = '0')
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);
        AssertIntegrationRecordNotFound(Customer[1].Id);
        AssertIntegrationRecordNotFound(Customer[2].Id);
        Assert.TableIsEmpty(DATABASE::"Integration Record");

        // [GIVEN] Journal Line, where "Account No." is 'A', "Bal. Account No." is 'B', "Customer Id" is '0'
        GenJournalLine.Init();
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine.Validate("Account No.", Customer[1]."No.");
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::Customer;
        GenJournalLine.Validate("Bal. Account No.", Customer[2]."No.");
        GenJournalLine.Insert();
        GenJournalLine.TestField("Customer Id", IntegrationRecord[1]."Integration ID");
        // [GIVEN] O365CouponClaim, where "Customer Id" is '0'
        O365CouponClaim."Claim ID" := LibraryUtility.GenerateGUID;
        O365CouponClaim."Customer Id" := IntegrationRecord[1]."Integration ID";
        O365CouponClaim.Insert();
        // [GIVEN] O365CouponClaim, where "Customer Id" is '0'
        O365PostedCouponClaim."Claim ID" := LibraryUtility.GenerateGUID;
        O365PostedCouponClaim."Customer Id" := IntegrationRecord[1]."Integration ID";
        O365PostedCouponClaim.Insert();
        // [GIVEN] Native Payment, where "Customer No." is 'A', "Customer Id" is '0'
        NativePayment."Applies-to Invoice Id" := CreateGuid;
        NativePayment.Validate("Customer No.", Customer[1]."No.");
        NativePayment.Insert();
        // [GIVEN] SalesInvoiceEntityAggregate, where "Sell-to Customer No." is 'A', "Customer Id" is '0'
        SalesInvoiceEntityAggregate."No." := LibraryUtility.GenerateGUID;
        SalesInvoiceEntityAggregate.Validate("Sell-to Customer No.", Customer[1]."No.");
        SalesInvoiceEntityAggregate.Insert();
        // [GIVEN] SalesOrderEntityBuffer, where "Sell-to Customer No." is 'A', "Customer Id" is '0'
        SalesOrderEntityBuffer."No." := LibraryUtility.GenerateGUID;
        SalesOrderEntityBuffer.Validate("Sell-to Customer No.", Customer[1]."No.");
        SalesOrderEntityBuffer.Insert();
        // [GIVEN] SalesQuoteEntityBuffer, where "Sell-to Customer No." is 'A', "Customer Id" is '0'
        SalesQuoteEntityBuffer."No." := LibraryUtility.GenerateGUID;
        SalesQuoteEntityBuffer.Validate("Sell-to Customer No.", Customer[1]."No.");
        SalesQuoteEntityBuffer.Insert();
        // [GIVEN] SalesCrMemoEntityBuffer, where "Sell-to Customer No." is 'A', "Customer Id" is '0'
        SalesCrMemoEntityBuffer."No." := LibraryUtility.GenerateGUID;
        SalesCrMemoEntityBuffer.Validate("Sell-to Customer No.", Customer[1]."No.");
        SalesCrMemoEntityBuffer.Insert();
        // [GIVEN] Default Dimension, where "Table ID" is '18', "No." is 'A', ParentID is '0'
        DimensionValue.FindFirst;
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, Customer[1]."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.TestField(ParentId, IntegrationRecord[1]."Integration ID");

        // [WHEN] Merge 'A' to 'B'
        TempMergeDuplicatesBuffer."Table ID" := DATABASE::Customer;
        TempMergeDuplicatesBuffer.Duplicate := Customer[1]."No.";
        TempMergeDuplicatesBuffer.Current := Customer[2]."No.";
        TempMergeDuplicatesBuffer.Insert();
        LibraryVariableStorage.Enqueue(true); // Reply for ConfirmHandler
        TempMergeDuplicatesBuffer.Merge;
        Assert.ExpectedMessage(ConfirmMergeTxt, LibraryVariableStorage.DequeueText);

        // [THEN] Customer 'A' does not exist,
        Assert.IsFalse(Customer[1].Find, 'Customer A must not exist');

        // [THEN] Customer 'B' does exist, where Name = 'B', ID is '0'
        Assert.IsTrue(Customer[2].Find, 'Customer B must exist');
        Customer[2].TestField(Name, Customer[2].Name);
        Customer[2].TestField(Id, IntegrationRecord[2]."Integration ID");
        AssertIntegrationRecordNotFound(Customer[2].Id);

        // [THEN] Journal Line, where "Account No." is 'B', "Bal. Account No." is 'B', "Customer Id" is '0'
        GenJournalLine.Find;
        GenJournalLine.TestField("Bal. Account No.", Customer[2]."No.");
        GenJournalLine.TestField("Account No.", Customer[2]."No.");
        GenJournalLine.TestField("Customer Id", IntegrationRecord[2]."Integration ID");
        // [THEN] O365CouponClaim, where "Customer Id" is '0'
        O365CouponClaim.Find;
        O365CouponClaim.TestField("Customer Id", IntegrationRecord[2]."Integration ID");
        // [THEN] O365PostedCouponClaim, where "Customer Id" is '0'
        O365PostedCouponClaim.Find;
        O365PostedCouponClaim.TestField("Customer Id", IntegrationRecord[2]."Integration ID");
        // [THEN] Native Payment, where "Customer No." is 'B', "Customer Id" is '0'
        NativePayment.Find;
        NativePayment.TestField("Customer No.", Customer[2]."No.");
        NativePayment.TestField("Customer Id", IntegrationRecord[2]."Integration ID");
        // [THEN] SalesInvoiceEntityAggregate, where "Sell-to Customer No." is 'B', "Customer Id" is '0'
        SalesInvoiceEntityAggregate.Find;
        SalesInvoiceEntityAggregate.TestField("Sell-to Customer No.", Customer[2]."No.");
        SalesInvoiceEntityAggregate.TestField("Customer Id", IntegrationRecord[2]."Integration ID");
        // [THEN] SalesOrderEntityBuffer, where "Sell-to Customer No." is 'B', "Customer Id" is '0'
        SalesOrderEntityBuffer.Find;
        SalesOrderEntityBuffer.TestField("Sell-to Customer No.", Customer[2]."No.");
        SalesOrderEntityBuffer.TestField("Customer Id", IntegrationRecord[2]."Integration ID");
        // [THEN] SalesQuoteEntityBuffer, where "Sell-to Customer No." is 'B', "Customer Id" is '0'
        SalesQuoteEntityBuffer.Find;
        SalesQuoteEntityBuffer.TestField("Sell-to Customer No.", Customer[2]."No.");
        SalesQuoteEntityBuffer.TestField("Customer Id", IntegrationRecord[2]."Integration ID");
        // [THEN] SalesCrMemoEntityBuffer, where "Sell-to Customer No." is 'B', "Customer Id" is '0'
        SalesCrMemoEntityBuffer.Find;
        SalesCrMemoEntityBuffer.TestField("Sell-to Customer No.", Customer[2]."No.");
        SalesCrMemoEntityBuffer.TestField("Customer Id", IntegrationRecord[2]."Integration ID");
        // [THEN] Default Dimension, where "Table ID" is '18', "No." is 'B', ParentID is '0'
        DefaultDimension.SetRange("No.", Customer[2]."No.");
        DefaultDimension.FindFirst;
        DefaultDimension.TestField(ParentId, IntegrationRecord[2]."Integration ID");

        // [THEN] There is no integration records
        Assert.TableIsEmpty(DATABASE::"Integration Record");

        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Merge Duplicates");
        LibraryVariableStorage.Clear;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Merge Duplicates");
        LibraryApplicationArea.EnableEssentialSetup;

        ForceIntegrationActivated;

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Merge Duplicates");
    end;

    local procedure AddGenJnlLine(AccType: Option; AccNo: Code[20]; Counter: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        i: Integer;
    begin
        for i := 1 to Counter do begin
            GenJournalLine."Journal Template Name" := CopyStr(AccNo, 1, 10);
            GenJournalLine."Journal Batch Name" := Format(AccType);
            GenJournalLine."Line No." := i;
            GenJournalLine."Account Type" := AccType;
            GenJournalLine."Account No." := AccNo;
            GenJournalLine.Insert();
        end;
    end;

    local procedure AddItemCrossReference(Item: Record Item; Type: Option; No: Code[20]; Counter: Integer)
    var
        ItemCrossReference: Record "Item Cross Reference";
        i: Integer;
    begin
        for i := 1 to Counter do begin
            ItemCrossReference.Init();
            ItemCrossReference."Item No." := Item."No.";
            ItemCrossReference."Cross-Reference No." := Format(i);
            ItemCrossReference."Cross-Reference Type" := Type;
            ItemCrossReference."Cross-Reference Type No." := No;
            ItemCrossReference.Insert();
        end;
    end;

    local procedure CreateConflict(CustomerBankAccount: array[2] of Record "Customer Bank Account"; var TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary)
    begin
        TempMergeDuplicatesConflict."Table ID" := DATABASE::"Customer Bank Account";
        TempMergeDuplicatesConflict.Current := CustomerBankAccount[1].RecordId;
        TempMergeDuplicatesConflict.Duplicate := CustomerBankAccount[2].RecordId;
        TempMergeDuplicatesConflict."Field ID" := CustomerBankAccount[1].FieldNo("Customer No.");
        TempMergeDuplicatesConflict.Insert();
    end;

    local procedure CreateConflictingCustomerBanks(var CustomerBankAccount: array[2] of Record "Customer Bank Account")
    begin
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount[1], LibrarySales.CreateCustomerNo);
        CustomerBankAccount[2] := CustomerBankAccount[1];
        CustomerBankAccount[2]."Customer No." := LibrarySales.CreateCustomerNo;
        CustomerBankAccount[2].Name := LibraryUtility.GenerateGUID;
        CustomerBankAccount[2].Insert();
    end;

    local procedure CreateContact(var Contact: Record Contact)
    var
        ContDuplicateSearchString: Record "Cont. Duplicate Search String";
    begin
        LibraryMarketing.CreatePersonContact(Contact);
        Contact."Lookup Contact No." := '';
        Contact.Modify();
        ContDuplicateSearchString.DeleteAll();
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."Invoice Disc. Code" := '';
        Customer.Modify();
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", Customer."No.");
        ContactBusinessRelation.DeleteAll();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactLookupModalHandler(var ContactListPage: TestPage "Contact List")
    begin
        ContactListPage.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText);
        ContactListPage.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerLookupModalHandler(var CustomerLookupPage: TestPage "Customer Lookup")
    begin
        CustomerLookupPage.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText);
        CustomerLookupPage.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorLookupModalHandler(var VendorLookupPage: TestPage "Vendor Lookup")
    begin
        VendorLookupPage.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText);
        VendorLookupPage.OK.Invoke;
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure IsMergePageOpen(var MergeDuplicatePage: TestPage "Merge Duplicate")
    begin
        MergeDuplicatePage.First;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text)
    begin
        LibraryVariableStorage.Enqueue(Msg);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerSimple(Msg: Text)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConflictListModalHandler(var MergeDuplicateConflicts: TestPage "Merge Duplicate Conflicts")
    begin
        Assert.IsTrue(MergeDuplicateConflicts.First, 'there must be first line in conflicts');
        LibraryVariableStorage.Enqueue(MergeDuplicateConflicts."Table ID".AsInteger);
        LibraryVariableStorage.Enqueue(MergeDuplicateConflicts.Current.Value);
        LibraryVariableStorage.Enqueue(MergeDuplicateConflicts.Duplicate.Value);
        Assert.IsFalse(MergeDuplicateConflicts.Next, 'there must be no second line in conflicts');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConflictListViewConflictModalHandler(var MergeDuplicateConflicts: TestPage "Merge Duplicate Conflicts")
    begin
        Assert.IsTrue(MergeDuplicateConflicts.First, 'there must be first line in conflicts');
        MergeDuplicateConflicts.ViewConflictRecords.Invoke;
    end;

    local procedure OpenMergePageForConflictingRecords(var MergeDuplicatePage: TestPage "Merge Duplicate"; MergeDuplicatesConflict: Record "Merge Duplicates Conflict")
    var
        MergeDuplicate: Page "Merge Duplicate";
    begin
        MergeDuplicatePage.Trap;
        MergeDuplicate.SetConflict(MergeDuplicatesConflict);
        MergeDuplicate.Run;
    end;

    local procedure SetOverride(var MergeDuplicatePage: TestPage "Merge Duplicate"; FieldNo: Integer; Value: Boolean)
    begin
        MergeDuplicatePage.Fields.FindFirstField(ID, FieldNo);
        MergeDuplicatePage.Fields.Override.SetValue(Value);
    end;

    local procedure InsertODataEdmTypeEntry()
    var
        ODataEdmType: Record "OData Edm Type";
    begin
        ODataEdmType.Init();
        ODataEdmType.Key := LibraryUtility.GenerateGUID;
        ODataEdmType.Insert();
    end;

    local procedure ForceIntegrationActivated()
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        IntegrationManagement: Codeunit "Integration Management";
    begin
        InsertODataEdmTypeEntry;
        GraphMgtGeneralTools.APISetupIfEnabled;
        Assert.IsTrue(IntegrationManagement.IsIntegrationActivated, 'Integration must be activated.');
    end;

    local procedure DisableIntegration()
    var
        ODataEdmType: Record "OData Edm Type";
        IntegrationRecord: Record "Integration Record";
        IntegrationManagement: Codeunit "Integration Management";
        APIMockEvents: Codeunit "API Mock Events";
    begin
        ODataEdmType.DeleteAll();
        IntegrationRecord.DeleteAll();
        IntegrationManagement.ResetIntegrationActivated;
        APIMockEvents.SetIsAPIEnabled(false);
        BindSubscription(APIMockEvents);
        Assert.IsFalse(IntegrationManagement.IsIntegrationActivated, 'Integration must be disabled with mock.');
        UnbindSubscription(APIMockEvents);
        Assert.IsFalse(IntegrationManagement.IsIntegrationActivated, 'Integration must be disabled without mock.');
        Assert.RecordIsEmpty(IntegrationRecord);
        Assert.RecordIsEmpty(ODataEdmType);
    end;

    local procedure VerifyFieldDuplicateValueEditable(var MergeDuplicatePage: TestPage "Merge Duplicate"; FieldNo: Integer; IsEditable: Boolean)
    begin
        MergeDuplicatePage.Fields.FindFirstField(ID, FieldNo);
        Assert.AreEqual(
          IsEditable, MergeDuplicatePage.Fields."Duplicate Value".Editable,
          'Duplicate Value.EDITABLE for field ' + Format(FieldNo));
    end;

    local procedure VerifyFieldOverrideEditable(var MergeDuplicatePage: TestPage "Merge Duplicate"; FieldNo: Integer; IsEditable: Boolean)
    begin
        MergeDuplicatePage.Fields.FindFirstField(ID, FieldNo);
        Assert.AreEqual(
          IsEditable, MergeDuplicatePage.Fields.Override.Editable,
          'Override.EDITABLE for field ' + Format(FieldNo));
    end;

    local procedure AssertIntegrationRecordNotFound(IntegrationID: Guid)
    var
        IntegrationRecord: Record "Integration Record";
    begin
        Assert.IsFalse(
          IntegrationRecord.FindByIntegrationId(IntegrationID),
          StrSubstNo('Integration record %1 must not be found', IntegrationID));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean;
        LibraryVariableStorage.Enqueue(Question);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNoHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MergeDuplicatesConflictingRecordsModalHandler(var MergeDuplicate: TestPage "Merge Duplicate")
    var
        ConflictAction: Integer;
    begin
        ConflictAction := LibraryVariableStorage.DequeueInteger;
        case ConflictAction of
            ConflictResolution::None:
                MergeDuplicate.Cancel.Invoke;
            ConflictResolution::Rename:
                begin
                    MergeDuplicate.Fields.FindFirstField(ID, LibraryVariableStorage.DequeueInteger);
                    Assert.IsTrue(MergeDuplicate.Fields."Duplicate Value".Editable, '"Duplicate Value".EDITABLE');
                    MergeDuplicate.Fields."Duplicate Value".SetValue(LibraryVariableStorage.DequeueText);
                    MergeDuplicate."Rename Duplicate".Invoke;
                end;
            ConflictResolution::Remove:
                MergeDuplicate."Remove Duplicate".Invoke;
        end;
        LibraryVariableStorage.Enqueue(IsMergePageOpen(MergeDuplicate));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RemoveConflictModalHandler(var MergeDuplicatePage: TestPage "Merge Duplicate")
    begin
        LibraryVariableStorage.Enqueue(MergeDuplicatePage.CurrentRecID.Value);
        LibraryVariableStorage.Enqueue(MergeDuplicatePage.DuplicateRecID.Value);
        MergeDuplicatePage."Remove Duplicate".Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RemoveConflictModalSimpleHandler(var MergeDuplicatePage: TestPage "Merge Duplicate")
    begin
        MergeDuplicatePage."Remove Duplicate".Invoke;
    end;

    [EventSubscriber(ObjectType::Table, 64, 'OnAfterFindRelatedFields', '', false, false)]
    local procedure OnAfterFindRelatedFields(var TempTableRelationsMetadata: Record "Table Relations Metadata" temporary)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // adds the record to the related fields list
        TempTableRelationsMetadata.Init();
        TempTableRelationsMetadata."Table ID" := DATABASE::"Gen. Journal Line";
        TempTableRelationsMetadata."Field No." := GenJournalLine.FieldNo("Creditor No.");
        TempTableRelationsMetadata.Insert();
    end;

    [EventSubscriber(ObjectType::Table, 18, 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterCustomerRename(var Rec: Record Customer; var xRec: Record Customer; RunTrigger: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        if RunTrigger then begin
            GenJournalLine.SetRange("Creditor No.", xRec."No.");
            if not GenJournalLine.IsEmpty then
                GenJournalLine.ModifyAll("Creditor No.", Rec."No.");
        end;
    end;
}

