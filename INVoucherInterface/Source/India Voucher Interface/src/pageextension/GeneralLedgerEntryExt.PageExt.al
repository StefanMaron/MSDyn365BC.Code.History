pageextension 18930 "General Ledger Entry Ext." extends "General Ledger Entries"
{
    actions
    {
        addafter("Value Entries")
        {
            action(Narration)
            {
                Caption = 'Narration';
                ToolTip = 'Select this option to enter narration for a particular line.';
                ApplicationArea = Basic, Suite;
                RunObject = page "Posted Narration";
                RunPageLink = "Entry No." = filter(0), "Transaction No." = field("Transaction No.");
                Promoted = true;
                PromotedCategory = Process;
                Image = Description;
            }
            action("Line Narration")
            {
                Caption = 'Line Narration';
                ToolTip = 'Select this option to enter narration for the voucher.';
                ApplicationArea = Basic, Suite;
                RunObject = page "Posted Narration";
                RunPageLink = "Entry No." = field("Entry No."), "Transaction No." = field("Transaction No.");
                Promoted = true;
                PromotedCategory = Process;
                Image = LineDescription;
            }
            action("Print Voucher")
            {
                Caption = 'Print Voucher';
                ToolTip = 'Select this option to take print of the voucher.';
                ApplicationArea = Basic, Suite;
                Image = PrintVoucher;
                Ellipsis = true;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    GLEntry: Record "G/L Entry";
                    ReportSelections: Record "Report Selections";
                begin
                    ReportSelections.SetRange(Usage, ReportSelections.Usage::"Posted Voucher");
                    ReportSelections.SetFilter("Report ID", '<>0');
                    if not ReportSelections.FindFirst() then
                        exit;

                    GLEntry.SetCurrentKey("Document No.", "Posting Date");
                    GLEntry.SetRange("Document No.", "Document No.");
                    GLEntry.SetRange("Posting Date", "Posting Date");
                    if GLEntry.FindFirst() then
                        Report.RunModal(ReportSelections."Report ID", true, true, GLEntry);
                end;
            }
        }
    }
}