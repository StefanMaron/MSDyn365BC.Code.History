// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using System.Utilities;

table 5460 "Graph Business Setting"
{
    Caption = 'Graph Business Setting';
    ExternalName = 'BusinessSetting';
    TableType = MicrosoftGraph;
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
    ObsoleteReason = 'This functionality is out of support';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Text[250])
        {
            Caption = 'Id';
            ExternalName = 'id';
            ExternalType = 'Edm.String';
        }
        field(2; Scope; Text[250])
        {
            Caption = 'Name';
            ExternalName = 'scope';
            ExternalType = 'Edm.String';
        }
        field(3; Name; Text[250])
        {
            Caption = 'Name';
            ExternalName = 'name';
            ExternalType = 'Edm.String';
        }
        field(4; Data; BLOB)
        {
            Caption = 'Data';
            ExternalName = 'data';
            ExternalType = 'Microsoft.Griffin.SmallBusiness.SbGraph.Core.SettingsData';
            SubType = Json;
        }
        field(5; SecondaryKey; Text[250])
        {
            Caption = 'SecondaryKey';
            ExternalName = 'secondaryKey';
            ExternalType = 'Edm.String';
        }
        field(6; CreatedDate; DateTime)
        {
            Caption = 'CreatedDate';
            ExternalName = 'createdDate';
            ExternalType = 'Edm.DateTimeOffset';
        }
        field(7; LastModifiedDate; DateTime)
        {
            Caption = 'LastModifiedDate';
            ExternalName = 'lastModifiedDate';
            ExternalType = 'Edm.DateTimeOffset';
        }
        field(8; ETag; Text[250])
        {
            Caption = 'ETag';
            ExternalName = '@odata.etag';
            ExternalType = 'Edm.String';
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure GetDataString() DataText: Text
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
    begin
        TempBlob.FromRecord(Rec, FieldNo(Data));
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        InStream.Read(DataText);
    end;
}

