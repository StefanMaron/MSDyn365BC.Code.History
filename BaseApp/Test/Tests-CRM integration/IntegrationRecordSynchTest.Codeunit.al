codeunit 139166 "Integration Record Synch. Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [Integration Record Synch.]
    end;

    var
        Assert: Codeunit Assert;
        LibraryMarketing: Codeunit "Library - Marketing";

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTransferFieldsNewRecord()
    var
        TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        SourceTableRecRef: RecordRef;
        DestinationTableRecRef: RecordRef;
    begin
        // [SCENARIO] Synchronize Integration Table with Nav Table if destination record does not exist
        Initialize;

        // [GIVEN] Source row is filled, Destination row is empty
        PrepareSourceRowAndDestinationRefs(SourceTableRecRef, DestinationTableRecRef);

        // [GIVEN] Integration Field Mappping is defined
        CreateComparisonTypeRowTempIntegrationFieldMapping(TempIntegrationFieldMapping, true);

        // [WHEN] Run IntegrationRecordSynch for the source row and the destination row
        IntegrationRecordSynch.SetFieldMapping(TempIntegrationFieldMapping);
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, false);
        Commit;
        Assert.IsTrue(IntegrationRecordSynch.Run, 'Expected the transfer to return true');
        // [THEN] Field values are copied and WasModified flags is true
        Assert.IsTrue(IntegrationRecordSynch.GetWasModified, 'Expected the modified flag to be set');

        ValidateComparisonTypeRow(SourceTableRecRef, DestinationTableRecRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTransferFieldsExistingRecord()
    var
        TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        SourceTableRecRef: RecordRef;
        DestinationTableRecRef: RecordRef;
        SourceFieldRef: FieldRef;
    begin
        // [SCENARIO] Synchronize Integration Table with Nav Table if destination record already exists
        Initialize;

        // [GIVEN] Source row is synced with Destination row once
        PrepareSourceRowAndDestinationRefs(SourceTableRecRef, DestinationTableRecRef);
        CreateComparisonTypeRowTempIntegrationFieldMapping(TempIntegrationFieldMapping, true);
        IntegrationRecordSynch.SetFieldMapping(TempIntegrationFieldMapping);
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, false);
        Commit;
        Assert.IsTrue(IntegrationRecordSynch.Run, 'Expected the first transfer to succeed');
        Assert.IsTrue(IntegrationRecordSynch.GetWasModified, 'Expected first transfer to set the modified flag to true');

        // Re-create the fieldmapping without the primary key default. If we do not the all transfers will reset the primary key to default value.
        TempIntegrationFieldMapping.DeleteAll;
        CreateComparisonTypeRowTempIntegrationFieldMapping(TempIntegrationFieldMapping, false);

        // [GIVEN] Destination row has already been synchronized
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, true);
        Commit;
        // [WHEN] Run IntegrationRecordSynch, where "Copy Only Modified" is 'true'
        Assert.IsTrue(IntegrationRecordSynch.Run, 'Expected the second transfer to succeed');
        // [THEN] WasModified flag will be 'false'
        Assert.IsFalse(IntegrationRecordSynch.GetWasModified, 'Expected second transfer to set the modified flag to false');

        // [GIVEN] Destination row has already been synchronized but one value has changed.
        SourceFieldRef := SourceTableRecRef.Field(12);
        SourceFieldRef.Value := 'This is another text';
        SourceTableRecRef.Modify;
        Commit;
        // [WHEN] Run IntegrationRecordSynch, where "Copy Only Modified" is 'true'
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, true);
        Assert.IsTrue(IntegrationRecordSynch.Run, 'Expected the third transfer to succeed');
        // [THEN] Modified field should be transfered and WasModified flags set to 'true'
        Assert.IsTrue(IntegrationRecordSynch.GetWasModified, 'Expected third transfer to set the modified flag to true');

        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, false);
        Commit;
        // [WHEN] Run IntegrationRecordSynch, where "Copy Only Modified" is 'false'
        Assert.IsTrue(IntegrationRecordSynch.Run, 'Expected the fourth transfer to succeed');
        // [THEN] All fields should be copied and WasModified flags should be 'true'
        Assert.IsTrue(IntegrationRecordSynch.GetWasModified, 'Expected fourth transfer to set the modified flag to true');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTransferFieldsFailOnMissingParameters()
    var
        TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        SourceTableRecRef: RecordRef;
        DestinationTableRecRef: RecordRef;
    begin
        // [SCENARIO] Synchronize Integration Table with Nav Table if parameters are not defined correctly
        Initialize;
        Commit;
        // [GIVEN] Process parameters has not been set
        // [WHEN] Copying source row fields to Destination row
        // [THEN] Processing should not succeed
        Assert.IsFalse(IntegrationRecordSynch.Run, 'Expected run to fail');

        // [GIVEN] Processing parameters are invalid
        // [WHEN] Copying source row fields to Destination row
        // [THEN] Processing should not succeed
        IntegrationRecordSynch.SetFieldMapping(TempIntegrationFieldMapping);
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, false);
        Assert.IsFalse(IntegrationRecordSynch.Run, 'Expected run to fail when set with empty parameters');

        CreateComparisonTypeRowTempIntegrationFieldMapping(TempIntegrationFieldMapping, true);
        IntegrationRecordSynch.SetFieldMapping(TempIntegrationFieldMapping);
        // [GIVEN] Source has no data
        // [WHEN] Copying source row fields to Destination row
        // [THEN] Processing should not succeed
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, false);
        Assert.IsFalse(IntegrationRecordSynch.Run, 'Expected run to fail when set with empty source and Destination');

        // [GIVEN] Destination has not been initialized
        // [WHEN] Copying source row fields to Destination row
        // [THEN] Processing should not succeed
        SourceTableRecRef.Open(DATABASE::Customer);
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, false);
        Assert.IsFalse(IntegrationRecordSynch.Run, 'Expected run to fail when set with empty Destination');

        // [GIVEN] Destination does not have the expected fields
        // [WHEN] Copying source row fields to Destination row
        // [THEN] Processing should not succeed
        DestinationTableRecRef.Open(DATABASE::Contact);
        IntegrationRecordSynch.SetParameters(SourceTableRecRef, DestinationTableRecRef, false);
        Assert.IsFalse(IntegrationRecordSynch.Run, 'Expected run to fail when Destination does not have the required fields');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanTransferCalculatedFields()
    var
        Contact: Record Contact;
        ValidationContact: Record Contact;
        JobResponsibility: Record "Job Responsibility";
        ContactJobResponsibility: Record "Contact Job Responsibility";
        ComparisonType: Record "Comparison Type";
        TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
        SourceFieldRef: FieldRef;
        ExpectedValue: Integer;
    begin
        // [FEATURE] [FlowField]
        // [SCENARIO] IntegrationRecordSynch should sync the value of calculated flowfield
        Initialize;
        // [GIVEN] Destination row is empty
        ComparisonType.Init;
        DestinationRecordRef.GetTable(ComparisonType);
        // [GIVEN] Source record has a calculated flowfield
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryMarketing.CreateJobResponsibility(JobResponsibility);
        with ContactJobResponsibility do begin
            Init;
            "Contact No." := Contact."No.";
            "Contact Name" := Contact.Name;
            "Contact Company Name" := Contact."Company Name";
            "Job Responsibility Code" := JobResponsibility.Code;
            "Job Responsibility Description" := JobResponsibility.Description;
            Insert;
        end;
        // [GIVEN] The source flowfield is mapped to a normal destination field
        with TempIntegrationFieldMapping do begin
            Init;
            "No." := 1;
            "Integration Table Mapping Name" := 'Temp Mapping';
            "Source Field No." := Contact.FieldNo("No. of Job Responsibilities");
            "Destination Field No." := ComparisonType.FieldNo("Integer Field");
            "Constant Value" := '';
            Insert;
        end;

        ValidationContact.Get(Contact."No.");
        ValidationContact.CalcFields("No. of Job Responsibilities");
        ExpectedValue := ValidationContact."No. of Job Responsibilities";
        Assert.AreEqual(
          1, ValidationContact."No. of Job Responsibilities", 'Expected the calulated field to have a value after calculation.');
        Assert.AreEqual(
          0, Contact."No. of Job Responsibilities", 'Did not expect the calculated field to have a value before calculation.');

        // Validate field class. This could change if we decide to change/expose the field class option
        // causing the production code to fail
        SourceRecordRef.GetTable(Contact);
        SourceFieldRef := SourceRecordRef.Field(Contact.FieldNo("No. of Job Responsibilities"));
        Assert.AreEqual(
          'FlowField', Format(SourceFieldRef.Class, 0, 9), 'Expected the formatting field class Flowfield to match expected value.');
        SourceFieldRef := SourceRecordRef.Field(Contact.FieldNo("No."));
        Assert.AreEqual('Normal', Format(SourceFieldRef.Class, 0, 9), 'Expected the formatting field class Normal to match expected value.');
        SourceFieldRef := SourceRecordRef.Field(Contact.FieldNo("Date Filter"));
        Assert.AreEqual(
          'FlowFilter', Format(SourceFieldRef.Class, 0, 9), 'Expected the formatting field class FlowFilter to match expected value.');

        // [WHEN] Run IntegrationRecordSynch, where "Copy Only Modified" is 'false'
        IntegrationRecordSynch.SetFieldMapping(TempIntegrationFieldMapping);
        IntegrationRecordSynch.SetParameters(SourceRecordRef, DestinationRecordRef, false);
        Commit;
        Assert.IsTrue(IntegrationRecordSynch.Run, 'Expected the transfer to succeed');

        // [THEN] Calculated flowfield value will be transfered.
        DestinationRecordRef.SetTable(ComparisonType);
        Assert.AreEqual(ExpectedValue, ComparisonType."Integer Field", 'Expected the No. of Job Responsibilities to be transfered');
    end;

    local procedure Initialize()
    var
        ComparisonType: Record "Comparison Type";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        ComparisonType.DeleteAll;
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::"On Hold with Inactivity Timeout");
        JobQueueEntry.ModifyAll(Status, JobQueueEntry.Status::"On Hold", false);
    end;

    local procedure CreateComparisonTypeRow(var ComparisonType: Record "Comparison Type")
    begin
        with ComparisonType do begin
            Init;
            Key := 1;
            "Big Integer Field" := 10;
            "Boolean Field" := true;
            "Code Field" := 'CODE';
            "Date Field" := Today;
            Evaluate("Date Formula Field", '<1Y>');
            "Date / Time Field" := CurrentDateTime;
            "Decimal Field" := 10.1;
            "Duration Field" := CurrentDateTime - CreateDateTime(20000101D, 080000T);
            "Integer Field" := 10;
            "Option Field" := 3;
            "Text Field" := 'This is text';
            "Time Field" := Time;
            "GUID Field" := CreateGuid;
            Insert;
            "Record ID Field" := RecordId;
            Modify;
        end;
    end;

    local procedure CreateComparisonTypeRowTempIntegrationFieldMapping(var TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary; IncludePrimaryKeyDefault: Boolean)
    var
        "Field": Record "Field";
    begin
        Field.SetRange(TableNo, DATABASE::"Comparison Type");
        Field.SetFilter("No.", '<>1'); // Ignore the key
        Field.FindSet;

        if IncludePrimaryKeyDefault then
            with TempIntegrationFieldMapping do begin
                Init;
                "No." := 1;
                "Integration Table Mapping Name" := Field.TableName;
                "Destination Field No." := "No.";
                "Constant Value" := '';
                Insert;
            end;

        repeat
            with TempIntegrationFieldMapping do begin
                Init;
                "No." := Field."No.";
                "Integration Table Mapping Name" := Field.TableName;
                "Source Field No." := "No.";
                "Destination Field No." := "No.";
                "Constant Value" := '';
                Insert;
            end;
        until Field.Next = 0;
    end;

    local procedure PrepareSourceRowAndDestinationRefs(var SourceTableRecRef: RecordRef; var DestinationTableRecRef: RecordRef)
    var
        SourceComparisonType: Record "Comparison Type";
        DestinationComparisonType: Record "Comparison Type";
    begin
        CreateComparisonTypeRow(SourceComparisonType);
        SourceTableRecRef.GetTable(SourceComparisonType);

        DestinationComparisonType.Reset;
        DestinationComparisonType.Init;
        DestinationTableRecRef.GetTable(DestinationComparisonType);
    end;

    local procedure ValidateComparisonTypeRow(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        "Field": Record "Field";
        SourceFieldRef: FieldRef;
        DestinationFieldRef: FieldRef;
    begin
        // Validate primary key is different
        Assert.IsFalse(SourceRecordRef.Field(1).Value = DestinationRecordRef.Field(1).Value, 'Expected the primary keys to differ');

        // Validate fields are equal;
        Field.SetRange(TableNo, DATABASE::"Comparison Type");
        Field.SetFilter("No.", '<>1'); // Ignore the key
        Field.FindSet;

        repeat
            SourceFieldRef := SourceRecordRef.Field(Field."No.");
            DestinationFieldRef := DestinationRecordRef.Field(Field."No.");
            Assert.IsTrue(SourceFieldRef.Value = DestinationFieldRef.Value, 'Expected the two fields to match');
        until Field.Next = 0;
    end;
}

