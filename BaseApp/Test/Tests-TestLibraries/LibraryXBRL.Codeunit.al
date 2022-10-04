#if not CLEAN20
codeunit 131333 "Library - XBRL"
{
    ObsoleteReason = 'XBRL feature will be discontinued';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Scope('OnPrem')]
    procedure CreateXBRLTaxonomy(var XBRLTaxonomy: Record "XBRL Taxonomy")
    begin
        with XBRLTaxonomy do begin
            Init();

            Name := LibraryUtility.GenerateGUID();
            Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Description)), 1, MaxStrLen(Description));

            Insert();
        end;
    end;

    procedure CreateXBRLTaxonomyWithDetails(var XBRLTaxonomy: Record "XBRL Taxonomy"; SchemaLocation: Text; TargetNamespace: Text; XmlnsXbrli: Text)
    begin
        XBRLTaxonomy.Init();
        XBRLTaxonomy.Name := LibraryUtility.GenerateGUID();
        XBRLTaxonomy.Description := LibraryUtility.GenerateGUID();
        XBRLTaxonomy.schemaLocation := CopyStr(SchemaLocation, 1, MaxStrLen(XBRLTaxonomy.schemaLocation));
        XBRLTaxonomy.targetNamespace := CopyStr(TargetNamespace, 1, MaxStrLen(XBRLTaxonomy.targetNamespace));
        XBRLTaxonomy."xmlns:xbrli" := CopyStr(XmlnsXbrli, 1, MaxStrLen(XBRLTaxonomy."xmlns:xbrli"));
        XBRLTaxonomy.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateXBRLTaxonomyLine(var XBRLTaxonomyLine: Record "XBRL Taxonomy Line"; XBRLTaxonomy: Record "XBRL Taxonomy"; LineLevel: Integer)
    begin
        with XBRLTaxonomyLine do begin
            Init();

            "XBRL Taxonomy Name" := XBRLTaxonomy.Name;
            "Line No." := LibraryUtility.GetNewRecNo(XBRLTaxonomyLine, FieldNo("Line No."));
            Name := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Name)), 1, MaxStrLen(Name));
            Level := LineLevel;

            Insert();
        end;
    end;

    procedure CreateXBRLTaxonomyLineWithDetails(var XBRLTaxonomyLine: Record "XBRL Taxonomy Line"; XBRLTaxonomyName: Code[20]; XBRLSchemaLineNo: Integer; ElementID: Text)
    begin
        XBRLTaxonomyLine.Init();
        XBRLTaxonomyLine."XBRL Taxonomy Name" := XBRLTaxonomyName;
        XBRLTaxonomyLine."Line No." := LibraryUtility.GetNewRecNo(XBRLTaxonomyLine, XBRLTaxonomyLine.FieldNo("Line No."));
        XBRLTaxonomyLine."XBRL Schema Line No." := XBRLSchemaLineNo;
        XBRLTaxonomyLine."Element ID" := CopyStr(ElementID, 1, MaxStrLen(XBRLTaxonomyLine."Element ID"));
        XBRLTaxonomyLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateXBRLCommentLine(var XBRLCommentLine: Record "XBRL Comment Line"; XBRLTaxonomyLine: Record "XBRL Taxonomy Line"; CommentType: Option; CommentLineComment: Text[80]; CommentLineDate: Date)
    begin
        with XBRLCommentLine do begin
            Init();

            "XBRL Taxonomy Name" := XBRLTaxonomyLine."XBRL Taxonomy Name";
            "XBRL Taxonomy Line No." := XBRLTaxonomyLine."Line No.";
            "Line No." := LibraryUtility.GetNewRecNo(XBRLCommentLine, FieldNo("Line No."));
            "Comment Type" := CommentType;

            if CommentLineDate <> 0D then
                Date := CommentLineDate
            else
                Date := LibraryRandom.RandDate(10);

            if CommentLineComment <> '' then
                Comment := CommentLineComment
            else
                Comment := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Comment)), 1, MaxStrLen(Comment));

            Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateXBRLRollupLine(var XBRLRollupLine: Record "XBRL Rollup Line"; XBRLTaxonomyLine: Record "XBRL Taxonomy Line"; XBRLTaxonomyLineFrom: Record "XBRL Taxonomy Line")
    begin
        with XBRLRollupLine do begin
            Init();

            "XBRL Taxonomy Name" := XBRLTaxonomyLine."XBRL Taxonomy Name";
            "XBRL Taxonomy Line No." := XBRLTaxonomyLine."Line No.";
            "From XBRL Taxonomy Line No." := XBRLTaxonomyLineFrom."Line No.";
            Weight := LibraryRandom.RandDecInRange(100, 200, 2);

            Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateXBRLGLMapLine(var XBRLGLMapLine: Record "XBRL G/L Map Line"; XBRLTaxonomyLine: Record "XBRL Taxonomy Line")
    begin
        with XBRLGLMapLine do begin
            Init();

            "XBRL Taxonomy Name" := XBRLTaxonomyLine."XBRL Taxonomy Name";
            "XBRL Taxonomy Line No." := XBRLTaxonomyLine."Line No.";
            "Line No." := LibraryUtility.GetNewRecNo(XBRLGLMapLine, FieldNo("Line No."));

            Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateXBRLLineConstant(var XBRLLineConstant: Record "XBRL Line Constant"; XBRLTaxonomyLine: Record "XBRL Taxonomy Line")
    begin
        with XBRLLineConstant do begin
            Init();

            "XBRL Taxonomy Name" := XBRLTaxonomyLine."XBRL Taxonomy Name";
            "XBRL Taxonomy Line No." := XBRLTaxonomyLine."Line No.";
            "Line No." := LibraryUtility.GetNewRecNo(XBRLLineConstant, FieldNo("Line No."));

            "Starting Date" := LibraryRandom.RandDate(10);
            "Constant Amount" := LibraryRandom.RandDecInRange(100, 200, 2);

            Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateXBRLTaxonomyLabel(var XBRLTaxonomyLabel: Record "XBRL Taxonomy Label"; XBRLTaxonomyLine: Record "XBRL Taxonomy Line")
    begin
        with XBRLTaxonomyLabel do begin
            Init();

            "XBRL Taxonomy Name" := XBRLTaxonomyLine."XBRL Taxonomy Name";
            "XBRL Taxonomy Line No." := XBRLTaxonomyLine."Line No.";
            "XML Language Identifier" :=
              CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen("XML Language Identifier")), 1, MaxStrLen("XML Language Identifier"));

            Insert();
        end;
    end;

    procedure CreateXBRLSchemaWithXSD(var XBRLSchema: Record "XBRL Schema"; XBRLTaxonomy: Record "XBRL Taxonomy"; XSD: Text)
    var
        OutStream: OutStream;
    begin
        XBRLSchema.Init();
        XBRLSchema."XBRL Taxonomy Name" := XBRLTaxonomy.Name;
        XBRLSchema."Line No." := LibraryUtility.GetNewRecNo(XBRLSchema, XBRLSchema.FieldNo("Line No."));
        XBRLSchema.schemaLocation := XBRLTaxonomy.schemaLocation;
        XBRLSchema.targetNamespace := XBRLTaxonomy.targetNamespace;
        XBRLSchema."xmlns:xbrli" := XBRLTaxonomy."xmlns:xbrli";
        XBRLSchema.XSD.CreateOutStream(OutStream);
        OutStream.Write(XSD);
        XBRLSchema.Insert();
    end;

    procedure CreateXBRLLinkBase(var XBRLLinkbase: Record "XBRL Linkbase"; XBRLTaxonomyName: Code[20]; XBRLSchemaLineNo: Integer; Type: Option; XML: Text)
    var
        OutStream: OutStream;
    begin
        XBRLLinkbase.Init();
        XBRLLinkbase."XBRL Taxonomy Name" := XBRLTaxonomyName;
        XBRLLinkbase."XBRL Schema Line No." := XBRLSchemaLineNo;
        XBRLLinkbase."Line No." := LibraryUtility.GetNewRecNo(XBRLLinkbase, XBRLLinkbase.FieldNo("Line No."));
        XBRLLinkbase.Type := Type;
        XBRLLinkbase.XML.CreateOutStream(OutStream);
        OutStream.Write(XML);
        XBRLLinkbase.Insert();
    end;

    procedure ImportSchema(var XBRLSchema: Record "XBRL Schema"; XBRLTaxonomy: Record "XBRL Taxonomy"; XSD: Text)
    begin
        CreateXBRLSchemaWithXSD(XBRLSchema, XBRLTaxonomy, XSD);
        Codeunit.Run(Codeunit::"XBRL Import Taxonomy Spec. 2", XBRLSchema);
    end;

    procedure ImportLabels(XBRLSchema: Record "XBRL Schema"; XML: Text)
    var
        XBRLLinkbase: Record "XBRL Linkbase";
        XBRLImportTaxonomySpec2: Codeunit "XBRL Import Taxonomy Spec. 2";
    begin
        CreateXBRLLinkBase(XBRLLinkbase, XBRLSchema."XBRL Taxonomy Name", XBRLSchema."Line No.", XBRLLinkbase.Type::Label, XML);
        XBRLImportTaxonomySpec2.ImportLabels(XBRLLinkbase);
    end;

    procedure ImportPresentations(XBRLSchema: Record "XBRL Schema"; XML: Text)
    var
        XBRLLinkbase: Record "XBRL Linkbase";
        XBRLImportTaxonomySpec2: Codeunit "XBRL Import Taxonomy Spec. 2";
    begin
        CreateXBRLLinkBase(XBRLLinkbase, XBRLSchema."XBRL Taxonomy Name", XBRLSchema."Line No.", XBRLLinkbase.Type::Presentation, XML);
        XBRLImportTaxonomySpec2.ImportPresentation(XBRLLinkbase);
    end;

    procedure ImportCalculations(XBRLSchema: Record "XBRL Schema"; XML: Text)
    var
        XBRLLinkbase: Record "XBRL Linkbase";
        XBRLImportTaxonomySpec2: Codeunit "XBRL Import Taxonomy Spec. 2";
    begin
        CreateXBRLLinkBase(XBRLLinkbase, XBRLSchema."XBRL Taxonomy Name", XBRLSchema."Line No.", XBRLLinkbase.Type::Calculation, XML);
        XBRLImportTaxonomySpec2.ImportCalculation(XBRLLinkbase);
    end;

    procedure ImportReferences(XBRLSchema: Record "XBRL Schema"; XML: Text)
    var
        XBRLLinkbase: Record "XBRL Linkbase";
        XBRLImportTaxonomySpec2: Codeunit "XBRL Import Taxonomy Spec. 2";
    begin
        CreateXBRLLinkBase(XBRLLinkbase, XBRLSchema."XBRL Taxonomy Name", XBRLSchema."Line No.", XBRLLinkbase.Type::Reference, XML);
        XBRLImportTaxonomySpec2.ImportReference(XBRLLinkbase);
    end;

    procedure FindXBRLTaxonomyLine(var XBRLTaxonomyLine: Record "XBRL Taxonomy Line"; XBRLTaxonomyName: Code[20])
    begin
        XBRLTaxonomyLine.SetRange("XBRL Taxonomy Name", XBRLTaxonomyName);
        XBRLTaxonomyLine.FindFirst();
    end;

    procedure FindXBRLTaxonomyLabel(var XBRLTaxonomyLabel: Record "XBRL Taxonomy Label"; XBRLTaxonomyLine: Record "XBRL Taxonomy Line")
    begin
        XBRLTaxonomyLabel.SetRange("XBRL Taxonomy Name", XBRLTaxonomyLine."XBRL Taxonomy Name");
        XBRLTaxonomyLabel.SetRange("XBRL Taxonomy Line No.", XBRLTaxonomyLine."Line No.");
        XBRLTaxonomyLabel.FindFirst();
    end;

    procedure FindXBRLRollupLine(var XBRLRollupLine: Record "XBRL Rollup Line"; XBRLTaxonomyLine: Record "XBRL Taxonomy Line")
    begin
        XBRLRollupLine.SetRange("XBRL Taxonomy Name", XBRLTaxonomyLine."XBRL Taxonomy Name");
        XBRLRollupLine.SetRange("XBRL Taxonomy Line No.", XBRLTaxonomyLine."Line No.");
        XBRLRollupLine.FindFirst();
    end;

    procedure FindXBRLCommentLine(var XBRLCommentLine: Record "XBRL Comment Line"; XBRLTaxonomyLine: Record "XBRL Taxonomy Line")
    begin
        XBRLCommentLine.SetRange("XBRL Taxonomy Name", XBRLTaxonomyLine."XBRL Taxonomy Name");
        XBRLCommentLine.SetRange("XBRL Taxonomy Line No.", XBRLTaxonomyLine."Line No.");
        XBRLCommentLine.FindFirst();
    end;

    procedure GetXmlnsXbrli21(): Text
    begin
        exit('http://www.xbrl.org/2003/instance');
    end;
}

#endif