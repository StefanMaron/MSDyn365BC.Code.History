codeunit 131333 "Library - XBRL"
{

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
            Init;

            Name := LibraryUtility.GenerateRandomCode20(FieldNo(Name), DATABASE::"XBRL Taxonomy");
            Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Description)), 1, MaxStrLen(Description));

            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateXBRLTaxonomyLine(var XBRLTaxonomyLine: Record "XBRL Taxonomy Line"; XBRLTaxonomy: Record "XBRL Taxonomy"; LineLevel: Integer)
    begin
        with XBRLTaxonomyLine do begin
            Init;

            "XBRL Taxonomy Name" := XBRLTaxonomy.Name;
            "Line No." := LibraryUtility.GetNewRecNo(XBRLTaxonomyLine, FieldNo("Line No."));
            Name := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Name)), 1, MaxStrLen(Name));
            Level := LineLevel;

            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateXBRLCommentLine(var XBRLCommentLine: Record "XBRL Comment Line"; XBRLTaxonomyLine: Record "XBRL Taxonomy Line"; CommentType: Option; CommentLineComment: Text[80]; CommentLineDate: Date)
    begin
        with XBRLCommentLine do begin
            Init;

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

            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateXBRLRollupLine(var XBRLRollupLine: Record "XBRL Rollup Line"; XBRLTaxonomyLine: Record "XBRL Taxonomy Line"; XBRLTaxonomyLineFrom: Record "XBRL Taxonomy Line")
    begin
        with XBRLRollupLine do begin
            Init;

            "XBRL Taxonomy Name" := XBRLTaxonomyLine."XBRL Taxonomy Name";
            "XBRL Taxonomy Line No." := XBRLTaxonomyLine."Line No.";
            "From XBRL Taxonomy Line No." := XBRLTaxonomyLineFrom."Line No.";
            Weight := LibraryRandom.RandDecInRange(100, 200, 2);

            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateXBRLGLMapLine(var XBRLGLMapLine: Record "XBRL G/L Map Line"; XBRLTaxonomyLine: Record "XBRL Taxonomy Line")
    begin
        with XBRLGLMapLine do begin
            Init;

            "XBRL Taxonomy Name" := XBRLTaxonomyLine."XBRL Taxonomy Name";
            "XBRL Taxonomy Line No." := XBRLTaxonomyLine."Line No.";
            "Line No." := LibraryUtility.GetNewRecNo(XBRLGLMapLine, FieldNo("Line No."));

            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateXBRLLineConstant(var XBRLLineConstant: Record "XBRL Line Constant"; XBRLTaxonomyLine: Record "XBRL Taxonomy Line")
    begin
        with XBRLLineConstant do begin
            Init;

            "XBRL Taxonomy Name" := XBRLTaxonomyLine."XBRL Taxonomy Name";
            "XBRL Taxonomy Line No." := XBRLTaxonomyLine."Line No.";
            "Line No." := LibraryUtility.GetNewRecNo(XBRLLineConstant, FieldNo("Line No."));

            "Starting Date" := LibraryRandom.RandDate(10);
            "Constant Amount" := LibraryRandom.RandDecInRange(100, 200, 2);

            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateXBRLTaxonomyLabel(var XBRLTaxonomyLabel: Record "XBRL Taxonomy Label"; XBRLTaxonomyLine: Record "XBRL Taxonomy Line")
    begin
        with XBRLTaxonomyLabel do begin
            Init;

            "XBRL Taxonomy Name" := XBRLTaxonomyLine."XBRL Taxonomy Name";
            "XBRL Taxonomy Line No." := XBRLTaxonomyLine."Line No.";
            "XML Language Identifier" :=
              CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen("XML Language Identifier")), 1, MaxStrLen("XML Language Identifier"));

            Insert;
        end;
    end;
}

