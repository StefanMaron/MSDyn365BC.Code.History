codeunit 139023 "OSynch. Filter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Outlook Synch.] [Filter]
    end;

    var
        ToDo: Record "To-do";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateFilterExpressionForFieldTest()
    var
        OutlookSynchFilter: Record "Outlook Synch. Filter";
    begin
        with OutlookSynchFilter do begin
            "Table No." := 5080; // To-Do table
            "Field No." := 3; // Salesperson code
            "Master Table No." := 13; // Salesperson
            "Master Table Field No." := 1; // Salesperson code
            "Filter Type" := "Filter Type"::Condition;
            Type := Type::FIELD;

            UpdateFilterExpression;
            Assert.AreEqual('', FilterExpression, 'Unexpected filter result');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateFilterExpressionForFilterTest()
    var
        OutlookSynchFilter: Record "Outlook Synch. Filter";
    begin
        with OutlookSynchFilter do begin
            "Table No." := 5080; // To-Do table
            "Field No." := 3; // Salesperson code
            "Master Table No." := 13; // Salesperson
            "Master Table Field No." := 1; // Salesperson code
            "Filter Type" := "Filter Type"::Condition;
            Type := Type::FILTER;
            Value := '>''A*''';
            UpdateFilterExpression;
            Assert.AreEqual('Field3=1(>''A*'')', FilterExpression, 'Unexpected filter result');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateFilterExpressionForConstStringTest()
    var
        OutlookSynchFilter: Record "Outlook Synch. Filter";
    begin
        with OutlookSynchFilter do begin
            "Table No." := 5080; // To-Do table
            "Field No." := 3; // Salesperson code
            "Filter Type" := "Filter Type"::Condition;
            Type := Type::CONST;
            Value := 'AH';
            UpdateFilterExpression;
            Assert.AreEqual('Field3=1(AH)', FilterExpression, 'Unexpected filter result');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateFilterExpressionForConstBooleanTrueTest()
    var
        OutlookSynchFilter: Record "Outlook Synch. Filter";
    begin
        with OutlookSynchFilter do begin
            "Table No." := 5080; // To-Do table
            "Field No." := 17; // Canceled
            "Filter Type" := "Filter Type"::Condition;
            Type := Type::CONST;
            Value := Format(true);
            UpdateFilterExpression;
            Assert.AreEqual('Field17=1(1)', FilterExpression, 'Unexpected filter result');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateFilterExpressionForConstBooleanFalseTest()
    var
        OutlookSynchFilter: Record "Outlook Synch. Filter";
    begin
        with OutlookSynchFilter do begin
            "Table No." := 5080; // To-Do table
            "Field No." := 17; // Canceled
            "Filter Type" := "Filter Type"::Condition;
            Type := Type::CONST;
            Value := Format(false);
            UpdateFilterExpression;
            Assert.AreEqual('Field17=1(0)', FilterExpression, 'Unexpected filter result');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateFilterExpressionForConstOptionTest()
    var
        OutlookSynchFilter: Record "Outlook Synch. Filter";
    begin
        with OutlookSynchFilter do begin
            "Table No." := 5080; // To-Do table
            "Field No." := 10; // Status
            "Filter Type" := "Filter Type"::Condition;
            Type := Type::CONST;
            Value := Format(ToDo.Status::Waiting);
            UpdateFilterExpression;
            Assert.AreEqual('Field10=1(3)', FilterExpression, 'Unexpected filter result');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateFilterExpressionForConstDecimalTest()
    var
        OutlookSynchFilter: Record "Outlook Synch. Filter";
    begin
        // TODO: This test should be changed to support fixed decimal point when GETVIEW returns invariant data
        with OutlookSynchFilter do begin
            "Table No." := 5080; // To-Do table
            "Field No." := 41; // Unit Cost (LCY)
            "Filter Type" := "Filter Type"::Condition;
            Type := Type::CONST;
            Value := Format(41.5);
            UpdateFilterExpression;
            Assert.AreEqual('Field41=1(41.5)', FilterExpression, 'Unexpected filter result');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateFilterExpressionForConstDateTest()
    var
        OutlookSynchFilter: Record "Outlook Synch. Filter";
    begin
        // TODO: This test should be changed to support invariant date format when GETVIEW returns invariant data
        with OutlookSynchFilter do begin
            "Table No." := 5080; // To-Do table
            "Field No." := 9; // Date
            "Filter Type" := "Filter Type"::Condition;
            Type := Type::CONST;
            Value := Format(20170315D);
            UpdateFilterExpression;
            Assert.AreEqual('Field9=1(2017-03-15)', FilterExpression, 'Unexpected filter result');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertUpdatesFilterExpressionTest()
    var
        OutlookSynchFilter: Record "Outlook Synch. Filter";
    begin
        with OutlookSynchFilter do begin
            "Table No." := 5080; // To-Do table
            "Field No." := 3; // Salesperson code
            "Filter Type" := "Filter Type"::Condition;
            Type := Type::CONST;
            Value := 'AH';
            "Record GUID" := CreateGuid;

            Insert(true);
            Assert.AreNotEqual('', FilterExpression, 'Unexpected filter result');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyUpdatesFilterExpressionTest()
    var
        OutlookSynchFilter: Record "Outlook Synch. Filter";
        InsertExpression: Text;
    begin
        with OutlookSynchFilter do begin
            "Table No." := 5080; // To-Do table
            "Field No." := 3; // Salesperson code
            "Filter Type" := "Filter Type"::Condition;
            Type := Type::CONST;
            Value := 'AH';

            "Record GUID" := CreateGuid;
            Insert(true);
            Assert.AreNotEqual('', FilterExpression, 'Unexpected filter result');
            InsertExpression := FilterExpression;

            Value := 'MH';
            Modify(true);

            Assert.AreNotEqual(InsertExpression, FilterExpression, 'Expected filter to change during modify of value');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFieldTextFailureTest()
    var
        OutlookSynchFilter: Record "Outlook Synch. Filter";
    begin
        Assert.AreEqual('', OutlookSynchFilter.GetFieldCaption, 'Expected empty field name for cleared row');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetTableNoTest()
    var
        OutlookSynchFilter: Record "Outlook Synch. Filter";
    begin
        OutlookSynchFilter.SetTablesNo(5080, 13);
        Assert.AreEqual(5080, OutlookSynchFilter."Table No.", 'Expeted master table no to be set');
        Assert.AreEqual(13, OutlookSynchFilter."Master Table No.", 'Expeted master table field no to be set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecomposeFilterExpressionTest()
    var
        OutlookSynchFilter: Record "Outlook Synch. Filter";
        OutlookSynchSetupMgt: Codeunit "Outlook Synch. Setup Mgt.";
    begin
        Assert.AreEqual(
          OutlookSynchSetupMgt.ComposeFilterExpression(OutlookSynchFilter."Record GUID", OutlookSynchFilter.Type),
          OutlookSynchFilter.RecomposeFilterExpression, 'Expected this to be a direct mapping');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateFieldValuePairTest()
    var
        OutlookSynchFilter: Record "Outlook Synch. Filter";
    begin
        with OutlookSynchFilter do begin
            "Table No." := 5080; // To-Do table
            "Field No." := 0;
            asserterror ValidateFieldValuePair;

            "Field No." := 3; // Salesperson code
            "Filter Type" := "Filter Type"::Condition;
            Type := Type::CONST;
            Value := 'AH';
            ValidateFieldValuePair;

            Value := 'AHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAH';
            asserterror ValidateFieldValuePair;

            "Field No." := 8; // Type
            "Filter Type" := "Filter Type"::Condition;
            Type := Type::CONST;
            Value := Format(ToDo.Type::Meeting);
            ValidateFieldValuePair;

            Value := 'WRONG';
            asserterror ValidateFieldValuePair;

            "Field No." := 13; // Closed
            "Filter Type" := "Filter Type"::Condition;
            Type := Type::CONST;
            Value := Format(false);
            ValidateFieldValuePair;

            Value := 'WRONG';
            asserterror ValidateFieldValuePair;

            "Field No." := 14; // Date Closed
            "Filter Type" := "Filter Type"::Condition;
            Type := Type::CONST;
            Value := 'This is not a date';
            asserterror ValidateFieldValuePair;

            Value := '';
            "Field No." := 14; // Date Closed
            "Filter Type" := "Filter Type"::Condition;
            Type := Type::FIELD;
            "Master Table No." := 13;
            "Master Table Field No." := 1;
            asserterror ValidateFieldValuePair;

            "Table No." := 5080; // To-Do table
            "Field No." := 3; // Salesperson code
            "Master Table No." := 13; // Salesperson
            "Master Table Field No." := 1; // Salesperson code
            Value := 'Code';
            ValidateFieldValuePair;

            "Field No." := 8; // Type
            "Filter Type" := "Filter Type"::Condition;
            Type := Type::FILTER;
            Value := Format(ToDo.Type::Meeting);
            ValidateFieldValuePair;

            Value := 'WRONG';
            asserterror ValidateFieldValuePair;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFilterExpressionOptionValueTest()
    var
        OutlookSynchFilter: Record "Outlook Synch. Filter";
        Attendee: Record Attendee;
        OutlookSynchTypeConv: Codeunit "Outlook Synch. Type Conv";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        ActualIntegerValue: Integer;
        ExpectedIntegerValue: Integer;
    begin
        with OutlookSynchFilter do begin
            "Table No." := 5199; // Attendee
            "Field No." := 4; // Type
            "Filter Type" := "Filter Type"::Condition;
            Type := Type::CONST;
            Value := Format(Attendee."Attendee Type"::Salesperson);
            Insert(true);

            Assert.IsFalse(Value = GetFilterExpressionValue, 'Expected to get option index not value from FilterExpressionValue');

            Evaluate(ExpectedIntegerValue, Format(Attendee."Attendee Type"::Salesperson, 0, 2));
            RecordRef.Open(5199);
            FieldRef := RecordRef.Field(4);
            ActualIntegerValue := OutlookSynchTypeConv.TextToOptionValue(GetFilterExpressionValue, FieldRef.OptionCaption);

            Assert.AreEqual(ExpectedIntegerValue, ActualIntegerValue, 'Expected option to evaluate to value');

            Delete;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFilterExpressionEmptyValueTest()
    var
        OutlookSynchFilter: Record "Outlook Synch. Filter";
    begin
        with OutlookSynchFilter do begin
            "Table No." := 5199; // Attendee
            "Field No." := 5; // Attendee No.
            "Filter Type" := "Filter Type"::Condition;
            Type := Type::CONST;
            Value := '';
            Insert(true);

            Assert.AreEqual(2, StrLen(GetFilterExpressionValue), 'Expected FilterExpressionValue convert empty string to two spaces');

            Delete;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFilterExpressionTextValueTest()
    var
        OutlookSynchFilter: Record "Outlook Synch. Filter";
    begin
        with OutlookSynchFilter do begin
            "Table No." := 5199; // Attendee
            "Field No." := 5; // Attendee No.
            "Filter Type" := "Filter Type"::Condition;
            Type := Type::CONST;
            Value := 'SOMEID 2222';
            Insert(true);

            Assert.AreEqual(
              StrLen(Value), StrLen(GetFilterExpressionValue), 'Expected FilterExpressionValue to return same string length as value');
            Assert.IsTrue(Value = GetFilterExpressionValue, 'Expected FilterExpressionValue to return text as value');

            Delete;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFilterExpressionFailureTest()
    var
        OutlookSynchFilter: Record "Outlook Synch. Filter";
    begin
        with OutlookSynchFilter do begin
            "Table No." := 5199; // Attendee
            "Field No." := 4; // Attendee Type
            "Filter Type" := "Filter Type"::Condition;
            Type := Type::CONST;
            Value := 'Invalid Data';
            FilterExpression := '';

            asserterror GetFilterExpressionValue
        end;
    end;
}

