namespace Microsoft.Manufacturing.StandardCost;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;
#if not CLEAN23
using Microsoft.Pricing.Calculation;
#endif
using Microsoft.Pricing.PriceList;
#if not CLEAN23
using Microsoft.Projects.Resources.Pricing;
#endif
using Microsoft.Projects.Resources.Resource;
using Microsoft.Inventory.Costing;

report 5855 "Implement Standard Cost Change"
{
    Caption = 'Implement Standard Cost Change';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Standard Cost Worksheet"; "Standard Cost Worksheet")
        {
            DataItemTableView = sorting("Standard Cost Worksheet Name", Type, "No.");
            RequestFilterFields = Type, "No.";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, Type);
                Window.Update(2, "No.");

                case Type of
                    Type::Item:
                        begin
                            UpdateItem("Standard Cost Worksheet");
                            UpdateSKU("Standard Cost Worksheet");
                            InsertRevalItemJnlLine();
                        end;
                    Type::"Work Center":
                        UpdateWorkCenter("Standard Cost Worksheet");
                    Type::"Machine Center":
                        UpdateMachCenter("Standard Cost Worksheet");
                    Type::Resource:
                        UpdateRes("Standard Cost Worksheet");
                end;
                UpdateStdCostWksh("Standard Cost Worksheet")
            end;

            trigger OnPostDataItem()
            begin
                if not NoMessage then
                    Message(GetMessage());
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Standard Cost Worksheet Name", StdCostWkshName);
                if IsEmpty() then
                    Error(Text013, StdCostWkshName);

                Window.Open(
                  Text000 +
                  Text007 +
                  Text008);

                ItemJnlLine.LockTable();
                LockTable();

                RevalJnlCreated := false;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the date that the revaluation should take place.';
                    }
                    field(DocumentNo; DocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the revaluation journal lines.';
                    }
                    field(ItemJournalTemplate; RevalItemJnlTemplate.Name)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Journal Template ';
                        NotBlank = true;
                        TableRelation = "Item Journal Template" where(Type = const(Revaluation));
                        ToolTip = 'Specifies the name of the revaluation journal template.';
                    }
                    field(ItemJournalBatchName; RevalItemJnlBatch.Name)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Journal Batch Name';
                        NotBlank = true;
                        TableRelation = "Item Journal Batch".Name;
                        ToolTip = 'Specifies the name of the actual revaluation journal.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            RevalItemJnlBatch.SetFilter("Journal Template Name", RevalItemJnlTemplate.Name);
                            if PAGE.RunModal(0, RevalItemJnlBatch) = ACTION::LookupOK then begin
                                Text := Text + RevalItemJnlBatch.Name;
                                exit(true);
                            end;
                            exit(false);
                        end;

                        trigger OnValidate()
                        begin
                            RevalItemJnlBatchNameOnAfterVa();
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PostingDate = 0D then
                PostingDate := WorkDate();

            ValidatePostingDate();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        RevalItemJnlTemplate.Get(RevalItemJnlTemplate.Name);
        RevalItemJnlTemplate.TestField(Type, RevalItemJnlTemplate.Type::Revaluation);
        RevalItemJnlBatch.Get(RevalItemJnlTemplate.Name, RevalItemJnlBatch.Name);

        if DocNo = '' then
            Error(Text001);
        if StdCostWkshName = '' then
            Error(Text002);
    end;

    var
        ItemJnlLine: Record "Item Journal Line";
        RevalItemJnlTemplate: Record "Item Journal Template";
        RevalItemJnlBatch: Record "Item Journal Batch";
        Window: Dialog;
        StdCostWkshName: Code[10];
        DocNo: Code[20];
        Text000: Label 'Implementing standard cost changes...\\';
        Text001: Label 'You must specify a document no.';
        Text002: Label 'You must specify a worksheet to implement from.';
        Text007: Label 'Type                       #1##########\';
        Text008: Label 'No.                        #2##########';
        Text009: Label '\Revaluation journal lines have also been created.';
        RevalJnlCreated: Boolean;
        ItemCostsUpdated: Boolean;
        MachCtrCostsUpdated: Boolean;
        WorkCtrCostsUpdated: Boolean;
        ResCostsUpdated: Boolean;
        SKUCostsUpdated: Boolean;
        NoMessage: Boolean;
        HideDuplWarning: Boolean;
        Text010: Label 'Costs have been updated on the following: ';
        Text011: Label ', ';
        Text012: Label '.';
        Text013: Label 'Standard Cost Worksheet %1 is empty.';

    protected var
        PostingDate: Date;

    local procedure UpdateItem(StdCostWksh: Record "Standard Cost Worksheet")
    var
        Item: Record Item;
    begin
        OnBeforeUpdateItem(StdCostWksh, PostingDate);
        Item.Get(StdCostWksh."No.");
        Item.Validate("Indirect Cost %", StdCostWksh."New Indirect Cost %");
        Item.Validate("Overhead Rate", StdCostWksh."New Overhead Rate");
        Item.Validate("Standard Cost", StdCostWksh."New Standard Cost");
        Item."Single-Level Material Cost" := StdCostWksh."New Single-Lvl Material Cost";
        Item."Single-Level Capacity Cost" := StdCostWksh."New Single-Lvl Cap. Cost";
        Item."Single-Level Subcontrd. Cost" := StdCostWksh."New Single-Lvl Subcontrd Cost";
        Item."Single-Level Cap. Ovhd Cost" := StdCostWksh."New Single-Lvl Cap. Ovhd Cost";
        Item."Single-Level Mfg. Ovhd Cost" := StdCostWksh."New Single-Lvl Mfg. Ovhd Cost";

        Item."Rolled-up Material Cost" := StdCostWksh."New Rolled-up Material Cost";
        Item."Rolled-up Capacity Cost" := StdCostWksh."New Rolled-up Cap. Cost";
        Item."Rolled-up Subcontracted Cost" := StdCostWksh."New Rolled-up Subcontrd Cost";
        Item."Rolled-up Mfg. Ovhd Cost" := StdCostWksh."New Rolled-up Mfg. Ovhd Cost";
        Item."Rolled-up Cap. Overhead Cost" := StdCostWksh."New Rolled-up Cap. Ovhd Cost";

        Item."Last Unit Cost Calc. Date" := PostingDate;
        OnUpdateItemOnBeforeModify(StdCostWksh, Item);
        Item.Modify(true);

        ItemCostsUpdated := true;
    end;

    local procedure UpdateSKU(StdCostWksh: Record "Standard Cost Worksheet")
    var
        SKU: Record "Stockkeeping Unit";
        IsHandled: Boolean;
    begin
        SKU.SetRange("Item No.", StdCostWksh."No.");
        if SKU.Find('-') then begin
            SKUCostsUpdated := true;
            repeat
                IsHandled := false;
                OnUpdateSKUOnBeforeValidateStandardCost(StdCostWksh, SKU, IsHandled);
                if not IsHandled then
                    SKU.Validate("Standard Cost", StdCostWksh."New Standard Cost");
                SKU.Modify(true);
            until SKU.Next() = 0;
        end;
    end;

    local procedure UpdateMachCenter(StdCostWksh: Record "Standard Cost Worksheet")
    var
        MachCtr: Record "Machine Center";
    begin
        OnBeforeUpdateMachCenter(StdCostWksh, PostingDate);
        MachCtr.Get(StdCostWksh."No.");
        MachCtr.Validate("Overhead Rate", StdCostWksh."New Overhead Rate");
        MachCtr.Validate("Indirect Cost %", StdCostWksh."New Indirect Cost %");
        MachCtr.Validate("Unit Cost", StdCostWksh."New Standard Cost");
        MachCtr.Modify(true);
        MachCtrCostsUpdated := true;
    end;

    local procedure UpdateWorkCenter(StdCostWksh: Record "Standard Cost Worksheet")
    var
        WorkCtr: Record "Work Center";
    begin
        OnBeforeUpdateWorkCenter(StdCostWksh, PostingDate);
        WorkCtr.Get(StdCostWksh."No.");
        WorkCtr.Validate("Overhead Rate", StdCostWksh."New Overhead Rate");
        WorkCtr.Validate("Indirect Cost %", StdCostWksh."New Indirect Cost %");
        WorkCtr.Validate("Unit Cost", StdCostWksh."New Standard Cost");
        WorkCtr.Modify(true);
        WorkCtrCostsUpdated := true;
    end;

    local procedure UpdateRes(StdCostWksh: Record "Standard Cost Worksheet")
    var
        Resource: Record Resource;
    begin
        Resource.Get(StdCostWksh."No.");
        Resource.Validate(Resource."Indirect Cost %", StdCostWksh."New Indirect Cost %");
        Resource.Validate(Resource."Unit Cost", StdCostWksh."New Standard Cost");
        Resource.Modify(true);
        ResCostsUpdated := true;

        UpdateResourceCost(StdCostWksh, Resource);
    end;

    local procedure UpdateStdCostWksh(var StdCostWksh: Record "Standard Cost Worksheet")
    begin
        StdCostWksh.Implemented := true;
        StdCostWksh.Modify(true);
    end;

    local procedure InsertRevalItemJnlLine()
    var
        GLSetup: Record "General Ledger Setup";
        ItemJnlLine2: Record "Item Journal Line";
        IsHandled: Boolean;
    begin
        ItemJnlLine2.SetRange("Journal Template Name", RevalItemJnlTemplate.Name);
        ItemJnlLine2.SetRange("Journal Batch Name", RevalItemJnlBatch.Name);
        if ItemJnlLine2.Find('+') then;

        CalculateInventoryValue();
        HideDuplWarning := true;

        GLSetup.Get();
        IsHandled := false;
        OnInsertRevalItemJnlLineOnBeforeItemJnlLineLoop(ItemJnlLine2, RevalJnlCreated, IsHandled);
        if not IsHandled then
            if ItemJnlLine2.Next() <> 0 then
                repeat
                    ItemJnlLine2.Validate(
                      "Unit Cost (Revalued)", Round("Standard Cost Worksheet"."New Standard Cost", GLSetup."Unit-Amount Rounding Precision"));
                    ItemJnlLine2.Modify(true);
                    RevalJnlCreated := true;
                until ItemJnlLine2.Next() = 0;
    end;

    procedure SetStdCostWksh(NewStdCostWkshName: Code[10])
    begin
        StdCostWkshName := NewStdCostWkshName;
    end;

    local procedure GetMessage() TheMsg: Text[250]
    var
        Item: Record Item;
        MachCtr: Record "Machine Center";
        WorkCtr: Record "Work Center";
        Res: Record Resource;
        SKU: Record "Stockkeeping Unit";
    begin
        TheMsg := '';
        if ItemCostsUpdated then
            TheMsg := Item.TableCaption();
        if SKUCostsUpdated then begin
            TheMsg := TheMsg + Text011;
            TheMsg := TheMsg + SKU.TableCaption();
        end;
        if MachCtrCostsUpdated then begin
            if TheMsg <> '' then
                TheMsg := TheMsg + Text011;
            TheMsg := TheMsg + MachCtr.TableCaption();
        end;
        if WorkCtrCostsUpdated then begin
            if TheMsg <> '' then
                TheMsg := TheMsg + Text011;
            TheMsg := TheMsg + WorkCtr.TableCaption();
        end;
        if ResCostsUpdated then begin
            if TheMsg <> '' then
                TheMsg := TheMsg + Text011;
            TheMsg := TheMsg + Res.TableCaption();
        end;
        if TheMsg <> '' then
            TheMsg := Text010 + TheMsg + Text012;
        if RevalJnlCreated then
            TheMsg := TheMsg + Text009;
        exit(TheMsg);
    end;

    local procedure ValidatePostingDate()
    var
        NoSeries: Codeunit "No. Series";
    begin
        if RevalItemJnlBatch.Get(RevalItemJnlTemplate.Name, RevalItemJnlBatch.Name) then
            if RevalItemJnlBatch."No. Series" = '' then
                DocNo := ''
            else
                DocNo := NoSeries.PeekNextNo(RevalItemJnlBatch."No. Series", PostingDate);
    end;

    procedure Initialize()
    var
        DocNo2: Code[20];
        PostingDate2: Date;
        RevalItemJnlTemplate2: Code[10];
        RevalItemJnlBatch2: Code[10];
        NoMessage2: Boolean;
    begin
        PostingDate := PostingDate2;
        DocNo := DocNo2;
        RevalItemJnlTemplate.Get(RevalItemJnlTemplate2);
        RevalItemJnlBatch.Get(RevalItemJnlTemplate2, RevalItemJnlBatch2);
        NoMessage := NoMessage2;
    end;

    local procedure RevalItemJnlBatchNameOnAfterVa()
    begin
        ValidatePostingDate();
    end;

    local procedure CalculateInventoryValue()
    var
        Item: Record Item;
        CalcInvtValue: Report "Calculate Inventory Value";
        CalculatePer: Enum "Inventory Value Calc. Per";
        IsHandled: Boolean;
    begin
        OnBeforeCalculateInventoryValue(RevalItemJnlTemplate, "Standard Cost Worksheet", PostingDate, DocNo, HideDuplWarning, IsHandled, RevalItemJnlBatch);
        if IsHandled then
            exit;

        ItemJnlLine."Journal Template Name" := RevalItemJnlTemplate.Name;
        ItemJnlLine."Journal Batch Name" := RevalItemJnlBatch.Name;
        CalcInvtValue.SetItemJnlLine(ItemJnlLine);
        Clear(Item);
        Item.SetRange("No.", "Standard Cost Worksheet"."No.");
        CalcInvtValue.SetTableView(Item);
        CalcInvtValue.SetParameters(PostingDate, DocNo, HideDuplWarning, CalculatePer::Item, false, false, false, "Inventory Value Calc. Base"::" ", false);
        CalcInvtValue.UseRequestPage(false);
        OnCalculateInventoryValueOnBeforeCalcInvtValueRun(CalcInvtValue, PostingDate, DocNo, HideDuplWarning);
        CalcInvtValue.Run();
    end;

    local procedure UpdateResourceCost(StandardCostWorksheet: Record "Standard Cost Worksheet"; Resource: Record Resource)
    var
        PriceListLine: Record "Price List Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateResourceCost(StandardCostWorksheet, Resource, IsHandled);
        if IsHandled then
            exit;

#if not CLEAN23
        if UpdateOldResourceCost(StandardCostWorksheet, Resource) then
            exit;
#endif
        PriceListLine.Reset();
        PriceListLine.SetRange("Price Type", PriceListLine."Price Type"::Purchase);
        PriceListLine.SetRange("Source Type", PriceListLine."Source Type"::"All Jobs");
        PriceListLine.SetRange("Asset Type", PriceListLine."Asset Type"::Resource);
        PriceListLine.SetRange("Asset No.", Resource."No.");
        PriceListLine.SetRange("Work Type Code", '');
        PriceListLine.SetRange("Starting Date", 0D);
        PriceListLine.SetRange("Ending Date", 0D);
        PriceListLine.SetRange("Minimum Quantity", 0);
        PriceListLine.SetRange(Status, PriceListLine.Status::Draft, PriceListLine.Status::Active);
        if PriceListLine.FindFirst() then begin
            if PriceListLine.Status = PriceListLine.Status::Active then begin
                PriceListLine.Status := PriceListLine.Status::Draft;
                PriceListLine.Modify();
            end;
            PriceListLine.Validate("Direct Unit Cost", Resource."Direct Unit Cost");
            PriceListLine.Validate("Unit Cost", StandardCostWorksheet."New Standard Cost");
            PriceListLine.Status := PriceListLine.Status::Active;
            PriceListLine.Modify(true);
        end;
    end;

#if not CLEAN23
    local procedure UpdateOldResourceCost(StandardCostWorksheet: Record "Standard Cost Worksheet"; Resource: Record Resource): Boolean;
    var
        ResourceCost: Record "Resource Cost";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        if PriceCalculationMgt.IsExtendedPriceCalculationEnabled() then
            exit(false);

        ResourceCost.Type := ResourceCost.Type::Resource;
        ResourceCost.Code := StandardCostWorksheet."No.";
        ResourceCost.Validate("Direct Unit Cost", Resource."Direct Unit Cost");
        ResourceCost.Validate("Unit Cost", StandardCostWorksheet."New Standard Cost");
        if not ResourceCost.Modify(true) then;
        exit(true);
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateInventoryValue(var ItemJournalTemplate: Record "Item Journal Template"; var StandardCostWorksheet: Record "Standard Cost Worksheet"; PostingDate: Date; DocNo: Code[20]; HideDuplWarning: Boolean; var IsHandled: Boolean; var ItemJournalBatch: Record "Item Journal Batch");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateResourceCost(StandardCostWorksheet: Record "Standard Cost Worksheet"; Resource: Record Resource; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateItem(var StandardCostWorksheet: Record "Standard Cost Worksheet"; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateMachCenter(var StandardCostWorksheet: Record "Standard Cost Worksheet"; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWorkCenter(var StandardCostWorksheet: Record "Standard Cost Worksheet"; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemOnBeforeModify(StandardCostWorksheet: Record "Standard Cost Worksheet"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateInventoryValueOnBeforeCalcInvtValueRun(var CalculateInventoryValue: Report "Calculate Inventory Value"; NewPostingDate: Date; NewDocNo: Code[20]; NewHideDuplWarning: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSKUOnBeforeValidateStandardCost(StandardCostWorksheet: Record "Standard Cost Worksheet"; var StockkeepingUnit: Record "Stockkeeping Unit"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertRevalItemJnlLineOnBeforeItemJnlLineLoop(var ItemJournalLine: Record "Item Journal Line"; var RevalJnlCreated: Boolean; var IsHandled: Boolean)
    begin
    end;
}

