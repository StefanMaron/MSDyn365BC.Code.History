table 12454 "Item Shipment Header"
{
    Caption = 'Item Shipment Header';
    DataCaptionFields = "No.", "Posting Description";
    LookupPageID = "Posted Item Shipments";

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
        field(11; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(12; Comment; Boolean)
        {
            CalcFormula = Exist ("Inventory Comment Line" WHERE("Document Type" = CONST("Posted Item Shipment"),
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
        field(24; "Shipment No."; Code[20])
        {
            Caption = 'Shipment No.';
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
        ItemShptLine: Record "Item Shipment Line";
        InvtCommentLine: Record "Inventory Comment Line";
    begin
        ItemShptLine.SetRange("Document No.", "No.");
        if ItemShptLine.Find('-') then
            repeat
                ItemShptLine.Delete;
            until ItemShptLine.Next = 0;

        InvtCommentLine.SetRange("Document Type", InvtCommentLine."Document Type"::"Posted Item Shipment");
        InvtCommentLine.SetRange("No.", "No.");
        InvtCommentLine.DeleteAll;

        ItemTrackingMgt.DeleteItemEntryRelation(
          DATABASE::"Item Shipment Line", 0, "No.", '', 0, 0, true);
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
        ReportSelection: Record "Report Selections";
        ItemShptHeader: Record "Item Shipment Header";
        RepSelectionTmp: Record "Report Selections" temporary;
    begin
        with ItemShptHeader do begin
            Copy(Rec);
            FindFirst;
            ReportSelection.SetRange(Usage, ReportSelection.Usage::IS);
            ReportSelection.SetFilter("Report ID", '<>0');
            ReportSelection.Find('-');
            case ReportSelection.Count of
                1:
                    REPORT.RunModal(ReportSelection."Report ID", ShowRequestForm, false, ItemShptHeader);
                else begin
                        RepSelectionTmp.Reset;
                        RepSelectionTmp.DeleteAll;
                        repeat
                            RepSelectionTmp.Init;
                            RepSelectionTmp := ReportSelection;
                            RepSelectionTmp.Insert;
                        until ReportSelection.Next = 0;
                        Commit;
                        RepSelectionTmp.Find('-');
                        if PAGE.RunModal(PAGE::"Report Selection - Print", RepSelectionTmp) = ACTION::LookupOK then begin
                            RepSelectionTmp.SetRange(Default, true);
                            if RepSelectionTmp.Find('-') then
                                repeat
                                    REPORT.RunModal(RepSelectionTmp."Report ID", ShowRequestForm, false, ItemShptHeader);
                                until RepSelectionTmp.Next = 0;
                            RepSelectionTmp.DeleteAll;
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

