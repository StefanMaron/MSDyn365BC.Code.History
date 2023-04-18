#if not CLEAN21
page 2124 "O365 Item Basket Part"
{
    Caption = 'Prices';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "O365 Item Basket Entry";
    SourceTableTemporary = true;
    SourceTableView = SORTING(Description);
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(Control14)
            {
                InstructionalText = 'Swipe right to add line items, swipe left to remove';
                ShowCaption = false;
            }
            repeater(Group)
            {
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    BlankZero = true;
                    DecimalPlaces = 0 : 5;
                    Style = StandardAccent;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies the quantity for the line.';

                    trigger OnValidate()
                    begin
                        ChangeBasket(Quantity - xRec.Quantity);
                    end;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the item number.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the item description.';
                }
                field("Base Unit of Measure"; Rec."Base Unit of Measure")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the item unit of measure.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = '2';
                    AutoFormatType = 10;
                    Editable = false;
                    ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                }
                field(Picture; Picture)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies a picture of the item.';
                }
                field("Brick Text 2"; Rec."Brick Text 2")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Editable = false;
                    Style = StandardAccent;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies the line total for this item.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(AddToBasket)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = '+1';
                Gesture = LeftSwipe;
                Image = Add;
                Scope = Repeater;
                ToolTip = 'Add an item to the invoice.';

                trigger OnAction()
                begin
                    AddOneToBasket();
                end;
            }
            action(ReduceBasket)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = '-1';
                Gesture = RightSwipe;
                Image = RemoveLine;
                Scope = Repeater;
                ToolTip = 'Remove an item from the invoice.';

                trigger OnAction()
                begin
                    RemoveOneFromBasket();
                end;
            }
            action(Card)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Card';
                Scope = Repeater;
                ToolTip = 'View or change detailed information about the record on the document or journal line.';

                trigger OnAction()
                var
                    Item: Record Item;
                begin
                    if not Item.Get("Item No.") then
                        exit;
                    PAGE.RunModal(PAGE::"O365 Item Card", Item);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(AddToBasket_Promoted; AddToBasket)
                {
                }
                actionref(ReduceBasket_Promoted; ReduceBasket)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        "Brick Text 2" := '';
        Quantity := 0;
        if TempO365ItemBasketEntry.Get("Item No.") then begin
            if TempO365ItemBasketEntry."Line Total" <> 0 then
                "Brick Text 2" := Format(TempO365ItemBasketEntry."Line Total", 0, '<Precision,2><Standard Format,0>');
            Quantity := TempO365ItemBasketEntry.Quantity;
            "Unit Price" := TempO365ItemBasketEntry."Unit Price";
            Description := TempO365ItemBasketEntry.Description;
        end;
    end;

    trigger OnClosePage()
    begin
        if AnySelectionMade then
            if Confirm(UpdateQst, true) then
                GetSalesLines(GlobalSalesLine);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Found: Boolean;
    begin
        CopyFiltersToItem(Item);
        Found := Item.Find(Which);
        if Found then
            CopyFromItem(Item);
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        ResultSteps: Integer;
    begin
        CopyFiltersToItem(Item);
        ResultSteps := Item.Next(Steps);
        if ResultSteps <> 0 then
            CopyFromItem(Item);
        exit(ResultSteps);
    end;

    var
        GlobalSalesLine: Record "Sales Line";
        Item: Record Item;
        TempO365ItemBasketEntry: Record "O365 Item Basket Entry" temporary;
        AnySelectionMade: Boolean;
        UpdateQst: Label 'Update invoice?';

    local procedure CopyFiltersToItem(var Item: Record Item)
    begin
        FilterGroup(-1);
        Item.FilterGroup(-1);
        CopyFilter(Description, Item.Description);
        CopyFilter("Item No.", Item."No.");
        CopyFilter("Unit Price", Item."Unit Price");
        CopyFilter("Base Unit of Measure", Item."Base Unit of Measure");
        FilterGroup(0);
        Item.FilterGroup(0);
        Item.SetCurrentKey(Description);
        if Item.Get("Item No.") then;
    end;

    local procedure GetBasketEntry(var O365ItemBasketEntry: Record "O365 Item Basket Entry")
    begin
        if O365ItemBasketEntry.Get("Item No.") then
            exit;
        O365ItemBasketEntry.Init();
        O365ItemBasketEntry."Item No." := "Item No.";
        O365ItemBasketEntry.Description := Description;
        O365ItemBasketEntry.Insert();
    end;

    local procedure AddOneToBasket()
    begin
        ChangeBasket(1);
    end;

    local procedure RemoveOneFromBasket()
    begin
        ChangeBasket(-1);
    end;

    local procedure ChangeBasket(QuantityChange: Decimal)
    begin
        GetBasketEntry(TempO365ItemBasketEntry);
        TempO365ItemBasketEntry.Quantity += QuantityChange;
        if TempO365ItemBasketEntry.Quantity <= 0 then
            TempO365ItemBasketEntry.Delete()
        else begin
            TempO365ItemBasketEntry."Unit Price" := "Unit Price";
            TempO365ItemBasketEntry."Line Total" := Round(TempO365ItemBasketEntry.Quantity * TempO365ItemBasketEntry."Unit Price");
            TempO365ItemBasketEntry.Modify();
        end;
        AnySelectionMade := true;
    end;

    local procedure CopyFromItem(var Item: Record Item)
    begin
        if not Get(Item."No.") then begin
            Init();
            "Item No." := Item."No.";
            "Unit Price" := Item."Unit Price";
            Description := Item.Description;
            "Base Unit of Measure" := Item."Base Unit of Measure";
            Picture := Item.Picture;
            Insert();
        end else
            Modify();
    end;

    procedure SetSalesLines(var OrgSalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        TempO365ItemBasketEntry.DeleteAll();
        OrgSalesLine.FilterGroup(4);
        if OrgSalesLine.GetFilters = '' then
            exit;
        if not SalesHeader.Get(OrgSalesLine.GetRangeMin("Document Type"), OrgSalesLine.GetRangeMin("Document No.")) then
            exit;
        GlobalSalesLine.Copy(OrgSalesLine);
        OrgSalesLine.FilterGroup(0);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                TempO365ItemBasketEntry.Init();
                TempO365ItemBasketEntry."Item No." := SalesLine."No.";
                if not TempO365ItemBasketEntry.Find() then
                    TempO365ItemBasketEntry.Insert();
                TempO365ItemBasketEntry.Quantity += SalesLine.Quantity;
                TempO365ItemBasketEntry."Unit Price" := SalesLine."Unit Price";
                TempO365ItemBasketEntry."Line Total" := Round(TempO365ItemBasketEntry.Quantity * TempO365ItemBasketEntry."Unit Price");
                TempO365ItemBasketEntry.Description := SalesLine.Description;
                TempO365ItemBasketEntry."Base Unit of Measure" := SalesLine."Unit of Measure Code";
                TempO365ItemBasketEntry.Modify();
            until SalesLine.Next() = 0;
    end;

    procedure GetSalesLines(var OrgSalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        OrgSalesLine.FilterGroup(4);
        if OrgSalesLine.GetFilters = '' then
            exit;
        if not SalesHeader.Get(OrgSalesLine.GetRangeMin("Document Type"), OrgSalesLine.GetRangeMin("Document No.")) then
            exit;
        OrgSalesLine.FilterGroup(0);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.DeleteAll(true);
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 0;
        SalesLine.SetHideValidationDialog(true);
        if TempO365ItemBasketEntry.FindSet() then
            repeat
                SalesLine.Init();
                SalesLine."Line No." += 10000;
                SalesLine.Type := SalesLine.Type::Item;
                SalesLine.Validate("No.", TempO365ItemBasketEntry."Item No.");
                SalesLine.Description := TempO365ItemBasketEntry.Description;
                SalesLine."Unit of Measure Code" := TempO365ItemBasketEntry."Base Unit of Measure";
                if SalesLine."Unit of Measure Code" <> '' then
                    if UnitOfMeasure.Get(SalesLine."Unit of Measure Code") then
                        SalesLine."Unit of Measure" := UnitOfMeasure.GetDescriptionInCurrentLanguage();
                SalesLine.Validate("Unit Price", TempO365ItemBasketEntry."Unit Price");
                SalesLine.Validate(Quantity, TempO365ItemBasketEntry.Quantity);
                SalesLine.Insert();
            until TempO365ItemBasketEntry.Next() = 0;
    end;
}
#endif
