table 394 "XBRL Taxonomy"
{
    Caption = 'XBRL Taxonomy';
#if not CLEAN20
    LookupPageID = "XBRL Taxonomies";
#endif
    ObsoleteReason = 'XBRL feature will be discontinued';
#if not CLEAN20
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
#endif
    ReplicateData = false;

    fields
    {
        field(1; Name; Code[20])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "xmlns:xbrli"; Text[250])
        {
            Caption = 'xmlns:xbrli';
        }
        field(4; targetNamespace; Text[250])
        {
            Caption = 'targetNamespace';
        }
        field(5; schemaLocation; Text[250])
        {
            Caption = 'schemaLocation';
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        with XBRLTaxonomyLine do begin
            SetRange("XBRL Taxonomy Name", Rec.Name);
            DeleteAll();
        end;
        with XBRLCommentLine do begin
            SetRange("XBRL Taxonomy Name", Rec.Name);
            DeleteAll();
        end;
        with XBRLGLMap do begin
            SetRange("XBRL Taxonomy Name", Rec.Name);
            DeleteAll();
        end;
        with XBRLRollupLine do begin
            SetRange("XBRL Taxonomy Name", Rec.Name);
            DeleteAll();
        end;
        with XBRLSchema do begin
            SetRange("XBRL Taxonomy Name", Rec.Name);
            DeleteAll();
        end;
        with XBRLLinkbase do begin
            SetRange("XBRL Taxonomy Name", Rec.Name);
            DeleteAll();
        end;
        with XBRLTaxonomyLabel do begin
            SetRange("XBRL Taxonomy Name", Rec.Name);
            DeleteAll();
        end;
    end;

    var
        XBRLTaxonomyLine: Record "XBRL Taxonomy Line";
        XBRLCommentLine: Record "XBRL Comment Line";
        XBRLGLMap: Record "XBRL G/L Map Line";
        XBRLRollupLine: Record "XBRL Rollup Line";
        XBRLSchema: Record "XBRL Schema";
        XBRLLinkbase: Record "XBRL Linkbase";
        XBRLTaxonomyLabel: Record "XBRL Taxonomy Label";
}

