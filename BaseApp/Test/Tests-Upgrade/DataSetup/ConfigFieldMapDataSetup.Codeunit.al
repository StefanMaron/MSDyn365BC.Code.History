codeunit 132808 "Config. Field Map Data Setup"
{
    Subtype = Upgrade;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerCompany', '', false, false)]
    local procedure SetupReferencesToRemovedTables()
    begin
        InsertConfigFieldMapping();
    end;

    local procedure InsertConfigFieldMapping()
    var
        ConfigFieldMapping: Record "Config. Field Mapping";
    begin
        // first record
        ConfigFieldMapping."Package Code" := 'PACK1';
        ConfigFieldMapping."Table ID" := 123;
        ConfigFieldMapping."Field ID" := 123;
        ConfigFieldMapping."Field Name" := 'My field';
        ConfigFieldMapping."Old Value" := 'Y10';
        ConfigFieldMapping."New Value" := '10Y';
        ConfigFieldMapping.Insert();

        // second record
        ConfigFieldMapping."Package Code" := 'PACK1';
        ConfigFieldMapping."Table ID" := 321;
        ConfigFieldMapping."Field ID" := 1;
        ConfigFieldMapping."Field Name" := 'My field';
        ConfigFieldMapping."Old Value" := 'foo';
        ConfigFieldMapping."New Value" := 'bar';
        ConfigFieldMapping.Insert();
    end;
}