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
        InitCustomerNo(Customer, CustomerTempl);
        Customer."Contact Type" := CustomerTempl."Contact Type";
        Customer.Insert(true);
        Customer.SetInsertFromTemplate(false);

        ApplyCustomerTemplate(Customer, CustomerTempl);

        OnAfterCreateCustomerFromTemplate(Customer, CustomerTempl);
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
        InsertDimensions(Customer."No.", CustomerTempl.Code, Database::Customer, Database::"Customer Templ.");

        exit(true);
    end;

    procedure ApplyCustomerTemplate(var Customer: Record Customer; CustomerTempl: Record "Customer Templ.")
    begin
        ApplyTemplate(Customer, CustomerTempl);
        InsertDimensions(Customer."No.", CustomerTempl.Code, Database::Customer, Database::"Customer Templ.");
    end;

    local procedure ApplyTemplate(var Customer: Record Customer; CustomerTempl: Record "Customer Templ.")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApplyTemplate(Customer, CustomerTempl, IsHandled);
        if IsHandled then
            exit;

        if CustomerTempl.City <> '' then
            Customer.City := CustomerTempl.City;
        Customer."Customer Posting Group" := CustomerTempl."Customer Posting Group";
        if (CustomerTempl."Currency Code" <> '') and (Customer."Currency Code" = '') then
            Customer."Currency Code" := CustomerTempl."Currency Code";
        if (CustomerTempl."Language Code" <> '') and (Customer."Language Code" = '') then
            Customer."Language Code" := CustomerTempl."Language Code";
        Customer."Payment Terms Code" := CustomerTempl."Payment Terms Code";
        Customer."Fin. Charge Terms Code" := CustomerTempl."Fin. Charge Terms Code";
        if CustomerTempl."Invoice Disc. Code" <> '' then
            Customer."Invoice Disc. Code" := CustomerTempl."Invoice Disc. Code";
        if (CustomerTempl."Country/Region Code" <> '') and (Customer."Country/Region Code" = '') then
            Customer."Country/Region Code" := CustomerTempl."Country/Region Code";
        Customer."Bill-to Customer No." := CustomerTempl."Bill-to Customer No.";
        Customer."Payment Method Code" := CustomerTempl."Payment Method Code";
        Customer."Application Method" := CustomerTempl."Application Method";
        Customer."Prices Including VAT" := CustomerTempl."Prices Including VAT";
        Customer."Gen. Bus. Posting Group" := CustomerTempl."Gen. Bus. Posting Group";
        if CustomerTempl."Post Code" <> '' then
            Customer."Post Code" := CustomerTempl."Post Code";
        if CustomerTempl.County <> '' then
            Customer.County := CustomerTempl.County;
        Customer."VAT Bus. Posting Group" := CustomerTempl."VAT Bus. Posting Group";
        Customer."Block Payment Tolerance" := CustomerTempl."Block Payment Tolerance";
        Customer."Validate EU Vat Reg. No." := CustomerTempl."Validate EU Vat Reg. No.";
        Customer.Blocked := CustomerTempl.Blocked;
        Customer."Shipment Method Code" := CustomerTempl."Shipment Method Code";
        Customer."Reminder Terms Code" := CustomerTempl."Reminder Terms Code";
        Customer."Print Statements" := CustomerTempl."Print Statements";
        Customer."Customer Price Group" := CustomerTempl."Customer Price Group";
        Customer."Customer Disc. Group" := CustomerTempl."Customer Disc. Group";
        Customer."Document Sending Profile" := CustomerTempl."Document Sending Profile";
        if (CustomerTempl."Territory Code" <> '') and (Customer."Territory Code" = '') then
            Customer."Territory Code" := CustomerTempl."Territory Code";
        Customer."Credit Limit (LCY)" := CustomerTempl."Credit Limit (LCY)";
        Customer."Allow Line Disc." := CustomerTempl."Allow Line Disc.";
        Customer."Contact Type" := CustomerTempl."Contact Type";
        Customer."Partner Type" := CustomerTempl."Partner Type";
        Customer."Location Code" := CustomerTempl."Location Code";
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
        if not IsEnabled() then
            exit;

        IsHandled := true;

        InsertTemplateFromCustomer(CustomerTempl, Customer);
        InsertDimensions(CustomerTempl.Code, Customer."No.", Database::"Customer Templ.", Database::Customer);
        CustomerTempl.Get(CustomerTempl.Code);
        ShowCustomerTemplCard(CustomerTempl);
    end;

    local procedure InsertTemplateFromCustomer(var CustomerTempl: Record "Customer Templ."; Customer: Record Customer)
    begin
        CustomerTempl.Init();
        CustomerTempl.Code := GetCustomerTemplCode();

        CustomerTempl.City := Customer.City;
        CustomerTempl."Customer Posting Group" := Customer."Customer Posting Group";
        CustomerTempl."Currency Code" := Customer."Currency Code";
        CustomerTempl."Language Code" := Customer."Language Code";
        CustomerTempl."Payment Terms Code" := Customer."Payment Terms Code";
        CustomerTempl."Fin. Charge Terms Code" := Customer."Fin. Charge Terms Code";
        CustomerTempl."Invoice Disc. Code" := Customer."Invoice Disc. Code";
        CustomerTempl."Country/Region Code" := Customer."Country/Region Code";
        CustomerTempl."Bill-to Customer No." := Customer."Bill-to Customer No.";
        CustomerTempl."Payment Method Code" := Customer."Payment Method Code";
        CustomerTempl."Application Method" := Customer."Application Method";
        CustomerTempl."Prices Including VAT" := Customer."Prices Including VAT";
        CustomerTempl."Gen. Bus. Posting Group" := Customer."Gen. Bus. Posting Group";
        CustomerTempl."Post Code" := Customer."Post Code";
        CustomerTempl.County := Customer.County;
        CustomerTempl."VAT Bus. Posting Group" := Customer."VAT Bus. Posting Group";
        CustomerTempl."Block Payment Tolerance" := Customer."Block Payment Tolerance";
        CustomerTempl."Validate EU Vat Reg. No." := Customer."Validate EU Vat Reg. No.";
        CustomerTempl.Blocked := Customer.Blocked;
        CustomerTempl."Shipment Method Code" := Customer."Shipment Method Code";
        CustomerTempl."Reminder Terms Code" := Customer."Reminder Terms Code";
        CustomerTempl."Print Statements" := Customer."Print Statements";
        CustomerTempl."Customer Price Group" := Customer."Customer Price Group";
        CustomerTempl."Customer Disc. Group" := Customer."Customer Disc. Group";
        CustomerTempl."Document Sending Profile" := Customer."Document Sending Profile";
        CustomerTempl."Territory Code" := Customer."Territory Code";
        CustomerTempl."Credit Limit (LCY)" := Customer."Credit Limit (LCY)";
        CustomerTempl."Allow Line Disc." := Customer."Allow Line Disc.";
        CustomerTempl."Partner Type" := Customer."Partner Type";
        CustomerTempl."Location Code" := Customer."Location Code";

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
        if not IsEnabled() then
            exit;

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
}
