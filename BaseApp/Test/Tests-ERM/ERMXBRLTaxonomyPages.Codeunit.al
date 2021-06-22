codeunit 134240 "ERM - XBRL Taxonomy Pages"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [XBRL Taxonomy] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryXBRL: Codeunit "Library - XBRL";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        SingleLineExpectedErr: Label 'The only single visible line expected';
        InsertedLabelsMsg: Label 'Applied %1 labels.', Comment = '%1 - integer, e.g. "Applied 3 labels."';
        InsertedPresentationsMsg: Label 'Applied %1 presentation relations.', Comment = '%1 - integer, e.g. "Applied 3 presentation relations."';
        InsertedCalculationsMsg: Label 'Applied %1 calculations.', Comment = '%1 - integer, e.g. "Applied 3 calculations."';
        InsertedReferencesMsg: Label 'Applied %1 references.', Comment = '%1 - integer, e.g. "Applied 3 references."';
        InsertedSchemeMsg: Label 'Applied %1 taxonomy lines.', Comment = '%1 - integer, e.g. "Applied 3 taxonomy lines."';

    [Test]
    [HandlerFunctions('XBRLCommentLinesMPH')]
    [Scope('OnPrem')]
    procedure ShowNotesCommentsDialog()
    var
        XBRLCommentLine: Record "XBRL Comment Line";
        XBRLTaxonomyLine: Record "XBRL Taxonomy Line";
        XBRLTaxonomyLines: TestPage "XBRL Taxonomy Lines";
    begin
        // [SCENARIO 257237] Stan can open filtered "XBRL Taxonomy Line Notes" dialog from "XBRL Taxonomy Lines" page
        CreateXBRLTaxonomyWithLine(XBRLTaxonomyLine);

        LibraryXBRL.CreateXBRLCommentLine(XBRLCommentLine, XBRLTaxonomyLine, XBRLCommentLine."Comment Type"::Notes, '', 0D);

        OpenTaxonomyLinesFromTaxonomyCard(XBRLTaxonomyLines, XBRLTaxonomyLine);

        LibraryVariableStorage.Enqueue(XBRLCommentLine.Comment);
        LibraryVariableStorage.Enqueue(XBRLCommentLine.Date);

        XBRLTaxonomyLines.Notes.Invoke;

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('XBRLCommentLinesMPH')]
    [Scope('OnPrem')]
    procedure ShowInformationCommentsDialog()
    var
        XBRLCommentLine: Record "XBRL Comment Line";
        XBRLTaxonomyLine: Record "XBRL Taxonomy Line";
        XBRLTaxonomyLines: TestPage "XBRL Taxonomy Lines";
    begin
        // [SCENARIO 257237] Stan can open filtered "XBRL Taxonomy Line Information" dialog from "XBRL Taxonomy Lines" page
        CreateXBRLTaxonomyWithLine(XBRLTaxonomyLine);

        LibraryXBRL.CreateXBRLCommentLine(XBRLCommentLine, XBRLTaxonomyLine, XBRLCommentLine."Comment Type"::Information, '', 0D);

        OpenTaxonomyLinesFromTaxonomyCard(XBRLTaxonomyLines, XBRLTaxonomyLine);

        LibraryVariableStorage.Enqueue(XBRLCommentLine.Comment);
        LibraryVariableStorage.Enqueue(XBRLCommentLine.Date);

        XBRLTaxonomyLines.Information.Invoke;

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('XBRLCommentLinesMPH')]
    [Scope('OnPrem')]
    procedure ShowReferenceDialog()
    var
        XBRLCommentLine: Record "XBRL Comment Line";
        XBRLTaxonomyLine: Record "XBRL Taxonomy Line";
        XBRLTaxonomyLines: TestPage "XBRL Taxonomy Lines";
    begin
        // [SCENARIO 257237] Stan can open filtered "XBRL Taxonomy Line References" dialog from "XBRL Taxonomy Lines" page
        CreateXBRLTaxonomyWithLine(XBRLTaxonomyLine);

        LibraryXBRL.CreateXBRLCommentLine(XBRLCommentLine, XBRLTaxonomyLine, XBRLCommentLine."Comment Type"::Reference, '', 0D);

        OpenTaxonomyLinesFromTaxonomyCard(XBRLTaxonomyLines, XBRLTaxonomyLine);

        LibraryVariableStorage.Enqueue(XBRLCommentLine.Comment);
        LibraryVariableStorage.Enqueue(XBRLCommentLine.Date);

        XBRLTaxonomyLines.Reference.Invoke;

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('XBRLRollupLinesMPH')]
    [Scope('OnPrem')]
    procedure ShowRollupDialog()
    var
        XBRLTaxonomy: Record "XBRL Taxonomy";
        XBRLTaxonomyLine: Record "XBRL Taxonomy Line";
        XBRLTaxonomyLineFrom: Record "XBRL Taxonomy Line";
        XBRLRollupLine: Record "XBRL Rollup Line";
        XBRLTaxonomyLines: TestPage "XBRL Taxonomy Lines";
    begin
        // [SCENARIO 257237] Stan can open filtered "XBRL Rollups" dialog from "XBRL Taxonomy Lines" page
        CreateXBRLTaxonomyWithLine(XBRLTaxonomyLine);

        XBRLTaxonomy.Get(XBRLTaxonomyLine."XBRL Taxonomy Name");
        LibraryXBRL.CreateXBRLTaxonomyLine(XBRLTaxonomyLineFrom, XBRLTaxonomy, 0);
        LibraryXBRL.CreateXBRLRollupLine(XBRLRollupLine, XBRLTaxonomyLine, XBRLTaxonomyLineFrom);

        OpenTaxonomyLinesFromTaxonomyCard(XBRLTaxonomyLines, XBRLTaxonomyLine);

        LibraryVariableStorage.Enqueue(XBRLRollupLine.Weight);

        XBRLTaxonomyLines.Rollups.Invoke;

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('XBRLGLMapLinesMPH')]
    [Scope('OnPrem')]
    procedure ShowGLMapDialog()
    var
        XBRLTaxonomyLine: Record "XBRL Taxonomy Line";
        XBRLGLMapLine: Record "XBRL G/L Map Line";
        XBRLTaxonomyLines: TestPage "XBRL Taxonomy Lines";
    begin
        // [SCENARIO 257237] Stan can open filtered "XBRL G/L Map Lines" dialog from "XBRL Taxonomy Lines" page
        CreateXBRLTaxonomyWithLine(XBRLTaxonomyLine);

        LibraryXBRL.CreateXBRLGLMapLine(XBRLGLMapLine, XBRLTaxonomyLine);
        XBRLGLMapLine."G/L Account Filter" := LibraryUtility.GenerateGUID;
        XBRLGLMapLine.Modify();

        OpenTaxonomyLinesFromTaxonomyCard(XBRLTaxonomyLines, XBRLTaxonomyLine);

        LibraryVariableStorage.Enqueue(XBRLGLMapLine."G/L Account Filter");
        XBRLTaxonomyLines.GLMapLines.Invoke;

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('XBRLLineConstantsMPH')]
    [Scope('OnPrem')]
    procedure ShowLineConstantDialog()
    var
        XBRLTaxonomyLine: Record "XBRL Taxonomy Line";
        XBRLLineConstant: Record "XBRL Line Constant";
        XBRLTaxonomyLines: TestPage "XBRL Taxonomy Lines";
    begin
        // [SCENARIO 257237] Stan can open filtered "XBRL Constant Lines" dialog from "XBRL Taxonomy Lines" page
        CreateXBRLTaxonomyWithLine(XBRLTaxonomyLine);

        LibraryXBRL.CreateXBRLLineConstant(XBRLLineConstant, XBRLTaxonomyLine);

        OpenTaxonomyLinesFromTaxonomyCard(XBRLTaxonomyLines, XBRLTaxonomyLine);

        LibraryVariableStorage.Enqueue(XBRLLineConstant."Constant Amount");
        LibraryVariableStorage.Enqueue(XBRLLineConstant."Starting Date");

        XBRLTaxonomyLines.Constants.Invoke;

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ImportSchemaSummaryMessage()
    var
        XBRLTaxonomy: Record "XBRL Taxonomy";
        XBRLTaxonomyLine: Record "XBRL Taxonomy Line";
        XBRLSchema: Record "XBRL Schema";
        XSD: Text;
        ElementID: Text;
        Name: Text;
        TargetNamespace: Text;
        XmlnsXbrli: Text;
    begin
        // [FEATURE] [UT] [XBRL Schema]
        // [SCENARIO 387254] Import XBRL Taxonomy Scheme shows a summary message
        Initialize();
        ElementID := LibraryUtility.GenerateGUID();
        Name := LibraryUtility.GenerateGUID();
        TargetNamespace := LibraryUtility.GenerateGUID();
        XmlnsXbrli := LibraryXBRL.GetXmlnsXbrli21();

        // [GIVEN] XBRL Taxonomy
        LibraryXBRL.CreateXBRLTaxonomyWithDetails(XBRLTaxonomy, LibraryUtility.GenerateGUID(), TargetNamespace, XmlnsXbrli);
        // [GIVEN] Schema XSD file containing single element
        XSD := GenerateSingleElementXSDText(ElementID, Name, TargetNamespace, XmlnsXbrli);

        // [WHEN] Perform "Import" action from XBRL Schemas page
        LibraryXBRL.ImportSchema(XBRLSchema, XBRLTaxonomy, XSD);

        // [THEN] A message is shown: "Applied 1 taxonomy lines."
        Assert.ExpectedMessage(StrSubstNo(InsertedSchemeMsg, 1), LibraryVariableStorage.DequeueText());

        // [THEN] A new taxonomy line has been created with correct taxonomy element info
        LibraryXBRL.FindXBRLTaxonomyLine(XBRLTaxonomyLine, XBRLTaxonomy.Name);
        XBRLTaxonomyLine.TestField(Name, Name);
        XBRLTaxonomyLine.TestField("Element ID", ElementID);
        XBRLTaxonomyLine.TestField("XBRL Item Type", 'monetaryItemType');
        XBRLTaxonomyLine.TestField("Source Type", XBRLTaxonomyLine."Source Type"::"General Ledger");
        XBRLTaxonomyLine.TestField("Numeric Context Period Type", XBRLTaxonomyLine."Numeric Context Period Type"::Instant);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ImportLabelSummaryMessage()
    var
        XBRLSchema: Record "XBRL Schema";
        XBRLTaxonomyLine: Record "XBRL Taxonomy Line";
        XBRLTaxonomyLabel: Record "XBRL Taxonomy Label";
        XML: Text;
        Label: Text;
    begin
        // [FEATURE] [UT] [XBRL Linkbases] [Label]
        // [SCENARIO 387254] Import XBRL Taxonomy Label linkbases shows a summary message
        Initialize();
        Label := LibraryUtility.GenerateGUID();

        // [GIVEN] XBRL Taxonomy with one line
        PrepareTaxonomyWithOneLine(XBRLSchema, XBRLTaxonomyLine);
        // [GIVEN] XML file containing single Label element
        XML := GenerateLabelsXMLText(XBRLSchema.schemaLocation, XBRLTaxonomyLine."Element ID", Label);

        // [WHEN] Perform "Import" action from XBRL Linkbases page using "Type" = "Label"
        LibraryXBRL.ImportLabels(XBRLSchema, XML);

        // [THEN] A message is shown: "Applied 1 labels."
        Assert.ExpectedMessage(StrSubstNo(InsertedLabelsMsg, 1), LibraryVariableStorage.DequeueText());

        // [THEN] A new taxonomy label record has been created with correct Label value
        LibraryXBRL.FindXBRLTaxonomyLabel(XBRLTaxonomyLabel, XBRLTaxonomyLine);
        XBRLTaxonomyLabel.TestField(Label, Label);

        // [THEN] The taxonomy line "Label" has been updated with a new value
        XBRLTaxonomyLine.CalcFields(Label);
        XBRLTaxonomyLine.TestField(Label, Label);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ImportPresentationSummaryMessage()
    var
        XBRLSchema: Record "XBRL Schema";
        XBRLTaxonomyLine: Record "XBRL Taxonomy Line";
        XML: Text;
        ElementID: array[2] of Text;
    begin
        // [FEATURE] [UT] [XBRL Linkbases] [Presenation]
        // [SCENARIO 387254] Import XBRL Taxonomy Presentation linkbases shows a summary message
        Initialize();

        // [GIVEN] XBRL Taxonomy with two lines
        PrepareTaxonomyWithTwoLines(XBRLSchema, ElementID);
        // [GIVEN] XML file containing single Presentation element
        XML := GeneratePresentationsXMLText(XBRLSchema.schemaLocation, ElementID[1], ElementID[2]);

        // [WHEN] Perform "Import" action from XBRL Linkbases page using "Type" = "Presentation"
        LibraryXBRL.ImportPresentations(XBRLSchema, XML);

        // [THEN] A message is shown: "Applied 1 presentation relations."
        Assert.ExpectedMessage(StrSubstNo(InsertedPresentationsMsg, 1), LibraryVariableStorage.DequeueText());

        // [THEN] The taxonomy lines have been updated with presentation order info
        LibraryXBRL.FindXBRLTaxonomyLine(XBRLTaxonomyLine, XBRLSchema."XBRL Taxonomy Name");
        XBRLTaxonomyLine.TestField("Element ID", ElementID[1]);
        XBRLTaxonomyLine.TestField("Parent Line No.", 0);
        XBRLTaxonomyLine.TestField("Presentation Order", '00010000');
        XBRLTaxonomyLine.TestField("Presentation Order No.", 0);

        XBRLTaxonomyLine.Next();
        XBRLTaxonomyLine.TestField("Element ID", ElementID[2]);
        XBRLTaxonomyLine.TestField("Parent Line No.", 10000);
        XBRLTaxonomyLine.TestField("Presentation Order", '00010000.010');
        XBRLTaxonomyLine.TestField("Presentation Order No.", 10);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ImportCalculationSummaryMessage()
    var
        XBRLSchema: Record "XBRL Schema";
        XBRLTaxonomyLine: Record "XBRL Taxonomy Line";
        XBRLRollupLine: Record "XBRL Rollup Line";
        XML: Text;
        ElementID: array[2] of Text;
    begin
        // [FEATURE] [UT] [XBRL Linkbases] [Calculation]
        // [SCENARIO 387254] Import XBRL Taxonomy Calculation linkbases shows a summary message
        Initialize();

        // [GIVEN] XBRL Taxonomy with two lines
        PrepareTaxonomyWithTwoLines(XBRLSchema, ElementID);
        // [GIVEN] XML file containing single Calculation element
        XML := GenerateCalculationsXMLText(XBRLSchema.schemaLocation, ElementID[1], ElementID[2]);

        // [WHEN] Perform "Import" action from XBRL Linkbases page using "Type" = "Calculation"
        LibraryXBRL.ImportCalculations(XBRLSchema, XML);

        // [THEN] A message is shown: "Applied 1 calculations."
        Assert.ExpectedMessage(StrSubstNo(InsertedCalculationsMsg, 1), LibraryVariableStorage.DequeueText());

        // [THEN] The taxonomy lines have been updated with calculation info
        LibraryXBRL.FindXBRLTaxonomyLine(XBRLTaxonomyLine, XBRLSchema."XBRL Taxonomy Name");
        LibraryXBRL.FindXBRLRollupLine(XBRLRollupLine, XBRLTaxonomyLine);
        XBRLTaxonomyLine.TestField("Element ID", ElementID[1]);
        XBRLTaxonomyLine.TestField("Source Type", XBRLTaxonomyLine."Source Type"::Rollup);

        XBRLTaxonomyLine.Next();
        XBRLTaxonomyLine.TestField("Element ID", ElementID[2]);
        XBRLRollupLine.TestField("From XBRL Taxonomy Line No.", XBRLTaxonomyLine."Line No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ImportReferenceSummaryMessage()
    var
        XBRLSchema: Record "XBRL Schema";
        XBRLTaxonomyLine: Record "XBRL Taxonomy Line";
        XBRLCommentLine: Record "XBRL Comment Line";
        XML: Text;
        RefName: Text;
        RefValue: Text;
    begin
        // [FEATURE] [UT] [XBRL Linkbases] [Reference]
        // [SCENARIO 387254] Import XBRL Taxonomy Reference linkbases shows a summary message
        Initialize();
        RefName := LibraryUtility.GenerateGUID();
        RefValue := LibraryUtility.GenerateGUID();

        // [GIVEN] XBRL Taxonomy with one line
        PrepareTaxonomyWithOneLine(XBRLSchema, XBRLTaxonomyLine);
        // [GIVEN] XML file containing single reference element
        XML := GenerateReferencesXMLText(XBRLSchema.schemaLocation, XBRLTaxonomyLine."Element ID", RefName, RefValue);

        // [WHEN] Perform "Import" action from XBRL Linkbases page using "Type" = "Reference"
        LibraryXBRL.ImportReferences(XBRLSchema, XML);

        // [THEN] A message is shown: "Applied 1 references."
        Assert.ExpectedMessage(StrSubstNo(InsertedReferencesMsg, 1), LibraryVariableStorage.DequeueText());

        // [THEN] A new XBRL Comment record has been created with correct reference value
        LibraryXBRL.FindXBRLCommentLine(XBRLCommentLine, XBRLTaxonomyLine);
        XBRLCommentLine.TestField("Comment Type", XBRLCommentLine."Comment Type"::Reference);
        XBRLCommentLine.TestField(Comment, StrSubstNo('%1: %2', RefName, RefValue));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ImportLabelWithRelativePath()
    var
        XBRLSchema: Record "XBRL Schema";
        XBRLTaxonomyLine: Record "XBRL Taxonomy Line";
        XML: Text;
    begin
        // [FEATURE] [UT] [XBRL Linkbases] [Label]
        // [SCENARIO 387254] Import XBRL Taxonomy Label linkbases with a relative path
        Initialize();

        // [GIVEN] XBRL Taxonomy with one line
        PrepareTaxonomyWithOneLine(XBRLSchema, XBRLTaxonomyLine);
        // [GIVEN] XML file containing single Label element with a relative path to the root schema element: "..\rootSchema#elementID"
        XML :=
          GenerateLabelsXMLText(MakeRelativePath(XBRLSchema.schemaLocation), XBRLTaxonomyLine."Element ID", LibraryUtility.GenerateGUID());

        // [WHEN] Perform "Import" action from XBRL Linkbases page using "Type" = "Label"
        LibraryXBRL.ImportLabels(XBRLSchema, XML);

        // [THEN] A message is shown: "Applied 1 labels."
        Assert.ExpectedMessage(StrSubstNo(InsertedLabelsMsg, 1), LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ImportPresentationWithRelativePath()
    var
        XBRLSchema: Record "XBRL Schema";
        XML: Text;
        ElementID: array[2] of Text;
    begin
        // [FEATURE] [UT] [XBRL Linkbases] [Presenation]
        // [SCENARIO 387254] Import XBRL Taxonomy Presentation linkbases with a relative path
        Initialize();

        // [GIVEN] XBRL Taxonomy with two lines
        PrepareTaxonomyWithTwoLines(XBRLSchema, ElementID);
        // [GIVEN] XML file containing single Presentation element with a relative path to the root schema element: "..\rootSchema#elementID"
        XML := GeneratePresentationsXMLText(XBRLSchema.schemaLocation, ElementID[1], ElementID[2]);

        // [WHEN] Perform "Import" action from XBRL Linkbases page using "Type" = "Presentation"
        LibraryXBRL.ImportPresentations(XBRLSchema, XML);

        // [THEN] A message is shown: "Applied 1 presentation relations."
        Assert.ExpectedMessage(StrSubstNo(InsertedPresentationsMsg, 1), LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ImportCalculationWithRelativePath()
    var
        XBRLSchema: Record "XBRL Schema";
        XML: Text;
        ElementID: array[2] of Text;
    begin
        // [FEATURE] [UT] [XBRL Linkbases] [Calculation]
        // [SCENARIO 387254] Import XBRL Taxonomy Calculation linkbases with a relative path
        Initialize();

        // [GIVEN] XBRL Taxonomy with two lines
        PrepareTaxonomyWithTwoLines(XBRLSchema, ElementID);
        // [GIVEN] XML file containing single Calculation element with a relative path to the root schema element: "..\rootSchema#elementID"
        XML := GenerateCalculationsXMLText(XBRLSchema.schemaLocation, ElementID[1], ElementID[2]);

        // [WHEN] Perform "Import" action from XBRL Linkbases page using "Type" = "Calculation"
        LibraryXBRL.ImportCalculations(XBRLSchema, XML);

        // [THEN] A message is shown: "Applied 1 calculations."
        Assert.ExpectedMessage(StrSubstNo(InsertedCalculationsMsg, 1), LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ImportReferenceWithRelativePath()
    var
        XBRLSchema: Record "XBRL Schema";
        XBRLTaxonomyLine: Record "XBRL Taxonomy Line";
        XML: Text;
    begin
        // [FEATURE] [UT] [XBRL Linkbases] [Reference]
        // [SCENARIO 387254] Import XBRL Taxonomy Reference linkbases with a relative path
        Initialize();

        // [GIVEN] XBRL Taxonomy with one line
        PrepareTaxonomyWithOneLine(XBRLSchema, XBRLTaxonomyLine);
        // [GIVEN] XML file containing single reference element with a relative path to the root schema element: "..\rootSchema#elementID"
        XML := GenerateReferencesXMLText(XBRLSchema.schemaLocation, XBRLTaxonomyLine."Element ID", 'name', 'value');

        // [WHEN] Perform "Import" action from XBRL Linkbases page using "Type" = "Reference"
        LibraryXBRL.ImportReferences(XBRLSchema, XML);

        // [THEN] A message is shown: "Applied 1 references."
        Assert.ExpectedMessage(StrSubstNo(InsertedReferencesMsg, 1), LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
    end;

    local procedure PrepareTaxonomyWithOneLine(var XBRLSchema: Record "XBRL Schema"; var XBRLTaxonomyLine: Record "XBRL Taxonomy Line")
    var
        XBRLTaxonomy: Record "XBRL Taxonomy";
    begin
        LibraryXBRL.CreateXBRLTaxonomyWithDetails(XBRLTaxonomy, LibraryUtility.GenerateGUID(), '', LibraryXBRL.GetXmlnsXbrli21());
        LibraryXBRL.CreateXBRLSchemaWithXSD(XBRLSchema, XBRLTaxonomy, '');
        LibraryXBRL.CreateXBRLTaxonomyLineWithDetails(
          XBRLTaxonomyLine, XBRLTaxonomy.Name, XBRLSchema."Line No.", LibraryUtility.GenerateGUID());
    end;

    local procedure PrepareTaxonomyWithTwoLines(var XBRLSchema: Record "XBRL Schema"; var ElementID: array[2] of Text)
    var
        XBRLTaxonomy: Record "XBRL Taxonomy";
        XBRLTaxonomyLine: Record "XBRL Taxonomy Line";
        i: Integer;
    begin
        for i := 1 to ARRAYLEN(ElementID) do
            ElementID[i] := LibraryUtility.GenerateGUID();

        LibraryXBRL.CreateXBRLTaxonomyWithDetails(XBRLTaxonomy, LibraryUtility.GenerateGUID(), '', LibraryXBRL.GetXmlnsXbrli21());
        LibraryXBRL.CreateXBRLSchemaWithXSD(XBRLSchema, XBRLTaxonomy, '');
        for i := 1 to ARRAYLEN(ElementID) do
            LibraryXBRL.CreateXBRLTaxonomyLineWithDetails(XBRLTaxonomyLine, XBRLTaxonomy.Name, XBRLSchema."Line No.", ElementID[i]);
    end;

    local procedure CreateXBRLTaxonomyWithLine(var XBRLTaxonomyLine: Record "XBRL Taxonomy Line")
    var
        XBRLTaxonomy: Record "XBRL Taxonomy";
    begin
        LibraryXBRL.CreateXBRLTaxonomy(XBRLTaxonomy);
        LibraryXBRL.CreateXBRLTaxonomyLine(XBRLTaxonomyLine, XBRLTaxonomy, 0);
    end;

    local procedure OpenTaxonomyLinesFromTaxonomyCard(var XBRLTaxonomyLines: TestPage "XBRL Taxonomy Lines"; XBRLTaxonomyLine: Record "XBRL Taxonomy Line")
    var
        XBRLTaxonomy: Record "XBRL Taxonomy";
        XBRLTaxonomies: TestPage "XBRL Taxonomies";
    begin
        XBRLTaxonomy.Get(XBRLTaxonomyLine."XBRL Taxonomy Name");

        XBRLTaxonomies.OpenView;
        XBRLTaxonomies.GotoRecord(XBRLTaxonomy);

        XBRLTaxonomyLines.Trap;
        XBRLTaxonomies.Lines.Invoke;
    end;

    local procedure GenerateSingleElementXSDText(ElementID: Text; Name: Text; TargetNamespace: Text; XmlnsXbrli: Text): Text
    begin
        exit(
          StrSubstNo(
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<xsd:schema targetNamespace="%3" xmlns:xbrli="%4" xmlns:xsd="http://www.w3.org/2001/XMLSchema">' +
            '<xsd:element id="%1" name="%2" type="xbrli:monetaryItemType" xbrli:periodType="instant"/>' +
            '</xsd:schema>',
            ElementID, Name, TargetNamespace, XmlnsXbrli));
    end;

    local procedure GenerateLabelsXMLText(SchemaLocation: Text; ID: Text; Label: Text): Text
    begin
        exit(
          StrSubstNo(
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<link:linkbase %1>' +
            '<link:labelLink xlink:role="http://www.xbrl.org/2003/role/link">' +
            '<link:loc xlink:href="%2#%3" xlink:label="loc_1" xlink:type="locator"/>' +
            '<link:labelArc xlink:arcrole="http://www.xbrl.org/2003/arcrole/concept-label"' +
            ' xlink:from="loc_1" xlink:to="res_1" xlink:type="arc"/>' +
            '<link:label id="ifrs-smes_BalancesWithBanks_label" xlink:label="res_1"' +
            ' xlink:role="http://www.xbrl.org/2003/role/label" xlink:type="resource" xml:lang="en">%4</link:label>' +
            '</link:labelLink>' +
            '</link:linkbase>',
            GetCommonLinkBaseAttr(''), SchemaLocation, ID, Label));
    end;

    local procedure GeneratePresentationsXMLText(SchemaLocation: Text; ElementFrom: Text; ElementTo: Text): Text
    begin
        exit(
          StrSubstNo(
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<link:linkbase %1>' +
            '<link:presentationLink>' +
            '<link:loc xlink:href="%2#%3" xlink:label="loc_1" xlink:type="locator"/>' +
            '<link:loc xlink:href="%2#%4" xlink:label="loc_2" xlink:type="locator"/>' +
            '<link:presentationArc order="10.0" xlink:arcrole="http://www.xbrl.org/2003/arcrole/parent-child"' +
            ' xlink:from="loc_1" xlink:to="loc_2" xlink:type="arc"/>' +
            '</link:presentationLink>' +
            '</link:linkbase>',
            GetCommonLinkBaseAttr(''), SchemaLocation, ElementFrom, ElementTo));
    end;

    local procedure GenerateCalculationsXMLText(SchemaLocation: Text; ElementFrom: Text; ElementTo: Text): Text
    begin
        exit(
          StrSubstNo(
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<link:linkbase %1>' +
            '<link:calculationLink>' +
            '<link:loc xlink:href="%2#%3" xlink:label="loc_1" xlink:type="locator"/>' +
            '<link:loc xlink:href="%2#%4" xlink:label="loc_2" xlink:type="locator"/>' +
            '<link:calculationArc order="10.0" weight="1" xlink:arcrole="http://www.xbrl.org/2003/arcrole/summation-item"' +
            ' xlink:from="loc_1" xlink:to="loc_2" xlink:type="arc"/>' +
            '</link:calculationLink>' +
            '</link:linkbase>',
            GetCommonLinkBaseAttr(''), SchemaLocation, ElementFrom, ElementTo));
    end;

    local procedure GenerateReferencesXMLText(SchemaLocation: Text; ElementID: Text; RefName: Text; RefValue: Text): Text
    begin
        exit(
          StrSubstNo(
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<link:linkbase %1>' +
            '<link:referenceLink>' +
            '<link:loc xlink:href="%2#%3" xlink:label="loc_1" xlink:type="locator"/>' +
            '<link:referenceArc xlink:arcrole="http://www.xbrl.org/2003/arcrole/concept-reference"' +
            ' xlink:from="loc_1" xlink:to="res_1" xlink:type="arc"/>' +
            '<link:reference xlink:label="res_1" xlink:role="http://www.xbrl.org/2003/role/disclosureRef" xlink:type="resource">' +
            '<ref:%4>%5</ref:%4>' +
            '</link:reference>' +
            '</link:referenceLink>' +
            '</link:linkbase>',
            GetCommonLinkBaseAttr('xmlns:ref="http://www.xbrl.org/2006/ref"'), SchemaLocation, ElementID, RefName, RefValue));
    end;

    local procedure GetCommonLinkBaseAttr(AdditionalAttr: Text): Text
    begin
        exit(
          StrSubstNo(
            'xmlns:link="http://www.xbrl.org/2003/linkbase" ' +
            'xmlns:xlink="http://www.w3.org/1999/xlink" ' +
            'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' +
            'xsi:schemaLocation="http://www.xbrl.org/2003/xbrl-linkbase-2003-12-31.xsd" %1',
            AdditionalAttr));
    end;

    local procedure MakeRelativePath(Path: Text): Text
    begin
        exit(StrSubstNo('../%1', Path));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure XBRLCommentLinesMPH(var XBRLCommentLines: TestPage "XBRL Comment Lines")
    begin
        XBRLCommentLines.First;
        XBRLCommentLines.Comment.AssertEquals(LibraryVariableStorage.DequeueText);
        XBRLCommentLines.Next;
        XBRLCommentLines.Comment.AssertEquals('');
        Assert.AreEqual(LibraryVariableStorage.DequeueDate, XBRLCommentLines.Date.AsDate, '');
        Assert.IsFalse(XBRLCommentLines.Next, SingleLineExpectedErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure XBRLRollupLinesMPH(var XBRLRollupLines: TestPage "XBRL Rollup Lines")
    begin
        XBRLRollupLines.First;
        Assert.AreEqual(LibraryVariableStorage.DequeueDecimal, XBRLRollupLines.Weight.AsDEcimal, 'Weight');
        XBRLRollupLines.Next;
        Assert.IsFalse(XBRLRollupLines.Next, SingleLineExpectedErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure XBRLGLMapLinesMPH(var XBRLGLMapLines: TestPage "XBRL G/L Map Lines")
    begin
        XBRLGLMapLines.First;
        XBRLGLMapLines."G/L Account Filter".AssertEquals(LibraryVariableStorage.DequeueText);
        XBRLGLMapLines.Next;
        Assert.IsFalse(XBRLGLMapLines.Next, SingleLineExpectedErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure XBRLLineConstantsMPH(var XBRLLineConstants: TestPage "XBRL Line Constants")
    begin
        XBRLLineConstants.First;
        Assert.AreEqual(LibraryVariableStorage.DequeueDecimal, XBRLLineConstants."Constant Amount".AsDEcimal, '');
        XBRLLineConstants.Next;
        Assert.AreEqual(0, XBRLLineConstants."Constant Amount".AsDEcimal, '');
        Assert.AreEqual(LibraryVariableStorage.DequeueDate, XBRLLineConstants."Starting Date".AsDate, '');
        Assert.IsFalse(XBRLLineConstants.Next, SingleLineExpectedErr);
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;
}

