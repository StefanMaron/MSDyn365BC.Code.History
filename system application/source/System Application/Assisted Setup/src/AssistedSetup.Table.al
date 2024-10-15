// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

table 1803 "Assisted Setup"
{
    Access = Internal;
    Caption = 'Assisted Setup';
    ReplicateData = false;

    fields
    {
        field(1; "Page ID"; Integer)
        {
            Caption = 'Page ID';
        }
        field(2; Name; Text[2048])
        {
            Caption = 'Name';
        }
        field(3; "Order"; Integer)
        {
            Caption = 'Order';
            ObsoleteState = Pending;
            ObsoleteReason = 'Order cannot be determined at compile time because the extensions that add to the table are unknown and can insert records in any order.';
            ObsoleteTag = '16.0';
        }
        field(4; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Not Completed,Completed,Not Started,Seen,Watched,Read, ';
            OptionMembers = "Not Completed",Completed,"Not Started",Seen,Watched,Read," ";
            ObsoleteState = Pending;
            ObsoleteReason = 'Only option used is Complete- new boolean field with that name created.';
            ObsoleteTag = '16.0';
        }
        field(5; Visible; Boolean)
        {
            Caption = 'Visible';
            ObsoleteState = Pending;
            ObsoleteReason = 'Only those setup records that are visible should be added.';
            ObsoleteTag = '16.0';
        }
        field(6; Parent; Integer)
        {
            Caption = 'Parent';
            ObsoleteState = Pending;
            ObsoleteReason = 'Hierarchy is removed. Instead the Group Name is populated for each record.';
            ObsoleteTag = '16.0';
        }
        field(7; "Video Url"; Text[250])
        {
            Caption = 'Video Url';
        }
        field(8; Icon; Media)
        {
            Caption = 'Icon';
        }
        field(9; "Item Type"; Option)
        {
            Caption = 'Item Type';
            InitValue = "Setup and Help";
            OptionCaption = ' ,Group,Setup and Help';
            OptionMembers = " ",Group,"Setup and Help";
            ObsoleteState = Pending;
            ObsoleteReason = 'No group type items anymore. Use the Group Name field instead.';
            ObsoleteTag = '16.0';
        }
        field(10; Featured; Boolean)
        {
            Caption = 'Featured';
            ObsoleteState = Pending;
            ObsoleteReason = 'Not used in any UI component.';
            ObsoleteTag = '16.0';
        }
        field(11; "Help Url"; Text[250])
        {
            Caption = 'Help Url';
        }
        field(12; "Assisted Setup Page ID"; Integer)
        {
            Caption = 'Assisted Setup Page ID';
            ObsoleteState = Pending;
            ObsoleteReason = 'Redundant field- duplication of Page ID field.';
            ObsoleteTag = '16.0';
        }
        field(13; "Tour Id"; Integer)
        {
            Caption = 'Tour Id';
            ObsoleteState = Pending;
            ObsoleteReason = 'Not used in any UI component.';
            ObsoleteTag = '16.0';
        }
        field(14; "Video Status"; Boolean)
        {
            Caption = 'Video Status';
            ObsoleteState = Pending;
            ObsoleteReason = 'Not needed to track if user has seen video.';
            ObsoleteTag = '16.0';
        }
        field(15; "Help Status"; Boolean)
        {
            Caption = 'Help Status';
            ObsoleteState = Pending;
            ObsoleteReason = 'Not needed to track if user has seen help.';
            ObsoleteTag = '16.0';
        }
        field(16; "Tour Status"; Boolean)
        {
            Caption = 'Tour Status';
            ObsoleteState = Pending;
            ObsoleteReason = 'Not used in any UI component.';
            ObsoleteTag = '16.0';
        }
        field(19; "App ID"; Guid)
        {
            Caption = 'App ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(20; "Extension Name"; Text[250])
        {
            Caption = 'Extension Name';
            FieldClass = FlowField;
            CalcFormula = Lookup ("NAV App".Name where(ID = FIELD("App ID"), "Tenant Visible" = CONST(true)));
            Editable = false;
        }
        field(21; "Group Name"; Enum "Assisted Setup Group")
        {
            Caption = 'Group';
            Editable = false;
        }
        field(22; Completed; Boolean)
        {
            Caption = 'Completed';
            Editable = false;
        }
        field(23; "Video Category"; Enum "Video Category")
        {
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Page ID")
        {
            Clustered = true;
        }
        key(Key2; Order, Visible)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        Translation: Codeunit Translation;
    begin
        Translation.Delete(Rec);
    end;
}

