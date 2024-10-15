﻿codeunit 1385 "Vendor Templ. Mgt."
{
    EventSubscriberInstance = StaticAutomatic;

    trigger OnRun()
    begin
    end;

    procedure CreateVendorFromTemplate(var Vendor: Record Vendor; var IsHandled: Boolean): Boolean
    var
        VendorTempl: Record "Vendor Templ.";
    begin
        if not IsEnabled() then
            exit(false);

        IsHandled := true;

        if not SelectVendorTemplate(VendorTempl) then
            exit(false);

        Vendor.SetInsertFromTemplate(true);
        Vendor.Init();
        Vendor.Insert(true);
        Vendor.SetInsertFromTemplate(false);

        ApplyVendorTemplate(Vendor, VendorTempl);

        exit(true);
    end;

    procedure ApplyVendorTemplate(var Vendor: Record Vendor; VendorTempl: Record "Vendor Templ.")
    begin
        ApplyTemplate(Vendor, VendorTempl);
        InsertDimensions(Vendor."No.", VendorTempl.Code);
    end;

    [Obsolete('Replaced by ApplyVendorTemplate with different set of parameters', '18.0')]
    procedure ApplyContactVendorTemplate(var Vendor: Record Vendor; Contact: Record Contact)
    var
        VendorTempl: Record "Vendor Templ.";
    begin
        if not IsEnabled() then
            exit;

        VendorTempl.SetRange("Contact Type", Contact.Type);
        if not SelectVendorTemplate(VendorTempl) then
            exit;

        ApplyVendorTemplate(Vendor, VendorTempl);
    end;

    local procedure ApplyTemplate(var Vendor: Record Vendor; VendorTempl: Record "Vendor Templ.")
    begin
        Vendor.City := VendorTempl.City;
        Vendor."Vendor Posting Group" := VendorTempl."Vendor Posting Group";
        Vendor."Currency Code" := VendorTempl."Currency Code";
        Vendor."Language Code" := VendorTempl."Language Code";
        Vendor."Payment Terms Code" := VendorTempl."Payment Terms Code";
        Vendor."Fin. Charge Terms Code" := VendorTempl."Fin. Charge Terms Code";
        Vendor."Invoice Disc. Code" := VendorTempl."Invoice Disc. Code";
        Vendor."Country/Region Code" := VendorTempl."Country/Region Code";
        Vendor."Pay-to Vendor No." := VendorTempl."Pay-to Vendor No.";
        Vendor."Payment Method Code" := VendorTempl."Payment Method Code";
        Vendor."Application Method" := VendorTempl."Application Method".AsInteger();
        Vendor."Prices Including VAT" := VendorTempl."Prices Including VAT";
        Vendor."Gen. Bus. Posting Group" := VendorTempl."Gen. Bus. Posting Group";
        Vendor."Post Code" := VendorTempl."Post Code";
        Vendor.County := VendorTempl.County;
        Vendor."VAT Bus. Posting Group" := VendorTempl."VAT Bus. Posting Group";
        Vendor."Block Payment Tolerance" := VendorTempl."Block Payment Tolerance";
        Vendor."Validate EU Vat Reg. No." := VendorTempl."Validate EU Vat Reg. No.";
        Vendor.Blocked := VendorTempl.Blocked;
        OnApplyTemplateOnBeforeVendorModify(Vendor, VendorTempl);
        Vendor.Modify(true);
    end;

    procedure SelectVendorTemplateFromContact(var VendorTempl: Record "Vendor Templ."; Contact: Record Contact): Boolean
    begin
        VendorTempl.SetRange("Contact Type", Contact.Type);
        exit(SelectVendorTemplate(VendorTempl));
    end;

    local procedure SelectVendorTemplate(var VendorTempl: Record "Vendor Templ."): Boolean
    var
        SelectVendorTemplList: Page "Select Vendor Templ. List";
    begin
        if VendorTempl.Count = 1 then begin
            VendorTempl.FindFirst();
            exit(true);
        end;

        if (VendorTempl.Count > 1) and GuiAllowed then begin
            SelectVendorTemplList.SetTableView(VendorTempl);
            SelectVendorTemplList.LookupMode(true);
            if SelectVendorTemplList.RunModal() = Action::LookupOK then begin
                SelectVendorTemplList.GetRecord(VendorTempl);
                exit(true);
            end;
        end;

        exit(false);
    end;

    local procedure InsertDimensions(VendorNo: Code[20]; VendorTemplCode: Code[20])
    var
        SourceDefaultDimension: Record "Default Dimension";
        DestDefaultDimension: Record "Default Dimension";
    begin
        SourceDefaultDimension.SetRange("Table ID", Database::"Vendor Templ.");
        SourceDefaultDimension.SetRange("No.", VendorTemplCode);
        if SourceDefaultDimension.FindSet() then
            repeat
                DestDefaultDimension.Init();
                DestDefaultDimension.Validate("Table ID", Database::Vendor);
                DestDefaultDimension.Validate("No.", VendorNo);
                DestDefaultDimension.Validate("Dimension Code", SourceDefaultDimension."Dimension Code");
                DestDefaultDimension.Validate("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
                DestDefaultDimension.Validate("Value Posting", SourceDefaultDimension."Value Posting");
                if not DestDefaultDimension.Get(DestDefaultDimension."Table ID", DestDefaultDimension."No.", DestDefaultDimension."Dimension Code") then
                    DestDefaultDimension.Insert(true);
            until SourceDefaultDimension.Next() = 0;
    end;

    procedure VendorTemplatesAreNotEmpty(var IsHandled: Boolean): Boolean
    var
        VendorTempl: Record "Vendor Templ.";
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        if not TemplateFeatureMgt.IsEnabled() then
            exit(false);

        IsHandled := true;
        exit(not VendorTempl.IsEmpty);
    end;

    procedure InsertVendorFromTemplate(var Vendor: Record Vendor) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnInsertVendorFromTemplate(Vendor, Result, IsHandled);
    end;

    procedure TemplatesAreNotEmpty() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnTemplatesAreNotEmpty(Result, IsHandled);
    end;

    procedure IsEnabled() Result: Boolean
    var
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        Result := TemplateFeatureMgt.IsEnabled();

        OnAfterIsEnabled(Result);
    end;

    procedure UpdateVendorFromTemplate(var Vendor: Record Vendor)
    var
        IsHandled: Boolean;
    begin
        OnUpdateVendorFromTemplate(Vendor, IsHandled);
    end;

    local procedure UpdateFromTemplate(var Vendor: Record Vendor; var IsHandled: Boolean)
    var
        VendorTempl: Record "Vendor Templ.";
    begin
        if not CanBeUpdatedFromTemplate(VendorTempl, IsHandled) then
            exit;

        ApplyVendorTemplate(Vendor, VendorTempl);
    end;

    procedure UpdateVendorsFromTemplate(var Vendor: Record Vendor)
    var
        IsHandled: Boolean;
    begin
        OnUpdateVendorsFromTemplate(Vendor, IsHandled);
    end;

    local procedure UpdateMultipleFromTemplate(var Vendor: Record Vendor; var IsHandled: Boolean)
    var
        VendorTempl: Record "Vendor Templ.";
    begin
        if not CanBeUpdatedFromTemplate(VendorTempl, IsHandled) then
            exit;

        if Vendor.FindSet() then
            repeat
                ApplyVendorTemplate(Vendor, VendorTempl);
            until Vendor.Next() = 0;
    end;

    local procedure CanBeUpdatedFromTemplate(var VendorTempl: Record "Vendor Templ."; var IsHandled: Boolean): Boolean
    begin
        if not IsEnabled() then
            exit(false);

        IsHandled := true;

        if not SelectVendorTemplate(VendorTempl) then
            exit(false);

        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsEnabled(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyTemplateOnBeforeVendorModify(var Vendor: Record Vendor; VendorTempl: Record "Vendor Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVendorFromTemplate(var Vendor: Record Vendor; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTemplatesAreNotEmpty(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVendorFromTemplate(var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVendorsFromTemplate(var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Templ. Mgt.", 'OnInsertVendorFromTemplate', '', false, false)]
    local procedure OnInsertVendorFromTemplateHandler(var Vendor: Record Vendor; var Result: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        Result := CreateVendorFromTemplate(Vendor, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Templ. Mgt.", 'OnTemplatesAreNotEmpty', '', false, false)]
    local procedure OnTemplatesAreNotEmptyHandler(var Result: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        Result := VendorTemplatesAreNotEmpty(IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Templ. Mgt.", 'OnUpdateVendorFromTemplate', '', false, false)]
    local procedure OnUpdateVendorFromTemplateHandler(var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        UpdateFromTemplate(Vendor, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Templ. Mgt.", 'OnUpdateVendorsFromTemplate', '', false, false)]
    local procedure OnUpdateVendorsFromTemplateHandler(var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        UpdateMultipleFromTemplate(Vendor, IsHandled);
    end;
}