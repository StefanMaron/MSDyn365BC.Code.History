// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using System.IO;
using System.Upgrade;

codeunit 104043 "Upgrade Config. Field Map"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetConfigFieldMapUpgradeTag()) then
            exit;

        UpgradeConfigFieldMap();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetConfigFieldMapUpgradeTag());
    end;

    local procedure UpgradeConfigFieldMap()
    var
        ConfigFieldMap: Record "Config. Field Map";
        ConfigFieldMapping: Record "Config. Field Mapping";
    begin
        if not ConfigFieldMapping.FindSet() then
            exit;

        repeat
            ConfigFieldMap.SetRange("Package Code", ConfigFieldMapping."Package Code");
            ConfigFieldMap.SetRange("Table ID", ConfigFieldMapping."Table ID");
            ConfigFieldMap.SetRange("Field ID", ConfigFieldMapping."Field ID");
            ConfigFieldMap.SetRange("Old Value", ConfigFieldMapping."Old Value");
            if not ConfigFieldMap.FindFirst() then begin
                ConfigFieldMap.ID := 0; // autoincrement
                ConfigFieldMap.TransferFields(ConfigFieldMapping);
                if not ConfigFieldMap.Insert() then
                    Session.LogMessage('0000G9N', FailedToMigrateFieldMapErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
            end;
        until ConfigFieldMapping.Next() = 0;
    end;

    var
        TelemetryCategoryTxt: Label 'AL SaaS Upgrade', Locked = true;
        FailedToMigrateFieldMapErr: Label 'Could not insert a record into Config. Field Map table.', Locked = true;
}
