codeunit 2142 "O365 Template Management"
{

    trigger OnRun()
    begin
    end;

    procedure GetDefaultVATBusinessPostingGroup(): Code[20]
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        ConfigTemplateLine: Record "Config. Template Line";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        DummyCustomer: Record Customer;
    begin
        if not O365SalesInitialSetup.Get then
            exit;

        if not ConfigTemplateLine.GetLine(ConfigTemplateLine, O365SalesInitialSetup."Default Customer Template",
             DummyCustomer.FieldNo("VAT Bus. Posting Group"))
        then
            exit;

        if not VATBusinessPostingGroup.Get(ConfigTemplateLine."Default Value") then
            exit;

        exit(VATBusinessPostingGroup.Code);
    end;

    procedure GetDefaultVATProdPostingGroup(): Code[20]
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        ConfigTemplateLine: Record "Config. Template Line";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        DummyItem: Record Item;
    begin
        if not O365SalesInitialSetup.Get then
            exit;

        if not ConfigTemplateLine.GetLine(ConfigTemplateLine, O365SalesInitialSetup."Default Item Template",
             DummyItem.FieldNo("VAT Prod. Posting Group"))
        then
            exit;

        if not VATProductPostingGroup.Get(ConfigTemplateLine."Default Value") then
            exit;

        exit(VATProductPostingGroup.Code);
    end;

    procedure SetDefaultVATProdPostingGroup(VATProdPostingGroupCode: Code[20])
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        DummyItem: Record Item;
        ConfigTemplateManagement: Codeunit "Config. Template Management";
    begin
        if not O365SalesInitialSetup.Get then
            exit;

        ConfigTemplateManagement.ReplaceDefaultValueForAllTemplates(
          DATABASE::Item, DummyItem.FieldNo("VAT Prod. Posting Group"), VATProdPostingGroupCode);
    end;

    procedure GetDefaultBaseUnitOfMeasure(): Code[10]
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        ConfigTemplateLine: Record "Config. Template Line";
        UnitOfMeasure: Record "Unit of Measure";
        DummyItem: Record Item;
    begin
        if not O365SalesInitialSetup.Get then
            exit;

        ConfigTemplateLine.SetRange("Data Template Code", O365SalesInitialSetup."Default Item Template");
        ConfigTemplateLine.SetRange("Field ID", DummyItem.FieldNo("Base Unit of Measure"));
        if not ConfigTemplateLine.FindFirst then
            exit;

        if not UnitOfMeasure.Get(ConfigTemplateLine."Default Value") then
            exit;

        exit(UnitOfMeasure.Code);
    end;
}

