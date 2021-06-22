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
}

