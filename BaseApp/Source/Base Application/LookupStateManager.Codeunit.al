// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

codeunit 109 "Lookup State Manager"
{
    SingleInstance = true;

    trigger OnRun()
    begin

    end;

    var
        SavedVariant: Variant;
        RecordSaved: Boolean;

    internal procedure GetSavedRecord(): Variant
    begin
        if SavedVariant.IsRecord() then
            exit(SavedVariant);
    end;

    internal procedure ClearSavedRecord()
    begin
        clear(SavedVariant);
        RecordSaved := false;
    end;

    internal procedure IsRecordSaved(): Boolean
    begin
        exit(RecordSaved);
    end;

    internal procedure SaveRecord(var RecordVariant: Variant)
    begin
        SavedVariant := RecordVariant;
        RecordSaved := true;
    end;
}