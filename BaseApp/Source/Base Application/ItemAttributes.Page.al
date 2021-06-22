page 7500 "Item Attributes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Item Attributes';
    CardPageID = "Item Attribute";
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Item Attribute";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the item attribute.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the item attribute.';
                }
                field(Values; GetValues)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Values';
                    ToolTip = 'Specifies the values of the item attribute.';

                    trigger OnDrillDown()
                    begin
                        OpenItemAttributeValues;
                    end;
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Attribute")
            {
                Caption = '&Attribute';
                action(ItemAttributeValues)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Attribute &Values';
                    Enabled = (Type = Type::Option);
                    Image = CalculateInventory;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    RunObject = Page "Item Attribute Values";
                    RunPageLink = "Attribute ID" = FIELD(ID);
                    ToolTip = 'Opens a window in which you can define the values for the selected item attribute.';
                }
                action(ItemAttributeTranslations)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Translations';
                    Image = Translations;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    RunObject = Page "Item Attribute Translations";
                    RunPageLink = "Attribute ID" = FIELD(ID);
                    ToolTip = 'Opens a window in which you can define the translations for the selected item attribute.';
                }
            }
        }
    }
}

