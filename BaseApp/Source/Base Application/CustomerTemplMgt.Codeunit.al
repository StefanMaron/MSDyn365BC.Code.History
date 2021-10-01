codeunit 1381 "Customer Templ. Mgt."
{
    trigger OnRun()
    begin
    end;

#if not CLEAN19
    var
        TemplatesDisabledTxt: Label 'Contact conversion templates are being replaced by customer templates to avoid duplication. We have migrated your existing contact conversion templates to customer templates. Going forward, use only customer templates. Contact conversion templates are no longer used.';
        LearnMoreTxt: Label 'Learn more';
        LearnMoreUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2171036', Locked = true;
        OpenPageTxt: Label 'Open the %1 page', Comment = '%1 = page caption';
#endif

    procedure CreateCustomerFromTemplate(var Customer: Record Customer; var IsHandled: Boolean) Result: Boolean
    var
        CustomerTempl: Record "Customer Templ.";
    begin
        IsHandled := false;
        OnBeforeCreateCustomerFromTemplate(Customer, Result, IsHandled);
        if IsHandled then
            exit(Result);

        IsHandled := true;

        if not SelectCustomerTemplate(CustomerTempl) then
            exit(false);

        Customer.SetInsertFromTemplate(true);
        Customer.Init();
        InitCustomerNo(Customer, CustomerTempl);
        Customer."Contact Type" := CustomerTempl."Contact Type";
        Customer.Insert(true);
        Customer.SetInsertFromTemplate(false);

        ApplyCustomerTemplate(Customer, CustomerTempl);

        OnAfterCreateCustomerFromTemplate(Customer, CustomerTempl);
        exit(true);
    end;

#if not CLEAN18
    [Obsolete('Function is not used and not required.', '18.0')]
    procedure InsertCustomerFromContact(var Customer: Record Customer; Contact: Record Contact): Boolean
    var
        CustomerTempl: Record "Customer Templ.";
    begin
        if not IsEnabled() then
            exit(false);

        CustomerTempl.SetRange("Contact Type", Contact.Type);
        if not SelectCustomerTemplate(CustomerTempl) then
            exit(false);

        Customer.SetInsertFromContact(true);
        Customer.Init();
        Customer.Insert(true);
        Customer.SetInsertFromContact(false);

        ApplyTemplate(Customer, CustomerTempl);
        InsertDimensions(Customer."No.", CustomerTempl.Code, Database::Customer, Database::"Customer Templ.");

        exit(true);
    end;
#endif

    procedure ApplyCustomerTemplate(var Customer: Record Customer; CustomerTempl: Record "Customer Templ.")
    begin
        ApplyTemplate(Customer, CustomerTempl);
        InsertDimensions(Customer."No.", CustomerTempl.Code, Database::Customer, Database::"Customer Templ.");
    end;

    local procedure ApplyTemplate(var Customer: Record Customer; CustomerTempl: Record "Customer Templ.")
    var
        CustomerRecRef: RecordRef;
        EmptyCustomerRecRef: RecordRef;
        CustomerTemplRecRef: RecordRef;
        EmptyCustomerTemplRecRef: RecordRef;
        CustomerFldRef: FieldRef;
        EmptyCustomerFldRef: FieldRef;
        CustomerTemplFldRef: FieldRef;
        EmptyCustomerTemplFldRef: FieldRef;
        IsHandled: Boolean;
        i: Integer;
        FieldExclusionList: List of [Integer];
    begin
        IsHandled := false;
        OnBeforeApplyTemplate(Customer, CustomerTempl, IsHandled);
        if IsHandled then
            exit;

        CustomerRecRef.GetTable(Customer);
        EmptyCustomerRecRef.Open(Database::Customer);
        EmptyCustomerRecRef.Init();
        CustomerTemplRecRef.GetTable(CustomerTempl);
        EmptyCustomerTemplRecRef.Open(Database::"Customer Templ.");
        EmptyCustomerTemplRecRef.Init();

        FillFieldExclusionList(FieldExclusionList);

        for i := 3 to CustomerTemplRecRef.FieldCount do begin
            CustomerTemplFldRef := CustomerTemplRecRef.FieldIndex(i);
            if TemplateFieldCanBeProcessed(CustomerTemplFldRef, FieldExclusionList) then begin
                CustomerFldRef := CustomerRecRef.Field(CustomerTemplFldRef.Number);
                EmptyCustomerFldRef := EmptyCustomerRecRef.Field(CustomerTemplFldRef.Number);
                EmptyCustomerTemplFldRef := EmptyCustomerTemplRecRef.Field(CustomerTemplFldRef.Number);
                if (CustomerFldRef.Value = EmptyCustomerFldRef.Value) and (CustomerTemplFldRef.Value <> EmptyCustomerTemplFldRef.Value) then
                    CustomerFldRef.Value := CustomerTemplFldRef.Value;
            end;
        end;
        CustomerRecRef.SetTable(Customer);
        if CustomerTempl."Invoice Disc. Code" <> '' then
            Customer."Invoice Disc. Code" := CustomerTempl."Invoice Disc. Code";
        OnApplyTemplateOnBeforeCustomerModify(Customer, CustomerTempl);
        Customer.Modify(true);
    end;

    procedure SelectCustomerTemplateFromContact(var CustomerTempl: Record "Customer Templ."; Contact: Record Contact): Boolean
    begin
        OnBeforeSelectCustomerTemplateFromContact(CustomerTempl, Contact);

        CustomerTempl.SetRange("Contact Type", Contact.Type);
        exit(SelectCustomerTemplate(CustomerTempl));
    end;

    procedure SelectCustomerTemplate(var CustomerTempl: Record "Customer Templ.") Result: Boolean
    var
        SelectCustomerTemplList: Page "Select Customer Templ. List";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectCustomerTemplate(CustomerTempl, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if CustomerTempl.Count = 1 then begin
            CustomerTempl.FindFirst();
            exit(true);
        end;

        if (CustomerTempl.Count > 1) and GuiAllowed then begin
            SelectCustomerTemplList.SetTableView(CustomerTempl);
            SelectCustomerTemplList.LookupMode(true);
            if SelectCustomerTemplList.RunModal() = Action::LookupOK then begin
                SelectCustomerTemplList.GetRecord(CustomerTempl);
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

    procedure CustomerTemplatesAreNotEmpty(var IsHandled: Boolean): Boolean
    var
        CustomerTempl: Record "Customer Templ.";
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        if not TemplateFeatureMgt.IsEnabled() then
            exit(false);

        IsHandled := true;
        exit(not CustomerTempl.IsEmpty);
    end;

    procedure InsertCustomerFromTemplate(var Customer: Record Customer) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnInsertCustomerFromTemplate(Customer, Result, IsHandled);
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

    procedure UpdateCustomerFromTemplate(var Customer: Record Customer)
    var
        IsHandled: Boolean;
    begin
        OnUpdateCustomerFromTemplate(Customer, IsHandled);
    end;

    local procedure UpdateFromTemplate(var Customer: Record Customer; var IsHandled: Boolean)
    var
        CustomerTempl: Record "Customer Templ.";
    begin
        IsHandled := false;
        OnBeforeUpdateFromTemplate(Customer, IsHandled);
        if IsHandled then
            exit;

        if not CanBeUpdatedFromTemplate(CustomerTempl, IsHandled) then
            exit;

        ApplyCustomerTemplate(Customer, CustomerTempl);
    end;

    procedure UpdateCustomersFromTemplate(var Customer: Record Customer)
    var
        IsHandled: Boolean;
    begin
        OnUpdateCustomersFromTemplate(Customer, IsHandled);
    end;

    local procedure UpdateMultipleFromTemplate(var Customer: Record Customer; var IsHandled: Boolean)
    var
        CustomerTempl: Record "Customer Templ.";
    begin
        IsHandled := false;
        OnBeforeUpdateMultipleFromTemplate(Customer, IsHandled);
        if IsHandled then
            exit;

        if not CanBeUpdatedFromTemplate(CustomerTempl, IsHandled) then
            exit;

        if Customer.FindSet() then
            repeat
                ApplyCustomerTemplate(Customer, CustomerTempl);
            until Customer.Next() = 0;
    end;

    local procedure CanBeUpdatedFromTemplate(var CustomerTempl: Record "Customer Templ."; var IsHandled: Boolean): Boolean
    begin
        IsHandled := true;

        if not SelectCustomerTemplate(CustomerTempl) then
            exit(false);

        exit(true);
    end;

    procedure SaveAsTemplate(Customer: Record Customer)
    var
        IsHandled: Boolean;
    begin
        OnSaveAsTemplate(Customer, IsHandled);
    end;

    procedure CreateTemplateFromCustomer(Customer: Record Customer; var IsHandled: Boolean)
    var
        CustomerTempl: Record "Customer Templ.";
    begin
        IsHandled := false;
        OnBeforeCreateTemplateFromCustomer(Customer, IsHandled);
        if IsHandled then
            exit;

        IsHandled := true;

        InsertTemplateFromCustomer(CustomerTempl, Customer);
        InsertDimensions(CustomerTempl.Code, Customer."No.", Database::"Customer Templ.", Database::Customer);
        CustomerTempl.Get(CustomerTempl.Code);
        ShowCustomerTemplCard(CustomerTempl);
    end;

    local procedure InsertTemplateFromCustomer(var CustomerTempl: Record "Customer Templ."; Customer: Record Customer)
    var
        SavedCustomerTempl: Record "Customer Templ.";
    begin
        CustomerTempl.Init();
        CustomerTempl.Code := GetCustomerTemplCode();
        SavedCustomerTempl := CustomerTempl;
        CustomerTempl.TransferFields(Customer);
        CustomerTempl.Code := SavedCustomerTempl.Code;
        CustomerTempl.Description := SavedCustomerTempl.Description;
        CustomerTempl.Insert();
    end;

    local procedure GetCustomerTemplCode() CustomerTemplCode: Code[20]
    var
        Customer: Record Customer;
        CustomerTempl: Record "Customer Templ.";
    begin
        if CustomerTempl.FindLast() and (IncStr(CustomerTempl.Code) <> '') then
            CustomerTemplCode := CustomerTempl.Code
        else
            CustomerTemplCode := CopyStr(Customer.TableCaption, 1, 4) + '000001';

        while CustomerTempl.Get(CustomerTemplCode) do
            CustomerTemplCode := IncStr(CustomerTemplCode);
    end;

    local procedure ShowCustomerTemplCard(CustomerTempl: Record "Customer Templ.")
    var
        CustomerTemplCard: Page "Customer Templ. Card";
    begin
        if not GuiAllowed then
            exit;

        Commit();
        CustomerTemplCard.SetRecord(CustomerTempl);
        CustomerTemplCard.LookupMode := true;
        if CustomerTemplCard.RunModal() = Action::LookupCancel then begin
            CustomerTempl.Get(CustomerTempl.Code);
            CustomerTempl.Delete(true);
        end;
    end;

    procedure ShowTemplates()
    var
        IsHandled: Boolean;
    begin
        OnShowTemplates(IsHandled);
    end;

    local procedure ShowCustomerTemplList(var IsHandled: Boolean)
    begin
        IsHandled := true;
        Page.Run(Page::"Customer Templ. List");
    end;

    local procedure InitCustomerNo(var Customer: Record Customer; CustomerTempl: Record "Customer Templ.")
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        if CustomerTempl."No. Series" = '' then
            exit;

        NoSeriesManagement.InitSeries(CustomerTempl."No. Series", '', 0D, Customer."No.", Customer."No. Series");
    end;

    local procedure TemplateFieldCanBeProcessed(TemplateFldRef: FieldRef; FieldExclusionList: List of [Integer]): Boolean
    begin
        exit(not (FieldExclusionList.Contains(TemplateFldRef.Number) or (TemplateFldRef.Number > 2000000000)));
    end;

    local procedure FillFieldExclusionList(var FieldExclusionList: List of [Integer])
    var
        CustomerTempl: Record "Customer Templ.";
    begin
        FieldExclusionList.Add(CustomerTempl.FieldNo("Invoice Disc. Code"));
        FieldExclusionList.Add(CustomerTempl.FieldNo("No. Series"));

        OnAfterFillFieldExclusionList(FieldExclusionList);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsEnabled(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyTemplateOnBeforeCustomerModify(var Customer: Record Customer; CustomerTempl: Record "Customer Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyTemplate(var Customer: Record Customer; CustomerTempl: Record "Customer Templ."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectCustomerTemplateFromContact(var CustomerTempl: Record "Customer Templ."; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCustomerFromTemplate(var Customer: Record Customer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTemplatesAreNotEmpty(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustomerFromTemplate(var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustomersFromTemplate(var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveAsTemplate(Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowTemplates(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCustomerFromTemplate(var Customer: Record Customer; CustomerTempl: Record "Customer Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectCustomerTemplate(var CustomerTempl: Record "Customer Templ."; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillFieldExclusionList(var FieldExclusionList: List of [Integer])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCustomerFromTemplate(var Customer: Record Customer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateFromTemplate(var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateMultipleFromTemplate(var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTemplateFromCustomer(Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Templ. Mgt.", 'OnInsertCustomerFromTemplate', '', false, false)]
    local procedure OnInsertCustomerFromTemplateHandler(var Customer: Record Customer; var Result: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        Result := CreateCustomerFromTemplate(Customer, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Templ. Mgt.", 'OnTemplatesAreNotEmpty', '', false, false)]
    local procedure OnTemplatesAreNotEmptyHandler(var Result: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        Result := CustomerTemplatesAreNotEmpty(IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Templ. Mgt.", 'OnUpdateCustomerFromTemplate', '', false, false)]
    local procedure OnUpdateCustomerFromTemplateHandler(var Customer: Record Customer; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        UpdateFromTemplate(Customer, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Templ. Mgt.", 'OnUpdateCustomersFromTemplate', '', false, false)]
    local procedure OnUpdateCustomersFromTemplateHandler(var Customer: Record Customer; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        UpdateMultipleFromTemplate(Customer, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Templ. Mgt.", 'OnSaveAsTemplate', '', false, false)]
    local procedure OnSaveAsTemplateHandler(Customer: Record Customer; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        CreateTemplateFromCustomer(Customer, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Templ. Mgt.", 'OnShowTemplates', '', false, false)]
    local procedure OnShowTemplatesHandler(var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        ShowCustomerTemplList(IsHandled);
    end;

#if not CLEAN19
    [Obsolete('Will not be needed after customer template table will be removed.', '19.0')]
    procedure ShowContactConversionTemplatesNotification()
    var
        CustomerTemplList: Page "Customer Templ. List";
        Notification: Notification;
    begin
        Notification.Message(TemplatesDisabledTxt);
        Notification.AddAction(LearnMoreTxt, Codeunit::"Customer Templ. Mgt.", 'OpenLearnMore');
        Notification.AddAction(StrSubstNo(OpenPageTxt, CustomerTemplList.Caption), Codeunit::"Customer Templ. Mgt.", 'OpenCustomerTemplListPage');
        Notification.Send();
    end;

    [Obsolete('Will not be needed after customer template table will be removed.', '19.0')]
    procedure OpenLearnMore(Notification: Notification)
    begin
        Hyperlink(LearnMoreUrlTxt);
    end;

    [Obsolete('Will not be needed after customer template table will be removed.', '19.0')]
    procedure OpenCustomerTemplListPage(Notification: Notification)
    begin
        Page.Run(Page::"Customer Templ. List");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Customer Template List", 'OnOpenPageEvent', '', false, false)]
    local procedure CustomerTemplateListOnOpenPageEventHandler()
    begin
        ShowContactConversionTemplatesNotification();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Customer Template Card", 'OnOpenPageEvent', '', false, false)]
    local procedure CustomerTemplateCardOnOpenPageEventHandler()
    begin
        ShowContactConversionTemplatesNotification();
    end;
#endif
}