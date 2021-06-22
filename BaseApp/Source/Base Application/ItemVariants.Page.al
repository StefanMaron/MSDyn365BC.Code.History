page 5401 "Item Variants"
{
    Caption = 'Item Variants';
    DataCaptionFields = "Item No.";
    PageType = List;
    SourceTable = "Item Variant";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the item card from which you opened the Item Variant Translations window.';
                    Visible = false;
                }
                field("Code"; Code)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a code to identify the variant.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies text that describes the item variant.';
                }
                field("Description 2"; "Description 2")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the item variant in more detail than the Description field.';
                    Visible = false;
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
        area(navigation)
        {
            group("V&ariant")
            {
                Caption = 'V&ariant';
                Image = ItemVariant;
                action(Translations)
                {
                    ApplicationArea = Planning;
                    Caption = 'Translations';
                    Image = Translations;
                    RunObject = Page "Item Translations";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD(Code);
                    ToolTip = 'View or edit translated item descriptions. Translated item descriptions are automatically inserted on documents according to the language code.';
                }
            }
        }
    }

    procedure GetSelectionFilter(): Text
    var
        ItemVariant: Record "Item Variant";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(ItemVariant);
        exit(SelectionFilterManagement.GetSelectionFilterForItemVariant(ItemVariant));
    end;
}

