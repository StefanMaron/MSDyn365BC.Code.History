page 598 "XBRL Line Constants"
{
    AutoSplitKey = true;
    Caption = 'XBRL Line Constants';
    DataCaptionExpression = GetCaption;
    PageType = List;
    SourceTable = "XBRL Line Constant";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies the date on which the constant amount on this line comes into effect. The constant amount on this line applies from this date until the date in the Starting Date field on the next line.';
                }
                field("Constant Amount"; "Constant Amount")
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies the amount that will be exported if the source type is Constant.';
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

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if BelowxRec then
            "Starting Date" := xRec."Starting Date";
    end;

    local procedure GetCaption(): Text[250]
    var
        XBRLLine: Record "XBRL Taxonomy Line";
    begin
        if not XBRLLine.Get("XBRL Taxonomy Name", "XBRL Taxonomy Line No.") then
            exit('');

        CopyFilter("Label Language Filter", XBRLLine."Label Language Filter");
        XBRLLine.CalcFields(Label);
        if XBRLLine.Label = '' then
            XBRLLine.Label := XBRLLine.Name;
        exit(XBRLLine.Label);
    end;
}

