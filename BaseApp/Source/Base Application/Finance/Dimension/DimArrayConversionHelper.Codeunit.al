// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN23
namespace Microsoft.Finance.Dimension;

using Microsoft.Assembly.Document;
using Microsoft.Bank.Reconciliation;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Journal;
using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Document;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using System.Environment;

codeunit 488 "Dim. Array Conversion Helper"
{
    SingleInstance = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'Temporary codeunit for compatibility';
    ObsoleteTag = '20.0';

    var
        IsInitialized: Boolean;
        SubscriberObjectList: List of [Integer];

    trigger OnRun()
    begin
    end;

    procedure CreateDimTableIDs(RecVariant: Variant; DefaultDimSource: Dictionary of [Integer, Code[20]]; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    var
        DimensionManagement: Codeunit DimensionManagement;
        DefaultDimSourceList: List of [Dictionary of [Integer, Code[20]]];
        i: Integer;
    begin
        for i := 1 to DefaultDimSource.Count do
            DimensionManagement.AddDimSource(DefaultDimSourceList, DefaultDimSource.Keys.Get(i), DefaultDimSource.Values.Get(i));

        CreateDimTableIDs(RecVariant, DefaultDimSourceList, TableID, No);
    end;

    procedure CreateDimTableIDs(RecVariant: Variant; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    var
        RecRef: RecordRef;
        i: Integer;
        DimSource: Dictionary of [Integer, Code[20]];
    begin
        RecRef.GetTable(RecVariant);

        for i := 1 to GetDimArrayLength(RecRef.Number, DefaultDimSource.Count) do begin
            DimSource := DefaultDimSource.Get(i);
            TableID[i] := DimSource.Keys.Get(1);
            No[i] := DimSource.Values.Get(1);
        end;
    end;

    procedure CreateDimTableIDs(TableNum: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    var
        i: Integer;
        DimSource: Dictionary of [Integer, Code[20]];
    begin
        for i := 1 to GetDimArrayLength(TableNum, DefaultDimSource.Count) do begin
            DimSource := DefaultDimSource.Get(i);
            TableID[i] := DimSource.Keys.Get(1);
            No[i] := DimSource.Values.Get(1);
        end;
    end;

    procedure CreateDefaultDimSourcesFromDimArray(RecVariant: Variant; var DefaultDimSource: Dictionary of [Integer, Code[20]]; TableID: array[10] of Integer; No: array[10] of Code[20])
    var
        DimensionManagement: Codeunit DimensionManagement;
        DefaultDimSourceList: List of [Dictionary of [Integer, Code[20]]];
        i: Integer;
    begin
        for i := 1 to DefaultDimSource.Count do
            DimensionManagement.AddDimSource(DefaultDimSourceList, DefaultDimSource.Keys.Get(i), DefaultDimSource.Values.Get(i));

        CreateDefaultDimSourcesFromDimArray(RecVariant, DefaultDimSourceList, TableID, No);
    end;

    procedure CreateDefaultDimSourcesFromDimArray(RecVariant: Variant; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; TableID: array[10] of Integer; No: array[10] of Code[20])
    var
        DimensionManagement: Codeunit DimensionManagement;
        RecRef: RecordRef;
        i: Integer;
        SavedDefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
        DimSource: Dictionary of [Integer, Code[20]];
    begin
        RecRef.GetTable(RecVariant);
        CopyDimSourceList(DefaultDimSource, SavedDefaultDimSource);

        Clear(DefaultDimSource);
        for i := 1 to ArrayLen(TableID) do
            if TableID[i] <> 0 then
                DimensionManagement.AddDimSource(DefaultDimSource, TableID[i], No[i]);

        for i := GetDimArrayLength(RecRef.Number, SavedDefaultDimSource.Count) + 1 to SavedDefaultDimSource.Count do begin
            DimSource := SavedDefaultDimSource.Get(i);
            DimensionManagement.AddDimSource(DefaultDimSource, DimSource.Keys.Get(1), DimSource.Values.Get(1));
        end;
    end;

    procedure CreateDefaultDimSourcesFromDimArray(TableNum: Integer; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; TableID: array[10] of Integer; No: array[10] of Code[20])
    var
        DimensionManagement: Codeunit DimensionManagement;
        i: Integer;
        SavedDefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
        DimSource: Dictionary of [Integer, Code[20]];
    begin
        CopyDimSourceList(DefaultDimSource, SavedDefaultDimSource);

        Clear(DefaultDimSource);
        for i := 1 to ArrayLen(TableID) do
            if TableID[i] <> 0 then
                DimensionManagement.AddDimSource(DefaultDimSource, TableID[i], No[i]);

        for i := GetDimArrayLength(TableNum, SavedDefaultDimSource.Count) + 1 to SavedDefaultDimSource.Count do begin
            DimSource := SavedDefaultDimSource.Get(i);
            DimensionManagement.AddDimSource(DefaultDimSource, DimSource.Keys.Get(1), DimSource.Values.Get(1));
        end;
    end;

    local procedure GetDimArrayLength(TableId: Integer; DictLength: Integer): Integer
    var
        MaxDimArrayLength: Integer;
    begin
        MaxDimArrayLength := GetMaxDimArrayLength(TableId);
        if MaxDimArrayLength > DictLength then
            exit(DictLength);

        exit(MaxDimArrayLength);
    end;

    local procedure GetMaxDimArrayLength(TableNo: Integer): Integer
    begin
        case TableNo of
            Database::"Sales Header":
                exit(5);
            Database::"Sales Line":
                exit(3);
            Database::"Purchase Header":
                exit(4);
            Database::"Purchase Line":
                exit(4);
            Database::"Requisition Line":
                exit(2);
            Database::"Standard Item Journal Line":
                exit(3);
            Database::"Assembly Header":
                exit(1);
            Database::"Assembly Line":
                exit(1);
            Database::"Production Order":
                exit(1);
            Database::"Prod. Order Line":
                exit(1);
            Database::"Prod. Order Component":
                exit(1);
            Database::"Invt. Document Header":
                exit(1);
            Database::"Invt. Document Line":
                exit(2);
            Database::"Phys. Invt. Order Line":
                exit(1);
            Database::Microsoft.Service.Document."Service Header":
                exit(5);
            Database::Microsoft.Service.Document."Service Line":
                exit(3);
            Database::"Planning Component":
                exit(1);
            Database::"Bank Acc. Reconciliation":
                exit(1);
            Database::"Bank Acc. Reconciliation Line":
                exit(2);
            Database::"FA Journal Line":
                exit(2);
            Database::"Finance Charge Memo Header":
                exit(1);
            Database::"Gen. Jnl. Allocation":
                exit(1);
            Database::"Gen. Journal Line":
                exit(5);
            Database::"Insurance Journal Line":
                exit(1);
            Database::"Item Journal Line":
                exit(3);
            Database::"Job Journal Line":
                exit(3);
            Database::"Res. Journal Line":
                exit(3);
            Database::Microsoft.Service.Contract."Service Contract Header":
                exit(5);
            Database::Microsoft.Service.Document."Service Item Line":
                exit(3);
            Database::"Standard General Journal Line":
                exit(5);
            Database::Microsoft.Service.Document."Standard Service Line":
                exit(1);
        end;

        exit(0);
    end;

    local procedure CopyDimSourceList(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; var SavedDefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        DimensionManagement: Codeunit DimensionManagement;
        DimSource: Dictionary of [Integer, Code[20]];
        i: Integer;
    begin
        for i := 1 to DefaultDimSource.Count do begin
            DimSource := DefaultDimSource.Get(i);
            DimensionManagement.AddDimSource(SavedDefaultDimSource, DimSource.Keys.Get(1), DimSource.Values.Get(1));
        end;
    end;

    local procedure Initialize()
    var
        EventSubscription: Record "Event Subscription";
        EventFilterStr: Text;
        ObjectFilterStr: Text;
    begin
        EventFilterStr :=
            'OnAfterCreateDimTableIDs|OnAfterSetDimensions|OnBeforeCreateDim|OnAfterCreateDim|OnGetRecDefaultDimID|OnAfterGetRecDefaultDimID|OnBeforeGetDefaultDimID|OnGetDefaultDimIDOnBeforeFindNewDimSetID|OnBeforeGetTableIDsForHigherPriorities|OnAfterCreateDimForJobJournalLineWithHigherPriorities';
        ObjectFilterStr :=
            '900|901|273|274|5621|302|395|221|81|5635|210|5876|99000829|5407|5406|5405|38|39|295|246|207|202|36|37|5965|5900|5901|5902|751|753|5997|5741|83|408';

        EventSubscription.SetFilter("Published Function", EventFilterStr);
        EventSubscription.SetFilter("Publisher Object ID", ObjectFilterStr);
        EventSubscription.SetFilter("Publisher Object Type", '%1|%2|%3', EventSubscription."Publisher Object Type"::Codeunit, EventSubscription."Publisher Object Type"::Table, EventSubscription."Publisher Object Type"::Report);
        repeat
            SubscriberObjectList.Add(EventSubscription."Publisher Object ID");
        until EventSubscription.Next() = 0;

        IsInitialized := true;
    end;

    internal procedure IsSubscriberExist(ObjectId: Integer): Boolean
    begin
        if not IsInitialized then
            Initialize();

        exit(SubscriberObjectList.Contains(ObjectId));
    end;
}
#endif
