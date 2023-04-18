page 1637 "Office Suggested Line Items"
{
    Caption = 'Suggested Line Items';
    DataCaptionExpression = PageTitleTxt;
    PageType = StandardDialog;
    ShowFilter = false;
    SourceTable = "Office Suggested Line Item";
    SourceTableTemporary = true;
    layout
    {
        area(content)
        {
            group(Control8)
            {
                InstructionalText = 'We think we''ve found one or more items that match the text in the email. Would you like to add them as line items in the document?';
                ShowCaption = false;
                repeater(Control3)
                {
                    ShowCaption = false;
                    field(Add; Add)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies whether to add this item to the document';
                        trigger OnValidate()
                        begin
                            if Add and (Matches > 1) then
                                Error(ItemNeedsToBeResolvedErr);
                        end;
                    }
                    field(Item; GetItem())
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item';
                        Editable = false;
                        Lookup = false;
                        QuickEntry = false;
                        Style = Attention;
                        StyleExpr = Matches > 1;
                        ToolTip = 'Specifies the item';
                        Width = 10;

                        trigger OnDrillDown()
                        var
                            Item: Record Item;
                            ItemNo: Text[50];
                        begin
                            if Matches > 1 then begin
                                if Item.TryGetItemNo(ItemNo, "Item Description", false) then
                                    Item.Get(ItemNo);
                            end else
                                Item.PickItem(Item);

                            if Item."No." <> '' then begin
                                Validate("Item No.", Item."No.");
                                Validate("Item Description", Item.Description);
                                Validate(Add, true);
                                Validate(Matches, 1);
                                if "Line No." = 0 then begin
                                    Validate("Line No.", LastLineNo + 1000);
                                    LastLineNo := "Line No.";
                                end;
                            end;
                        end;

                        trigger OnValidate()
                        var
                            TempOfficeSuggestedLineItem: Record "Office Suggested Line Item" temporary;
                        begin
                            if "Line No." = 0 then begin
                                TempOfficeSuggestedLineItem.Copy(Rec, true);
                                if TempOfficeSuggestedLineItem.FindLast() then
                                    "Line No." := TempOfficeSuggestedLineItem."Line No." + 1000;
                            end;
                        end;
                    }
                    field(Description; GetDescription())
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Description';
                        Editable = false;
                        TableRelation = Item.Description WHERE("No." = FIELD("Item No."));
                        Width = 20;
                    }
                    field(Quantity; Rec.Quantity)
                    {
                        ApplicationArea = Basic, Suite;
                        Width = 6;
                    }
                }
                field(DoNotShowAgain; DoNotShowAgain)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Do not show this message again';
                    trigger OnValidate()
                    begin
                        UpdatedDoNotShowAgain := DoNotShowAgain;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if FindLast() then
            LastLineNo := "Line No.";
    end;

    trigger OnAfterGetCurrRecord()
    begin
        DoNotShowAgain := UpdatedDoNotShowAgain;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            if DoNotShowAgain then
                OnDisableMessage();
    end;

    var
        PageTitleTxt: Label 'Suggested Line Items';
        ResolveItemTxt: Label 'Resolve item';
        LastLineNo: Integer;
        DoNotShowAgain: Boolean;
        UpdatedDoNotShowAgain: Boolean;
        MultipleMatchesTxt: Label '%1 (%2 matches)', Comment = '%1 - The keyword that yielded items in the database. %2 - the number of item matches that were found from the keyword.';
        ItemNeedsToBeResolvedErr: Label 'Resolve the item in order to add it.';

    local procedure GetDescription() Description: Text
    begin
        if Matches > 1 then
            Description := StrSubstNo(MultipleMatchesTxt, "Item Description", Matches)
        else
            Description := "Item Description";
    end;

    local procedure GetItem() Item: Text
    begin
        if Matches > 1 then
            Item := ResolveItemTxt
        else
            Item := "Item No.";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDisableMessage()
    begin
    end;
}

