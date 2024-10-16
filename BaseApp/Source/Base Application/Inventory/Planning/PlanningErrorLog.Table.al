namespace Microsoft.Inventory.Planning;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Vendor;
using System.Reflection;

table 5430 "Planning Error Log"
{
    Caption = 'Planning Error Log';
    DrillDownPageID = "Planning Error Log";
    LookupPageID = "Planning Error Log";
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Worksheet Template Name"; Code[10])
        {
            Caption = 'Worksheet Template Name';
            TableRelation = "Req. Wksh. Template";
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Requisition Wksh. Name".Name where("Worksheet Template Name" = field("Worksheet Template Name"));
        }
        field(3; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(4; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(5; "Error Description"; Text[250])
        {
            Caption = 'Error Description';
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
        key(Key1; "Worksheet Template Name", "Journal Batch Name", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure Caption(): Text
    var
        ReqWkshName: Record "Requisition Wksh. Name";
    begin
        case true of
            GetFilters = '':
                exit('');
            not ReqWkshName.Get("Worksheet Template Name", "Journal Batch Name"):
                exit('');
            else
                exit(StrSubstNo('%1 %2', "Journal Batch Name", ReqWkshName.Description));
        end;
    end;

    procedure SetJnlBatch(WkshTemplName: Code[10]; JnlBatchName: Code[10]; ItemNo: Code[20])
    begin
        SetRange("Worksheet Template Name", WkshTemplName);
        SetRange("Journal Batch Name", JnlBatchName);
        if Find('+') then;
        "Worksheet Template Name" := WkshTemplName;
        "Journal Batch Name" := JnlBatchName;
        "Item No." := ItemNo;
    end;

    procedure SetError(TheError: Text[250]; TheTableID: Integer; TheTablePosition: Text[250])
    begin
        "Entry No." := "Entry No." + 1;
        "Error Description" := TheError;
        "Table ID" := TheTableID;
        "Table Position" := TheTablePosition;
        Insert();
    end;

    procedure GetError(var PlanningErrorLog: Record "Planning Error Log"): Boolean
    begin
        if not Find('-') then
            exit(false);
        Delete();
        PlanningErrorLog.SetRange("Worksheet Template Name", "Worksheet Template Name");
        PlanningErrorLog.SetRange("Journal Batch Name", "Journal Batch Name");
        if PlanningErrorLog.Find('+') then
            "Entry No." := PlanningErrorLog."Entry No." + 1;

        PlanningErrorLog := Rec;
        PlanningErrorLog.Insert();
        exit(true);
    end;

    procedure ShowError()
    var
        NoSeries: Record "No. Series";
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        MfgSetup: Record "Manufacturing Setup";
        Vendor: Record Vendor;
        Currency: Record Currency;
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
        RtngHeader: Record "Routing Header";
        RtngVersion: Record "Routing Version";
        WorkCenter: Record "Work Center";
        MachCenter: Record "Machine Center";
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
            DATABASE::"Stockkeeping Unit":
                begin
                    RecRef.SetTable(SKU);
                    SKU.SetRecFilter();
                    PAGE.RunModal(PAGE::"Stockkeeping Unit Card", SKU);
                end;
            DATABASE::Currency:
                begin
                    RecRef.SetTable(Currency);
                    Currency.SetRecFilter();
                    PAGE.RunModal(PAGE::Currencies, Currency);
                end;
            DATABASE::Vendor:
                begin
                    RecRef.SetTable(Vendor);
                    Vendor.SetRecFilter();
                    PAGE.RunModal(PAGE::"Vendor Card", Vendor);
                end;
            DATABASE::"No. Series":
                begin
                    RecRef.SetTable(NoSeries);
                    NoSeries.SetRecFilter();
                    PAGE.RunModal(PAGE::"No. Series", NoSeries);
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
                    RecRef.SetTable(MachCenter);
                    MachCenter.SetRecFilter();
                    PAGE.RunModal(PAGE::"Machine Center Card", MachCenter);
                end;
            DATABASE::"Work Center":
                begin
                    RecRef.SetTable(WorkCenter);
                    WorkCenter.SetRecFilter();
                    PAGE.RunModal(PAGE::"Work Center Card", WorkCenter);
                end;
            DATABASE::"Manufacturing Setup":
                begin
                    RecRef.SetTable(MfgSetup);
                    PAGE.RunModal(0, MfgSetup);
                end;
            DATABASE::"Transfer Route":
                PAGE.RunModal(PAGE::"Transfer Routes");
        end;
    end;
}

