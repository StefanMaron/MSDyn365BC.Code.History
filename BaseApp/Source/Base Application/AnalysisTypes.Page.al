page 7110 "Analysis Types"
{
    ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
    Caption = 'Analysis Types';
    DataCaptionFields = "Code";
    PageType = List;
    SourceTable = "Analysis Type";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies the code of the analysis type.';
                }
                field(Name; Name)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies a description of the analysis type.';
                }
                field("Value Type"; "Value Type")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies the value type that the analysis type is based on.';
                }
                field("Item Ledger Entry Type Filter"; "Item Ledger Entry Type Filter")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies a filter on the type of item ledger entry.';
                }
                field("Value Entry Type Filter"; "Value Entry Type Filter")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies a filter on the type of item value entry.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Reset Default Analysis Types")
            {
                ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                Caption = '&Reset Default Analysis Types';
                Image = ResetStatus;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Revert to use the default analysis types that exist in the system.';

                trigger OnAction()
                begin
                    ResetDefaultAnalysisTypes(true);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ItemLedgerEntryTypeFilterOnFor(Format("Item Ledger Entry Type Filter"));
        ValueEntryTypeFilterOnFormat(Format("Value Entry Type Filter"));
    end;

    var
        AnalysisRepMgmt: Codeunit "Analysis Report Management";

    local procedure ItemLedgerEntryTypeFilterOnFor(Text: Text[250])
    begin
        AnalysisRepMgmt.ValidateFilter(Text, DATABASE::"Analysis Type", FieldNo("Item Ledger Entry Type Filter"), false);
        "Item Ledger Entry Type Filter" := Text;
    end;

    local procedure ValueEntryTypeFilterOnFormat(Text: Text[250])
    begin
        AnalysisRepMgmt.ValidateFilter(Text, DATABASE::"Analysis Type", FieldNo("Value Entry Type Filter"), false);
        "Value Entry Type Filter" := Text;
    end;
}

