codeunit 7006 "Price Helper - V16"
{
    SingleInstance = true;

    local procedure CopyJobPrices(SourceJob: Record Job; TargetJob: Record Job)
    var
        SourceType: Enum "Price Source Type";
    begin
        CopyPriceListHeaders(SourceType::Job, SourceJob."No.", TargetJob."No.");
        CopyPriceListHeaders(SourceType::"Job Task", SourceJob."No.", TargetJob."No.");

        CopyPriceListLines('', '', SourceType::Job, SourceJob."No.", TargetJob."No.");
        CopyPriceListLines('', '', SourceType::"Job Task", SourceJob."No.", TargetJob."No.");
    end;

    local procedure CopyPriceListHeaders(SourceType: Enum "Price Source Type"; OldSourceNo: Code[20]; NewSourceNo: Code[20])
    var
        PriceListHeader: Record "Price List Header";
        NewPriceListHeader: Record "Price List Header";
        FilterParentSource: Boolean;
    begin
        FilterParentSource := IsParentSourceAllowed(SourceType);
        PriceListHeader.SetRange("Source Type", SourceType);
        if FilterParentSource then
            PriceListHeader.SetRange("Parent Source No.", OldSourceNo)
        else
            PriceListHeader.SetRange("Source No.", OldSourceNo);
        if PriceListHeader.FindSet() then
            repeat
                NewPriceListHeader := PriceListHeader;
                NewPriceListHeader.Code := '';
                if FilterParentSource then
                    NewPriceListHeader."Parent Source No." := NewSourceNo
                else
                    NewPriceListHeader."Source No." := NewSourceNo;
                NewPriceListHeader.Insert(true);

                CopyPriceListLines(PriceListHeader.Code, NewPriceListHeader.Code, SourceType, OldSourceNo, NewSourceNo);
            until PriceListHeader.Next() = 0;
    end;

    local procedure CopyPriceListLines(OldCode: Code[20]; NewCode: Code[20]; SourceType: Enum "Price Source Type"; OldSourceNo: Code[20]; NewSourceNo: Code[20])
    var
        PriceListLine: Record "Price List Line";
        NewPriceListLine: Record "Price List Line";
        FilterParentSource: Boolean;
    begin
        FilterParentSource := IsParentSourceAllowed(SourceType);
        PriceListLine.SetRange("Price List Code", OldCode);
        PriceListLine.SetRange("Source Type", SourceType);
        if FilterParentSource then
            PriceListLine.SetRange("Parent Source No.", OldSourceNo)
        else
            PriceListLine.SetRange("Source No.", OldSourceNo);
        if PriceListLine.FindSet() then
            repeat
                NewPriceListLine := PriceListLine;
                NewPriceListLine."Price List Code" := NewCode;
                NewPriceListLine.SetNextLineNo();
                if FilterParentSource then
                    NewPriceListLine."Parent Source No." := NewSourceNo
                else
                    NewPriceListLine."Source No." := NewSourceNo;
                NewPriceListLine.Insert(true);
            until PriceListLine.Next() = 0;
    end;

    local procedure DeletePrices(SourceType: Enum "Price Source Type"; SourceNo: Code[20]; ParentSourceNo: Code[20])
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        PriceListHeader.SetRange("Source Type", SourceType);
        PriceListHeader.SetRange("Parent Source No.", ParentSourceNo);
        PriceListHeader.SetRange("Source No.", SourceNo);
        if not PriceListHeader.IsEmpty() then
            PriceListHeader.DeleteAll();

        PriceListLine.SetRange("Source Type", SourceType);
        PriceListLine.SetRange("Parent Source No.", ParentSourceNo);
        PriceListLine.SetRange("Source No.", SourceNo);
        if not PriceListLine.IsEmpty() then
            PriceListLine.DeleteAll();

        PriceWorksheetLine.SetRange("Source Type", SourceType);
        PriceWorksheetLine.SetRange("Parent Source No.", ParentSourceNo);
        PriceWorksheetLine.SetRange("Source No.", SourceNo);
        if not PriceWorksheetLine.IsEmpty() then
            PriceWorksheetLine.DeleteAll();
    end;

    local procedure DeletePriceLines(AssetType: Enum "Price Asset Type"; AssetNo: Code[20]; VariantCode: Code[10])
    var
        PriceListLine: Record "Price List Line";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        PriceListLine.SetRange("Asset Type", AssetType);
        PriceListLine.SetRange("Asset No.", AssetNo);
        if VariantCode <> '' then
            PriceListLine.SetRange("Variant Code", VariantCode);
        if not PriceListLine.IsEmpty() then
            PriceListLine.DeleteAll();

        PriceWorksheetLine.SetRange("Asset Type", AssetType);
        PriceWorksheetLine.SetRange("Asset No.", AssetNo);
        if VariantCode <> '' then
            PriceWorksheetLine.SetRange("Variant Code", VariantCode);
        if not PriceWorksheetLine.IsEmpty() then
            PriceWorksheetLine.DeleteAll();
    end;

    local procedure IsParentSourceAllowed(SourceType: Enum "Price Source Type"): Boolean;
    var
        PriceSource: Record "Price Source";
    begin
        PriceSource."Source Type" := SourceType;
        exit(PriceSource.IsParentSourceAllowed());
    end;

    local procedure RenameAssetInPrices(AssetType: Enum "Price Asset Type"; xAssetNo: Code[20]; AssetNo: Code[20])
    var
        PriceListLine: Record "Price List Line";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        PriceListLine.SetRange("Asset Type", AssetType);
        PriceListLine.SetRange("Asset No.", xAssetNo);
        if not PriceListLine.IsEmpty() then
            PriceListLine.ModifyAll("Asset No.", AssetNo);

        PriceWorksheetLine.SetRange("Asset Type", AssetType);
        PriceWorksheetLine.SetRange("Asset No.", xAssetNo);
        if not PriceWorksheetLine.IsEmpty() then
            PriceWorksheetLine.ModifyAll("Asset No.", AssetNo);
    end;

    local procedure RenameAssetInPrices(ItemNo: Code[20]; xVariantCode: Code[10]; VariantCode: Code[10])
    var
        PriceListLine: Record "Price List Line";
        PriceWorksheetLine: Record "Price Worksheet Line";
        AssetType: Enum "Price Asset Type";
    begin
        PriceListLine.SetRange("Asset Type", AssetType::Item);
        PriceListLine.SetRange("Asset No.", ItemNo);
        PriceListLine.SetRange("Variant Code", xVariantCode);
        if not PriceListLine.IsEmpty() then
            PriceListLine.ModifyAll("Variant Code", VariantCode);

        PriceWorksheetLine.SetRange("Asset Type", AssetType::Item);
        PriceWorksheetLine.SetRange("Asset No.", ItemNo);
        PriceWorksheetLine.SetRange("Variant Code", xVariantCode);
        if not PriceWorksheetLine.IsEmpty() then
            PriceWorksheetLine.ModifyAll("Variant Code", VariantCode);
    end;

    local procedure RenameSourceInPrices(SourceType: Enum "Price Source Type"; xSourceNo: Code[20]; SourceNo: Code[20])
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        PriceListHeader.SetRange("Source Type", SourceType);
        PriceListHeader.SetRange("Source No.", xSourceNo);
        if not PriceListHeader.IsEmpty() then
            PriceListHeader.ModifyAll("Source No.", SourceNo);

        PriceListLine.SetRange("Source Type", SourceType);
        PriceListLine.SetRange("Source No.", xSourceNo);
        if not PriceListLine.IsEmpty() then
            PriceListLine.ModifyAll("Source No.", SourceNo);

        PriceWorksheetLine.SetRange("Source Type", SourceType);
        PriceWorksheetLine.SetRange("Source No.", xSourceNo);
        if not PriceWorksheetLine.IsEmpty() then
            PriceWorksheetLine.ModifyAll("Source No.", SourceNo);
    end;

    local procedure RenameParentSourceInPrices(SourceType: Enum "Price Source Type"; xSourceNo: Code[20]; SourceNo: Code[20])
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        PriceListHeader.SetRange("Source Type", SourceType);
        PriceListHeader.SetRange("Parent Source No.", xSourceNo);
        if not PriceListHeader.IsEmpty() then
            PriceListHeader.ModifyAll("Parent Source No.", SourceNo);

        PriceListLine.SetRange("Source Type", SourceType);
        PriceListLine.SetRange("Parent Source No.", xSourceNo);
        if not PriceListLine.IsEmpty() then
            PriceListLine.ModifyAll("Parent Source No.", SourceNo);

        PriceWorksheetLine.SetRange("Source Type", SourceType);
        PriceWorksheetLine.SetRange("Parent Source No.", xSourceNo);
        if not PriceWorksheetLine.IsEmpty() then
            PriceWorksheetLine.ModifyAll("Parent Source No.", SourceNo);
    end;

    local procedure UpdateDates(Campaign: Record Campaign)
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceWorksheetLine: Record "Price Worksheet Line";
    begin
        PriceListHeader.SetRange("Source Type", "Price Source Type"::Campaign);
        PriceListHeader.SetRange("Source No.", Campaign."No.");
        PriceListHeader.LockTable();
        if PriceListHeader.FindSet() then
            repeat
                PriceListHeader."Starting Date" := Campaign."Starting Date";
                PriceListHeader.Validate("Ending Date", Campaign."Ending Date");
                PriceListHeader.Modify();
            until PriceListHeader.Next() = 0;

        PriceListLine.SetRange("Source Type", "Price Source Type"::Campaign);
        PriceListLine.SetRange("Source No.", Campaign."No.");
        PriceListLine.LockTable();
        if PriceListLine.FindSet() then
            repeat
                PriceListLine."Starting Date" := Campaign."Starting Date";
                PriceListLine.Validate("Ending Date", Campaign."Ending Date");
                PriceListLine.Modify();
            until PriceListLine.Next() = 0;

        PriceWorksheetLine.SetRange("Source Type", "Price Source Type"::Campaign);
        PriceWorksheetLine.SetRange("Source No.", Campaign."No.");
        PriceWorksheetLine.LockTable();
        if PriceWorksheetLine.FindSet() then
            repeat
                PriceWorksheetLine."Starting Date" := Campaign."Starting Date";
                PriceWorksheetLine.Validate("Ending Date", Campaign."Ending Date");
                PriceWorksheetLine.Modify();
            until PriceWorksheetLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::Campaign, 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteCampaign(var Rec: Record Campaign; RunTrigger: Boolean);
    var
        SourceType: Enum "Price Source Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeletePrices(SourceType::Campaign, Rec."No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::Contact, 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteContact(var Rec: Record Contact; RunTrigger: Boolean);
    var
        SourceType: Enum "Price Source Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeletePrices(SourceType::Contact, Rec."No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteCustomer(var Rec: Record Customer; RunTrigger: Boolean);
    var
        SourceType: Enum "Price Source Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeletePrices(SourceType::Customer, Rec."No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer Price Group", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteCustomerPriceGroup(var Rec: Record "Customer Price Group"; RunTrigger: Boolean);
    var
        SourceType: Enum "Price Source Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeletePrices(SourceType::"Customer Price Group", Rec.Code, '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer Discount Group", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteCustomerDiscountGroup(var Rec: Record "Customer Discount Group"; RunTrigger: Boolean);
    var
        SourceType: Enum "Price Source Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeletePrices(SourceType::"Customer Disc. Group", Rec.Code, '');
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteVendor(var Rec: Record Vendor; RunTrigger: Boolean);
    var
        SourceType: Enum "Price Source Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeletePrices(SourceType::Vendor, Rec."No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"G/L Account", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteGLAccount(var Rec: Record "G/L Account"; RunTrigger: Boolean);
    var
        AssetType: Enum "Price Asset Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeletePriceLines(AssetType::"G/L Account", Rec."No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::Job, 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteJob(var Rec: Record Job; RunTrigger: Boolean);
    var
        SourceType: Enum "Price Source Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeletePrices(SourceType::Job, Rec."No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Task", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteJobTask(var Rec: Record "Job Task"; RunTrigger: Boolean);
    var
        SourceType: Enum "Price Source Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeletePrices(SourceType::"Job Task", Rec."Job Task No.", Rec."Job No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteItem(var Rec: Record Item; RunTrigger: Boolean);
    var
        AssetType: Enum "Price Asset Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeletePriceLines(AssetType::Item, Rec."No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Discount Group", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteItemDiscountGroup(var Rec: Record "Item Discount Group"; RunTrigger: Boolean);
    var
        AssetType: Enum "Price Asset Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeletePriceLines(AssetType::"Item Discount Group", Rec.Code, '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Variant", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteItemVariant(var Rec: Record "Item Variant"; RunTrigger: Boolean);
    var
        AssetType: Enum "Price Asset Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeletePriceLines(AssetType::Item, Rec."Item No.", Rec.Code);
    end;

    [EventSubscriber(ObjectType::Table, Database::Resource, 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteResource(var Rec: Record Resource; RunTrigger: Boolean);
    var
        AssetType: Enum "Price Asset Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeletePriceLines(AssetType::Resource, Rec."No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Resource Group", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteResourceGroup(var Rec: Record "Resource Group"; RunTrigger: Boolean);
    var
        AssetType: Enum "Price Asset Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeletePriceLines(AssetType::"Resource Group", Rec."No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cost", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteServiceCost(var Rec: Record "Service Cost"; RunTrigger: Boolean);
    var
        AssetType: Enum "Price Asset Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeletePriceLines(AssetType::"Service Cost", Rec.Code, '');
    end;

    [EventSubscriber(ObjectType::Table, Database::Campaign, 'OnAfterModifyEvent', '', false, false)]
    local procedure AfterModifyCampaign(var Rec: Record Campaign; var xRec: Record Campaign; RunTrigger: Boolean);
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            if (Rec."Starting Date" <> xRec."Starting Date") or (Rec."Ending Date" <> xRec."Ending Date") then
                UpdateDates(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::Campaign, 'OnAfterRenameEvent', '', false, false)]
    local procedure AfterRenameCampaign(var Rec: Record Campaign; var xRec: Record Campaign; RunTrigger: Boolean);
    var
        SourceType: Enum "Price Source Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            RenameSourceInPrices(SourceType::Campaign, xRec."No.", Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::Contact, 'OnAfterRenameEvent', '', false, false)]
    local procedure AfterRenameContact(var Rec: Record Contact; var xRec: Record Contact; RunTrigger: Boolean);
    var
        SourceType: Enum "Price Source Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            RenameSourceInPrices(SourceType::Contact, xRec."No.", Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterRenameEvent', '', false, false)]
    local procedure AfterRenameCustomer(var Rec: Record Customer; var xRec: Record Customer; RunTrigger: Boolean);
    var
        SourceType: Enum "Price Source Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            RenameSourceInPrices(SourceType::Customer, xRec."No.", Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer Discount Group", 'OnAfterRenameEvent', '', false, false)]
    local procedure AfterRenameCustomerDiscGroup(var Rec: Record "Customer Discount Group"; var xRec: Record "Customer Discount Group"; RunTrigger: Boolean);
    var
        SourceType: Enum "Price Source Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            RenameSourceInPrices(SourceType::"Customer Disc. Group", xRec.Code, Rec.Code);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer Price Group", 'OnAfterRenameEvent', '', false, false)]
    local procedure AfterRenameCustomerPriceGroup(var Rec: Record "Customer Price Group"; var xRec: Record "Customer Price Group"; RunTrigger: Boolean);
    var
        SourceType: Enum "Price Source Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            RenameSourceInPrices(SourceType::"Customer Price Group", xRec.Code, Rec.Code);
    end;

    [EventSubscriber(ObjectType::Table, Database::"G/L Account", 'OnAfterRenameEvent', '', false, false)]
    local procedure AfterRenameGLAccount(var Rec: Record "G/L Account"; var xRec: Record "G/L Account"; RunTrigger: Boolean);
    var
        AssetType: Enum "Price Asset Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            RenameAssetInPrices(AssetType::"G/L Account", xRec."No.", Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterRenameEvent', '', false, false)]
    local procedure AfterRenameItem(var Rec: Record Item; var xRec: Record Item; RunTrigger: Boolean);
    var
        AssetType: Enum "Price Asset Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            RenameAssetInPrices(AssetType::Item, xRec."No.", Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Discount Group", 'OnAfterRenameEvent', '', false, false)]
    local procedure AfterRenameItemDiscountGroup(var Rec: Record "Item Discount Group"; var xRec: Record "Item Discount Group"; RunTrigger: Boolean);
    var
        AssetType: Enum "Price Asset Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            RenameAssetInPrices(AssetType::"Item Discount Group", xRec.Code, Rec.Code);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Variant", 'OnAfterRenameEvent', '', false, false)]
    local procedure AfterRenameItemVariant(var Rec: Record "Item Variant"; var xRec: Record "Item Variant"; RunTrigger: Boolean);
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            RenameAssetInPrices(Rec."Item No.", xRec.Code, Rec.Code);
    end;

    [EventSubscriber(ObjectType::Table, Database::Resource, 'OnAfterRenameEvent', '', false, false)]
    local procedure AfterRenameResource(var Rec: Record Resource; var xRec: Record Resource; RunTrigger: Boolean);
    var
        AssetType: Enum "Price Asset Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            RenameAssetInPrices(AssetType::Resource, xRec."No.", Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Resource Group", 'OnAfterRenameEvent', '', false, false)]
    local procedure AfterRenameResourceGroup(var Rec: Record "Resource Group"; var xRec: Record "Resource Group"; RunTrigger: Boolean);
    var
        AssetType: Enum "Price Asset Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            RenameAssetInPrices(AssetType::"Resource Group", xRec."No.", Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cost", 'OnAfterRenameEvent', '', false, false)]
    local procedure AfterRenameServiceCost(var Rec: Record "Service Cost"; var xRec: Record "Service Cost"; RunTrigger: Boolean);
    var
        AssetType: Enum "Price Asset Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            RenameAssetInPrices(AssetType::"Service Cost", xRec.Code, Rec.Code);
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnAfterRenameEvent', '', false, false)]
    local procedure AfterRenameVendor(var Rec: Record Vendor; var xRec: Record Vendor; RunTrigger: Boolean);
    var
        SourceType: Enum "Price Source Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            RenameSourceInPrices(SourceType::Vendor, xRec."No.", Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::Job, 'OnAfterRenameEvent', '', false, false)]
    local procedure AfterRenameJob(var Rec: Record Job; var xRec: Record Job; RunTrigger: Boolean);
    var
        SourceType: Enum "Price Source Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then begin
            RenameSourceInPrices(SourceType::Job, xRec."No.", Rec."No.");
            RenameParentSourceInPrices(SourceType::"Job Task", xRec."No.", Rec."No.");
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Task", 'OnAfterRenameEvent', '', false, false)]
    local procedure AfterRenameJobTask(var Rec: Record "Job Task"; var xRec: Record "Job Task"; RunTrigger: Boolean);
    var
        SourceType: Enum "Price Source Type";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            RenameSourceInPrices(SourceType::"Job Task", xRec."Job Task No.", Rec."Job Task No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Job", 'OnBeforeCopyJobPrices', '', false, false)]
    local procedure BeforeCopyJobPrices(var SourceJob: Record Job; var TargetJob: Record Job);
    begin
        CopyJobPrices(SourceJob, TargetJob);
    end;
}