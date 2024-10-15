page 18871 "TCS Journal Batches"
{
    Caption = 'TCS Journal Batches';
    DataCaptionExpression = DataCaption();
    PageType = List;
    SourceTable = "TCS Journal Batch";

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal you are creating.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a brief description of the journal batch you are creating.';
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as Bank for a Cash account.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the location code for which the journal lines will be posted.';
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account that the balancing entry is posted to, such as a Cash account.';
                }
                field("No. Series"; "No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("Posting No. Series"; "Posting No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign document numbers to ledger entries that are posted from this journal batch.';
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
                Caption = 'Edit Journal';
                Image = OpenJournal;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                PromotedIsBig = true;
                ShortCutKey = 'Return';
                ApplicationArea = Basic, Suite;
                ToolTip = 'Opens a journal based on the journal batch.';
                trigger OnAction()
                begin
                    TCSAdjustment.TemplateSelectionFromTCSBatch(Rec);
                end;
            }
        }
    }
    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetupNewBatch();
    end;

    trigger OnOpenPage()
    begin
        TCSAdjustment.OpenTCSJnlBatch(Rec);
    end;

    local procedure DataCaption(): Text[250]
    var
        TaxJnlTemplate: Record "TCS Journal Template";
    begin
        if Not CurrPage.LookupMode() then
            if GetFilter("Journal Template Name") <> '' then
                if GetRangeMin("Journal Template Name") = GetRangeMax("Journal Template Name") then
                    if TaxJnlTemplate.Get(GetRangeMin("Journal Template Name")) then
                        Exit(TaxJnlTemplate.Name + ' ' + TaxJnlTemplate.Description);
    end;

    var
        TCSAdjustment: Codeunit "TCS Adjustment";
}