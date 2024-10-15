page 17305 "Tax Difference Journal Batches"
{
    Caption = 'Tax Difference Journal Batches';
    DataCaptionExpression = DataCaption;
    PageType = List;
    SourceTable = "Tax Diff. Journal Batch";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name associated with the tax differences journal batch.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with the tax differences journal batch.';
                }
                field("No. Series"; "No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Edit Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Journal';
                Image = EditJournal;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ShortCutKey = 'Return';

                trigger OnAction()
                begin
                    TaxDiffJnlMgt.TemplateSelectionFromBatch(Rec);
                end;
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("P&ost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Image = Post;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Record the related transaction in your books.';

                    trigger OnAction()
                    begin
                        TaxDiffJnlMgt.JnlBatchPost(Rec);
                        CurrPage.Update();
                    end;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetupNewBatch;
    end;

    var
        TaxDiffJnlMgt: Codeunit TaxDiffJnlManagement;

    local procedure DataCaption(): Text[250]
    var
        GenJnlTemplate: Record "Tax Diff. Journal Template";
    begin
        if not CurrPage.LookupMode then
            if GetFilter("Journal Template Name") <> '' then
                if GetRangeMin("Journal Template Name") = GetRangeMax("Journal Template Name") then
                    if GenJnlTemplate.Get(GetRangeMin("Journal Template Name")) then
                        exit(GenJnlTemplate.Name + ' ' + GenJnlTemplate.Description);
    end;
}

