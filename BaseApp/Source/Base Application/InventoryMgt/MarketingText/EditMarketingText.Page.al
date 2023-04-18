page 5835 "Edit Marketing Text"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Marketing Text';
    DelayedInsert = true;
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    Extensible = false;
    SourceTable = "Entity Text";
    DataCaptionExpression = ItemDescription;

    layout
    {
        area(content)
        {
            part(EntityTextPart; "Entity Text Part")
            {
                ApplicationArea = Basic, Suite;
                UpdatePropagation = Both;
                Caption = 'Marketing text';
            }
        }
    }

    trigger OnInit()
    begin
        CurrPage.EntityTextPart.Page.SetContentCaption(MarketingTextLbl);
    end;

    trigger OnAfterGetCurrRecord()
    var
        Item: Record Item;
        EntityText: Codeunit "Entity Text";
        Facts: Dictionary of [Text, Text];
        Tone: Enum "Entity Text Tone";
        TextFormat: Enum "Entity Text Format";
    begin
        if HasLoaded then
            exit;

        Item.GetBySystemId(Rec."Source System Id");
        ItemDescription := Item.Description;

        CurrPage.EntityTextPart.Page.SetContext(EntityText.GetText(Rec), Facts, Tone, TextFormat);
        HasLoaded := true;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not (CloseAction in [Action::LookupOK, Action::OK]) then
            exit(true);

        CurrPage.EntityTextPart.Page.UpdateRecord(Rec);
        Rec.Modify();
    end;

    var
        ItemDescription: Text;
        HasLoaded: Boolean;
        MarketingTextLbl: Label 'Marketing Text';
}