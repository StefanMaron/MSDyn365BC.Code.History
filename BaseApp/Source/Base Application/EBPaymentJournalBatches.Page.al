page 2000003 "EB Payment Journal Batches"
{
    Caption = 'EB Payment Journal Batches';
    DataCaptionExpression = DataCaption;
    PageType = List;
    SourceTable = "Paym. Journal Batch";

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
                    ToolTip = 'Specifies that the name of the journal batch you are creating.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the journal batch you are creating.';
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code linked to this journal batch.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that to see the available status, click the AssistButton.';
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
                Image = OpenJournal;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ShortCutKey = 'Return';
                ToolTip = 'Open a journal based on the journal batch.';

                trigger OnAction()
                begin
                    PaymJnlManagement.TemplateSelectionFromBatch(Rec);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        PaymJnlManagement.OpenJnlBatch(Rec);
    end;

    var
        PaymJnlManagement: Codeunit PmtJrnlManagement;

    local procedure DataCaption(): Text[250]
    var
        PaymJnlTemplate: Record "Payment Journal Template";
    begin
        if not CurrPage.LookupMode then
            if GetFilter("Journal Template Name") <> '' then
                if GetRangeMin("Journal Template Name") = GetRangeMax("Journal Template Name") then
                    if PaymJnlTemplate.Get(GetRangeMin("Journal Template Name")) then
                        exit(PaymJnlTemplate.Name + ' ' + PaymJnlTemplate.Description);
    end;
}

