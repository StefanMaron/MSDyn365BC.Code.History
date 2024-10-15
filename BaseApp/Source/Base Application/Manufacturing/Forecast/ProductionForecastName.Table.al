namespace Microsoft.Manufacturing.Forecast;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using System.Automation;
using System.Utilities;

table 99000851 "Production Forecast Name"
{
    Caption = 'Demand Forecast Name';
    DrillDownPageID = "Demand Forecast Names";
    LookupPageID = "Demand Forecast Names";
    DataCaptionFields = Name, Description;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "View By"; Enum "Analysis Period Type")
        {
            Caption = 'View By';
        }
        field(4; "Forecast Type"; Enum "Demand Forecast Type")
        {
            Caption = 'Forecast Type';
        }
        field(5; "Location Filter"; Blob)
        {
            Caption = 'Location Filter';
        }
        field(6; "Variant Filter"; Blob)
        {
            Caption = 'Variant Filter';
        }
        field(7; "Item Filter"; Blob)
        {
            Caption = 'Item Filter';
        }
        field(8; "Forecast By Locations"; Boolean)
        {
            Caption = 'Forecast by Locations';
            trigger OnValidate()
            begin
                if not "Forecast By Locations" then begin
                    SetTextFilterToLocationBlob('');
                    Modify();
                end;
            end;
        }
        field(9; "Forecast By Variants"; Boolean)
        {
            Caption = 'Forecast by Variants';
            trigger OnValidate()
            begin
                if not "Forecast By Variants" then begin
                    SetTextFilterToVariantFilterBlob('');
                    Modify();
                end;
            end;
        }
        field(10; "Quantity Type"; Enum "Analysis Amount Type")
        {
            Caption = 'Quantity Type';
        }
        field(11; "Date Filter"; Text[1024])
        {
            Caption = 'Date Filter';
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ProdForecastEntry: Record "Production Forecast Entry";
    begin
        ProdForecastEntry.SetRange("Production Forecast Name", Name);
        if not ProdForecastEntry.IsEmpty() then begin
            if GuiAllowed then
                if not Confirm(Confirm001Qst, true, Name) then
                    Error('');
            ProdForecastEntry.DeleteAll();
        end;
    end;

    var
        Confirm001Qst: Label 'Demand forecast %1 has entries. Do you want to delete it anyway?', Comment = '%1 = forecast name';

    procedure GetItemFilterBlobAsViewFilters(): Text
    begin
        exit(GetItemFilterBlobAsRecordRef().GetView());
    end;

    procedure GetItemFilterAsDisplayText(): Text
    begin
        exit(GetItemFilterBlobAsRecordRef().GetFilters);
    end;

    local procedure GetItemFilterBlobAsRecordRef(): RecordRef
    var
        Item: Record Item;
        TempBlob: Codeunit "Temp Blob";
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FiltersRecordRef: RecordRef;
    begin
        FiltersRecordRef.GetTable(Item);
        CalcFields("Item Filter");
        TempBlob.FromRecord(Rec, FieldNo("Item Filter"));

        RequestPageParametersHelper.ConvertParametersToFilters(FiltersRecordRef, TempBlob);
        exit(FiltersRecordRef);
    end;

    procedure GetItemFilterBlobAsText(): Text
    var
        FiltersInStream: InStream;
        ItemFilterText: Text;
    begin
        CalcFields("Item Filter");
        "Item Filter".CreateInStream(FiltersInStream);
        FiltersInStream.ReadText(ItemFilterText);
        exit(ItemFilterText);
    end;

    procedure SetTextFilterToItemFilterBlob(TextFilter: Text)
    var
        FiltersOutStream: OutStream;
    begin
        Clear("Item Filter");
        "Item Filter".CreateOutStream(FiltersOutStream);
        FiltersOutStream.WriteText(TextFilter);
    end;

    procedure SetTextFilterToVariantFilterBlob(TextFilter: Text)
    var
        FiltersOutStream: OutStream;
    begin
        Clear("Variant Filter");
        "Variant Filter".CreateOutStream(FiltersOutStream);
        FiltersOutStream.WriteText(TextFilter);
    end;

    procedure GetVariantFilterBlobAsText(): Text
    var
        FiltersInStream: InStream;
        VariantFilterText: Text;
    begin
        CalcFields("Variant Filter");
        "Variant Filter".CreateInStream(FiltersInStream);
        FiltersInStream.ReadText(VariantFilterText);
        exit(VariantFilterText);
    end;

    procedure SetTextFilterToLocationBlob(TextFilter: Text)
    var
        FiltersOutStream: OutStream;
    begin
        Clear("Location Filter");
        "Location Filter".CreateOutStream(FiltersOutStream);
        FiltersOutStream.WriteText(TextFilter);
    end;

    procedure GetLocationFilterBlobAsText(): Text
    var
        FiltersInStream: InStream;
        LocationFilterText: Text;
    begin
        CalcFields("Location Filter");
        "Location Filter".CreateInStream(FiltersInStream);
        FiltersInStream.ReadText(LocationFilterText);
        exit(LocationFilterText);
    end;
}

