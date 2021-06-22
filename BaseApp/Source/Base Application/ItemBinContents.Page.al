page 7379 "Item Bin Contents"
{
    Caption = 'Item Bin Contents';
    DataCaptionExpression = GetCaption;
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Bin Content";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the item that will be stored in the bin.';
                    Visible = false;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location code of the bin.';
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin code.';
                }
                field("Fixed"; Fixed)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that the item (bin content) has been associated with this bin, and that the bin should normally contain the item.';
                }
                field(Default; Default)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if the bin is the default bin for the associated item.';
                }
                field(Dedicated; Dedicated)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if the bin is used as a dedicated bin, which means that its bin content is available only to certain resources.';
                }
                field(CalcQtyUOM; CalcQtyUOM)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of an item in each bin and for each item that has been fixed to a bin.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Quantity (Base)"; "Quantity (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many units of the item, in the base unit of measure, are stored in the bin.';
                }
                field("Bin Type Code"; "Bin Type Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the bin type that was selected for this bin.';
                    Visible = false;
                }
                field("Zone Code"; "Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone code of the bin.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(Control7; "Lot Numbers by Bin FactBox")
            {
                ApplicationArea = ItemTracking;
                SubPageLink = "Item No." = FIELD("Item No."),
                              "Variant Code" = FIELD("Variant Code"),
                              "Location Code" = FIELD("Location Code");
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if xRec."Location Code" <> '' then
            "Location Code" := xRec."Location Code";
    end;

    local procedure GetCaption(): Text[250]
    var
        ObjTransl: Record "Object Translation";
        ItemNo: Code[20];
        VariantCode: Code[10];
        BinCode: Code[20];
        FormCaption: Text[250];
        SourceTableName: Text[250];
    begin
        SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 14);
        FormCaption := StrSubstNo('%1 %2', SourceTableName, "Location Code");
        if GetFilter("Item No.") <> '' then
            if GetRangeMin("Item No.") = GetRangeMax("Item No.") then begin
                ItemNo := GetRangeMin("Item No.");
                if ItemNo <> '' then begin
                    SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 27);
                    FormCaption := StrSubstNo('%1 %2 %3', FormCaption, SourceTableName, ItemNo)
                end;
            end;

        if GetFilter("Variant Code") <> '' then
            if GetRangeMin("Variant Code") = GetRangeMax("Variant Code") then begin
                VariantCode := GetRangeMin("Variant Code");
                if VariantCode <> '' then begin
                    SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 5401);
                    FormCaption := StrSubstNo('%1 %2 %3', FormCaption, SourceTableName, VariantCode)
                end;
            end;

        if GetFilter("Bin Code") <> '' then
            if GetRangeMin("Bin Code") = GetRangeMax("Bin Code") then begin
                BinCode := GetRangeMin("Bin Code");
                if BinCode <> '' then begin
                    SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 7354);
                    FormCaption := StrSubstNo('%1 %2 %3', FormCaption, SourceTableName, BinCode);
                end;
            end;

        exit(FormCaption);
    end;
}

