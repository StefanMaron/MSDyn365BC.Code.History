﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

page 2503 "Extension Installation"
{
    Extensible = false;
    PageType = Card;
    SourceTable = "NAV App";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
        }
    }

    actions
    {
        area(processing)
        {
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        CurrPage.Close();
    end;

    trigger OnOpenPage()
    var
        ExtensionMarketplace: Codeunit "Extension Marketplace";
        MarketplaceExtnDeployment: Page "Marketplace Extn Deployment";
    begin
        GetDetailsFromFilters();

        MarketplaceExtnDeployment.RunModal();
        if MarketplaceExtnDeployment.GetInstalledSelected() then
            ExtensionMarketplace.InstallMarketplaceExtension(ID, ResponseURL, MarketplaceExtnDeployment.GetLanguageId());
    end;

    local procedure GetDetailsFromFilters()
    var
        RecRef: RecordRef;
        i: Integer;
    begin
        RecRef.GetTable(Rec);
        for i := 1 to RecRef.FieldCount() do
            ParseFilter(RecRef.FieldIndex(i));
        RecRef.SetTable(Rec);
    end;

    local procedure ParseFilter(FieldRef: FieldRef)
    var
        FilterPrefixDotNet_Regex: DotNet Regex;
        SingleQuoteDotNet_Regex: DotNet Regex;
        EscapedEqualityDotNet_Regex: DotNet Regex;
        "Filter": Text;
    begin
        FilterPrefixDotNet_Regex := FilterPrefixDotNet_Regex.Regex('^@\*([^\\]+)\*$');
        SingleQuoteDotNet_Regex := SingleQuoteDotNet_Regex.Regex('^''([^\\]+)''$');
        EscapedEqualityDotNet_Regex := EscapedEqualityDotNet_Regex.Regex('~');
        Filter := FieldRef.GetFilter();
        Filter := FilterPrefixDotNet_Regex.Replace(Filter, '$1');
        Filter := SingleQuoteDotNet_Regex.Replace(Filter, '$1');
        Filter := EscapedEqualityDotNet_Regex.Replace(Filter, '=');

        if Filter <> '' then
            FieldRef.Value(Filter);
    end;
}

