page 586 "XBRL G/L Map Lines"
{
    AutoSplitKey = true;
    Caption = 'XBRL G/L Map Lines';
    DataCaptionExpression = GetCaption;
    PageType = List;
    SourceTable = "XBRL G/L Map Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("G/L Account Filter"; "G/L Account Filter")
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies the general ledger accounts that will be used to generate the exported data contained in the instance document. Only posting accounts will be used.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GLAccList: Page "G/L Account List";
                    begin
                        GLAccList.LookupMode(true);
                        if not (GLAccList.RunModal = ACTION::LookupOK) then
                            exit(false);

                        Text := GLAccList.GetSelectionFilter;
                        exit(true);
                    end;
                }
                field("Business Unit Filter"; "Business Unit Filter")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the business units that will be used to generate the exported data that is contained in the instance document.';
                    Visible = false;
                }
                field("Global Dimension 1 Filter"; "Global Dimension 1 Filter")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimensions by which data is shown. Global dimensions are linked to records or entries for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Filter"; "Global Dimension 2 Filter")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimensions by which data is shown. Global dimensions are linked to records or entries for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Timeframe Type"; "Timeframe Type")
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies, along with the starting date, period length, and number of periods, what date range will be applied to the general ledger data exported for this line.';
                }
                field("Amount Type"; "Amount Type")
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies which general ledger entries will be included in the total calculated for export to the instance document.';
                }
                field("Normal Balance"; "Normal Balance")
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies either debit or credit. This determines how the balance will be handled during calculation, allowing balances consistent with the Normal Balance type to be exported as positive values. For example, if you want the instance document to contain positive numbers, all G/L Accounts with a normal credit balance will need to have Credit selected for this field.';
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
    }

    local procedure GetCaption(): Text[250]
    var
        XBRLLine: Record "XBRL Taxonomy Line";
    begin
        if not XBRLLine.Get("XBRL Taxonomy Name", "XBRL Taxonomy Line No.") then
            exit('');

        CopyFilter("Label Language Filter", XBRLLine."Label Language Filter");
        XBRLLine.CalcFields(Label);
        if XBRLLine.Label = '' then
            XBRLLine.Label := XBRLLine.Name;
        exit(XBRLLine.Label);
    end;
}

