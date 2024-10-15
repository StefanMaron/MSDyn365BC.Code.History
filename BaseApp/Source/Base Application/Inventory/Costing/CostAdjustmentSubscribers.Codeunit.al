namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using System.Telemetry;

codeunit 5821 "Cost Adjustment Subscribers"
{
    EventSubscriberInstance = Manual;
    Permissions = tabledata "Cost Adjustment Log" = rimd,
                  tabledata "Cost Adjustment Detailed Log" = rimd,
                  tabledata "Item Register" = r;

    var
        InventorySetup: Record "Inventory Setup";
        TempItem: Record Item temporary;
        TempCostAdjustmentDetailedLog: Record "Cost Adjustment Detailed Log" temporary;
        TempCostAdjustmentLog: Record "Cost Adjustment Log" temporary;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CostAdjustmentRunGuid: Guid;
        CostAdjmtTelemetryCustomDim: Dictionary of [Text, Text];
        StartingDateTime: DateTime;
        LastError: Text[2048];
        LastErrorCallStack: Text[2048];
        FailedItemNo: Code[20];
        CostAdjustmentRunnerFeatureTok: Label 'Cost adjustment batch runner', Locked = true;
        ItemCostAdjustedTok: Label 'Item cost was adjusted with the batch runner.', Locked = true;
        ItemCostNotAdjustedTok: Label 'Item cost was not adjusted with the batch runner.', Locked = true;
        GuidTok: Label 'GUID', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cost Adjustment Runner", OnBeforeRunCostAdjustment, '', false, false)]
    local procedure InitializeBucketRunCostAdjustment()
    begin
        InventorySetup.Get();
        CostAdjustmentRunGuid := CreateGuid();
        Clear(CostAdjmtTelemetryCustomDim);
        CostAdjmtTelemetryCustomDim.Add(GuidTok, Format(CostAdjustmentRunGuid));
        StartingDateTime := CurrentDateTime();
        TempItem.Reset();
        TempItem.DeleteAll();
        TempCostAdjustmentDetailedLog.Reset();
        TempCostAdjustmentDetailedLog.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Report, Report::"Adjust Cost - Item Entries", OnBeforeRunCostAdjustment, '', false, false)]
    local procedure InitializeRegularCostAdjustment()
    begin
        InventorySetup.Get();
        CostAdjustmentRunGuid := CreateGuid();
        StartingDateTime := CurrentDateTime();
        TempItem.Reset();
        TempItem.DeleteAll();
        TempCostAdjustmentDetailedLog.Reset();
        TempCostAdjustmentDetailedLog.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cost Adjustment Runner", OnAfterRunCostAdjustment, '', false, false)]
    local procedure LogLastBucketRun(CostAdjItemBucket: Record "Cost Adj. Item Bucket")
    var
        ItemRegister: Record "Item Register";
        CostAdjustmentLog: Record "Cost Adjustment Log";
        CostAdjustmentDetailedLog: Record "Cost Adjustment Detailed Log";
    begin
        case InventorySetup."Cost Adjustment Logging" of
            InventorySetup."Cost Adjustment Logging"::All:
                begin
                    ItemRegister.SetCurrentKey("Cost Adjustment Run Guid");
                    ItemRegister.SetRange("Cost Adjustment Run Guid", CostAdjustmentRunGuid);
                    ItemRegister.SetLoadFields("No.");
                    if ItemRegister.FindSet() then
                        repeat
                            Clear(CostAdjustmentLog);
                            CostAdjustmentLog."Cost Adjustment Run Guid" := CostAdjustmentRunGuid;
                            CostAdjustmentLog."Item Filter" := CostAdjItemBucket."Item Filter";
                            CostAdjustmentLog.Status := CostAdjItemBucket.Status;
                            CostAdjustmentLog."Starting Date-Time" := StartingDateTime;
                            CostAdjustmentLog."Ending Date-Time" := CurrentDateTime();
                            CostAdjustmentLog."Item Register No." := ItemRegister."No.";
                            CostAdjustmentLog.Insert();
                        until ItemRegister.Next() = 0
                    else begin
                        // in case the cost adjustment run is not logged in item register (e.g. no item is adjusted)
                        Clear(CostAdjustmentLog);
                        CostAdjustmentLog."Cost Adjustment Run Guid" := CostAdjustmentRunGuid;
                        CostAdjustmentLog."Item Filter" := CostAdjItemBucket."Item Filter";
                        CostAdjustmentLog.Status := CostAdjItemBucket.Status;
                        CostAdjustmentLog."Starting Date-Time" := StartingDateTime;
                        CostAdjustmentLog."Ending Date-Time" := CurrentDateTime();
                        CostAdjustmentLog."Last Error" := CostAdjItemBucket."Last Error";
                        CostAdjustmentLog."Last Error Call Stack" := CostAdjItemBucket."Last Error Call Stack";
                        CostAdjustmentLog."Failed Item No." := CostAdjItemBucket."Failed Item No.";
                        CostAdjustmentLog.Insert();
                    end;

                    TempCostAdjustmentDetailedLog.Reset();
                    if CostAdjustmentLog."Failed Item No." <> '' then
                        TempCostAdjustmentDetailedLog.SetRange("Item No.", CostAdjustmentLog."Failed Item No.");
                    if TempCostAdjustmentDetailedLog.FindSet() then
                        repeat
                            CostAdjustmentDetailedLog := TempCostAdjustmentDetailedLog;
                            CostAdjustmentDetailedLog.Insert();
                        until TempCostAdjustmentDetailedLog.Next() = 0;
                end;
            InventorySetup."Cost Adjustment Logging"::"Errors Only":
                begin
                    if CostAdjItemBucket.Status <> CostAdjItemBucket.Status::Failed then
                        exit;

                    Clear(CostAdjustmentLog);
                    CostAdjustmentLog."Cost Adjustment Run Guid" := CostAdjustmentRunGuid;
                    CostAdjustmentLog."Item Filter" := CostAdjItemBucket."Item Filter";
                    CostAdjustmentLog.Status := CostAdjItemBucket.Status;
                    CostAdjustmentLog."Starting Date-Time" := StartingDateTime;
                    CostAdjustmentLog."Ending Date-Time" := CurrentDateTime();
                    CostAdjustmentLog."Last Error" := CostAdjItemBucket."Last Error";
                    CostAdjustmentLog."Last Error Call Stack" := CostAdjItemBucket."Last Error Call Stack";
                    CostAdjustmentLog."Failed Item No." := CostAdjItemBucket."Failed Item No.";
                    CostAdjustmentLog.Insert();

                    TempCostAdjustmentDetailedLog.Reset();
                    TempCostAdjustmentDetailedLog.SetRange("Item No.", CostAdjustmentLog."Failed Item No.");
                    if TempCostAdjustmentDetailedLog.FindFirst() then begin
                        CostAdjustmentDetailedLog := TempCostAdjustmentDetailedLog;
                        CostAdjustmentDetailedLog.Insert();
                    end;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Adjust Cost - Item Entries", OnAfterRunCostAdjustment, '', false, false)]
    local procedure LogLastOrdinaryRun(var Item: Record Item)
    var
        ItemRegister: Record "Item Register";
        CostAdjustmentLog: Record "Cost Adjustment Log";
        CostAdjustmentDetailedLog: Record "Cost Adjustment Detailed Log";
    begin
        case InventorySetup."Cost Adjustment Logging" of
            InventorySetup."Cost Adjustment Logging"::All:
                begin
                    ItemRegister.SetCurrentKey("Cost Adjustment Run Guid");
                    ItemRegister.SetRange("Cost Adjustment Run Guid", CostAdjustmentRunGuid);
                    ItemRegister.SetLoadFields("No.");
                    if ItemRegister.FindSet() then
                        repeat
                            Clear(CostAdjustmentLog);
                            CostAdjustmentLog."Cost Adjustment Run Guid" := CostAdjustmentRunGuid;
                            CostAdjustmentLog."Item Filter" := CopyStr(Item.GetFilters(), 1, MaxStrLen(CostAdjustmentLog."Item Filter"));
                            CostAdjustmentLog.Status := TempCostAdjustmentLog.Status;
                            CostAdjustmentLog."Starting Date-Time" := StartingDateTime;
                            CostAdjustmentLog."Ending Date-Time" := CurrentDateTime();
                            CostAdjustmentLog."Item Register No." := ItemRegister."No.";
                            CostAdjustmentLog.Insert();
                        until ItemRegister.Next() = 0
                    else begin
                        // in case the cost adjustment run is not logged in item register (e.g. no item is adjusted)
                        Clear(CostAdjustmentLog);
                        CostAdjustmentLog."Cost Adjustment Run Guid" := CostAdjustmentRunGuid;
                        CostAdjustmentLog."Item Filter" := CopyStr(Item.GetFilters(), 1, MaxStrLen(CostAdjustmentLog."Item Filter"));
                        CostAdjustmentLog.Status := TempCostAdjustmentLog.Status;
                        CostAdjustmentLog."Starting Date-Time" := StartingDateTime;
                        CostAdjustmentLog."Ending Date-Time" := CurrentDateTime();
                        CostAdjustmentLog."Last Error" := LastError;
                        CostAdjustmentLog."Last Error Call Stack" := LastErrorCallStack;
                        CostAdjustmentLog."Failed Item No." := FailedItemNo;
                        CostAdjustmentLog.Insert();
                    end;

                    TempCostAdjustmentDetailedLog.Reset();
                    if CostAdjustmentLog."Failed Item No." <> '' then
                        TempCostAdjustmentDetailedLog.SetRange("Item No.", CostAdjustmentLog."Failed Item No.");
                    if TempCostAdjustmentDetailedLog.FindSet() then
                        repeat
                            CostAdjustmentDetailedLog := TempCostAdjustmentDetailedLog;
                            CostAdjustmentDetailedLog.Insert();
                        until TempCostAdjustmentDetailedLog.Next() = 0;
                end;
            InventorySetup."Cost Adjustment Logging"::"Errors Only":
                begin
                    if TempCostAdjustmentLog.Status <> TempCostAdjustmentLog.Status::Failed then
                        exit;

                    Clear(CostAdjustmentLog);
                    CostAdjustmentLog."Cost Adjustment Run Guid" := CostAdjustmentRunGuid;
                    CostAdjustmentLog."Item Filter" := CopyStr(Item.GetFilters(), 1, MaxStrLen(CostAdjustmentLog."Item Filter"));
                    CostAdjustmentLog.Status := TempCostAdjustmentLog.Status;
                    CostAdjustmentLog."Starting Date-Time" := StartingDateTime;
                    CostAdjustmentLog."Ending Date-Time" := CurrentDateTime();
                    CostAdjustmentLog."Last Error" := LastError;
                    CostAdjustmentLog."Last Error Call Stack" := LastErrorCallStack;
                    CostAdjustmentLog."Failed Item No." := FailedItemNo;
                    CostAdjustmentLog.Insert();

                    TempCostAdjustmentDetailedLog.Reset();
                    TempCostAdjustmentDetailedLog.SetRange("Item No.", CostAdjustmentLog."Failed Item No.");
                    if TempCostAdjustmentDetailedLog.FindFirst() then begin
                        CostAdjustmentDetailedLog := TempCostAdjustmentDetailedLog;
                        CostAdjustmentDetailedLog.Insert();
                    end;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cost Adjustment Runner", OnRegisterSuccess, '', false, false)]
    local procedure RegisterSuccessBucketRun(var CostAdjItemBucket: Record "Cost Adj. Item Bucket")
    begin
        FeatureTelemetry.LogUsage('0000MEN', CostAdjustmentRunnerFeatureTok, ItemCostAdjustedTok, CostAdjmtTelemetryCustomDim);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cost Adjustment Runner", OnRegisterFailure, '', false, false)]
    local procedure RegisterFailureBucketRun(var CostAdjItemBucket: Record "Cost Adj. Item Bucket")
    begin
        if TempItem.FindLast() then
            CostAdjItemBucket."Failed Item No." := TempItem."No.";

        FeatureTelemetry.LogUsage('0000MEO', CostAdjustmentRunnerFeatureTok, ItemCostNotAdjustedTok, CostAdjmtTelemetryCustomDim);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Adjust Cost - Item Entries", OnRegisterSuccess, '', false, false)]
    local procedure RegisterSuccessRegularRun()
    begin
        TempCostAdjustmentLog.Status := TempCostAdjustmentLog.Status::Success;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Adjust Cost - Item Entries", OnRegisterFailure, '', false, false)]
    local procedure RegisterFailureRegularRun()
    begin
        if TempItem.FindLast() then
            FailedItemNo := TempItem."No.";
        TempCostAdjustmentLog.Status := TempCostAdjustmentLog.Status::Failed;
        LastError := CopyStr(GetLastErrorText(), 1, MaxStrLen(LastError));
        LastErrorCallStack := CopyStr(GetLastErrorCallStack(), 1, MaxStrLen(LastErrorCallStack));

        TempCostAdjustmentDetailedLog."Cost Adjustment Run Guid" := CostAdjustmentRunGuid;
        TempCostAdjustmentDetailedLog."Item No." := FailedItemNo;
        if TempCostAdjustmentDetailedLog.Find() then begin
            TempCostAdjustmentDetailedLog."Ending Date-Time" := CurrentDateTime();
            TempCostAdjustmentDetailedLog.Duration += (TempCostAdjustmentDetailedLog."Ending Date-Time" - TempCostAdjustmentDetailedLog."Interim Date-Time");
            TempCostAdjustmentDetailedLog.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnInsertItemRegOnBeforeItemRegInsert', '', false, false)]
    local procedure AddGuidToItemRegister(var ItemRegister: Record "Item Register")
    begin
        ItemRegister."Cost Adjustment Run Guid" := CostAdjustmentRunGuid;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", 'OnBeforeAdjustItem', '', false, false)]
    local procedure PushItemBeforeAdjustment(var TheItem: Record Item)
    begin
        TempItem := TheItem;
        if TempItem.Insert() then;

        TempCostAdjustmentDetailedLog."Cost Adjustment Run Guid" := CostAdjustmentRunGuid;
        TempCostAdjustmentDetailedLog."Item No." := TheItem."No.";
        if TempCostAdjustmentDetailedLog.Find() then begin
            TempCostAdjustmentDetailedLog."Interim Date-Time" := CurrentDateTime();
            TempCostAdjustmentDetailedLog.Modify();
        end else begin
            TempCostAdjustmentDetailedLog."Starting Date-Time" := CurrentDateTime();
            TempCostAdjustmentDetailedLog."Interim Date-Time" := TempCostAdjustmentDetailedLog."Starting Date-Time";
            TempCostAdjustmentDetailedLog.Insert();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", 'OnAfterAdjustItem', '', false, false)]
    local procedure PopItemAfterAdjustment(var TheItem: Record Item)
    begin
        if TempItem.Get(TheItem."No.") then
            TempItem.Delete();

        TempCostAdjustmentDetailedLog."Cost Adjustment Run Guid" := CostAdjustmentRunGuid;
        TempCostAdjustmentDetailedLog."Item No." := TheItem."No.";
        if TempCostAdjustmentDetailedLog.Find() then begin
            TempCostAdjustmentDetailedLog."Ending Date-Time" := CurrentDateTime();
            TempCostAdjustmentDetailedLog.Duration += (TempCostAdjustmentDetailedLog."Ending Date-Time" - TempCostAdjustmentDetailedLog."Interim Date-Time");
            TempCostAdjustmentDetailedLog.Modify();
        end;
    end;
}