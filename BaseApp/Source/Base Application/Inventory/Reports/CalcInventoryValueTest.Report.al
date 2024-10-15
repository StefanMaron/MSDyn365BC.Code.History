namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Inventory.Costing;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Utilities;
using System.Utilities;

report 5811 "Calc. Inventory Value - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/CalcInventoryValueTest.rdlc';
    Caption = 'Calc. Inventory Value - Test';

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(STRSUBSTNO_Text000_FORMAT_PostingDate__; StrSubstNo(Text000, Format(PostingDate)))
            {
            }
            column(STRSUBSTNO___1___2__Item_TABLECAPTION_ItemFilter_; StrSubstNo('%1: %2', TableCaption(), ItemFilter))
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(Standard_Cost_Revaluation___TestCaption; Standard_Cost_Revaluation___TestCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }

            trigger OnPreDataItem()
            begin
                if GetFilter("Date Filter") <> '' then
                    Error(Text005, FieldCaption("Date Filter"));

                if PostingDate = 0D then
                    Error(Text006);

                if (CalculatePer = CalculatePer::Item) and (GetFilter("Bin Filter") <> '') then
                    Error(Text007, FieldCaption("Bin Filter"));

                CheckCalcInvtVal.SetParameters(PostingDate, CalculatePer, ByLocation, ByVariant, true, true);
                CheckCalcInvtVal.RunCheck(Item, TempErrorBuf);

                if CalcBase = CalcBase::"Standard Cost - Manufacturing" then begin
                    CalcStdCost.SetProperties(PostingDate, true, false, true, '', true);
                    CalcStdCost.TestPreconditions(Item, TempProdBOMVersionErrBuf, TempRtngVersionErrBuf);
                end;
            end;
        }
        dataitem(ItemLedgEntryErrBufLoop; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(ItemLedgEntryErrBuf__Document_Date_; Format(ItemLedgEntryErrBuf."Document Date"))
            {
            }
            column(ItemLedgEntryErrBuf__Entry_Type_; ItemLedgEntryErrBuf."Entry Type")
            {
            }
            column(ItemLedgEntryErrBuf_Description; ItemLedgEntryErrBuf.Description)
            {
            }
            column(ItemLedgEntryErrBuf__Document_No__; ItemLedgEntryErrBuf."Document No.")
            {
            }
            column(ItemLedgEntryErrBuf__Item_No__; ItemLedgEntryErrBuf."Item No.")
            {
            }
            column(ItemLedgEntryErrBuf_Error_Text; TempErrorBuf."Error Text")
            {
            }
            column(ItemLedgEntryErrBuf__Document_Date_Caption; ItemLedgEntryErrBuf__Document_Date_CaptionLbl)
            {
            }
            column(ItemLedgEntryErrBuf__Entry_Type_Caption; ItemLedgEntryErrBuf__Entry_Type_CaptionLbl)
            {
            }
            column(ItemLedgEntryErrBuf_DescriptionCaption; ItemLedgEntryErrBuf_DescriptionCaptionLbl)
            {
            }
            column(ItemLedgEntryErrBuf__Document_No__Caption; ItemLedgEntryErrBuf__Document_No__CaptionLbl)
            {
            }
            column(ItemLedgEntryErrBuf__Item_No__Caption; ItemLedgEntryErrBuf__Item_No__CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    OK := TempErrorBuf.FindSet()
                else
                    OK := TempErrorBuf.Next() <> 0;
                if not OK then
                    CurrReport.Break();

                Clear(ItemLedgEntryErrBuf);
                if TempErrorBuf."Source Table" = DATABASE::Item then begin
                    Item.Get(TempErrorBuf."Source No.");
                    ItemLedgEntryErrBuf."Item No." := Item."No.";
                    ItemLedgEntryErrBuf.Description := Item.Description;
                end;

                if TempErrorBuf."Source Table" = DATABASE::"Item Ledger Entry" then begin
                    ItemLedgEntryErrBuf.Get(TempErrorBuf."Source Ref. No.");
                    Item.Get(ItemLedgEntryErrBuf."Item No.");
                    ItemLedgEntryErrBuf.Description := Item.Description;
                end;
            end;

            trigger OnPreDataItem()
            begin
                TempErrorBuf.Reset();
                TempErrorBuf.SetCurrentKey("Source Table", "Source No.", "Source Ref. No.");
            end;
        }
        dataitem(ProdBOMVersionErrBufLoop; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(Text002; Text002Lbl)
            {
            }
            column(ProdBOMVersionErrBuf__Production_BOM_No__; TempProdBOMVersionErrBuf."Production BOM No.")
            {
            }
            column(ProdBOMVersionErrBuf__Version_Code_; TempProdBOMVersionErrBuf."Version Code")
            {
            }
            column(ProdBOMVersionErrBuf_Description; TempProdBOMVersionErrBuf.Description)
            {
            }
            column(ProdBOMVersionErrBuf__Starting_Date_; Format(TempProdBOMVersionErrBuf."Starting Date"))
            {
            }
            column(ProdBOMVersionErrBuf_Status; TempProdBOMVersionErrBuf.Status)
            {
            }
            column(Text002Caption; Text002CaptionLbl)
            {
            }
            column(ProdBOMVersionErrBuf_StatusCaption; ProdBOMVersionErrBuf_StatusCaptionLbl)
            {
            }
            column(ProdBOMVersionErrBuf__Starting_Date_Caption; ProdBOMVersionErrBuf__Starting_Date_CaptionLbl)
            {
            }
            column(ProdBOMVersionErrBuf_DescriptionCaption; ProdBOMVersionErrBuf_DescriptionCaptionLbl)
            {
            }
            column(ProdBOMVersionErrBuf__Version_Code_Caption; ProdBOMVersionErrBuf__Version_Code_CaptionLbl)
            {
            }
            column(ProdBOMVersionErrBuf__Production_BOM_No__Caption; ProdBOMVersionErrBuf__Production_BOM_No__CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    OK := TempProdBOMVersionErrBuf.Find('-')
                else
                    OK := TempProdBOMVersionErrBuf.Next() <> 0;
                if not OK then
                    CurrReport.Break();

                if TempProdBOMVersionErrBuf."Version Code" = '' then begin
                    ProdBOMHeader.Get(TempProdBOMVersionErrBuf."Production BOM No.");
                    TempProdBOMVersionErrBuf.Description := ProdBOMHeader.Description;
                    TempProdBOMVersionErrBuf.Status := ProdBOMHeader.Status;
                end else begin
                    ProdBOMVersion.Get(TempProdBOMVersionErrBuf."Production BOM No.", TempProdBOMVersionErrBuf."Version Code");
                    TempProdBOMVersionErrBuf.Description := ProdBOMVersion.Description;
                    TempProdBOMVersionErrBuf."Starting Date" := ProdBOMVersion."Starting Date";
                    TempProdBOMVersionErrBuf.Status := ProdBOMVersion.Status;
                end;
                TempProdBOMVersionErrBuf.Modify();
            end;
        }
        dataitem(RtngVersionErrBufLoop; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(Text003; Text003Lbl)
            {
            }
            column(RtngVersionErrBuf_Status; TempRtngVersionErrBuf.Status)
            {
            }
            column(RtngVersionErrBuf__Starting_Date_; Format(TempRtngVersionErrBuf."Starting Date"))
            {
            }
            column(RtngVersionErrBuf_Description; TempRtngVersionErrBuf.Description)
            {
            }
            column(RtngVersionErrBuf__Version_Code_; TempRtngVersionErrBuf."Version Code")
            {
            }
            column(RtngVersionErrBuf__Routing_No__; TempRtngVersionErrBuf."Routing No.")
            {
            }
            column(Text003Caption; Text003CaptionLbl)
            {
            }
            column(RtngVersionErrBuf_StatusCaption; RtngVersionErrBuf_StatusCaptionLbl)
            {
            }
            column(RtngVersionErrBuf__Starting_Date_Caption; RtngVersionErrBuf__Starting_Date_CaptionLbl)
            {
            }
            column(RtngVersionErrBuf_DescriptionCaption; RtngVersionErrBuf_DescriptionCaptionLbl)
            {
            }
            column(RtngVersionErrBuf__Version_Code_Caption; RtngVersionErrBuf__Version_Code_CaptionLbl)
            {
            }
            column(RtngVersionErrBuf__Routing_No__Caption; RtngVersionErrBuf__Routing_No__CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    OK := TempRtngVersionErrBuf.Find('-')
                else
                    OK := TempRtngVersionErrBuf.Next() <> 0;
                if not OK then
                    CurrReport.Break();

                if TempRtngVersionErrBuf."Version Code" = '' then begin
                    RtngHeader.Get(TempRtngVersionErrBuf."Routing No.");
                    TempRtngVersionErrBuf.Description := RtngHeader.Description;
                    TempRtngVersionErrBuf.Status := RtngHeader.Status;
                end else begin
                    RtngVersion.Get(TempRtngVersionErrBuf."Routing No.", TempRtngVersionErrBuf."Version Code");
                    TempRtngVersionErrBuf.Description := RtngVersion.Description;
                    TempRtngVersionErrBuf."Starting Date" := RtngVersion."Starting Date";
                    TempRtngVersionErrBuf.Status := RtngVersion.Status;
                end;
                TempRtngVersionErrBuf.Modify();
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
                        ToolTip = 'Specifies the date for the posting of this batch job. By default, the working date is entered, but you can change it.';
                    }
                    field(CalculatePer; CalculatePer)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calculate Per';
                        ToolTip = 'Specifies if you want to sum up the inventory value per item ledger entry or per item.';

                        trigger OnValidate()
                        begin
                            if CalculatePer = CalculatePer::Item then
                                ItemCalculatePerOnValidate();
                            if CalculatePer = CalculatePer::"Item Ledger Entry" then
                                ItemLedgerEntryCalculatePerOnV();
                        end;
                    }
                    field("By Location"; ByLocation)
                    {
                        ApplicationArea = Location;
                        Caption = 'By Location';
                        Enabled = ByLocationEnable;
                        ToolTip = 'Specifies whether to calculate inventory by location.';
                    }
                    field("By Variant"; ByVariant)
                    {
                        ApplicationArea = Planning;
                        Caption = 'By Variant';
                        Enabled = ByVariantEnable;
                        ToolTip = 'Specifies the item variants that you want the batch job to consider.';
                    }
                    field(CalcBase; CalcBase)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calculation Base';
                        Enabled = CalcBaseEnable;
                        ToolTip = 'Specifies if the revaluation journal will suggest a new value for the Unit Cost (Revalued) field.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            CalcBaseEnable := true;
            ByVariantEnable := true;
            ByLocationEnable := true;
        end;

        trigger OnOpenPage()
        begin
            if PostingDate = 0D then
                PostingDate := WorkDate();

            ValidateCalcLevel();
        end;
    }

    labels
    {
        ItemLedgEntryErrBuf_Error_Text_Caption = 'Error Text';
    }

    trigger OnPreReport()
    begin
        ItemFilter := Item.GetFilters();
    end;

    var
        ItemLedgEntryErrBuf: Record "Item Ledger Entry";
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
        RtngHeader: Record "Routing Header";
        RtngVersion: Record "Routing Version";
        CheckCalcInvtVal: Codeunit "Calc. Inventory Value-Check";
        CalcStdCost: Codeunit "Calculate Standard Cost";
        ItemFilter: Text;
        OK: Boolean;
        ByLocationEnable: Boolean;
        ByVariantEnable: Boolean;
        CalcBaseEnable: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Posting Date of %1';
        Text005: Label 'You cannot enter a %1.';
#pragma warning restore AA0470
        Text006: Label 'You must enter a posting date.';
#pragma warning disable AA0470
        Text007: Label 'You cannot enter a %1, if Calculate Per is Item.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Standard_Cost_Revaluation___TestCaptionLbl: Label 'Standard Cost Revaluation - Test';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        ItemLedgEntryErrBuf__Document_Date_CaptionLbl: Label 'Document Date';
        ItemLedgEntryErrBuf__Entry_Type_CaptionLbl: Label 'Entry Type';
        ItemLedgEntryErrBuf_DescriptionCaptionLbl: Label 'Description';
        ItemLedgEntryErrBuf__Document_No__CaptionLbl: Label 'Document No.';
        ItemLedgEntryErrBuf__Item_No__CaptionLbl: Label 'Item No.';
        Text002Lbl: Label 'The standard cost cannot be calculated before the following production BOMs are certified.';
        Text002CaptionLbl: Label 'Warning!';
        ProdBOMVersionErrBuf_StatusCaptionLbl: Label 'Status';
        ProdBOMVersionErrBuf__Starting_Date_CaptionLbl: Label 'Starting Date';
        ProdBOMVersionErrBuf_DescriptionCaptionLbl: Label 'Description';
        ProdBOMVersionErrBuf__Version_Code_CaptionLbl: Label 'Version Code';
        ProdBOMVersionErrBuf__Production_BOM_No__CaptionLbl: Label 'No.';
        Text003Lbl: Label 'The standard cost cannot be calculated before the following production routings are certified.';
        Text003CaptionLbl: Label 'Warning!';
        RtngVersionErrBuf_StatusCaptionLbl: Label 'Status';
        RtngVersionErrBuf__Starting_Date_CaptionLbl: Label 'Starting Date';
        RtngVersionErrBuf_DescriptionCaptionLbl: Label 'Description';
        RtngVersionErrBuf__Version_Code_CaptionLbl: Label 'Version Code';
        RtngVersionErrBuf__Routing_No__CaptionLbl: Label 'Routing No.';

    protected var
        TempProdBOMVersionErrBuf: Record "Production BOM Version" temporary;
        TempRtngVersionErrBuf: Record "Routing Version" temporary;
        TempErrorBuf: Record "Error Buffer" temporary;
        ByLocation: Boolean;
        ByVariant: Boolean;
        CalcBase: Enum "Inventory Value Calc. Base";
        CalculatePer: Enum "Inventory Value Calc. Per";
        PostingDate: Date;

    local procedure ValidateCalcLevel()
    begin
        PageValidateCalcLevel();
        exit;
    end;

    local procedure PageValidateCalcLevel()
    begin
        if CalculatePer = CalculatePer::"Item Ledger Entry" then begin
            ByLocation := false;
            ByVariant := false;
            CalcBase := CalcBase::" ";
        end;
    end;

    local procedure ItemLedgerEntryCalculatePerOnV()
    begin
        ValidateCalcLevel();
    end;

    local procedure ItemCalculatePerOnValidate()
    begin
        ValidateCalcLevel();
    end;

#if not CLEAN24
    [Obsolete('Replaced by procedure SetParameters()', '24.0')]
    procedure InitializeRequest(NewPostingDate: Date; NewCalculatePer: Option; NewByLocation: Boolean; NewByVariant: Boolean; NewCalcBase: Option)
    begin
        PostingDate := NewPostingDate;
        CalculatePer := "Inventory Value Calc. Per".FromInteger(NewCalculatePer);
        ByLocation := NewByLocation;
        ByVariant := NewByVariant;
        CalcBase := "Inventory Value Calc. Base".FromInteger(NewCalcBase);
    end;
#endif

    procedure SetParameters(NewPostingDate: Date; NewCalculatePer: Enum "Inventory Value Calc. Per"; NewByLocation: Boolean; NewByVariant: Boolean; NewCalcBase: Enum "Inventory Value Calc. Base")
    begin
        PostingDate := NewPostingDate;
        CalculatePer := NewCalculatePer;
        ByLocation := NewByLocation;
        ByVariant := NewByVariant;
        CalcBase := NewCalcBase;
    end;
}

