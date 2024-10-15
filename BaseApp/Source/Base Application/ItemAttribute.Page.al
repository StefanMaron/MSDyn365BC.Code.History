page 7503 "Item Attribute"
{
    Caption = 'Item Attribute';
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "Item Attribute";
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            group(Control9)
            {
                ShowCaption = false;
                group(Control2)
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

                        trigger OnValidate()
                        begin
                            UpdateControlVisibility();
                        end;
                    }
                    field(Blocked; Blocked)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies that the attribute cannot be assigned to an item. Items to which the attribute is already assigned are not affected.';
                    }
                }
                group(Control11)
                {
                    ShowCaption = false;
                    Visible = ValuesDrillDownVisible;
                    field(Values; GetValues())
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Values';
                        Editable = false;
                        ToolTip = 'Specifies the values of the item attribute.';

                        trigger OnDrillDown()
                        begin
                            OpenItemAttributeValues();
                        end;
                    }
                }
                group(Control13)
                {
                    ShowCaption = false;
                    Visible = UnitOfMeasureVisible;
                    field("Unit of Measure"; Rec."Unit of Measure")
                    {
                        ApplicationArea = Basic, Suite;
                        DrillDown = false;
                        ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';

                        trigger OnDrillDown()
                        begin
                            OpenItemAttributeValues();
                        end;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ItemAttributeValues)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item Attribute &Values';
                Enabled = ValuesDrillDownVisible;
                Image = CalculateInventory;
                RunObject = Page "Item Attribute Values";
                RunPageLink = "Attribute ID" = FIELD(ID);
                ToolTip = 'Opens a window in which you can define the values for the selected item attribute.';
            }
            action(ItemAttributeTranslations)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Translations';
                Image = Translations;
                RunObject = Page "Item Attribute Translations";
                RunPageLink = "Attribute ID" = FIELD(ID);
                ToolTip = 'Opens a window in which you can define the translations for the selected item attribute.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ItemAttributeValues_Promoted; ItemAttributeValues)
                {
                }
                actionref(ItemAttributeTranslations_Promoted; ItemAttributeTranslations)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControlVisibility();
    end;

    trigger OnOpenPage()
    begin
        UpdateControlVisibility();
    end;

    var
        ValuesDrillDownVisible: Boolean;
        UnitOfMeasureVisible: Boolean;

    local procedure UpdateControlVisibility()
    begin
        ValuesDrillDownVisible := (Type = Type::Option);
        UnitOfMeasureVisible := (Type = Type::Decimal) or (Type = Type::Integer);
    end;
}

