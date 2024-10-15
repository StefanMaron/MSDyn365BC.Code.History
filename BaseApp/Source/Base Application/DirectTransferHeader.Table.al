table 12458 "Direct Transfer Header"
{
    Caption = 'Direct Transfer Header';
    DataCaptionFields = "No.";
    LookupPageID = "Posted Direct Transfers";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));
        }
        field(3; "Transfer-from Name"; Text[100])
        {
            Caption = 'Transfer-from Name';
        }
        field(4; "Transfer-from Name 2"; Text[50])
        {
            Caption = 'Transfer-from Name 2';
        }
        field(5; "Transfer-from Address"; Text[100])
        {
            Caption = 'Transfer-from Address';
        }
        field(6; "Transfer-from Address 2"; Text[50])
        {
            Caption = 'Transfer-from Address 2';
        }
        field(7; "Transfer-from Post Code"; Code[20])
        {
            Caption = 'Transfer-from Post Code';
            TableRelation = "Post Code";

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                  "Transfer-from City", "Transfer-from Post Code",
                  "Transfer-from County", "Trsf.-from Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(8; "Transfer-from City"; Text[30])
        {
            Caption = 'Transfer-from City';

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Transfer-from City", "Transfer-from Post Code",
                  "Transfer-from County", "Trsf.-from Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(9; "Transfer-from County"; Text[30])
        {
            Caption = 'Transfer-from County';
        }
        field(10; "Trsf.-from Country/Region Code"; Code[10])
        {
            Caption = 'Trsf.-from Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(11; "Transfer-to Code"; Code[10])
        {
            Caption = 'Transfer-to Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));
        }
        field(12; "Transfer-to Name"; Text[100])
        {
            Caption = 'Transfer-to Name';
        }
        field(13; "Transfer-to Name 2"; Text[50])
        {
            Caption = 'Transfer-to Name 2';
        }
        field(14; "Transfer-to Address"; Text[100])
        {
            Caption = 'Transfer-to Address';
        }
        field(15; "Transfer-to Address 2"; Text[50])
        {
            Caption = 'Transfer-to Address 2';
        }
        field(16; "Transfer-to Post Code"; Code[20])
        {
            Caption = 'Transfer-to Post Code';
            TableRelation = "Post Code";

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                  "Transfer-to City", "Transfer-to Post Code", "Transfer-to County",
                  "Trsf.-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(17; "Transfer-to City"; Text[30])
        {
            Caption = 'Transfer-to City';

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Transfer-to City", "Transfer-to Post Code", "Transfer-to County",
                  "Trsf.-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(18; "Transfer-to County"; Text[30])
        {
            Caption = 'Transfer-to County';
        }
        field(19; "Trsf.-to Country/Region Code"; Code[10])
        {
            Caption = 'Trsf.-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(20; "Transfer Order Date"; Date)
        {
            Caption = 'Transfer Order Date';
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(22; Comment; Boolean)
        {
            CalcFormula = Exist ("Inventory Comment Line" WHERE("Document Type" = CONST("Posted Transfer Receipt"),
                                                                "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(23; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(24; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(25; "Transfer Order No."; Code[20])
        {
            Caption = 'Transfer Order No.';
            TableRelation = "Transfer Header";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(26; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(30; "Transfer-from Contact"; Text[100])
        {
            Caption = 'Transfer-from Contact';
        }
        field(31; "Transfer-to Contact"; Text[100])
        {
            Caption = 'Transfer-to Contact';
        }
        field(32; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Transfer-from Code", "Transfer-to Code", "Posting Date", "Transfer Order Date")
        {
        }
    }

    trigger OnDelete()
    var
        InvtCommentLine: Record "Inventory Comment Line";
        DirectTransLine: Record "Direct Transfer Line";
        PostedDocSignature: Record "Posted Document Signature";
        MoveEntries: Codeunit MoveEntries;
    begin
        DirectTransLine.SetRange("Document No.", "No.");
        DirectTransLine.DeleteAll();

        InvtCommentLine.SetRange("Document Type", InvtCommentLine."Document Type"::"Posted Direct Transfer");
        InvtCommentLine.SetRange("No.", "No.");
        InvtCommentLine.DeleteAll();

        PostedDocSignature.SetRange("Table ID", DATABASE::"Direct Transfer Header");
        PostedDocSignature.SetRange("Document No.", "No.");
        PostedDocSignature.DeleteAll();

        ItemTrackingMgt.DeleteItemEntryRelation(
          DATABASE::"Direct Transfer Line", 0, "No.", '', 0, 0, true);

        MoveEntries.MoveDocRelatedEntries(DATABASE::"Direct Transfer Header", "No.");
    end;

    var
        PostCode: Record "Post Code";
        DimMgt: Codeunit DimensionManagement;
        ItemTrackingMgt: Codeunit "Item Tracking Management";

    [Scope('OnPrem')]
    procedure Navigate()
    var
        NavigatePage: Page Navigate;
    begin
        NavigatePage.SetDoc("Posting Date", "No.");
        NavigatePage.Run;
    end;

    [Scope('OnPrem')]
    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        ReportSelection: Record "Report Selections";
        DirectTransHeader: Record "Direct Transfer Header";
        ReportSelectionTmp: Record "Report Selections" temporary;
    begin
        with DirectTransHeader do begin
            Copy(Rec);
            ReportSelection.SetRange(Usage, ReportSelection.Usage::DT);
            ReportSelection.SetFilter("Report ID", '<>0');
            ReportSelection.Find('-');
            case ReportSelection.Count of
                1:
                    REPORT.RunModal(ReportSelection."Report ID", ShowRequestForm, false, DirectTransHeader);
                else begin
                        ReportSelectionTmp.Reset();
                        ReportSelectionTmp.DeleteAll();
                        repeat
                            ReportSelectionTmp.Init();
                            ReportSelectionTmp := ReportSelection;
                            ReportSelectionTmp.Insert();
                        until ReportSelection.Next = 0;
                        Commit();
                        ReportSelectionTmp.Find('-');
                        if PAGE.RunModal(PAGE::"Report Selection - Print", ReportSelectionTmp) = ACTION::LookupOK then begin
                            ReportSelectionTmp.SetRange(Default, true);
                            if ReportSelectionTmp.Find('-') then
                                repeat
                                    REPORT.RunModal(ReportSelectionTmp."Report ID", ShowRequestForm, false, DirectTransHeader)
                                until ReportSelectionTmp.Next = 0;
                            ReportSelectionTmp.DeleteAll();
                        end;
                    end;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption, "No."));
    end;
}

