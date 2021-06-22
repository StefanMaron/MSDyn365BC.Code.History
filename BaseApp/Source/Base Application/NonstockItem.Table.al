table 5718 "Nonstock Item"
{
    Caption = 'Nonstock Item';
    DrillDownPageID = "Catalog Item List";
    LookupPageID = "Catalog Item List";

    fields
    {
        field(1; "Entry No."; Code[20])
        {
            Caption = 'Entry No.';
            Editable = true;

            trigger OnValidate()
            begin
                if "Entry No." <> xRec."Entry No." then begin
                    GetInvtSetup;
                    NoSeriesMgt.TestManual(InvtSetup."Nonstock Item Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Manufacturer Code"; Code[10])
        {
            Caption = 'Manufacturer Code';
            TableRelation = Manufacturer.Code;

            trigger OnValidate()
            begin
                if ("Manufacturer Code" <> xRec."Manufacturer Code") and
                   ("Item No." <> '')
                then
                    Error(Text001);
            end;
        }
        field(3; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor."No.";

            trigger OnValidate()
            begin
                if ("Vendor No." <> xRec."Vendor No.") and
                   ("Item No." <> '')
                then
                    Error(Text001);

                if "Vendor No." <> xRec."Vendor No." then
                    if CheckVendorItemNo("Vendor No.", "Vendor Item No.") then
                        Error(Text002, "Vendor No.", "Vendor Item No.");
            end;
        }
        field(4; "Vendor Item No."; Code[50])
        {
            Caption = 'Vendor Item No.';

            trigger OnValidate()
            begin
                if ("Vendor Item No." <> xRec."Vendor Item No.") and
                   ("Item No." <> '')
                then
                    Error(Text001);

                if "Vendor Item No." <> xRec."Vendor Item No." then
                    if CheckVendorItemNo("Vendor No.", "Vendor Item No.") then
                        Error(Text002, "Vendor No.", "Vendor Item No.");
            end;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
            Editable = true;

            trigger OnValidate()
            begin
                if (Description <> xRec.Description) and
                   ("Item No." <> '')
                then
                    Error(Text001);
            end;
        }
        field(6; "Unit of Measure"; Code[10])
        {
            Caption = 'Unit of Measure';
            TableRelation = "Unit of Measure";

            trigger OnValidate()
            begin
                if ("Unit of Measure" <> xRec."Unit of Measure") and
                   ("Item No." <> '')
                then
                    Error(Text001);
            end;
        }
        field(7; "Published Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Published Cost';

            trigger OnValidate()
            begin
                if ("Published Cost" <> xRec."Published Cost") and
                   ("Item No." <> '')
                then
                    Error(Text001);
            end;
        }
        field(8; "Negotiated Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Negotiated Cost';

            trigger OnValidate()
            begin
                if ("Negotiated Cost" <> xRec."Negotiated Cost") and
                   ("Item No." <> '')
                then
                    Error(Text001);
            end;
        }
        field(9; "Unit Price"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Unit Price';

            trigger OnValidate()
            begin
                if ("Unit Price" <> xRec."Unit Price") and
                   ("Item No." <> '')
                then
                    Error(Text001);
            end;
        }
        field(10; "Gross Weight"; Decimal)
        {
            Caption = 'Gross Weight';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if ("Gross Weight" <> xRec."Gross Weight") and
                   ("Item No." <> '')
                then
                    Error(Text001);
            end;
        }
        field(11; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if ("Net Weight" <> xRec."Net Weight") and
                   ("Item No." <> '')
                then
                    Error(Text001);
            end;
        }
        field(12; "Item Template Code"; Code[10])
        {
            Caption = 'Item Template Code';
            TableRelation = "Config. Template Header".Code WHERE("Table ID" = CONST(27));

            trigger OnValidate()
            begin
                if ("Item Template Code" <> xRec."Item Template Code") and
                   ("Item No." <> '')
                then
                    Error(Text001);
            end;
        }
        field(13; "Product Group Code"; Code[10])
        {
            Caption = 'Product Group Code';
            ObsoleteReason = 'Product Groups became first level children of Item Categories.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(14; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(15; "Bar Code"; Code[20])
        {
            Caption = 'Bar Code';

            trigger OnValidate()
            begin
                if ("Bar Code" <> xRec."Bar Code") and
                   ("Item No." <> '')
                then
                    Error(Text001);
            end;
        }
        field(16; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            Editable = false;
            TableRelation = Item."No.";

            trigger OnValidate()
            begin
                if ("Item No." <> xRec."Item No.") and
                   ("Item No." <> '')
                then
                    Error(Text001);
            end;
        }
        field(53; Comment; Boolean)
        {
            CalcFormula = Exist ("Comment Line" WHERE("Table Name" = CONST("Nonstock Item"),
                                                      "No." = FIELD("Entry No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(97; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Vendor Item No.", "Manufacturer Code")
        {
        }
        key(Key3; "Item No.")
        {
        }
        key(Key4; "Vendor No.", "Vendor Item No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        NonStockItem.LockTable();
        if "Entry No." = '' then begin
            GetInvtSetup;
            InvtSetup.TestField("Nonstock Item Nos.");
            NoSeriesMgt.InitSeries(InvtSetup."Nonstock Item Nos.", xRec."No. Series", 0D, "Entry No.", "No. Series");
        end;
    end;

    trigger OnModify()
    var
        Item: Record Item;
    begin
        "Last Date Modified" := Today;
        MfrLength := StrLen("Manufacturer Code");
        VenLength := StrLen("Vendor Item No.");

        NonStockItemSetup.Get();
        case NonStockItemSetup."No. Format" of
            NonStockItemSetup."No. Format"::"Entry No.":
                ItemNo := "Entry No.";
            NonStockItemSetup."No. Format"::"Vendor Item No.":
                ItemNo := CopyStr("Vendor Item No.", 1, MaxStrLen("Item No."));
            NonStockItemSetup."No. Format"::"Mfr. + Vendor Item No.":
                if NonStockItemSetup."No. Format Separator" = '' then begin
                    if MfrLength + VenLength <= 20 then
                        ItemNo := CopyStr(InsStr("Manufacturer Code", "Vendor Item No.", 6), 1, MaxStrLen("Item No."))
                    else
                        ItemNo := InsStr("Manufacturer Code", "Entry No.", 6);
                end else begin
                    TempItemNo :=
                      InsStr("Manufacturer Code", NonStockItemSetup."No. Format Separator", 6);
                    if MfrLength + VenLength < 20 then
                        ItemNo := CopyStr(InsStr(TempItemNo, "Vendor Item No.", 7), 1, MaxStrLen("Item No."))
                    else
                        ItemNo := InsStr(TempItemNo, "Entry No.", 7);
                end;
            NonStockItemSetup."No. Format"::"Vendor Item No. + Mfr.":
                if NonStockItemSetup."No. Format Separator" = '' then begin
                    if VenLength + MfrLength <= 20 then
                        ItemNo := CopyStr(InsStr("Vendor Item No.", "Manufacturer Code", 11), 1, MaxStrLen("Item No."))
                    else
                        ItemNo := InsStr("Entry No.", "Manufacturer Code", 11);
                end else begin
                    TempItemNo :=
                      CopyStr(InsStr("Vendor Item No.", NonStockItemSetup."No. Format Separator", 10), 1, MaxStrLen("Item No."));
                    if VenLength + MfrLength < 20 then
                        ItemNo := InsStr(TempItemNo, "Manufacturer Code", 11);
                end;
        end;
        Item.SetRange("No.", ItemNo);
        if not Item.IsEmpty then
            Error(Text001);
    end;

    var
        Text001: Label 'Modification not allowed, item record already exists.';
        NonStockItem: Record "Nonstock Item";
        NonStockItemSetup: Record "Nonstock Item Setup";
        InvtSetup: Record "Inventory Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        ItemNo: Code[20];
        TempItemNo: Code[20];
        MfrLength: Integer;
        VenLength: Integer;
        Text002: Label 'No.=<%1> and Vendor Item No.=<%2> already exists.';
        HasInvtSetup: Boolean;

    procedure AssistEdit(): Boolean
    begin
        GetInvtSetup;
        InvtSetup.TestField("Nonstock Item Nos.");
        if NoSeriesMgt.SelectSeries(InvtSetup."Nonstock Item Nos.", xRec."No. Series", "No. Series") then begin
            NoSeriesMgt.SetSeries("Entry No.");
            exit(true);
        end;
    end;

    local procedure CheckVendorItemNo(VendorNo: Code[20]; VendorItemNo: Code[50]): Boolean
    begin
        NonStockItem.Reset();
        NonStockItem.SetCurrentKey("Vendor No.", "Vendor Item No.");
        NonStockItem.SetRange("Vendor No.", VendorNo);
        NonStockItem.SetRange("Vendor Item No.", VendorItemNo);
        exit(NonStockItem.FindFirst);
    end;

    local procedure GetInvtSetup()
    begin
        if not HasInvtSetup then begin
            InvtSetup.Get();
            HasInvtSetup := true;
        end;
    end;
}

