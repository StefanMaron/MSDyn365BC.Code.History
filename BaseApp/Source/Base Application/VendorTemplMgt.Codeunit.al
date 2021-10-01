codeunit 1385 "Vendor Templ. Mgt."
{
    EventSubscriberInstance = StaticAutomatic;

    trigger OnRun()
    begin
    end;

    procedure CreateVendorFromTemplate(var Vendor: Record Vendor; var IsHandled: Boolean) Result: Boolean
    var
        VendorTempl: Record "Vendor Templ.";
    begin
        IsHandled := false;
        OnBeforeCreateVendorFromTemplate(Vendor, Result, IsHandled);
        if IsHandled then
            exit(Result);

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

        OnAfterCreateVendorFromTemplate(Vendor, VendorTempl);
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
        VendorTempl.SetRange("Contact Type", Contact.Type);
        if not SelectVendorTemplate(VendorTempl) then
            exit;

        ApplyVendorTemplate(Vendor, VendorTempl);
    end;

    local procedure ApplyTemplate(var Vendor: Record Vendor; VendorTempl: Record "Vendor Templ.")
    var
        VendorRecRef: RecordRef;
        EmptyVendorRecRef: RecordRef;
        VendorTemplRecRef: RecordRef;
        EmptyVendorTemplRecRef: RecordRef;
        VendorFldRef: FieldRef;
        EmptyVendorFldRef: FieldRef;
        VendorTemplFldRef: FieldRef;
        EmptyVendorTemplFldRef: FieldRef;
        i: Integer;
        FieldExclusionList: List of [Integer];
    begin
        VendorRecRef.GetTable(Vendor);
        EmptyVendorRecRef.Open(Database::Vendor);
        EmptyVendorRecRef.Init();
        VendorTemplRecRef.GetTable(VendorTempl);
        EmptyVendorTemplRecRef.Open(Database::"Vendor Templ.");
        EmptyVendorTemplRecRef.Init();

        FillFieldExclusionList(FieldExclusionList);

        for i := 3 to VendorTemplRecRef.FieldCount do begin
            VendorTemplFldRef := VendorTemplRecRef.FieldIndex(i);
            if TemplateFieldCanBeProcessed(VendorTemplFldRef, FieldExclusionList) then begin
                VendorFldRef := VendorRecRef.Field(VendorTemplFldRef.Number);
                EmptyVendorFldRef := EmptyVendorRecRef.Field(VendorTemplFldRef.Number);
                EmptyVendorTemplFldRef := EmptyVendorTemplRecRef.Field(VendorTemplFldRef.Number);
                if (VendorFldRef.Value = EmptyVendorFldRef.Value) and (VendorTemplFldRef.Value <> EmptyVendorTemplFldRef.Value) then
                    VendorFldRef.Value := VendorTemplFldRef.Value;
            end;
        end;
        VendorRecRef.SetTable(Vendor);
        if VendorTempl."Invoice Disc. Code" <> '' then
            Vendor."Invoice Disc. Code" := VendorTempl."Invoice Disc. Code";
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
        IsHandled := false;
        OnBeforeUpdateFromTemplate(Vendor, IsHandled);
        if IsHandled then
            exit;

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
        IsHandled := false;
        OnBeforeUpdateMultipleFromTemplate(Vendor, IsHandled);
        if IsHandled then
            exit;

        if not CanBeUpdatedFromTemplate(VendorTempl, IsHandled) then
            exit;

        if Vendor.FindSet() then
            repeat
                ApplyVendorTemplate(Vendor, VendorTempl);
            until Vendor.Next() = 0;
    end;

    local procedure CanBeUpdatedFromTemplate(var VendorTempl: Record "Vendor Templ."; var IsHandled: Boolean): Boolean
    begin
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
        IsHandled := false;
        OnBeforeCreateTemplateFromVendor(Vendor, IsHandled);
        if IsHandled then
            exit;

        IsHandled := true;

        InsertTemplateFromVendor(VendorTempl, Vendor);
        InsertDimensions(VendorTempl.Code, Vendor."No.", Database::"Vendor Templ.", Database::Vendor);
        VendorTempl.Get(VendorTempl.Code);
        ShowVendorTemplCard(VendorTempl);
    end;

    local procedure InsertTemplateFromVendor(var VendorTempl: Record "Vendor Templ."; Vendor: Record Vendor)
    var
        SavedVendorTempl: Record "Vendor Templ.";
    begin
        VendorTempl.Init();
        VendorTempl.Code := GetVendorTemplCode();
        SavedVendorTempl := VendorTempl;
        VendorTempl.TransferFields(Vendor);
        VendorTempl.Code := SavedVendorTempl.Code;
        VendorTempl.Description := SavedVendorTempl.Description;
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

    local procedure TemplateFieldCanBeProcessed(TemplateFldRef: FieldRef; FieldExclusionList: List of [Integer]): Boolean
    begin
        exit(not (FieldExclusionList.Contains(TemplateFldRef.Number) or (TemplateFldRef.Number > 2000000000)));
    end;

    local procedure FillFieldExclusionList(var FieldExclusionList: List of [Integer])
    var
        VendorTempl: Record "Vendor Templ.";
    begin
        FieldExclusionList.Add(VendorTempl.FieldNo("Invoice Disc. Code"));
        FieldExclusionList.Add(VendorTempl.FieldNo("No. Series"));
        FieldExclusionList.Add(VendorTempl.FieldNo("Contact Type"));

        OnAfterFillFieldExclusionList(FieldExclusionList);
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateVendorFromTemplate(var Vendor: Record Vendor; VendorTempl: Record "Vendor Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillFieldExclusionList(var FieldExclusionList: List of [Integer])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateVendorFromTemplate(var Vendor: Record Vendor; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateFromTemplate(var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateMultipleFromTemplate(var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTemplateFromVendor(Vendor: Record Vendor; var IsHandled: Boolean)
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