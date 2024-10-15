codeunit 135974 "Upgrade Config. Field Map Test"
{
    Subtype = Test;

    [Test]
    procedure ConfigFieldMappingToConfigFieldMapTest()
    var
        ConfigFieldMap: Record "Config. Field Map";
        UpgradeStatus: Codeunit "Upgrade Status";
        Assert: Codeunit "Library Assert";
    begin
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

        Assert.AreEqual(2, ConfigFieldMap.Count(), 'The number of mappings is wrong.');

        ConfigFieldMap.FindSet();
        repeat
            Assert.IsTrue(ConfigFieldMap."Package Code" = 'PACK1', 'Wrong mapping data.');
            Assert.IsTrue(ConfigFieldMap."Table ID" in [123, 321], 'Wrong mapping data.');
            Assert.IsTrue(ConfigFieldMap."Field ID" in [123, 1], 'Wrong mapping data.');
            Assert.IsTrue(ConfigFieldMap."Field Name" = 'My field', 'Wrong mapping data.');
            Assert.IsTrue(ConfigFieldMap."Old Value" in ['Y10', 'foo'], 'Wrong mapping data.');
            Assert.IsTrue(ConfigFieldMap."New Value" in ['10Y', 'bar'], 'Wrong mapping data.');
        until ConfigFieldMap.Next() = 0;
    end;
}