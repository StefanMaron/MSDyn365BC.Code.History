codeunit 138011 "O365 Demo Templates Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Config. Template]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyAllCustomerTemplates()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Customer: Record Customer;
        TempMiniCustomerTemplate: Record "Mini Customer Template" temporary;
        RecRef: RecordRef;
    begin
        Initialize;

        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Customer);
        if ConfigTemplateHeader.FindSet then
            repeat
                Clear(Customer);
                TempMiniCustomerTemplate.InsertCustomerFromTemplate(ConfigTemplateHeader, Customer);
                RecRef.GetTable(Customer);
                ValidateRecRefVsConfigTemplate(RecRef, ConfigTemplateHeader.Code);
            until ConfigTemplateHeader.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyAllItemTemplates()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Item: Record Item;
        TempItemTemplate: Record "Item Template" temporary;
        RecRef: RecordRef;
    begin
        Initialize;

        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Item);
        if ConfigTemplateHeader.FindSet then
            repeat
                Clear(Item);
                TempItemTemplate.InsertItemFromTemplate(ConfigTemplateHeader, Item);
                RecRef.GetTable(Item);
                ValidateRecRefVsConfigTemplate(RecRef, ConfigTemplateHeader.Code);
            until ConfigTemplateHeader.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyAllVendorTemplates()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Vendor: Record Vendor;
        TempMiniVendorTemplate: Record "Mini Vendor Template" temporary;
        RecRef: RecordRef;
    begin
        Initialize;

        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Vendor);
        if ConfigTemplateHeader.FindSet then
            repeat
                Clear(Vendor);
                TempMiniVendorTemplate.InsertVendorFromTemplate(ConfigTemplateHeader, Vendor);
                RecRef.GetTable(Vendor);
                ValidateRecRefVsConfigTemplate(RecRef, ConfigTemplateHeader.Code);
            until ConfigTemplateHeader.Next = 0;
    end;

    local procedure ValidateRecRefVsConfigTemplate(RecRef: RecordRef; TemplateCode: Code[10])
    var
        ConfigTemplateLine: Record "Config. Template Line";
        FieldRef: FieldRef;
    begin
        with ConfigTemplateLine do begin
            SetRange("Data Template Code", TemplateCode);
            if FindSet then
                repeat
                    FieldRef := RecRef.Field("Field ID");
                    Assert.AreEqual(
                      Format(FieldRef.Value),
                      "Default Value",
                      StrSubstNo('<%1> field', FieldRef.Caption));
                until Next = 0;
        end;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Demo Templates Test");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Demo Templates Test");

        LibraryApplicationArea.EnableFoundationSetup;

        isInitialized := true;

        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Demo Templates Test");
    end;
}

