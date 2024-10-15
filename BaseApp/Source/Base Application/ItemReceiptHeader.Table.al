table 12451 "Item Receipt Header"
{
    Caption = 'Item Receipt Header';
    DataCaptionFields = "No.", "Posting Description";
    LookupPageID = "Posted Item Receipts";

    fields
    {
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(5; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(6; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location.Code WHERE("Use As In-Transit" = CONST(false));
        }
        field(8; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(9; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(10; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(11; "Purchaser Code"; Code[20])
        {
            Caption = 'Purchaser Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(12; Comment; Boolean)
        {
            CalcFormula = Exist ("Inventory Comment Line" WHERE("Document Type" = CONST("Posted Item Receipt"),
                                                                "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(15; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(16; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(20; "Posting No."; Code[10])
        {
            Caption = 'Posting No.';
        }
        field(23; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(24; "Receipt No."; Code[20])
        {
            Caption = 'Receipt No.';
        }
        field(27; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
        }
        field(30; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions;
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
    }

    trigger OnDelete()
    var
        ItemRcptLine: Record "Item Receipt Line";
        InvtCommentLine: Record "Inventory Comment Line";
    begin
        ItemRcptLine.SetRange("Document No.", "No.");
        if ItemRcptLine.Find('-') then
            repeat
                ItemRcptLine.Delete;
            until ItemRcptLine.Next = 0;

        InvtCommentLine.SetRange("Document Type", InvtCommentLine."Document Type"::"Posted Item Receipt");
        InvtCommentLine.SetRange("No.", "No.");
        InvtCommentLine.DeleteAll;

        ItemTrackingMgt.DeleteItemEntryRelation(
          DATABASE::"Item Receipt Line", 0, "No.", '', 0, 0, true);
    end;

    var
        DimMgt: Codeunit DimensionManagement;
        ItemTrackingMgt: Codeunit "Item Tracking Management";

    [Scope('OnPrem')]
    procedure Navigate()
    var
        NavigateForm: Page Navigate;
    begin
        NavigateForm.SetDoc("Posting Date", "No.");
        NavigateForm.Run;
    end;

    [Scope('OnPrem')]
    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        DocumentPrint: Codeunit "Document-Print";
    begin
        DocumentPrint.PrintItemReceipt(Rec, ShowRequestForm);
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption, "No."));
    end;
}

