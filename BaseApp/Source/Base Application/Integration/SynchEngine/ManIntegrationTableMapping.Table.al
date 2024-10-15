// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using System.IO;
using System.Reflection;
table 5380 "Man. Integration Table Mapping"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Name; Code[20])
        {
            Caption = 'Name';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = SystemMetadata;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table), "Object Subtype" = const('Normal'));
        }
        field(3; "Integration Table ID"; Integer)
        {
            Caption = 'Integration Table ID';
            DataClassification = SystemMetadata;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table), "Object Subtype" = const('CRM'));
        }
        field(4; "Integration Table UID"; Integer)
        {
            Caption = 'Integration Table UID';
            DataClassification = SystemMetadata;
            TableRelation = Field."No." where(TableNo = field("Integration Table ID"));
        }
        field(5; "Int. Tbl. Modified On Id"; Integer)
        {
            Caption = 'Integration Table Modified On Id';
            DataClassification = SystemMetadata;
            TableRelation = Field."No." where(TableNo = field("Integration Table ID"));
        }
        field(6; "Sync Only Coupled Records"; Boolean)
        {
            Caption = 'Sync Only Coupled Records';
            DataClassification = SystemMetadata;
        }
        field(7; Direction; Option)
        {
            Caption = 'Direction';
            DataClassification = SystemMetadata;
            OptionCaption = 'Bidirectional,ToIntegrationTable,FromIntegrationTable';
            OptionMembers = Bidirectional,ToIntegrationTable,FromIntegrationTable;
        }
        field(8; "Table Config Template Code"; Code[10])
        {
            Caption = 'Table Config Template Code';
            TableRelation = "Config. Template Header".Code where("Table ID" = field("Table ID"));
        }
        field(9; "Int. Tbl. Config Template Code"; Code[10])
        {
            Caption = 'Int. Tbl. Config Template Code';
            TableRelation = "Config. Template Header".Code where("Table ID" = field("Integration Table ID"));
        }
        field(10; "Table Filter"; BLOB)
        {
            Caption = 'Table Filter';
        }
        field(11; "Integration Table Filter"; BLOB)
        {
            Caption = 'Integration Table Filter';
        }
    }
    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }
    trigger OnDelete()
    var
        ManIntFieldMapping: Record "Man. Int. Field Mapping";
    begin
        ManIntFieldMapping.SetRange(Name, Name);
        ManIntFieldMapping.DeleteAll(true);
    end;

    internal procedure CreateRecord(IntegrationMappingName: Code[20]; IntegrationMappingTableId: Integer; IntegrationMappingIntTableId: Integer; IntegrationTableUID: Integer; IntTblModifiedOnId: Integer; SyncOnlyCoupledRecords: Boolean; lDirection: Option; TableFilter: Text; IntegrationTableFilter: Text; TableConfigTemplateCode: Code[20]; IntTableConfigTemplateCode: Code[20])
    begin
        Init();
        Name := IntegrationMappingName;
        "Table ID" := IntegrationMappingTableId;
        "Integration Table ID" := IntegrationMappingIntTableId;
        "Integration Table UID" := IntegrationTableUID;
        "Int. Tbl. Modified On Id" := IntTblModifiedOnId;
        "Sync Only Coupled Records" := SyncOnlyCoupledRecords;
        Direction := lDirection;
        "Table Config Template Code" := TableConfigTemplateCode;
        "Int. Tbl. Config Template Code" := IntTableConfigTemplateCode;
        Insert(true);

        SetTableFilter(TableFilter);
        SetIntegrationTableFilter(IntegrationTableFilter);
        Modify(true);
    end;

    internal procedure InsertIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; MappingName: Code[20]; TableNo: Integer; IntegrationTableNo: Integer; IntegrationTableUIDFieldNo: Integer; IntegrationTableModifiedFieldNo: Integer; TableConfigTemplateCode: Code[10]; IntegrationTableConfigTemplateCode: Code[10]; SynchOnlyCoupledRecords: Boolean; Direction: Option)
    begin
        IntegrationTableMapping.CreateRecord(
            MappingName,
            TableNo,
            IntegrationTableNo,
            IntegrationTableUIDFieldNo,
            IntegrationTableModifiedFieldNo,
            TableConfigTemplateCode,
            IntegrationTableConfigTemplateCode,
            SynchOnlyCoupledRecords,
            Direction,
            'CDS');
    end;

    internal procedure InsertIntegrationFieldMapping(IntegrationTableMappingName: Code[20]; TableFieldNo: Integer; IntegrationTableFieldNo: Integer; SynchDirection: Option; ConstValue: Text; ValidateField: Boolean; ValidateIntegrationTableField: Boolean; Status: Boolean; TransformationRule: Code[20])
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.CreateRecord(
            IntegrationTableMappingName,
            TableFieldNo,
            IntegrationTableFieldNo,
            SynchDirection,
            ConstValue,
            ValidateField,
            ValidateIntegrationTableField,
            Status,
            TransformationRule,
            true);
    end;

    local procedure SetTableFilter("Filter": Text)
    var
        OutStream: OutStream;
    begin
        "Table Filter".CreateOutStream(OutStream);
        OutStream.Write(Filter);
    end;

    local procedure SetIntegrationTableFilter(IntTableFilter: Text)
    var
        OutStream: OutStream;
    begin
        "Integration Table Filter".CreateOutStream(OutStream);
        OutStream.Write(IntTableFilter);
    end;
}