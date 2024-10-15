namespace Microsoft.Inventory.Item;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Location;
using Microsoft.Utilities;

report 794 "Adjust Item Costs/Prices"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Adjust Item Costs/Prices';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Vendor No.", "Inventory Posting Group", "Costing Method";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");

                case Selection of
                    Selection::"Unit Price":
                        OldFieldValue := "Unit Price";
                    Selection::"Profit %":
                        OldFieldValue := "Profit %";
                    Selection::"Indirect Cost %":
                        OldFieldValue := "Indirect Cost %";
                    Selection::"Last Direct Cost":
                        OldFieldValue := "Last Direct Cost";
                    Selection::"Standard Cost":
                        OldFieldValue := "Standard Cost";
                end;
                NewFieldValue := OldFieldValue * AdjFactor;

                GetGLSetup();
                PriceIsRnded := false;
                if RoundingMethod.Code <> '' then begin
                    RoundingMethod."Minimum Amount" := NewFieldValue;
                    if RoundingMethod.Find('=<') then begin
                        NewFieldValue := NewFieldValue + RoundingMethod."Amount Added Before";
                        if RoundingMethod.Precision > 0 then begin
                            NewFieldValue := Round(NewFieldValue, RoundingMethod.Precision, CopyStr('=><', RoundingMethod.Type + 1, 1));
                            PriceIsRnded := true;
                        end;
                        NewFieldValue := NewFieldValue + RoundingMethod."Amount Added After";
                    end;
                end;
                if not PriceIsRnded then
                    NewFieldValue := Round(NewFieldValue, GLSetup."Unit-Amount Rounding Precision");

                case Selection of
                    Selection::"Unit Price":
                        Validate("Unit Price", NewFieldValue);
                    Selection::"Profit %":
                        Validate("Profit %", NewFieldValue);
                    Selection::"Indirect Cost %":
                        Validate("Indirect Cost %", NewFieldValue);
                    Selection::"Last Direct Cost":
                        Validate("Last Direct Cost", NewFieldValue);
                    Selection::"Standard Cost":
                        Validate("Standard Cost", NewFieldValue);
                end;
                Modify();
            end;

            trigger OnPreDataItem()
            begin
                if AdjustCard = AdjustCard::"Stockkeeping Unit Card" then
                    CurrReport.Break();

                Window.Open(Text000);
            end;
        }
        dataitem("Stockkeeping Unit"; "Stockkeeping Unit")
        {
            DataItemTableView = sorting("Item No.", "Location Code", "Variant Code");

            trigger OnAfterGetRecord()
            begin
                SkipNoneExistingItem("Item No.");

                Window.Update(1, "Item No.");
                Window.Update(2, "Location Code");
                Window.Update(3, "Variant Code");

                case Selection of
                    Selection::"Last Direct Cost":
                        OldFieldValue := "Last Direct Cost";
                    Selection::"Standard Cost":
                        OldFieldValue := "Standard Cost";
                end;
                NewFieldValue := OldFieldValue * AdjFactor;

                PriceIsRnded := false;
                if RoundingMethod.Code <> '' then begin
                    RoundingMethod."Minimum Amount" := NewFieldValue;
                    if RoundingMethod.Find('=<') then begin
                        NewFieldValue := NewFieldValue + RoundingMethod."Amount Added Before";
                        if RoundingMethod.Precision > 0 then begin
                            NewFieldValue := Round(NewFieldValue, RoundingMethod.Precision, CopyStr('=><', RoundingMethod.Type + 1, 1));
                            PriceIsRnded := true;
                        end;
                        NewFieldValue := NewFieldValue + RoundingMethod."Amount Added After";
                    end;
                end;
                if not PriceIsRnded then
                    NewFieldValue := Round(NewFieldValue, 0.00001);

                case Selection of
                    Selection::"Last Direct Cost":
                        Validate("Last Direct Cost", NewFieldValue);
                    Selection::"Standard Cost":
                        Validate("Standard Cost", NewFieldValue);
                end;
                Modify();
            end;

            trigger OnPreDataItem()
            begin
                if AdjustCard = AdjustCard::"Item Card" then
                    CurrReport.Break();

                Item.CopyFilter("No.", "Item No.");
                Item.CopyFilter("Location Filter", "Location Code");
                Item.CopyFilter("Variant Filter", "Variant Code");

                Window.Open(
                  Text002 +
                  Text003 +
                  Text004);
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
                    field(Adjust; AdjustCard)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust';
                        OptionCaption = 'Item Card,Stockkeeping Unit Card';
                        ToolTip = 'Specifies which card is to be adjusted.';

                        trigger OnValidate()
                        begin
                            UpdateEnabled();
                        end;
                    }
                    field(AdjustField; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Field';
                        OptionCaption = 'Unit Price,Profit %,Indirect Cost %,Last Direct Cost,Standard Cost';
                        ToolTip = 'Specifies which field should be adjusted.';

                        trigger OnValidate()
                        begin
                            if Selection = Selection::"Indirect Cost %" then
                                IndirectCost37SelectionOnValid();
                            if Selection = Selection::"Profit %" then
                                Profit37SelectionOnValidate();
                            if Selection = Selection::"Unit Price" then
                                UnitPriceSelectionOnValidate();
                        end;
                    }
                    field(AdjustmentFactor; AdjFactor)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjustment Factor';
                        DecimalPlaces = 0 : 5;
                        MinValue = 0;
                        ToolTip = 'Specifies an adjustment factor to multiply the amounts that you want to copy. By entering an adjustment factor, you can increase or decrease the amounts.';
                    }
                    field(Rounding_Method; RoundingMethod.Code)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Rounding Method';
                        TableRelation = "Rounding Method";
                        ToolTip = 'Specifies a code for the rounding method that you want to apply to costs or prices that you adjust.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            Selection3Enable := true;
            Selection2Enable := true;
            Selection1Enable := true;
        end;

        trigger OnOpenPage()
        begin
            if AdjFactor = 0 then
                AdjFactor := 1;
            UpdateEnabled();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        RoundingMethod.SetRange(Code, RoundingMethod.Code);

        if Item.GetFilters <> '' then
            FilteredItem.CopyFilters(Item);
    end;

    var
        RoundingMethod: Record "Rounding Method";
        GLSetup: Record "General Ledger Setup";
        FilteredItem: Record Item;
        Window: Dialog;
        NewFieldValue: Decimal;
        OldFieldValue: Decimal;
        PriceIsRnded: Boolean;
        GLSetupRead: Boolean;
        AdjFactor: Decimal;
        Selection: Option "Unit Price","Profit %","Indirect Cost %","Last Direct Cost","Standard Cost";
        AdjustCard: Option "Item Card","Stockkeeping Unit Card";
        Selection1Enable: Boolean;
        Selection2Enable: Boolean;
        Selection3Enable: Boolean;
#pragma warning disable AA0470
        SelectionErr: Label '%1 is not a valid selection.';
#pragma warning restore AA0470
        SelectionTxt: Label 'Unit Price,Profit %,Indirect Cost %,Last Direct Cost,Standard Cost';

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Processing items  #1##########';
        Text002: Label 'Processing items     #1##########\';
        Text003: Label 'Processing locations #2##########\';
        Text004: Label 'Processing variants  #3##########';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure UpdateEnabled()
    begin
        PageUpdateEnabled();
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    local procedure PageUpdateEnabled()
    begin
        if AdjustCard = AdjustCard::"Stockkeeping Unit Card" then
            if Selection < 3 then
                Selection := 3;
    end;

    local procedure UnitPriceSelectionOnValidate()
    begin
        if not Selection1Enable then
            Error(SelectionErr, SelectStr(Selection + 1, SelectionTxt));
    end;

    local procedure Profit37SelectionOnValidate()
    begin
        if not Selection2Enable then
            Error(SelectionErr, SelectStr(Selection + 1, SelectionTxt));
    end;

    local procedure IndirectCost37SelectionOnValid()
    begin
        if not Selection3Enable then
            Error(SelectionErr, SelectStr(Selection + 1, SelectionTxt));
    end;

    local procedure SkipNoneExistingItem(ItemNo: Code[20])
    begin
        if Item.GetFilters <> '' then begin
            FilteredItem.SetRange("No.", ItemNo);
            if FilteredItem.IsEmpty() then
                CurrReport.Skip();
        end;
    end;
}

