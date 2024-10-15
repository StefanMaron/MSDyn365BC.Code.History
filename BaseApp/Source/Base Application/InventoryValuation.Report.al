report 10139 "Inventory Valuation"
{
    DefaultLayout = RDLC;
    RDLCLayout = './InventoryValuation.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Valuation';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = WHERE(Type = CONST(Inventory));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Inventory Posting Group", "Costing Method", "Location Filter", "Variant Filter";
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(STRSUBSTNO_Text003_AsOfDate_; StrSubstNo(Text003, AsOfDate))
            {
            }
            column(ShowVariants; ShowVariants)
            {
            }
            column(ShowLocations; ShowLocations)
            {
            }
            column(ShowACY; ShowACY)
            {
            }
            column(STRSUBSTNO_Text006_Currency_Description_; StrSubstNo(Text006, Currency.Description))
            {
            }
            column(Item_TABLECAPTION__________ItemFilter; Item.TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(STRSUBSTNO_Text004_InvPostingGroup_TABLECAPTION_InvPostingGroup_Code_InvPostingGroup_Description_; StrSubstNo(Text004, InvPostingGroup.TableCaption, InvPostingGroup.Code, InvPostingGroup.Description))
            {
            }
            column(Item__Inventory_Posting_Group_; "Inventory Posting Group")
            {
            }
            column(Grouping; Grouping)
            {
            }
            column(Item__No__; "No.")
            {
                IncludeCaption = true;
            }
            column(Item_Description; Description)
            {
                IncludeCaption = true;
            }
            column(Item__Base_Unit_of_Measure_; "Base Unit of Measure")
            {
                IncludeCaption = true;
            }
            column(Item__Costing_Method_; "Costing Method")
            {
                IncludeCaption = true;
            }
            column(STRSUBSTNO_Text005_InvPostingGroup_TABLECAPTION_InvPostingGroup_Code_InvPostingGroup_Description_; StrSubstNo(Text005, InvPostingGroup.TableCaption, InvPostingGroup.Code, InvPostingGroup.Description))
            {
            }
            column(Inventory_ValuationCaption; Inventory_ValuationCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(InventoryValue_Control34Caption; InventoryValue_Control34CaptionLbl)
            {
            }
            column(Item_Ledger_Entry__Remaining_Quantity_Caption; "Item Ledger Entry".FieldCaption("Remaining Quantity"))
            {
            }
            column(UnitCost_Control33Caption; UnitCost_Control33CaptionLbl)
            {
            }
            column(Total_Inventory_ValueCaption; Total_Inventory_ValueCaptionLbl)
            {
            }
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = FIELD("No."), "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"), "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"), "Location Code" = FIELD("Location Filter"), "Variant Code" = FIELD("Variant Filter");
                DataItemTableView = SORTING("Item No.", "Variant Code", "Location Code", "Posting Date");

                trigger OnAfterGetRecord()
                begin
                    AdjustItemLedgEntryToAsOfDate("Item Ledger Entry");
                    UpdateBuffer("Item Ledger Entry");
                    CurrReport.Skip();
                end;

                trigger OnPostDataItem()
                begin
                    UpdateTempEntryBuffer;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Posting Date", 0D, AsOfDate);
                end;
            }
            dataitem(BufferLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(RowLabel; TempEntryBuffer.Label)
                {
                }
                column(RemainingQty; TempEntryBuffer."Remaining Quantity")
                {
                }
                column(InventoryValue; TempEntryBuffer.Value1)
                {
                }
                column(VariantCode; TempEntryBuffer."Variant Code")
                {
                }
                column(LocationCode; TempEntryBuffer."Location Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if TempEntryBuffer.Next <> 1 then
                        CurrReport.Break();
                end;

                trigger OnPreDataItem()
                begin
                    Clear(TempEntryBuffer);
                    TempEntryBuffer.SetFilter("Item No.", '%1', Item."No.");
                    if Item."Location Filter" <> '' then
                        TempEntryBuffer.SetFilter("Location Code", '%1', Item."Location Filter");

                    if Item."Variant Filter" <> '' then
                        TempEntryBuffer.SetFilter("Variant Code", '%1', Item."Variant Filter");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not InvPostingGroup.Get("Inventory Posting Group") then
                    Clear(InvPostingGroup);
                TempEntryBuffer.Reset();
                TempEntryBuffer.DeleteAll();
                Progress.Update(1, Format("No."));
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Date Filter", 0D, AsOfDate);
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
                    field(AsOfDate; AsOfDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'As Of Date';
                        ToolTip = 'Specifies the valuation date.';
                        ShowMandatory = true;
                    }
                    field(BreakdownByVariants; ShowVariants)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Breakdown by Variants';
                        ToolTip = 'Specifies the item variants that you want the report to consider.';
                    }
                    field(BreakdownByLocation; ShowLocations)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Breakdown by Location';
                        ToolTip = 'Specifies the breakdown report data by locations.';
                    }
                    field(UseAdditionalReportingCurrency; ShowACY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Additional Reporting Currency';
                        ToolTip = 'Specifies if you want all amounts to be printed by using the additional reporting currency. If you do not select the check box, then all amounts will be printed in US dollars.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        Progress.Close();
    end;

    trigger OnPreReport()
    begin
        Grouping := (Item.FieldCaption("Inventory Posting Group") = Item.CurrentKey);

        if AsOfDate = 0D then
            Error(Text000);
        if ShowLocations and not ShowVariants then
            if not "Item Ledger Entry".SetCurrentKey("Item No.", "Location Code") then
                Error(Text001,
                  "Item Ledger Entry".TableCaption,
                  "Item Ledger Entry".FieldCaption("Item No."),
                  "Item Ledger Entry".FieldCaption("Location Code"));
        if Item.GetFilter("Date Filter") <> '' then
            Error(Text002, Item.FieldCaption("Date Filter"), Item.TableCaption);

        CompanyInformation.Get();
        ItemFilter := Item.GetFilters();
        GLSetup.Get();
        if GLSetup."Additional Reporting Currency" = '' then
            ShowACY := false
        else begin
            Currency.Get(GLSetup."Additional Reporting Currency");
            Currency.TestField("Amount Rounding Precision");
            Currency.TestField("Unit-Amount Rounding Precision");
        end;
        Progress.Open(Item.TableCaption + '  #1############');
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInformation: Record "Company Information";
        InvPostingGroup: Record "Inventory Posting Group";
        Currency: Record Currency;
        Location: Record Location;
        ItemVariant: Record "Item Variant";
        ItemFilter: Text;
        ShowVariants: Boolean;
        ShowLocations: Boolean;
        ShowACY: Boolean;
        AsOfDate: Date;
        Text000: Label 'You must enter an As Of Date.';
        Text001: Label 'If you want to show Locations without also showing Variants, you must add a new key to the %1 table which starts with the %2 and %3 fields.';
        Text002: Label 'Do not set a %1 on the %2.  Use the As Of Date on the Option tab instead.';
        Text003: Label 'Quantities and Values As Of %1';
        Text004: Label '%1 %2 (%3)';
        Text005: Label '%1 %2 (%3) Total';
        Text006: Label 'All Inventory Values are shown in %1.';
        Text007: Label 'No Variant';
        Text008: Label 'No Location';
        Grouping: Boolean;
        Inventory_ValuationCaptionLbl: Label 'Inventory Valuation';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        InventoryValue_Control34CaptionLbl: Label 'Inventory Value';
        UnitCost_Control33CaptionLbl: Label 'Unit Cost';
        Total_Inventory_ValueCaptionLbl: Label 'Total Inventory Value';
        LastItemNo: Code[20];
        LastLocationCode: Code[10];
        LastVariantCode: Code[10];
        TempEntryBuffer: Record "Item Location Variant Buffer" temporary;
        VariantLabel: Text[250];
        LocationLabel: Text[250];
        IsCollecting: Boolean;
        Progress: Dialog;

    local procedure AdjustItemLedgEntryToAsOfDate(var ItemLedgEntry: Record "Item Ledger Entry")
    var
        ItemApplnEntry: Record "Item Application Entry";
        ValueEntry: Record "Value Entry";
        ItemLedgEntry2: Record "Item Ledger Entry";
    begin
        with ItemLedgEntry do begin
            // adjust remaining quantity
            "Remaining Quantity" := Quantity;
            if Positive then begin
                ItemApplnEntry.Reset();
                ItemApplnEntry.SetCurrentKey(
                  "Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.", "Cost Application");
                ItemApplnEntry.SetRange("Inbound Item Entry No.", "Entry No.");
                ItemApplnEntry.SetRange("Posting Date", 0D, AsOfDate);
                ItemApplnEntry.SetFilter("Outbound Item Entry No.", '<>%1', 0);
                ItemApplnEntry.SetFilter("Item Ledger Entry No.", '<>%1', "Entry No.");
                ItemApplnEntry.CalcSums(Quantity);
                "Remaining Quantity" += ItemApplnEntry.Quantity;
            end else begin
                ItemApplnEntry.Reset();
                ItemApplnEntry.SetCurrentKey(
                  "Outbound Item Entry No.", "Item Ledger Entry No.", "Cost Application", "Transferred-from Entry No.");
                ItemApplnEntry.SetRange("Item Ledger Entry No.", "Entry No.");
                ItemApplnEntry.SetRange("Outbound Item Entry No.", "Entry No.");
                ItemApplnEntry.SetRange("Posting Date", 0D, AsOfDate);
                if ItemApplnEntry.Find('-') then
                    repeat
                        if ItemLedgEntry2.Get(ItemApplnEntry."Inbound Item Entry No.") and
                           (ItemLedgEntry2."Posting Date" <= AsOfDate)
                        then
                            "Remaining Quantity" := "Remaining Quantity" - ItemApplnEntry.Quantity;
                    until ItemApplnEntry.Next() = 0;
            end;

            // calculate adjusted cost of entry
            ValueEntry.Reset();
            ValueEntry.SetRange("Item Ledger Entry No.", "Entry No.");
            ValueEntry.SetRange("Posting Date", 0D, AsOfDate);
            ValueEntry.CalcSums(
              "Cost Amount (Expected)", "Cost Amount (Actual)", "Cost Amount (Expected) (ACY)", "Cost Amount (Actual) (ACY)");
            "Cost Amount (Actual)" := Round(ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)");
            "Cost Amount (Actual) (ACY)" :=
              Round(
                ValueEntry."Cost Amount (Actual) (ACY)" + ValueEntry."Cost Amount (Expected) (ACY)", Currency."Amount Rounding Precision");
        end;
    end;

    procedure UpdateBuffer(var ItemLedgEntry: Record "Item Ledger Entry")
    var
        NewRow: Boolean;
    begin
        if ItemLedgEntry."Item No." <> LastItemNo then begin
            ClearLastEntry();
            LastItemNo := ItemLedgEntry."Item No.";
            NewRow := true
        end;

        if ShowVariants or ShowLocations then begin
            if ItemLedgEntry."Variant Code" <> LastVariantCode then begin
                NewRow := true;
                LastVariantCode := ItemLedgEntry."Variant Code";
                if ShowVariants then begin
                    if (ItemLedgEntry."Variant Code" = '') or not ItemVariant.Get(ItemLedgEntry."Item No.", ItemLedgEntry."Variant Code") then
                        VariantLabel := Text007
                    else
                        VariantLabel := ItemVariant.TableCaption + ' ' + ItemLedgEntry."Variant Code" + '(' + ItemVariant.Description + ')';
                end
                else
                    VariantLabel := ''
            end;
            if ItemLedgEntry."Location Code" <> LastLocationCode then begin
                NewRow := true;
                LastLocationCode := ItemLedgEntry."Location Code";
                if ShowLocations then begin
                    if (ItemLedgEntry."Location Code" = '') or not Location.Get(ItemLedgEntry."Location Code") then
                        LocationLabel := Text008
                    else
                        LocationLabel := Location.TableCaption + ' ' + ItemLedgEntry."Location Code" + '(' + Location.Name + ')';
                end
                else
                    LocationLabel := '';
            end
        end;

        if NewRow then
            UpdateTempEntryBuffer();

        TempEntryBuffer."Remaining Quantity" += ItemLedgEntry."Remaining Quantity";
        if ShowACY then
            TempEntryBuffer.Value1 += ItemLedgEntry."Cost Amount (Actual) (ACY)"
        else
            TempEntryBuffer.Value1 += ItemLedgEntry."Cost Amount (Actual)";

        TempEntryBuffer."Item No." := ItemLedgEntry."Item No.";
        TempEntryBuffer."Variant Code" := LastVariantCode;
        TempEntryBuffer."Location Code" := LastLocationCode;
        TempEntryBuffer.Label := CopyStr(VariantLabel + ' ' + LocationLabel, 1, MaxStrLen(TempEntryBuffer.Label));

        IsCollecting := true;
    end;

    procedure ClearLastEntry()
    begin
        LastItemNo := '@@@';
        LastLocationCode := '@@@';
        LastVariantCode := '@@@';
    end;

    procedure UpdateTempEntryBuffer()
    begin
        if IsCollecting and ((TempEntryBuffer."Remaining Quantity" <> 0) or (TempEntryBuffer.Value1 <> 0)) then
            TempEntryBuffer.Insert();
        IsCollecting := false;
        Clear(TempEntryBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnAfterItemGetRecord(var Item: Record Item; var SkipItem: Boolean)
    begin
    end;
}

