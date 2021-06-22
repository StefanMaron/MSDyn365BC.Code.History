page 272 "Resource Jnl. Batches"
{
    Caption = 'Resource Jnl. Batches';
    DataCaptionExpression = DataCaption;
    PageType = List;
    SourceTable = "Res. Journal Batch";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of this resource journal.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a description of this batch.';
                }
                field("No. Series"; "No. Series")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("Posting No. Series"; "Posting No. Series")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number series code used to assign document numbers to ledger entries that are posted from this journal batch.';
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
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
            action("Edit Journal")
            {
                ApplicationArea = Jobs;
                Caption = 'Edit Journal';
                Image = OpenJournal;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ShortCutKey = 'Return';
                ToolTip = 'Open a journal based on the journal batch.';

                trigger OnAction()
                begin
                    ResJnlMgt.TemplateSelectionFromBatch(Rec);
                end;
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Test Report")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintResJnlBatch(Rec);
                    end;
                }
                action("P&ost")
                {
                    ApplicationArea = Jobs;
                    Caption = 'P&ost';
                    Image = PostOrder;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Codeunit "Res. Jnl.-B.Post";
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';
                }
                action("Post and &Print")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Codeunit "Res. Jnl.-B.Post+Print";
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';
                }
            }
        }
    }

    trigger OnInit()
    begin
        SetRange("Journal Template Name");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetupNewBatch;
    end;

    trigger OnOpenPage()
    begin
        ResJnlMgt.OpenJnlBatch(Rec);
    end;

    var
        ReportPrint: Codeunit "Test Report-Print";
        ResJnlMgt: Codeunit ResJnlManagement;

    local procedure DataCaption(): Text[250]
    var
        ResJnlTemplate: Record "Res. Journal Template";
    begin
        if not CurrPage.LookupMode then
            if GetFilter("Journal Template Name") <> '' then
                if GetRangeMin("Journal Template Name") = GetRangeMax("Journal Template Name") then
                    if ResJnlTemplate.Get(GetRangeMin("Journal Template Name")) then
                        exit(ResJnlTemplate.Name + ' ' + ResJnlTemplate.Description);
    end;
}

