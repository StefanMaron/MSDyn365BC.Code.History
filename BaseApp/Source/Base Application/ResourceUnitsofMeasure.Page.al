page 210 "Resource Units of Measure"
{
    Caption = 'Resource Units of Measure';
    DataCaptionFields = "Resource No.";
    PageType = List;
    SourceTable = "Resource Unit of Measure";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Resource No."; "Resource No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the resource.';
                    Visible = false;
                }
                field("Code"; Code)
                {
                    ApplicationArea = Jobs;
                    Style = Strong;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies one of the unit of measure codes that has been set up in the Unit of Measure table.';
                }
                field("Qty. per Unit of Measure"; "Qty. per Unit of Measure")
                {
                    ApplicationArea = Jobs;
                    Style = Strong;
                    StyleExpr = StyleName;
                    ToolTip = 'Specifies the number of units of the code. If, for example, the base unit of measure is hour, and the code is day, enter 8 in this field.';
                }
                field("Related to Base Unit of Meas."; "Related to Base Unit of Meas.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies that the unit of measure can be calculated into the base unit of measure. For example, 2 days equals 16 hours.';
                }
            }
            group("Current Base Unit of Measure")
            {
                Caption = 'Current Base Unit of Measure';
                field(ResUnitOfMeasure; ResBaseUOM)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Base Unit of Measure';
                    Lookup = true;
                    TableRelation = "Unit of Measure".Code;
                    ToolTip = 'Specifies the unit in which the resource is managed internally. The base unit of measure also serves as the conversion basis for alternate units of measure.';

                    trigger OnValidate()
                    begin
                        Res.Validate("Base Unit of Measure", ResBaseUOM);
                        Res.Modify(true);
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
        SetStyle;
    end;

    trigger OnOpenPage()
    begin
        if Res.Get("Resource No.") then
            ResBaseUOM := Res."Base Unit of Measure";
    end;

    var
        Res: Record Resource;
        ResBaseUOM: Code[10];
        StyleName: Text;

    local procedure SetStyle()
    begin
        if Code = ResBaseUOM then
            StyleName := 'Strong'
        else
            StyleName := '';
    end;
}

