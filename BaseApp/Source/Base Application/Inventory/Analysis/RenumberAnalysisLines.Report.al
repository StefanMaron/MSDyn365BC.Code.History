namespace Microsoft.Inventory.Analysis;

report 7110 "Renumber Analysis Lines"
{
    Caption = 'Renumber Analysis Lines';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartRowRefNo; RowRefNo)
                    {
                        ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                        Caption = 'Start Row Ref. No.';
                        ToolTip = 'Specifies that the row reference numbers are filled.';
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
        Message(Text000);
    end;

    trigger OnPreReport()
    begin
        if AnalysisLine.Find('-') then
            repeat
                AnalysisLine.Validate("Row Ref. No.", RowRefNo);
                AnalysisLine.Modify();
                RowRefNo := IncStr(RowRefNo);
            until AnalysisLine.Next() = 0;
    end;

    var
        AnalysisLine: Record "Analysis Line";
        RowRefNo: Code[20];
        Text000: Label 'The reference numbers were successfully changed.';

    procedure Init(var AnalysisLine2: Record "Analysis Line")
    begin
        AnalysisLine.Copy(AnalysisLine2);
    end;
}

