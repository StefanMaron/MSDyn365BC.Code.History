namespace Microsoft.Service.Maintenance;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Setup;

table 5943 "Troubleshooting Header"
{
    Caption = 'Troubleshooting Header';
    LookupPageID = "Troubleshooting List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    ServMgtSetup.Get();
                    NoSeriesMgt.TestManual(ServMgtSetup."Troubleshooting Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        ServMgtSetup.Get();
        if "No." = '' then begin
            ServMgtSetup.TestField("Troubleshooting Nos.");
            NoSeriesMgt.InitSeries(ServMgtSetup."Troubleshooting Nos.", xRec."No. Series", 0D, "No.", "No. Series");
        end;
    end;

    var
        ServMgtSetup: Record "Service Mgt. Setup";
        TblshtgHeader: Record "Troubleshooting Header";
        TblshtgHeader2: Record "Troubleshooting Header";
        TblshtgSetup: Record "Troubleshooting Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Tblshtg: Page Troubleshooting;

        Text000: Label 'No %1 was found.';
        Text001: Label 'No %1 was found for %2 %3.';

    procedure AssistEdit(OldTblshtHeader: Record "Troubleshooting Header"): Boolean
    begin
        with TblshtgHeader do begin
            TblshtgHeader := Rec;
            ServMgtSetup.Get();
            ServMgtSetup.TestField("Troubleshooting Nos.");
            if NoSeriesMgt.SelectSeries(ServMgtSetup."Troubleshooting Nos.", OldTblshtHeader."No. Series", "No. Series") then begin
                NoSeriesMgt.SetSeries("No.");
                Rec := TblshtgHeader;
                exit(true);
            end;
        end;
    end;

    procedure ShowForServItemLine(ServItemLine: Record "Service Item Line")
    var
        TblshtFound: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowForServItemLine(Rec, ServItemLine, IsHandled);
        if IsHandled then
            exit;

        TblshtgSetup.Reset();
        TblshtgSetup.SetRange(Type, TblshtgSetup.Type::"Service Item");
        TblshtgSetup.SetRange("No.", ServItemLine."Service Item No.");
        TblshtFound := TblshtgSetup.FindFirst();

        if not TblshtFound then begin
            TblshtgSetup.SetRange(Type, TblshtgSetup.Type::Item);
            TblshtgSetup.SetRange("No.", ServItemLine."Item No.");
            TblshtFound := TblshtgSetup.FindFirst();
        end;
        if not TblshtFound then begin
            TblshtgSetup.SetRange(Type, TblshtgSetup.Type::"Service Item Group");
            TblshtgSetup.SetRange("No.", ServItemLine."Service Item Group Code");
            TblshtFound := TblshtgSetup.FindFirst();
        end;
        if TblshtFound then
            RunTroubleshooting()
        else
            Message(
              Text000, TblshtgSetup.TableCaption());
    end;

    procedure ShowForServItem(ServItem: Record "Service Item")
    var
        TblshtFound: Boolean;
    begin
        TblshtgSetup.Reset();
        TblshtgSetup.SetRange(Type, TblshtgSetup.Type::"Service Item");
        TblshtgSetup.SetRange("No.", ServItem."No.");
        TblshtFound := TblshtgSetup.FindFirst();

        if not TblshtFound then begin
            TblshtgSetup.Reset();
            TblshtgSetup.SetRange(Type, TblshtgSetup.Type::Item);
            TblshtgSetup.SetRange("No.", ServItem."Item No.");
            TblshtFound := TblshtgSetup.FindFirst();
        end;
        if not TblshtFound then begin
            TblshtgSetup.SetRange(Type, TblshtgSetup.Type::"Service Item Group");
            TblshtgSetup.SetRange("No.", ServItem."Service Item Group Code");
            TblshtFound := TblshtgSetup.FindFirst();
        end;
        if TblshtFound then
            RunTroubleshooting()
        else
            Message(Text001, TblshtgSetup.TableCaption(), ServItem.TableCaption(), ServItem."No.");
    end;

    procedure ShowForItem(Item: Record Item)
    var
        TblshtFound: Boolean;
    begin
        TblshtgSetup.Reset();
        TblshtgSetup.SetRange(Type, TblshtgSetup.Type::Item);
        TblshtgSetup.SetRange("No.", Item."No.");
        TblshtFound := TblshtgSetup.FindFirst();
        if not TblshtFound then begin
            TblshtgSetup.SetRange(Type, TblshtgSetup.Type::"Service Item Group");
            TblshtgSetup.SetRange("No.", Item."Service Item Group");
            TblshtFound := TblshtgSetup.FindFirst();
        end;
        if TblshtFound then
            RunTroubleshooting()
        else
            Message(Text001, TblshtgSetup.TableCaption(), Item.TableCaption(), Item."No.");
    end;

    local procedure MarkTroubleShtgHeader(var TblshtgSetup2: Record "Troubleshooting Setup")
    begin
        TblshtgSetup2.Find('-');
        repeat
            TblshtgHeader2.Get(TblshtgSetup2."Troubleshooting No.");
            TblshtgHeader2.Mark(true);
        until TblshtgSetup2.Next() = 0;
    end;

    local procedure RunTroubleshooting()
    begin
        TblshtgHeader.Get(TblshtgSetup."Troubleshooting No.");
        MarkTroubleShtgHeader(TblshtgSetup);
        TblshtgHeader2.MarkedOnly(true);
        Clear(Tblshtg);
        Tblshtg.SetCaption(Format(TblshtgSetup.Type), TblshtgSetup."No.");
        Tblshtg.SetRecord(TblshtgHeader);
        Tblshtg.SetTableView(TblshtgHeader2);
        Tblshtg.Editable := false;
        Tblshtg.Run();
        TblshtgHeader2.Reset();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowForServItemLine(var TroubleshootingHeader: Record "Troubleshooting Header"; ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;
}

