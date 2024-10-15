page 9185 "Generic Chart Text Editor"
{
    Caption = 'Generic Chart Text Editor';
    PageType = List;
    ShowFilter = false;
    SourceTable = "Generic Chart Captions Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code. This field is intended only for internal use.';
                    Visible = false;
                }
                field("Language Code"; "Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                }
                field("Language Name"; "Language Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the language of the measure caption that is shown next to the y-axis of the generic chart.';
                }
                field(Text; Caption)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the caption that is shown next to the y-axis to describe the selected measure.';
                }
            }
        }
    }

    actions
    {
    }

    procedure AssistEdit(var TempGenericChartCaptionsBuf: Record "Generic Chart Captions Buffer" temporary; CaptionCode: Code[10]): Text
    var
        Language: Codeunit Language;
    begin
        Copy(TempGenericChartCaptionsBuf, true);
        SetRange(Code, CaptionCode);
        if Get(CaptionCode, Language.GetUserLanguageCode) then;
        CurrPage.RunModal();
        exit(GetCaption(CaptionCode, Language.GetUserLanguageCode))
    end;
}

