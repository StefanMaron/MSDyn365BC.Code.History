report 31071 "Adj. Maintenance-Item Entries"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Maintenance Adjustments - Item Entries';
    ProcessingOnly = true;
    UsageCategory = Tasks;

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
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies posted prepayment invoices';
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
                PostingDate := WorkDate;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        Residual: Decimal;
        NewPostingDate: Date;
    begin
        if PostingDate = 0D then
            Error(PostingDateErr);

        Window.Open(ProcessTxt);
        with ItemLedgerEntry do begin
            SetCurrentKey("Item No.", "Entry Type");
            SetRange("Entry Type", "Entry Type"::"Negative Adjmt.");
            SetFilter("FA No.", '<>''''');
            if FindSet then
                repeat
                    Window.Update(1, "FA No.");
                    CalcFields("Maintenance Amount", "Cost Amount (Actual)");
                    Residual := -"Cost Amount (Actual)" - "Maintenance Amount";
                    if PostingDate < "Posting Date" then
                        NewPostingDate := "Posting Date"
                    else
                        NewPostingDate := PostingDate;
                    if Residual <> 0 then
                        ItemJnlLinePosting.PostToFA("Document No.", NewPostingDate, "FA No.", "Maintenance Code",
                          Residual, "Entry No.", "Global Dimension 1 Code", "Global Dimension 2 Code");
                until Next = 0;
        end;
        Window.Close;
    end;

    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJnlLinePosting: Codeunit "Item Jnl.-Post Line";
        Window: Dialog;
        PostingDate: Date;
        ProcessTxt: Label 'FA Maintenance updating #1##########';
        PostingDateErr: Label 'You must enter a posting date.';
}

