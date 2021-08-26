codeunit 1385 "Vendor Templ. Mgt."
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

        OnCreateVendorFromTemplateOnBeforeSelectVendorTemplate(Vendor, VendorTempl);
        if not SelectVendorTemplate(VendorTempl) then
            exit(false);

        Vendor.SetInsertFromTemplate(true);
        Vendor.Init();
        InitVendorNo(Vendor, VendorTempl);
        Vendor.Insert(true);
        Vendor.SetInsertFromTemplate(false);

        ApplyVendorTemplate(Vendor, VendorTempl);

        exit(true);
    end;

    procedure ApplyVendorTemplate(var Vendor: Record Vendor; VendorTempl: Record "Vendor Templ.")
    begin
        ApplyTemplate(Vendor, VendorTempl);
        InsertDimensions(Vendor."No.", VendorTempl.Code, Database::Vendor, Database::"Vendor Templ.");
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
        if (VendorTempl.City <> '') and (Vendor.City = '') then
            Vendor.City := VendorTempl.City;
        Vendor."Vendor Posting Group" := VendorTempl."Vendor Posting Group";
        if (VendorTempl."Currency Code" <> '') and (Vendor."Currency Code" = '') then
            Vendor."Currency Code" := VendorTempl."Currency Code";
        if (VendorTempl."Language Code" <> '') and (Vendor."Language Code" = '') then
            Vendor."Language Code" := VendorTempl."Language Code";
        Vendor."Payment Terms Code" := VendorTempl."Payment Terms Code";
        Vendor."Fin. Charge Terms Code" := VendorTempl."Fin. Charge Terms Code";
        Vendor."Invoice Disc. Code" := VendorTempl."Invoice Disc. Code";
        if (VendorTempl."Country/Region Code" <> '') and (Vendor."Country/Region Code" = '') then
            Vendor."Country/Region Code" := VendorTempl."Country/Region Code";
        Vendor."Pay-to Vendor No." := VendorTempl."Pay-to Vendor No.";
        Vendor."Payment Method Code" := VendorTempl."Payment Method Code";
        Vendor."Application Method" := VendorTempl."Application Method";
        Vendor."Prices Including VAT" := VendorTempl."Prices Including VAT";
        Vendor."Gen. Bus. Posting Group" := VendorTempl."Gen. Bus. Posting Group";
        if (VendorTempl."Post Code" <> '') and (Vendor."Post Code" = '') then
            Vendor."Post Code" := VendorTempl."Post Code";
        if (VendorTempl.County <> '') and (Vendor.County = '') then
            Vendor.County := VendorTempl.County;
        Vendor."VAT Bus. Posting Group" := VendorTempl."VAT Bus. Posting Group";
        Vendor."Block Payment Tolerance" := VendorTempl."Block Payment Tolerance";
        Vendor."Validate EU Vat Reg. No." := VendorTempl."Validate EU Vat Reg. No.";
        Vendor.Blocked := VendorTempl.Blocked;
        Vendor."Document Sending Profile" := VendorTempl."Document Sending Profile";
        Vendor."Partner Type" := VendorTempl."Partner Type";
        Vendor."Location Code" := VendorTempl."Location Code";
        Vendor."Shipment Method Code" := VendorTempl."Shipment Method Code";
        OnApplyTemplateOnBeforeVendorModify(Vendor, VendorTempl);
        Vendor.Modify(true);
    end;

    procedure SelectVendorTemplateFromContact(var VendorTempl: Record "Vendor Templ."; Contact: Record Contact): Boolean
    begin
        OnBeforeSelectVendorTemplateFromContact(VendorTempl, Contact);

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

    local procedure InsertDimensions(DestNo: Code[20]; SourceNo: Code[20]; DestTableId: Integer; SourceTableId: Integer)
    var
        SourceDefaultDimension: Record "Default Dimension";
        DestDefaultDimension: Record "Default Dimension";
    begin
        SourceDefaultDimension.SetRange("Table ID", SourceTableId);
        SourceDefaultDimension.SetRange("No.", SourceNo);
        if SourceDefaultDimension.FindSet() then
            repeat
                DestDefaultDimension.Init();
                DestDefaultDimension.Validate("Table ID", DestTableId);
                DestDefaultDimension.Validate("No.", DestNo);
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

    procedure SaveAsTemplate(Vendor: Record Vendor)
    var
        IsHandled: Boolean;
    begin
        OnSaveAsTemplate(Vendor, IsHandled);
    end;

    procedure CreateTemplateFromVendor(Vendor: Record Vendor; var IsHandled: Boolean)
    var
        VendorTempl: Record "Vendor Templ.";
    begin
        if not IsEnabled() then
            exit;

        IsHandled := true;

        InsertTemplateFromVendor(VendorTempl, Vendor);
        InsertDimensions(VendorTempl.Code, Vendor."No.", Database::"Vendor Templ.", Database::Vendor);
        VendorTempl.Get(VendorTempl.Code);
        ShowVendorTemplCard(VendorTempl);
    end;

    local procedure InsertTemplateFromVendor(var VendorTempl: Record "Vendor Templ."; Vendor: Record Vendor)
    begin
        VendorTempl.Init();
        VendorTempl.Code := GetVendorTemplCode();

        VendorTempl.City := Vendor.City;
        VendorTempl."Vendor Posting Group" := Vendor."Vendor Posting Group";
        VendorTempl."Currency Code" := Vendor."Currency Code";
        VendorTempl."Language Code" := Vendor."Language Code";
        VendorTempl."Payment Terms Code" := Vendor."Payment Terms Code";
        VendorTempl."Fin. Charge Terms Code" := Vendor."Fin. Charge Terms Code";
        VendorTempl."Invoice Disc. Code" := Vendor."Invoice Disc. Code";
        VendorTempl."Country/Region Code" := Vendor."Country/Region Code";
        VendorTempl."Pay-to Vendor No." := Vendor."Pay-to Vendor No.";
        VendorTempl."Payment Method Code" := Vendor."Payment Method Code";
        VendorTempl."Application Method" := Vendor."Application Method";
        VendorTempl."Prices Including VAT" := Vendor."Prices Including VAT";
        VendorTempl."Gen. Bus. Posting Group" := Vendor."Gen. Bus. Posting Group";
        VendorTempl."Post Code" := Vendor."Post Code";
        VendorTempl.County := Vendor.County;
        VendorTempl."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        VendorTempl."Block Payment Tolerance" := Vendor."Block Payment Tolerance";
        VendorTempl."Validate EU Vat Reg. No." := Vendor."Validate EU Vat Reg. No.";
        VendorTempl.Blocked := Vendor.Blocked;
        VendorTempl."Document Sending Profile" := Vendor."Document Sending Profile";
        VendorTempl."Partner Type" := Vendor."Partner Type";
        VendorTempl."Location Code" := Vendor."Location Code";
        VendorTempl."Shipment Method Code" := Vendor."Shipment Method Code";
        OnInsertTemplateFromVendorOnBeforeVendorTemplInsert(VendorTempl, Vendor);
        VendorTempl.Insert();
    end;

    local procedure GetVendorTemplCode() VendorTemplCode: Code[20]
    var
        Vendor: Record Vendor;
        VendorTempl: Record "Vendor Templ.";
    begin
        if VendorTempl.FindLast() and (IncStr(VendorTempl.Code) <> '') then
            VendorTemplCode := VendorTempl.Code
        else
            VendorTemplCode := CopyStr(Vendor.TableCaption, 1, 4) + '000001';

        while VendorTempl.Get(VendorTemplCode) do
            VendorTemplCode := IncStr(VendorTemplCode);
    end;

    local procedure ShowVendorTemplCard(VendorTempl: Record "Vendor Templ.")
    var
        VendorTemplCard: Page "Vendor Templ. Card";
    begin
        if not GuiAllowed then
            exit;

        Commit();
        VendorTemplCard.SetRecord(VendorTempl);
        VendorTemplCard.LookupMode := true;
        if VendorTemplCard.RunModal() = Action::LookupCancel then begin
            VendorTempl.Get(VendorTempl.Code);
            VendorTempl.Delete(true);
        end;
    end;

    procedure ShowTemplates()
    var
        IsHandled: Boolean;
    begin
        OnShowTemplates(IsHandled);
    end;

    local procedure ShowVendorTemplList(var IsHandled: Boolean)
    begin
        if not IsEnabled() then
            exit;

        IsHandled := true;
        Page.Run(Page::"Vendor Templ. List");
    end;

    local procedure InitVendorNo(var Vendor: Record Vendor; VendorTempl: Record "Vendor Templ.")
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        if VendorTempl."No. Series" = '' then
            exit;

        NoSeriesManagement.InitSeries(VendorTempl."No. Series", '', 0D, Vendor."No.", Vendor."No. Series");
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
    local procedure OnBeforeSelectVendorTemplateFromContact(var VendorTempl: Record "Vendor Templ."; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateVendorFromTemplateOnBeforeSelectVendorTemplate(Vendor: Record Vendor; var VendorTempl: Record "Vendor Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVendorFromTemplate(var Vendor: Record Vendor; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTemplateFromVendorOnBeforeVendorTemplInsert(var VendorTempl: Record "Vendor Templ."; Vendor: Record Vendor)
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

    [IntegrationEvent(false, false)]
    local procedure OnSaveAsTemplate(Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowTemplates(var IsHandled: Boolean)
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Templ. Mgt.", 'OnSaveAsTemplate', '', false, false)]
    local procedure OnSaveAsTemplateHandler(Vendor: Record Vendor; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        CreateTemplateFromVendor(Vendor, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Templ. Mgt.", 'OnShowTemplates', '', false, false)]
    local procedure OnShowTemplatesHandler(var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        ShowVendorTemplList(IsHandled);
    end;
}