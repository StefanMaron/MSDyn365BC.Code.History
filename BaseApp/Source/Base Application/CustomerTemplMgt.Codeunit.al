codeunit 1381 "Customer Templ. Mgt."
{
    trigger OnRun()
    begin
    end;

    procedure CreateCustomerFromTemplate(var Customer: Record Customer; var IsHandled: Boolean): Boolean
    var
        CustomerTempl: Record "Customer Templ.";
    begin
        if not IsEnabled() then
            exit(false);

        IsHandled := true;

        if not SelectCustomerTemplate(CustomerTempl) then
            exit(false);

        Customer.SetInsertFromTemplate(true);
        Customer.Init();
        Customer.Insert(true);
        Customer.SetInsertFromTemplate(false);

        ApplyCustomerTemplate(Customer, CustomerTempl);

        exit(true);
    end;

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
        InsertDimensions(Customer."No.", CustomerTempl.Code);

        exit(true);
    end;

    procedure ApplyCustomerTemplate(var Customer: Record Customer; CustomerTempl: Record "Customer Templ.")
    begin
        ApplyTemplate(Customer, CustomerTempl);
        InsertDimensions(Customer."No.", CustomerTempl.Code);
    end;

    local procedure ApplyTemplate(var Customer: Record Customer; CustomerTempl: Record "Customer Templ.")
    begin
        Customer.City := CustomerTempl.City;
        Customer."Customer Posting Group" := CustomerTempl."Customer Posting Group";
        Customer."Currency Code" := CustomerTempl."Currency Code";
        Customer."Language Code" := CustomerTempl."Language Code";
        Customer."Payment Terms Code" := CustomerTempl."Payment Terms Code";
        Customer."Fin. Charge Terms Code" := CustomerTempl."Fin. Charge Terms Code";
        Customer."Invoice Disc. Code" := CustomerTempl."Invoice Disc. Code";
        Customer."Country/Region Code" := CustomerTempl."Country/Region Code";
        Customer."Bill-to Customer No." := CustomerTempl."Bill-to Customer No.";
        Customer."Payment Method Code" := CustomerTempl."Payment Method Code";
        Customer."Application Method" := CustomerTempl."Application Method".AsInteger();
        Customer."Prices Including VAT" := CustomerTempl."Prices Including VAT";
        Customer."Gen. Bus. Posting Group" := CustomerTempl."Gen. Bus. Posting Group";
        Customer."Post Code" := CustomerTempl."Post Code";
        Customer.County := CustomerTempl.County;
        Customer."VAT Bus. Posting Group" := CustomerTempl."VAT Bus. Posting Group";
        Customer."Block Payment Tolerance" := CustomerTempl."Block Payment Tolerance";
        Customer."Validate EU Vat Reg. No." := CustomerTempl."Validate EU Vat Reg. No.";
        Customer.Blocked := CustomerTempl.Blocked;
        Customer."Shipment Method Code" := CustomerTempl."Shipment Method Code";
        OnApplyTemplateOnBeforeCustomerModify(Customer, CustomerTempl);
        Customer.Modify(true);
    end;

    procedure SelectCustomerTemplateFromContact(var CustomerTempl: Record "Customer Templ."; Contact: Record Contact): Boolean
    begin
        CustomerTempl.SetRange("Contact Type", Contact.Type);
        exit(SelectCustomerTemplate(CustomerTempl));
    end;

    local procedure SelectCustomerTemplate(var CustomerTempl: Record "Customer Templ."): Boolean
    var
        SelectCustomerTemplList: Page "Select Customer Templ. List";
    begin
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

    local procedure InsertDimensions(CustomerNo: Code[20]; CustomerTemplCode: Code[20])
    var
        SourceDefaultDimension: Record "Default Dimension";
        DestDefaultDimension: Record "Default Dimension";
    begin
        SourceDefaultDimension.SetRange("Table ID", Database::"Customer Templ.");
        SourceDefaultDimension.SetRange("No.", CustomerTemplCode);
        if SourceDefaultDimension.FindSet() then
            repeat
                DestDefaultDimension.Init();
                DestDefaultDimension.Validate("Table ID", Database::Customer);
                DestDefaultDimension.Validate("No.", CustomerNo);
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
        if not CanBeUpdatedFromTemplate(CustomerTempl, IsHandled) then
            exit;

        if Customer.FindSet() then
            repeat
                ApplyCustomerTemplate(Customer, CustomerTempl);
            until Customer.Next() = 0;
    end;

    local procedure CanBeUpdatedFromTemplate(var CustomerTempl: Record "Customer Templ."; var IsHandled: Boolean): Boolean
    begin
        if not IsEnabled() then
            exit(false);

        IsHandled := true;

        if not SelectCustomerTemplate(CustomerTempl) then
            exit(false);

        exit(true);
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
}