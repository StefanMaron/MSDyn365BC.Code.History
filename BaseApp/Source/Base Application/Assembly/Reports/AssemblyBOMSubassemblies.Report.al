namespace Microsoft.Assembly.Reports;

using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;

report 811 "Assembly BOM - Subassemblies"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Assembly/Reports/AssemblyBOMSubassemblies.rdlc';
    AdditionalSearchTerms = 'bill of material sub-assemblies';
    ApplicationArea = Assembly;
    Caption = 'BOM - Sub-Assemblies';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = where("Assembly BOM" = const(true));
            RequestFilterFields = "No.", "Base Unit of Measure", "Shelf No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(temFilter_Item; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(No_Item; "No.")
            {
                IncludeCaption = true;
            }
            column(Description_Item; Description)
            {
                IncludeCaption = true;
            }
            column(BaseUnitofMeasure_Item; "Base Unit of Measure")
            {
                IncludeCaption = true;
            }
            column(Inventory_Item; Inventory)
            {
                IncludeCaption = true;
            }
            column(UnitCost_Item; "Unit Cost")
            {
                IncludeCaption = true;
            }
            column(AlternativeItemNo_Item; "Alternative Item No.")
            {
                IncludeCaption = true;
            }
            column(BOMSubAssembliesCaption; BOMSubAssembliesCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                BOMComp.Reset();
                BOMComp.SetCurrentKey(Type, "No.");
                BOMComp.SetRange(Type, BOMComp.Type::Item);
                BOMComp.SetRange("No.", "No.");
                if not BOMComp.FindFirst() then // Not part of a BOM
                    CurrReport.Skip();
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        ItemFilter := Item.GetFilters();
    end;

    var
        BOMComp: Record "BOM Component";
        ItemFilter: Text;
        BOMSubAssembliesCaptionLbl: Label 'BOM - Sub-Assemblies';
        CurrReportPageNoCaptionLbl: Label 'Page';
}

