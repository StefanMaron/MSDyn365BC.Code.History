// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN23
namespace Microsoft.FixedAssets.FixedAsset;

#pragma warning disable AL0432
codeunit 27041 "Sync.Dep.Fixed Asset SCT"
{
    Access = Internal;
    Permissions = tabledata "Fixed Asset" = rm;

    [EventSubscriber(ObjectType::Table, Database::"Fixed Asset", 'OnAfterValidateEvent', 'SCT Permission Number', false, false)]
    local procedure SyncOnAfterValidateSCTPermissionNumber(var Rec: Record "Fixed Asset")
    begin
        Rec."SCT Permission No." := Rec."SCT Permission Number";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Fixed Asset", 'OnAfterValidateEvent', 'SCT Permission No.', false, false)]
    local procedure SyncOnAfterValidateSCTPermissionNo(var Rec: Record "Fixed Asset")
    begin
        if StrLen(Rec."SCT Permission No.") <= MaxStrLen(Rec."SCT Permission Number") then
            Rec."SCT Permission Number" := CopyStr(Rec."SCT Permission No.", 1, StrLen(Rec."SCT Permission No."));
    end;
}
#endif
