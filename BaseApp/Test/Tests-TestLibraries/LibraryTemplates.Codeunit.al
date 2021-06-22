codeunit 132210 "Library - Templates"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        LibraryTemplates: Codeunit "Library - Templates";
        LibraryERM: Codeunit "Library - ERM";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";

    procedure DisableTemplatesFeature()
    begin
        UnbindSubscription(LibraryTemplates);
        BindSubscription(LibraryTemplates);
    end;

    procedure CreateVendorTemplate(var VendorTempl: Record "Vendor Templ.")
    begin
        VendorTempl.Init();
        VendorTempl.Validate(Code, LibraryUtility.GenerateRandomCode(VendorTempl.FieldNo(Code), Database::"Vendor Templ."));
        VendorTempl.Validate(Description, VendorTempl.Code);
        VendorTempl.Insert(true);
    end;

    procedure CreateVendorTemplateWithData(var VendorTempl: Record "Vendor Templ.")
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        CreateVendorTemplate(VendorTempl);

        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);

        VendorTempl.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        VendorTempl.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        VendorTempl.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        VendorTempl.Modify(true);
    end;

    procedure CreateVendorTemplateWithDataAndDimensions(var VendorTempl: Record "Vendor Templ.")
    begin
        CreateVendorTemplateWithData(VendorTempl);
        CreateTemplateGlobalDimensions(Database::"Vendor Templ.", VendorTempl.Code);
        CreateTemplateDimensions(Database::"Vendor Templ.", VendorTempl.Code);
    end;

    procedure CreateCustomerTemplate(var CustomerTempl: Record "Customer Templ.")
    begin
        CustomerTempl.Init();
        CustomerTempl.Validate(Code, LibraryUtility.GenerateRandomCode(CustomerTempl.FieldNo(Code), Database::"Customer Templ."));
        CustomerTempl.Validate(Description, CustomerTempl.Code);
        CustomerTempl.Insert(true);
    end;

    procedure CreateCustomerTemplateWithData(var CustomerTempl: Record "Customer Templ.")
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CreateCustomerTemplate(CustomerTempl);

        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);

        CustomerTempl.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        CustomerTempl.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        CustomerTempl.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        CustomerTempl.Modify(true);
    end;

    procedure CreateCustomerTemplateWithDataAndDimensions(var CustomerTempl: Record "Customer Templ.")
    begin
        CreateCustomerTemplateWithData(CustomerTempl);
        CreateTemplateGlobalDimensions(Database::"Customer Templ.", CustomerTempl.Code);
        CreateTemplateDimensions(Database::"Customer Templ.", CustomerTempl.Code);
    end;

    procedure CreateItemTemplate(var ItemTempl: Record "Item Templ.")
    begin
        ItemTempl.Init();
        ItemTempl.Validate(Code, LibraryUtility.GenerateRandomCode(ItemTempl.FieldNo(Code), Database::"Item Templ."));
        ItemTempl.Validate(Description, ItemTempl.Code);
        ItemTempl.Insert(true);
    end;

    procedure CreateItemTemplateWithData(var ItemTempl: Record "Item Templ.")
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        InventoryPostingGroup: Record "Inventory Posting Group";
        UnitofMeasure: Record "Unit of Measure";
    begin
        CreateItemTemplate(ItemTempl);

        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure);

        ItemTempl.Validate("Inventory Posting Group", InventoryPostingGroup.Code);
        ItemTempl.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        ItemTempl.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        ItemTempl.Validate("Base Unit of Measure", UnitofMeasure.Code);
        ItemTempl.Modify(true);
    end;

    procedure CreateItemTemplateWithDataAndDimensions(var ItemTempl: Record "Item Templ.")
    begin
        CreateItemTemplateWithData(ItemTempl);
        CreateTemplateGlobalDimensions(Database::"Item Templ.", ItemTempl.Code);
        CreateTemplateDimensions(Database::"Item Templ.", ItemTempl.Code);
    end;

    procedure CreateEmployeeTemplate(var EmployeeTempl: Record "Employee Templ.")
    begin
        EmployeeTempl.Init();
        EmployeeTempl.Validate(Code, LibraryUtility.GenerateRandomCode(EmployeeTempl.FieldNo(Code), Database::"Employee Templ."));
        EmployeeTempl.Validate(Description, EmployeeTempl.Code);
        EmployeeTempl.Insert(true);
    end;

    procedure CreateEmployeeTemplateWithData(var EmployeeTempl: Record "Employee Templ.")
    var
        EmployeePostingGroup: Record "Employee Posting Group";
        EmployeeStatisticsGroup: Record "Employee Statistics Group";
    begin
        CreateEmployeeTemplate(EmployeeTempl);

        EmployeePostingGroup.Init();
        EmployeePostingGroup.Validate(Code, LibraryUtility.GenerateRandomCode(EmployeePostingGroup.FieldNo(Code), Database::"Employee Posting Group"));
        EmployeePostingGroup.Insert();

        EmployeeStatisticsGroup.Init();
        EmployeeStatisticsGroup.Validate(Code, LibraryUtility.GenerateRandomCode(EmployeeStatisticsGroup.FieldNo(Code), Database::"Employee Statistics Group"));
        EmployeeStatisticsGroup.Insert();

        EmployeeTempl.Validate("Employee Posting Group", EmployeePostingGroup.Code);
        EmployeeTempl.Validate("Statistics Group Code", EmployeeStatisticsGroup.Code);
        EmployeeTempl.Modify(true);
    end;

    procedure CreateEmployeeTemplateWithDataAndDimensions(var EmployeeTempl: Record "Employee Templ.")
    begin
        CreateEmployeeTemplateWithData(EmployeeTempl);
        CreateTemplateGlobalDimensions(Database::"Employee Templ.", EmployeeTempl.Code);
        CreateTemplateDimensions(Database::"Employee Templ.", EmployeeTempl.Code);
    end;

    procedure CreateTemplateGlobalDimensions(TemplateTableId: Integer; TemplateCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        i: Integer;
    begin
        for i := 1 to 2 do begin
            LibraryDimension.GetGlobalDimCodeValue(i, DimensionValue);
            LibraryDimension.CreateDefaultDimension(DefaultDimension, TemplateTableId, TemplateCode, DimensionValue."Dimension Code", DimensionValue.Code);
        end;
    end;

    procedure CreateTemplateDimensions(TemplateTableId: Integer; TemplateCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        i: Integer;
    begin
        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            LibraryDimension.CreateDimWithDimValue(DimensionValue);
            LibraryDimension.CreateDefaultDimension(DefaultDimension, TemplateTableId, TemplateCode, DimensionValue."Dimension Code", DimensionValue.Code);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Template Feature Mgt.", 'OnAfterIsEnabled', '', false, false)]
    local procedure OnAfterIsEnabledHandler(var Result: Boolean)
    begin
        Result := false;
    end;
}