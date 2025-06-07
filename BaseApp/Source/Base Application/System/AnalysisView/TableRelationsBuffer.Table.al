// // ------------------------------------------------------------------------------------------------
// // Copyright (c) Microsoft Corporation. All rights reserved.
// // Licensed under the MIT License. See License.txt in the project root for license information.
// // ------------------------------------------------------------------------------------------------
namespace System.Tooling;

using System.Reflection;
using System.Environment;

table 9640 "Table Relations Buffer"
{
    Scope = OnPrem;
    TableType = Temporary;
    Access = Internal;
    InherentPermissions = RIMDX;
    InherentEntitlements = RIMDX;

    fields
    {
        field(1; "Table ID"; Integer)
        {
        }
        field(2; "Field No."; Integer)
        {
        }
        field(3; "Related Table ID"; Integer)
        {
        }
        field(4; "Related Field No."; Integer)
        {
        }
        field(5; "Table Name"; Text[250])
        {
        }
        field(6; "Field Name"; Text[250])
        {
        }
        field(7; "Related Table Name"; Text[250])
        {
        }
        field(8; "Related Field Name"; Text[250])
        {
        }
        field(9; "Relation Description"; Text[250])
        {
        }
    }
    keys
    {
        key(pk; "Table ID", "Related Table ID", "Field No.", "Related Field No.")
        {
        }
    }
    fieldgroups
    {
        fieldgroup(DropDown; "Related Table Name", "Relation Description")
        {
        }
    }

    procedure PopulateFields(TableId: Integer)
    var
        TableRelationsMetadata: Record "Table Relations Metadata";
    begin
        if TableRelationsMetadata.FindSet() then
            repeat
                if (TableRelationsMetadata."Table ID" = TableId) then begin
                    Rec."Table Name" := TableRelationsMetadata."Table Name";
                    Rec."Table ID" := TableRelationsMetadata."Table ID";

                    Rec."Related Table Name" := TableRelationsMetadata."Related Table Name";
                    Rec."Related Table ID" := TableRelationsMetadata."Related Table ID";

                    Rec."Field Name" := TableRelationsMetadata."Field Name";
                    Rec."Field No." := TableRelationsMetadata."Field No.";

                    Rec."Related Field Name" := TableRelationsMetadata."Related Field Name";
                    Rec."Related Field No." := TableRelationsMetadata."Related Field No.";

                    Rec."Relation Description" := StrSubstNo(RelationDescriptionMsg, TableRelationsMetadata."Field Name", TableRelationsMetadata."Related Field Name");

                    if (CheckValidTable(TableRelationsMetadata."Related Table ID") and
                        CheckValidField(TableRelationsMetadata."Table ID", TableRelationsMetadata."Field No.") and
                        CheckValidField(TableRelationsMetadata."Related Table ID", TableRelationsMetadata."Related Field No.")
                        and (TableRelationsMetadata."Table ID" <> TableRelationsMetadata."Related Table ID")) then
                        if not Rec.Insert() then;
                end
                else
                    if (TableRelationsMetadata."Related Table ID" = TableId) then begin
                        Rec."Table Name" := TableRelationsMetadata."Related Table Name";
                        Rec."Table ID" := TableRelationsMetadata."Related Table ID";

                        Rec."Related Table ID" := TableRelationsMetadata."Table ID";
                        Rec."Related Table Name" := TableRelationsMetadata."Table Name";

                        Rec."Field Name" := TableRelationsMetadata."Related Field Name";
                        Rec."Field No." := TableRelationsMetadata."Related Field No.";

                        Rec."Related Field Name" := TableRelationsMetadata."Field Name";
                        Rec."Related Field No." := TableRelationsMetadata."Field No.";

                        Rec."Relation Description" := StrSubstNo(RelationDescriptionMsg, TableRelationsMetadata."Related Field Name", TableRelationsMetadata."Field Name");

                        if (CheckValidTable(TableRelationsMetadata."Table ID") and
                            CheckValidField(TableRelationsMetadata."Table ID", TableRelationsMetadata."Field No.") and
                            CheckValidField(TableRelationsMetadata."Related Table ID", TableRelationsMetadata."Related Field No.")
                            and (TableRelationsMetadata."Table ID" <> TableRelationsMetadata."Related Table ID")) then
                            if not Rec.Insert() then;
                    end;
            until TableRelationsMetadata.Next() = 0;
        Rec.SetCurrentKey("Table Name");
    end;

    local procedure CheckValidTable(TableId: Integer): Boolean
    var
        TableMetadata: Record "Table Metadata";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if not TableMetadata.Get(TableId) then
            Error('Table with ID %1 does not exist.', TableId);

        exit((TableMetadata.TableType = TableMetadata.TableType::Normal) and
              (TableMetadata.Access = TableMetadata.Access::Public) and
              (TableMetadata.ObsoleteState <> TableMetadata.ObsoleteState::Removed) and
              ((TableMetadata.Scope = TableMetadata.Scope::Cloud) or EnvironmentInformation.IsOnPrem()) and
              DoesTheTableHavePages(TableId));
    end;

    local procedure DoesTheTableHavePages(TableId: Integer): Boolean
    var
        PageMetadata: Record "Page Metadata";
    begin
        PageMetadata.SetRange(SourceTable, TableId);
        exit(not PageMetadata.IsEmpty());
    end;

    local procedure CheckValidField(TableId: Integer; FieldId: Integer): Boolean
    var
        FieldMetadata: Record Field;
    begin
        if not FieldMetadata.Get(TableId, FieldId) then
            Error('Field with ID %1 does not exist.', FieldId);

        exit((FieldMetadata.Class = FieldMetadata.Class::Normal) and
              (FieldMetadata.Access = FieldMetadata.Access::Public) and
              (FieldMetadata.ObsoleteState <> FieldMetadata.ObsoleteState::Removed) and
              (FieldMetadata.IsAllowedInCustomizations));
    end;

    var
        RelationDescriptionMsg: Label 'Via: %1 = %2', Comment = '%1 = Field Name, %2 = Related Field Name';
}