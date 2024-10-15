﻿table 99 "Item Vendor"
{
    Caption = 'Item Vendor';
    LookupPageID = "Item Vendor Catalog";

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item;
        }
        field(2; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            NotBlank = true;
            TableRelation = Vendor;

            trigger OnValidate()
            begin
                Vend.Get("Vendor No.");
                "Lead Time Calculation" := Vend."Lead Time Calculation";
            end;
        }
        field(6; "Lead Time Calculation"; DateFormula)
        {
            Caption = 'Lead Time Calculation';

            trigger OnValidate()
            begin
                LeadTimeMgt.CheckLeadTimeIsNotNegative("Lead Time Calculation");
            end;
        }
        field(7; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';

            trigger OnValidate()
            begin
                UpdateItemCrossReference();
            end;
        }
        field(5700; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
    }

    keys
    {
        key(Key1; "Vendor No.", "Item No.", "Variant Code")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Variant Code", "Vendor No.")
        {
        }
        key(Key3; "Vendor No.", "Vendor Item No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Vendor No.", "Item No.", "Variant Code")
        {
        }
    }

    trigger OnDelete()
    begin
        if ItemReferenceMgt.IsEnabled() then
            DeleteItemReference()
        else
            DeleteItemCrossReference();
    end;

    trigger OnInsert()
    begin
        if ItemReferenceMgt.IsEnabled() then
            InsertItemReference()
        else
            InsertItemCrossReference();
    end;

    trigger OnModify()
    begin
        if ItemReferenceMgt.IsEnabled() then
            UpdateItemReference()
        else
            UpdateItemCrossReference();
    end;

    trigger OnRename()
    begin
        if ItemReferenceMgt.IsEnabled() then
            UpdateItemReference()
        else
            UpdateItemCrossReference();
    end;

    var
        Vend: Record Vendor;
        LeadTimeMgt: Codeunit "Lead-Time Management";
        ItemReferencemgt: Codeunit "Item Reference Management";

    local procedure InsertItemReference()
    var
        ItemReference: Record "Item Reference";
    begin
        if ItemReference.WritePermission then
            if ("Vendor No." <> '') and ("Item No." <> '') then
                ItemReferenceMgt.InsertItemReference(Rec);
    end;

    local procedure DeleteItemReference()
    var
        ItemReference: Record "Item Reference";
    begin
        if ItemReference.WritePermission then
            if ("Vendor No." <> '') and ("Item No." <> '') then
                ItemReferenceMgt.DeleteItemReference(Rec);
    end;

    local procedure UpdateItemReference()
    var
        ItemReference: Record "Item Reference";
    begin
        if ItemReference.WritePermission then
            if ("Vendor No." <> '') and ("Item No." <> '') then
                if ("Vendor No." <> xRec."Vendor No.") or ("Item No." <> xRec."Item No.") or
                   ("Variant Code" <> xRec."Variant Code") or ("Vendor Item No." <> xRec."Vendor Item No.")
                then
                    ItemReferenceMgt.UpdateItemReference(Rec, xRec);
    end;

    local procedure InsertItemCrossReference()
    var
        ItemCrossReference: Record "Item Cross Reference";
        DistIntegration: Codeunit "Dist. Integration";
    begin
        if ItemCrossReference.WritePermission then
            if ("Vendor No." <> '') and ("Item No." <> '') then
                DistIntegration.InsertItemCrossReference(Rec);
    end;

    local procedure DeleteItemCrossReference()
    var
        ItemCrossReference: Record "Item Cross Reference";
        DistIntegration: Codeunit "Dist. Integration";
    begin
        if ItemCrossReference.WritePermission then
            if ("Vendor No." <> '') and ("Item No." <> '') then
                DistIntegration.DeleteItemCrossReference(Rec);
    end;

    local procedure UpdateItemCrossReference()
    var
        ItemCrossReference: Record "Item Cross Reference";
        DistIntegration: Codeunit "Dist. Integration";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateItemCrossReference(Rec, IsHandled, xRec);
        if IsHandled then
            exit;

        if ItemCrossReference.WritePermission then
            if ("Vendor No." <> '') and ("Item No." <> '') then
                if ("Vendor No." <> xRec."Vendor No.") or ("Item No." <> xRec."Item No.") or
                   ("Variant Code" <> xRec."Variant Code") or ("Vendor Item No." <> xRec."Vendor Item No.")
                then
                    DistIntegration.UpdateItemCrossReference(Rec, xRec);
    end;

    local procedure ToPriceAsset(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset.Init();
        PriceAsset."Asset Type" := PriceAsset."Asset Type"::Item;
        PriceAsset."Asset No." := Rec."Item No.";
        PriceAsset."Variant Code" := Rec."Variant Code";
    end;

    local procedure ToPriceSource(var PriceSource: Record "Price Source")
    begin
        PriceSource.Init();
        PriceSource."Price Type" := "Price Type"::Purchase;
        PriceSource.Validate("Source Type", PriceSource."Source Type"::Vendor);
        PriceSource."Source No." := Rec."Vendor No.";
    end;

    procedure ShowPriceListLines(PriceAmountType: Enum "Price Amount Type")
    var
        PriceAsset: Record "Price Asset";
        PriceSource: Record "Price Source";
        PriceUXManagement: Codeunit "Price UX Management";
    begin
        ToPriceAsset(PriceAsset);
        ToPriceSource(PriceSource);
        PriceUXManagement.ShowPriceListLines(PriceSource, PriceAsset, PriceAmountType);
    end;

    procedure FindLeadTimeCalculation(Item: Record Item; var SKU: Record "Stockkeeping Unit"; LocationCode: Code[10])
    var
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindLeadTimeCalculation(Rec, Item, LocationCode, IsHandled);
        if IsHandled then
            exit;

        if Format("Lead Time Calculation") = '' then begin
            GetPlanningParameters.AtSKU(SKU, Item."No.", "Variant Code", LocationCode);
            "Lead Time Calculation" := SKU."Lead Time Calculation";
            if Format("Lead Time Calculation") = '' then
                if Vend.Get("Vendor No.") then
                    "Lead Time Calculation" := Vend."Lead Time Calculation";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindLeadTimeCalculation(var ItemVendor: Record "Item Vendor"; Item: Record Item; LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateItemCrossReference(var ItemVendor: Record "Item Vendor"; var IsHandled: Boolean; var xItemVendor: Record "Item Vendor")
    begin
    end;
}

