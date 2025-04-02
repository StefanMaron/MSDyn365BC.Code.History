namespace Microsoft.Purchases.Document;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Inventory;
using Microsoft.Manufacturing.Routing;
using Microsoft.Finance.GeneralLedger.Setup;

tableextension 99000751 "Mfg. Purchase Line" extends "Purchase Line"
{
    fields
    {
        field(5401; "Prod. Order No."; Code[20])
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Prod. Order No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Production Order"."No." where(Status = const(Released));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                CheckDropShipment();

                AddOnIntegrMgt.ValidateProdOrderOnPurchLine(Rec);
            end;
        }
        field(99000750; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            DataClassification = CustomerContent;
            TableRelation = "Routing Header";
        }
        field(99000751; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Prod. Order Routing Line"."Operation No." where(Status = const(Released),
                                                                              "Prod. Order No." = field("Prod. Order No."),
                                                                              "Routing No." = field("Routing No."));

            trigger OnValidate()
            var
                ProdOrderRtngLine: Record "Prod. Order Routing Line";
            begin
                if "Operation No." = '' then
                    exit;

                TestField(Type, Type::Item);
                TestField("Prod. Order No.");
                TestField("Routing No.");

                ProdOrderRtngLine.Get(
                  ProdOrderRtngLine.Status::Released,
                  "Prod. Order No.",
                  "Routing Reference No.",
                  "Routing No.",
                  "Operation No.");

                ProdOrderRtngLine.TestField(
                  Type,
                  ProdOrderRtngLine.Type::"Work Center");

                "Expected Receipt Date" := ProdOrderRtngLine."Ending Date";
                Validate("Work Center No.", ProdOrderRtngLine."No.");
                Validate("Direct Unit Cost", ProdOrderRtngLine."Direct Unit Cost");
            end;
        }
        field(99000752; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Work Center";

            trigger OnValidate()
            var
                GenProductPostingGroup: Record "Gen. Product Posting Group";
            begin
                if Type = Type::"Charge (Item)" then
                    TestField("Work Center No.", '');
                if "Work Center No." = '' then
                    exit;

                WorkCenter.Get("Work Center No.");
                "Gen. Prod. Posting Group" := WorkCenter."Gen. Prod. Posting Group";
                "VAT Prod. Posting Group" := '';
                if GenProductPostingGroup.ValidateVatProdPostingGroup(GenProductPostingGroup, "Gen. Prod. Posting Group") then
                    "VAT Prod. Posting Group" := GenProductPostingGroup."Def. VAT Prod. Posting Group";
                Validate("VAT Prod. Posting Group");

                "Overhead Rate" := WorkCenter."Overhead Rate";
                Validate("Indirect Cost %", WorkCenter."Indirect Cost %");

                CreateDimFromDefaultDim(Rec.FieldNo("Work Center No."));
            end;
        }
        field(99000753; Finished; Boolean)
        {
            Caption = 'Finished';
            DataClassification = CustomerContent;
        }
        field(99000754; "Prod. Order Line No."; Integer)
        {
            Caption = 'Prod. Order Line No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Prod. Order Line"."Line No." where(Status = filter(Released ..),
                                                                 "Prod. Order No." = field("Prod. Order No."));
        }
        field(99000759; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key8; "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.")
        {
        }
    }

    var
        WorkCenter: Record "Work Center";
        AddOnIntegrMgt: Codeunit AddOnIntegrManagement;
        CannotChangeAssociatedLineErr: Label 'You cannot change %1 because the order line is associated with sales order %2.', Comment = '%1 - Prod. Order No., %2 - Sales Order No.';

    procedure CheckDropShipment()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDropShipment(IsHandled, Rec);
        if IsHandled then
            exit;

        if "Drop Shipment" then
            Error(CannotChangeAssociatedLineErr, FieldCaption("Prod. Order No."), "Sales Order No.");
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckDropShipment(var IsHandled: Boolean; var PurchaseLine: Record "Purchase Line")
    begin
    end;
}