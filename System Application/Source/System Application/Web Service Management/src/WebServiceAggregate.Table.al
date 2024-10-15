// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

table 9900 "Web Service Aggregate"
{
    Caption = 'Web Service Aggregate';
    DataPerCompany = false;
    ReplicateData = false;
    Extensible = false;
    Access = Public;

    fields
    {
        field(3; "Object Type"; Option)
        {
            Caption = 'Object Type';
            OptionCaption = ',,,,,Codeunit,,,Page,Query';
            OptionMembers = ,,,,,"Codeunit",,,"Page","Query";
        }
        field(6; "Object ID"; Integer)
        {
            Caption = 'Object ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = FIELD("Object Type"));
        }
        field(9; "Service Name"; Text[240])
        {
            Caption = 'Service Name';

            trigger OnValidate()
            var
                WebServiceManagementImpl: Codeunit "Web Service Management Impl.";
            begin
                WebServiceManagementImpl.AssertServiceNameIsValid("Service Name");
            end;
        }
        field(12; Published; Boolean)
        {
            Caption = 'Published';
        }
        field(15; "All Tenants"; Boolean)
        {
            Caption = 'All Tenants';
        }
    }

    keys
    {
        key(Key1; "Object Type", "Service Name")
        {
            Clustered = true;
        }
        key(Key2; "Object Type", "Object ID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        WebServiceManagementImpl: Codeunit "Web Service Management Impl.";
    begin
        WebServiceManagementImpl.DeleteWebService(Rec);
    end;

    trigger OnInsert()
    var
        WebServiceManagementImpl: Codeunit "Web Service Management Impl.";
    begin
        WebServiceManagementImpl.VerifyRecord(Rec);
        WebServiceManagementImpl.AssertUniquePublishedServiceName(Rec, xRec);
        WebServiceManagementImpl.AssertUniqueUnpublishedObject(Rec);
        WebServiceManagementImpl.InsertWebService(Rec);
    end;

    trigger OnModify()
    var
        WebServiceManagementImpl: Codeunit "Web Service Management Impl.";
    begin
        WebServiceManagementImpl.VerifyRecord(Rec);
        WebServiceManagementImpl.AssertUniquePublishedServiceName(Rec, xRec);
        WebServiceManagementImpl.ModifyWebService(Rec, xRec);
    end;

    trigger OnRename()
    var
        WebServiceManagementImpl: Codeunit "Web Service Management Impl.";
    begin
        WebServiceManagementImpl.AssertUniquePublishedServiceName(Rec, xRec);
        WebServiceManagementImpl.RenameWebService(Rec, xRec);
    end;
}