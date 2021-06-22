page 5404 "Item Units of Measure"
{
    Caption = 'Item Units of Measure';
    DataCaptionFields = "Item No.";
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Item Unit of Measure";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item card from which you opened the Item Units of Measure window.';
                    Visible = false;
                }
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies a unit of measure code that has been set up in the Unit of Measure table.';
                }
                field("Qty. per Unit of Measure"; "Qty. per Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies how many of the base unit of measure are contained in one unit of the item.';
                }
                field(Height; Height)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies the height of one item unit when measured in the unit of measure in the Code field.';
                }
                field(Width; Width)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies the width of one item unit when measured in the specified unit of measure.';
                }
                field(Length; Length)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies the length of one item unit when measured in the specified unit of measure.';
                }
                field(Cubage; Cubage)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies the volume (cubage) of one item unit in the unit of measure in the Code field.';
                }
                field(Weight; Weight)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies the weight of one item unit when measured in the specified unit of measure.';
                }
            }
            group("Current Base Unit of Measure")
            {
                Caption = 'Current Base Unit of Measure';
                field(ItemUnitOfMeasure; ItemBaseUOM)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Base Unit of Measure';
                    Lookup = true;
                    TableRelation = "Unit of Measure".Code;
                    ToolTip = 'Specifies the unit in which the item is held on inventory. The base unit of measure also serves as the conversion basis for alternate units of measure.';

                    trigger OnValidate()
                    begin
                        Item.TestField("No.");
                        Item.LockTable();
                        Item.Find;
                        Item.Validate("Base Unit of Measure", ItemBaseUOM);
                        Item.Modify(true);
                        CurrPage.Update;
                    end;
                }
            }
        }
        area(factboxes)
        {
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

    trigger OnAfterGetRecord()
    begin
        SetStyle;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if "Item No." = '' then
            "Item No." := Item."No.";
        SetStyle;
    end;

    trigger OnOpenPage()
    begin
        if GetFilter("Item No.") <> '' then begin
            CopyFilter("Item No.", Item."No.");
            if Item.FindFirst then
                ItemBaseUOM := Item."Base Unit of Measure";
        end;
    end;

    var
        Item: Record Item;
        ItemBaseUOM: Code[10];
        StyleName: Text;

    local procedure SetStyle()
    begin
        if Code = ItemBaseUOM then
            StyleName := 'Strong'
        else
            StyleName := '';
    end;
}

