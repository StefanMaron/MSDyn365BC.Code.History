namespace Microsoft.Inventory.BOM;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using System.Reflection;

table 5874 "BOM Warning Log"
{
    Caption = 'BOM Warning Log';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Warning Description"; Text[250])
        {
            Caption = 'Warning Description';
        }
        field(6; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(7; "Table Position"; Text[250])
        {
            Caption = 'Table Position';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetWarning(TheWarning: Text[250]; TheTableID: Integer; TheTablePosition: Text[250])
    begin
        "Entry No." := "Entry No." + 1;
        "Warning Description" := TheWarning;
        "Table ID" := TheTableID;
        "Table Position" := TheTablePosition;
        Insert();
    end;

    procedure ShowWarning()
    var
        Item: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
        RtngHeader: Record "Routing Header";
        RtngVersion: Record "Routing Version";
        WorkCtr: Record "Work Center";
        MachineCtr: Record "Machine Center";
        RecRef: RecordRef;
    begin
        if "Table ID" = 0 then
            exit;

        RecRef.Open("Table ID");
        RecRef.SetPosition("Table Position");

        case "Table ID" of
            DATABASE::Item:
                begin
                    RecRef.SetTable(Item);
                    Item.SetRecFilter();
                    PAGE.RunModal(PAGE::"Item Card", Item);
                end;
            DATABASE::"Production BOM Header":
                begin
                    RecRef.SetTable(ProdBOMHeader);
                    ProdBOMHeader.SetRecFilter();
                    PAGE.RunModal(PAGE::"Production BOM", ProdBOMHeader);
                end;
            DATABASE::"Routing Header":
                begin
                    RecRef.SetTable(RtngHeader);
                    RtngHeader.SetRecFilter();
                    PAGE.RunModal(PAGE::Routing, RtngHeader);
                end;
            DATABASE::"Production BOM Version":
                begin
                    RecRef.SetTable(ProdBOMVersion);
                    ProdBOMVersion.SetRecFilter();
                    PAGE.RunModal(PAGE::"Production BOM Version", ProdBOMVersion);
                end;
            DATABASE::"Routing Version":
                begin
                    RecRef.SetTable(RtngVersion);
                    RtngVersion.SetRecFilter();
                    PAGE.RunModal(PAGE::"Routing Version", RtngVersion);
                end;
            DATABASE::"Machine Center":
                begin
                    RecRef.SetTable(MachineCtr);
                    MachineCtr.SetRecFilter();
                    PAGE.RunModal(PAGE::"Machine Center Card", MachineCtr);
                end;
            DATABASE::"Work Center":
                begin
                    RecRef.SetTable(WorkCtr);
                    WorkCtr.SetRecFilter();
                    PAGE.RunModal(PAGE::"Work Center Card", WorkCtr);
                end;
        end;
    end;
}

