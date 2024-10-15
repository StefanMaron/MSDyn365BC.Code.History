page 7505 "Item Attr. Value Translations"
{
    Caption = 'Item Attribute Value Translations';
    DataCaptionExpression = DynamicCaption;
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Item Attr. Value Translation";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Language Code"; "Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Languages;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the translated name of the item attribute value.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateWindowCaption
    end;

    var
        DynamicCaption: Text;

    local procedure UpdateWindowCaption()
    var
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        if ItemAttributeValue.Get("Attribute ID", ID) then
            DynamicCaption := ItemAttributeValue.Value
        else
            DynamicCaption := '';
    end;
}

