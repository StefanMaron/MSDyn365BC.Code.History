report 730 "Copy Item"
{
    Caption = 'Copy Item';
    ProcessingOnly = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Copy Item page';
    ObsoleteTag = '16.0';

    dataset
    {
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(SourceItemNo; SourceItem."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Source Item No.';
                        Editable = false;
                        Lookup = true;
                        TableRelation = Item;
                        ToolTip = 'Specifies the number of the item that you want to copy the data from.';
                    }
                    field(TargetItemNo; TargetItemNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Target Item No.';
                        ToolTip = 'Specifies the number of the new item that you want to copy the data to. \\To generate the new item number from a number series, fill in the Target No. Series field instead.';

                        trigger OnValidate()
                        begin
                            if TargetItemNo <> '' then
                                TargetNoSeries := '';
                        end;
                    }
                    field(TargetNoSeries; TargetNoSeries)
                    {
                        ApplicationArea = Basic, Suite;
                        AssistEdit = true;
                        Caption = 'Target No. Series';
                        Editable = false;
                        ToolTip = 'Specifies the number series that is used to assign a number to the new item.';

                        trigger OnAssistEdit()
                        begin
                            InvtSetup.Get();
                            InvtSetup.TestField("Item Nos.");
                            NoSeriesMgt.SelectSeries(InvtSetup."Item Nos.", SourceItem."No. Series", TargetNoSeries);
                            TargetItemNo := '';
                        end;
                    }
                    field(NumberOfCopies; NumberOfCopies)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Number of Copies';
                        MinValue = 1;
                        ToolTip = 'Specifies the number of new items that you want to create.';
                    }
                    group(General)
                    {
                        Caption = 'General';
                        field(GeneralItemInformation; CopyGenItemInfo)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'General Item Information';
                            ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                        }
                        field(UnitsOfMeasure; CopyUnitOfMeasure)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Units of measure';
                            ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                        }
                        field(Dimensions; CopyDimensions)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Dimensions';
                            ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                        }
                        field(Picture; CopyPic)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Picture';
                            ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                        }
                        field(Comments; CopyComments)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Comments';
                            ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                        }
                    }
                    group(Sale)
                    {
                        Caption = 'Sale';
                        field(SalesPrices; CopySalesPrices)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Sales Prices';
                            ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                        }
                        field(SalesLineDisc; CopySalesLineDisc)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Sales Line Disc.';
                            ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                        }
                    }
                    group(Purchase)
                    {
                        Caption = 'Purchase';
                        field(PurchasePrices; CopyPurchPrices)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Purchase Prices';
                            ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                        }
                        field(PurchaseLineDisc; CopyPurchLineDisc)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Purchase Line Disc.';
                            ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                        }
                    }
                    group(Service)
                    {
                        Caption = 'Service';
                        field(Troubleshooting; CopyTroubleshooting)
                        {
                            ApplicationArea = Service;
                            Caption = 'Troubleshooting';
                            ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                        }
                        field(ResourceSkills; CopyResourceSkills)
                        {
                            ApplicationArea = Service;
                            Caption = 'Resource Skills';
                            ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                        }
                    }
                    group(Extended)
                    {
                        Caption = 'Extended';
                        field(ItemVariants; CopyVariants)
                        {
                            ApplicationArea = Planning;
                            Caption = 'Item Variants';
                            ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                        }
                        field(Translations; CopyTranslations)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Translations';
                            ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                        }
                        field(ExtendedTexts; CopyExtTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Extended Texts';
                            ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                        }
                        field(BOMComponents; CopyBOM)
                        {
                            ApplicationArea = Assembly, Manufacturing;
                            Caption = 'BOM Components';
                            ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                        }
                        field(ItemVendors; CopyItemVendor)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Item Vendors';
                            ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                        }
                        field(Attributes; CopyAttributes)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Attributes';
                            ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            SourceItem := TempItem;
            InvtSetup.Get();
            TargetNoSeries := InvtSetup."Item Nos.";

            OnAfterOpenPage;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        NumberOfCopies := 1;
    end;

    trigger OnPostReport()
    begin
        OnAfterPostReport(TargetItemNo, SourceItem."No.");
    end;

    trigger OnPreReport()
    var
        i: Integer;
    begin
        CheckTargetItemNo;

        if not SourceItem.Get(SourceItem."No.") then
            Error(SourceItemDoesNotExistErr, SourceItem."No.");

        if (TargetItemNo = '') and (TargetNoSeries = '') then
            Error(SpecifyTargetItemNoErr);

        InvtSetup.Get();

        for i := 1 to NumberOfCopies do
            CopyItem(i);

        CopySuccessful := true;
    end;

    var
        SourceItem: Record Item;
        TempItem: Record Item temporary;
        InvtSetup: Record "Inventory Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        CopyGenItemInfo: Boolean;
        CopyComments: Boolean;
        CopyPic: Boolean;
        CopyUnitOfMeasure: Boolean;
        CopyVariants: Boolean;
        CopyTranslations: Boolean;
        CopyExtTxt: Boolean;
        CopyBOM: Boolean;
        CopyItemVendor: Boolean;
        CopyDimensions: Boolean;
        CopyTroubleshooting: Boolean;
        CopyResourceSkills: Boolean;
        CopySalesPrices: Boolean;
        CopySalesLineDisc: Boolean;
        CopyPurchPrices: Boolean;
        CopyPurchLineDisc: Boolean;
        CopyAttributes: Boolean;
        NumberOfCopies: Integer;
        CopySuccessful: Boolean;
        SourceItemDoesNotExistErr: Label 'Source item number %1 does not exist.', Comment = '%1 - item number.';
        SpecifyTargetItemNoErr: Label 'You must specify the target item number.';
        TargetItemDoesNotExistErr: Label 'Target item number %1 already exists.', Comment = '%1 - item number.';
        TargetNoSeries: Code[20];
        TargetItemNoTxt: Label 'Target Item No.';
        TargetItemNo: Code[20];
        FirstItemNo: Code[20];
        LastItemNo: Code[20];
        UnincrementableStringErr: Label 'The value in the %1 field must have a number so that we can assign the next number in the series.', Comment = '%1 = New Field Name';

    [Scope('OnPrem')]
    procedure CopyItem(CopyCounter: Integer)
    var
        TargetItem: Record Item;
    begin
        InsertTargetItem(TargetItem, CopyCounter);

        if not (CopySalesLineDisc or CopyPurchLineDisc) then begin
            TargetItem."Item Disc. Group" := '';
            TargetItem.Modify();
        end;

        CopyItemPicture(SourceItem, TargetItem);
        CopyItemComments(SourceItem."No.", TargetItem."No.");
        CopyItemUnisOfMeasure(SourceItem, TargetItem);
        CopyItemVariants(SourceItem."No.", TargetItem."No.");
        CopyItemTranslations(SourceItem."No.", TargetItem."No.");
        CopyExtendedTexts(SourceItem."No.", TargetItem);
        CopyBOMComponents(SourceItem."No.", TargetItem."No.");
        CopyItemVendors(SourceItem."No.", TargetItem."No.");
        CopyItemDimensions(SourceItem, TargetItem);
        CopyTroubleshootingSetup(SourceItem."No.", TargetItem."No.");
        CopyItemResourceSkills(SourceItem."No.", TargetItem."No.");
        CopyItemSalesPrices(SourceItem."No.", TargetItem."No.");
        CopySalesLineDiscounts(SourceItem."No.", TargetItem."No.");
        CopyPurchasePrices(SourceItem."No.", TargetItem."No.");
        CopyPurchaseLineDiscounts(SourceItem."No.", TargetItem."No.");
        CopyItemAttributes(SourceItem."No.", TargetItem."No.");

        OnAfterCopyItem(SourceItem, TargetItem);
    end;

    [Scope('OnPrem')]
    procedure SetItem(var Item2: Record Item)
    begin
        TempItem := Item2;
    end;

    procedure IsItemCopied(var NewFirstItemNo: Code[20]; var NewLastItemNo: Code[20]): Boolean
    begin
        NewFirstItemNo := FirstItemNo;
        NewLastItemNo := LastItemNo;
        exit(CopySuccessful);
    end;

    local procedure SetTargetItemNo(var TargetItem: Record Item; CopyCounter: Integer)
    begin
        with TargetItem do begin
            if TargetNoSeries <> '' then begin
                OnBeforeInitSeries(SourceItem, InvtSetup);
                InvtSetup.TestField("Item Nos.");
                "No." := '';
                NoSeriesMgt.InitSeries(InvtSetup."Item Nos.", TargetNoSeries, 0D, "No.", TargetNoSeries);
                "No. Series" := TargetNoSeries;
            end else begin
                NoSeriesMgt.TestManual(InvtSetup."Item Nos.");

                if CopyCounter > 1 then
                    TargetItemNo := IncStr(TargetItemNo);
                "No." := TargetItemNo;
            end;

            CheckExistingItem("No.");

            if CopyCounter = 1 then
                FirstItemNo := "No.";
            LastItemNo := "No.";
        end;
    end;

    local procedure InsertTargetItem(var TargetItem: Record Item; CopyCounter: Integer)
    begin
        with TargetItem do begin
            TransferFields(SourceItem);

            SetTargetItemNo(TargetItem, CopyCounter);

            "Last Date Modified" := Today;
            "Created From Nonstock Item" := false;
            Insert;
        end;
    end;

    local procedure CheckTargetItemNo()
    begin
        if (NumberOfCopies > 1) and (TargetItemNo <> '') then
            if IncStr(TargetItemNo) = '' then
                Error(StrSubstNo(UnincrementableStringErr, TargetItemNoTxt));
    end;

    local procedure CheckExistingItem(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        if Item.Get(ItemNo) then
            Error(TargetItemDoesNotExistErr, ItemNo);
    end;

    local procedure CopyItemPicture(FromItem: Record Item; var ToItem: Record Item)
    begin
        if CopyPic then begin
            ToItem.Picture := FromItem.Picture;
            ToItem.Modify();
        end else begin
            Clear(ToItem.Picture);
            ToItem.Modify();
        end;
    end;

    local procedure CopyItemRelatedTable(TableId: Integer; FieldNo: Integer; FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        SourceRecRef: RecordRef;
        TargetRecRef: RecordRef;
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
    begin
        SourceRecRef.Open(TableId);
        SourceFieldRef := SourceRecRef.Field(FieldNo);
        SourceFieldRef.SetRange(FromItemNo);
        if SourceRecRef.FindSet then
            repeat
                TargetRecRef := SourceRecRef.Duplicate;
                TargetFieldRef := TargetRecRef.Field(FieldNo);
                TargetFieldRef.Value(ToItemNo);
                TargetRecRef.Insert();
            until SourceRecRef.Next = 0;
    end;

    local procedure CopyItemRelatedTableFromRecRef(var SourceRecRef: RecordRef; FieldNo: Integer; FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        TargetRecRef: RecordRef;
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
    begin
        SourceFieldRef := SourceRecRef.Field(FieldNo);
        SourceFieldRef.SetRange(FromItemNo);
        if SourceRecRef.FindSet then
            repeat
                TargetRecRef := SourceRecRef.Duplicate;
                TargetFieldRef := TargetRecRef.Field(FieldNo);
                TargetFieldRef.Value(ToItemNo);
                TargetRecRef.Insert();
            until SourceRecRef.Next = 0;
    end;

    local procedure CopyItemComments(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        CommentLine: Record "Comment Line";
        RecRef: RecordRef;
    begin
        if not CopyComments then
            exit;

        CommentLine.SetRange("Table Name", CommentLine."Table Name"::Item);

        RecRef.GetTable(CommentLine);
        CopyItemRelatedTableFromRecRef(RecRef, CommentLine.FieldNo("No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyItemUnisOfMeasure(FromItem: Record Item; var ToItem: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        RecRef: RecordRef;
    begin
        if CopyUnitOfMeasure then begin
            ItemUnitOfMeasure.SetRange("Item No.", FromItem."No.");
            RecRef.GetTable(ItemUnitOfMeasure);
            CopyItemRelatedTableFromRecRef(RecRef, ItemUnitOfMeasure.FieldNo("Item No."), FromItem."No.", ToItem."No.");
        end else
            if CopyGenItemInfo then begin
                ToItem."Base Unit of Measure" := '';
                ToItem."Sales Unit of Measure" := '';
                ToItem."Purch. Unit of Measure" := '';
                ToItem."Put-away Unit of Measure Code" := '';
                ToItem.Modify();
            end;
    end;

    local procedure CopyItemVariants(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        ItemVariant: Record "Item Variant";
    begin
        if not CopyVariants then
            exit;

        CopyItemRelatedTable(DATABASE::"Item Variant", ItemVariant.FieldNo("Item No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyItemTranslations(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        ItemTranslation: Record "Item Translation";
        RecRef: RecordRef;
    begin
        if not CopyTranslations then
            exit;

        ItemTranslation.SetRange("Item No.", FromItemNo);
        if not CopyVariants then
            ItemTranslation.SetRange("Variant Code", '');

        RecRef.GetTable(ItemTranslation);
        CopyItemRelatedTableFromRecRef(RecRef, ItemTranslation.FieldNo("Item No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyExtendedTexts(FromItemNo: Code[20]; var TargetItem: Record Item)
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        NewExtendedTextHeader: Record "Extended Text Header";
        NewExtendedTextLine: Record "Extended Text Line";
    begin
        if not CopyExtTxt then
            exit;

        ExtendedTextHeader.SetRange("Table Name", ExtendedTextHeader."Table Name"::Item);
        ExtendedTextHeader.SetRange("No.", FromItemNo);
        if ExtendedTextHeader.FindSet then
            repeat
                ExtendedTextLine.SetRange("Table Name", ExtendedTextHeader."Table Name");
                ExtendedTextLine.SetRange("No.", ExtendedTextHeader."No.");
                ExtendedTextLine.SetRange("Language Code", ExtendedTextHeader."Language Code");
                ExtendedTextLine.SetRange("Text No.", ExtendedTextHeader."Text No.");
                if ExtendedTextLine.FindSet then
                    repeat
                        NewExtendedTextLine.TransferFields(ExtendedTextLine);
                        NewExtendedTextLine."No." := TargetItem."No.";
                        NewExtendedTextLine.Insert();
                    until ExtendedTextLine.Next = 0;

                NewExtendedTextHeader.TransferFields(ExtendedTextHeader);
                NewExtendedTextHeader."No." := TargetItem."No.";
                NewExtendedTextHeader.Insert();
            until ExtendedTextHeader.Next = 0;

        OnAfterCopyExtendedTexts(SourceItem, TargetItem);
    end;

    local procedure CopyBOMComponents(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        BOMComponent: Record "BOM Component";
    begin
        if not CopyBOM then
            exit;

        CopyItemRelatedTable(DATABASE::"BOM Component", BOMComponent.FieldNo("Parent Item No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyItemVendors(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        ItemVendor: Record "Item Vendor";
    begin
        if not CopyItemVendor then
            exit;

        CopyItemRelatedTable(DATABASE::"Item Vendor", ItemVendor.FieldNo("Item No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyItemDimensions(FromItem: Record Item; var ToItem: Record Item)
    var
        DefaultDim: Record "Default Dimension";
        NewDefaultDim: Record "Default Dimension";
    begin
        if CopyDimensions then begin
            DefaultDim.SetRange("Table ID", DATABASE::Item);
            DefaultDim.SetRange("No.", FromItem."No.");
            if DefaultDim.FindSet then
                repeat
                    NewDefaultDim.TransferFields(DefaultDim);
                    NewDefaultDim."No." := ToItem."No.";
                    NewDefaultDim.Insert();
                until DefaultDim.Next = 0;
            ToItem."Global Dimension 1 Code" := FromItem."Global Dimension 1 Code";
            ToItem."Global Dimension 2 Code" := FromItem."Global Dimension 2 Code";
            ToItem.Modify();
        end else
            if CopyGenItemInfo then begin
                ToItem."Global Dimension 1 Code" := '';
                ToItem."Global Dimension 2 Code" := '';
                ToItem.Modify();
            end;
    end;

    local procedure CopyTroubleshootingSetup(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        TroubleshootingSetup: Record "Troubleshooting Setup";
        RecRef: RecordRef;
    begin
        if not CopyTroubleshooting then
            exit;

        TroubleshootingSetup.SetRange(Type, TroubleshootingSetup.Type::Item);

        RecRef.GetTable(TroubleshootingSetup);
        CopyItemRelatedTableFromRecRef(RecRef, TroubleshootingSetup.FieldNo("No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyItemResourceSkills(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        ResourceSkill: Record "Resource Skill";
        RecRef: RecordRef;
    begin
        if not CopyResourceSkills then
            exit;

        ResourceSkill.SetRange(Type, ResourceSkill.Type::Item);

        RecRef.GetTable(ResourceSkill);
        CopyItemRelatedTableFromRecRef(RecRef, ResourceSkill.FieldNo("No."), FromItemNo, ToItemNo);
    end;

    [Obsolete('Replaced by the new implementation (V16) of price calculation.', '16.0')]
    local procedure CopyItemSalesPrices(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        SalesPrice: Record "Sales Price";
    begin
        if not CopySalesPrices then
            exit;

        CopyItemRelatedTable(DATABASE::"Sales Price", SalesPrice.FieldNo("Item No."), FromItemNo, ToItemNo);
    end;

    [Obsolete('Replaced by the new implementation (V16) of price calculation.', '16.0')]
    local procedure CopySalesLineDiscounts(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        SalesLineDiscount: Record "Sales Line Discount";
        RecRef: RecordRef;
    begin
        if not CopySalesLineDisc then
            exit;

        SalesLineDiscount.SetRange(Type, SalesLineDiscount.Type::Item);

        RecRef.GetTable(SalesLineDiscount);
        CopyItemRelatedTableFromRecRef(RecRef, SalesLineDiscount.FieldNo(Code), FromItemNo, ToItemNo);
    end;

    [Obsolete('Replaced by the new implementation (V16) of price calculation.', '16.0')]
    local procedure CopyPurchasePrices(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        PurchasePrice: Record "Purchase Price";
    begin
        if not CopyPurchPrices then
            exit;

        CopyItemRelatedTable(DATABASE::"Purchase Price", PurchasePrice.FieldNo("Item No."), FromItemNo, ToItemNo);
    end;

    [Obsolete('Replaced by the new implementation (V16) of price calculation.', '16.0')]
    local procedure CopyPurchaseLineDiscounts(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        PurchLineDiscount: Record "Purchase Line Discount";
    begin
        if not CopyPurchLineDisc then
            exit;

        CopyItemRelatedTable(DATABASE::"Purchase Line Discount", PurchLineDiscount.FieldNo("Item No."), FromItemNo, ToItemNo);
    end;

    local procedure CopyItemAttributes(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        RecRef: RecordRef;
    begin
        if not CopyAttributes then
            exit;

        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);

        RecRef.GetTable(ItemAttributeValueMapping);
        CopyItemRelatedTableFromRecRef(RecRef, ItemAttributeValueMapping.FieldNo("No."), FromItemNo, ToItemNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenPage()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostReport(ToItemNo: Code[20]; FromItemNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyExtendedTexts(var SourceItem: Record Item; var TargetItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItem(SourceItem: Record Item; var TargetItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitSeries(var Item: Record Item; var InventorySetup: Record "Inventory Setup")
    begin
    end;
}

