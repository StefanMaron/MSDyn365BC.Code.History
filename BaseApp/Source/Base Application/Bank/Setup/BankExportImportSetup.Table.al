namespace Microsoft.Bank.Setup;

using Microsoft.Bank.PositivePay;
using System.IO;
using System.Reflection;

table 1200 "Bank Export/Import Setup"
{
    Caption = 'Bank Export/Import Setup';
    DataCaptionFields = "Code", Name;
    DrillDownPageID = "Bank Export/Import Setup";
    LookupPageID = "Bank Export/Import Setup";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(3; Direction; Option)
        {
            Caption = 'Direction';
            OptionCaption = 'Export,Import,Export-Positive Pay';
            OptionMembers = Export,Import,"Export-Positive Pay";

            trigger OnValidate()
            begin
                if Direction = Direction::"Export-Positive Pay" then
                    "Processing Codeunit ID" := CODEUNIT::"Exp. Launcher Pos. Pay"
                else
                    if "Processing Codeunit ID" = CODEUNIT::"Exp. Launcher Pos. Pay" then
                        "Processing Codeunit ID" := 0;
            end;
        }
        field(4; "Processing Codeunit ID"; Integer)
        {
            Caption = 'Processing Codeunit ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Codeunit));
        }
#pragma warning disable AS0086
        field(5; "Processing Codeunit Name"; Text[249])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Processing Codeunit ID")));
            Caption = 'Processing Codeunit Name';
            Editable = false;
            FieldClass = FlowField;
        }
#pragma warning restore AS0086
        field(6; "Processing XMLport ID"; Integer)
        {
            Caption = 'Processing XMLport ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(XMLport));
        }
#pragma warning disable AS0086
        field(7; "Processing XMLport Name"; Text[249])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(XMLport),
                                                                           "Object ID" = field("Processing XMLport ID")));
            Caption = 'Processing XMLport Name';
            Editable = false;
            FieldClass = FlowField;
        }
#pragma warning restore AS0086
        field(8; "Data Exch. Def. Code"; Code[20])
        {
            Caption = 'Data Exch. Def. Code';
            TableRelation = if (Direction = const(Import)) "Data Exch. Def".Code where(Type = const("Bank Statement Import"))
            else
            if (Direction = const(Export)) "Data Exch. Def".Code where(Type = const("Payment Export"))
            else
            if (Direction = const("Export-Positive Pay")) "Data Exch. Def".Code where(Type = const("Positive Pay Export"));
        }
        field(9; "Data Exch. Def. Name"; Text[100])
        {
            CalcFormula = lookup("Data Exch. Def".Name where(Code = field("Data Exch. Def. Code")));
            Caption = 'Data Exch. Def. Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Preserve Non-Latin Characters"; Boolean)
        {
            Caption = 'Preserve Non-Latin Characters';
            InitValue = true;
        }
        field(11; "Check Export Codeunit"; Integer)
        {
            Caption = 'Check Export Codeunit';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Codeunit));
        }
#pragma warning disable AS0086
        field(12; "Check Export Codeunit Name"; Text[249])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Check Export Codeunit")));
            Caption = 'Check Export Codeunit Name';
            Editable = false;
            FieldClass = FlowField;
        }
#pragma warning restore AS0086
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

