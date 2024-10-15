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

    local procedure ValidateRecRefVsConfigTemplate(RecRef: RecordRef; TemplateCode: Code[10])
    var
        ConfigTemplateLine: Record "Config. Template Line";
        FieldRef: FieldRef;
    begin
        ConfigTemplateLine.SetRange("Data Template Code", TemplateCode);
        if ConfigTemplateLine.FindSet() then
            repeat
                FieldRef := RecRef.Field(ConfigTemplateLine."Field ID");
                Assert.AreEqual(
                  Format(FieldRef.Value),
                  ConfigTemplateLine."Default Value",
                  StrSubstNo('<%1> field', FieldRef.Caption));
            until ConfigTemplateLine.Next() = 0;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Demo Templates Test");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Demo Templates Test");

        LibraryApplicationArea.EnableFoundationSetup();

        isInitialized := true;

        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Demo Templates Test");
    end;
}

