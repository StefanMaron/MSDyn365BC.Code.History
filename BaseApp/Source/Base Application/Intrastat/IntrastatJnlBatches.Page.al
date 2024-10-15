page 327 "Intrastat Jnl. Batches"
{
    Caption = 'Intrastat Jnl. Batches';
    DataCaptionExpression = DataCaption;
    PageType = List;
    SourceTable = "Intrastat Jnl. Batch";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the name of the Intrastat journal.';
                }
                field(Description; Description)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies some information about the Intrastat journal.';
                }
                field("Statistics Period"; "Statistics Period")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the month to report data for. Enter the period as a four-digit number, with no spaces or symbols. Depending on your country, enter either the month first and then the year, or vice versa. For example, enter either 1706 or 0617 for June, 2017.';
                }
                field("Currency Identifier"; "Currency Identifier")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies a code that identifies the currency of the Intrastat report.';
                }
                field("Amounts in Add. Currency"; "Amounts in Add. Currency")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies that you use an additional reporting currency in the general ledger and that you want to report Intrastat in this currency.';
                    Visible = false;
                }
                field(Reported; Reported)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies whether the entry has already been reported to the tax authorities.';
                }
                field("Declaration No."; "Declaration No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the declaration number for the Intrastat journal batch.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(Rec) then
                            CurrPage.Update;
                    end;
                }
                field("Statement Type"; "Statement Type")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies a statement type for the Intrastat journal batch.';
                }
                field("Perform. Country/Region Code"; "Perform. Country/Region Code")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the country/region code. It is mandatory field by creating documents with VAT registration number for other countries.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of VAT Registration in Other Countries will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                    ObsoleteTag = '15.3';
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
            action(EditJournal)
            {
                ApplicationArea = VAT;
                Caption = 'Edit Journal';
                Image = OpenJournal;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ShortCutKey = 'Return';
                ToolTip = 'Open a journal based on the journal batch.';

                trigger OnAction()
                begin
                    IntraJnlManagement.TemplateSelectionFromBatch(Rec);
                end;
            }
        }
    }

    trigger OnInit()
    begin
        SetRange("Journal Template Name");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        xSetupNewBatch; // NAVCZ
    end;

    trigger OnOpenPage()
    begin
        IntraJnlManagement.OpenJnlBatch(Rec);
    end;

    var
        IntraJnlManagement: Codeunit IntraJnlManagement;

    local procedure DataCaption(): Text[250]
    var
        IntraJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        if not CurrPage.LookupMode then
            if (GetFilter("Journal Template Name") <> '') and (GetFilter("Journal Template Name") <> '''''') then
                if GetRangeMin("Journal Template Name") = GetRangeMax("Journal Template Name") then
                    if IntraJnlTemplate.Get(GetRangeMin("Journal Template Name")) then
                        exit(IntraJnlTemplate.Name + ' ' + IntraJnlTemplate.Description);
    end;
}

