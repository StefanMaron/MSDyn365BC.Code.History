report 11511 "Item Copy"
{
    Caption = 'Item Copy';
    ProcessingOnly = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Copy Item page';
    ObsoleteTag = '15.3';

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
                    field("SourceItem.""No."""; SourceItem."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Source Item No.';
                        Lookup = true;
                        TableRelation = Item;
                        ToolTip = 'Specifies the number of the item that you want to copy the data from.';
                    }
                    field(TargetItemNo; TargetItem."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Target Item No.';
                        Lookup = true;
                        ToolTip = 'Specifies the number of the item that you want to copy the data to.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if PAGE.RunModal(PAGE::"Item List", TargetItem, TargetItem."No.") = ACTION::LookupOK then;
                        end;
                    }
                    field(NewNoSeries; NewNoSeries)
                    {
                        ApplicationArea = Basic, Suite;
                        AssistEdit = true;
                        Caption = 'Target No. Series';
                        Editable = false;
                        ToolTip = 'Specifies the item number series to which the data is to be copied.';

                        trigger OnAssistEdit()
                        begin
                            InvtSetup.Get();
                            InvtSetup.TestField("Item Nos.");
                            NoSeriesMgt.SelectSeries(InvtSetup."Item Nos.", SourceItem."No. Series", NewNoSeries);
                        end;
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
                        field(Comments; CopyComments)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Comments';
                            ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                        }
                        field(CopyPic; CopyPic)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Picture';
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
                        field(UnitsOfMeasure; CopyUnitOfMeasure)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Units of measure';
                            ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                        }
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
                        field(Dimensions; CopyDimensions)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Dimensions';
                            ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                        }
                        field(CopyItemVendor; CopyItemVendor)
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
            Clear(TargetItem);
            NewNoSeries := '';

            OnAfterOpenPage;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        OnAfterPostReport(TargetItem."No.", SourceItem."No.");
    end;

    trigger OnPreReport()
    begin
        Window.Open(
          Text001 + // copy item
          Text002 + // From item
          Text003 + // To item
          '             #3############## #4#####');

        Window.Update(1, SourceItem."No.");
        Window.Update(2, TargetItem."No.");
        CopyItem(SourceItem."No.", TargetItem."No.");

        Message(
          RecapitulationTxt +
          DialogTxt[1] + DialogTxt[2] + DialogTxt[3] + DialogTxt[4] + DialogTxt[5] +
          DialogTxt[6] + DialogTxt[7] + DialogTxt[8] + DialogTxt[9] + DialogTxt[10] +
          DialogTxt[11] + DialogTxt[12] + DialogTxt[13] + DialogTxt[14] + DialogTxt[15] +
          DialogTxt[16] + DialogTxt[17] + DialogTxt[18] + DialogTxt[19] + DialogTxt[20] +
          DialogTxt[21] + DialogTxt[22] + DialogTxt[23] + DialogTxt[24] + DialogTxt[25] +
          DialogTxt[26] + DialogTxt[27] + DialogTxt[28] + DialogTxt[29] + DialogTxt[30],
          SourceItem."No.", TargetItem."No.");

        Window.Close;

        CopySuccessful := true;
    end;

    var
        SourceItem: Record Item;
        TargetItem: Record Item;
        ItemTranslation: Record "Item Translation";
        TempItem: Record Item temporary;
        InvtSetup: Record "Inventory Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Window: Dialog;
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
        DialogTxt: array[30] of Text[250];
        DialogTitle: Text[50];
        RecCount: Integer;
        CopyCount: Integer;
        TmpItemNo: Code[20];
        CopySuccessful: Boolean;
        Text001: Label 'Copy Item\\';
        Text002: Label 'Source Item     #1########\';
        Text003: Label 'Target Item     #2########\';
        RecapitulationTxt: Label 'Recapitulation of copy job:\\Source Item: %1\Target Item: %2\', Comment = 'Parameters 1 and 2 - item number';
        Text007: Label 'Source Item No. %1 doesn''t exist.';
        Text008: Label 'Target Item No. must not be empty.';
        Text009: Label 'General item information';
        Text010: Label 'Target Item No.%1 already exists.';
        Text011: Label 'Target Item %1 doesn''t exist.';
        Text013: Label 'Comments';
        Text014: Label 'Item units of measure';
        Text015: Label 'Item variants';
        Text016: Label 'Item translations';
        Text017: Label 'Extended texts';
        Text018: Label 'BOM components';
        Text021: Label 'Item vendors';
        Text025: Label 'copied.';
        Text026: Label 'Resource skills';
        Text027: Label 'Dimensions';
        Text028: Label 'Troubleshootings';
        Text029: Label 'Sales Prices';
        Text030: Label 'Sales Line Disc.';
        Text031: Label 'Purchase Prices';
        Text032: Label 'Purchase Line Disc.';
        NewNoSeries: Code[20];

    [Scope('OnPrem')]
    procedure CopyItem(SourceItemNo: Code[20]; TargetItemNo: Code[20])
    begin
        if not SourceItem.Get(SourceItemNo) then
            Error(Text007, SourceItemNo);

        if (TargetItemNo = '') and (not CopyGenItemInfo) then
            Error(Text008);

        InvtSetup.Get();

        if CopyGenItemInfo then
            InsertTargetItem(TargetItemNo)
        else begin
            if not TargetItem.Get(TargetItemNo) then
                Error(Text011, TargetItemNo);
        end;

        if not (CopySalesLineDisc or CopyPurchLineDisc) then begin
            TargetItem."Item Disc. Group" := '';
            TargetItem.Modify();
        end;

        CopyItemPicture(SourceItem, TargetItem);
        CopyItemComments(SourceItem."No.", TargetItem."No.");
        CopyItemUnisOfMeasure(SourceItem, TargetItem);
        CopyItemVariants(SourceItem."No.", TargetItem."No.");
        CopyItemTranslations(SourceItem."No.", TargetItem."No.");
        CopyExtendedTexts(SourceItem."No.", TargetItem."No.");
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
    end;

    [Scope('OnPrem')]
    procedure InitDialog(Txt: Text[50])
    begin
        RecCount := 0;
        CopyCount := CopyCount + 1;
        DialogTitle := Txt;
        Window.Update(3, Txt);
        Window.Update(4, 0);
    end;

    [Scope('OnPrem')]
    procedure UpdateDialog()
    begin
        RecCount := RecCount + 1;
        Window.Update(4, RecCount);
    end;

    [Scope('OnPrem')]
    procedure EndDialog()
    begin
        if RecCount <> 0 then
            DialogTitle := StrSubstNo('%1 %2', RecCount, DialogTitle);
        DialogTitle := DialogTitle + ' ' + Text025;
        DialogTxt[CopyCount] := DialogTitle + '\';
    end;

    procedure ItemDef(var Item2: Record Item)
    begin
        TempItem := Item2;
    end;

    procedure ItemReturn(var ReturnItem: Record Item): Boolean
    begin
        ReturnItem := TargetItem;
        exit(CopySuccessful);
    end;

    local procedure SetTargetItemNo(NewItemNo: Code[20]; var TargetItemNo: Code[20]; var TargetNoSeries: Code[20])
    var
        TmpItemNo: Code[20];
    begin
        if NewItemNo = '' then
            if NewNoSeries <> '' then begin
                NoSeriesMgt.SetSeries(TargetItemNo);
                TargetNoSeries := NewNoSeries;
            end else begin
                OnBeforeInitSeries(SourceItem, InvtSetup);
                InvtSetup.TestField("Item Nos.");
                NoSeriesMgt.InitSeries(InvtSetup."Item Nos.", TargetItem."No. Series", 0D, TargetItemNo, TargetNoSeries);
            end
        else begin
            if TargetItem.Get(NewItemNo) then
                Error(Text010, NewItemNo);
            if InvtSetup."Item Nos." <> '' then
                NoSeriesMgt.TestManual(InvtSetup."Item Nos.");

            TargetItemNo := NewItemNo;
            TargetNoSeries := '';
        end
    end;

    local procedure InsertTargetItem(NewItemNo: Code[20])
    var
        TempItemNo: Code[20];
        TempItemNoSeries: Code[20];
    begin
        InitDialog(Text009);
        with TargetItem do begin
            SetTargetItemNo(NewItemNo, TempItemNo, TempItemNoSeries);
            Copy(SourceItem);
            "No." := TempItemNo;
            "No. Series" := TempItemNoSeries;
            "Last Date Modified" := Today;
            "Created From Nonstock Item" := false;
            Insert;
        end;
        EndDialog;
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

    local procedure CopyItemComments(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        CommentLine: Record "Comment Line";
    begin
        if not CopyComments then
            exit;

        CommentLine.SetRange("Table Name", CommentLine."Table Name"::Item);
        CommentLine.SetRange("No.", FromItemNo);
        if CommentLine.FindSet then begin
            InitDialog(Text013);
            repeat
                CommentLine."No." := ToItemNo;
                CommentLine.Insert();
                CommentLine."No." := FromItemNo;
                UpdateDialog;
            until CommentLine.Next() = 0;
            EndDialog;
        end;
    end;

    local procedure CopyItemUnisOfMeasure(FromItem: Record Item; var ToItem: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        if CopyUnitOfMeasure then begin
            ItemUnitOfMeasure.SetRange("Item No.", FromItem."No.");
            if ItemUnitOfMeasure.FindSet then begin
                InitDialog(Text014);
                repeat
                    ItemUnitOfMeasure."Item No." := ToItem."No.";
                    ItemUnitOfMeasure.Insert();
                    ItemUnitOfMeasure."Item No." := FromItem."No.";
                    UpdateDialog;
                until ItemUnitOfMeasure.Next() = 0;
                EndDialog;
            end;
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

        ItemVariant.SetRange("Item No.", FromItemNo);
        if ItemVariant.FindSet then begin
            InitDialog(Text015);
            repeat
                ItemVariant."Item No." := ToItemNo;
                ItemVariant.Insert();
                ItemVariant."Item No." := FromItemNo;
                UpdateDialog;
            until ItemVariant.Next() = 0;
            EndDialog;
        end;
    end;

    local procedure CopyItemTranslations(FromItemNo: Code[20]; ToItemNo: Code[20])
    begin
        if not CopyTranslations then
            exit;

        ItemTranslation.SetRange("Item No.", FromItemNo);
        if not CopyVariants then
            ItemTranslation.SetRange("Variant Code", '');
        if ItemTranslation.FindSet then begin
            InitDialog(Text016);
            repeat
                ItemTranslation."Item No." := ToItemNo;
                ItemTranslation.Insert();
                ItemTranslation."Item No." := FromItemNo;
                UpdateDialog;
            until ItemTranslation.Next() = 0;
            EndDialog;
        end;
    end;

    local procedure CopyExtendedTexts(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        if not CopyExtTxt then
            exit;

        ExtendedTextHeader.SetRange("Table Name", ExtendedTextHeader."Table Name"::Item);
        ExtendedTextHeader.SetRange("No.", FromItemNo);
        if ExtendedTextHeader.FindSet then begin
            InitDialog(Text017);
            repeat
                ExtendedTextLine.SetRange("Table Name", ExtendedTextHeader."Table Name");
                ExtendedTextLine.SetRange("No.", ExtendedTextHeader."No.");
                ExtendedTextLine.SetRange("Language Code", ExtendedTextHeader."Language Code");
                ExtendedTextLine.SetRange("Text No.", ExtendedTextHeader."Text No.");
                if ExtendedTextLine.FindSet then
                    repeat
                        ExtendedTextLine."No." := ToItemNo;
                        ExtendedTextLine.Insert();
                        ExtendedTextLine."No." := FromItemNo;
                    until ExtendedTextLine.Next() = 0;

                ExtendedTextHeader."No." := ToItemNo;
                ExtendedTextHeader.Insert();
                ExtendedTextHeader."No." := FromItemNo;
                UpdateDialog;
            until ExtendedTextHeader.Next() = 0;
            EndDialog;
        end;

        OnAfterCopyExtendedTexts(SourceItem, TargetItem, CopyVariants);
    end;

    local procedure CopyBOMComponents(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        BOMComponent: Record "BOM Component";
    begin
        if not CopyBOM then
            exit;

        BOMComponent.SetRange("Parent Item No.", FromItemNo);
        if BOMComponent.FindSet then begin
            InitDialog(Text018);
            repeat
                BOMComponent."Parent Item No." := ToItemNo;
                BOMComponent.Insert();
                BOMComponent."Parent Item No." := FromItemNo;
                UpdateDialog;
            until BOMComponent.Next() = 0;
            EndDialog;
        end;
    end;

    local procedure CopyItemVendors(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        ItemVendor: Record "Item Vendor";
    begin
        if not CopyItemVendor then
            exit;

        ItemVendor.SetRange("Item No.", FromItemNo);
        if ItemVendor.FindSet then begin
            InitDialog(Text021);
            repeat
                ItemVendor."Item No." := ToItemNo;
                ItemVendor.Insert();
                ItemVendor."Item No." := FromItemNo;
                UpdateDialog;
            until ItemVendor.Next() = 0;
            EndDialog;
        end;
    end;

    local procedure CopyItemDimensions(FromItem: Record Item; var ToItem: Record Item)
    var
        DefaultDim: Record "Default Dimension";
    begin
        if CopyDimensions then begin
            DefaultDim.SetRange("Table ID", DATABASE::Item);
            DefaultDim.SetRange("No.", FromItem."No.");
            if DefaultDim.FindSet then begin
                InitDialog(Text027);
                repeat
                    DefaultDim."No." := ToItem."No.";
                    DefaultDim.Insert();
                    DefaultDim."No." := FromItem."No.";
                    UpdateDialog;
                until DefaultDim.Next() = 0;
                EndDialog;
            end;
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
    begin
        if not CopyTroubleshooting then
            exit;

        TroubleshootingSetup.SetRange(Type, TroubleshootingSetup.Type::Item);
        TroubleshootingSetup.SetRange("No.", FromItemNo);
        if TroubleshootingSetup.FindSet then begin
            InitDialog(Text028);
            repeat
                TroubleshootingSetup."No." := ToItemNo;
                TroubleshootingSetup.Insert();
                TroubleshootingSetup."No." := FromItemNo;
                UpdateDialog;
            until TroubleshootingSetup.Next() = 0;
            EndDialog;
        end;
    end;

    local procedure CopyItemResourceSkills(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        ResourceSkill: Record "Resource Skill";
    begin
        if not CopyResourceSkills then
            exit;

        ResourceSkill.SetRange(Type, ResourceSkill.Type::Item);
        ResourceSkill.SetRange("No.", FromItemNo);
        if ResourceSkill.FindSet then begin
            InitDialog(Text026);
            repeat
                ResourceSkill."No." := ToItemNo;
                ResourceSkill.Insert();
                ResourceSkill."No." := FromItemNo;
                UpdateDialog;
            until ResourceSkill.Next() = 0;
            EndDialog;
        end;
    end;

    local procedure CopyItemSalesPrices(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        SalesPrice: Record "Sales Price";
    begin
        if not CopySalesPrices then
            exit;

        SalesPrice.SetRange("Item No.", FromItemNo);
        if SalesPrice.FindSet then begin
            InitDialog(Text029);
            repeat
                SalesPrice."Item No." := ToItemNo;
                SalesPrice.Insert();
                SalesPrice."Item No." := FromItemNo;
                UpdateDialog;
            until SalesPrice.Next() = 0;
        end;
    end;

    local procedure CopySalesLineDiscounts(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        if not CopySalesLineDisc then
            exit;

        SalesLineDiscount.SetRange(Type, SalesLineDiscount.Type::Item);
        SalesLineDiscount.SetRange(Code, FromItemNo);
        if SalesLineDiscount.FindSet then begin
            InitDialog(Text030);
            repeat
                SalesLineDiscount.Code := ToItemNo;
                SalesLineDiscount.Insert();
                SalesLineDiscount.Code := FromItemNo;
                UpdateDialog;
            until SalesLineDiscount.Next() = 0;
        end;
    end;

    local procedure CopyPurchasePrices(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        PurchasePrice: Record "Purchase Price";
    begin
        if not CopyPurchPrices then
            exit;

        PurchasePrice.SetRange("Item No.", FromItemNo);
        if PurchasePrice.FindSet then begin
            InitDialog(Text031);
            repeat
                PurchasePrice."Item No." := ToItemNo;
                PurchasePrice.Insert();
                PurchasePrice."Item No." := FromItemNo;
                UpdateDialog;
            until PurchasePrice.Next() = 0;
        end;
    end;

    local procedure CopyPurchaseLineDiscounts(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        PurchLineDiscount: Record "Purchase Line Discount";
    begin
        if not CopyPurchLineDisc then
            exit;

        PurchLineDiscount.SetRange("Item No.", FromItemNo);
        if PurchLineDiscount.FindSet then begin
            InitDialog(Text032);
            repeat
                PurchLineDiscount."Item No." := ToItemNo;
                PurchLineDiscount.Insert();
                PurchLineDiscount."Item No." := FromItemNo;
                UpdateDialog;
            until PurchLineDiscount.Next() = 0;
        end;
    end;

    local procedure CopyItemAttributes(FromItemNo: Code[20]; ToItemNo: Code[20])
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        NewItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        if not CopyAttributes then
            exit;

        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        ItemAttributeValueMapping.SetRange("No.", FromItemNo);
        if ItemAttributeValueMapping.FindSet then
            repeat
                NewItemAttributeValueMapping := ItemAttributeValueMapping;
                NewItemAttributeValueMapping."No." := ToItemNo;
                NewItemAttributeValueMapping.Insert();
            until ItemAttributeValueMapping.Next() = 0;
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
    local procedure OnAfterCopyExtendedTexts(var SourceItem: Record Item; var TargetItem: Record Item; CopyVariants: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitSeries(var Item: Record Item; var InventorySetup: Record "Inventory Setup")
    begin
    end;
}

