page 7501 "Item Attribute Values"
{
    Caption = 'Item Attribute Values';
    DataCaptionFields = "Attribute ID";
    PageType = List;
    SourceTable = "Item Attribute Value";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Value; Value)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the item attribute.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the attribute value cannot be assigned to an item. Items to which the attribute value is already assigned are not affected.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Process)
            {
                Caption = 'Process';
                action(ItemAttributeValueTranslations)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Translations';
                    Image = Translations;
                    RunObject = Page "Item Attr. Value Translations";
                    RunPageLink = "Attribute ID" = FIELD("Attribute ID"),
                                  ID = FIELD(ID);
                    ToolTip = 'Opens a window in which you can specify the translations of the selected item attribute value.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ItemAttributeValueTranslations_Promoted; ItemAttributeValueTranslations)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        AttributeID: Integer;
    begin
        if GetFilter("Attribute ID") <> '' then
            AttributeID := GetRangeMin("Attribute ID");
        if AttributeID <> 0 then begin
            FilterGroup(2);
            SetRange("Attribute ID", AttributeID);
            FilterGroup(0);
        end;
    end;
}

