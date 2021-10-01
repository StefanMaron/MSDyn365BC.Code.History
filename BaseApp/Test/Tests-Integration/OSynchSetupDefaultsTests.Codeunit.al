#if not CLEAN19
codeunit 139024 "OSynch Setup Defaults Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Outlook Synch.]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        ResetEntityChoiceValue: Integer;
        OSynchUserSetupDeleteErr: Label 'You cannot delete this entity because it is set up for synchronization. Please verify %1.';

    [Test]
    [HandlerFunctions('ResetEntitySelectEntityStrMenuHandler')]
    [Scope('OnPrem')]
    procedure ResetEntityTest()
    var
        OutlookSynchEntity: Record "Outlook Synch. Entity";
        OutlookSynchSetupDefaults: Codeunit "Outlook Synch. Setup Defaults";
        MyEntityCode: Code[10];
    begin
        Initialize;

        MyEntityCode := 'RESETTEST';
        if OutlookSynchEntity.Get(MyEntityCode) then
            OutlookSynchEntity.Delete(true);
        OutlookSynchEntity.Init();
        OutlookSynchEntity.Code := MyEntityCode;
        OutlookSynchEntity.Insert();

        ResetEntityChoiceValue := 4;
        OutlookSynchSetupDefaults.ResetEntity(MyEntityCode);
        Assert.IsTrue(OutlookSynchEntity.Get(MyEntityCode), 'Expected entity to be created');
        OutlookSynchEntity.Delete(true);
    end;

    [Test]
    [HandlerFunctions('AlwaysDeleteDependenciesConfirmHandler')]
    [Scope('OnPrem')]
    procedure InsertOSynchDefaultsTest()
    var
        OutlookSynchEntity: Record "Outlook Synch. Entity";
        OutlookSynchFilter: Record "Outlook Synch. Filter";
        OutlookSynchField: Record "Outlook Synch. Field";
        OutlookSynchSetupDefaults: Codeunit "Outlook Synch. Setup Defaults";
    begin
        Initialize;

        OutlookSynchEntity.DeleteAll(true);
        OutlookSynchFilter.DeleteAll(true);
        OutlookSynchField.DeleteAll(true);

        OutlookSynchSetupDefaults.InsertOSynchDefaults;
        Assert.AreNotEqual(0, OutlookSynchEntity.Count, 'Expected more than one entity to be created');

        ValidateOSynchFilters;
        ValidateOSynchFields;

        OutlookSynchEntity.DeleteAll(true);
        OutlookSynchFilter.DeleteAll(true);
        OutlookSynchField.DeleteAll(true);
    end;

    [Test]
    [HandlerFunctions('AlwaysDeleteDependenciesConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteOSynchEntityWithRelatedEntries_UT()
    var
        OutlookSynchEntity: Record "Outlook Synch. Entity";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 180152] Delete "Outlook Synch. Entity"
        Initialize;
        // [GIVEN] Outlook Synch. Entity with related entries
        MockOSynchEntityWithRelatedEntries(OutlookSynchEntity);
        // [WHEN] Delete Outlook Synch. Entity
        OutlookSynchEntity.Delete(true);
        // [THEN] Outlook Synch. Entity with related entries are deleted
        VerifyOSynchEntityWithRelatedEntriesDeleted(OutlookSynchEntity.Code, OutlookSynchEntity."Record GUID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteOSynchEntityWithUserSetup_UT()
    var
        OutlookSynchEntity: Record "Outlook Synch. Entity";
        OutlookSynchUserSetup: Record "Outlook Synch. User Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 180152] Delete "Outlook Synch. Entity" with related "Outlook Synch. User Setup"
        Initialize;
        // [GIVEN] Outlook Synch. Entity
        MockOSynchEntity(OutlookSynchEntity);
        // [GIVEN] Outlook Synch. User Setup
        MockOSynchUserSetup(OutlookSynchUserSetup, OutlookSynchEntity.Code);
        // [WHEN] Delete Outlook Synch. Entity
        asserterror OutlookSynchEntity.Delete(true);
        // [THEN] Error message thrown
        Assert.ExpectedError(StrSubstNo(OSynchUserSetupDeleteErr, OutlookSynchUserSetup.TableCaption));
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        Commit();

        IsInitialized := true;
    end;

    local procedure MockOSynchEntity(var OutlookSynchEntity: Record "Outlook Synch. Entity")
    begin
        OutlookSynchEntity.Init();
        OutlookSynchEntity.Code :=
          LibraryUtility.GenerateRandomCode(OutlookSynchEntity.FieldNo(Code), DATABASE::"Outlook Synch. Entity");
        OutlookSynchEntity.Insert(true);
    end;

    local procedure MockOSynchEntityWithRelatedEntries(var OutlookSynchEntity: Record "Outlook Synch. Entity")
    var
        OutlookSynchEntityElement: Record "Outlook Synch. Entity Element";
        OutlookSynchField: Record "Outlook Synch. Field";
        OutlookSynchFilter: Record "Outlook Synch. Filter";
        OutlookSynchDependency: Record "Outlook Synch. Dependency";
    begin
        MockOSynchEntity(OutlookSynchEntity);
        MockOSynchEntityElement(OutlookSynchEntityElement, OutlookSynchEntity.Code);
        MockOSynchField(OutlookSynchField, OutlookSynchEntity.Code);
        MockOSynchFilter(OutlookSynchFilter, OutlookSynchEntity."Record GUID");
        MockOSynchDependency(OutlookSynchDependency, OutlookSynchEntity.Code);
    end;

    local procedure MockOSynchEntityElement(var OutlookSynchEntityElement: Record "Outlook Synch. Entity Element"; OutlookSynchEntityCode: Code[10])
    begin
        OutlookSynchEntityElement.Init();
        OutlookSynchEntityElement."Synch. Entity Code" := OutlookSynchEntityCode;
        OutlookSynchEntityElement."Element No." := 10000;
        OutlookSynchEntityElement.Insert();
    end;

    local procedure MockOSynchField(var OutlookSynchField: Record "Outlook Synch. Field"; OutlookSynchEntityCode: Code[10])
    begin
        OutlookSynchField.Init();
        OutlookSynchField."Synch. Entity Code" := OutlookSynchEntityCode;
        OutlookSynchField."Element No." := 10000;
        OutlookSynchField."Line No." := 10000;
        OutlookSynchField.Insert();
    end;

    local procedure MockOSynchFilter(var OutlookSynchFilter: Record "Outlook Synch. Filter"; OutlookSynchEntityRecGUID: Guid)
    begin
        OutlookSynchFilter.Init();
        OutlookSynchFilter."Record GUID" := OutlookSynchEntityRecGUID;
        OutlookSynchFilter."Filter Type" := OutlookSynchFilter."Filter Type"::Condition;
        OutlookSynchFilter."Line No." := 10000;
        OutlookSynchFilter.Insert();
    end;

    local procedure MockOSynchDependency(var OutlookSynchDependency: Record "Outlook Synch. Dependency"; OutlookSynchEntityCode: Code[10])
    begin
        OutlookSynchDependency.Init();
        OutlookSynchDependency."Synch. Entity Code" := OutlookSynchEntityCode;
        OutlookSynchDependency."Element No." := 10000;
        OutlookSynchDependency."Depend. Synch. Entity Code" := OutlookSynchEntityCode;
        OutlookSynchDependency.Insert();
    end;

    local procedure MockOSynchUserSetup(var OutlookSynchUserSetup: Record "Outlook Synch. User Setup"; OutlookSynchEntityCode: Code[10])
    begin
        OutlookSynchUserSetup.Init();
        OutlookSynchUserSetup."User ID" := UserId;
        OutlookSynchUserSetup."Synch. Entity Code" := OutlookSynchEntityCode;
        OutlookSynchUserSetup.Insert();
    end;

    local procedure ValidateOSynchFilters()
    var
        Document: DotNet XmlDocument;
        DocumentRowNode: DotNet XmlElement;
        DocumentTableNode: DotNet XmlElement;
        FieldRecordRef: RecordRef;
    begin
        CreateFilterCompareDocument(Document);
        FieldRecordRef.Open(5303);
        FieldRecordRef.FindFirst;
        Assert.AreEqual(
          Document.SelectNodes('/Workbook/Worksheet/Table/Row[position()>1]').Count, FieldRecordRef.Count,
          'One or more rows are missing from the test definition');

        repeat
            Clear(DocumentRowNode);
            FindDocumentRow(FieldRecordRef, 3, Document, 3, DocumentRowNode);

            MatchRecordValue(FieldRecordRef, 4, DocumentRowNode, 4);
            MatchRecordValue(FieldRecordRef, 5, DocumentRowNode, 5);
            MatchRecordValue(FieldRecordRef, 9, DocumentRowNode, 8);
            MatchRecordValue(FieldRecordRef, 10, DocumentRowNode, 9);
            MatchRecordValue(FieldRecordRef, 99, DocumentRowNode, 10);

            DocumentRowNode.ParentNode.RemoveChild(DocumentRowNode);
        until FieldRecordRef.Next = 0;

        DocumentTableNode := Document.SelectSingleNode('/Workbook/Worksheet/Table');
        // Only the header can remain
        Assert.AreEqual(
          1, DocumentTableNode.ChildNodes.Count,
          'One or more items are not present in the database.\' + DocumentTableNode.InnerXml);
    end;

    local procedure ValidateOSynchFields()
    var
        Document: DotNet XmlDocument;
        DocumentRowNode: DotNet XmlElement;
        DocumentTableNode: DotNet XmlElement;
        FieldRecordRef: RecordRef;
    begin
        CreateFieldCompareDocument(Document);
        FieldRecordRef.Open(5304);
        FieldRecordRef.FindFirst;
        Assert.AreEqual(
          Document.SelectNodes('/Workbook/Worksheet/Table/Row[position()>1]').Count, FieldRecordRef.Count,
          'One or more rows are missing from the test definition');

        repeat
            Clear(DocumentRowNode);
            FindDocumentRow(FieldRecordRef, 3, Document, 3, DocumentRowNode);

            MatchRecordValue(FieldRecordRef, 4, DocumentRowNode, 4);
            MatchRecordValue(FieldRecordRef, 5, DocumentRowNode, 5);
            MatchRecordValue(FieldRecordRef, 6, DocumentRowNode, 6);
            MatchRecordValue(FieldRecordRef, 10, DocumentRowNode, 9);
            MatchRecordValue(FieldRecordRef, 13, DocumentRowNode, 10);

            DocumentRowNode.ParentNode.RemoveChild(DocumentRowNode);
        until FieldRecordRef.Next = 0;

        DocumentTableNode := Document.SelectSingleNode('/Workbook/Worksheet/Table');
        // Only the header can remain
        Assert.AreEqual(
          1, DocumentTableNode.ChildNodes.Count,
          'One or more items are not present in the database.\' + DocumentTableNode.InnerXml);
    end;

    local procedure VerifyOSynchEntityWithRelatedEntriesDeleted(OutlookSynchEntityCode: Code[10]; OutlookSynchEntityRecGUID: Guid)
    var
        OutlookSynchEntity: Record "Outlook Synch. Entity";
        OutlookSynchEntityElement: Record "Outlook Synch. Entity Element";
        OutlookSynchField: Record "Outlook Synch. Field";
        OutlookSynchFilter: Record "Outlook Synch. Filter";
        OutlookSynchDependency: Record "Outlook Synch. Dependency";
    begin
        OutlookSynchEntity.SetRange(Code, OutlookSynchEntityCode);
        Assert.RecordIsEmpty(OutlookSynchEntity);

        OutlookSynchEntityElement.SetRange("Synch. Entity Code", OutlookSynchEntityCode);
        Assert.RecordIsEmpty(OutlookSynchEntityElement);

        OutlookSynchField.SetRange("Synch. Entity Code", OutlookSynchEntityCode);
        Assert.RecordIsEmpty(OutlookSynchField);

        OutlookSynchFilter.SetRange("Record GUID", OutlookSynchEntityRecGUID);
        Assert.RecordIsEmpty(OutlookSynchFilter);

        OutlookSynchDependency.SetRange("Depend. Synch. Entity Code", OutlookSynchEntityCode);
        Assert.RecordIsEmpty(OutlookSynchDependency);
    end;

    local procedure MatchRecordValue(var RecordRef: RecordRef; FieldId: Integer; var DocumentRowNode: DotNet XmlNode; CellIndex: Integer)
    var
        ValueNode: DotNet XmlElement;
        ValueFieldRef: FieldRef;
        Value: Text;
    begin
        ValueFieldRef := RecordRef.Field(FieldId);

        ValueNode := DocumentRowNode.SelectSingleNode('Cell[position()=' + Format(CellIndex) + ']/Data');
        Value := ValueNode.InnerText;
        Assert.AreEqual(Value, Format(ValueFieldRef.Value), 'Did not find expected values in row.\' + Format(RecordRef));
    end;

    local procedure FindDocumentRow(var RecordRef: RecordRef; IdentifierFieldId: Integer; var Document: DotNet XmlDocument; IdentifierCellIndex: Integer; var DocumentRowNode: DotNet XmlNode)
    var
        IdentifierFieldRef: FieldRef;
        "Query": Text;
    begin
        IdentifierFieldRef := RecordRef.Field(IdentifierFieldId);
        Query :=
          '/Workbook/Worksheet/Table/Row[Cell[position()=' +
          Format(IdentifierCellIndex) + ']/Data=''' +
          Format(IdentifierFieldRef.Value) + ''']';
        DocumentRowNode := Document.SelectSingleNode(Query);
        if IsNull(DocumentRowNode) then
            Assert.Fail(CopyStr('Failed to find document row for query: ' + Query, 1, 1024));
    end;

    local procedure CreateFilterCompareDocument(var Document: DotNet XmlDocument)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
    begin
        XMLDOMManagement.LoadXMLDocumentFromText(
          '<?xml version="1.0"?>' +
          '<Workbook>' +
          ' <Worksheet Name="5303">' +
          '  <Table>' +
          '   <Row>' +
          '    <Cell><Data>Record GUID</Data></Cell>' +
          '    <Cell><Data>Filter Type</Data></Cell>' +
          '    <Cell><Data>Line No.</Data></Cell>' +
          '    <Cell><Data>Table No.</Data></Cell>' +
          '    <Cell><Data>Field No.</Data></Cell>' +
          '    <Cell><Data>Type</Data></Cell>' +
          '    <Cell><Data>Value</Data></Cell>' +
          '    <Cell><Data>Master Table No.</Data></Cell>' +
          '    <Cell><Data>Master Table Field No.</Data></Cell>' +
          '    <Cell><Data>FilterExpression</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{629b434d-2960-45bb-9445-664d96c93203}</Data></Cell>' +
          '    <Cell><Data>Condition</Data></Cell>' +
          '    <Cell><Data>10000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>CONST</Data></Cell>' +
          '    <Cell><Data>Person</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field5050=1(1)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{71aba7f7-27bb-488a-a51a-c0faa4f29e7d}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>20000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>Company No.</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>5051</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{71aba7f7-27bb-488a-a51a-c0faa4f29e7d}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>30000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>CONST</Data></Cell>' +
          '    <Cell><Data>Company</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field5050=1(0)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{bd7774ea-9f4a-4b32-b41b-bd28a42fe1c1}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>40000</Data></Cell>' +
          '    <Cell><Data>9</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>Country/Region Code</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>35</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{e124337c-4d75-4a91-9e79-e111ce96cd2d}</Data></Cell>' +
          '    <Cell><Data>Condition</Data></Cell>' +
          '    <Cell><Data>50000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>CONST</Data></Cell>' +
          '    <Cell><Data>Company</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field5050=1(0)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{bbe3bece-a8a8-44d8-a91c-999e0478f393}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>60000</Data></Cell>' +
          '    <Cell><Data>225</Data></Cell>' +
          '    <Cell><Data>2</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>City</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>7</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{4f04ee5f-6a2d-447b-ae4d-97c9c21a7fed}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>70000</Data></Cell>' +
          '    <Cell><Data>225</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>Post Code</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>91</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{33865f0d-63e8-4cae-b1b4-d74d746f2b25}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>80000</Data></Cell>' +
          '    <Cell><Data>9</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>Country/Region Code</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>35</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{bd81cc3f-c4d7-4a91-b36b-df4b576f32a1}</Data></Cell>' +
          '    <Cell><Data>Condition</Data></Cell>' +
          '    <Cell><Data>90000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>8</Data></Cell>' +
          '    <Cell><Data>CONST</Data></Cell>' +
          '    <Cell><Data>Meeting</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field8=1(1)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{bd81cc3f-c4d7-4a91-b36b-df4b576f32a1}</Data></Cell>' +
          '    <Cell><Data>Condition</Data></Cell>' +
          '    <Cell><Data>100000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>17</Data></Cell>' +
          '    <Cell><Data>CONST</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field17=1(0)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{bd81cc3f-c4d7-4a91-b36b-df4b576f32a1}</Data></Cell>' +
          '    <Cell><Data>Condition</Data></Cell>' +
          '    <Cell><Data>110000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>45</Data></Cell>' +
          '    <Cell><Data>CONST</Data></Cell>' +
          '    <Cell><Data>Organizer</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field45=1(0)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{bd81cc3f-c4d7-4a91-b36b-df4b576f32a1}</Data></Cell>' +
          '    <Cell><Data>Condition</Data></Cell>' +
          '    <Cell><Data>120000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>2</Data></Cell>' +
          '    <Cell><Data>CONST</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field2=1(==)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{e77ca386-b531-4864-882f-4d58414399bb}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>130000</Data></Cell>' +
          '    <Cell><Data>13</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>Salesperson Code</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>3</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{4f775f81-1c98-47ca-a9c9-371bd058c57f}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>140000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>No.</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{4f775f81-1c98-47ca-a9c9-371bd058c57f}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>150000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>7</Data></Cell>' +
          '    <Cell><Data>CONST</Data></Cell>' +
          '    <Cell><Data>Yes</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field7=1(1)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{dfb6dc33-4e5b-4322-959e-0984dd36c90b}</Data></Cell>' +
          '    <Cell><Data>Condition</Data></Cell>' +
          '    <Cell><Data>160000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>4</Data></Cell>' +
          '    <Cell><Data>CONST</Data></Cell>' +
          '    <Cell><Data>Contact</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field4=1(0)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{dfb6dc33-4e5b-4322-959e-0984dd36c90b}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>170000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>Attendee No.</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>5</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{a17c030a-34ac-4e48-8186-4fc91b5f6746}</Data></Cell>' +
          '    <Cell><Data>Condition</Data></Cell>' +
          '    <Cell><Data>180000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>4</Data></Cell>' +
          '    <Cell><Data>CONST</Data></Cell>' +
          '    <Cell><Data>Contact</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field4=1(0)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{a17c030a-34ac-4e48-8186-4fc91b5f6746}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>190000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>Attendee No.</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>5</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{9194c09f-9e4b-40f8-9cb0-eb651b2a6def}</Data></Cell>' +
          '    <Cell><Data>Condition</Data></Cell>' +
          '    <Cell><Data>200000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>4</Data></Cell>' +
          '    <Cell><Data>CONST</Data></Cell>' +
          '    <Cell><Data>Salesperson</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field4=1(1)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{9194c09f-9e4b-40f8-9cb0-eb651b2a6def}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>210000</Data></Cell>' +
          '    <Cell><Data>13</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>Attendee No.</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>5</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{8f35a934-6c4d-4fab-868f-584069e6b4a9}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>220000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>Attendee No.</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>5</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{8f35a934-6c4d-4fab-868f-584069e6b4a9}</Data></Cell>' +
          '    <Cell><Data>Condition</Data></Cell>' +
          '    <Cell><Data>230000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>4</Data></Cell>' +
          '    <Cell><Data>CONST</Data></Cell>' +
          '    <Cell><Data>Contact</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field4=1(0)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{cc5a271d-4f34-4f11-b6f7-b74b80fb69e0}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>240000</Data></Cell>' +
          '    <Cell><Data>13</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>Attendee No.</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>5</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{cc5a271d-4f34-4f11-b6f7-b74b80fb69e0}</Data></Cell>' +
          '    <Cell><Data>Condition</Data></Cell>' +
          '    <Cell><Data>250000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>4</Data></Cell>' +
          '    <Cell><Data>CONST</Data></Cell>' +
          '    <Cell><Data>Salesperson</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field4=1(1)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{9b4f46e9-00ba-42f1-a263-dea1f5540209}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>260000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>No.</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{9b4f46e9-00ba-42f1-a263-dea1f5540209}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>270000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>7</Data></Cell>' +
          '    <Cell><Data>CONST</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field7=1(0)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{1f3dc712-aeae-4e88-9d8f-e8c8e156d130}</Data></Cell>' +
          '    <Cell><Data>Condition</Data></Cell>' +
          '    <Cell><Data>280000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>4</Data></Cell>' +
          '    <Cell><Data>CONST</Data></Cell>' +
          '    <Cell><Data>Contact</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field4=1(0)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{1f3dc712-aeae-4e88-9d8f-e8c8e156d130}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>290000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>Attendee No.</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>5</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{0494773c-e92b-4693-9084-72deeb2d3e48}</Data></Cell>' +
          '    <Cell><Data>Condition</Data></Cell>' +
          '    <Cell><Data>300000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>4</Data></Cell>' +
          '    <Cell><Data>CONST</Data></Cell>' +
          '    <Cell><Data>Contact</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field4=1(0)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{0494773c-e92b-4693-9084-72deeb2d3e48}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>310000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>Attendee No.</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>5</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{01acd336-184f-4f64-a8b6-f00ed86da54b}</Data></Cell>' +
          '    <Cell><Data>Condition</Data></Cell>' +
          '    <Cell><Data>320000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>4</Data></Cell>' +
          '    <Cell><Data>CONST</Data></Cell>' +
          '    <Cell><Data>Salesperson</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field4=1(1)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{01acd336-184f-4f64-a8b6-f00ed86da54b}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>330000</Data></Cell>' +
          '    <Cell><Data>13</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>Attendee No.</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>5</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{0be2e144-b417-4cd4-abf5-38acccf09d7c}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>340000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>Attendee No.</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>5</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{0be2e144-b417-4cd4-abf5-38acccf09d7c}</Data></Cell>' +
          '    <Cell><Data>Condition</Data></Cell>' +
          '    <Cell><Data>350000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>4</Data></Cell>' +
          '    <Cell><Data>CONST</Data></Cell>' +
          '    <Cell><Data>Contact</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field4=1(0)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{cae1d8d2-1a4e-4b5f-a64d-b8ea7fe84ba0}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>360000</Data></Cell>' +
          '    <Cell><Data>13</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>Attendee No.</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>5</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{cae1d8d2-1a4e-4b5f-a64d-b8ea7fe84ba0}</Data></Cell>' +
          '    <Cell><Data>Condition</Data></Cell>' +
          '    <Cell><Data>370000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>4</Data></Cell>' +
          '    <Cell><Data>CONST</Data></Cell>' +
          '    <Cell><Data>Salesperson</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field4=1(1)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{734668d7-54dd-4ade-b5dc-66ad08ee4b0f}</Data></Cell>' +
          '    <Cell><Data>Condition</Data></Cell>' +
          '    <Cell><Data>380000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>8</Data></Cell>' +
          '    <Cell><Data>FILTER</Data></Cell>' +
          '    <Cell><Data>&lt;&gt;Meeting</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field8=1(&lt;&gt;1)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{734668d7-54dd-4ade-b5dc-66ad08ee4b0f}</Data></Cell>' +
          '    <Cell><Data>Condition</Data></Cell>' +
          '    <Cell><Data>390000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>45</Data></Cell>' +
          '    <Cell><Data>CONST</Data></Cell>' +
          '    <Cell><Data>Organizer</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field45=1(0)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{734668d7-54dd-4ade-b5dc-66ad08ee4b0f}</Data></Cell>' +
          '    <Cell><Data>Condition</Data></Cell>' +
          '    <Cell><Data>400000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>2</Data></Cell>' +
          '    <Cell><Data>CONST</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field2=1(==)</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{8adf6fad-ffbc-4164-9f15-31077c83719f}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>410000</Data></Cell>' +
          '    <Cell><Data>13</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>Salesperson Code</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>3</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{57f1f552-add3-4f0d-80d9-8bc75e17dc61}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>420000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>No.</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{57f1f552-add3-4f0d-80d9-8bc75e17dc61}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>430000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>5</Data></Cell>' +
          '    <Cell><Data>FILTER</Data></Cell>' +
          '    <Cell><Data>&lt;&gt;''''</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>Field5=1(&lt;&gt;'''')</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{34799719-ec75-4318-b042-5c0010dac777}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>440000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>Contact No.</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>5</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{5d9efb42-30bf-4f4e-bfaf-64786d579cd9}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>450000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>Contact No.</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>5</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>{70ec0144-eaee-441c-9cd5-bba3a19f822f}</Data></Cell>' +
          '    <Cell><Data>Table Relation</Data></Cell>' +
          '    <Cell><Data>460000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>FIELD</Data></Cell>' +
          '    <Cell><Data>Contact No.</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>5</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '   </Row>' +
          '  </Table>' +
          ' </Worksheet>' +
          '</Workbook>',
          Document);
    end;

    local procedure CreateFieldCompareDocument(var Document: DotNet XmlDocument)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
    begin
        XMLDOMManagement.LoadXMLDocumentFromText(
          '<?xml version="1.0"?>' +
          '<Workbook>' +
          ' <Worksheet Name="5304">' +
          '  <Table>' +
          '   <Row>' +
          '    <Cell><Data>Synch. Entity Code</Data></Cell>' +
          '    <Cell><Data>Element No.</Data></Cell>' +
          '    <Cell><Data>Line No.</Data></Cell>' +
          '    <Cell><Data>Master Table No.</Data></Cell>' +
          '    <Cell><Data>Outlook Object</Data></Cell>' +
          '    <Cell><Data>Outlook Property</Data></Cell>' +
          '    <Cell><Data>User-Defined</Data></Cell>' +
          '    <Cell><Data>Search Field</Data></Cell>' +
          '    <Cell><Data>Table No.</Data></Cell>' +
          '    <Cell><Data>Field No.</Data></Cell>' +
          '    <Cell><Data>Read-Only Status</Data></Cell>' +
          '    <Cell><Data>Field Default Value</Data></Cell>' +
          '    <Cell><Data>Record GUID</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_PERS</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>10000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>Read-Only in Microsoft Dynamics NAV</Data></Cell>' +
          '    <Cell><Data>Person</Data></Cell>' +
          '    <Cell><Data>{9f26f043-0e67-46c5-8dec-f8f0496213be}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_PERS</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>20000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>CompanyName</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>5052</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{71aba7f7-27bb-488a-a51a-c0faa4f29e7d}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_PERS</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>30000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>FullName</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>2</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{c8c04354-ce49-49f4-bb29-37452d3c641a}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_PERS</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>40000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>FirstName</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>5054</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{20533874-d763-4e43-843a-e0ec52258d9c}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_PERS</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>50000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>MiddleName</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>5055</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{9e811b47-56a8-49c4-8f62-209d52a5dde6}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_PERS</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>60000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>LastName</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>5056</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{0cce3c28-c2b5-4408-8f77-b92ca792b26c}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_PERS</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>70000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>JobTitle</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>5058</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{6655c88f-e366-4d5a-9bb6-3aabf27114ae}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_PERS</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>80000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>BusinessAddressStreet</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>5</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{40408e41-eead-4884-b5ec-1819bd9d1184}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_PERS</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>90000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>BusinessAddressCity</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>7</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{7613bf3c-7687-48e0-9a94-68476333502c}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_PERS</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>100000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>BusinessAddressPostalCode</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>91</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{a2076e2c-9884-4aaa-b640-5a6f6ea63d42}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_PERS</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>110000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>BusinessAddressCountry</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>9</Data></Cell>' +
          '    <Cell><Data>2</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{bd7774ea-9f4a-4b32-b41b-bd28a42fe1c1}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_PERS</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>120000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>BusinessTelephoneNumber</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>9</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{d50250dd-a8fd-4c5f-b9c4-65e4867c021f}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_PERS</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>130000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>BusinessFaxNumber</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>84</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{ff62367b-efc4-4a17-b74a-6d677b8e3477}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_PERS</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>140000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>BusinessHomePage</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>103</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{ec23ded1-8644-466d-b7ba-2ec27a3adbcf}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_PERS</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>150000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>Email1Address</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>102</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{b86ba6cb-70a1-4f12-83a6-13bc93c2193e}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_PERS</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>160000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>Email2Address</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>5105</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{e0647078-a888-42dd-bdde-764b08e7b13f}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_PERS</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>170000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>MobileTelephoneNumber</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>5061</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{3c516463-4497-4e4a-b0cc-e85fe5c668f0}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_PERS</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>180000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>PagerNumber</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>5062</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{20d19dc4-8317-40a7-9921-d02fa2042ec0}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_PERS</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>190000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>TelexNumber</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>10</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{b8c9e3f1-bcc3-4202-8a51-83d987fed776}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_PERS</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>200000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>Salesperson Code</Data></Cell>' +
          '    <Cell><Data>Yes</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>29</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{9fcfd0eb-f521-4737-9c17-beb40516e7a5}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_COMP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>210000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>Read-Only in Microsoft Dynamics NAV</Data></Cell>' +
          '    <Cell><Data>Company</Data></Cell>' +
          '    <Cell><Data>{96a127eb-891f-40e1-b944-01d0e568d4d6}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_COMP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>220000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>BusinessAddressStreet</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>5</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{f69a6c18-1eab-4812-9b22-bbf598ff8668}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_COMP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>230000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>BusinessAddressCity</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>225</Data></Cell>' +
          '    <Cell><Data>2</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{bbe3bece-a8a8-44d8-a91c-999e0478f393}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_COMP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>240000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>BusinessAddressPostalCode</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>225</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{4f04ee5f-6a2d-447b-ae4d-97c9c21a7fed}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_COMP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>250000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>BusinessAddressCountry</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>9</Data></Cell>' +
          '    <Cell><Data>2</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{33865f0d-63e8-4cae-b1b4-d74d746f2b25}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_COMP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>260000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>BusinessTelephoneNumber</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>9</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{7352c395-2e4c-486c-8c2d-f610e2a4697c}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_COMP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>270000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>CompanyName</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>2</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{1258079d-efe6-4130-8e86-ba405e7f3233}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_COMP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>280000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>BusinessFaxNumber</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>84</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{32ab687f-3fb3-4942-837b-4c8602c43d63}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_COMP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>290000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>Email1Address</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>102</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{89f89f32-e1e6-49a1-b697-62ca499bacac}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_COMP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>300000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>Email2Address</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>5105</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{6d55136f-3e84-4638-aa69-6e67574ad95a}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_COMP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>310000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>BusinessHomePage</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>103</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{ffd9cbd7-e6f7-4a76-82a2-3bdb526b0f5f}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_COMP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>320000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>MobileTelephoneNumber</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>5061</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{38190f83-51d4-497e-97bc-44641b531637}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_COMP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>330000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>PagerNumber</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>5062</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{0b7fa4be-7cd8-41f5-b6e3-d11bc68b8946}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_COMP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>340000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>TelexNumber</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>10</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{e3ace3c5-a07a-415d-9ff3-1de035978e9a}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_COMP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>350000</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>Salesperson Code</Data></Cell>' +
          '    <Cell><Data>Yes</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>29</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{6f3aa923-28fd-4377-9c6a-f6075613f947}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_SP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>360000</Data></Cell>' +
          '    <Cell><Data>13</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>FullName</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>2</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{c996f325-82e0-4a0e-8ae3-34d5ee360c5d}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_SP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>370000</Data></Cell>' +
          '    <Cell><Data>13</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>JobTitle</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>5062</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{7ae30e7a-29fa-408d-bb8f-8a3b75aac201}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_SP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>380000</Data></Cell>' +
          '    <Cell><Data>13</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>Email1Address</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>5052</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{0b95a8f7-0091-4c1e-b8a2-c060f6e99d78}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_SP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>390000</Data></Cell>' +
          '    <Cell><Data>13</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>Email2Address</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>5086</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{d0c85350-2625-4041-ba25-e54ea02afbd8}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_SP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>400000</Data></Cell>' +
          '    <Cell><Data>13</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>BusinessTelephoneNumber</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>5053</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{624c9903-c97e-4087-bd4c-785f3593f009}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>CONT_SP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>410000</Data></Cell>' +
          '    <Cell><Data>13</Data></Cell>' +
          '    <Cell><Data>ContactItem</Data></Cell>' +
          '    <Cell><Data>Salesperson Code</Data></Cell>' +
          '    <Cell><Data>Yes</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>1</Data></Cell>' +
          '    <Cell><Data>Read-Only in Microsoft Dynamics NAV</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{6f76227b-282a-4739-a1ff-6e6db6eae4a2}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>APP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>420000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>AppointmentItem</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>8</Data></Cell>' +
          '    <Cell><Data>Read-Only in Microsoft Dynamics NAV</Data></Cell>' +
          '    <Cell><Data>Meeting</Data></Cell>' +
          '    <Cell><Data>{e752fe68-c375-4f85-9167-f100e0a678e2}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>APP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>430000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>AppointmentItem</Data></Cell>' +
          '    <Cell><Data>Start</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>9</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{b1ddb790-8edb-4611-8efb-cc9d724a9b74}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>APP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>440000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>AppointmentItem</Data></Cell>' +
          '    <Cell><Data>Start</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>28</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{f4741de4-e043-41ee-9b5a-ebbe341c2a90}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>APP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>450000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>AppointmentItem</Data></Cell>' +
          '    <Cell><Data>Subject</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>12</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{12471866-9634-4043-96c1-d84c68b0479e}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>APP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>460000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>AppointmentItem</Data></Cell>' +
          '    <Cell><Data>Location</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>35</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{273954b6-d7dd-47db-ae30-4fbb14acb1d1}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>APP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>470000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>AppointmentItem</Data></Cell>' +
          '    <Cell><Data>AllDayEvent</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>34</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{3ccdaef5-5a92-4cf4-a4d0-db4d10fd7da9}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>APP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>480000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>AppointmentItem</Data></Cell>' +
          '    <Cell><Data>Importance</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>11</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{cf9b8b90-44b6-4e32-aae9-433d3cec09f3}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>APP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>490000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>AppointmentItem</Data></Cell>' +
          '    <Cell><Data>Duration</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>29</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{8a5ecc69-7afc-4a2e-b52e-5cabb21f6435}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>APP</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>500000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>AppointmentItem</Data></Cell>' +
          '    <Cell><Data>Organizer</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>13</Data></Cell>' +
          '    <Cell><Data>2</Data></Cell>' +
          '    <Cell><Data>Read-Only in Outlook</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{e77ca386-b531-4864-882f-4d58414399bb}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>APP</Data></Cell>' +
          '    <Cell><Data>10000</Data></Cell>' +
          '    <Cell><Data>510000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>Recipients</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>7</Data></Cell>' +
          '    <Cell><Data>Read-Only in Microsoft Dynamics NAV</Data></Cell>' +
          '    <Cell><Data>Yes</Data></Cell>' +
          '    <Cell><Data>{c34b2041-2c69-4508-b3a0-795aced701c4}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>APP</Data></Cell>' +
          '    <Cell><Data>10000</Data></Cell>' +
          '    <Cell><Data>520000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>Recipients</Data></Cell>' +
          '    <Cell><Data>Type</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>3</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{21a290c6-8d0d-4ea7-ab25-87f2f829d5d3}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>APP</Data></Cell>' +
          '    <Cell><Data>10000</Data></Cell>' +
          '    <Cell><Data>530000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>Recipients</Data></Cell>' +
          '    <Cell><Data>Address</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>Yes</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>102</Data></Cell>' +
          '    <Cell><Data>Read-Only in Outlook</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{8f35a934-6c4d-4fab-868f-584069e6b4a9}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>APP</Data></Cell>' +
          '    <Cell><Data>10000</Data></Cell>' +
          '    <Cell><Data>540000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>Recipients</Data></Cell>' +
          '    <Cell><Data>Address</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>Yes</Data></Cell>' +
          '    <Cell><Data>13</Data></Cell>' +
          '    <Cell><Data>5052</Data></Cell>' +
          '    <Cell><Data>Read-Only in Outlook</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{cc5a271d-4f34-4f11-b6f7-b74b80fb69e0}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>APP</Data></Cell>' +
          '    <Cell><Data>10000</Data></Cell>' +
          '    <Cell><Data>550000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>Recipients</Data></Cell>' +
          '    <Cell><Data>MeetingResponseStatus</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>8</Data></Cell>' +
          '    <Cell><Data>Read-Only in Outlook</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{e028bea3-9510-41a8-a4a2-68ea55da2f47}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>APP</Data></Cell>' +
          '    <Cell><Data>20000</Data></Cell>' +
          '    <Cell><Data>560000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>Links</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>7</Data></Cell>' +
          '    <Cell><Data>Read-Only in Microsoft Dynamics NAV</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>{5508511a-6e3d-4a5a-b5e2-8e431e20a4e7}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>APP</Data></Cell>' +
          '    <Cell><Data>20000</Data></Cell>' +
          '    <Cell><Data>570000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>Links</Data></Cell>' +
          '    <Cell><Data>Name</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>Yes</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>2</Data></Cell>' +
          '    <Cell><Data>Read-Only in Outlook</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{0be2e144-b417-4cd4-abf5-38acccf09d7c}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>APP</Data></Cell>' +
          '    <Cell><Data>20000</Data></Cell>' +
          '    <Cell><Data>580000</Data></Cell>' +
          '    <Cell><Data>5199</Data></Cell>' +
          '    <Cell><Data>Links</Data></Cell>' +
          '    <Cell><Data>Name</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>Yes</Data></Cell>' +
          '    <Cell><Data>13</Data></Cell>' +
          '    <Cell><Data>2</Data></Cell>' +
          '    <Cell><Data>Read-Only in Outlook</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{cae1d8d2-1a4e-4b5f-a64d-b8ea7fe84ba0}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>TASK</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>590000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>TaskItem</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>8</Data></Cell>' +
          '    <Cell><Data>Read-Only in Microsoft Dynamics NAV</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{30cb6f4b-c969-44eb-a2df-b1b3c05a5fc6}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>TASK</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>600000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>TaskItem</Data></Cell>' +
          '    <Cell><Data>StartDate</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>9</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{4c5e9625-3fc6-4d1e-99f7-0afc60892ee7}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>TASK</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>610000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>TaskItem</Data></Cell>' +
          '    <Cell><Data>StartDate</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>28</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{b981ace2-20f7-4d3c-a676-6b49bacadd5d}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>TASK</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>620000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>TaskItem</Data></Cell>' +
          '    <Cell><Data>DueDate</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>47</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{bfbcfa5d-e208-41ae-9789-a8491304b983}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>TASK</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>630000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>TaskItem</Data></Cell>' +
          '    <Cell><Data>DueDate</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>48</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{0605cd22-ff2f-4c08-8d38-a30b5c3462eb}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>TASK</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>640000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>TaskItem</Data></Cell>' +
          '    <Cell><Data>Subject</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>12</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{22bcb8fe-32cd-4d88-b944-75cc4f9b3205}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>TASK</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>650000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>TaskItem</Data></Cell>' +
          '    <Cell><Data>Importance</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>11</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{60dc2202-db6a-4372-b255-b807eb6c082c}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>TASK</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>660000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>TaskItem</Data></Cell>' +
          '    <Cell><Data>Status</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>10</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{0472c7ba-b9a2-4f4a-89bf-854e38a67773}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>TASK</Data></Cell>' +
          '    <Cell><Data>0</Data></Cell>' +
          '    <Cell><Data>670000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>TaskItem</Data></Cell>' +
          '    <Cell><Data>Owner</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>13</Data></Cell>' +
          '    <Cell><Data>2</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{8adf6fad-ffbc-4164-9f15-31077c83719f}</Data></Cell>' +
          '   </Row>' +
          '   <Row>' +
          '    <Cell><Data>TASK</Data></Cell>' +
          '    <Cell><Data>30000</Data></Cell>' +
          '    <Cell><Data>680000</Data></Cell>' +
          '    <Cell><Data>5080</Data></Cell>' +
          '    <Cell><Data>Links</Data></Cell>' +
          '    <Cell><Data>Name</Data></Cell>' +
          '    <Cell><Data>No</Data></Cell>' +
          '    <Cell><Data>Yes</Data></Cell>' +
          '    <Cell><Data>5050</Data></Cell>' +
          '    <Cell><Data>2</Data></Cell>' +
          '    <Cell><Data>Read-Only in Outlook</Data></Cell>' +
          '    <Cell><Data></Data></Cell>' +
          '    <Cell><Data>{70ec0144-eaee-441c-9cd5-bba3a19f822f}</Data></Cell>' +
          '   </Row>' +
          '  </Table>' +
          ' </Worksheet>' +
          '</Workbook>',
          Document);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ResetEntitySelectEntityStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := ResetEntityChoiceValue;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure AlwaysDeleteDependenciesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
#endif
